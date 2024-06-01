if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_shotgun",
        "weapon_smg1",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_357",
    },
    Ammo = {
        ["XBowBolt"] = 4,
        ["AR2"] = 30,
        ["SMG1_Grenade"] = 3,
        ["Pistol"] = 20,
        ["SMG1"] = 45,
    },
    Armor = 30,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_base_items"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")
end

return MAPSCRIPT