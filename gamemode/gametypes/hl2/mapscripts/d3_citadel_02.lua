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

function MAPSCRIPT:Init()

    self.PlayerQueue = {}

end

function MAPSCRIPT:CreatePlayerPod()

    local tracktrain = ents.Create("func_tracktrain")
    tracktrain:SetKeyValue("movesound", "d3_citadel.playerpod_move")
    tracktrain:SetKeyValue("volume", "d3_citadel.playerpod_move")
    tracktrain:SetKeyValue("velocitytype", "1")
    tracktrain:SetKeyValue("target", "pod_player_start")
    tracktrain:SetKeyValue("stopsound", "d3_citadel.playerpod_stop")
    tracktrain:SetKeyValue("spawnflags", "11")
    tracktrain:SetKeyValue("startspeed", "200")
    tracktrain:SetKeyValue("orientationtype", "3")
    tracktrain:SetKeyValue("wheels", "0")
    -- -6272.000000 6656.000000 2754.000000
    tracktrain:SetPos(Vector(-6466, 6656, 2754))
    --tracktrain:SetName("podtrain_player")
    tracktrain:Spawn()
    tracktrain:Activate()

    local podarm = ents.Create("prop_dynamic")
    podarm:SetModel("models/vehicles/Inner_pod_arm.mdl")
    podarm:SetPos(Vector(-6471, 6647, 2736))
    podarm:SetAngles(Angle(0, 270, 0))
    podarm:SetParent(tracktrain)
    podarm:Spawn()

    local podrotator = ents.Create("prop_dynamic")
    podrotator:SetModel("models/vehicles/Inner_pod_rotator.mdl")
    podrotator:SetPos(Vector(-6471, 6647, 2736))
    podrotator:SetAngles(Angle(0, 270, 0))
    podrotator:SetParent(tracktrain)
    podrotator:Spawn()

    local pod = ents.Create("prop_vehicle_prisoner_pod")
    pod:SetName("pod_player2")
    pod:SetPos(Vector(-6472, 6640, 2661))
    pod:SetAngles(Angle(0, 0, 0))
    pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
    pod:SetModel("models/vehicles/prisoner_pod_inner.mdl")
    pod:Spawn()
    pod:Activate()
    --pod:SetParent(tracktrain)

    -- FIXME: This is somewhat wrong.
    local rel1 = Vector(-3, -3, 0)
    local rel2 = Vector(14, -1, 37)
    -- Constraint
    constraint.AdvBallsocket(podrotator, pod, 0, 0, rel1, rel2, 0, 0, 0, -15, 0, 0, 15, 0, 0.8, 0.8, 0.8, 0, 1)

    return pod, tracktrain

end

function MAPSCRIPT:Think()

    if not SERVER then return end

    local ct = CurTime()

    for k,v in pairs(self.PlayerQueue or {}) do
        if ct < v.timestamp then
            continue
        end
        table.remove(self.PlayerQueue, k)

        local ply = v.player
        if IsValid(ply) and ply:Alive() == true then
            local pod, tracktrain = self:CreatePlayerPod()
            ply:RemoveEffects(EF_NODRAW)
            ply:DrawWorldModel(true)
            ply:DrawViewModel(true)
            ply:EnterVehicle(pod)
            tracktrain:Fire("StartForward")
        end

        break
    end

end

function MAPSCRIPT:PostInit()

    if SERVER then

        self.PlayerQueue = {}
        self.NextPlayerPod = CurTime() + 2

        ents.WaitForEntityByName("track_dump", function(ent)
            ent:SetWaitTime(0.2) -- Turn to trigger_multiple.
            ent.OnTrigger = function(ent, other)
                if other:IsPlayer() and IsValid(other:GetVehicle()) then
                    local vehicle = other:GetVehicle()
                    vehicle:Fire("Unlock")
                    vehicle:Fire("Open")
                    vehicle:Fire("ExitVehicle", "", 1)
                    vehicle:Remove()
                end
            end
        end)

        ents.WaitForEntityByName("trigger_leave_level", function(ent)
            ent:SetKeyValue("teamwait", "1")
            ent.OnTrigger = function()
                TriggerOutputs({
                    {"trigger_vphysics_03_fall", "Kill", "", 0.0},
                    {"cit02_cit03_trans", "ChangeLevel", "", 2.00},
                })
            end
        end)

        ents.WaitForEntityByName("pod_player", function(ent)
            -- FIX: Only remove if theres no transitioned player in it.
            if IsValid(ent:GetDriver()) == false then
                ent:Remove()
            end
        end)

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

    self.NextPlayerPod = self.NextPlayerPod + 4

end

return MAPSCRIPT
