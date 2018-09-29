if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("LambdaRoundInfo")
end

local DbgPrint = GetLogging("RoundLogic")

local STATE_BOOTING = -2
local STATE_IDLE = -1
local STATE_RESTART_REQUESTED = 0
local STATE_RESTARTING = 1
local STATE_RUNNING = 2
local STATE_FINISHED = 3

ROUND_INFO_NONE = 0
ROUND_INFO_PLAYERRESPAWN = 1
ROUND_INFO_ROUNDRESTART = 2
ROUND_INFO_WAITING_FOR_PLAYER = 3
ROUND_INFO_STARTED = 4
ROUND_INFO_FINISHED = 5

function GM:InitializeRoundSystem()

    DbgPrint("GM:InitializeRoundSystem")

    if not SERVER then
        return
    end

    self:SetRoundState(STATE_IDLE)
    self:SetRoundStartTime(GetSyncedTimestamp())

    self.WaitingForRoundStart = true
    self.RoundStartTimeout = GetSyncedTimestamp() + lambda_connect_timeout:GetInt()

end

function GM:GetRoundState()
    if SERVER then
        return self.RoundState
    end
    return GetGlobalInt("LambdaRoundState", STATE_IDLE)
end

function GM:GetRoundStartTime()
    if SERVER then
        return self.RoundStartTime
    end
    return GetGlobalFloat("LambdaRoundStartTime", 0)
end

function GM:RoundElapsedTime()

    if self:GetRoundState() == STATE_RUNNING then
        return GetSyncedTimestamp() - self:GetRoundStartTime()
    end

    return 0

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

        if istable(receivers) and #receivers == 0 then
            return
        end

        net.Start("LambdaRoundInfo")
        net.WriteUInt(infoType, 4)
        net.WriteTable(params)
        net.Send(receivers)
    end

    function GM:NotifyPlayerListChanged()

        if self.WaitingForRoundStart ~= true then
            return
        end

        DbgPrint("GM:NotifyPlayerListChanged")

        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_WAITING_FOR_PLAYER, {
            StartTime = self.ServerStartupTime,
            Timeout = lambda_connect_timeout:GetInt(),
            FullyConnected = self:GetFullyConnectedCount(),
            Connecting = self:GetConnectingCount(),
        })

    end

    function GM:SetRoundBootingComplete()

        DbgPrint("GM:SetRoundBootingComplete")

        if self.RoundState == STATE_BOOTING then
            self.RoundState = STATE_IDLE -- Wait for players.
        end

    end

    function GM:IncludePlayerInRound(ply)

        DbgPrint("GM:IncludePlayerInRound(" .. tostring(ply) .. ")")
        self:NotifyPlayerListChanged()

    end

    function GM:RestartRound()

        DbgPrint("Requested restart")

        local restartTime = lambda_map_restart_timeout:GetInt()
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
            Timeout = restartTime,
        })

        if restartTime > 0 then

            if IsValid(self.LambdaFailureMessage) then
                self.LambdaFailureMessage:Fire("ShowMessage")
            end

            -- FIXME: This only works on listen server, we should setup a new message
            --        and run this on the client only.

            -- Stop all the current playing sounds.
            for k,v in pairs(player.GetAll()) do
                v:ConCommand("stopsoundscape")
                v:ConCommand("stopsound")
                v:SetDSP(0, true)
            end

            -- We have to delay this otherwise it will be cancalced by stopsound.
            util.RunNextFrame(function()
                local filter = RecipientFilter()
                filter:AddAllPlayers()

                local snd = CreateSound(game.GetWorld(), "lambda/roundover.mp3", filter)
                snd:SetSoundLevel(0)
                snd:Play()
            end)

        end

    end

    function GM:CleanUpMap()

        DbgPrint("GM:CleanUpMap")

        -- Make sure nothing is going to create new things now
        self:SetRoundState(STATE_RESTARTING)

        -- Remove vehicles
        self:CleanUpVehicles()

        -- Check what we have to cleanup
        local filter = {}
        hook.Call("LambdaCleanupFilter", GAMEMODE, filter)

        game.CleanUpMap(false, filter)

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
                self:StartRound()
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

        if curTime > self.ScheduledRestartTime then
            DbgPrint("Restarting round...")
            self.RoundState = STATE_RESTARTING
            self:CleanUpMap()
        else
            local timescale = 0.7 - ((curTime / self.ScheduledRestartTime) * 0.5)
            game.SetTimeScale(timescale)
        end

    end

    function GM:RoundStateRestarting()
    end

    function GM:RoundStateRunning()

        local elapsed = self:RoundElapsedTime()

        if self:CallGameTypeFunc("ShouldRestartRound", elapsed) == true then
            DbgPrint("All players are dead, restart required")
            self:RestartRound()
            self:RegisterRoundLost()
        elseif self:CallGameTypeFunc("ShouldEndRound", elapsed) == true then 
            DbgPrint("Round end")
            self:FinishRound()
        end

    end

    function GM:RoundStateFinished()
    end

    local ROUND_STATE_LOGIC =
    {
        [STATE_BOOTING] = GM.RoundStateBooting,
        [STATE_IDLE] = GM.RoundStateIdle,
        [STATE_RESTART_REQUESTED] = GM.RoundStateRestartRequested,
        [STATE_RESTARTING] = GM.RoundStateRestarting,
        [STATE_RUNNING] = GM.RoundStateRunning,
        [STATE_FINISHED] = GM.RoundStateFinished,
    }

    function GM:RoundThink()

        local state = self:GetRoundState()
        local fn = ROUND_STATE_LOGIC[state]
        if fn ~= nil then
            fn(self)
        end

    end

    function GM:FinishRound()

        self:SetRoundState(STATE_END_RESULTS)

        for _,v in pairs(player.GetAll()) do
            v:Freeze(true)
        end

        local gameType = self:GetGameType()
        local mapOptions = table.Copy(gameType.MapList)
        for k,v in pairs(mapOptions) do
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

        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_FINISHED, {
        })

        timer.Simple(5, function()
            self:StartVote(nil, VOTE_TYPE_NEXT_MAP, 10, { mustComplete = true }, mapOptions, {}, function(vote, failed, timeout, winningOption)
                local picked = mapOptions[winningOption]
                self:ChangeLevel(picked)
            end)
        end)

    end

else -- CLIENT

    function GM:HandleRoundInfoStarted(infoType, params)
    end

    function GM:HandleRoundInfoFinished(infoType, params)
        self:ScoreboardShow(true)
    end

    function GM:HandleRoundInfoChange(infoType, params)

        if infoType == ROUND_INFO_FINISHED then
            self:HandleRoundInfoFinished(infoType, params)
        elseif infoType == ROUND_INFO_STARTED then
            self:HandleRoundInfoStarted(infoType, params)
        else
            self:SetRoundDisplayInfo(infoType, params)
        end

    end

    net.Receive("LambdaRoundInfo", function(len)

        local infoType = net.ReadUInt(4)
        local params = net.ReadTable()

        DbgPrint("Received round state info: " .. tostring(infoType))
        --PrintTable(params)

        GAMEMODE:HandleRoundInfoChange(infoType, params)

    end)

end

function GM:PreCleanupMap()
    DbgPrint("GM:PreCleanupMap")
    if SERVER then
        for _,v in pairs(player.GetAll()) do
            v:KillSilent()
        end

        -- Prevent recursions.
        for _,v in pairs(ents.GetAll()) do
            v:EnableRespawn(false)
        end

        -- Cleanup the input/output system.
        self:SetRoundState(STATE_RESTARTING)

        self:ResetInputOutput()
        self:ResetVehicleCheckpoint()
        self:ResetCheckpoints()
        self:ResetSceneCheck()
        self:ClearLevelDesignerPlacedObjects()
    end
end

function GM:PostCleanupMap()

    DbgPrint("GM:PostCleanupMap")

    if self:GetRoundState() ~= STATE_RESTARTING then
        return
    end

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
    if state == STATE_RESTART_REQUESTED or
       state == STATE_RESTARTING
    then
        return true
    end

    return false

end

function GM:GetMapLoadType()

    -- Because changelevel is used instead of changelevel2 it would always return "newgame"
    -- http://wiki.garrysmod.com/page/game/MapLoadType
    if self.IsChangeLevel == true then
        return "transition"
    end
    return game.MapLoadType()

end

-- Called as soon players are ready to play or a new round has begun.
function GM:OnNewGame()

    DbgPrint("GM:OnNewGame")

    if self.WaitingForRoundStart == true then
        Error("Critical flaw: Called OnNewGame before NewRound == false")
    end

    if SERVER then

        local defaultGlobals = self:GetGameTypeData("DefaultGlobalState")
        if defaultGlobals ~= nil then
            for k,v in pairs(defaultGlobals) do
                game.SetGlobalState(k, v)
            end
        end

        local mapscriptGlobals = self.MapScript.GlobalStates
        if mapscriptGlobals ~= nil then
            for k,v in pairs(mapscriptGlobals) do
                game.SetGlobalState(k, v)
            end
        end

        -- FIXME: Don't ignore the delay time.
        self:CreateTransitionObjects()

        -- Create/Replace things for the map.
        if self.MapScript.PostInit ~= nil then
            self.MapScript:PostInit()
        end

        -- Notify clients.
        self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_NONE, {})

        local failureMessage = ents.Create("env_message")
        failureMessage:SetKeyValue("spawnflags", "2")
        failureMessage:SetKeyValue("targetname", "LambdaGameOver")
        failureMessage:SetKeyValue("message", "GAMEOVER_ALLY")
        failureMessage:Spawn()
        self.LambdaFailureMessage = failureMessage

        local mapData = game.GetMapData()
        if mapData ~= nil and mapData.Entities ~= nil then
            local worldData = mapData.Entities[1]
            if worldData ~= nil and worldData["chaptertitle"] ~= nil then

                local chapterText = worldData["chaptertitle"]
                local dupe = false
                -- Lets not do it if it already exists in env_message.
                for _,v in pairs(ents.FindByClass("env_message")) do
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
        StartTime = self:GetRoundStartTime(),
    })

    DbgPrint("Spawning players")
    for _,v in pairs(player.GetAll()) do
        v.TransitionData = self:GetPlayerTransitionData(v)
        v:Spawn()
    end

    self:ResetGlobalStates()

    -- GoldSrc support.
    for _,v in pairs(ents.FindByClass("trigger_auto")) do
        v:Fire("Enable")
    end

    for _,v in pairs(ents.FindByClass("logic_auto")) do
        v:Fire("Enable")
    end

    util.RunDelayed(function()
        if IsValid(self.LambdaChapterMessage) then
            self.LambdaChapterMessage:Fire("ShowMessage")
        end
    end, CurTime() + 1)

end

function GM:StartRound(cleaned)

    -- Initialize map script.
    DbgPrint("GM:StartRound")

    if CLIENT then
        hook.Remove("HUDPaint", "LambdaRoundRestart")
        hook.Remove("Think", "LambdaRoundRestart")

        self:SetSoundSuppressed(false)
    end

    if SERVER then

        self:InitializeGlobalSpeechContext()
        self:InitializeWeaponTracking()
        self:ResetMetrics()

        game.SetTimeScale(1)

        if self.InitPostEntityDone ~= true then
            DbgError("Unfinished booting")
        end

        if cleaned ~= true then
        --  GAMEMODE:CleanUpMap()
        --  DbgPrint("Forcing map refresh.")
        else
            -- Make sure map created vehicles are gone, we take over.
            self:CleanUpVehicles()
        end

        --self.RoundState = STATE_RESTARTING
        self:SetRoundState(STATE_RESTARTING)

    end

    self.WaitingForRoundStart = false

    if self:GetConnectingCount() > 0 and self.RoundState ~= STATE_RESTARTING then
        self.WaitingForRoundStart = true
    elseif player.GetCount() == 0 then
        self.WaitingForRoundStart = true
    end

    self:ResetMapScript()

    if self.MapScript.Init ~= nil then
        self.MapScript:Init()
    end

    if SERVER and self.MapScript and self.MapScript.InputFilters then
        local count = 0
        for k,t in pairs(self.MapScript.InputFilters) do
            for _,v in pairs(t) do
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
            self.RoundStartTimeout = GetSyncedTimestamp() + lambda_connect_timeout:GetInt()
            self:NotifyPlayerListChanged()
        end
    end

end

function GM:IsRoundRunning()
    return self:GetRoundState() == STATE_RUNNING
end
