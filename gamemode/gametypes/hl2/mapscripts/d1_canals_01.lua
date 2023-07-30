if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar"},
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["boxcar_closedoor"] = {"BeginSequence"},
    ["brush_boxcar_door_PClip"] = {"Enable"}
}

MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["start_item_template"] = true
}

MAPSCRIPT.ImportantPlayerNPCNames = {
    ["boxcar_human"] = true,
    ["boxcar_vort"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(650.433105, -6424.663086, 540.031250),
        Ang = Angle(0, 0, 0),
        VisiblePos = Vector(619.656433, -6512.142578, 540.031250),
        Trigger = {
            Pos = Vector(614.625732, -6519.078613, 540.031250),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180)
        }
    },
    {
        Pos = Vector(877.780457, 2621.807617, -55.060749),
        Ang = Angle(0, 180, 0),
        VisiblePos = Vector(853.600281, 2638.468018, 73.964828),
        Trigger = {
            Pos = Vector(855.660400, 2638.366943, 30),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 180)
        }
    },
    -- Boxcar checkpoint
    {
        Pos = Vector(447.302185, -2656.709961, 576.031250),
        Ang = Angle(0, 180, 0),
        VisiblePos = Vector(853.600281, 2638.468018, 73.964828),
        Trigger = {
            Pos = Vector(447.302185, -2656.709961, 576.031250),
            Mins = Vector(-50, -50, 0),
            Maxs = Vector(50, 50, 180)
        }
    },
    {
        Pos = Vector(473.498352, -3530.257324, 256.031250),
        Ang = Angle(0, 90, 0),
        VisiblePos = Vector(853.600281, 2638.468018, 73.964828),
        Trigger = {
            Pos = Vector(544.810791, -3423.548584, 322.719330),
            Mins = Vector(-70, -70, -50),
            Maxs = Vector(70, 70, 100)
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        local jumpBox = ents.Create("prop_physics")
        jumpBox:SetPos(Vector(363.177521, -4154.399902, 277.458130))
        jumpBox:SetAngles(Angle(0, 180, 0))
        jumpBox:SetModel("models/props_junk/wood_crate001a.mdl")
        jumpBox:Spawn()
        jumpBox:SetHealth(1000)
        local phys = jumpBox:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200)
        end

        GAMEMODE:WaitForInput(
            "boxcar_human",
            "StopScripting",
            function()
                -- No longer mission relevant.
                ents.WaitForEntityByName(
                    "boxcar_human",
                    function(ent)
                        GAMEMODE:UnregisterMissionCriticalNPC(ent)
                    end
                )

                ents.WaitForEntityByName(
                    "boxcar_vort",
                    function(ent)
                        GAMEMODE:UnregisterMissionCriticalNPC(ent)
                    end
                )
            end
        )
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT
--DbgPrint("PostPlayerSpawn")