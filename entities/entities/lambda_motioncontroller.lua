if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("motioncontroller")

DEFINE_BASECLASS("base_entity")

ENT.Base = "base_entity"
ENT.Type = "anim"

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "TargetPos")
    self:NetworkVar("Angle", 0, "TargetAng")
    self:NetworkVar("Float", 0, "TimeToArrive")
    self:NetworkVar("Entity", 0, "TargetObject")
end

function ENT:Initialize()

    DbgPrint(self, "Initialize")

    self:SetTargetTransform(Vector(0, 0, 0), Angle(0, 0, 0))

    local shadowParams = {}

    -- Initialize shadow params.
    shadowParams.dt = 0
    shadowParams.secondstoarrive = 0
    shadowParams.maxangular = 360 * 10
    shadowParams.maxangulardamp = shadowParams.maxangular
    shadowParams.maxspeed = 4000
    shadowParams.maxspeeddamp = shadowParams.maxspeed * 2
    shadowParams.dampfactor = 0.8
    shadowParams.teleportdistance = 0

    self.ShadowParams = shadowParams
    self.SavedMass = {}
    self.SavedRotDamping = {}
    self.ErrorTime = 0
    self.Error = 0

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

    self.SavedMass = {}
    self.SavedRotDamping = {}
    self.ErrorTime = -1.0
    self.Error = 0

    for i = 0, obj:GetPhysicsObjectCount() - 1 do
        local phys2 = obj:GetPhysicsObjectNum(i)
        if not IsValid(phys2) then
            continue
        end
        self.SavedMass[i] = phys2:GetMass()
        phys2:SetMass(1) -- Carry mass

        local linear, angular = phys2:GetDamping()
        self.SavedRotDamping[i] = angular
        phys2:SetDamping(linear, 10)
    end

    physObj:SetMass(1.0)
    physObj:EnableDrag(false)
    physObj:Wake()

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
            if IsValid(phys) then
                -- NOTE: Not calling wake holds it back from calling PhysicsSimulate, also calling ENT:PhysWake did nothing on the client.
                phys:Wake()
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

local abs = math.abs
local PREDICTION_TOLERANCE = 3

function ENT:ComputeNetworkError()
    local serverEnt = self:GetTargetObject()
    local targetPos = self:GetTargetPos()
    local objectPos = serverEnt:GetPos()
    local posDelta = objectPos - targetPos
    local errorPos = ((abs(posDelta.x) / PREDICTION_TOLERANCE) + (abs(posDelta.y) / PREDICTION_TOLERANCE) + (abs(posDelta.z) / PREDICTION_TOLERANCE)) / 3
    return errorPos
end

function ENT:ManagePredictedObject()
    if CLIENT then
        local ent = self.AttachedObject
        local serverEnt = self:GetTargetObject()
        if ent == nil and IsValid(serverEnt) then
            -- We give the prediction a tolerance, so objects being detached wont instantly fly to us
            -- while on the server they are still being detached.
            if self:ComputeNetworkError() < 0.5 then
                self:AttachObject(serverEnt)
            end
        elseif ent ~= nil and not IsValid(serverEnt) then
            -- Make sure we detach the entity if the server did.
            self:DetachObject()
        end
    end
end

function ENT:PhysicsSimulate( phys, dt )

    if self.AttachedObject == nil then
        return
    end

    local shadowParams = self.ShadowParams
    local timeToArrive

    if CLIENT then
        timeToArrive = FrameTime()
    else
        timeToArrive = self:GetTimeToArrive()
    end

    if timeToArrive <= 0 then
        timeToArrive = FrameTime()
    end

    shadowParams.dt = dt
    shadowParams.pos = self:GetTargetPos()
    shadowParams.angle = self:GetTargetAng()
    shadowParams.secondstoarrive = timeToArrive

    phys:ComputeShadowControl(shadowParams)

    timeToArrive = timeToArrive - dt
    if timeToArrive < 0 then
        timeToArrive = 0
    end

    self.ErrorTime = self.ErrorTime + dt
    self:SetTimeToArrive(timeToArrive)

    return Vector(0, 0, 0), Vector(0, 0, 0), SIM_LOCAL_ACCELERATION

end

function ENT:IsObjectAttached()
    return IsValid(self.AttachedObject)
end

function ENT:GetAttachedObject()
    return self.AttachedObject
end
