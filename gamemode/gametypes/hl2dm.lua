if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("GameType")
local GAMETYPE = {}

GAMETYPE.Name = "Deathmatch"
GAMETYPE.MapScript = {}
GAMETYPE.UsingCheckpoints = false
GAMETYPE.PlayerSpawnClass = "info_player_deathmatch"

GAMETYPE.MapList =
{
}

GAMETYPE.ClassesEnemyNPC =
{
	["npc_metropolice"] = true,
	["npc_combine"] = true,
	["npc_combine_s"] = true,
	["npc_zombie"] = true,
	["npc_headcrab"] = true,
}

GAMETYPE.ImportantPlayerNPCNames =
{
}

GAMETYPE.ImportantPlayerNPCClasses =
{
}

function GAMETYPE:GetPlayerRespawnTime()

	local timeout = math.Clamp(lambda_max_respawn_timeout:GetInt(), -1, 255)
	return timeout

end

function GAMETYPE:ShouldRestartRound()

    local playerCount = 0
    local aliveCount = 0

	return false

end

function GAMETYPE:GetPlayerLoadout()
	return {
		Weapons =
		{
			"weapon_crowbar",
			"weapon_physcannon",
			"weapon_pistol",
		},
		Ammo =
		{
			["Pistol"] = 20,
		},
		Armor = 0,
		HEV = true,
	}
end

function GAMETYPE:GetPlayerItemPickupMode()
	return GAMETYPE_WEAPONPICKUPMODE_SIMPLE
end

hook.Add("LambdaLoadGameTypes", "HL2DMGameType", function(gametypes)
	gametypes:Add("hl2dm", GAMETYPE)
end)

if CLIENT then
	language.Add("hl2_AmmoFull", "FULL")

	language.Add("HL2_GameOver_Object", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: FAILURE TO PRESERVE MISSION-CRITICAL RESOURCES")
	language.Add("HL2_GameOver_Ally", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: FAILURE TO PRESERVE MISSION-CRITICAL PERSONNEL")
	language.Add("HL2_GameOver_Timer", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: FAILURE TO PREVENT TIME-CRITICAL SEQUENCE")
	language.Add("HL2_GameOver_Stuck", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: DEMONSTRATION OF EXCEEDINGLY POOR JUDGMENT")

	language.Add("HL2_357Handgun", ".357 MAGNUM")
	language.Add("HL2_Pulse_Rifle", "PULSE-RIFLE")
	language.Add("HL2_Bugbait", "BUGBAIT")
	language.Add("HL2_Crossbow", "CROSSBOW")
	language.Add("HL2_Crowbar", "CROWBAR")
	language.Add("HL2_Grenade", "GRENADE")
	language.Add("HL2_GravityGun", "GRAVITY GUN")
	language.Add("HL2_Pistol", "9MM PISTOL")
	language.Add("HL2_RPG", "RPG")
	language.Add("HL2_Shotgun", "SHOTGUN")
	language.Add("HL2_SMG1", "SMG")

	language.Add("World", "Cruel World")
	language.Add("base_ai", "Creature")
end
