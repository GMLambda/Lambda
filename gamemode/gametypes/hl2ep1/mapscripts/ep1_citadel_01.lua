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

MAPSCRIPT.InputFilters = {
    ["relay_combineshieldwall3_on"] = {"Trigger"}, -- Don't allow to reactivate.
    ["clip_combineshieldwall6"] = {"Enable"}
}

MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["trigger_start_rollertraining"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-4860.789063, 3407.795166, 2592.708008),
        Ang = Angle(0, 45, 0),
        Trigger = {
            Pos = Vector(-4860.789063, 3407.795166, 2592.708008),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 100)
        }
    },
    {
        Pos = Vector(-4892, 1488, 2471),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-4856, 1491.14, 2494.08),
            Mins = Vector(-174, -140, -60),
            Maxs = Vector(174, 140, 60)
        }
    }
}

function MAPSCRIPT:PostInit()
    if SERVER then
        local alyxStopFollow = ents.Create("trigger_once")
        alyxStopFollow:SetupTrigger(Vector(-4727.891113, 7711.114258, 2520.031250), Angle(0, 0, 0), Vector(-240, -200, 0), Vector(200, 200, 180))
        alyxStopFollow:SetKeyValue("StartDisabled", "0")
        alyxStopFollow:SetKeyValue("filtername", "filter_alyx")
        alyxStopFollow:SetKeyValue("spawnflags", "3")
        alyxStopFollow:Fire("AddOutput", "OnTrigger follow_alyx,Deactivate,,0.0,-1")
        alyxStopFollow:Fire("AddOutput", "OnTrigger lambda_start_rollertraining,Enable,,0.0,-1")
        ents.WaitForEntityByName(
            "counter_rollerdoor_close",
            function(ent)
                ent:SetKeyValue("max", "3")
            end
        )

        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(-4727.891113, 7711.114258, 2520.031250), Angle(0, 0, 0), Vector(-240, -200, 0), Vector(200, 200, 180))
        checkpointTrigger1:SetKeyValue("StartDisabled", "1")
        checkpointTrigger1:SetKeyValue("teamwait", "1")
        checkpointTrigger1:SetName("lambda_start_rollertraining")
        checkpointTrigger1:Fire("AddOutput", "OnTrigger lcs_al_citadel_01_rollertraining_01,Start,,0.0,-1")
        checkpointTrigger1:Fire("AddOutput", "OnTrigger follow_alyx,Deactivate,,0.0,-1")
        checkpointTrigger1:Fire("AddOutput", "OnTrigger counter_rollerdoor_close,Add,1,0.0,-1")
        checkpointTrigger1:Fire("AddOutput", "OnTrigger alyx,StartScripting,,0.01,-1")
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(Vector(-4721.599121, 7732.462891, 2520.031250), activator)
        end

        -- Not sure why players should activate this.
        ents.WaitForEntityByName(
            "trigger_player_holdmine",
            function(ent)
                ent:SetKeyValue("spawnflags", "10")
                ent:SetKeyValue("filtername", "filter_rollermine")
            end
        )

        GAMEMODE:WaitForInput(
            "logic_weapon_strip_physcannon_end1",
            "Trigger",
            function(ent)
                for k, v in pairs(ents.FindByClass("weapon_physcannon")) do
                    v:Supercharge()
                end
            end
        )

        -- Try to ignore the player so they all fall off.
        ents.WaitForEntityByName(
            "soldier_assault1_soldier1",
            function(ent)
                ent:SetKeyValue("spawnflags", "17940")
            end
        )

        ents.WaitForEntityByName(
            "soldier_assault1_soldier2",
            function(ent)
                ent:SetKeyValue("spawnflags", "17940")
            end
        )

        ents.WaitForEntityByName(
            "soldier_assault1_soldier3",
            function(ent)
                ent:SetKeyValue("spawnflags", "17940")
            end
        )

        ents.WaitForEntityByName(
            "soldier_assault1_soldier4",
            function(ent)
                ent:SetKeyValue("spawnflags", "17940")
            end
        )

        -- Move slightly away from player
        ents.WaitForEntityByName(
            "soldier_assault1_assault1",
            function(ent)
                ent:SetPos(Vector(-4846.420410, 4386.058594, 2605.789307))
            end
        )

        ents.WaitForEntityByName(
            "soldier_assault1_assault2",
            function(ent)
                ent:SetPos(Vector(-4846.420410, 4386.058594, 2605.789307))
            end
        )

        ents.WaitForEntityByName(
            "soldier_assault1_assault3",
            function(ent)
                ent:SetPos(Vector(-4846.420410, 4386.058594, 2605.789307))
            end
        )

        ents.WaitForEntityByName(
            "soldier_assault1_assault4",
            function(ent)
                ent:SetPos(Vector(-4846.420410, 4386.058594, 2605.789307))
            end
        )

        -- Unnamed trigger.
        for _, stripTrigger in pairs(ents.FindByPos(Vector(-2658, 1377, 2576.86), "trigger_once")) do
            print("Removing trigger:" .. tostring(stripTrigger))
            stripTrigger:Remove()
        end

        -- We have to take away all physcannons except one.
        GAMEMODE:WaitForInput(
            "weapon_strip1",
            "Enable",
            function(ent)
                local lastPly = nil
                for _, v in pairs(player.GetAll()) do
                    if lastPly ~= nil then
                        lastPly:StripWeapon("weapon_physcannon")
                    end

                    lastPly = v
                end
            end
        )

        for _, v in pairs(ents.FindByPos(Vector(-2408, 1332, 2560), "func_brush", "clip_combineshieldwall3")) do
            v:SetName("clip_combineshieldwall3_exit")
        end

        for _, v in pairs(ents.FindByPos(Vector(-2451, 1366, 2560), "prop_dynamic", "model_combineshieldwall2_3")) do
            v:SetName("model_combineshieldwall3_exit")
        end

        for _, v in pairs(ents.FindByPos(Vector(-2451, 1290, 2560), "prop_dynamic", "model_combineshieldwall2_3")) do
            v:SetName("model_combineshieldwall3_exit")
        end

        ents.WaitForEntityByName(
            "relay_combineshieldwall2_off1",
            function(ent)
                ent:Fire("AddOutput", "OnTrigger clip_combineshieldwall3_exit,Disable,,0.0,-1")
                ent:Fire("AddOutput", "OnTrigger model_combineshieldwall3_exit,Skin,1,0.0,-1")
            end
        )

        local stripTrigger = ents.Create("trigger_once")
        stripTrigger:SetupTrigger(Vector(-2684.712891, 1377.693115, 2464.031250), Angle(0, 0, 0), Vector(-200, -100, 0), Vector(230, 100, 180))
        stripTrigger:SetKeyValue("teamwait", "1")
        stripTrigger:Fire("AddOutput", "OnTrigger relay_combineshieldwall2_on1,Trigger,,0.0,-1")
        stripTrigger:Fire("AddOutput", "OnTrigger lcs_al_citadel_01_gravcharge_01,Start,,0.0,-1")
        stripTrigger:Fire("AddOutput", "OnTrigger weapon_strip_motion_disable_player,Enable,,1.0,-1")
        stripTrigger:Fire("AddOutput", "OnTrigger logic_weapon_strip_announce,Trigger,,1.5,-1")
        stripTrigger:Fire("AddOutput", "OnTrigger ambient_holdfield_loop,PlaySound,,2.0,-1")
        -- Close the one side so players won't run too far.
        local shieldClose = ents.Create("logic_auto")
        shieldClose:Fire("AddOutput", "OnMapSpawn model_combineshieldwall3_exit,Skin,0,1.0,-1")
        shieldClose:Fire("AddOutput", "OnMapSpawn clip_combineshieldwall3_exit,Enable,,1.0,-1")
        shieldClose:Spawn()
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT