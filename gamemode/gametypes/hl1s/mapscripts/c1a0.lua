if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {},
    Ammo = {},
    Armor = 0,
    HEV = false
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {} --["env_global"] = true,
MAPSCRIPT.EntityFilterByName = {} --["spawnitems_template"] = true,

function MAPSCRIPT:Init()
    --TEST_DbgPrint("-- Mapscript: Template loaded --")
end

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    ----TEST_DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT