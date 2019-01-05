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
    },
    Ammo =
    {
        ["Pistol"] = 60,
        ["SMG1"] = 60,
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
    ["relay_locks_closegates"] = true, -- Dont close the doors if we pass thru the gate
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        for _,v in pairs(ents.FindByClass("info_player_start")) do
            v:Remove()
        end

        local playerStart = ents.Create("info_player_start")
        playerStart:SetPos(Vector(7504, -11398, -412))
        playerStart:Spawn()
        playerStart.MasterSpawn = true

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-486.748169, -329.674469, -591.968750), Angle(0, 90, 0))
        checkpoint1:SetVisiblePos(Vector(-420.171631, -97.050110, -591.968750))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-480.402649, -58.779499, -575.968750),
            Angle(0, 0, 0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger1.OnTrigger = function()
            GAMEMODE:SetVehicleCheckpoint(Vector(53.214970, -102.730621, -615.638123), Angle(0, -180, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- -841.505310 -1408.689331 -382.968750
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-841.505310, -1408.689331, -382.968750), Angle(0, 90, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-841.505310, -1408.689331, -382.968750),
            Angle(0, 0, 0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger2.OnTrigger = function()
            --GAMEMODE:SetVehicleCheckpoint(Vector(53.214970, -102.730621, -615.638123), Angle(0, -180, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        -- It looks odd when they spawn right infront of one.
        ents.WaitForEntityByName("bunker_copmaker1", function(ent)
            ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
        end)

        ents.WaitForEntityByName("bunker_copmaker2", function(ent)
            ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
        end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
