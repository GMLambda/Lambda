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
    ["player_spawn_items_maker"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-1478.292725, -1717.604614, 104.600342),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-1478.292725, -1717.604614, 104.600342),
            Mins = Vector(-130, -130, 0),
            Maxs = Vector(130, 130, 100),
        }
    },
    {
        Pos = Vector(299.584564, -1424.746704, -287.968750),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(227.741821, -1265.945923, -287.968750),
            Mins = Vector(-130, -130, 0),
            Maxs = Vector(130, 130, 100),
        }
    },
    {
        Pos = Vector(1488.074829, -900.734985, 80.031250),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(1537.006226, -813.546021, 80.031250),
            Mins = Vector(-130, -130, 0),
            Maxs = Vector(130, 130, 100),
        }
    },
    {
        Pos = Vector(1286.711914, 610.125366, 400.031250),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(1392.383179, -76.121971, 372.128113),
            Mins = Vector(-500, -500, 0),
            Maxs = Vector(500, 500, 250),
        }
    },
    {
        Pos = Vector(1650.219482, -89.667931, 624.031250),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1650.219482, -89.667931, 624.031250),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT