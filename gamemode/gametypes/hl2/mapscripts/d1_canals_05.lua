if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_entmaker"] = true,
    ["relay_rockfall_start"] = true -- Don't do that, its trivial.
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(4149.820313, 3446.334229, -466.530853),
        Ang = Angle(0, -66, 0),
        VisiblePos = Vector(4240.543945, 3220.031982, -473.430939),
        Trigger = {
            Pos = Vector(4236.846191, 3261.946289, -474.814972),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180),
        }
    },
    {
        Pos = Vector(7352.527344, 1597.768555, -447.968750),
        Ang = Angle(0, -90, 0),
        VisiblePos = Vector(6758.199219, 1572.104248, -447.968750),
        Trigger = {
            Pos = Vector(6770.862793, 1569.191040, -447.968750),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName("rotate_guncave_exit_wheel", function(ent)
            ent:Fire("Unlock")
            ent:Fire("AddOutput", "OnPressed relay_airboat_gateopen,Trigger")
            ent:Fire("AddOutput", "OnPressed ss_arlene_opengate,Kill") -- In case the player opens it dont play the scene.
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT