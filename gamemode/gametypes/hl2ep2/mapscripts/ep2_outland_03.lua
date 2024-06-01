if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_crowbar",
        "weapon_frag",
        "weapon_physcannon",
        "weapon_smg1",
        "weapon_357",
        "weapon_pistol",
        "weapon_shotgun",
    },
    Ammo = {
        ["Buckshot"] = 20,
        ["Grenade"] = 3,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 30,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems_template"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")
end

return MAPSCRIPT