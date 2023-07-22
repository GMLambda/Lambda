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

MAPSCRIPT.InputFilters = {
    ["sniper1"] = {"Kill"},
    ["sniper2"] = {"Kill"}
}

MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items_maker"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(7405.353516, 6305.318848, 0.031250),
        Ang = Angle(0, 180, 0),
        Trigger = {
            Pos = Vector(7099.762695, 6237.561523, 0.031250),
            Mins = Vector(-130, -130, 0),
            Maxs = Vector(130, 130, 100),
        }
    },
    {
        Pos = Vector(6000.681641, 6446.313477, 96.031250),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(6000.681641, 6446.313477, 96.031250),
            Mins = Vector(-130, -130, 0),
            Maxs = Vector(130, 130, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT