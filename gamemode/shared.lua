if SERVER then
	AddCSLuaFile()
end

GM.Name = "Lambda"
GM.Author = "N/A"
GM.Email = "N/A"
GM.Website = "https://github.com/ZehMatt/Lambda"
GM.Version = "0.9 Beta"

DEFINE_BASECLASS( "gamemode_base" )

include("sh_debug.lua")
include("sh_convars.lua")
include("sh_string_extend.lua")
include("sh_interpvalue.lua")
include("sh_timestamp.lua")
include("sh_gma.lua")

include("sh_surfaceproperties.lua")
include("sh_player_list.lua")
include("sh_mapdata.lua")
include("sh_utils.lua")
include("sh_ents_extend.lua")
include("sh_npc_extend.lua")
include("sh_player_extend.lua")
include("sh_entity_extend.lua")
include("sh_roundsystem.lua")
include("sh_sound_env.lua")
include("sh_vehicles.lua")
include("sh_sound_env.lua")
include("sh_temp.lua")
include("sh_bullets.lua")
include("sh_hudhint.lua")

include("sh_lambda.lua")
include("sh_lambda_npc.lua")
include("sh_lambda_player.lua")
include("sh_animations.lua")
include("sh_spectate.lua")
include("sh_playermodels.lua")
include("sh_globalstate.lua")
include("sh_userauth.lua")
include("sh_admin_config.lua")

--Disabled for now
--include("sh_gibs.lua")

include("sh_gametypes.lua")

local DbgPrint = GetLogging("Shared")

function GM:Tick()

	if CLIENT then
		self:HUDTick()
	else
		self:UpdateCheckoints()
	end

	if SERVER then
		self:CheckPlayerTimeouts()
		self:RoundThink()
		self:VehiclesThink()
		self:NPCThink()
		self:WeaponTrackingThink()
		self:CheckStuckScenes()
	else
		self:ClientThink()
	end

	if self.MapScript and self.MapScript.Think then
		self.MapScript:Think()
	end

	-- Make sure physics don't go crazy when we toggle it.
	local collisionChanged = false
	if self.LastAllowCollisions ~= lambda_playercollision:GetBool() then
		collisionChanged = true
		self.LastAllowCollisions = lambda_playercollision:GetBool()
	end

	for _,v in pairs(player.GetAll()) do
		self:PlayerThink(v)
		if collisionChanged == true then
			v:CollisionRulesChanged()
		end
	end

	local gameType = self:GetGameType()
	if gameType.Think then
		gameType:Think()
	end

end

function GM:EntityRemoved(ent)
	-- HACK: Fix fire sounds never stopping if packet loss happened, we just force it to stop on deletion.
	ent:StopSound("General.BurningFlesh")
	ent:StopSound("General.BurningObject")

	local class = ent:GetClass()
	if class == "logic_choreographed_scene" and self.LogicChoreographedScenes ~= nil then
		self.LogicChoreographedScenes[ent] = nil
	end
end

function GM:CheckStuckScenes()

	local curTime = CurTime()
	if self.LastStuckScenesCheck ~= nil and curTime - self.LastStuckScenesCheck < 0.5 then
		return
	end
	self.LastStuckScenesCheck = curTime

	for ent,_ in pairs(self.LogicChoreographedScenes or {}) do

		if not IsValid(ent) then
			table.remove(self.LogicChoreographedScenes, ent)
			continue
		end

		-- This probably performs like horseshit. Sadly GetInternalVariable doesn't work on this one.
		local savetable = ent:GetSaveTable()
		if savetable.m_bWaitingForActor == true then
			if ent.WaitingForActor ~= true then
				print(ent, "now waiting for actor")
				ent.WaitingForActorTime = CurTime()
				ent.WaitingForActor = true
			elseif ent.WaitingForActor == true then
				local delta = CurTime() - ent.WaitingForActorTime
				if delta >= 5 then
					print("Long waiting logic_choreographed_scene")
					ent:SetKeyValue("busyactor", "0")
					ent.WaitingForActor = false
				end
			end
		else
			if ent.WaitingForActor == true then
				print(ent, "no longer waiting")
			end
			ent.WaitingForActor = false
		end

	end

end

function GM:Think()


end

function GM:OnGamemodeLoaded()
	self.ServerStartupTime = GetSyncedTimestamp()

	self:LoadGameTypes()
	self:SetGameType(lambda_gametype:GetString())
	self:MountRequiredContent()

end

function GM:OnReloaded()

	if CLIENT then
		self:HUDInit()
	end

	self:LoadGameTypes()
	self:SetGameType(lambda_gametype:GetString())
end

function GM:MountRequiredContent()

	local gametype = self:GetGameType()
	local filename = "lambda_mount_" .. gametype.GameType .. ".dat"
	local mountFiles = gametype.MountContent or {}

	if table.Count(mountFiles) == 0 then
		return true
	end

	if file.Exists(filename, "DATA") == false then
		print("Creating new GMA mount package...")
		if GMA.CreatePackage(mountFiles, filename) == false then
			print("Unable to create GMA archive, make sure you have the required content mounted.")
			return
		end
		print("OK.")
	else
		print("Found pre-existing GMA archive, no need to generate.")
	end

	if file.Exists(filename, "DATA") == false then
		-- What?
		print("Unable to find the GMA archive, unable to mount.")
		return
	end

	local res, mountedList = game.MountGMA("data/" .. filename)
	if res == false then
		print("Unable to mount the required GMA, you may be unable to play.")
		return
	end

	print("Mounted content!")

end

function GM:Initialize()

	DbgPrint("GM:Initialize")
	DbgPrint("Synced Timestamp: " .. GetSyncedTimestamp())

	self:InitializePlayerList()
	self:InitializeRoundSystem()

	if SERVER then
		self:ResetSceneCheck()
		self:InitializeGlobalSpeechContext()
		self:InitializeWeaponTracking()
		self:InitializeGlobalStates()
		self:InitializePlayerModels()
		self:InitializeDifficulty()
		if self.InitializeSkybox then
			self:InitializeSkybox()
		end
		self:InitializeCurrentLevel()
		self:TransferPlayers()
		self:InitializeResources()
	end
end

function GM:ResetSceneCheck()
	self.LogicChoreographedScenes = {}
	self.LastStuckScenesCheck = CurTime()
end

function GM:InitPostEntity()

	DbgPrint("GM:InitPostEntity")

	if SERVER then
		self:ResetGlobalStates()
		self:PostLoadTransitionData()
		self:InitializeMapVehicles()
		if self.PostInitializeSkybox then
			self:PostInitializeSkybox()
		end
		self:SetRoundBootingComplete()
		self.InitPostEntityDone = true
	else
		self:HUDInit()
	end

end

function GM:ShouldCollide(ent1, ent2)

	if ent1:IsPlayer() and ent2:IsPlayer() then
		if lambda_playercollision:GetBool() == false then
			return false
		end
		if ent1:GetNWBool("DisablePlayerCollide", false) == true or ent2:GetNWBool("DisablePlayerCollide", false) == true then
			return false
		end
	elseif (ent1:IsNPC() and ent2:GetClass() == "trigger_changelevel") or
	   (ent2:IsNPC() and ent1:GetClass() == "trigger_changelevel")
	then
		return false
	end

	return true

end

function GM:ProcessEnvHudHint(ent)
	DbgPrint(ent, "Enabling env_hudhint for all players")
	ent:AddSpawnFlags(1) -- SF_HUDHINT_ALLPLAYERS
end

function GM:ProcessEnvMessage(ent)
	DbgPrint(ent, "Enabling env_message for all players")
	ent:AddSpawnFlags(2) -- SF_MESSAGE_ALL
end

function GM:ProcessFuncAreaPortal(ent)
	DbgPrint(ent, "Opening func_areaportal")
	-- TODO: This is not ideal at all on larger maps, however can can not get a position for them.
	ent:SetKeyValue("StartOpen", "1")
	ent:Fire("Open")
	ent:SetName("Lambda_" .. ent:GetName())
end

function GM:ProcessFuncAreaPortalWindow(ent)
	DbgPrint(ent, "Extending func_areaportalwindow")
	-- I know this is ugly, but its better than white windows everywhere, this is not 2004 anymore.
	local saveTable = ent:GetSaveTable()
	local fadeStartDist = tonumber(saveTable["FadeStartDist"] or "0") * 3
	local fadeDist = tonumber(saveTable["FadeDist"] or "0") * 3
	ent:SetKeyValue("FadeDist", fadeDist)
	ent:SetKeyValue("FadeStartDist", fadeStartDist)
end

function GM:ProcessTriggerWeaponDissolve(ent)
	-- OnChargingPhyscannon
	-- UGLY HACK! But thats the only way we can tell when to upgrade.
	ent:Fire("AddOutput", "OnChargingPhyscannon lambda_physcannon,Supercharge,,0")
end

function GM:ProcessLogicChoreographedScene(ent)

	self.LogicChoreographedScenes = self.LogicChoreographedScenes or {}
	self.LogicChoreographedScenes[ent] = true

end

local ENTITY_PROCESSORS =
{
	["env_hudhint"] = { PostFrame = true, Fn = GM.ProcessEnvHudHint },
	["env_message"] = { PostFrame = true, Fn = GM.ProcessEnvMessage },
	["func_areaportal"] = { PostFrame = true, Fn = GM.ProcessFuncAreaPortal },
	["func_areaportalwindow"] = { PostFrame = true, Fn = GM.ProcessFuncAreaPortalWindow },
	["logic_choreographed_scene"] = { PostFrame = true, Fn = GM.ProcessLogicChoreographedScene },
}

function GM:OnEntityCreated(ent)

	if SERVER then
		local class = ent:GetClass()
		local entityProcessor = ENTITY_PROCESSORS[class]

		if entityProcessor ~= nil and entityProcessor.PostFrame == false then
			entityProcessor.Fn(self, ent)
		end

		-- Used to track the entity in case we respawn it.
		ent.UniqueEntityId = ent.UniqueEntityId or self:GetNextUniqueEntityId()

		-- Run this next frame so we can safely remove entities and have their actual names assigned.
		util.RunNextFrame(function()

			if not IsValid(ent) then
				return
			end

			-- Required information for respawning some things.
			ent.InitialSpawnData =
			{
				Pos = ent:GetPos(),
				Ang = ent:GetAngles(),
				Mins = ent:OBBMins(),
				Maxs = ent:OBBMaxs(),
			}

			if ent:IsWeapon() == true then
				self:TrackWeapon(ent)
				if ent:CreatedByMap() == true then
					DbgPrint("Level designer created weapon: " .. tostring(ent))
					self:InsertLevelDesignerPlacedObject(ent)
				end
			elseif ent:IsItem() == true then
				if ent:CreatedByMap() == true then
					DbgPrint("Level designer created item: " .. tostring(ent))
					self:InsertLevelDesignerPlacedObject(ent)
				end
			end

			if self.MapScript then
				-- Monitor scripts that we have filtered by class name.
				if self.MapScript.EntityFilterByClass and self.MapScript.EntityFilterByClass[ent:GetClass()] == true then
					DbgPrint("Removing filtered entity by class: " .. tostring(ent))
					ent:Remove()
					return
				end

				-- Monitor scripts that have filtered by name.
				if self.MapScript.EntityFilterByName and self.MapScript.EntityFilterByName[ent:GetName()] == true then
					DbgPrint("Removing filtered entity by name: " .. tostring(ent) .. " (" .. ent:GetName() .. ")")
					ent:Remove()
					return
				end
			end

			if entityProcessor ~= nil and entityProcessor.PostFrame == true then
				entityProcessor.Fn(self, ent)
			end

		end)

		if ent:IsNPC() then
			self:RegisterNPC(ent)
		end

		-- Deal with vehicles at the same frame, sometimes it wouldn't show the gun.
		if ent:IsVehicle() then
			self:HandleVehicleCreation(ent)
		end
	else
		-- Nothing for now.
	end

end

function GM:EntityKeyValue(ent, key, val)

	ent.LambdaKeyValues = ent.LambdaKeyValues or {}

	if util.IsOutputValue(key) then
		ent.EntityOutputs = ent.EntityOutputs or {}
		ent.EntityOutputs[key] = ent.EntityOutputs[key] or {}
		table.insert(ent.EntityOutputs[key], val)
	else
		ent.LambdaKeyValues[key] = val
	end

	if SERVER then
		local res
		res = self:RoundSystemEntityKeyValue(ent, key, val)
		if res ~= nil then
			return res
		end
	end

	if self.MapScript.EntityKeyValue then
		res = self.MapScript:EntityKeyValue(ent, key, val)
		if res ~= nil then
			return res
		end
	end

	-- HACKHACK: Having it set to 1 causes some NPCs to fail playing their scene.
	if ent:GetClass() == "logic_choreographed_scene" and key:iequals("busyactor") then
		--return "0"
	end

end
