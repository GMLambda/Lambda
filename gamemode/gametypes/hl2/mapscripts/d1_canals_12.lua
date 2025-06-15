if SERVER then
    AddCSLuaFile()
end

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
    ["global_newgame_spawner_smg1"] = true,
    ["global_newgame_spawner_357"] = true,
}

MAPSCRIPT.Checkpoints = {
    { -- Before jump
        Pos = Vector(-961.568787, -1598.274902, 192.031250),
        Ang = Angle(0, 0, 0),
        RenderPos = Vector(-496.403473, -2616.393066, 142.600739),
        Vehicle = {
            Pos = Vector(-845.746704, -1628.464966, 120.773956),
            Ang = Angle(0, -180, 0)
        },
        Trigger = {
            Pos = Vector(-520.426453, -2655.423828, 83.702911),
            Mins = Vector(-500, -200, 0),
            Maxs = Vector(500, 200, 280)
        }
    }
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT