if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_frag",
        "weapon_pistol",
        "weapon_crowbar",
        "weapon_crossbow",
        "weapon_ar2",
        "weapon_357",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["XBowBolt"] = 4,
        ["AR2"] = 50,
        ["lambda_health"] = 1,
        ["Buckshot"] = 30,
        ["Grenade"] = 3,
        ["357"] = 6,
        ["SMG1"] = 90,
    },
    Armor = 45,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["citizen_warehouse_door_0"] = {"Lock", "Close"},
    ["door.garage.main"] = {"Close"} -- Maybe this keeps the garage open?
}

MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems"] = true,
    ["clip.door.garage.main"] = true -- Take care of garage vehicle clip
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(603, -9186, 77),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(510, -9196, 121),
            Mins = Vector(-181, -74, -46),
            Maxs = Vector(181, 74, 46)
        }
    },
    {
        Pos = Vector(-251, -9586, 206),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-238, -9574, 246),
            Mins = Vector(-80, -172, -54),
            Maxs = Vector(80, 172, 54)
        }
    },
    {
        Pos = Vector(-1483, -9593, 80),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-1351, -9716, 117),
            Mins = Vector(-167, -244, -75),
            Maxs = Vector(167, 244, 75)
        }
    },
    {
        Pos = Vector(195, -8493, 80),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(82, -8531, 144),
            Mins = Vector(-10, -70, -32),
            Maxs = Vector(10, 70, 32)
        }
    },
    {
        Pos = Vector(-876, -7222, 77),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-738, -7197, 132),
            Mins = Vector(-257, -111, -55),
            Maxs = Vector(257, 111, 55)
        }
    },
    {
        Pos = Vector(2807, 1735, 92),
        Ang = Angle(0, 0, 0),
        WeaponAdditions = {"weapon_rpg"},
        Trigger = {
            Pos = Vector(2589, 1274, 128),
            Mins = Vector(-65, -536, -64),
            Maxs = Vector(65, 536, 64)
        }
    }
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    local cp_garage = GAMEMODE:CreateCheckpoint(Vector(163, -8971, 75))
    ents.WaitForEntityByName("trigger.alyx.lead.to.garage", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp_garage, activator)
        end
    end)
end

return MAPSCRIPT