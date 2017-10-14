AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons =
	{
		"weapon_crowbar",
		"weapon_pistol",
		"weapon_smg1",
		"weapon_357",
		"weapon_physcannon",
		"weapon_frag",
		"weapon_shotgun",
		"weapon_ar2",
		"weapon_rpg",
		"weapon_crossbow",
        "weapon_bugbait",
	},
	Ammo =
	{
		["Pistol"] = 20,
		["SMG1"] = 45,
		["357"] = 6,
		["Grenade"] = 3,
		["Buckshot"] = 12,
		["AR2"] = 50,
		["RPG_Round"] = 8,
		["SMG1_Grenade"] = 3,
		["XBowBolt"] = 4,
	},
	Armor = 60,
	HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["player_spawn_items"] = true,
	["pclip_gate1"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-4438.691406, 274.473907, -319.968750), Ang = Angle(0, 0, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-4493.349121, 297.115906, -319.968750),
			Angle(0, 0, 0),
			Vector(-20, -20, 0),
			Vector(20, 20, 100)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- -4295.874023 430.960907 96.031250
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-4295.874023, 430.960907, 96.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(-4295.874023, 430.960907, 96.031250),
			Angle(0, 0, 0),
			Vector(-20, -20, 0),
			Vector(20, 20, 100)
		)
		checkpointTrigger2.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
