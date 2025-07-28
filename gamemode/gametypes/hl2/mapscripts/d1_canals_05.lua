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
    { -- At the big ammo crate with citizen
        Pos = Vector(4240.543945, 3220.031982, -473.430939),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(4236.846191, 3261.946289, -474.814972),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180)
        }
    },
    { -- Airboat location
        Pos = Vector(7352.527344, 1597.768555, -447.968750),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(6770.862793, 1569.191040, -447.968750),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180)
        }
    }
}

local function FreezeEntitiesAt(pos, extent)
    local foundEnts = ents.FindInBox(pos - extent, pos + extent)
    for _, v in pairs(foundEnts) do
        local physObj = v:GetPhysicsObject()
        if IsValid(physObj) then
            physObj:EnableMotion(false)
        end
    end
end

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName(
            "rotate_guncave_exit_wheel",
            function(ent)
                ent:Fire("Unlock")
                ent:Fire("AddOutput", "OnPressed relay_airboat_gateopen,Trigger")
                ent:Fire("AddOutput", "OnPressed ss_arlene_opengate,Kill") -- In case the player opens it dont play the scene.
            end
        )

        -- Disable motion of some entities, they are odd to walk on in multiplayer.
        FreezeEntitiesAt(Vector(4172.168457, 5346.647461, -124.435822), Vector(10, 10, 10))
        FreezeEntitiesAt(Vector(4397.086914, 5241.035645, -121.793793), Vector(10, 10, 10))
        FreezeEntitiesAt(Vector(4246.002441, 4931.557129, -121.530907), Vector(10, 10, 10))
    end
end

return MAPSCRIPT