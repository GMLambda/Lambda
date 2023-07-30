if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow", "weapon_bugbait"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
        ["XBowBolt"] = 4
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["antlion_allied"] = GLOBAL_ON
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(1726.193115, -3289.614502, 1280.03125),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1726.193115, -3289.614502, 1280.03125),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 200),
        }
    },
    {
        Pos = Vector(1645.749756, -2053.893066, 1600.687744),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1645.749756, -2053.893066, 1600.687744),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 200),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName("tower_4_spawner", function(ent)
            ent:Fire("ForceSpawn")
            ent:SetName("lambda_tower_4_spawner")
        end)

        ents.WaitForEntityByName("fallback_spawner_1", function(ent)
            ent:Fire("ForceSpawn")
            ent:SetName("lambda_fallback_spawner_1")
        end)

        -- Enable the changelevel trigger like it would normally.
        ents.WaitForEntityByName("changelevel_01-02", function(ent)
            ent:SetKeyValue("spawnflags", "1") -- Remove no-touch
            ent:Fire("Enable")
        end)

        -- Rock falling at the end
        GAMEMODE:WaitForInput("relay_start_rockfall", "Trigger", function(ent)
            TriggerOutputs({{"ambient_rockfall_creak", "PlaySound", 0, ""}, {"door_2", "Unlock", 0, ""}})

            return true
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT