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

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["startitems"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")
end

return MAPSCRIPT