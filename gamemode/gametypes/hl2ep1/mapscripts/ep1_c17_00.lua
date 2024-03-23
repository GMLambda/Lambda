if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_physcannon"},
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["door_blocker"] = true,
    ["suit"] = true,
    ["physcannon"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(4352, -4260, -119),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(4292, -4130, -119),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 100)
        }
    },
    {
        Pos = Vector(3550.521240, 1506.495483, 140.031250),
        Ang = Angle(0, -180, 0),
        Trigger = {
            Pos = Vector(3500.521240, 1506.495483, 140.031250),
            Mins = Vector(-55, -25, 0),
            Maxs = Vector(55, 25, 100)
        }
    }
}

function MAPSCRIPT:PostInit()

    -- Make the door after the barnacle area open and ignore player interaction
    ents.WaitForEntityByName("barnacle_exit_door", function(ent)
        ent:RemoveSpawnFlags(8192)
        ent:AddSpawnFlags(32768)
        ent:Fire("Open")
    end)

    -- Also remove the playerclip behind the door
    ents.WaitForEntityByName("barnacle_exit_door_clip", function(ent)
        ent:Remove()
    end)

end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT