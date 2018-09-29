AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
        "weapon_physcannon",
        "weapon_frag",
        "weapon_shotgun",
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 3,
        ["Grenade"] = 1,
        ["Buckshot"] = 12,
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
    ["warehouse_citizen"] = { "Kill" },
    ["warehouse_citizen_jacobs"] = { "Kill" },
    ["winston"] = { "Kill" },
    ["citizen_warehouse_door_1"] = { "Close", "Lock" },
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["player_spawn_items"] = true,
    ["trigger_changelevel"] = true, -- We use a better one.
    ["invulnerable"] = true, -- Why not.
}

MAPSCRIPT.ImportantPlayerNPCNames =
{
    ["warehouse_citizen_jacobs"] = true,
    ["warehouse_citizen"] = true,
    ["warehouse_citizen_leon"] = true,
    ["warehouse_nurse"] = true,
    ["winston"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        ents.WaitForEntityByName("warehouse_citizen_jacobs", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("warehouse_citizen_leon", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("warehouse_citizen", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("warehouse_soldier", function(ent)
            DbgPrint("Solider: " .. tostring(ent))
        end)

        -- Fix scaling affect math_counter by renaming it and fire on OnAllSpawnedDead instead, since they are set to 2
        ents.WaitForEntityByName("end_reinforcements_counter", function(ent)
            ent:SetName("lambda_end_reinforcements_counter")
        end)

        ents.WaitForEntityByName("warehouse_deadcombine_counter", function(ent)
            ent:SetName("lambda_warehouse_deadcombine_counter")
        end)

        -- -6381.103027 8103.064453 896.031250
        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-6533.443848, 8131.516602, 896.031250), Ang = Angle(0, 0, 0) })
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-6381.103027, 8103.064453, 896.031250),
            Angle(0, 0, 0),
            Vector(-100, -300, 0),
            Vector(100, 300, 170)
        )
        checkpointTrigger1.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- Make sure to substract on our renamed math_counter.
        ents.WaitForEntityByName("end_reinforcements_trigger", function(ent)
            ent:Fire("AddOutput", "OnTrigger lambda_warehouse_deadcombine_counter,Subtractw,2")
        end)

        -- Because those npcs are created via point_template, this is a good hooking spot to correct the output.
        GAMEMODE:WaitForInput("lcs_winston", "Start", function(ent)
            for _,v in pairs(ents.FindByName("warehouse_soldier")) do
                v:Fire("AddOutput", "OnDeath lambda_warehouse_deadcombine_counter,Add,1")
            end
        end)

        ents.WaitForEntityByName("end_soldier_1_maker", function(ent)
            ent:AddSpawnFlags(SF_NPCMAKER_ALWAYSUSERADIUS)
            --ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
            ent:SetName("lambda_end_soldier_1_maker")
            ent:SetKeyValue("MaxNPCCount", "2")
            ent:SetKeyValue("SpawnFrequency", "0")
            ent:SetKeyValue("Radius", 428)
            ent:SetPos(Vector(-1946.261353, 8187.082031, 955.381775))
            ent:Fire("AddOutput", "OnAllSpawnedDead lambda_end_reinforcements_counter,Add,1")
            end_soldier_1_maker = ent
        end)

        ents.WaitForEntityByName("end_soldier_2_maker", function(ent)
            ent:AddSpawnFlags(SF_NPCMAKER_ALWAYSUSERADIUS)
            --ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
            ent:SetName("lambda_end_soldier_2_maker")
            ent:SetKeyValue("MaxNPCCount", "2")
            ent:SetKeyValue("SpawnFrequency", "0")
            ent:SetKeyValue("Radius", 128)
            ent:SetPos(Vector(-1497.389404, 8514.711914, 896.0312507)) -- Lets give them a beter position.
            ent:Fire("AddOutput", "OnAllSpawnedDead lambda_end_reinforcements_counter,Add,1")
        end)

        ents.WaitForEntityByName("end_soldier_3_maker", function(ent)
            ent:AddSpawnFlags(SF_NPCMAKER_ALWAYSUSERADIUS)
            --ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
            ent:SetName("lambda_end_soldier_3_maker")
            ent:SetKeyValue("MaxNPCCount", "2")
            ent:SetKeyValue("SpawnFrequency", "0")
            ent:SetKeyValue("Radius", 328)
            --ent:Fire("AddOutput", "OnAllSpawnedDead lambda_warehouse_deadcombine_counter,Add,1")
        end)

        -- -3500.986816 7756.634766 896.031250
        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-4065.605957, 7748.239258, 896.032776), Ang = Angle(3.366, 19.338, 0.000) })
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-3500.986816, 7756.634766, 896.031250),
            Angle(0, 0, 0),
            Vector(-25, -100, 0),
            Vector(25, 100, 170)
        )
        checkpointTrigger2.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
            TriggerOutputs({
                {"lambda_end_soldier_1_maker", "Enable", 0, ""},
                {"lambda_end_soldier_2_maker", "Enable", 0, ""},
                {"lambda_end_soldier_3_maker", "Enable", 0, ""},
            })
        end

        ents.WaitForEntityByName("end_soldier_4_maker", function(ent)
            --ent:KeyValue("DisableScaling", "1")
            ent:SetPos(Vector(-2003.583618, 9071.959961, 897.031250))
            ent:AddSpawnFlags(SF_NPCMAKER_ALWAYSUSERADIUS)
            --ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
            ent:SetKeyValue("MaxNPCCount", "2")
            ent:SetKeyValue("SpawnFrequency", "1")
            ent:SetKeyValue("Radius", 60)
            ent:Fire("AddOutput", "OnAllSpawnedDead lambda_warehouse_deadcombine_counter,Add,1")
        end)
        GAMEMODE:WaitForInput("end_soldier_4_maker", "Spawn", function(ent)
            ent:Fire("Enable")
        end)

        ents.WaitForEntityByName("end_soldier_5_maker", function(ent)
            --ent:KeyValue("DisableScaling", "1")
            ent:SetPos(Vector(-1969.444214, 8991.776367, 897.031250))
            ent:AddSpawnFlags(SF_NPCMAKER_ALWAYSUSERADIUS)
            --ent:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
            ent:SetKeyValue("MaxNPCCount", "2")
            ent:SetKeyValue("SpawnFrequency", "1")
            ent:SetKeyValue("Radius", 128)
            ent:Fire("AddOutput", "OnAllSpawnedDead lambda_warehouse_deadcombine_counter,Add,1")
        end)

        GAMEMODE:WaitForInput("end_soldier_5_maker", "Spawn", function(ent)
            ent:Fire("Enable")
        end)

        ents.WaitForEntityByName("warehouse_leonleads_lcs", function(ent)
            ent:Fire("AddOutput", "OnTrigger2 !self,Resume,,2") -- Whoever gets picked as freeman, stop giving a fuck.
        end)

        -- Checkpoint
        -- -1123.785400 10358.985352 896.031250
        local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1098.884766, 10457.261719, 896.031250), Ang = Angle(0, -180, 0.000) })
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(-1123.785400, 10358.985352, 896.031250),
            Angle(0, 0, 0),
            Vector(-100, -25, 0),
            Vector(100, 25, 170)
        )
        checkpointTrigger3.OnTrigger = function()
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end


        -- Better changelevel trigger.
        local changelevelTrigger = ents.CreateSimple("trigger_changelevel", {
            Pos = Vector(-1680, 10970, 952),
            Ang = Angle(0, 0, 0),
            Model = "*40",
            KeyValues =
            {
                ["map"] = "d2_coast_01",
                ["landmark"] = "d1_town-coast",
            }
         })
         changelevelTrigger:Spawn()

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
