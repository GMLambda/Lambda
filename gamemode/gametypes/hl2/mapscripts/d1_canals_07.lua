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
        "weapon_smg1",
    },
    Ammo =
    {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
    },
    Armor = 0,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["global_newgame_entmaker"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(11292.084961, 2207.724365, -255.968750), Angle(0, -90, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(11296.274414, 2074.708008, -255.968750),
            Angle(0, 0, 0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(10367.498047, 1265.902466, -487.621826), Angle(0, 90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- Subtile rush blocking.
        ents.CreateSimple("prop_physics", {
            Model = "models/props_wasteland/laundry_washer003.mdl",
            Pos = Vector(7780.393555, 1381.725220, -228.653198),
            Ang = Angle(0, -90, 0),
            MoveType = MOVETYPE_NONE,
            SpawnFlags = SF_PHYSPROP_MOTIONDISABLED,
            Flags = FL_STATICPROP,
        })

        -- Remove the default explose barrels, too easy to shoot from the gate.
        local searchPos = Vector(6975.288574, 1361.227783, -255.968735)
        for _,v in pairs(ents.FindInBox(searchPos - Vector(250, 250, 0), searchPos + Vector(255, 255, 100))) do
            if v:GetClass() == "prop_physics" and v:GetModel() == "models/props_c17/oildrum001_explosive.mdl" then
                v:Remove()
            end
        end

        -- Create better positioned ones.

        -- 6899.897461 1423.682495 -255.634171, 0.003 -171.758 0.005
        ents.CreateSimple("prop_physics", {
            Model = "models/props_c17/oildrum001_explosive.mdl",
            Pos = Vector(6991.625488, 1304.797119, -255.640411),
        })

        -- 6871.656250 1421.762695 -255.474014, -0.403 136.494 0.118
        ents.CreateSimple("prop_physics", {
            Model = "models/props_c17/oildrum001_explosive.mdl",
            Pos = Vector(7020.829102, 1305.285522, -255.544678),
        })

        -- Block the view to the barrels
        ents.CreateSimple("prop_physics", {
            Model = "models/props_debris/metal_panel01a.mdl",
            Pos = Vector(7050.838379, 1287.056885, -231.276840),
            Ang = Angle(6.208, -89.358, 90.071),
        })

        ents.CreateSimple("prop_physics", {
            Model = "models/props_c17/oildrum001.mdl",
            Pos = Vector(7131.379883, 1305.574463, -255.968750),
        })

        ents.CreateSimple("prop_physics", {
            Model = "models/props_c17/oildrum001.mdl",
            Pos = Vector(7089.489258, 1304.665649, -255.525589),
        })

        -- Additional fancy
        ents.CreateSimple("prop_dynamic", {
            Model = "models/props_buildings/row_res_1_fullscale.mdl",
            Pos = Vector(9748.061523, -1349.575928, -6.638969),
            MoveType = MOVETYPE_NONE,
        })


    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

-- spillway_cop1

function CreateDropship()
    local landing = ents.Create("info_target")
    landing:SetPos(Vector(8791.229492, 240.316772, -255.968750))
    landing:SetName("lambda_landing_1")
    landing:Spawn()

    local track1 = ents.Create("path_track")
    track1:SetPos(Vector(5090.260254, -4773.803223, 342.677246))
    track1:SetName("lambda_track_1")
    track1:SetKeyValue("target", "lambda_track_2")
    track1:Spawn()
    track1:Activate()

    local track2 = ents.Create("path_track")
    track2:SetPos(Vector(11300.325195, 1308.573486, 138.682419))
    track2:SetName("lambda_track_2")
    track2:SetKeyValue("target", "lambda_track_3")
    track2:Spawn()
    track2:Activate()

    local track3 = ents.Create("path_track")
    track3:SetPos(Vector(8555.336914, 269.825989, 25.706255))
    track3:SetName("lambda_track_3")
    --track3:SetKeyValue("target", "lambda_track_4")
    track3:Spawn()
    track3:Activate()

    local track4 = ents.Create("path_track")
    track4:SetPos(Vector(6976.248535, 1049.134155, 661.333191))
    track4:SetName("lambda_track_4")
    track4:SetKeyValue("target", "lambda_track_5")
    track4:Spawn()
    track4:Activate()

    local track5 = ents.Create("path_track")
    track5:SetPos(Vector(8382.391602, 579.510437, 183.660080))
    track5:SetName("lambda_track_5")
    --track5:SetKeyValue("target", "lambda_landing_1")
    track5:Spawn()
    track5:Activate()

    local ship = ents.Create("npc_combinedropship")
    ship:SetPos(Vector(1623.408936, -6077.656250, 491.766144))
    ship:SetKeyValue("NPCTemplate", "spillway_cop1")
    ship:SetKeyValue("NPCTemplate2", "spillway_cop1")
    ship:SetKeyValue("NPCTemplate3", "spillway_cop1")
    ship:SetKeyValue("NPCTemplate4", "spillway_cop1")
    ship:SetKeyValue("NPCTemplate5", "spillway_cop1")
    ship:SetKeyValue("NPCTemplate6", "spillway_cop1")
    ship:SetKeyValue("LandTarget", "lambda_landing_1")
    ship:SetKeyValue("InitialSpeed", "600")
    ship:SetKeyValue("CrateType", "1")
    ship:SetKeyValue("target", "lambda_track_1")
    ship:SetKeyValue("spawnflags", "16")
    ship:Spawn()
    --ship:Fire("StartScripting")
    ship:Fire("FlyToSpecificTrackViaPath", "lambda_track_1")
    --ship:Fire("LandTakeCrate", "6")

end

return MAPSCRIPT
