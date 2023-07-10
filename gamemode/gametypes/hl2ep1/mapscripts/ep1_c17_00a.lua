if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_physcannon", "weapon_pistol", "weapon_shotgun"},
    Ammo = {
        ["Pistol"] = 18,
        ["Buckshot"] = 12
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["door_blocker"] = true,
    ["suit"] = true,
    ["physcannon"] = true,
    ["weapons"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

function MAPSCRIPT:PostInit()
    if SERVER then
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(4352, -4260, -119), Angle(0, 90, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(4292, -4130, -119), Angle(0, 0, 0), Vector(-25, -25, 0), Vector(25, 25, 100))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(1161.264038, 4318.854980, 628.031250), Angle(0, 90, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(Vector(1161.264038, 4318.854980, 628.031250), Angle(0, 0, 0), Vector(-25, -25, 0), Vector(25, 25, 100))

        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT