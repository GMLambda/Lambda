AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
    },
    Ammo =
    {
        ["Pistol"] = 60,
        ["SMG1"] = 60,
        ["357"] = 3,
    },
    Armor = 0,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["global_newgame_entmaker"] = true,
    ["spawnitems_template"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-961.568787, -1598.274902, 192.031250), Ang = Angle(0, 0, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-520.426453, -2655.423828, 83.702911),
            Angle(0, 0, 0),
            Vector(-400, -200, 0),
            Vector(400, 200, 280)
        )
        checkpointTrigger1.OnTrigger = function()
            GAMEMODE:SetVehicleCheckpoint(Vector(-845.746704, -1628.464966, 120.773956), Angle(0, -180, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
