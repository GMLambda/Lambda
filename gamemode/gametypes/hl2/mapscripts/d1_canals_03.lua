AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_lambda_medkit",
        "weapon_crowbar",
        "weapon_pistol",
    },
    Ammo =
    {
        ["Pistol"] = 18,
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

MAPSCRIPT.ImportantPlayerNPCNames =
{
    ["matt"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["global_newgame_template"] = true,
}

function MAPSCRIPT:PostInit()

    if SERVER then

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-722.162354, 1341.204834, -831.968750), Angle(0, 135, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-722.162354, 1341.204834, -831.968750),
            Angle(0, 0, 0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-1368.427856, -69.149689, -1023.968750), Angle(0, 0, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-1058.438110, -66.407013, -959.968750),
            Angle(0, 0, 0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end

        -- Let him stay alive if no one kills him.
        ents.RemoveByClass("trigger_once", Vector(378, 2620, -770))

        local matt
        ents.WaitForEntityByName("matt", function(ent)
            matt = ent
            -- The NPC doesn't start with 100 health.
            matt:SetHealth(100)
        end)

        GAMEMODE:WaitForInput("door_manhack_break_1p", "EnableMotion", function(ent)
            if IsValid(matt) then
                -- No longer relevant when this input fires.
                GAMEMODE:UnregisterMissionCriticalNPC(matt)
            end
        end)

        -- Rename it, we fire it via a different output
        ents.WaitForEntityByName("math_manhack_death_coutner", function(ent)
            ent:SetName("stub_math_manhack_death_coutner")
        end)

        ents.WaitForEntityByName("underground_script_matt_spawn_mh1", function(ent)
            ent:Fire("AddOutput", "OnAllSpawnedDead logic_matt_survival,Trigger")
        end)

        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(-1833.402344, -775.765564, -895.968750), Angle(0, -110, 0))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(-1808.799927, -958.450073, -895.968750),
            Angle(0, 0, 0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger3.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3, activator)
        end

        -- -446.415466 -526.288147 -1017.968750
        local checkpoint4 = GAMEMODE:CreateCheckpoint(Vector(-347.239502, -525.000366, -1017.968750), Angle(0, -180, 0))
        local checkpointTrigger4 = ents.Create("trigger_once")
        checkpointTrigger4:SetupTrigger(
            Vector(-446.415466, -526.288147, -1017.968750),
            Angle(0, 0, 0),
            Vector(-60, -60, 0),
            Vector(60, 60, 60)
        )
        checkpointTrigger4.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint4, activator)
        end

        local a = ents.CreateSimple("prop_physics_override", {
            Pos = Vector(-2153.951416, -852.403381, -1028.920410),
            Ang = Angle(0.107, -1.445, 8.021),
            Model = "models/props_wasteland/dockplank01a.mdl",
            SpawnFlags = bit.bor(2, 8),
            KeyValues = { ["health"] = 0, },
            UnFreezable = true,
        })
        a:Activate()

        local b = ents.CreateSimple("prop_physics_override", {
            Pos = Vector(-2133.457275, -851.055847, -1028.304565),
            Ang = Angle(-0.798, 175.696, -7.717),
            Model = "models/props_wasteland/dockplank01b.mdl",
            SpawnFlags = bit.bor(2, 8),
            KeyValues = { ["health"] = 0, },
            UnFreezable = true,
        })
        b:Activate()

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
