if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_rpg",
        "weapon_pistol",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_357",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["lambda_health"] = 1,
        ["XBowBolt"] = 9,
        ["AR2"] = 60,
        ["SMG1_Grenade"] = 1,
        ["Buckshot"] = 18,
        ["Pistol"] = 18,
        ["RPG_Round"] = 3,
        ["357"] = 12,
    },
    Armor = 45,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["base_gate_door"] = {"Close"}, -- Dont close outside gate after battle
    ["changelevel_to_12a_door"] = {"Close"} -- Keep the doors into the changelevel room open
}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["startitems"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-1219, -3919, -114),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-654, -5984, -240),
            Mins = Vector(-285, -160, -80),
            Maxs = Vector(285, 160, 80)
        }
    },
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- TODO: Set checkpoints based on when and which buildings/areas get destroyed by striders
    -- for now, outside the base will do :)

    -- Simplify triggers near the changelevel
    for k, v in pairs(ents.FindByPos(Vector(162, -8860, -256), "trigger_multiple")) do
        print(k, v)
        if v:GetInternalVariable("filtername") == "" then
            print("removed")
            v:Remove()
        end
    end

    ents.WaitForEntityByName("changelevel_to_12a_counter", function(ent)
        ent:SetKeyValue("max", "1")
    end)
end

return MAPSCRIPT