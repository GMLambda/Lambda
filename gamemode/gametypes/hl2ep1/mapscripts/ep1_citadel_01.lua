AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_physcannon"
    },
    Ammo =
    {
    },
    Armor = 0,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
}

MAPSCRIPT.EntityFilterByName =
{
}

function MAPSCRIPT:Init()

    DbgPrint("MapScript EP1")

end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- -4367.901855 7960.572266 2520.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-4367.901855, 7960.572266, 2520.031250), Angle(0, 45, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-4367.901855, 7960.572266, 2520.031250),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 100)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- -4860.789063 3407.795166 2592.708008
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-4860.789063, 3407.795166, 2592.708008), Angle(0, 45, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-4860.789063, 3407.795166, 2592.708008),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 100)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

end

return MAPSCRIPT