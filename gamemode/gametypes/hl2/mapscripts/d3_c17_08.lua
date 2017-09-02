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
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

		-- -1478.292725 -1717.604614 104.600342
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1478.292725, -1717.604614, 104.600342), Ang = Angle(0, 90, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-1478.292725, -1717.604614, 104.600342),
			Angle(0, 0, 0),
			Vector(-130, -130, 0),
			Vector(130, 130, 100)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- 1119.968750 -840.288269 -559.968750
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(299.584564, -1424.746704, -287.968750), Ang = Angle(0, 0, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(227.741821, -1265.945923, -287.968750),
			Angle(0, 0, 0),
			Vector(-130, -130, 0),
			Vector(130, 130, 100)
		)
		checkpointTrigger2.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

		-- 1537.006226 -813.546021 80.031250
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1488.074829, -900.734985, 80.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(1537.006226, -813.546021, 80.031250),
			Angle(0, 0, 0),
			Vector(-130, -130, 0),
			Vector(130, 130, 100)
		)
		checkpointTrigger3.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end


		-- 1392.383179 -76.121971 372.128113
		local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1286.711914, 610.125366, 400.031250), Ang = Angle(0, -90, 0) })
		local checkpointTrigger4 = ents.Create("trigger_once")
		checkpointTrigger4:SetupTrigger(
			Vector(1392.383179, -76.121971, 372.128113),
			Angle(0, 0, 0),
			Vector(-500, -500, 0),
			Vector(500, 500, 250)
		)
		checkpointTrigger4.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint4)
		end

		-- 1650.219482 -89.667931 624.031250
		local checkpoint5 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1650.219482, -89.667931, 624.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger5 = ents.Create("trigger_once")
		checkpointTrigger5:SetupTrigger(
			Vector(1650.219482, -89.667931, 624.031250),
			Angle(0, 0, 0),
			Vector(-100, -100, 0),
			Vector(100, 100, 100)
		)
		checkpointTrigger5.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint5)
		end


    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
