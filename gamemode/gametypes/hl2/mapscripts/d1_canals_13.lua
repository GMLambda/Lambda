if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
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
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_357"] = true,
    ["canals_trigger_elitrans"] = true -- Do not changelevel based on the output.
}

MAPSCRIPT.Checkpoints = {
    { -- After gate
        Pos = Vector(3435.695557, 1247.184448, -385.343903),
        Ang = Angle(0, 90, 0),
        RenderPos = Vector(3369.119873, 2166.538818, -367.946716),
        Vehicle = {
            Pos = Vector(3437.813477, 1579.182251, -455.238220),
            Ang = Angle(0, -90, 0)
        },
        Trigger = {
            Pos = Vector(3425.643555, 2139.872314, -476.733490),
            Mins = Vector(-200, -400, 0),
            Maxs = Vector(200, 400, 280)
        }
    }
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        -- TODO: Duplicate canals_npc_reservoircopter01 (player / 2) times
        -- TODO: Trigger helicopter OnDeath outputs only if all of them are dead.

        -- We gotta place a giant changelevel trigger here, the other one is dangling in the air and uses Input instead of touch.
        -- -1024.000000 -6656.000000 -1262.920044
        -- *16
        local changelevelTrigger = ents.CreateSimple("trigger_changelevel", {
            Pos = Vector(-1024.000000, -6656.000000, -1262.920044),
            Ang = Angle(0, 0, 0),
            Model = "*16",
            KeyValues = {
                ["map"] = "d1_eli_01",
                ["landmark"] = "canals_trans_13_eli"
            }
        })

        changelevelTrigger:Spawn()

        ents.WaitForEntityByName("lambda_canals_portal_elitrans", function(ent)
            DbgPrint("Fixing visibility")
            ent:Fire("Open")
        end)
    end
end

function MAPSCRIPT:FindUseEntity(ply, engineEnt)
    -- Workaround for: https://github.com/Facepunch/garrysmod-issues/issues/6480
    -- Remove this once it is fixed in GMod.
    if IsValid(engineEnt) and engineEnt:GetName() == "water_control_lever" then
        -- For some reason it picks up the wrong entity which is next to it, return the correct one.
        return ents.FindFirstByName("gate_control_lever")
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT