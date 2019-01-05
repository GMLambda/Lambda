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
        "weapon_physcannon",
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 3,
    },
    Armor = 60,
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
    --["test_name"] = true,
    ["player_spawn_template"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- 2849.690674 -1397.864624 -3839.968750
        ents.WaitForEntityByName("null_filter", function(ent)
            ent:Remove()
        end)

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(2643.776611, -1465.673584, -3839.968750), Angle(0, 90, 0))
        checkpoint1:SetVisiblePos(Vector(3005.009521, -1394.904053, -3783.968750))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(3007.881836, -1393.500732, -3783.968750),
            Angle(0, 0, 0),
            Vector(-50, -50, 0),
            Vector(50, 50, 70)
        )
        checkpointTrigger1.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(2018.717896, -1513.990112, -3839.968750), Angle(0, 90, 0))
        checkpoint2:SetVisiblePos(Vector(2029.538086, -1425.406128, -3839.968750))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(2029.538086, -1425.406128, -3839.968750),
            Angle(0, 0, 0),
            Vector(-90, -100, 0),
            Vector(70, 200, 50)
        )
        checkpointTrigger2.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
