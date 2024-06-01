if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_pistol",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_357",
        "weapon_frag",
        "weapon_physcannon",
        "weapon_rpg",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["AR2"] = 60,
        ["Buckshot"] = 18,
        ["Grenade"] = 3,
        ["SMG1"] = 90,
        ["SMG1_Grenade"] = 1,
        ["AR2AltFire"] = 1,
        ["RPG_Round"] = 3,
        ["Pistol"] = 54,
        ["357"] = 6,
        ["XBowBolt"] = 4,
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