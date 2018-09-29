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
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
}

MAPSCRIPT.GlobalStates =
{
    ["antlion_allied"] = GLOBAL_ON,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- Enable the changelevel trigger like it would normally.
        ents.WaitForEntityByName("changelevel_01-02", function(ent)
            ent:SetKeyValue("spawnflags", "1") -- Remove no-touch
            ent:Fire("Enable")
        end)

        --1726.193115 -3289.614502 1344.031250
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1726.193115, -3289.614502, 1280.03125), Ang = Angle(0, 0, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(1726.193115, -3289.614502, 1280.03125),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        --2918.824219 -3629.748779 1344.031250
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2918.824219, -3629.748779, 1280.03125), Ang = Angle(0, 0, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(3940.151855, -3635.220215, 1312.03125),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger2.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        --1645.749756 -2053.893066 1664.687744
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1645.749756, -2053.893066, 1600.687744), Ang = Angle(0, 0, 0) })
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(1645.749756, -2053.893066, 1600.687744),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 200)
        )
        checkpointTrigger3.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

        -- Rock falling at the end
        GAMEMODE:WaitForInput("relay_start_rockfall", "Trigger", function(ent)
            TriggerOutputs({
                {"ambient_rockfall_creak", "PlaySound", 0, ""},
                {"door_2", "Unlock", 0, ""},
            })
            return true
        end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
