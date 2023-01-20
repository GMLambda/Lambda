if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_entmaker"] = true,
    ["spawnitems_template"] = true
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-961.568787, -1598.274902, 192.031250), Angle(0, 0, 0))
        checkpoint1:SetVisiblePos(Vector(-496.403473, -2616.393066, 142.600739))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(-520.426453, -2655.423828, 83.702911), Angle(0, 0, 0), Vector(-500, -200, 0), Vector(500, 200, 280))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(-845.746704, -1628.464966, 120.773956), Angle(0, -180, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT