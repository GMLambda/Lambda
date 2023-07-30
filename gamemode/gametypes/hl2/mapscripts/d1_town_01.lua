if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 3
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_template"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(2643.776611, -1465.673584, -3839.968750),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(3007.881836, -1393.500732, -3783.968750),
            Ang = Angle(0, 0, 0),
            Mins = Vector(-50, -50, 0),
            Maxs = Vector(50, 50, 70),
        }
    },
    {
        Pos = Vector(2018.717896, -1513.990112, -3839.968750),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(2029.538086, -1425.406128, -3839.968750),
            Ang = Angle(0, 0, 0),
            Mins = Vector(-90, -100, 0),
            Maxs = Vector(70, 200, 50),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- 2849.690674 -1397.864624 -3839.968750
        ents.WaitForEntityByName(
            "null_filter",
            function(ent)
                ent:Remove()
            end
        )
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT