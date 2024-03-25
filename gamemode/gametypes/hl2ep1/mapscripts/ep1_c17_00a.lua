if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_physcannon", "weapon_pistol", "weapon_shotgun"},
    Ammo = {
        ["Pistol"] = 18,
        ["Buckshot"] = 12
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["door_blocker"] = true,
    ["suit"] = true,
    ["physcannon"] = true,
    ["weapons"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(1161.264038, 4318.854980, 628.031250),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(1161.264038, 4318.854980, 628.031250),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 100)
        }
    }
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- Prevent door from closing when entering the elevator waiting room
        ents.WaitForEntityByName("math_count_door", function(ent)
            ent:Remove()
        end)

        -- Add checkpoint in elevator wait room
        ents.WaitForEntityByName("trigger_door_close", function(ent)
            ent.OnStartTouch = function()
                local elevfightcp = GAMEMODE:CreateCheckpoint(Vector(4436, 3578, 414), Angle(0, 90, 0))
                GAMEMODE:SetPlayerCheckpoint(elevfightcp)
            end
        end)

        -- Remove default elevator player entry trigger
        ents.WaitForEntityByName("trigger_elevator_player", function(ent)
            ent:Remove()
        end)

        -- Add a new one with a teamwait value
        local elevTrigger = ents.Create("trigger_once")
        elevTrigger:SetupTrigger(Vector(4644, 3584, 481.5), Angle(0, 0, 0), Vector(-100, -100, -50), Vector(100, 100, 50))
        elevTrigger:SetKeyValue("teamwait", "1")
        elevTrigger.OnTrigger = function(trigger)
            TriggerOutputs({{"counter_elevator", "Add", 0.0, "1"}})
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT