if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_crossbow"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 12,
        ["Grenade"] = 3,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 1,
        ["XBowBolt"] = 4
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {
    ["weapon_pistol"] = true -- The weapon is not a part of any spawner template so we have to remove it here
}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_physcannon"] = true,
    ["global_newgame_spawner_shotgun"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_ar2"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_spawner_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(1130, 1845, -247),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(1088.5, 1806.5, -195.49),
            Mins = Vector(-112, -140, -60),
            Maxs = Vector(112, 140, 60)
        }
    },
    {
        Pos = Vector(1203, 1911, 141),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(1311, 1844, 192),
            Mins = Vector(-30, -180, -60),
            Maxs = Vector(30, 180, 60)
        }
    },
    {
        Pos = Vector(569, 2776, 265),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(586, 2776, 312),
            Mins = Vector(-111, -87, -48),
            Maxs = Vector(111, 87, 48)
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT