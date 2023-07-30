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
    ["pclip_gate1"] = true,
    ["player_spawn_template"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-1468.447632, -4747.628418, 320.031250),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(-1468.447632, -4747.628418, 320.031250),
            Mins = Vector(-50, -50, 0),
            Maxs = Vector(50, 50, 130),
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT