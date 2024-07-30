local util = util

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("LambdaRoundInfo")
    util.AddNetworkString("LambdaRoundRestarting")
end

sound.Add({
    name = "Lambda.RoundEnd",
    channel = CHAN_STATIC,
    volume = 1.0,
    soundlevel = 80,
    pitchstart = 100,
    pitchend = 100,
    sound = "lambda/roundover.mp3"
})

local DbgPrint = GetLogging("RoundLogic")
local ents = ents
local IsValid = IsValid
local table = table
local CurTime = CurTime
local STATE_NONE = -3
local STATE_BOOTING = -2
local STATE_IDLE = -1
local STATE_RESTART_REQUESTED = 0
local STATE_RESTARTING = 1
local STATE_RUNNING = 2
local STATE_FINISHED = 3
local STATE_CHANGING_LEVEL = 4
ROUND_INFO_NONE = 0
ROUND_INFO_PLAYERRESPAWN = 1
ROUND_INFO_ROUNDRESTART = 2
ROUND_INFO_WAITING_FOR_PLAYER = 3
ROUND_INFO_STARTED = 4
ROUND_INFO_FINISHED = 5
ROUND_INFO_CHANGELEVEL = 6

function GM:ShouldWaitForPlayers()
    local res = self:GetGameTypeData("WaitForPlayers")
    if res == nil then return false end

    return res
end

function GM:InitializeRoundSystem()
    DbgPrint("GM:InitializeRoundSystem")
    if not SERVER then return end
    self:SetRoundState(STATE_IDLE)
    self:SetRoundStartTime(GetSyncedTimestamp())
    self.WaitingForRoundStart = self:ShouldWaitForPlayers()
    self.RoundStartTimeout = GetSyncedTimestamp() + self:GetSetting("connect_timeout")
end

function GM:GetRoundState()
    if SERVER then return self.RoundState end

    return GetGlobalInt("LambdaRoundState", STATE_IDLE)
end

function GM:GetRoundStartTime()
    if SERVER then return self.RoundStartTime end

    return GetGlobalFloat("LambdaRoundStartTime", 0)
end

function GM:RoundElapsedTime()
    return GetSyncedTimestamp() - self:GetRoundStartTime()
end

if SERVER then
    function GM:SetRoundState(state)
        -- Clients.
        SetGlobalInt("LambdaRoundState", state)
        -- Server.
        self.RoundState = state
    end

    function GM:SetRoundStartTime(t)
        -- Clients.
        SetGlobalFloat("LambdaRoundStartTime", t)
        -- Server
        self.RoundStartTime = t
    end

    function GM:NotifyRoundStateChanged(receivers, infoType, params)
        DbgPrint("GM:NotifyRoundStateChanged")
        if istable(receivers) and #receivers == 0 then return end
        net.Start("LambdaRoundInfo")
        net.WriteUInt(infoType, 4)
        net.WriteTable(params)
        net.Send(receivers)
    end

    function GM:NotifyPlayerListChanged()
        if self.WaitingForRoundStart ~= true then return end
        DbgPrint("GM:NotifyPlayerListChanged")

        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_WAITING_FOR_PLAYER, {
            StartTime = self.ServerStartupTime,
            Timeout = self:GetSetting("connect_timeout"),
            FullyConnected = self:GetFullyConnectedCount(),
            Connecting = self:GetConnectingCount()
        })
    end

    function GM:SetRoundBootingComplete()
        DbgPrint("GM:SetRoundBootingComplete")

        if self.RoundState == STATE_BOOTING then
            self.RoundState = STATE_IDLE -- Wait for players.
        end

        -- Reset map once players are arround.
        if player.GetCount() == 0 then
            self.RequiresRoundRestart = true
        end
    end

    function GM:IncludePlayerInRound(ply)
        DbgPrint("GM:IncludePlayerInRound(" .. tostring(ply) .. ")")
        self:NotifyPlayerListChanged()
    end

    function GM:RestartRound(reason)
        DbgPrint("Requested restart")
        local restartTime = self:GetSetting("map_restart_timeout")
        restartTime = math.Clamp(restartTime, 0, 127)

        if self.RoundState ~= STATE_RUNNING then
            DbgPrint("Attempted to restart while restart is pending")

            return
        end

        self:SetRoundState(STATE_RESTART_REQUESTED)
        self.RestartStartTime = GetSyncedTimestamp()
        self.ScheduledRestartTime = self.RestartStartTime + restartTime
        self.RealTimeScale = game.GetTimeScale()

        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_ROUNDRESTART, {
            StartTime = self.RestartStartTime,
            Timeout = restartTime
        })

        if restartTime > 0 then
            if reason ~= nil then
                reason = self.FailureMessages[reason]

                if IsValid(reason) then
                    reason:Fire("ShowMessage")
                end
            end

            net.Start("LambdaRoundRestarting", false)
            net.Broadcast()
        end
    end

    function GM:CleanUpMap()
        DbgPrint("GM:CleanUpMap")
        -- Make sure nothing is going to create new things now
        self:SetRoundState(STATE_RESTARTING)
        -- Check what we have to cleanup
        local filter = {}
        hook.Call("LambdaCleanupFilter", GAMEMODE, filter)
        game.CleanUpMap(false, filter, function() end)
    end

    function GM:RoundStateBooting()
        DbgUniquePrint("Waiting for boot")
    end

    function GM:RoundStateIdle()
        local playerCount = player.GetCount()

        if self.WaitingForRoundStart == true and (self:GetConnectingCount() > 0 or playerCount == 0) then
            -- Waiting for players
            if self.RoundStartTimeout ~= nil and GetSyncedTimestamp() >= self.RoundStartTimeout then
                DbgPrint("Timeout, round will start now")
                self:StartRound(false, true)
            end
        elseif self.WaitingForRoundStart == true and playerCount > 0 and self:GetConnectingCount() == 0 then
            DbgPrint("All players available")
            self:StartRound()
        elseif self.WaitingForRoundStart == false then
            self:StartRound()
        end
    end

    function GM:RoundStateRestartRequested()
        local curTime = GetSyncedTimestamp()

        if curTime >= self.ScheduledRestartTime then
            DbgPrint("Restarting round...")
            self.RoundState = STATE_RESTARTING
            self:CleanUpMap()
        else
            local timeLeft = self.ScheduledRestartTime - curTime
            local timeLimit = self.ScheduledRestartTime - self.RestartStartTime
            local timeAlpha = timeLeft / timeLimit
            local timeScale = math.max(0.1, timeAlpha * 0.2)
            game.SetTimeScale(timeScale)
        end
    end

    function GM:RoundStateRestarting()
    end

    function GM:RoundStateRunning()
        local elapsed = self:RoundElapsedTime()

        if self:CallGameTypeFunc("ShouldRestartRound", elapsed) == true then
            DbgPrint("All players are dead, restart required")
            self:RestartRound("GAMEOVER_STUCK")
            self:RegisterRoundLost()
        elseif self:CallGameTypeFunc("ShouldEndRound", elapsed) == true then
            DbgPrint("Round end")
            self:FinishRound()
        end
    end

    function GM:RoundStateFinished()
    end

    function GM:RoundStateChangingLevel()
        if GetSyncedTimestamp() < self.ChangeLevelTime then return end
        -- Avoid coming back here and avoid notifying the client.
        self.RoundState = STATE_NONE
        -- Invoke a changelevel command to actually change the map.
        self:ChangeLevel(self.ChangeLevelMap)
    end

    local ROUND_STATE_LOGIC = {
        [STATE_NONE] = function() end,
        [STATE_BOOTING] = GM.RoundStateBooting,
        [STATE_IDLE] = GM.RoundStateIdle,
        [STATE_RESTART_REQUESTED] = GM.RoundStateRestartRequested,
        [STATE_RESTARTING] = GM.RoundStateRestarting,
        [STATE_RUNNING] = GM.RoundStateRunning,
        [STATE_FINISHED] = GM.RoundStateFinished,
        [STATE_CHANGING_LEVEL] = GM.RoundStateChangingLevel
    }

    function GM:RoundThink()
        local state = self:GetRoundState()
        local fn = ROUND_STATE_LOGIC[state]

        if fn ~= nil then
            fn(self)
        else
            error("Missing round state handler: " .. tostring(state))
        end
    end

    function GM:SetRoundChangingLevel(nextMap, delay)
        self:SetRoundState(STATE_CHANGING_LEVEL)

        for _, v in pairs(player.GetAll()) do
            v:Freeze(true)
        end

        self.ChangeLevelTime = GetSyncedTimestamp() + delay
        self.ChangeLevelMap = nextMap

        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_CHANGELEVEL, {
            NextMap = nextMap,
            ChangeLevelTime = self.ChangeLevelTime
        })
    end

    function GM:FinishRound()
        self:SetRoundState(STATE_FINISHED)

        for _, v in pairs(player.GetAll()) do
            v:Freeze(true)
        end

        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_FINISHED, {})

        if self:GetGameTypeData("PostRoundMapVote") == true then
            local gameType = self:GetGameType()
            local mapOptions = table.Copy(gameType.MapList)

            for k, v in pairs(mapOptions) do
                local r = math.random(1, #mapOptions)
                mapOptions[k] = mapOptions[r]
                mapOptions[r] = string.lower(v)
            end

            local prevMap = self:GetPreviousMap()

            if prevMap ~= nil then
                prevMap = string.lower(prevMap)
                table.RemoveByValue(mapOptions, prevMap)
            end

            local curMap = self:GetCurrentMap()

            if curMap ~= nil then
                curMap = string.lower(curMap)
                table.RemoveByValue(mapOptions, curMap)
            end

            while #mapOptions > 8 do
                local k = math.random(1, #mapOptions)
                table.remove(mapOptions, k)
            end

            timer.Simple(5, function()
                self:StartVote(nil, VOTE_TYPE_NEXT_MAP, 10, {
                    mustComplete = true
                }, mapOptions, {}, function(vote, failed, timeout, winningOption)
                    local picked = mapOptions[winningOption]
                    self:RequestChangeLevel(picked, nil, {})
                end)
            end)
        end
    end
else -- CLIENT
    function GM:HandleRoundInfoStarted(infoType, params)
        if IsValid(self.RoundEndSound) then
            self.RoundEndSound:Stop()
            self.RoundEndSound = nil
        end
    end

    function GM:HandleRoundInfoFinished(infoType, params)
        self:SetKeepScoreboardOpen(true)
        self:ScoreboardShow()
    end

    function GM:HandleRoundInfoChangeLevel(infoType, params)
        self.ChangeLevelTime = params.ChangeLevelTime
        self.ChangeLevelMap = params.NextMap
        self:SetKeepScoreboardOpen(true)
        self:ScoreboardShow()
    end

    function GM:HandleRoundInfoChange(infoType, params)
        if infoType == ROUND_INFO_FINISHED then
            self:HandleRoundInfoFinished(infoType, params)
        elseif infoType == ROUND_INFO_CHANGELEVEL then
            self:HandleRoundInfoChangeLevel(infoType, params)
        elseif infoType == ROUND_INFO_STARTED then
            self:HandleRoundInfoStarted(infoType, params)
        else
            self:SetRoundDisplayInfo(infoType, params)
        end
    end

    function GM:HandleRoundRestarting()
        local ply = LocalPlayer()
        ply:ConCommand("stopsoundscape")
        ply:ConCommand("stopsound")
        ply:SetDSP(0, true)

        -- We have to delay this otherwise it will be cancalced by stopsound.
        util.RunNextFrame(function()
            local snd = CreateSound(game.GetWorld(), "Lambda.RoundEnd")
            snd:SetSoundLevel(0)
            snd:ChangeVolume(1)
            snd:Play()

            self.RoundEndSound = snd
        end)
    end

    net.Receive("LambdaRoundInfo", function(len)
        local infoType = net.ReadUInt(4)
        local params = net.ReadTable()
        DbgPrint("Received round state info: " .. tostring(infoType))
        GAMEMODE:HandleRoundInfoChange(infoType, params)
    end)

    net.Receive("LambdaRoundRestarting", function(len)
        GAMEMODE:HandleRoundRestarting()
    end)
end

function GM:PreCleanupMap()
    DbgPrint("GM:PreCleanupMap")
    -- Because of reload testing.
    self.ChangingLevel = false

    if SERVER then
        -- Make sure there are no pending outputs
        RunConsoleCommand("ent_cancelpendingentfires")

        -- Disable all overlays.
        for _, v in pairs(ents.FindByClass("env_screenoverlay")) do
            v:Input("StopOverlays")
        end

        -- Reset player state.
        for _, v in pairs(player.GetAll()) do
            v:LockPosition(false)
            v:Freeze(false)
            v:KillSilent()
        end

        for _, v in pairs(ents.GetAll()) do
            -- Prevent recursions.
            v:EnableRespawn(false)
        end

        -- NOTE: Sometimes scripted scenes can play after map cleanup.
        --       So we cancel everything before that.
        do
            for _, v in pairs(ents.FindByClass("logic_choreographed_scene")) do
                -- Cancel all scenes.
                DbgPrint("Cancel scene " .. tostring(v))
                v:Input("Cancel")
            end

            for _, v in pairs(ents.FindByClass("npc_*")) do
                DbgPrint("Cancel scripting " .. tostring(v))
                v:Input("StopScripting")
            end
        end

        -- FIX: Stop screen shaking, they are not cleaned up.
        for _, v in pairs(ents.FindByClass("env_shake")) do
            v:Input("StopShake")
        end

        -- Cleanup the input/output system.
        self:SetRoundState(STATE_RESTARTING)
        self:ResetInputOutput()
        self:ResetVehicleCheckpoint()
        self:ResetCheckpoints()
        self:ResetSceneCheck()
        self:CleanUpVehicles()
        self:ClearLevelDesignerPlacedObjects()
        -- Reset all queued functions.
        util.ResetFunctionQueue()
    end
end

function GM:PostCleanupMap()
    DbgPrint("GM:PostCleanupMap")
    -- Make sure there are no builtin outputs
    RunConsoleCommand("ent_cancelpendingentfires")
    -- Make sure no lambda outputs are created during restart.
    util.ResetOutputQueue()
    if self:GetRoundState() ~= STATE_RESTARTING then return end

    util.RunNextFrame(function()
        -- Create/Replace things for the map.
        if self.MapScript.LevelPostInit ~= nil then
            self.MapScript:LevelPostInit()
        end

        self:StartRound(true)
    end)
end

function GM:IsRoundRestarting()
    local state = self:GetRoundState()
    if state == STATE_RESTART_REQUESTED or state == STATE_RESTARTING then return true end

    return false
end

function GM:GetMapLoadType()
    -- Because changelevel is used instead of changelevel2 it would always return "newgame"
    -- http://wiki.garrysmod.com/page/game/MapLoadType
    if self.IsChangeLevel == true then return "transition" end

    return game.MapLoadType()
end

function GM:SetupRoundRelevantObjects()
    local function CreateEnvMessage(msg)
        -- Remove duplicate ones
        for _, v in pairs(ents.FindByClass("env_message")) do
            local keyvalues = v:GetKeyValues()
            local message = keyvalues["message"]
            if keyvalues ~= nil and message ~= nil and msg == message then
                DbgPrint("Removing duplicate env_message : " .. msg)
                v:Remove()
            end
        end

        -- Take control over env_message with GAMEOVER_ALLY
        local envMsg = ents.Create("env_message")
        envMsg:SetKeyValue("spawnflags", "2")
        envMsg:SetKeyValue("targetname", "LambdaMessage_" .. msg)
        envMsg:SetKeyValue("message", msg)
        envMsg:Spawn()

        return envMsg
    end

    for _, v in pairs(self.FailureMessages or {}) do
        if IsValid(v) then
            v:Remove()
        end
    end

    self.FailureMessages = {}
    self.FailureMessages["GAMEOVER_ALLY"] = CreateEnvMessage("GAMEOVER_ALLY")
    self.FailureMessages["GAMEOVER_TIMER"] = CreateEnvMessage("GAMEOVER_TIMER")
    self.FailureMessages["GAMEOVER_OBJECT"] = CreateEnvMessage("GAMEOVER_OBJECT")
    self.FailureMessages["GAMEOVER_STUCK"] = CreateEnvMessage("GAMEOVER_STUCK")
    local roachManager = ents.Create("lambda_cockroach_manager")
    roachManager:Spawn()
    self.LambdaRoachManager = roachManager
    local mapData = game.GetMapData()

    if mapData ~= nil and mapData.Entities ~= nil then
        local worldData = mapData.Entities[1]

        if worldData ~= nil and worldData["chaptertitle"] ~= nil then
            local chapterText = worldData["chaptertitle"]
            local dupe = false

            -- Lets not do it if it already exists in env_message.
            for _, v in pairs(ents.FindByClass("env_message")) do
                local keyvalues = v:GetKeyValues()

                if keyvalues ~= nil and keyvalues["message"] ~= nil and keyvalues["message"]:iequals(chapterText) then
                    dupe = true
                    break
                end
            end

            -- Garry's Mod never shows the chapter title, but it is identical to env_message.
            if dupe == false then
                local chapterMessage = ents.Create("env_message")
                chapterMessage:SetKeyValue("spawnflags", "2")
                chapterMessage:SetKeyValue("message", worldData["chaptertitle"])
                chapterMessage:Spawn()
                self.LambdaChapterMessage = chapterMessage
            else
                DbgPrint("env_message with chapter already exists")
            end
        end
    end
end

-- Called as soon players are ready to play or a new round has begun.
function GM:OnNewGame()
    DbgPrint("GM:OnNewGame")

    if self.WaitingForRoundStart == true then
        Error("Critical flaw: Called OnNewGame before NewRound == false")
    end

    if SERVER then
        local function SetDefaultGlobals()
            local defaultGlobals = self:GetGameTypeData("DefaultGlobalState")

            if defaultGlobals ~= nil then
                for k, v in pairs(defaultGlobals) do
                    game.SetGlobalState(k, v)
                end
            end
        end

        SetDefaultGlobals()
        self:ResetGlobalStates()
        local mapscriptGlobals = self.MapScript.GlobalStates

        if mapscriptGlobals ~= nil then
            for k, v in pairs(mapscriptGlobals) do
                game.SetGlobalState(k, v)
            end
        else
            SetDefaultGlobals()
        end

        -- FIXME: Don't ignore the delay time.
        self:CreateTransitionObjects()

        -- Create/Replace things for the map.
        if self.MapScript.PostInit ~= nil then
            self.MapScript:PostInit()
        end

        if self.MapScript.Checkpoints ~= nil then
            self:CreateCheckpointsFromData(self.MapScript.Checkpoints)
        end

        -- Notify clients.
        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_NONE, {})
        self:SetupRoundRelevantObjects()
        self:ResetVehicleCheck()

        util.RunNextFrame(function()
            GAMEMODE:PostRoundSetup()
        end)
    end
end

function GM:PostRoundSetup()
    DbgPrint("PostRoundSetup")
    self:SetRoundState(STATE_RUNNING)
    self:SetRoundStartTime(GetSyncedTimestamp())

    self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_STARTED, {
        -- Is this required? GetRoundStartTime is networked, but as an event, why not?
        StartTime = self:GetRoundStartTime()
    })

    self:ResetPlayerRespawnQueue()
    DbgPrint("Spawning players")

    for _, v in pairs(player.GetAll()) do
        v.TransitionData = self:GetPlayerTransitionData(v)
        v:Spawn()
    end

    -- GoldSrc support.
    for _, v in pairs(ents.FindByClass("trigger_auto")) do
        v:Fire("Enable")
    end

    for _, v in pairs(ents.FindByClass("logic_auto")) do
        v:Fire("Enable")
    end

    local loadType = self:GetMapLoadType()
    local mapScript = self:GetMapScript()

    if loadType == "transition" then
        if mapScript ~= nil and mapScript.OnMapTransition ~= nil then
            mapScript:OnMapTransition()
        end
    elseif loadType == "newgame" then
        if mapScript ~= nil and mapScript.OnNewGame ~= nil then
            mapScript:OnNewGame()
        end
    elseif loadType == "loadgame" then
        if mapScript ~= nil and mapScript.OnLoadGame ~= nil then
            mapScript:OnLoadGame()
        end
    elseif loadType == "background" then
        if mapScript ~= nil and mapScript.OnBackgroundMap ~= nil then
            mapScript:OnBackgroundMap()
        end
    end

    -- Fires without condition.
    if mapScript ~= nil and mapScript.OnMapSpawn ~= nil then
        mapScript:OnMapSpawn()
    end

    util.RunDelayed(function()
        if IsValid(self.LambdaChapterMessage) then
            self.LambdaChapterMessage:Fire("ShowMessage")
        end
    end, CurTime() + 1)
end

function GM:StartRound(cleaned, force)
    -- Initialize map script.
    DbgPrint("GM:StartRound")

    if CLIENT then
        hook.Remove("HUDPaint", "LambdaRoundRestart")
        hook.Remove("Think", "LambdaRoundRestart")
        self:SetSoundSuppressed(false)
    end

    if SERVER then
        -- NOTE: If NPCs existed before players joined they often wander off.
        -- This compensates by simply resetting the map when every player is available.
        if self.RequiresRoundRestart == true and cleaned ~= true then
            self.RequiresRoundRestart = nil
            self:CleanUpMap()

            return
        end

        self:InitializeGlobalSpeechContext()
        self:InitializeWeaponTracking()
        self:ResetMetrics()
        game.SetTimeScale(1)

        if self.InitPostEntityDone ~= true then
            DbgError("Unfinished booting")
        end

        --self.RoundState = STATE_RESTARTING
        self:SetRoundState(STATE_RESTARTING)
    end

    self.WaitingForRoundStart = false

    if force ~= true and self:ShouldWaitForPlayers() == true then
        if self:GetConnectingCount() > 0 and self.RoundState ~= STATE_RESTARTING then
            self.WaitingForRoundStart = true
        elseif player.GetCount() == 0 then
            self.WaitingForRoundStart = true
        end
    end

    self:ResetMapScript()

    if self.MapScript ~= nil and self.MapScript.Init ~= nil then
        self.MapScript:Init()
    end

    if SERVER and self.MapScript and self.MapScript.InputFilters then
        local count = 0

        for k, t in pairs(self.MapScript.InputFilters) do
            for _, v in pairs(t) do
                self:FilterEntityInput(k, v)
                count = count + 1
            end
        end

        DbgPrint("Loaded " .. tostring(count) .. " input filter for current map")
    end

    if SERVER then
        local ignoreLandmark = false

        if self.MapScript ~= nil and self.MapScript.IgnoreLandmark ~= nil then
            ignoreLandmark = self.MapScript.IgnoreLandmark
        end

        self:DisablePreviousMap(ignoreLandmark)
    end

    if self.WaitingForRoundStart == false then
        util.RunDelayed(function()
            self:OnNewGame()
        end, CurTime() + 0.5)
    else
        if SERVER then
            self:SetRoundState(STATE_IDLE)
            self:SetRoundStartTime(GetSyncedTimestamp())
            self.RoundStartTimeout = GetSyncedTimestamp() + self:GetSetting("connect_timeout")
            self:NotifyPlayerListChanged()
        end
    end
end

function GM:IsRoundRunning()
    return self:GetRoundState() == STATE_RUNNING
end

function GM:IsChangingLevel()
    return self:GetRoundState() == STATE_CHANGING_LEVEL
end

function GM:GetLevelChangeMap()
    return self.ChangeLevelMap
end

function GM:GetLevelChangeTime()
    return self.ChangeLevelTime
end