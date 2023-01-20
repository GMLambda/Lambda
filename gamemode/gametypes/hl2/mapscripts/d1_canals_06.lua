if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_entmaker"] = true
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- 140.128403 6230.728516 -91.836014
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-244.051270, 5727.869141, -237.508698), Angle(0, 90, 0))
        checkpoint1:SetVisiblePos(Vector(236.710632, 6244.615234, -75.189445))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(140.128403, 6230.728516, -91.836014), Angle(0, 0, 0), Vector(-550, -500, -150), Vector(350, 100, 180))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(-405.258606, 5841.114258, -212.960327), Angle(0, 0, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT