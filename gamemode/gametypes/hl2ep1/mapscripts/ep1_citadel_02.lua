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
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_physcannon"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_ON
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-1657, 947, 821),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-2008, 960, 852),
            Mins = Vector(-128, -40, -52),
            Maxs = Vector(128, 40, 52)
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT