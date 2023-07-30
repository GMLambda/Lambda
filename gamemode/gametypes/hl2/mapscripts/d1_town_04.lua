if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 3,
        ["Grenade"] = 1,
        ["Buckshot"] = 12
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_template"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(1893.508423, 365.617035, -5120.287109),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(1915.561768, -19.246124, -5120.762695),
            Ang = Angle(0, 0, 0),
            Mins = Vector(-150, -50, 0),
            Maxs = Vector(150, 50, 70),
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT