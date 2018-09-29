AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_crowbar",
    },
    Ammo = {},
    Armor = 0,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
    ["boxcar_closedoor"] = { "BeginSequence" },
    ["brush_boxcar_door_PClip"] = { "Enable" },
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["start_item_template"] = true,
}

function MAPSCRIPT:Init()
end

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

        local boxcar_human
        local boxcar_vort
        ents.WaitForEntityByName("boxcar_human", function(ent)
            ent.ImportantNPC = true
            boxcar_human = ent
        end)

        ents.WaitForEntityByName("boxcar_vort", function(ent)
            ent.ImportantNPC = true
            boxcar_vort = ent
        end)

        GAMEMODE:WaitForInput("boxcar_human", "StopScripting", function(ent)
            DbgPrint("NPCs no longer important")
            if IsValid(boxcar_vort) then
                boxcar_vort.ImportantNPC = false
            end
            if IsValid(boxcar_human) then
                boxcar_human.ImportantNPC = false
            end
        end)

        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(650.433105, -6424.663086, 540.031250) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(614.625732, -6519.078613, 540.031250),
            Angle(0,0,0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger1.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(877.780457, 2621.807617, -55.060749), Ang = Angle(0, 180, 0) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(855.660400, 2638.366943, -51.748753),
            Angle(0,0,0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger2.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        -- 447.302185 -2656.709961 576.031250
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(447.302185, -2656.709961, 576.031250), Ang = Angle(0, 180, 0) })
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(447.302185, -2656.709961, 576.031250),
            Angle(0,0,0),
            Vector(-50, -50, 0),
            Vector(50, 50, 180)
        )
        checkpointTrigger3.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

        -- 544.810791 -3423.548584 322.719330
        local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(473.498352, -3530.257324, 256.031250), Ang = Angle(0, 90, 0) })
        local checkpointTrigger4 = ents.Create("trigger_once")
        checkpointTrigger4:SetupTrigger(
            Vector(544.810791, -3423.548584, 322.719330),
            Angle(0,0,0),
            Vector(-70, -70, -50),
            Vector(70, 70, 100)
        )
        checkpointTrigger4.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint4)
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
