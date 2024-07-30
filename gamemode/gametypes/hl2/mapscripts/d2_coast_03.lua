if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 3
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["fog"] = {"SetStartDist"}
}

MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items"] = true,
    ["invulnerable"] = true
}

MAPSCRIPT.ImportantPlayerNPCNames = {
    ["citizen_b_regular_original"] = true,
    ["rocketman"] = true,
    ["gatekeeper"] = true
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        -- Combine and their binoculars... it just fucks your game up, nothing else.
        ents.WaitForEntityByName("telescope", function(ent)
            ent:SetKeyValue("wait", "20")
            ent:SetKeyValue("spawnflags", "20")
        end)

        -- Bug fixes, exist in base HL2: The cleanup relay got triggered before first time use binocular.
        -- This bug can result player seeing G-Man face to face and duplicated citizens.
        -- Remove the cutscene related entities about using binocular. Player no longer see cutscene but better safe than sorry.
        ents.WaitForEntityByName("gman_template", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("citizen_spawn_relay", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("binoccit_1", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("binoccit_2", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("antlion_ragdoll", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("lr_binoc_scene", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("gman_walk", function(ent)
            ent:Remove()
        end)

        ents.WaitForEntityByName("odessa_walk", function(ent)
            ent:Remove()
        end)

        -- Spawn more supplies
        local crate_rpg1 = ents.Create("item_ammo_crate")
        crate_rpg1:SetKeyValue("AmmoType", "3")
        crate_rpg1:SetPos(Vector(6550, 4186, 276))
        crate_rpg1:SetAngles(Angle(0, 90, 0))
        crate_rpg1:Spawn()

        local crate_rpg2 = ents.Create("item_ammo_crate")
        crate_rpg2:SetKeyValue("AmmoType", "3")
        crate_rpg2:SetPos(Vector(8998, 4490, 272))
        crate_rpg2:SetAngles(Angle(0, 180, 0))
        crate_rpg2:Spawn()

        local medkits =
        {
            {7025, 3475, 340},
            {7000, 3485, 350},
            {6530, 4355, 280},
            {7920, 3520, 325},
            {7895, 3520, 325},
            {6735, 4790, 330},
            {6720, 4810, 330},
            {8365, 4350, 440},
            {8330, 4330, 440},
            {8295, 4325, 440},
            {8870, 4450, 535},
            {8865, 4425, 535}
        }

        for _, v in ipairs(medkits) do
            local medkit = ents.Create("item_healthkit")
            medkit:SetPos(Vector(v[1], v[2], v[3]))
            medkit:Spawn()
        end

        local batteries =
        {
            {8685, 4185, 305},
            {8665, 4175, 305},
            {8810, 4205, 405},
            {8415, 4340, 545},
            {8410, 4345, 545},
            {6480, 4370, 285}
        }

        for _, v in ipairs(batteries) do
            local battery = ents.Create("item_battery")
            battery:SetPos(Vector(v[1], v[2], v[3]))
            battery:Spawn()
        end

        -- Block the road to prevent player skipping the whole scene.
        -- These are 'func_vehicleclip' and it only do collision with vehicle, force it to collide with player.
        for _, v in ipairs(ents.FindByModel("*145")) do
            v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
            v:SetName("road_exploit_block")
        end

        for _, v in ipairs(ents.FindByModel("*146")) do
            v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
            v:SetName("road_exploit_block")
        end

        for _, v in ipairs(ents.FindByModel("*154")) do
            v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
            v:SetName("road_exploit_block")
        end

        -- Only the player can pass this filter.
        -- Prevent vehicle crushing the critical NPCs in accident!
        local filter_player = ents.Create("filter_activator_class")
        filter_player:SetName("filter_player")
        filter_player:SetKeyValue("filterclass", "player")

        ents.WaitForEntityByName("greeter_maker", function(ent)
            ent:Fire("AddOutput", "OnEntitySpawned citizen_b_regular_original,AddOutput,health 100,0.1,-1")
            ent:Fire("AddOutput", "OnEntitySpawned citizen_b_regular_original,SetDamageFilter,filter_player,0.1,-1")
        end)

        ents.WaitForEntityByName("rocketman", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("killed_critical_npc", function(ent)
            ent:SetName("killed_critical_npc_2")
        end)

        ents.WaitForEntityByName("rocketman", function(ent)
            ent:Fire("AddOutput", "OnDeath killed_critical_npc_2,ShowMessage,0") -- Use one with no delay.
        end)

        GAMEMODE:WaitForInput("spawner_rpg", "ForceSpawn", function(ent)
            local entityData = game.FindEntityInMapData("rpg_weapon")
            local pos = util.StringToType(entityData["origin"], "Vector")
            local ang = util.StringToType(entityData["angles"], "Angle")
            local newRPG = ents.Create("weapon_rpg")
            newRPG:SetPos(pos)
            newRPG:SetAngles(ang)
            newRPG:Spawn()
            TriggerOutputs({{"first_train_rl", "Trigger", 0.0, ""}, {"train_horn", "PlaySound", 0.0, ""}, {"template_rpg", "Kill", 0.0, ""}, {"spawner_rpg", "Kill", 0.1, ""}})

            return true -- Suppress
        end)

        GAMEMODE:WaitForInput("gunship_spawner_2", "Spawn", function(ent)
            ent:RemoveTemplateData("OnDeath")
            ent:AddTemplateData("squadname", "lambda_gunships")
            ent:SetKeyValue("SpawnFrequency", "10")
            ent:Enable()

            ent.OnAllSpawnedDead = function(e)
                TriggerOutputs({{"ag_siren", "StopSound", 0.0, ""}, {"lr_radioloop", "Disable", 0.0, ""}, {"citizen_standoff", "Kill", 0.0, ""}, {"aigf_combat", "Kill", 0.0, ""}, {"aisc_odessapostgunship", "Enable", 0.0, ""}, {"lr_squad_follow_*", "Kill", 0.0, ""}, {"post_gunship_jeep_relay*", "Enable", 0.0, ""}, {"aigf_odessapostgunship*", "Activate", 0.10, ""}, {"ss_post**", "BeginSequence", 2.00, ""}, {"gunshipdown_music*", "PlaySound", 3.00, ""}})
            end

            return true
        end)

        ents.WaitForEntityByName("gatekeeper", function(ent)
            ent:SetHealth(100)
            ent:Fire("SetDamageFilter", "filter_player")
        end)

        GAMEMODE:WaitForInput("village_gate", "Open", function(gate_ent)
            ents.WaitForEntityByName("gatekeeper", function(ent)
                GAMEMODE:UnregisterMissionCriticalNPC(ent)
            end)

            ents.WaitForEntityByName("road_exploit_block", function(ent)
                ent:SetCollisionGroup(COLLISION_GROUP_VEHICLE_CLIP)
            end)
        end)

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-5971.663574, 3534.091064, 269.338867), Angle(4.653, 55.612, 0.000))

        GAMEMODE:WaitForInput("spypost_template", "ForceSpawn", function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
            GAMEMODE:SetVehicleCheckpoint(Vector(-5811.580566, 3605.574463, 257.262878), Angle(0, 0, 0))
        end)

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(6494.825195, 4199.202637, 260.031250), Angle(0, 0, 0))
        checkpoint2:SetVisiblePos(Vector(7322.962402, 4037.665527, 257.896637))

        GAMEMODE:WaitForInput("aisc_pre_ingreeterrange", "Enable", function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
            GAMEMODE:SetVehicleCheckpoint(Vector(6610.592285, 4405.477539, 264.207794), Angle(0.091, -121.466, 0.363))
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT
