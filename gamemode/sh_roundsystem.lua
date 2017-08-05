if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("LambdaRestartRound")
    util.AddNetworkString("LambdaWaitingForPlayers")
end

local DbgPrint = GetLogging("RoundLogic")

local STATE_BOOTING = -2
local STATE_IDLE = -1
local STATE_RESTART_REQUESTED = 0
local STATE_RESTARTING = 1
local STATE_RUNNING = 2

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

	function GM:NotifyPlayerListChanged()

		DbgPrint("GM:NotifyPlayerListChanged")

		self.RoundStartTimeout = self.RoundStartTimeout or GetSyncedTimestamp() + 120
		net.Start("LambdaWaitingForPlayers")
            net.WriteBool(self.WaitingForRoundStart)
			net.WriteFloat(self.RoundStartTimeout)
			net.WriteUInt(self:GetFullyConnectedCount(), 8)
			net.WriteUInt(self:GetConnectingCount() + self:GetFullyConnectedCount(), 8)
        net.Broadcast()

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

    function GM:RestartRound(restartTime, showInfo)

        DbgPrint("Requested restart")

        restartTime = restartTime or lambda_map_restart_timeout:GetInt()

        if self.RoundState ~= STATE_RUNNING then
            DbgPrint("Attempted to restart while restart is pending")
            return
        end

        self.RoundState = STATE_RESTART_REQUESTED
        self.ScheduledRestartTime = GetSyncedTimestamp() + restartTime
        self.RealTimeScale = game.GetTimeScale()

		if IsValid(self.LambdaFailureMessage) then
			self.LambdaFailureMessage:Fire("ShowMessage")
		end

		if showInfo == nil then
			showInfo = true
		end

        net.Start("LambdaRestartRound")
			net.WriteFloat(restartTime)
			net.WriteBool(showInfo)
		net.Broadcast()

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
			--DbgUniquePrint("Waiting for players")
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
			local remaining = self.ScheduledRestartTime - curTime
			local timescale = 0.7 - ((curTime / self.ScheduledRestartTime) * 0.5)
			game.SetTimeScale(timescale)

			local remainingTime = string.format("%0.0f",remaining)
			DbgUniquePrint(remainingTime .. "s remaining until restart")
		end

	end

	function GM:RoundStateRestarting()

		-- PostCleanupMap takes care of this.
		-- Handle restarting state.
		--DbgUniquePrint("Restarting")
		--DbgPrint("Setting restart")
		--self.WaitingForRoundStart = false
		--self:OnNewGame()

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

	net.Receive("LambdaRestartRound", function(length)

		local scheduledRestartTime = net.ReadFloat()
		local showMessage = net.ReadBool()
		GAMEMODE:SetRoundRestarting(GetSyncedTimestamp(), scheduledRestartTime, showMessage)

	end)

    net.Receive("LambdaWaitingForPlayers", function(length)

        local waitingForPlayers = net.ReadBool()
		local timeout = net.ReadFloat()
		local connected = net.ReadUInt(8)
		local totalPlayers = net.ReadUInt(8)

        GAMEMODE:SetWaitingForPlayers(waitingForPlayers, timeout, connected, totalPlayers)

    end)

    function GM:SetRoundRestarting(currentTime, scheduledRestartTime, showMessage)

		self.ScheduledRestartTime = currentTime + scheduledRestartTime
		self.RestartTimeout = scheduledRestartTime
        self.RoundState = STATE_RESTART_REQUESTED

		self:BeginRoundRestart()
		self:EnableRespawnHUD(false, 0, 0)

		local showMessage = showMessage

        hook.Add("RenderScreenspaceEffects", "LambdaRoundRestart", function()
            GAMEMODE:DrawRoundRestart(showMessage)
        end)

    end

	function GM:BeginRoundRestart()

		local self = self
		local ply = LocalPlayer()

		RunConsoleCommand("stopsound")
		util.RunNextFrame(function()
			if IsValid(ply) then
				surface.PlaySound("lambda/death.mp3")
			end
			self:SetSoundSuppressed(true)
		end)

	end

    function GM:SetWaitingForPlayers(waitingForPlayers, timeout, connected, totalPlayers)

		local timeout = timeout
		local connected = connected
		local totalPlayers = totalPlayers

        if waitingForPlayers == true then
            DbgPrint("Set waiting for players")
            hook.Add("HUDPaint", "LambdaRoundWaitingForPlayers", function()
                GAMEMODE:DrawWaitingForPlayers(timeout, connected, totalPlayers)
            end)
        else
            DbgPrint("Unset waiting for players")
            hook.Remove("HUDPaint", "LambdaRoundWaitingForPlayers")
        end

    end

    function GM:DrawRoundRestart(showMessage)

        local curTime = GetSyncedTimestamp()
        if curTime > self.ScheduledRestartTime then
            return
        end

        local remaining = self.ScheduledRestartTime - curTime
		if remaining < 0 then
			return
		end

		local reverse = self.RestartTimeout - remaining
		local perc = 1 - (remaining / self.RestartTimeout)
		local brightness = 0
		if reverse <= 0.5 then
			brightness = (0.5 - reverse) * 1.3
		else
			brightness = 0
		end

        local noiseX = 0
		local noiseY = 0
		local alpha = 255

		if math.random(0, 15) == 0 then
			noiseX = math.random(-10, 5)
			noiseY = math.random(-5, 10)
		end

		if math.random(0, 5) == 0 then
			alpha = math.random(50, 150)
		end

		if showMessage == true then

			local text = "RESTARTING ROUND IN " .. string.format("%.1f", remaining) .. " SECONDS"
			local x = (ScrW() * 0.5)
			local y = (ScrH() * 0.5) + 80

			draw.SimpleText(text, "DermaLarge", x, y, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER)

		end

		local mul = perc * 3

		local tab =
		{
			["$pp_colour_addr"] = 0,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = brightness,
			["$pp_colour_contrast"] = (1 - perc * 0.2),
			["$pp_colour_colour"] = 0.8 - (perc * 0.5),
			["$pp_colour_mulr"] = mul,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0,
		}

		DrawColorModify( tab )

    end

    function GM:DrawWaitingForPlayers(timeout, connected, totalPlayers)

        local noiseX = math.random(-2, 2)
        local noiseY = math.random(-2, 2)
        local progress = string.rep(".", 1 + (CurTime() * 0.5 % 3))
		local remaining = timeout - GetSyncedTimestamp()
		if remaining < 0 then
			remaining = 0
		end

		surface.SetFont("DermaLarge")

        local text = "Waiting for other players" .. progress
		local _,h = surface.GetTextSize(text)
		local y = 0

        draw.SimpleText("Waiting for other players " .. string.format("%d/%d ", connected, totalPlayers) .. progress, "DermaLarge", ScrW() * 0.5, ScrH() * 0.5 + y, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER)
		y = y + h
        draw.SimpleText("Forcing start in " .. string.format("%.02f seconds", remaining), "DermaLarge", ScrW() * 0.5, ScrH() * 0.5 + y, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER)

    end

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
        net.Start("LambdaWaitingForPlayers")
            net.WriteBool(false)
        net.Broadcast()

		local failureMessage = ents.Create("env_message")
		failureMessage:SetKeyValue("spawnflags", "2")
		failureMessage:SetKeyValue("message", "GAMEOVER_ALLY")
		failureMessage:Spawn()

		self.LambdaFailureMessage = failureMessage

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
			self.RoundStartTimeout = GetSyncedTimestamp() + 120
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
