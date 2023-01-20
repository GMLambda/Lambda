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
end

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    -- Failsafe: Make sure players are in the train
    ents.WaitForEntityByName("train", function(ent)
        local pos = ent:LocalToWorld(Vector(50, 40, 8))
        local ang = ent:LocalToWorldAngles(Angle(0, 0, 0))
        ply:TeleportPlayer(pos, ang)
    end)
end

return MAPSCRIPT