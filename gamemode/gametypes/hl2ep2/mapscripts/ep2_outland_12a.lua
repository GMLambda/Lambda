if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_pistol",
        "weapon_rpg",
        "weapon_357",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["AR2"] = 60,
        ["Buckshot"] = 18,
        ["Grenade"] = 5,
        ["SMG1"] = 90,
        ["SMG1_Grenade"] = 1,
        ["AR2AltFire"] = 2,
        ["RPG_Round"] = 3,
        ["Pistol"] = 54,
        ["357"] = 12,
        ["XBowBolt"] = 9,
    },
    Armor = 30,
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