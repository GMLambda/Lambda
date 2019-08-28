AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons = {
        "weapon_lambda_hands",
    },
    Ammo = {},
    Armor = 30,
    HEV = false,
}

MAPSCRIPT.EntityFilterByClass =
{
    ["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
}

MAPSCRIPT.ImportantPlayerNPCNames =
{
    ["barneyroom_door_cop_1"] = true,
}

MAPSCRIPT.InputFilters =
{
    ["train_door_2_counter"] = {"Add"},
    ["razortrain_gate_cop_2"] = {"SetPoliceGoal"},
    ["cage_playerclip"] = {"Enable"},
    ["cage_door_counter"] = {"Add"},
    ["logic_kill_citizens"] = {"Trigger"},
    ["storage_room_door"] = {"Close", "Lock"},
}

MAPSCRIPT.GlobalStates =
{
    ["gordon_precriminal"] = GLOBAL_ON,
    ["gordon_invulnerable"] = GLOBAL_OFF,
    ["super_phys_gun"] = GLOBAL_OFF,
    ["antlion_allied"] = GLOBAL_OFF,
}

MAPSCRIPT.EntityRelationships =
{
    { Class1 = "npc_metropolice", Class2 = "player", Relation = D_NU, Rank = 99 },
    { Class1 = "npc_cscanner", Class2 = "player", Relation = D_NU, Rank = 99 },
    { Class1 = "npc_metropolice", Class2 = "npc_citizen", Relation = D_LI, Rank = 99 },
    { Class1 = "npc_strider", Class2 = "npc_metropolice", Relation = D_LI, Rank = 99 },
    { Class1 = "npc_strider", Class2 = "npc_citizen", Relation = D_LI, Rank = 99 },
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        local function fixCitizen(ent)
            ent:SetKeyValue("spawnflags", "16794640")
        end

        ents.WaitForEntityByName("citizen_queue_start_1", fixCitizen)
        ents.WaitForEntityByName("citizen_queue_start_2", fixCitizen)
        ents.WaitForEntityByName("citizen_queue_start_3", fixCitizen)

        ents.RemoveByClass("trigger_once", Vector(-4614.97, -678.03, 16))
        ents.RemoveByClass("trigger_once", Vector(-4614.97, -806.03, 16))
        ents.RemoveByClass("trigger_once", Vector(-5022.15, -787.48, 0))
        ents.RemoveByClass("trigger_once", Vector(-4370.18, -922.25, 20.5))

        ents.WaitForEntityByName("customs_schedule_walk_to_exit", function(ent)
            ent:SetKeyValue("m_flRadius", "110")
            ent:SetKeyValue("m_iszEntity", "citizen_queue_start*")
        end)

        ents.WaitForEntityByName("customs_schedule_walk_to_train", function(ent)
            ent:SetKeyValue("m_flRadius", "110")
            ent:SetKeyValue("m_iszEntity", "citizen_queue_start*")
        end)

        local queueTrigger = ents.Create("trigger_once")
        queueTrigger:SetupTrigger(Vector(-4322.127441, -922.505859, -27.981224), Angle(0,0,0), Vector(-20, -20, 0), Vector(20, 20, 90))
        queueTrigger:SetKeyValue("teamwait", 0)
        queueTrigger:Fire("AddOutput", "OnTrigger customs_relay_send_to_train,Trigger,,0.0,-1")
        queueTrigger:Fire("AddOutput", "OnTrigger lambda_queue_pclip,Kill,,0.0,-1")

        local pclipBrush = ents.Create("func_brush")
        pclipBrush:SetPos(Vector(-4330.575195, -922.814453, 35))
        pclipBrush:SetName("lambda_queue_pclip")
        pclipBrush:SetModel("*58")
        pclipBrush:SetKeyValue("disabled", "1")
        pclipBrush:SetKeyValue("rendermode", "10")
        pclipBrush:SetKeyValue("excludednpc", "npc_citizen")
        pclipBrush:Spawn()

        ents.WaitForEntityByName("trigger_watchclock", function(ent)
            ent:Fire("AddOutput", "OnTrigger customs_queue_timer,Enable,,0.1,-1")
        end)

        ents.WaitForEntityByName("customs_queue_timer", function(ent)
            ent:Fire("AddOutput", "OnTimer lambda_queue_pclip,Enable,,0.0,-1")
            ent:Fire("AddOutput", "OnTimer lambda_queue_pclip,Disable,,2.5,-1")
        end)

        -- Remove all default spawnpoints.
        ents.RemoveByClass("info_player_start")

        -- Annoying stuff.
        ents.RemoveByName("cage_playerclip")
        --ents.RemoveByName("barney_room_blocker")
        ents.RemoveByName("barney_room_blocker_2")
        ents.RemoveByName("barney_hallway_clip")
        ents.RemoveByName("logic_kill_citizens")

        -- Fix spawn position
        ents.WaitForEntityByName("teleport_to_start", function(ent)
            ent:SetPos(Vector(-14576, -13924, -1290))
        end)

        ents.WaitForEntityByName("breakfall_crates", function(ent)
            -- Don't break so easily.
            ent:SetKeyValue("physdamagescale", "1")
            ent:SetHealth(1000)
        end)

        -- Fix point_viewcontrol, affect all players.
        for k,v in pairs(ents.FindByClass("point_viewcontrol")) do
            v:SetKeyValue("spawnflags", "132") -- SF_CAMERA_PLAYER_MULTIPLAYER_ALL
        end

        -- Make the cop go outside the hallway so other players can still pass by.
        local mark_cop_security_room_leave = ents.FindFirstByName("mark_cop_security_room_leave");
        mark_cop_security_room_leave:SetPos(Vector(-4304, -464, -16))

        GAMEMODE:WaitForInput("logic_start_train", "Trigger", function()

            DbgPrint("Assigning new spawnpoint")

            local intro_train_2 = ents.FindFirstByName("intro_train_2")
            local pos = intro_train_2:LocalToWorld(Vector(-233.685928, 1.246165, 47.031250))
            local cp = GAMEMODE:SetPlayerCheckpoint({ Pos = pos, Ang = Angle(0, 0, 0)})
            cp:SetParent(intro_train_2)

            -- Disable them earlier, the black fadeout is gone.
            for k,v in pairs(ents.FindByClass("point_viewcontrol")) do
                v:Fire("Disable")
            end

        end)

        -- Block players from escaping control gate.
        local cage_playerclip = ents.Create("func_brush")
        cage_playerclip:SetPos(Vector(-4226.9350585938, -417.03271484375,-31.96875))
        cage_playerclip:SetModel("*68")
        cage_playerclip:SetKeyValue("spawnflags", "2")
        cage_playerclip:Spawn()

        -- Setup the door to not close anymore once we entered the trigger.
        GAMEMODE:WaitForInput("razor_train_gate_2", "Close", function()
            DbgPrint("Preventing barney_door_1 to close")
            GAMEMODE:FilterEntityInput("barney_door_1", "Close")
        end)

        -- Move barney to a better position when he wants players to go inside.
        ents.WaitForEntityByName("mark_barney_03", function(ent)
            ent:SetPos(Vector(-3466.066650, -486.869598, -31.968750))
        end)

        -- Create a trigger once all players are inside we setup a new spawnpoint and close the door.
        ents.RemoveByClass("trigger_once", Vector(-3442, -316, 8)) -- We will take over.

        local barney_room_trigger = ents.Create("trigger_once")
        barney_room_trigger:SetupTrigger(Vector(-3450, -255, 20), Angle(0,0,0), Vector(-150, -130, -50), Vector(150, 150, 50))
        barney_room_trigger:SetKeyValue("teamwait", 1)
        barney_room_trigger.OnTrigger = function(_, activator)

            GAMEMODE:SetPlayerCheckpoint({ Pos = Vector(-3549, -347, -31), Ang = Angle(0, 0, 0)}, activator)

            ents.WaitForEntityByName("security_intro_02", function(ent) ent:Fire("Start") end)
            ents.WaitForEntityByName("barney_room_blocker", function(ent) ent:Fire("Enable") end)
        end

        ents.WaitForEntityByName("barney_door_2", function(ent)
            ent:SetKeyValue("opendir", "2")
        end)

        -- Use a better spot for barney
        local mark_barneyroom_comblock_4 = ents.FindFirstByName("mark_barneyroom_comblock_4")
        mark_barneyroom_comblock_4:SetPos(Vector(-3588, 3, -31))
        
    end

end

return MAPSCRIPT
