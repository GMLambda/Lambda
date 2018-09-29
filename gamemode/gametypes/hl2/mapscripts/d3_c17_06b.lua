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

        -- 2894.431396 1052.031250 64.031250
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2843.645508, 1058.373169, 64.031250), Ang = Angle(0, 0, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(2894.431396, 1052.031250, 64.031250),
            Angle(0, 0, 0),
            Vector(-20, -20, 0),
            Vector(20, 20, 100)
        )
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- 3477.289062 1116.633179 0.031250 -0.188 -90.478 0.000
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3477.289062, 1116.633179, 0.031250), Ang = Angle(0, -90, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(3477.289062, 1116.633179, 0.031250),
            Angle(0, 0, 0),
            Vector(-60, -60, 0),
            Vector(60, 60, 100)
        )
        checkpointTrigger2.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        -- 3575.494873 1570.045532 256.031250 26.014 90.459 0.000
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3648.722412, 1569.612793, 256.031250), Ang = Angle(0, 90, 0) })
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(3575.494873, 1570.045532, 256.031250),
            Angle(0, 0, 0),
            Vector(-60, -60, 0),
            Vector(60, 60, 100)
        )
        checkpointTrigger3.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

        ents.WaitForEntityByName("wench_1_lever_1", function(ent)
            ent:SetKeyValue("spawnflags", "122")
        end)

        -- 3314.308350 1882.039551 0.031250 10.966 -88.900 0.000
        local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3648.722412, 1569.612793, 256.031250), Ang = Angle(0, -90, 0) })
        local checkpointTrigger4 = ents.Create("trigger_once")
        checkpointTrigger4:SetupTrigger(
            Vector(3314.308350, 1882.039551, 0.031250),
            Angle(0, 0, 0),
            Vector(-30, -30, 0),
            Vector(30, 30, 100)
        )
        checkpointTrigger4.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint4)
        end

        ents.WaitForEntityByName("wench_2_lever_1", function(ent)
            ent:Fire("AddOutput", "OnOpen !self,Lock")
        end)

        -- 4022.167480 1330.496826 387.531250 3.706 -140.541 0.000
        local checkpoint5 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3940.753906, 1200.170898, 384.031250), Ang = Angle(0, 180, 0) })
        local checkpointTrigger5 = ents.Create("trigger_once")
        checkpointTrigger5:SetupTrigger(
            Vector(4022.167480, 1330.496826, 387.531250),
            Angle(0, 0, 0),
            Vector(-40, -40, 0),
            Vector(40, 40, 100)
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
