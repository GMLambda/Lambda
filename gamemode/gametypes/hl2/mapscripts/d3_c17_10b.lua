if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow", "weapon_bugbait"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
        ["XBowBolt"] = 4
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["s_room_panelswitch"] = {"Lock"}, -- Prevent it from locking the button.
    ["n_room_camera_2"] = {"Toggle"}
}

MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items"] = true,
    ["lobby_combinedoor_portalbrush"] = true
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- 3887.857910 -514.078979 512.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(4184.389160, -740.649597, 512.031250), Angle(0, 180, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(4177.301758, -713.936646, 512.031250), Angle(0, 0, 0), Vector(-140, -140, 0), Vector(140, 140, 100))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- Don't close the door once it's opened.
        GAMEMODE:WaitForInput("lobby_combinedoor", "SetAnimation", function()
            GAMEMODE:FilterEntityInput("lobby_combinedoor", "SetAnimation")
        end)

        for _, v in pairs(ents.FindByPos(Vector(2768, 1136, 832), "trigger_once")) do
            v:ClearOutputs()
            v:Fire("AddOutput", "OnTrigger roof_soldiersquad_soldier_makers,Disable,,0,-1")
        end

        ents.WaitForEntityByName("lcs_barney_h4x_pows", function(ent)
            ent:Fire("AddOutput", "OnCompletion npc_citizen,SetSquad,player_squad,7,-1")
        end)

        ents.WaitForEntityByName("lcs_barney_h4x", function(ent)
            ent:Fire("AddOutput", "OnCompletion s_room_doors,Close,,10,-1")
            ent:Fire("AddOutput", "OnCompletion n_room_trapdoor_1a,Close,,10,-1")
            ent:Fire("AddOutput", "OnCompletion n_room_trapdoor_1b,Close,,10,-1")
            ent:Fire("AddOutput", "OnCompletion n_room_camera_2,Disable,,10,-1")
        end)

        for _, v in ipairs(ents.FindByModel("*147")) do
            v:Remove()
        end

        -- Disable all the turrets as soon as player press the button at stealth laser room.
        -- This will allow player continue to progress even if they failed to stealth.
        ents.WaitForEntityByName("s_room_off_relay", function(ent)
            ent:Fire("AddOutput", "OnTrigger s_room_doors,Open,,0,-1")
            ent:Fire("AddOutput", "OnTrigger s_room_turret_*,Disable,,0,-1")
        end)

        local triggersdoor = ents.Create("trigger_once")
        triggersdoor:SetupTrigger(Vector(3235, -1504, 592), Angle(0, 0, 0), Vector(-200, -65, -80), Vector(200, 65, 80))
        triggersdoor:SetKeyValue("teamwait", "1")

        triggersdoor.OnTrigger = function(ent)
            GAMEMODE:FilterEntityInput("s_room_doors", "Close")

            TriggerOutputs({{"barney_laseroom_lcs", "Start", 0.5, ""}})
            for _, v in pairs(ents.FindByPos(Vector(3168, -1564, 576), "func_door")) do
                v:Fire("Open")
            end
        end

        ents.WaitForEntityByName("n_room_trigger_relay", function(ent)
            ent:Fire("AddOutput", "OnTrigger n_room_doors2_close_relay,Trigger,,0,-1")
        end)

        ents.WaitForEntityByName("n_room_trigger_1", function(ent)
            ent:Remove()
        end)

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(3175, 1155, 530), Angle(0, 0, 0))

        local triggernroom = ents.Create("trigger_once")
        triggernroom:SetupTrigger(Vector(3072, 900, 552), Angle(0, 0, 0), Vector(-497, -341, -33), Vector(297, 341, 33))
        triggernroom:SetKeyValue("teamwait", "1")

        triggernroom.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)

            ents.WaitForEntityByName("n_room_trigger_relay", function(ent)
                ent:Fire("Trigger")
            end)
        end

        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(2405, 865, 260), Angle(0, 0, 0))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(Vector(2565, 865, 260), Angle(0, 0, 0), Vector(-10, -70, -80), Vector(10, 70, 80))

        checkpointTrigger3.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3, activator)
        end
    end
end

function MAPSCRIPT:OnMapTransition()
    DbgPrint("OnMapTransition")

    -- Make sure we have barney around.
    util.RunDelayed(function()
        local foundBarney = false

        for k, v in pairs(ents.FindByName("barney")) do
            foundBarney = true
            break
        end

        if foundBarney == false then
            ents.WaitForEntityByName("player_spawn_items_maker", function(ent)
                ent:Fire("ForceSpawn")
            end)
        end
    end, CurTime() + 0.1)
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT
