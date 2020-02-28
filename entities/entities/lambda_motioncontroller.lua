if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("motioncontroller")
local abs = math.abs
local PREDICTION_TOLERANCE = 33
local PREDICTION_THRESHOLD = 1
local DEFAULT_MAX_ANGULAR = 360.0 * 10.0
local REDUCED_CARRY_MASS = 1.0

DEFINE_BASECLASS("base_entity")

ENT.Base = "base_entity"
ENT.Type = "anim"

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "TargetPos")
    self:NetworkVar("Angle", 0, "TargetAng")
    self:NetworkVar("Float", 0, "TimeToArrive")
    self:NetworkVar("Entity", 0, "TargetObject")
end
    
function ENT:ResetState()
    local shadowParams = {}

    -- Initialize shadow params.
    shadowParams.dt = 0
    shadowParams.secondstoarrive = 0
    shadowParams.maxangular = DEFAULT_MAX_ANGULAR
    shadowParams.maxangulardamp = shadowParams.maxangular
    shadowParams.maxspeed = 4000
    shadowParams.maxspeeddamp = shadowParams.maxspeed * 2
    shadowParams.dampfactor = 0.8
    shadowParams.teleportdistance = 0

    self.ShadowParams = shadowParams
    self.SavedMass = {}
    self.SavedRotDamping = {}
    self.ErrorTime = -1.0
    self.Error = -1.0
    self.ContactAmount = 0
    self.LoadWeight = 0

end

function ENT:Initialize()

    DbgPrint(self, "Initialize")

    self:SetTargetTransform(Vector(0, 0, 0), Angle(0, 0, 0))
    self:ResetState()

    -- We don't need anything visible.
    self:SetNotSolid(true)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetNoDraw(true)

end

function ENT:SetTargetTransform(pos, ang)
    self:SetTargetPos(pos)
    self:SetTargetAng(ang)
    if SERVER then
        self:SetTimeToArrive(FrameTime())
    end
end

function ENT:UpdateTransmitState()
    -- FIXME: Do we really need this?
    return TRANSMIT_ALWAYS
end

function ENT:ComputeError()

    if self.ErrorTime <= 0 then
        return 0
    end

    if self:IsObjectAttached() == false then
        return 0
    end

    local attachedObject = self:GetAttachedObject()
    local phys = attachedObject:GetPhysicsObject()
    if not IsValid(phys) then
        DbgPrint("No physics object, forcing detach")
        return 9999
    end

    local shadowParams = self.ShadowParams
    local pos
    if phys.GetShadowPosition ~= nil then
        pos = phys:GetShadowPosition()
    else
        pos = phys:GetPos() -- TODO: Remove this once function available in main branch.
    end

    local err = (shadowParams.pos - pos):Length()
    if self.ErrorTime > 1 then
        self.ErrorTime = 1
    end
    local speed = err / self.ErrorTime
    if speed > shadowParams.maxspeed then
        err = err * 0.5
    end
    self.Error = (0.97 - self.ErrorTime) * self.Error + err * self.ErrorTime

    if attachedObject:IsEFlagSet(EFL_IS_BEING_LIFTED_BY_BARNACLE) then
        self.Error = self.Error * 3
    end

    self.ErrorTime = 0

    return self.Error

end

function ENT:FindNearestChildObject(obj, pos)

    local res = obj:GetPhysicsObject()
    local bestDist = 999999

    for i = 0, obj:GetPhysicsObjectCount() - 1 do
        local phys = obj:GetPhysicsObjectNum(i)
        local dist = (pos - phys:GetPos()):LengthSqr()
        if dist < bestDist then
            bestDist = dist
            res = phys
        end
    end

    return res

end

function ENT:AttachObject(obj, grabPos, useGrabPos)

    if IsValid(self.AttachedObject) then
        return
    end

    DbgPrint(self, "AttachObject", obj)

    self:StartMotionController()

    local physObj

    if SERVER then
        physObj = obj:GetPhysicsObject()
    else
        -- Valve decided to make the combine ball special so it overrides propdata.
        if obj:GetClass() == "prop_combine_ball" then
            -- They have no physics on the client?
            obj:PhysicsInitSphere(12, "metal_bouncy")
        else
            obj:PhysicsInit(SOLID_VPHYSICS)
        end
        physObj = obj:GetPhysicsObject()
        if not IsValid(physObj) then
            DbgPrint("Unable to create physics on client")
        end
    end

    if useGrabPos == true then
        -- Find the nearest child.
        physObj = self:FindNearestChildObject(obj, grabPos)
    end

    if not IsValid(physObj) then
        DbgPrint("Invalid physics object, can not attach.")
        return
    end

    self:ResetState()
    self.SavedBlocksLOS = obj:BlocksLOS()

    local totalCount = obj:GetPhysicsObjectCount()
    local carryMass = REDUCED_CARRY_MASS / totalCount
    local totalWeight = 0
    for i = 0, totalCount - 1 do
        local phys2 = obj:GetPhysicsObjectNum(i)
        if not IsValid(phys2) then
            continue
        end

        local mass = phys2:GetMass()
        totalWeight = totalWeight + mass

        self.SavedMass[i] = mass
        phys2:SetMass(carryMass)

        local linear, angular = phys2:GetDamping()
        self.SavedRotDamping[i] = angular
        phys2:SetDamping(linear, 10)
    end
    self.LoadWeight = totalWeight

    physObj:SetMass(REDUCED_CARRY_MASS)
    physObj:EnableDrag(false)
    physObj:Wake()

    obj:SetBlocksLOS(false)

    self:AddToMotionController(physObj)
    self.AttachedObject = obj

    if SERVER then
        self:SetTargetObject(obj)
    end

end

function ENT:DetachObject()

    DbgPrint(self, "DetachObject")

    if IsValid(self.AttachedObject) then

        local obj = self.AttachedObject

        local phys = obj:GetPhysicsObject()
        if IsValid(phys) then
            self:RemoveFromMotionController(phys)

            for i = 0, obj:GetPhysicsObjectCount() - 1 do
                local physObj = obj:GetPhysicsObjectNum(i)
                if not IsValid(physObj) then
                    continue
                end

                if self.SavedMass ~= nil and self.SavedMass[i] ~= nil then
                    physObj:SetMass(self.SavedMass[i])
                end

                if self.SavedRotDamping ~= nil and self.SavedRotDamping[i] ~= nil then
                    local linear,_ = physObj:GetDamping()
                    physObj:SetDamping(linear, self.SavedRotDamping[i])
                end

                physObj:SetVelocity(Vector(0, 0, 0))
            end

            phys:EnableDrag(true)
            phys:Wake()

            obj:SetBlocksLOS(self.SavedBlocksLOS)
            self.SavedMass = {}
            self.SavedRotDamping = {}

            if CLIENT then
               obj:PhysicsDestroy()
            end
        else
            DbgPrint(self, "No valid physics: " .. tostring(phys))
        end
    else
        DbgPrint(self, "No valid object: " .. tostring(self.AttachedObject))
    end

    -- Always reset in case the entity left PVS on client.
    self.AttachedObject = nil

    if SERVER then
        --self:SetNW2Entity("AttachedObj", nil)
        self:SetTargetObject(NULL)
    end

end

function ENT:Think()
    --DbgPrint(self, "Tick")

    local ent = self.AttachedObject

    -- Check if the entity is still valid
    if ent ~= nil and not IsValid(ent) then
        self:DetachObject()
        ent = nil
    end

    if ent ~= nil then

        local obj = self.AttachedObject
        if IsValid(obj) then
            local phys = obj:GetPhysicsObject()
            if CLIENT and IsValid(phys) then
                self:PhysicsSimulate2(phys, FrameTime())
            end
        end
    end

    if SERVER then
        self:NextThink( CurTime() )
    else
        self:SetNextClientThink( CurTime() )
    end

    return true

end

function ENT:ComputeNetworkError()
    local serverEnt = self:GetTargetObject()
    local targetPos = self:GetTargetPos()
    local objectPos = serverEnt:GetPos()
    local posDelta = objectPos - targetPos
    local errorPos = ((abs(posDelta.x) / PREDICTION_TOLERANCE) + (abs(posDelta.y) / PREDICTION_TOLERANCE) + (abs(posDelta.z) / PREDICTION_TOLERANCE)) / 3
    return errorPos
end

function ENT:ManagePredictedObject()
    if CLIENT and game.SinglePlayer() == false then
        local ent = self.AttachedObject
        local serverEnt = self:GetTargetObject()
        if ent == nil and IsValid(serverEnt) then
            -- We give the prediction a tolerance, so objects being detached wont instantly fly to us
            -- while on the server they are still being detached.
            if self:ComputeNetworkError() <= PREDICTION_THRESHOLD then
                self:AttachObject(serverEnt)
            end
        elseif ent ~= nil and not IsValid(serverEnt) then
            -- Make sure we detach the entity if the server did.
            self:DetachObject()
        end
    end
end

local function InContactWithHeavyObject(phys, maxMass)

    local heavyContact = false

    if phys.GetFrictionSnapshot ~= nil then
        local contacts = phys:GetFrictionSnapshot()
        for _,v in pairs(contacts) do
            local other = v.Other
            if IsValid(other) and (not other:IsMoveable() or other:GetMass() > maxMass) then
                heavyContact = true
                break
            end
        end
    end

    return heavyContact
end

function ENT:GetLoadWeight()
    return self.LoadWeight
end

local function PhysComputeSlideDirection(phys, inVel, inAngVel, minMass)

    local vel = Vector(inVel)
    local angVel = Vector(inAngVel)

    if phys.GetFrictionSnapshot ~= nil then
        local contacts = phys:GetFrictionSnapshot()
        for _,v in pairs(contacts) do
            local other = v.Other
            if not IsValid(other) then
                continue
            end
            if not other:IsMoveable() or other:GetMass() >= minMass then
                local normal = v.Normal
                angVel = normal * angVel:Dot(normal)
                local proj = vel:Dot(normal)
                if proj > 0.0 then
                    vel = vel - (normal * proj)
                end
            end
        end
    end

    return vel, angVel
end

function ENT:PhysicsSimulate( phys, dt )
    -- For better interpolation the client runs this in Think
    if SERVER then
        return self:PhysicsSimulate2(phys, dt)
    end
end

function ENT:PhysicsSimulate2( phys, dt )

    if self.AttachedObject == nil then
        return
    end

    local shadowParams = self.ShadowParams
    local timeToArrive

    if CLIENT then
        timeToArrive = engine.TickInterval() * 2
    else
        timeToArrive = self:GetTimeToArrive()
    end

    if timeToArrive <= 0 then
        timeToArrive = FrameTime()
    end

    if InContactWithHeavyObject(phys, self.LoadWeight) == true then
        self.ContactAmount = math.Approach(self.ContactAmount, 0.1, dt * 2.0)
    else
        self.ContactAmount = math.Approach(self.ContactAmount, 1.0, dt * 2.0)
    end

    shadowParams.dt = dt
    shadowParams.maxangular = DEFAULT_MAX_ANGULAR * self.ContactAmount * self.ContactAmount * self.ContactAmount
    shadowParams.pos = self:GetTargetPos()
    shadowParams.angle = self:GetTargetAng()
    shadowParams.secondstoarrive = timeToArrive

    phys:ComputeShadowControl(shadowParams)

    local vel = phys:GetVelocity()
    local angVel = phys:GetAngleVelocity()

    vel, angVel = PhysComputeSlideDirection(phys, vel, angVel, self.LoadWeight)
    phys:SetVelocityInstantaneous(vel)

    timeToArrive = timeToArrive - dt
    if timeToArrive < 0 then
        timeToArrive = 0
    end

    self.ErrorTime = self.ErrorTime + dt
    self:SetTimeToArrive(timeToArrive)

    return Vector(0, 0, 0), Vector(0, 0, 0), SIM_LOCAL_ACCELERATION

end

function ENT:IsObjectAttached()
    if IsValid(self.AttachedObject) == true then
        return true
    end
    return false
end

function ENT:GetAttachedObject()
    return self.AttachedObject
end
