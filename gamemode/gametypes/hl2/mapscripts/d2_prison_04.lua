AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.DayTime = "morning"

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

}

function MAPSCRIPT:Init()

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- -171.849915 1534.266602 320.031250
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-193.849915, 1534.266602, 256.031250), Ang = Angle(0, 45, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-171.849915, 1534.266602, 320.031250),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- -563.311829 1569.210205 448.031250
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-563.311829, 1569.210205, 384.163727), Ang = Angle(0, 45, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-563.311829, 1569.210205, 384.163727),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
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
