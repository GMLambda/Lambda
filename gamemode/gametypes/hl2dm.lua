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
	"dm_lockdown",
	"dm_overwatch",
	"dm_steamlab",
	"dm_underpass",
	"dm_resistance",
	"dm_powerhouse",
	"dm_runoff",
	"halls3"
}

GAMETYPE.ClassesEnemyNPC =
{
}

GAMETYPE.ImportantPlayerNPCNames =
{
}

GAMETYPE.ImportantPlayerNPCClasses =
{
}

function GAMETYPE:GetPlayerRespawnTime()

	local timeout = 2
	return timeout

end

function GAMETYPE:IsTeamOnly()

	return lambda_dm_teamonly:GetBool()

end

function GAMETYPE:GetFragLimit()

	return lambda_dm_fraglimit:GetInt()

end

function GAMETYPE:GetTimeLimit()

	return lambda_dm_timelimit:GetInt() * 60

end

function GAMETYPE:ShouldRestartRound()

	return false

end

function GAMETYPE:GetNextMap(map)
	local k = table.KeyFromValue(self.MapList, map)
	local nextmap

	if !self.MapList[k + 1] then
		nextmap = self.MapList[1]
	else
		nextmap = self.MapList[k + 1]
	end
	return nextmap
end

function GAMETYPE:EndRound(winner)

	local nextmap = self:GetNextMap(game.GetMap())
	for k, v in pairs(player.GetAll()) do v:Freeze(true) end
	PrintMessage(HUD_PRINTTALK, "Round Over. Frag limit reached by " .. winner:Name() .. ".")

	PrintMessage(HUD_PRINTTALK, "Switching map to " .. nextmap .. ".")
	timer.Simple(10, function() GAMEMODE:ChangeLevel(nextmap, nil, {}) end)

end

function GAMETYPE:ShouldEndRound()

	for _, ply in pairs(player.GetAll()) do
		if ply:Frags() >= self:GetFragLimit() then
			self:EndRound(ply)
			print(ply:Name())
		end
	end

end

function GAMETYPE:PlayerDeath(ply, inflictor, attacker)
	ply:AddDeaths( 1 )

	-- Suicide?
	if inflictor == ply or attacker == ply then
		attacker:AddFrags(-1)
		return
	end

	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:AddFrags( 1 )
	elseif IsValid(inflictor) and inflictor:IsPlayer() then
		inflictor:AddFrags( 1 )
	end

	self:ShouldEndRound()
end

function GAMETYPE:PlayerShouldTakeDamage(ply, attacker, inflictor)
	-- TODO: In case of TDM we need to check the team.
	return true
end

function GAMETYPE:GetPlayerLoadout()
	return {
		Weapons =
		{
			"weapon_crowbar",
			"weapon_physcannon",
			"weapon_smg1",
			"weapon_pistol",
		},
		Ammo =
		{
			["Pistol"] = 20,
			["SMG1"] = 60,
		},
		Armor = 0,
		HEV = true,
	}
end

function GAMETYPE:GetWeaponRespawnTime()
	-- ConVar sv_hl2mp_weapon_respawn_time( "sv_hl2mp_weapon_respawn_time", "20", FCVAR_GAMEDLL | FCVAR_NOTIFY );
	return 20
end

function GAMETYPE:GetItemRespawnTime()
	-- ConVar sv_hl2mp_item_respawn_time( "sv_hl2mp_item_respawn_time", "30", FCVAR_GAMEDLL | FCVAR_NOTIFY );
	return 30
end

function GAMETYPE:ShouldRespawnWeapon(ent)
	if GAMEMODE:IsLevelDesignerPlacedObject(ent) == false then
		return false
	end
	return true
end

function GAMETYPE:ShouldRespawnItem(ent)
	if GAMEMODE:IsLevelDesignerPlacedObject(ent) == false then
		return false
	end
	return true
end

function GAMETYPE:PlayerCanPickupWeapon(ply, wep)
	return true
end

function GAMETYPE:PlayerCanPickupItem(ply, item)
	return true
end

function GAMETYPE:CanPlayerSpawn(ply, spawn)
	local pos = spawn:GetPos()
	local tr = util.TraceHull(
	{
		start = pos,
		endpos = pos + Vector(0, 0, 1),
		mins = HULL_HUMAN_MINS,
		maxs = HULL_HUMAN_MAXS,
		mask = MASK_SOLID,
		filter = ply,
	})
	return tr.Fraction == 1.0
end

function GAMETYPE:PlayerSelectSpawn(spawns)
	return table.Random(spawns)
end

function GAMETYPE:AllowPlayerTracking()
	return false
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
