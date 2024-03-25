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
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_physcannon"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_ON
}

function MAPSCRIPT:PostInit()
    if SERVER then
        local multipleTrigger = ents.FindByPos(Vector(3424, 12808, 3696), "trigger_multiple")

        for k, v in pairs(multipleTrigger) do
            v:Remove()
        end

        local doorCloseTrigger = ents.Create("trigger_once")
        doorCloseTrigger:SetupTrigger(Vector(3424, 12808, 3696), Angle(0, 0, 0), Vector(-208, -472, -96), Vector(208, 472, 96))
        doorCloseTrigger:SetKeyValue("teamwait", "1")
        doorCloseTrigger:SetKeyValue("showwait", "0")
        doorCloseTrigger:Fire("AddOutput", "OnTrigger trigger_alyx_close_airlock,Enable,0.0,-1")

        doorCloseTrigger.OnTrigger = function(_, activator)
            local checkpoint = GAMEMODE:CreateCheckpoint(Vector(3424, 13184, 3604))
            GAMEMODE:SetPlayerCheckpoint(checkpoint, activator)
        end

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(3400, 11723, 3616), Angle(0, 0, 0))

        ents.WaitForEntityByName("trigger_player_closedoor", function(ent)
            ent:SetKeyValue("teamwait", "1")

            ent.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
            end
        end)

        ents.WaitForEntityByName("trigger_stalkercar_inside", function(ent)
            ent:SetKeyValue("teamwait", "1")
        end)

        local multipleTrigger2 = ents.FindByPos(Vector(4208, 7968, 3528), "trigger_multiple")

        for k, v in pairs(multipleTrigger2) do
            v:Remove()
        end

        local enablePull = ents.Create("trigger_once")
        enablePull:SetupTrigger(Vector(4208, 7968, 3528), Angle(0, 0, 0), Vector(-116, -80, -92), Vector(116, 80, 92))
        enablePull:Fire("AddOutput", "OnTrigger stalkerPod_Physanim,EnablePhyscannonPickup,0.0,-1")

        local pickupRelay = ents.Create("logic_relay")
        pickupRelay:SetKeyValue("spawnflags", "1") -- Trigger only once
        pickupRelay:SetName("lambda_stalkerPod_Physanim")
        pickupRelay:Fire("AddOutput", "OnTrigger spark_pod_lift_1,SparkOnce,0.0,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger ss_alyx_stalkertrain_postPod,BeginSequence,0.0,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger sound_pod_lift_1,PlaySound,0.2,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger spark_pod_lift_1,SparkOnce,0.2,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_stalkertrain_pulling,Start,0.2,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger ss_alyx_stalkertrain_prePod,BeginSequence,0.2,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger ss_alyx_stalkertrain_pullPod,BeginSequence,0.3,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger timer_nagtrapped_01,Kill,0.4,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_nagtrapped_01,Cancel,0.4,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_nagtrapped_02,Cancel,0.4,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_nagtrapped_03,Cancel,0.4,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_nagtrapped_04,Cancel,0.4,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger relay_hatch_shakebreak_1,Trigger,0.4,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_al_stalkertrain_03,Start,0.9,-1")
        pickupRelay:Fire("AddOutput", "OnTrigger lcs_al_stalkertrain_03,Start,0.9,-1")
        pickupRelay:Spawn()

        -- Missing PhysCannonAnimate outputs in Garry's Mod
        -- We have to redo the whole pulling logic to work properly
        ents.WaitForEntityByName("stalkerPod_Physanim", function(ent)
            ent:Fire("AddOutput", "OnPhysGunPickup lambda_stalkerPod_Physanim,Trigger,0.0,-1")
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT