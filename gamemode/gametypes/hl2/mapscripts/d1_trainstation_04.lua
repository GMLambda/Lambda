if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {},
    Ammo = {},
    Armor = 30,
    HEV = false
}

MAPSCRIPT.InputFilters = {
    ["logic_fade_view"] = {"Trigger"},
    ["door_inside_secret"] = {"Close", "Lock"}
}

MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["window_player_clip"] = true,
    ["trigger_knockout_teleport"] = true,
    ["ss_alyx_intro_bendover"] = true,
    ["lcs_knockout_kickdoor_2"] = true,
    ["lcs_knockout_kickdoor"] = true
}

--["npc_knockout_cop_upstairs"] = true, -- If players are still up they would see them spawn.
function MAPSCRIPT:PostInit()
    DbgPrint("PostInit")

    if SERVER then
        -- If the changelevel fires before he closed it, the position would be off.
        ents.WaitForEntityByName("citizen_DoorBracer", function(ent)
            ent:SetPos(Vector(-3082.781738, -3532.943115, 384.031250))
        end)

        ents.WaitForEntityByName("street_cop_1", function(ent)
            ent:SetName("lambda_street_cop_1")
        end)

        ents.WaitForEntityByName("street_cop_2", function(ent)
            ent:SetName("lambda_street_cop_2")
        end)

        ents.WaitForEntityByName("street_cop_3", function(ent)
            ent:SetName("lambda_street_cop_3")
        end)

        local supressKickdownEvent = true

        GAMEMODE:WaitForInput("kickdown_relay", "Trigger", function()
            if supressKickdownEvent == true then
                DbgPrint("Supressing event")

                return true
            end
        end)

        GAMEMODE:WaitForInput("ss_DoorBracer_Struggle", "Kill", function()
            if supressKickdownEvent == true then
                DbgPrint("Supressing event")

                return true
            end
        end)

        -- -3183.032227 -3624.933350 384.031250
        local doorBracerTrigger = ents.Create("trigger_multiple")
        doorBracerTrigger:SetupTrigger(Vector(-3183.032227, -3624.933350, 384.031250), Angle(0, 0, 0), Vector(-500, -200, 0), Vector(200, 300, 280))

        doorBracerTrigger.OnEndTouchAll = function(trigger)
            supressKickdownEvent = false
            TriggerOutputs({{"kickdown_relay", "Trigger", 0, ""}, {"ss_DoorBracer_Struggle", "Kill", 2, ""}})
            trigger:Remove()
            DbgPrint("All players left")
        end

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-5132.465332, -3575.130127, 698.892090), Angle(0, -180, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(-5132.465332, -3575.130127, 698.892090), Angle(0, 0, 0), Vector(-200, -200, 0), Vector(200, 200, 100))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- We skip the knockout scene because its not shown anyway.
        ents.WaitForEntityByName("door_knockout_1", function(ent)
            --ent:Fire("Lock")
            ent:SetKeyValue("spawnflags", "2048")
            ent:SetKeyValue("speed", "100")
            ent:SetKeyValue("opendir", "1")
            ent:SetKeyValue("soundlockedoverride", "DoorHandles.Locked1")
            ent:SetKeyValue("soundunlockedoverride", "DoorHandles.Unlocked1")
        end)

        -- We skip the knockout scene because its not shown anyway.
        ents.WaitForEntityByName("door_knockout_2", function(ent)
            ent:SetKeyValue("spawnflags", "2048")
            ent:SetKeyValue("soundlockedoverride", "DoorHandles.Locked1")
        end)

        local tracktrain_elevator

        ents.WaitForEntityByName("tracktrain_elevator", function(ent)
            tracktrain_elevator = ent
        end)

        ents.WaitForEntityByName("trigger_elevator_go_down", function(ent)
            ent:ResizeTriggerBox(Vector(-70, -70, -60), Vector(50, 70, 60))
            ent:SetKeyValue("teamwait", "1")

            ent.OnTrigger = function(_, activator)
                local checkpoint = GAMEMODE:CreateCheckpoint(Vector(-7740.829590, -3959.260010, 388.031250))
                checkpoint:SetParent(tracktrain_elevator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint, activator)
                -- No idea why this wouldnt be triggered already.
                TriggerOutputs({{"speaker_alyxfollow1", "TurnOff", 0, ""}, {"speaker_alyxfollow1", "Kill", 0.1, ""}})
            end
        end)

        ents.WaitForEntityByName("mark_knockout_alyxmark1", function(ent)
            ent:SetPos(Vector(-7464, -4008, 393))
        end)

        ents.WaitForEntityByName("alyx", function(ent)
            ent:SetPos(Vector(-7464, -4008, 393))
        end)

        -- -7740.829590 -3959.260010 388.031250
        GAMEMODE:WaitForInput("relay_knockout_start", "Trigger", function(ent)
            DbgPrint("Starting alyx action")
            TriggerOutputs({{"breakable_alyxwindow", "Break", 0.5, ""}, {"template_alyx", "ForceSpawn", 0.2, ""}, {"lcs_alyxgreet00", "Start", 0.4, ""}, {"logic_kill_cops", "Trigger", 0.2, ""}, {"relay_knockout_alyxrescue", "Trigger", 0.5, ""}, {"door_knockout_1", "Unlock", 8.5, ""}, {"door_knockout_1", "Open", 8.5, ""}, {"alyx_pos_fix", "Trigger", 8.5, ""}, {"door_knockout_2", "Lock", 1.0, ""}, {"door_knockout_2", "Close", 1.1, ""}, {"global_gordon_invulnerable", "TurnOff", 0.3, ""}, {"relationship_cops_hate_player", "RevertRelationship", 0, ""}, {"sound_knockout_copspeech_done", "PlaySound", 2.0, ""}, {"npc_knockout_cop_upstairs", "Kill", 3.0, ""}, {"mic_alyx", "Enable", 0, ""}}) --{"logic_fade_view", "Trigger", 0.1, ""},
        end)

        -- -7176.394043 -3890.482178 384.031250
        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(-7204.497070, -3997.591064, 384.031250), Angle(0, -180, 0))
        checkpoint3:SetVisiblePos(Vector(-7275.987793, -3983.696533, 384.031250))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(Vector(-7275.987793, -3983.696533, 384.031250), Angle(0, 0, 0), Vector(-50, -130, 0), Vector(160, 130, 100))

        checkpointTrigger3.OnTrigger = function(trigger)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT