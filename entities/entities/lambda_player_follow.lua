local DbgPrint = GetLogging("PlayerFollow")
local DESTINATION_DISTANCE_TOLERANCE = 94
local DISTANCE_RUN_THRESHOLD = 256

---
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")
---
function ENT:PreInitialize()
    DbgPrint(self, "PreInitialize")
    BaseClass.PreInitialize(self)
    self:SetInputFunction("Enable", self.EnableInput)
    self:SetInputFunction("Disable", self.DisableInput)
    self:SetupNWVar(
        "Disabled",
        "bool",
        {
            Default = false,
            KeyValue = "StartDisabled"
        }
    )
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
end

function ENT:KeyValue(key, val)
    BaseClass.KeyValue(self, key, val)
    if key:iequals("actor") then
        self.Actor = val
    end
end

local function GetClosestPlayer(pos)
    local players = player.GetAll()
    local closest = nil
    local closestDist = 999999
    for _, v in pairs(players) do
        local dist = v:GetPos():Distance(pos)
        if dist < closestDist then
            closest = v
            closestDist = dist
        end
    end

    return closest
end

local function FollowEntity(ent, entToFollow)
    -- Set the goal position infront of the player.
    local currentPos = ent:GetPos()
    local targetPos = entToFollow:GetPos()
    local distance = targetPos:Distance(currentPos)
    if distance > DISTANCE_RUN_THRESHOLD then
        -- Set target pos to the actual entity position.
        targetPos = entToFollow:GetPos()
    else
        -- See if the entity is moving.
        local vel = entToFollow:GetVelocity()
        if vel:Length() > 0 then
            -- Set target pos to the actual entity position.
            targetPos = entToFollow:GetPos()
        else
            -- Set target pos to the actual entity position.
            targetPos = entToFollow:GetPos() + (entToFollow:GetForward() * DESTINATION_DISTANCE_TOLERANCE)
        end
    end

    -- Entity might be in the air, so we need to adjust the target position.
    local tr = util.TraceLine({
        start = targetPos,
        endpos = targetPos - Vector(0, 0, 256),
        mask = MASK_SOLID_BRUSHONLY,
        filter = ent
    })
    if tr.Hit then
        targetPos = tr.HitPos
    end

    if distance < DESTINATION_DISTANCE_TOLERANCE then return end
    ent:SetLastPosition(targetPos)
    local currentSchedule = ent:GetCurrentSchedule()
    if currentSchedule == SCHED_FORCED_GO then
        -- Check if we should start running.
        if distance > DISTANCE_RUN_THRESHOLD then
            ent:SetSchedule(SCHED_FORCED_GO_RUN)
        end
    elseif currentSchedule == SCHED_FORCED_GO_RUN then
        -- Check if we should start walking.
        if distance < DISTANCE_RUN_THRESHOLD then
            ent:SetSchedule(SCHED_FORCED_GO)
        end
    elseif currentSchedule == SCHED_IDLE_STAND or currentSchedule == SCHED_ALERT_STAND or currentSchedule == SCHED_FAIL then
        -- We are idle, we should start going.
        if distance > DISTANCE_RUN_THRESHOLD then
            ent:SetSchedule(SCHED_FORCED_GO_RUN)
        else
            ent:SetSchedule(SCHED_FORCED_GO)
        end
    end
end

function ENT:Think()
    if self:GetNWVar("Disabled", false) == true then
        self:NextThink(CurTime() + 0.5)

        return true
    end

    local actors = ents.FindByName(self.Actor)
    if #actors == 0 then return end
    -- Make all actors follow the closest player.
    for _, v in pairs(actors) do
        if not v:IsNPC() then continue end
        local currentPos = v:GetPos()
        local closestPly = GetClosestPlayer(currentPos)
        if closestPly == nil then continue end
        FollowEntity(v, closestPly)
    end

    self:NextThink(CurTime() + 0.5)

    return true
end

function ENT:EnableInput()
    self:SetDisabled(false)
    self:NextThink(CurTime())
end

function ENT:DisableInput()
    self:SetDisabled(true)
end