if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_crossbow", "weapon_rpg"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 12,
        ["Grenade"] = 3,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 1,
        ["XBowBolt"] = 4
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
    ["ptemplate_csoldiers_cargroup"] = true,
    ["ptemplate_parkinglot_soldiers"] = true,
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(9777, 9720, -735),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(9777, 9720, -735),
            Mins = Vector(-106, -111, -64),
            Maxs = Vector(106, 111, 64)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Force the NPCs to follow the player. Squads in Garry's Mod are a bit broken, the replacement
    -- lambda_player_follow entity is a bit more reliable but also quite hacky.
    local playerFollow = ents.Create("ai_goal_follow")
    playerFollow:SetName("lambda_follow_player")
    playerFollow:SetKeyValue("actor", "citizen_refugees*")
    playerFollow:SetKeyValue("goal", "!player")
    playerFollow:SetKeyValue("Formation", "0")
    playerFollow:SetKeyValue("MaximumState", "1")
    playerFollow:SetKeyValue("StartActive", "0")
    playerFollow:SetKeyValue("SearchType", "0")
    playerFollow:Spawn()

    ents.WaitForEntityByName("relay_pickup_citizens", function(ent)
        ent:Fire("AddOutput", "OnTrigger lambda_follow_player,Deactivate,,0,-1")
        ent:Fire("AddOutput", "OnTrigger lambda_follow_player,Activate,,0.01,-1")
    end)

    -- Alyx should wait for everyone at the end before closing
    ents.WaitForEntityByName(
        "counter_everyone_in_place_for_barney_goodbye",
        function(ent)
            ent:SetKeyValue("max", "6")
        end
    )

    -- Make the doors at the end close when we are ready
    local trainCheckpoint = ents.Create("trigger_once")
    trainCheckpoint:SetupTrigger(Vector(9876, 9628, -680), Angle(0, 0, 0), Vector(-190, -220, -60), Vector(236, 220, 60))
    trainCheckpoint:SetKeyValue("teamwait", "1")
    trainCheckpoint:SetKeyValue("showwait", "1")
    trainCheckpoint:SetKeyValue("StartDisabled", "1")
    trainCheckpoint:SetName("lambda_close_doors")
    trainCheckpoint:AddOutput("OnTrigger", "counter_everyone_in_place_for_barney_goodbye", "Add", "1", 0.0, "1")
    -- When barney arrives add to the counter so alyx will start closing the door.
    ents.WaitForEntityByName(
        "rallypoint_barney_lasttrain",
        function(ent)
            ent:Fire("AddOutput", "OnArrival lambda_close_doors,Enable,,0,-1")
        end
    )

    -- Disallow shoving the NPC near the door out of the way.
    ents.WaitForEntityByName(
        "citizen_blocker",
        function(ent)
            ent:SetKeyValue("spawnflags", "1458180")
        end
    )

    -- Prevent NPCs from getting stuck on the lockers. Adjust spawnflags
    -- so they can't interact with it.
    ents.WaitForEntityByName(
        "lockers_1_door_left",
        function(ent)
            ent:SetKeyValue("spawnflags", "820")
        end
    )

    ents.WaitForEntityByName(
        "lockers_1_door_middle",
        function(ent)
            ent:SetKeyValue("spawnflags", "820")
        end
    )

    ents.WaitForEntityByName(
        "lockers_1_door_right",
        function(ent)
            ent:SetKeyValue("spawnflags", "820")
        end
    )

    -- Turn the NPCs passive once they reached the room.
    local passiveTrigger = ents.Create("trigger_multiple")
    passiveTrigger:SetKeyValue("filtername", "filter_citizens")
    passiveTrigger:SetKeyValue("spawnflags", "2")
    passiveTrigger:SetKeyValue("StartDisabled", "0")
    passiveTrigger:SetKeyValue("wait", "1")
    passiveTrigger:SetKeyValue("OnTrigger", "!activator,SetAmmoResupplierOff,,0,-1", "0.0")
    passiveTrigger:SetKeyValue("OnTrigger", "!activator,SetMedicOff,,0,-1", "0.0")
    passiveTrigger:SetName("lambda_passive_trigger")
    passiveTrigger:SetupTrigger(Vector(8681, 9510, -767), Angle(0, 0, 0), Vector(-110, -140, 0), Vector(110, 140, 100))
    ents.WaitForEntityByName(
        "trigger_citizen_boardtrain",
        function(ent)
            ent:Fire("AddOutput", "OnTrigger !activator,SetAmmoResupplierOff,,0,-1", "0.0")
            ent:Fire("AddOutput", "OnTrigger !activator,SetMedicOff,,0,-1", "0.0")
        end
    )

    GAMEMODE:WaitForInput(
        "citizen_refugees_1",
        "Kill",
        function(ent)
            ent:SetName("lambda_citizen_refugees_1")

            return true
        end
    )

    GAMEMODE:WaitForInput(
        "citizen_refugees_2",
        "Kill",
        function(ent)
            ent:SetName("lambda_citizen_refugees_2")

            return true
        end
    )

    GAMEMODE:WaitForInput(
        "citizen_refugees_3",
        "Kill",
        function(ent)
            ent:SetName("lambda_citizen_refugees_3")

            return true
        end
    )

    GAMEMODE:WaitForInput(
        "citizen_refugees_4",
        "Kill",
        function(ent)
            ent:SetName("lambda_citizen_refugees_4")

            return true
        end
    )

    -- Create more places where the NPC can sit.
    local sit1 = ents.Create("scripted_sequence")
    sit1:SetPos(Vector(9648, 9504, -735))
    sit1:SetName("lambda_ss_citizen_wait_points_3")
    sit1:SetAngles(Angle(0, 0, 0))
    sit1:SetKeyValue("m_iszEntity", "citizen_refugees_3")
    sit1:SetKeyValue("m_iszPlay", "Idle_to_Sit_Ground")
    sit1:SetKeyValue("m_iszPostIdle", "Sit_Ground")
    sit1:SetKeyValue("m_fMoveTo", "1")
    sit1:SetKeyValue("spawnflags", "356")
    sit1:SetKeyValue("OnBeginSequence", "lcs_cit_idle_3,Start,,0,-1")
    sit1:SetKeyValue("OnBeginSequence", "relay_use_cit_3,Enable,,0,-1")
    sit1:SetKeyValue("OnBeginSequence", "citizen_refugees_3,AddContext,Citizens_Safe_Ep1_05:1,0,-1")
    sit1:SetKeyValue("OnBeginSequence", "lambda_rename_trigger_1,RunLua,,0,-1")
    sit1:Spawn()
    local sit2 = ents.Create("scripted_sequence")
    sit2:SetPos(Vector(9648, 9446, -735))
    sit2:SetName("lambda_ss_citizen_wait_points_4")
    sit2:SetAngles(Angle(0, 0, 0))
    sit2:SetKeyValue("m_iszEntity", "citizen_refugees_4")
    sit2:SetKeyValue("m_iszPlay", "Idle_to_Sit_Ground")
    sit2:SetKeyValue("m_iszPostIdle", "Sit_Ground")
    sit2:SetKeyValue("m_fMoveTo", "1")
    sit2:SetKeyValue("spawnflags", "356")
    sit2:SetKeyValue("OnBeginSequence", "lcs_cit_idle_4,Start,,0,-1")
    sit2:SetKeyValue("OnBeginSequence", "relay_use_cit_4,Enable,,0,-1")
    sit2:SetKeyValue("OnBeginSequence", "citizen_refugees_1,AddContext,Citizens_Safe_Ep1_05:1,0,-1")
    sit2:SetKeyValue("OnBeginSequence", "lambda_rename_trigger_2,RunLua,,0,-1")
    sit2:Spawn()
    GAMEMODE:WaitForInput("ss_citizen_wait_points_3", "CancelSequence", function(ent) return true end)
    GAMEMODE:WaitForInput("ss_citizen_wait_points_4", "CancelSequence", function(ent) return true end)
    GAMEMODE:WaitForInput("ss_citizen_wait_points_3", "Kill", function(ent) return true end)
    GAMEMODE:WaitForInput("ss_citizen_wait_points_4", "Kill", function(ent) return true end)
    local renameTrigger1 = ents.Create("lambda_lua_logic")
    renameTrigger1:SetName("lambda_rename_trigger_1")
    renameTrigger1.OnRunLua = function(trigger)
        local old = ents.FindFirstByName("ss_citizen_wait_points_3")
        if IsValid(old) then
            old:SetName("stub_ss_citizen_wait_points_3")
        end

        local new = ents.FindFirstByName("lambda_ss_citizen_wait_points_3")
        if IsValid(new) then
            new:SetName("ss_citizen_wait_points_3")
        end
    end

    renameTrigger1:Spawn()
    local renameTrigger2 = ents.Create("lambda_lua_logic")
    renameTrigger2:SetName("lambda_rename_trigger_2")
    renameTrigger2.OnRunLua = function(trigger)
        local old = ents.FindFirstByName("ss_citizen_wait_points_4")
        if IsValid(old) then
            old:SetName("stub_ss_citizen_wait_points_4")
        end

        local new = ents.FindFirstByName("lambda_ss_citizen_wait_points_4")
        if IsValid(new) then
            new:SetName("ss_citizen_wait_points_4")
        end
    end

    renameTrigger2:Spawn()
    ents.WaitForEntityByName(
        "ss_citizen_wait_points_3",
        function(ent)
            ent:SetKeyValue("OnBeginSequence", "lambda_rename_trigger_1,RunLua,,0,-1")
        end
    )

    ents.WaitForEntityByName(
        "ss_citizen_wait_points_4",
        function(ent)
            ent:SetKeyValue("OnBeginSequence", "lambda_rename_trigger_2,RunLua,,0,-1")
        end
    )

    -- Replace the NPCs that would spawn in the parking lot and use a better spawn.
    local parkingLotSpawner = ents.Create("npc_template_maker")
    parkingLotSpawner:SetKeyValue("TemplateName", "csoldier_parkinglot_cargroup")
    parkingLotSpawner:SetKeyValue("Radius", "128")
    parkingLotSpawner:SetKeyValue("MaxNPCCount", "4")
    parkingLotSpawner:SetKeyValue("MaxLiveChildren", "4")
    parkingLotSpawner:SetKeyValue("StartDisabled", "1")
    parkingLotSpawner:SetKeyValue("SpawnFrequency", "2")
    parkingLotSpawner:SetName("csoldier_parkinglot_spawner")
    parkingLotSpawner:SetPos(Vector(9849.166016, 12281.231445, -631.968750))
    parkingLotSpawner:Spawn()
    parkingLotSpawner:Activate()
    parkingLotSpawner:SetKeyValue("OnSpawnNPC", "csoldier_parkinglot_cargroup,Assault,rallypoint_parkinglot*,0,-1")
    local function CreateAssaultPoint(pos)
        local assaultPoint = ents.Create("assault_assaultpoint")
        assaultPoint:SetPos(pos)
        assaultPoint:SetKeyValue("targetname", "assaultpoint_parkinglot")
        assaultPoint:SetKeyValue("assaultpointtype", "1")
        assaultPoint:SetKeyValue("clearoncontact", "0")
        assaultPoint:SetKeyValue("urgent", "1")
        assaultPoint:Spawn()
    end

    CreateAssaultPoint(Vector(9832.306641, 11567.169922, -703.968750))
    CreateAssaultPoint(Vector(9567.196289, 11502.808594, -704.058777))
    CreateAssaultPoint(Vector(10292.733398, 11504.300781, -695.968750))
    CreateAssaultPoint(Vector(9488.129883, 10744.701172, -831.968750))
    CreateAssaultPoint(Vector(10335.364258, 11658.113281, -703.968750))
    CreateAssaultPoint(Vector(9641.139648, 11862.100586, -703.968750))
    CreateAssaultPoint(Vector(10027.281250, 10899.580078, -832.058777))
    local function CreateRallyPoint(pos, name)
        local rallyPoint = ents.Create("assault_rallypoint")
        rallyPoint:SetPos(pos)
        rallyPoint:SetKeyValue("targetname", name)
        rallyPoint:SetKeyValue("assaultpoint", "assaultpoint_parkinglot")
        rallyPoint:SetKeyValue("urgent", "1")
        rallyPoint:Spawn()
    end

    -- Ensure we have enough rally points, this is a engine limitation that only one NPC can use it at a time.
    for i = 0, 20 do
        CreateRallyPoint(Vector(9832.306641, 11567.169922, -703.968750), "rallypoint_parkinglot" .. i)
    end

    ents.WaitForEntityByName(
        "trigger_csoldiers_cargroup",
        function(ent)
            ent:Fire("AddOutput", "OnTrigger csoldier_parkinglot_spawner,Enable,,0,-1", "0.0")
        end
    )
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

function MAPSCRIPT:EntityKeyValue(ent, key, value)
    -- HACKHACK: There is an issue with NPCs and multiple players.
    -- https://github.com/Facepunch/garrysmod-issues/issues/5795
    if key:iequals("sleepstate") then return "0" end
end

return MAPSCRIPT