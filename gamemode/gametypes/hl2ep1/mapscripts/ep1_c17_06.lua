if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_rpg", "weapon_crossbow"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 12,
        ["Grenade"] = 3,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 1,
        ["XBowBolt"] = 4,
        ["RPG_Round"] = 3,
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_dynamic"] = true,
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_physgun"] = true,
    ["global_newgame_spawner_shotgun"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_ar2"] = true,
    ["global_newgame_spawner_rpg"] = true,
    ["global_newgame_spawner_xbow"] = true,
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(12302, 9626, -728),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(12308, 9405, -678),
            Mins = Vector(-68, -19, -54),
            Maxs = Vector(68, 19, 54)
        }
    },
    {
        Pos = Vector(11934, 8531, -728),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(11946, 8528, -696),
            Mins = Vector(-101, -64, -40),
            Maxs = Vector(101, 64, 40)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Replace the train start trigger with a bigger one and a teamwait keyvalue and create a checkpoint parented to the train
    local trainCheckpoint = GAMEMODE:CreateCheckpoint(Vector(11986, 8409, -759), Angle(0, 90, 0))
    ents.WaitForEntityByName(
        "razortrain3",
        function(ent)
            trainCheckpoint:SetParent(ent)
        end
    )

    ents.WaitForEntityByName(
        "trigger_playerontrain",
        function(ent)
            local trigger = ents.Create("trigger_once")
            trigger:SetupTrigger(Vector(11986, 8374, -737), Angle(0, 0, 0), Vector(-25, -50, -33), Vector(25, 50, 33))
            trigger:SetName("trigger_playerontrain")
            trigger:SetKeyValue("teamwait", "1")
            trigger:CloneOutputs(ent)
            trigger.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(trainCheckpoint, activator)
            end

            ent:Remove()
        end
    )

    -- Adjust the default boarding position
    local boardingPos = Vector(9668.0, 9230, -700)
    ents.WaitForEntityByName(
        "ss_cit1_board",
        function(ent)
            ent:SetPos(boardingPos)
        end
    )

    ents.WaitForEntityByName(
        "ss_cit2_board",
        function(ent)
            ent:SetPos(boardingPos)
        end
    )

    -- Setup a timeout in case NPCs get stuck, seems to happen.
    local timeoutEnt = ents.Create("logic_timer")
    timeoutEnt:SetKeyValue("UseRandomTime", "0")
    timeoutEnt:SetKeyValue("RefireTime", "5")
    timeoutEnt:SetKeyValue("StartDisabled", "1")
    timeoutEnt:Fire("AddOutput", "OnTimer counter_goodbyescene,Add,999,0,-1", 0)
    timeoutEnt:Fire("AddOutput", "OnTimer !self,Kill,,0.01,-1", 0)
    timeoutEnt:SetName("logic_timer_goodbyescene")
    timeoutEnt:Spawn()

    local goodbyeCounter = ents.FindFirstByName("counter_goodbyescene")
    ents.WaitForEntityByName(
        "relay_barney_leaves",
        function(relayEnt)

            relayEnt:Fire("AddOutput", "OnTrigger logic_timer_goodbyescene,Enable,,0,-1", 0)

            local counter = 0
            local function CreateSS(entName, index)
                local ss = ents.Create("scripted_sequence")
                ss:SetPos(boardingPos)
                ss:SetKeyValue("m_fMoveTo", "2")
                ss:SetKeyValue("spawnflags", "96")
                ss:SetKeyValue("m_iszEntity", entName)
                ss:SetKeyValue("OnBeginSequence", entName .. ",Kill,,0,-1")
                ss:SetKeyValue("OnBeginSequence", "counter_goodbyescene,Add,1,0,-1")
                ss:SetName("ss_cit_board" .. tostring(index))
                ss:Spawn()
            end

            local function HandleCitizen(entCitizen)
                local newName = "citizen_refugees_board_" .. tostring(counter)
                entCitizen:SetName(newName)
                entCitizen:Fire("AddOutput", "OnDeath counter_goodbyescene,Add,1,0,-1")
                CreateSS(newName, counter)
                goodbyeCounter:SetKeyValue("max", tostring(counter + 2))
                relayEnt:Fire("AddOutput", "OnTrigger ss_cit_board" .. tostring(counter) .. ",BeginSequence,," .. tostring(counter + 2) .. ",-1", 0)
                counter = counter + 1

                -- Give each NPC some time to board before the fail safe kicks in.
                timeoutEnt:SetKeyValue("RefireTime", tostring(counter * 1.5))
            end

            ents.WaitForEntityByName(
                "citizen_refugees_1",
                function(ent)
                    HandleCitizen(ent)
                end
            )

            ents.WaitForEntityByName(
                "citizen_refugees_2",
                function(ent)
                    HandleCitizen(ent)
                end
            )

            ents.WaitForEntityByName(
                "lambda_citizen_refugees_1",
                function(ent)
                    HandleCitizen(ent)
                end
            )

            ents.WaitForEntityByName(
                "lambda_citizen_refugees_2",
                function(ent)
                    HandleCitizen(ent)
                end
            )

            ents.WaitForEntityByName(
                "lambda_citizen_refugees_3",
                function(ent)
                    HandleCitizen(ent)
                end
            )

            ents.WaitForEntityByName(
                "lambda_citizen_refugees_4",
                function(ent)
                    HandleCitizen(ent)
                end
            )
        end
    )
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT