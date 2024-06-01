if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_pistol",
        "weapon_357",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["lambda_health"] = 1,
        ["357"] = 6,
        ["AR2"] = 60,
        ["Grenade"] = 3,
        ["Buckshot"] = 18,
        ["Pistol"] = 18,
        ["XBowBolt"] = 4,
        ["SMG1"] = 90,
    },
    Armor = 45,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")
end

return MAPSCRIPT