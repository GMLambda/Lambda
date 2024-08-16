if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_crowbar",
        "weapon_frag",
        "weapon_physcannon",
        "weapon_smg1",
        "weapon_357",
        "weapon_pistol",
        "weapon_shotgun",
    },
    Ammo = {
        ["Buckshot"] = 20,
        ["Grenade"] = 3,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 30,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems_template"] = true,
    ["elevator_exit_gate_door_close_rl"] = true, -- (hopefully) delete relay that handles door closing after the elevator sequence
    ["bucket_tunnel_clip"] = true
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-3430, -3312, 1069),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-3444, -3480, -948),
            Mins = Vector(-170, -95, -140),
            Maxs = Vector(170, 95, 140)
        }
    },
    {
        Pos = Vector(-964, -2519, -749),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-1002, -2485, -641),
            Mins = Vector(-150, -105, -128),
            Maxs = Vector(150, 105, 128)
        }
    },
    {
        Pos = Vector(5305, -5140, -347),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(5208, -5152, -320),
            Mins = Vector(-24, -47, -35),
            Maxs = Vector(24, 47, 35)
        }
    },
    {
        Pos = Vector(3042, -7176, -1533),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(3125, -7152, -1386),
            Mins = Vector(-26, -127, -106),
            Maxs = Vector(26, 127, 106)
        }
    },
    {
        Pos = Vector(1483, -8533, -1788),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1528, -8188, -1626),
            Mins = Vector(-282, -135, -160),
            Maxs = Vector(282, 135, 160)
        }
    },
    {
        Pos = Vector(1168, -9901, -507),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1193, -9932, -416),
            Mins = Vector(-105, -75, -95),
            Maxs = Vector(105, 75, 95)
        }
    },
    {
        Pos = Vector(4132, -8943, -572),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(4012, -9116, -500),
            Mins = Vector(-80, -133, -77),
            Maxs = Vector(80, 133, 77)
        }
    }
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- TODO: Team wait for that train to go downhill?
end

return MAPSCRIPT