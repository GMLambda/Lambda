if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol"},
    Ammo = {
        ["Pistol"] = 18
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.ImportantPlayerNPCNames = {
    ["matt"] = true
}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template"] = true
}

MAPSCRIPT.Checkpoints = {
    { -- End of narrow corridors
        Pos = Vector(-722.162354, 1341.204834, -831.968750),
        Ang = Angle(0, 135, 0),
        Trigger = {
            Ang = Angle(0, 45, 0),
            Pos = Vector(-722.162354, 1341.204834, -831.968750),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180)
        }
    },
    { -- Before the underwater part
        Pos = Vector(-1584, -800, -1048),
        Ang = Angle(0, 0, 0),
        WeaponAdditions = { "weapon_smg1" },
        Trigger = {
            Pos = Vector(-1584, -638, -976),
            Mins = Vector(-96, -32, -64),
            Maxs = Vector(96, 32, 64)
        }
    },
    { -- After the underwater part
        Pos = Vector(-1066, -65, -1014),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-1141, -64, -968),
            Mins = Vector(-27, -30, -72),
            Maxs = Vector(27, 30, 72)
        }
    },
    { -- Before the 2nd underwater part
        Pos = Vector(-1833.402344, -775.765564, -895.968750),
        Ang = Angle(0, -110, 0),
        Trigger = {
            Pos = Vector(-1808.799927, -958.450073, -895.968750),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180)
        }
    },
    { -- Before manhack and water puzzle
        Pos = Vector(-347.239502, -525.000366, -1017.968750),
        Ang = Angle(0, -180, 0),
        Trigger = {
            Pos = Vector(-446.415466, -526.288147, -1017.968750),
            Mins = Vector(-60, -60, 0),
            Maxs = Vector(60, 60, 60)
        }
    }
}

function MAPSCRIPT:PostInit()
    if SERVER then
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
            ent:SetKeyValue("EnableScaling", "1")
        end)

        ents.WaitForEntityByName("tunnel_manhack_1_maker", function(ent)
            ent:SetKeyValue("EnableScaling", "1")
            ent:SetKeyValue("spawnflags", "128")
        end)
        ents.WaitForEntityByName("tunnel_manhack_2_maker", function(ent)
            ent:SetKeyValue("EnableScaling", "1")
            ent:SetKeyValue("spawnflags", "128")
        end)
        ents.WaitForEntityByName("waterroom_manhack_1_maker", function(ent)
            ent:SetKeyValue("EnableScaling", "1")
        end)

        ents.WaitForEntityByName("rappeller_cop_1_maker", function(ent)
            ent:SetKeyValue("EnableScaling", "1")
        end)

        local a = ents.CreateSimple("prop_physics_override", {
            Pos = Vector(-2153.951416, -852.403381, -1028.920410),
            Ang = Angle(0.107, -1.445, 8.021),
            Model = "models/props_wasteland/dockplank01a.mdl",
            SpawnFlags = bit.bor(2, 8),
            KeyValues = {
                ["health"] = 0
            },
            UnFreezable = true
        })

        a:Activate()

        local b = ents.CreateSimple("prop_physics_override", {
            Pos = Vector(-2133.457275, -851.055847, -1028.304565),
            Ang = Angle(-0.798, 175.696, -7.717),
            Model = "models/props_wasteland/dockplank01b.mdl",
            SpawnFlags = bit.bor(2, 8),
            KeyValues = {
                ["health"] = 0
            },
            UnFreezable = true
        })

        b:Activate()
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT