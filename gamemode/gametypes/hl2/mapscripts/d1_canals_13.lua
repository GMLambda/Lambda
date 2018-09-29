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
    ["canals_trigger_elitrans"] = true, -- Do not changelevel based on the output.
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- TODO: Duplicate canals_npc_reservoircopter01 (player / 2) times
        -- TODO: Trigger helicopter OnDeath outputs only if all of them are dead.

        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3435.695557, 1247.184448, -385.343903), Ang = Angle(0, 90, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(3425.643555, 2139.872314, -476.733490),
            Angle(0, 0, 0),
            Vector(-200, -400, 0),
            Vector(200, 400, 280)
        )
        --checkpointTrigger1:RemoveEffects(EF_NODRAW)
        checkpointTrigger1.OnTrigger = function()
            GAMEMODE:SetVehicleCheckpoint(Vector(3437.813477, 1579.182251, -455.238220), Angle(0, -90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- We gotta place a giant changelevel trigger here, the other one is dangling in the air and uses Input instead of touch.
        -- -1024.000000 -6656.000000 -1262.920044
        -- *16
        local changelevelTrigger = ents.CreateSimple("trigger_changelevel", {
            Pos = Vector(-1024.000000, -6656.000000, -1262.920044),
            Ang = Angle(0, 0, 0),
            Model = "*16",
            KeyValues =
            {
                ["map"] = "d1_eli_01",
                ["landmark"] = "canals_trans_13_eli",
            }
         })
         changelevelTrigger:Spawn()

         ents.WaitForEntityByName("lambda_canals_portal_elitrans", function(ent)
             DbgPrint("Fixing visibility")
             ent:Fire("Open")
         end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
