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

ROUND_INFO_NONE = 0
ROUND_INFO_PLAYERRESPAWN = 1
ROUND_INFO_ROUNDRESTART = 2
ROUND_INFO_WAITING_FOR_PLAYER = 3

function GM:InitializeRoundSystem()

	DbgPrint("GM:InitializeRoundSystem")

	self.RoundState = STATE_IDLE
	self.RoundStartTime = GetSyncedTimestamp()
	self.WaitingForRoundStart = true
	self.RoundStartTimeout = GetSyncedTimestamp() + lambda_connect_timeout:GetInt()

	if SERVER then
		self.OnNewGameEvents = {}
		self.OnMapTransitionEvents = {}
		self.OnMapSpawnEvents = {}
	end

end

if SERVER then

	function GM:NotifyRoundStateChanged(receivers, infoType, params)
		DbgPrint("GM:NotifyRoundStateChanged")

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

        self.RoundState = STATE_RESTART_REQUESTED
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
		self.RoundState = STATE_RESTARTING

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

		local gameType = self:GetGameType()

		--DbgUniquePrint("Round Logic")
		if gameType.ShouldRestartRound ~= nil and gameType:ShouldRestartRound() == true then
			DbgPrint("All players are dead, restart required")
			self:RestartRound()
			self:RegisterRoundLost()
		end

	end

	local ROUND_STATE_LOGIC =
	{
		[STATE_BOOTING] = GM.RoundStateBooting,
		[STATE_IDLE] = GM.RoundStateIdle,
		[STATE_RESTART_REQUESTED] = GM.RoundStateRestartRequested,
		[STATE_RESTARTING] = GM.RoundStateRestarting,
		[STATE_RUNNING] = GM.RoundStateRunning,
	}

    function GM:RoundThink()

		local fn = ROUND_STATE_LOGIC[self.RoundState]
		if fn ~= nil then
			fn(self)
		end

    end

else

	net.Receive("LambdaRoundInfo", function(len)

		local infoType = net.ReadUInt(4)
		local params = net.ReadTable()

		DbgPrint("Received round state info: " .. tostring(infoType))
		PrintTable(params)

		GAMEMODE:SetRoundDisplayInfo(infoType, params)

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
		self.RoundState = STATE_RESTARTING
		self:CleanUpGameEvents()
		self:ResetInputOutput()
		self:ResetVehicleCheckpoint()
		self:ResetCheckpoints()
		self:InitializeGlobalSpeechContext()
		self:InitializeWeaponTracking()
	end
end

function GM:PostCleanupMap()

	DbgPrint("GM:PostCleanupMap")
	if SERVER then
		--self:PostInitializeSkybox()
	end

	if self.RoundState ~= STATE_RESTARTING then
		return
	end

	local self = self
	util.RunNextFrame(function()
		self:StartRound(true)
	end)

end

function GM:IsRoundRestarting()

    if self.RoundState == STATE_RESTART_REQUESTED or
       self.RoundState == STATE_RESTARTING
    then
        return true
    end

    return false

end

function GM:CleanUpGameEvents()
	DbgPrint("Cleaning up Game events")
	self.OnNewGameEvents = {}
	self.OnMapTransitionEvents = {}
	self.OnMapSpawnEvents = {}
end

function GM:RegisterNewGameEvent(v)
    table.insert(self.OnNewGameEvents, { v, 0 })
end

function GM:RegisterMapTransitionEvent(v)
    table.insert(self.OnMapTransitionEvents, { v, 0 })
end

function GM:RegisterMapSpawnEvent(v)
    table.insert(self.OnMapSpawnEvents, { v, 0 })
end

function GM:RoundSystemEntityKeyValue(ent, key, val)

	if key:iequals("OnNewGame") then
        DbgPrint(tostring(ent) .. ": Overriding OnNewGame event")
        self:RegisterNewGameEvent(val)
        return ""
	elseif key:iequals("OnMapSpawn") then
		DbgPrint(tostring(ent) .. ": Overriding OnMapSpawn event")
		self:RegisterMapSpawnEvent(val)
		return ""
	elseif key:iequals("OnMapTransition") then
		DbgPrint(tostring(ent) .. ": Overriding OnMapTransition event")
		self:RegisterMapTransitionEvent(val)
		return ""
    end

end

-- Called as soon players are ready to play or a new round has begun.
function GM:OnNewGame()

    DbgPrint("GM:OnNewGame")

    if self.WaitingForRoundStart == true then
        Error("Critical flaw: Called OnNewGame before NewRound == false")
    end

	-- This should be the right spot.
	self.RoundState = STATE_RUNNING
	self.RoundStartTime = GetSyncedTimestamp()

    if SERVER then

		-- FIXME: Don't ignore the delay time.
		self:CreateTransitionObjects()

		-- Create/Replace things for the map.
		if self.MapScript.PostInit ~= nil then
			self.MapScript:PostInit()
		end

		DbgPrint("Spawning players")
		for _,v in pairs(player.GetAll()) do
			v.TransitionData = self:GetPlayerTransitionData(v)
			v:Spawn()
		end

        -- Notify clients.
		self:NotifyRoundStateChanged(player.GetAll(), ROUND_INFO_NONE, {})

		local failureMessage = ents.Create("env_message")
		failureMessage:SetKeyValue("spawnflags", "2")
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
					print("env_message with chapter already exists")
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
	DbgPrint("Game Events: " .. tostring(#self.OnNewGameEvents))

	self:ResetGlobalStates()

	-- We fire things two frames later as deletion of objects seem to be delayed.
	util.RunNextFrame(function()

		-- We always fire OnMapSpawn
		util.TriggerOutputs(self.OnMapSpawnEvents)

		-- Fire this only when we used map.
		if self.IsChangeLevel == false then
			DbgPrint("Firing OnNewGame events")
			util.TriggerOutputs(self.OnNewGameEvents)
		else
			DbgPrint("Firing OnMapTransition events")
			util.TriggerOutputs(self.OnMapTransitionEvents)
		end

		if self.MapScript.OnNewGame then
			self.MapScript:OnNewGame()
		end

		if IsValid(self.LambdaChapterMessage) then
			self.LambdaChapterMessage:Fire("ShowMessage")
		end

	end)

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

        game.SetTimeScale(1)

		if self.InitPostEntityDone ~= true then
			DbgError("Unfinished booting")
		end

		if cleaned ~= true then
		--	GAMEMODE:CleanUpMap()
		--	DbgPrint("Forcing map refresh.")
		else
			-- Make sure map created vehicles are gone, we take over.
			self:CleanUpVehicles()
		end

    end

    self.WaitingForRoundStart = false

    if self:GetConnectingCount() > 0 and self.RoundState ~= STATE_RESTARTING then
        self.WaitingForRoundStart = true
    elseif player.GetCount() == 0 then
        self.WaitingForRoundStart = true
    end

	self.RoundState = STATE_RESTARTING

	if self.MapScript.Init ~= nil then
    	self.MapScript:Init()
	end

    if SERVER then
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
		self:DisablePreviousMap()
	end

	if self.WaitingForRoundStart == false then
		local self = self
		util.RunNextFrame(function()
			self:OnNewGame()
		end)

    else
        if SERVER then
			self.RoundStartTimeout = GetSyncedTimestamp() + lambda_connect_timeout:GetInt()
			self:NotifyPlayerListChanged()
        end
    end

end

function GM:IsRoundRunning()
	return self.RoundState == STATE_RUNNING
end

function GM:RoundElapsedTime()

	if self.RoundState == STATE_RUNNING then
		return GetSyncedTimestamp() - self.RoundStartTime
	end

	return 0

end
