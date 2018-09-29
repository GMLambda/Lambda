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
    ["spawn_items_template"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- 1921.614014 -5632.266602 320.031250
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1921.614014, -5632.266602, 320.031250), Ang = Angle(0, 180, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(1921.614014, -5632.266602, 320.031250),
            Angle(0, 0, 0),
            Vector(-110, -110, 0),
            Vector(110, 110, 100)
        )
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- 896.339966 -4236.764160 384.031250
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(830.641296, -4235.453125, 128.031250), Ang = Angle(0, 90, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(831.859619, -4104.012695, 128.031250),
            Angle(0, 0, 0),
            Vector(-20, -20, 0),
            Vector(20, 20, 100)
        )
        checkpointTrigger2.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        -- 1793.683350 -3479.405762 320.031250
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1793.683350, -3479.405762, 320.031250), Ang = Angle(0, 0, 0) })
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(1793.683350, -3479.405762, 320.031250),
            Angle(0, 0, 0),
            Vector(-100, -80, 0),
            Vector(100, 80, 100)
        )
        checkpointTrigger3.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

        -- 1600.604126 -3304.045898 -63.968750
        local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1597.989380, -3329.118408, -63.968750), Ang = Angle(0, 0, 0) })
        local checkpointTrigger4 = ents.Create("trigger_once")
        checkpointTrigger4:SetupTrigger(
            Vector(1597.989380, -3329.118408, -63.968750),
            Angle(0, 0, 0),
            Vector(-60, -60, 0),
            Vector(60, 60, 100)
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
