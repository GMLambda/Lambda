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
	["global_newgame_template_local_items"] = true,
	["global_newgame_template_ammo"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

		-- 1386.760010 946.409973 385.000000
		-- Make sure the player spawns at the correct spot.
		local spawn = ents.Create("info_player_start")
		spawn:SetPos(Vector(1386.760010, 946.409973, 385.000000))
		spawn:SetAngles(Angle(0, -180, 0))
		spawn:SetKeyValue("spawnflags", "1")
		spawn:Spawn()

        -- setpos -497.127838 29.422707 576.030090;setang 1.708000 -178.566528 0.000000
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-497.127838, 29.422707, 512.03009), Ang = Angle(0, 0, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-497.127838, 29.422707, 576.030090),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        --setpos -1863.151978 -198.581955 576.031250;setang 4.380192 174.982666 0.000000
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1863.151978, -198.581955, 512.03125), Ang = Angle(0, 0, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-1863.151978, -198.581955, 576.031250),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger2.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        -- setpos -2622.549316 191.525955 704.031250;setang 4.698761 -175.380798 0.000000
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-2622.549316, 191.525955, 640.03125), Ang = Angle(0, 0, 0) })
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(-2622.549316, 191.525955, 704.031250),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger3.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

        -- setpos -4656.063477 -734.348145 704.031250;setang 3.504144 -4.528329 0.000000
        local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-4656.063477, -734.348145, 640.03125), Ang = Angle(0, 0, 0) })
        local checkpointTrigger4 = ents.Create("trigger_once")
        checkpointTrigger4:SetupTrigger(
            Vector(-4656.063477, -734.348145, 704.031250),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger4.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint4)
        end


    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
