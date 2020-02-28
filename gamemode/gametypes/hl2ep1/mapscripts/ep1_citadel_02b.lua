AddCSLuaFile()
local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.DefaultLoadout = 
{
    Weapons = {
        "weapon_physcannon"
    },
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = 
{
    ["global_newgame_template_base_items"] = true,
}

MAPSCRIPT.GlobalStates =
{
    ["super_phys_gun"] = GLOBAL_ON,
}
 
function MAPSCRIPT:PostInit()

    if SERVER then

        local tracktrain_elevator
        ents.WaitForEntityByName("citadel_train_lift01_1", function(ent) 
            tracktrain_elevator = ent
        end)

        ents.WaitForEntityByName("entry_transition_door", function(ent) 
            ent:Remove()
        end)

        ents.WaitForEntityByName("train_initial_start_trigger", function(ent)
            if ent:GetClass() == "trigger_multiple" then
                ent:Remove()
            end
        end, true)

        local elevator_trigger = ents.Create("trigger_once")
        elevator_trigger:SetupTrigger(
            Vector(3264, 4648, 2510),
            Angle(0, 0, 0),
            Vector(-155, -190, 0),
            Vector(190, 190, 200)
        )
        elevator_trigger:SetName("train_initial_start_trigger")
        elevator_trigger:SetKeyValue("StartDisabled", "1")
        elevator_trigger:SetKeyValue("teamwait", "1")
        elevator_trigger:Fire("AddOutput", "OnTrigger player_clip_1,Enable,0.0,-1")
        elevator_trigger:Fire("AddOutput", "OnTrigger train_initial_start_counter,Add,1,0.0,-1")
        elevator_trigger.OnTrigger = function(_, activator) 
            local checkpoint = GAMEMODE:CreateCheckpoint(Vector(3264, 4648, 2510))
            checkpoint:SetParent(tracktrain_elevator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint, activator)
        end

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(3570, 4648, -6715))
        local checkpoint2Trigger = ents.Create("trigger_once")
        checkpoint2Trigger:SetupTrigger(
            Vector(3570, 4648, -6715),
            Angle(0, 0, 0),
            Vector(-50, -50, 0),
            Vector(50, 50, 0)
        )
        checkpoint2Trigger.OnTrigger = function(_, activator) 
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end

        ents.WaitForEntityByName("kill_phys_objects_trigger", function(ent)
            local filter = ents.Create("filter_activator_name")
            filter:SetKeyValue("targetname", "player_ragdoll_filter")
            filter:SetKeyValue("Negated", "1")
            filter:SetKeyValue("filtername", "player_ragdoll")
            filter:Spawn()
            ent:SetKeyValue("filtername", "player_ragdoll_filter")
        end)

        local multipleTrigger = ents.FindByPos(Vector(5545.25, 4642.47, -6606), "trigger_multiple")
        for k, v in pairs(multipleTrigger) do
                v:Remove()
        end

        local changelevelTrigger = ents.Create("trigger_once")
        changelevelTrigger:SetupTrigger(
            Vector(5440, 4648, -6715),
            Angle(0, 0, 0),
            Vector(-250, -150, 0),
            Vector(250, 150, 0)
        )
        changelevelTrigger:SetKeyValue("teamwait", "1")
        changelevelTrigger:Fire("AddOutput", "OnTrigger airlock_exit_counter_1,Add,1,0.0,-1")

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT