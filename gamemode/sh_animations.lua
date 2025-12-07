if SERVER then AddCSLuaFile() end
local CurTime = CurTime
local Vector = Vector
local math = math
local IsValid = IsValid
local math_Clamp = math.Clamp
--local DbgPrint = GetLogging("Animation")
local function HandlePlayerJumping(ply, data, velocity)
    if data.MoveType == MOVETYPE_NOCLIP then
        data.m_bJumping = false
        return
    end

    local waterLevel = data.WaterLevel
    local onGround = data.IsOnGround
    local curTime = CurTime()

    -- airwalk more like hl2mp, we airwalk until we have 0 velocity, then it's the jump animation
    -- underwater we're alright we airwalking
    if not data.m_bJumping and not onGround and waterLevel <= 0 then
        if not data.m_fGroundTime then
            data.m_fGroundTime = curTime
        elseif (curTime - data.m_fGroundTime) > 0 and velocity:Length2DSqr() < 0.25 then
            data.m_bJumping = true
            data.m_bFirstJumpFrame = false
            data.m_flJumpStartTime = 0
        end
    end

    if data.m_bJumping then
        if data.m_bFirstJumpFrame then
            data.m_bFirstJumpFrame = false
            ply:AnimRestartMainSequence()
        end

        if (waterLevel >= 2) or ((curTime - data.m_flJumpStartTime) > 0.2 and onGround) then
            data.m_bJumping = false
            data.HandledCrouching = false
            data.m_fGroundTime = nil
            ply:AnimRestartMainSequence()
        end

        if data.m_bJumping then
            data.CalcIdeal = ACT_MP_JUMP
            return true
        end
    end
    return false
end

local function HandlePlayerDucking(ply, data, velocity)
    if ply:IsFlagSet(FL_ANIMDUCKING) == false and ply:Crouching() == false then return false end
    if velocity:Length2DSqr() > 0.25 then
        data.CalcIdeal = ACT_MP_CROUCHWALK
    else
        data.CalcIdeal = ACT_MP_CROUCH_IDLE
    end
    return true
end

local function HandlePlayerNoClipping(ply, data, velocity)
    if data.MoveType ~= MOVETYPE_NOCLIP or ply:InVehicle() then
        if data.m_bWasNoclipping then
            data.m_bWasNoclipping = nil
            ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
            if CLIENT then ply:SetIK(true) end
        end
        return
    end

    if not ply.m_bWasNoclipping then
        ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_NOCLIP_LAYER, false)
        if CLIENT then ply:SetIK(false) end
    end
    return true
end

local function HandlePlayerVaulting(ply, data, velocity)
    if velocity:LengthSqr() < 1000000 then return end
    if data.IsOnGround then return end
    data.CalcIdeal = ACT_MP_SWIM
    return true
end

local function HandlePlayerSwimming(ply, data, velocity)
    if data.WaterLevel < 2 or data.IsOnGround then
        data.m_bInSwim = false
        return false
    end

    data.CalcIdeal = ACT_MP_SWIM
    data.m_bInSwim = true
    return true
end

function GM:HandlePlayerLanding(ply, data, velocity, WasOnGround)
    if data.MoveType == MOVETYPE_NOCLIP then return end
    if data.IsOnGround and not WasOnGround then ply:AnimRestartGesture(GESTURE_SLOT_JUMP, ACT_LAND, true) end
end

local function HandlePlayerDriving(ply, data)
    if not ply:InVehicle() then return false end
    local pVehicle = ply:GetVehicle()
    if not pVehicle.HandleAnimation and pVehicle.GetVehicleClass then
        local c = pVehicle:GetVehicleClass()
        local t = list.Get("Vehicles")[c]
        if t and t.Members and t.Members.HandleAnimation then
            pVehicle.HandleAnimation = t.Members.HandleAnimation
        else
            pVehicle.HandleAnimation = true
        end
    end

    local class = pVehicle:GetClass()
    if isfunction(pVehicle.HandleAnimation) then
        local seq = pVehicle:HandleAnimation(ply)
        if seq ~= nil then data.CalcSeqOverride = seq end
    end

    -- pVehicle.HandleAnimation did not give us an animation
    if data.CalcSeqOverride == -1 then
        if class == "prop_vehicle_jeep" then
            data.CalcSeqOverride = ply:LookupSequence("drive_jeep")
        elseif class == "prop_vehicle_airboat" then
            data.CalcSeqOverride = ply:LookupSequence("drive_airboat")
        elseif class == "prop_vehicle_prisoner_pod" and pVehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" then
            -- HACK!!
            data.CalcSeqOverride = ply:LookupSequence("drive_pd")
        else
            data.CalcSeqOverride = ply:LookupSequence("sit_rollercoaster")
        end
    end

    local use_anims = data.CalcSeqOverride == ply:LookupSequence("sit_rollercoaster") or data.CalcSeqOverride == ply:LookupSequence("sit")
    if use_anims and ply:GetAllowWeaponsInVehicle() and IsValid(ply:GetActiveWeapon()) then
        local holdtype = ply:GetActiveWeapon():GetHoldType()
        if holdtype == "smg" then holdtype = "smg1" end
        local seqid = ply:LookupSequence("sit_" .. holdtype)
        if seqid ~= -1 then data.CalcSeqOverride = seqid end
    end
    return true
end

local function GrabEarAnimation(ply, data)
    ply.ChatGestureWeight = ply.ChatGestureWeight or 0
    -- Don't show this when we're playing a taunt!
    if ply:IsPlayingTaunt() then return end
    if ply:IsTyping() then
        data.ChatGestureWeight = math.Approach(data.ChatGestureWeight, 1, FrameTime() * 5.0)
    else
        data.ChatGestureWeight = math.Approach(data.ChatGestureWeight, 0, FrameTime() * 5.0)
    end

    if data.ChatGestureWeight > 0 then
        ply:AnimRestartGesture(GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true)
        ply:AnimSetGestureWeight(GESTURE_SLOT_VCD, data.ChatGestureWeight)
    end
end

local function MouthMoveAnimation(ply)
    local flexes = {ply:GetFlexIDByName("jaw_drop"), ply:GetFlexIDByName("left_part"), ply:GetFlexIDByName("right_part"), ply:GetFlexIDByName("left_mouth_drop"), ply:GetFlexIDByName("right_mouth_drop")}
    local weight = ply:IsSpeaking() and math_Clamp(ply:VoiceVolume() * 2, 0, 2) or 0
    for k, v in pairs(flexes) do
        ply:SetFlexWeight(v, weight)
    end
end

function GM:UpdateAnimation(ply, velocity, maxseqgroundspeed)
    local data = ply:GetTable()
    local len = velocity:Length()
    local movement = len / maxseqgroundspeed
    local rate = math.min(movement, 2)
    -- if we're under water we want to constantly be swimming..
    if ply:WaterLevel() >= 2 then
        rate = math.max(rate, 0.5)
    elseif not ply:IsOnGround() and len >= 1000 then
        rate = 0.1
    end

    ply:SetPlaybackRate(rate)
    if ply:InVehicle() then
        local Vehicle = ply:GetVehicle()
        -- We only need to do this clientside..
        if CLIENT then
            local Velocity = Vehicle:GetVelocity()
            local fwd = Vehicle:GetUp()
            local dp = fwd:Dot(Vector(0, 0, 1))
            local dp2 = fwd:Dot(Velocity)
            ply:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + dp2 * 0.005)
            -- Pass the vehicles steer param down to the player
            local steer = Vehicle:GetPoseParameter("vehicle_steer")
            steer = steer * 2 - 1 -- convert from 0..1 to -1..1
            if Vehicle:GetClass() == "prop_vehicle_prisoner_pod" then
                steer = 0
                ply:SetPoseParameter("aim_yaw", math.NormalizeAngle(ply:GetAimVector():Angle().y - Vehicle:GetAngles().y - 90))
            end

            ply:SetPoseParameter("vehicle_steer", steer)
        end
    end

    if CLIENT then
        GrabEarAnimation(ply, data)
        MouthMoveAnimation(ply, data)
    end
end

function GM:CalcMainActivity(ply, velocity)
    local data = ply:GetTable()
    data.CalcIdeal = ACT_MP_STAND_IDLE
    data.CalcSeqOverride = -1
    data.IsOnGround = ply:IsOnGround()
    data.WaterLevel = ply:WaterLevel()
    data.MoveType = ply:GetMoveType()
    self:HandlePlayerLanding(ply, velocity, data.m_bWasOnGround)
    local isHandled = HandlePlayerNoClipping(ply, data, velocity) or HandlePlayerDriving(ply, data) or HandlePlayerVaulting(ply, data, velocity) or HandlePlayerJumping(ply, data, velocity) or HandlePlayerSwimming(ply, data, velocity) or HandlePlayerDucking(ply, data, velocity)
    if not isHandled then
        local len2d = velocity:Length2DSqr()
        if len2d > 22500 then
            data.CalcIdeal = ACT_MP_RUN
        elseif len2d > 0.25 then
            data.CalcIdeal = ACT_MP_WALK
        end
    end

    data.m_bWasOnGround = data.IsOnGround
    data.m_bWasNoclipping = data.MoveType == MOVETYPE_NOCLIP and not ply:InVehicle()
    return data.CalcIdeal, data.CalcSeqOverride
end

local IdleActivity = ACT_HL2MP_IDLE
local IdleActivityTranslate = {}
IdleActivityTranslate[ACT_MP_STAND_IDLE] = IdleActivity
IdleActivityTranslate[ACT_MP_WALK] = IdleActivity + 1
IdleActivityTranslate[ACT_MP_RUN] = IdleActivity + 2
IdleActivityTranslate[ACT_MP_CROUCH_IDLE] = IdleActivity + 3
IdleActivityTranslate[ACT_MP_CROUCHWALK] = IdleActivity + 4
IdleActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_RELOAD_STAND] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_RELOAD_CROUCH] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
IdleActivityTranslate[ACT_MP_SWIM] = IdleActivity + 9
IdleActivityTranslate[ACT_LAND] = ACT_LAND
-- it is preferred you return ACT_MP_* in CalcMainActivity, and if you have a specific need to not tranlsate through the weapon do it here
function GM:TranslateActivity(ply, act)
    local newact = ply:TranslateWeaponActivity(act)
    -- select idle anims if the weapon didn't decide
    if act == newact then return IdleActivityTranslate[act] end
    return newact
end

local function HandleAnimAttackPrimary(ply, event, data)
    if ply:Crouching() then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_ATTACK_CROUCH_PRIMARYFIRE, true)
    else
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_ATTACK_STAND_PRIMARYFIRE, true)
    end
    return ACT_VM_PRIMARYATTACK
end

local function HandleAnimSecondaryAttack(ply, event, data)
    return ACT_VM_SECONDARYATTACK
end

local function HandleAnimReload(ply, event, data)
    if ply:Crouching() then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_RELOAD_CROUCH, true)
    else
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_RELOAD_STAND, true)
    end

    if SERVER then GAMEMODE:OnPlayerReload(ply, event, data) end
    return ACT_INVALID
end

local function HandleAnimJump(ply, event, data)
    ply.m_bJumping = true
    ply.m_bFirstJumpFrame = true
    ply.m_flJumpStartTime = CurTime()
    ply:AnimRestartMainSequence()
    return PLAYERANIMEVENT_JUMP
end

local function HandleAnimCancelReload(ply, event, data)
    ply:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
    return ACT_INVALID
end

-- FIXME: COMPATIBILITY, remove once update is out.
if PLAYERANIMEVENT_CANCEL_RELOAD == nil then PLAYERANIMEVENT_CANCEL_RELOAD = 23 end
local HANDLE_ANIM = {
    [PLAYERANIMEVENT_ATTACK_PRIMARY] = HandleAnimAttackPrimary,
    [PLAYERANIMEVENT_ATTACK_SECONDARY] = HandleAnimSecondaryAttack,
    [PLAYERANIMEVENT_RELOAD] = HandleAnimReload,
    [PLAYERANIMEVENT_CANCEL_RELOAD] = HandleAnimCancelReload,
    [PLAYERANIMEVENT_JUMP] = HandleAnimJump
}

function GM:DoAnimationEvent(ply, event, data)
    if event == nil then return ACT_INVALID end
    local fn = HANDLE_ANIM[event]
    if fn ~= nil then return fn(ply, event, data) end
    return ACT_INVALID
end