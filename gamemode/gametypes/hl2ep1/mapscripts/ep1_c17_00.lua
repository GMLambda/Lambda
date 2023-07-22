if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_physcannon"},
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["door_blocker"] = true,
    ["suit"] = true,
    ["physcannon"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(4352, -4260, -119),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(4292, -4130, -119),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 100)
        }
    },
    {
        Pos = Vector(3550.521240, 1506.495483, 140.031250),
        Ang = Angle(0, -180, 0),
        Trigger = {
            Pos = Vector(3500.521240, 1506.495483, 140.031250),
            Mins = Vector(-55, -25, 0),
            Maxs = Vector(55, 25, 100)
        }
    }
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT