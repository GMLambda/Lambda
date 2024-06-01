if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_frag",
        "weapon_357",
        "weapon_shotgun",
        "weapon_pistol",
        "weapon_smg1",
    },
    Ammo = {
        ["SMG1"] = 45,
        ["Buckshot"] = 6,
        ["Pistol"] = 18,
        ["Grenade"] = 3,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 0,
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