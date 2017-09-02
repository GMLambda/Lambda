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

}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        --3957.129150 -5952.989258 450.031250
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3957.129150, -5952.989258, 450.031250), Ang = Angle(0, 45, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(3652.347900, -5942.446777, 450.478577),
			Angle(0, 0, 0),
			Vector(-100, -250, 0),
			Vector(100, 250, 200)
		)
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- 3544.566162 -5148.934570 494.436218
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3544.566162, -5148.934570, 494.436218), Ang = Angle(0, 45, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(5272.279785, -3704.953613, 244.444000),
			Angle(0, 0, 0),
			Vector(-100, -250, 0),
			Vector(100, 250, 200)
		)
        checkpointTrigger2.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        -- 2141.143555 -346.152466 672.031250
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2141.143555, -346.152466, 672.031250), Ang = Angle(0, 45, 0) })
        local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(2141.143555, -346.152466, 672.031250),
			Angle(0, 0, 0),
			Vector(-100, -250, 0),
			Vector(100, 250, 200)
		)
        checkpointTrigger3.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

        -- 2200.594727, 2562.878418, 644.802246
        local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2200.594727, 2562.878418, 644.802246), Ang = Angle(0, 45, 0) })
        local checkpointTrigger4 = ents.Create("trigger_once")
		checkpointTrigger4:SetupTrigger(
			Vector(2200.594727, 2562.878418, 644.802246),
			Angle(0, 0, 0),
			Vector(-100, -250, 0),
			Vector(100, 250, 200)
		)
        checkpointTrigger4.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint4)
        end

        -- 4624.031250 4047.968750 848.031250
        local checkpoint5 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(4624.031250, 4047.968750, 848.031250), Ang = Angle(0, 45, 0) })
        local checkpointTrigger5 = ents.Create("trigger_once")
		checkpointTrigger5:SetupTrigger(
			Vector(4702.513184, 4080.001953, 848.031250),
			Angle(0, 0, 0),
			Vector(-100, -250, 0),
			Vector(100, 250, 200)
		)
        checkpointTrigger5.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint5)
        end

        --7709.140625 6282.970703 686.273071
        local checkpoint6 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(7709.140625, 6282.970703, 686.273071), Ang = Angle(0, 45, 0) })
        local checkpointTrigger6 = ents.Create("trigger_once")
        checkpointTrigger6:SetupTrigger(
            Vector(7709.140625, 6282.970703, 686.273071),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger6.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint6)
        end

        --9101.698242 7700.960938 1742.293091
        local checkpoint7 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(9101.698242, 7700.960938, 1742.293091), Ang = Angle(0, 45, 0) })
        local checkpointTrigger7 = ents.Create("trigger_once")
        checkpointTrigger6:SetupTrigger(
            Vector(9101.698242, 7700.960938, 1742.293091),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger7.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint7)
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
