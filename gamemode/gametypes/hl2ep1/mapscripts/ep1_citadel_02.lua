AddCSLuaFile()
local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.DefaultLoadout = 
{
    Weapons = {
        "weapon_physcannon"
    },
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = 
{
    ["global_newgame_template_base_items"] = true,
}

MAPSCRIPT.GlobalStates =
{
    ["super_phys_gun"] = GLOBAL_ON,
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT