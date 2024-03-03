local DbgPrint = GetLogging("PlayerFollow")
local DESTINATION_DISTANCE = 72
local DISTANCE_RUN_THRESHOLD = 256
---
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")
---
function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
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

function ENT:Think()
    local actors = ents.FindByName(self.Actor)
    if #actors == 0 then return end
    for _, v in pairs(actors) do
        if not v:IsNPC() then continue end
        local currentPos = v:GetPos()
        local closestPly = GetClosestPlayer(pos)
        if closestPly == nil then continue end
        -- Set the goal position infront of the player.
        local targetPos = closestPly:GetPos() + (closestPly:GetForward() * 72)
        local distance = targetPos:Distance(currentPos)
        if distance < DESTINATION_DISTANCE then continue end
        v:SetLastPosition(targetPos)
        local currentSchedule = v:GetCurrentSchedule()
        if currentSchedule == SCHED_FORCED_GO then
            -- Check if we should start running.
            if distance > DISTANCE_RUN_THRESHOLD then
                v:SetSchedule(SCHED_FORCED_GO_RUN)
            end
        elseif currentSchedule == SCHED_FORCED_GO_RUN then
            -- Check if we should start walking.
            if distance < DISTANCE_RUN_THRESHOLD then
                v:SetSchedule(SCHED_FORCED_GO)
            end
        elseif currentSchedule == SCHED_IDLE_STAND or currentSchedule == SCHED_ALERT_STAND then
            -- We are idle, we should start going.
            if distance > DISTANCE_RUN_THRESHOLD then
                v:SetSchedule(SCHED_FORCED_GO_RUN)
            else
                v:SetSchedule(SCHED_FORCED_GO)
            end
        end
    end

    self:NextThink(CurTime() + 0.5)

    return true
end