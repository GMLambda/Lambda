AddCSLuaFile()

GM.Name = "Lambda"
GM.Author = "N/A"
GM.Email = "N/A"
GM.Website = "N/A"

DEFINE_BASECLASS( "gamemode_base" )

include("sh_debug.lua")
include("sh_string_extend.lua")

include("sh_player_list.lua")
include("sh_mapdata.lua")
include("sh_utils.lua")
include("sh_convars.lua")
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
include("sh_timestamp.lua")

include("sh_lambda.lua")
include("sh_lambda_npc.lua")
include("sh_lambda_player.lua")
include("sh_animations.lua")
include("sh_spectate.lua")

--Disabled for now
--include("sh_gibs.lua")

include("sh_gametypes.lua")

local DbgPrint = GetLogging("Shared")

function GM:Tick()

	if CLIENT then
		self:HUDTick()
	end

end

function GM:Think()

	if SERVER then
		self:CheckPlayerTimeouts()
		self:RoundThink()
		self:VehiclesThink()
		self:NPCThink()

		for _,v in pairs(player.GetAll()) do
			self:PlayerThink(v)
		end
	end

end

function GM:OnReloaded()

	if CLIENT then
		self:HUDInit()
	end

end

function GM:Initialize()

	self:LoadGameTypes()
	self:SetGameType(lambda_gametype:GetString())

	self:InitializePlayerList()
	self:InitializeRoundSystem()

	if SERVER then
		self:InitializeDifficulty()
		if self.InitializeSkybox then
			self:InitializeSkybox()
		end
		self:InitializeCurrentLevel()
		self:TransferPlayers()
	end

end

function GM:ClearGlobalState()

	local gordon_invulnerable = ents.Create("env_global")
	gordon_invulnerable:SetKeyValue("globalstate", "gordon_invulnerable")
	gordon_invulnerable:SetKeyValue("initialstate", "0")
	gordon_invulnerable:Spawn()
	gordon_invulnerable:Fire("TurnOff")

	local gordon_precriminal = ents.Create("env_global")
	gordon_precriminal:SetKeyValue("globalstate", "gordon_precriminal")
	gordon_precriminal:SetKeyValue("initialstate", "0")
	gordon_precriminal:Spawn()
	gordon_precriminal:Fire("TurnOff")

end

function GM:InitPostEntity()

	DbgPrint("GM:InitPostEntity")

	if SERVER then
		self:ClearGlobalState()
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
		return false
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

function GM:ApplyCorrectedDamage(dmginfo)

	local attacker = dmginfo:GetAttacker()

	if IsValid(attacker) and dmginfo:IsDamageType(DMG_BULLET) then

		local weaponTable = nil
		local wep = nil

		if attacker:IsPlayer() then
			weaponTable = self.PLAYER_WEAPON_DAMAGE
			wep = attacker:GetActiveWeapon()
		elseif attacker:IsNPC() then
			weaponTable = self.NPC_WEAPON_DAMAGE
			wep = attacker:GetActiveWeapon()
		end

		if weaponTable ~= nil and IsValid(wep) then
			local class = wep:GetClass()
			local dmgCVar = weaponTable[class]
			if dmgCVar ~= nil then
				local dmgAmount = dmgCVar:GetInt()
				--DbgPrint("Setting modified weapon damage " .. tostring(dmgAmount) .. " on " .. class)
				dmginfo:SetDamage(dmgAmount)
			end
		end

	end

	return dmginfo

end
