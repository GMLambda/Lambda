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

include("sh_lambda.lua")
include("sh_lambda_npc.lua")
include("sh_lambda_player.lua")
include("sh_animations.lua")
include("sh_spectate.lua")
include("sh_playermodels.lua")
include("sh_globalstate.lua")

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

end

function GM:EntityRemoved(ent)
	-- Burning sounds are annoying.
    ent:StopSound("General.BurningFlesh")
	ent:StopSound("General.BurningObject")
end

function GM:Think()

	if SERVER then
		self:CheckPlayerTimeouts()
		self:RoundThink()
		self:VehiclesThink()
		self:NPCThink()
		self:WeaponTrackingThink()
	end

	if self.MapScript.Think then
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

end

function GM:OnGamemodeLoaded()
    self.ServerStartupTime = GetSyncedTimestamp()
end

function GM:OnReloaded()

	if CLIENT then
		self:HUDInit()
	end

	self:LoadGameTypes()
	self:SetGameType(lambda_gametype:GetString())

end

function GM:Initialize()

	print("GM:Initialize")
	DbgPrint("Synced Timestamp: " .. GetSyncedTimestamp())

	self:LoadGameTypes()
	self:SetGameType(lambda_gametype:GetString())

	self:InitializePlayerList()
	self:InitializeRoundSystem()

	if SERVER then
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
	end

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
		if ent1:GetNW2Bool("DisablePlayerCollide") == true or ent2:GetNW2Bool("DisablePlayerCollide") == true then
			return false
		end
	elseif (ent1:IsNPC() and ent2:GetClass() == "trigger_changelevel") or
	   (ent2:IsNPC() and ent1:GetClass() == "trigger_changelevel")
	then
		return false
	end

	return true

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

end

function GM:EntityRemoved(ent)
	-- HACK: Fix fire sounds never stopping if packet loss happened, we just force it to stop on deletion.
	ent:StopSound("General.BurningFlesh")
	ent:StopSound("General.BurningObject")
end
