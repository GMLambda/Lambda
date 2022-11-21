AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = true
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_lambda_medkit",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
        "weapon_physcannon",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_ar2",
        "weapon_rpg",
        "weapon_crossbow",
        "weapon_bugbait",
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
        ["XBowBolt"] = 4,
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["citadel_fade_in"] = true,
    --["logic_podtrains_L_start_1"] = true,
    ["pod_player"] = true,
    ["podtrain_player"] = true,
}

MAPSCRIPT.PlayerQueue = {}
MAPSCRIPT.NextPlayerPod = CurTime()

function MAPSCRIPT:CreatePlayerPod(id)

    local tracktrain = ents.Create("func_tracktrain")
    tracktrain:SetKeyValue("MoveSound", "d3_citadel.playerpod_move")
    tracktrain:SetKeyValue("MoveSoundMaxPitch", "130")
    tracktrain:SetKeyValue("MoveSoundMinPitch", "90")
    tracktrain:SetKeyValue("orientationtype", "3")
    tracktrain:SetKeyValue("volume", "10")
    tracktrain:SetKeyValue("velocitytype", "1")
    tracktrain:SetKeyValue("StopSound", "d3_citadel.playerpod_stop")
    tracktrain:SetKeyValue("spawnflags", "11")
    tracktrain:SetKeyValue("speed", "0")
    tracktrain:SetKeyValue("startspeed", "200")
    tracktrain:SetKeyValue("wheels", "0")
    tracktrain:SetKeyValue("height", "4")
    tracktrain:SetKeyValue("bank", "0")
    tracktrain:SetKeyValue("ManualAccelSpeed", "0")
    tracktrain:SetKeyValue("ManualDecelSpeed", "0")
    tracktrain:SetKeyValue("MoveSoundMaxTime", "0")
    tracktrain:SetKeyValue("MoveSoundMinTime", "0")

    -- pod_player38
    -- pod_player_start
    tracktrain:SetKeyValue("target", "pod_player_start")
    tracktrain:SetName("podtrain_player_" .. tostring(id))
    tracktrain:SetPos(Vector(-6466, 6734, 2727))
    tracktrain:Spawn()
    tracktrain:Activate()
    
    local podarm = ents.Create("prop_dynamic")
    podarm:SetModel("models/vehicles/Inner_pod_arm.mdl")
    podarm:SetPos(Vector(-6471, 6725, 2709))
    podarm:SetAngles(Angle(0, 270, 0))
    podarm:SetParent(tracktrain)
    podarm:Spawn()

    local podrotator = ents.Create("prop_dynamic")
    podrotator:SetModel("models/vehicles/Inner_pod_rotator.mdl")
    podrotator:SetPos(Vector(-6471, 6725, 2709.09))
    podrotator:SetAngles(Angle(0, 270, 0))
    podrotator:SetParent(podarm)
    podrotator:SetName("podrotator_" .. tostring(id))
    podrotator:Spawn()

    local pod = ents.Create("prop_vehicle_prisoner_pod")
    pod:SetName("pod_player_" .. tostring(id))
    pod:SetPos(Vector(-6492, 6718, 2635))
    pod:SetAngles(Angle(15, 0, 0))
    pod:SetModel("models/vehicles/prisoner_pod_inner.mdl")
    pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
    pod:SetKeyValue("vehiclelocked", "1")
    pod:SetKeyValue("solid", "0")
    -- HACK: Instead of a constraint we parent it, constraints pretty unstable and odd
    -- looking in multiplayer.
    pod:SetParent(podrotator)
    pod:Spawn()
    pod:Activate()

    tracktrain.AttachedChildPod = pod

    return pod, tracktrain

end

function MAPSCRIPT:Think()

    if not SERVER then return end

    local ct = CurTime()

    for k,v in pairs(self.PlayerQueue) do
        if ct < v.timestamp then
            continue
        end
        table.remove(self.PlayerQueue, k)

        local ply = v.player
        if IsValid(ply) and ply:Alive() == true then
            local pod, tracktrain = self:CreatePlayerPod(ply:EntIndex())
            -- Delay entering vehicle until next frame, this seems
            -- to cause issues otherwise.
            util.RunNextFrame(function()
                ply:RemoveEffects(EF_NODRAW)
                ply:DrawWorldModel(true)
                ply:DrawViewModel(true)
                ply:EnterVehicle(pod)
                tracktrain:Fire("StartForward")
            end)
        end

        break
    end

end

local function DropPod(tracktrain)

    local pod = tracktrain.AttachedChildPod
    local pos = pod:GetPos()

    local randVec = VectorRand() * 5
    randVec.z = -1
    randVec.y = randVec.y + 30

    pod:SetParent(nil)
    pod:SetPos(pos)
    local physObj = pod:GetPhysicsObject()
    if IsValid(physObj) then
        physObj:SetVelocity(randVec)
    end

    local effectdata = EffectData()
    effectdata:SetOrigin( tracktrain:GetPos() )
    effectdata:SetMagnitude(5)
    effectdata:SetScale(1)
    util.Effect( "ManhackSparks", effectdata )

    local effectdata = EffectData()
    effectdata:SetOrigin( tracktrain:GetPos() )
    effectdata:SetMagnitude(5)
    effectdata:SetScale(1)
    util.Effect( "Sparks", effectdata )

    tracktrain:EmitSound("Metal_Box.Break")

    tracktrain:Remove()

end

function MAPSCRIPT:PostInit()

    if SERVER then

        self.PlayerQueue = {}
        self.NextPlayerPod = CurTime()

        local dissolver = ents.Create("env_entity_dissolver")
        dissolver:SetPos(Vector(3917.164063, 13303.861328, 4439.324707))
        dissolver:SetKeyValue("dissolvetype", "0")
        dissolver:SetKeyValue("magnitude", "250")
        dissolver:Spawn()
        dissolver:Activate()

        ents.WaitForEntityByName("track_dump", function(ent)
            ent:SetWaitTime(0.2) -- Turn to trigger_multiple.
            ent:Fire("Enable")
            ent:SetKeyValue("spawnflags", "33")
            ent.StartTouch = function(ent, other)
                if other:IsPlayer() then
                    other:LockPosition(false)
                end
            end
        end)

        ents.WaitForEntityByName("trigger_leave_level", function(ent)
            ent:SetKeyValue("teamwait", "1")
            ent.OnTrigger = function()
                TriggerOutputs({
                    {"trigger_vphysics_03_fall", "Kill", 0.0, ""},
                    {"cit02_cit03_trans", "ChangeLevel", 2.0, ""},
                })
            end
        end)

        local pathDisconnect = ents.Create("lambda_path_tracker")
        pathDisconnect:SetName("lambda_drop_pod")
        pathDisconnect.OnPass = function(s, data, activator, caller)
            if IsValid(activator) and IsValid(activator.AttachedChildPod) then
                DropPod(activator)
            end
        end
        pathDisconnect:Spawn()

        ents.WaitForEntityByName("pod_player37", function(ent)
            ent:Fire("AddOutput", "OnPass lambda_drop_pod,OnPass,,0,-1")
        end)

        local dissolveTrigger = ents.Create("trigger_multiple")
        dissolveTrigger:SetupTrigger(
            Vector(3889.122803, 13407.586914, 3520.031250),
            Angle(0, 0, 0),
            Vector(-160, -260, 0),
            Vector(160, 260, 30)
        )
        dissolveTrigger:AddSpawnFlags(66)
        dissolveTrigger:SetName("lambda_dissolve_trigger")
        dissolveTrigger.OnStartTouch = function(ent, other)
            if other:IsVehicle() then
                dissolver:Fire("Dissolve", other:GetName())
            end
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    DbgPrint("PostPlayerSpawn")

    ply:LockPosition(true)
    ply:SetMoveType(MOVETYPE_FLY)
    ply:AddEffects(EF_NODRAW)
    ply:DrawWorldModel(false)
    ply:DrawViewModel(false)

    table.insert(self.PlayerQueue, {
        timestamp = self.NextPlayerPod,
        player = ply
    })

    local curTime = CurTime()
    if curTime > self.NextPlayerPod then
        self.NextPlayerPod = curTime
    end
    self.NextPlayerPod = self.NextPlayerPod + 5

end

return MAPSCRIPT
