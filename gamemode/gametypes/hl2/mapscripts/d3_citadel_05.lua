if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_physcannon"},
    Ammo = {},
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["pod_ready_counter"] = {"Kill"},
    ["relay_playerpod_resume"] = {"Kill"},
    ["counter_pod_alive"] = {"Subtract"}
}

MAPSCRIPT.EntityFilterByClass = {
    ["env_fade"] = true
}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_spawner_suit"] = true,
    ["playerpod1_train"] = true,
    ["playerpod2_train"] = true,
    ["playerpod3_train"] = true,
    ["playerpod4_train"] = true,
    ["playerpod5_train"] = true,
    ["playerpod6_train"] = true,
    ["playerpod7_train"] = true,
    ["playerpod1_vehicle"] = true,
    ["playerpod2_vehicle"] = true,
    ["playerpod3_vehicle"] = true,
    ["playerpod4_vehicle"] = true,
    ["playerpod5_vehicle"] = true,
    ["playerpod6_vehicle"] = true,
    ["playerpod7_vehicle"] = true,
    ["playerpod1_rotator"] = true,
    ["playerpod2_rotator"] = true,
    ["playerpod3_rotator"] = true,
    ["playerpod4_rotator"] = true,
    ["playerpod5_rotator"] = true,
    ["playerpod6_rotator"] = true,
    ["playerpod7_rotator"] = true,
    ["playerpod1_constraint"] = true,
    ["playerpod2_constraint"] = true,
    ["playerpod3_constraint"] = true,
    ["playerpod4_constraint"] = true,
    ["playerpod5_constraint"] = true,
    ["playerpod6_constraint"] = true,
    ["playerpod7_constraint"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_ON
}

POD_COUNTER = POD_COUNTER or 0

function CreatePOD(bayname)
    POD_COUNTER = POD_COUNTER + 1
    local trainName = "lambda_pod_train_" .. POD_COUNTER
    local rotatorName = "lambda_pod_rotator_" .. POD_COUNTER
    local podName = "lambda_pod_" .. POD_COUNTER
    local func_tracktrain = ents.Create("func_tracktrain")
    func_tracktrain:SetKeyValue("target", bayname)
    func_tracktrain:SetKeyValue("model", "*31")
    func_tracktrain:SetKeyValue("bank", "0")
    func_tracktrain:SetKeyValue("stopsound", "d3_citadel.playerpod_stop")
    func_tracktrain:SetKeyValue("movesound", "d3_citadel.playerpod_move")
    func_tracktrain:SetKeyValue("startspeed", "1000")
    func_tracktrain:SetKeyValue("speed", "100")
    func_tracktrain:SetKeyValue("spawnflags", "11")
    func_tracktrain:SetKeyValue("volume", "3")
    func_tracktrain:SetKeyValue("height", "4")
    func_tracktrain:SetKeyValue("velocitytype", "1")
    func_tracktrain:SetKeyValue("orientationtype", "3")
    func_tracktrain:SetKeyValue("origin", "-133 546 -2873")
    func_tracktrain:SetKeyValue("targetname", trainName)
    func_tracktrain:SetKeyValue("wheels", "0")
    --func_tracktrain:SetNotSolid(true)
    func_tracktrain:Fire("AddOutput", "onuser1 " .. rotatorName .. ",Open,,0,-1")
    func_tracktrain:Fire("AddOutput", "onuser1 " .. podName .. ",Open,,1,-1")
    func_tracktrain:Fire("AddOutput", "onuser1 " .. podName .. ",Close,,4,-1")
    func_tracktrain:Fire("AddOutput", "onuser1 " .. rotatorName .. ",Close,,5,-1")
    func_tracktrain:Spawn()
    func_tracktrain:Activate()
    local arm = ents.Create("prop_dynamic")
    arm:SetKeyValue("model", "models/vehicles/Inner_pod_arm.mdl")
    arm:SetKeyValue("origin", "-138 537 -2891")
    arm:SetKeyValue("angles", "0 270 0")
    arm:SetKeyValue("parentname", trainName)
    arm:SetParent(func_tracktrain)
    arm:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    arm:Spawn()
    arm:Activate()
    local func_door_rotating = ents.Create("func_door_rotating")
    func_door_rotating:SetKeyValue("speed", "100")
    func_door_rotating:SetKeyValue("spawnflags", "34")
    func_door_rotating:SetKeyValue("distance", "90")
    func_door_rotating:SetKeyValue("wait", "-1")
    func_door_rotating:SetKeyValue("spawnpos", "0")
    func_door_rotating:SetKeyValue("lip", "0")
    func_door_rotating:SetKeyValue("spawnpos", "0")
    func_door_rotating:SetKeyValue("angles", "0 0 0")
    func_door_rotating:SetKeyValue("origin", "-141.39 529.67 -2879")
    func_door_rotating:SetKeyValue("targetname", rotatorName)
    func_door_rotating:SetKeyValue("model", "*62")
    func_door_rotating:SetKeyValue("parentname", trainName)
    func_door_rotating:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    func_door_rotating:SetParent(func_tracktrain)
    func_door_rotating:Spawn()
    func_door_rotating:Activate()
    local rotator = ents.Create("prop_dynamic")
    rotator:SetKeyValue("angles", "0 270 0")
    rotator:SetKeyValue("model", "models/vehicles/Inner_pod_rotator.mdl")
    rotator:SetKeyValue("origin", "-138 537 -2890.91")
    rotator:SetKeyValue("parentname", rotatorName)
    rotator:SetParent(func_door_rotating)
    rotator:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    rotator:Spawn()
    local pod = ents.Create("prop_vehicle_prisoner_pod")
    pod:SetKeyValue("model", "models/vehicles/prisoner_pod_inner.mdl")
    pod:SetKeyValue("origin", "-159 530 -2965")
    pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
    pod:SetKeyValue("angles", "15 0 0")
    pod:SetKeyValue("targetname", podName)
    pod:Fire("AddOutput", "PlayerOn !self,Close,,0,-1")
    pod:Fire("AddOutput", "PlayerOn !self,Lock,,0.01,-1")
    pod:Spawn()
    pod:Activate()
    local podConstraint = ents.Create("phys_ragdollconstraint")
    podConstraint:SetKeyValue("xfriction", "0.8")
    podConstraint:SetKeyValue("xmax", "0.0")
    podConstraint:SetKeyValue("xmin", "0.0")
    podConstraint:SetKeyValue("yfriction", "0.8")
    podConstraint:SetKeyValue("ymax", "20")
    podConstraint:SetKeyValue("ymin", "-20")
    podConstraint:SetKeyValue("zfriction", "0.8")
    podConstraint:SetKeyValue("zmax", "0.0")
    podConstraint:SetKeyValue("zmin", "0.0")
    podConstraint:SetKeyValue("spawnflags", "1")
    podConstraint:SetKeyValue("origin", "-138 529 -2889")
    podConstraint:SetKeyValue("attach2", rotatorName)
    podConstraint:SetKeyValue("attach1", podName)
    podConstraint:SetParent(rotator)
    podConstraint:Spawn()
    podConstraint:Activate()

    ents.WaitForEntityByName(bayname, function(ent)
        func_tracktrain:SetPos(ent:GetPos())
    end)

    return func_tracktrain
end

function MAPSCRIPT:PostInit()
    if SERVER then
        CreatePOD("pod_bay_track1")
        CreatePOD("pod_bay_track2")
        CreatePOD("pod_bay_track3")
        CreatePOD("pod_bay_track4")
        CreatePOD("pod_bay_track5")
        CreatePOD("pod_bay_track8")
        CreatePOD("pod_bay_track9")
        local podCreateTrigger = ents.Create("trigger_multiple")
        podCreateTrigger:SetName("lambda_pod_create")
        podCreateTrigger:SetupTrigger(Vector(1005.086487, -512.151855, -3000.966553), Angle(0, 0, 0), Vector(-20, -50, 0), Vector(20, 50, 200))
        podCreateTrigger:SetKeyValue("spawnflags", "8")
        podCreateTrigger:SetKeyValue("wait", "4")

        podCreateTrigger.OnTrigger = function(_, ent)
            CreatePOD("pod_bay_track1")
            ent:SetNotSolid(true)
        end

        ents.WaitForEntityByName("path_pod_ok_4", function(ent)
            ent:Fire("AddOutput", "OnPass lambda_pod_create,Trigger,,0.0,-1")
        end)

        ents.WaitForEntityByName("pod_02_track0", function(ent)
            ent:Fire("AddOutput", "OnPass pod_02_track_inspection,DisableAlternatePath,,0.0")
        end)

        ents.WaitForEntityByName("cit05_to_breen01_changelevel", function(ent)
            ent:SetKeyValue("teamwait", "1")
        end)

        ents.WaitForEntityByName("relay_playerpod_resume", function(ent)
            ent:Fire("AddOutput", "OnTrigger lambda_pod_train*,Resume,, 0.1, -1")
        end)

        ents.WaitForEntityByName("path_pod_ok_4", function(ent)
            ent:Fire("AddOutput", "OnPass relay_playerpod_resume,Resume,,0.1,-1")
        end)

        for _, v in pairs(ents.FindByPos(Vector(936.5, -512, -2902), "trigger_once")) do
            v:Remove()
        end

        local cameraTrigger = ents.Create("trigger_multiple")
        cameraTrigger:SetupTrigger(Vector(936.5, -512, -3002), Angle(0, 0, 0), Vector(-10, -50, 0), Vector(10, 50, 200))
        cameraTrigger:SetName("lambda_camera_trigger")
        cameraTrigger:Fire("AddOutput", "OnStartTouch pod_02_track_inspection,EnableAlternatePath,,0.0,-1")
        cameraTrigger:Fire("AddOutput", "OnStartTouch pen_camera_1,SetAngry,,0.5,-1")

        ents.WaitForEntityByName("pen_camera_1", function(ent)
            ent:SetKeyValue("outerradius", "200")
            ent:SetKeyValue("innerradius", "150")
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT