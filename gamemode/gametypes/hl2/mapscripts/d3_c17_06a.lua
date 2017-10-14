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
	["pclip_gate1"] = true,
	["player_spawn_template"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

		-- 3081.572754 -1725.475098 -287.968750
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3081.572754, -1725.475098, -287.968750), Ang = Angle(0, 90, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(3081.572754, -1725.475098, -287.968750),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 100)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- 2937.786865 2507.701416 -319.968750 6.483 89.871 0.000

		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2667.206787, 3911.651367, -323.968750), Ang = Angle(0, 90, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(2945.403076, 2563.369629, -319.968750),
			Angle(0, 0, 0),
			Vector(-30, -30, 0),
			Vector(30, 30, 100)
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
