if SERVER then
    AddCSLuaFile()
end

local CurTime = CurTime
local Vector = Vector
local util = util
local math = math
local ents = ents
local player = player
local COND_SEE_HATE = 7
local COND_SEE_DISLIKE = 9
local COND_SEE_ENEMY = 10
local COND_SEE_FEAR = 8
local COND_SMELL = 37
local MODE_IDLE = 0
local MODE_EAT = 1
local MODE_BORED = 2
local MODE_SMELL_FOOD = 3
local MODE_SCARED_BY_ENT = 4
local MODE_SCARED_BY_LIGHT = 5
local COCKROACH_MDL = "models/decay/cockroach.mdl"
local LOOK_DISTANCE = 100
local THINK_MAX_TIME = 0.3
local THINK_DISTRIBUTION = 300
local DEBUG_COCKROACH = false
ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.Spawnable = true
ENT.AutomaticFrameAdvance = true
ENT.m_fMaxYawSpeed = 500 -- Max turning speed

local MODE_TO_STRING = {
    [MODE_IDLE] = "idle",
    [MODE_EAT] = "eat",
    [MODE_BORED] = "bored",
    [MODE_SMELL_FOOD] = "smell_food",
    [MODE_SCARED_BY_ENT] = "scared_by_ent",
    [MODE_SCARED_BY_LIGHT] = "scared_by_light"
}

local FOOD_MODELS = {
    ["models/props_junk/garbage_glassbottle001a.mdl"] = true,
    ["models/props_junk/garbage_glassbottle002a.mdl"] = true,
    ["models/props_junk/garbage_glassbottle003a.mdl"] = true,
    ["models/props_junk/garbage_metalcan001a.mdl"] = true,
    ["models/props_junk/garbage_metalcan002a.mdl"] = true,
    ["models/props_junk/garbage_takeoutcarton001a.mdl"] = true,
    ["models/props_junk/garbage_milkcarton002a.mdl"] = true,
    ["models/props_junk/garbage128_composite001b.mdl"] = true,
    ["models/props_junk/garbage128_composite001a.mdl"] = true,
    ["models/props_junk/garbage256_composite001b.mdl"] = true,
    ["models/props_junk/garbage_plasticbottle001a.mdl"] = true,
    ["models/props_junk/garbage_plasticbottle002a.mdl"] = true,
    ["models/props_junk/garbage_plasticbottle003a.mdl"] = true,
    ["models/props_junk/garbage_bag001a.mdl"] = true,
    ["models/props_junk/popcan01a.mdl"] = true,
    ["models/humans/charple01.mdl"] = true,
    ["models/humans/charple02.mdl"] = true,
    ["models/humans/charple03.mdl"] = true,
    ["models/humans/charple04.mdl"] = true,
    ["models/humans/corpse1.mdl"] = true,
    ["models/player/corpse1.mdl"] = true,
    ["models/Gibs/Fast_Zombie_Torso.mdl"] = true,
    ["models/Gibs/Fast_Zombie_Legs.mdl"] = true,
    ["models/zombie/classic_legs.mdl"] = true,
    ["models/zombie/zombie_soldier_legs.mdl"] = true,
    ["models/props_junk/watermelon01.mdl"] = true,
    ["models/props_junk/trashdumpster01a.mdl"] = true
}

local HIDING_MODELS = {
    ["models/props_junk/wood_crate001a.mdl"] = true,
    ["models/props_junk/wood_pallet001a.mdl"] = true,
    ["models/props_junk/cardboard_box001a.mdl"] = true,
    ["models/props_junk/cardboard_box001b.mdl"] = true,
    ["models/props_junk/trashdumpster01a.mdl"] = true,
    ["models/props_junk/metalbucket01a.mdl"] = true,
    ["models/props_c17/furniturecouch001a.mdl"] = true,
    ["models/props_c17/furnituredrawer001a.mdl"] = true,
    ["models/props_wasteland/prison_bedframe001a.mdl"] = true,
    ["models/props_interiors/furniture_couch01a.mdl"] = true,
    ["models/props_interiors/furniture_couch02a.mdl"] = true,
    ["models/props_junk/wood_crate002a.mdl"] = true,
    ["models/props_c17/oildrum001.mdl"] = true,
    ["models/props_c17/furnituredresser001a.mdl"] = true,
    ["models/props_vehicles/car004b_physics.mdl"] = true,
    ["models/props_junk/wood_crate001a_damagedmax.mdl"] = true,
    ["models/props_junk/trashdumpster01a.mdl"] = true
}

util.PrecacheModel(COCKROACH_MDL)
util.PrecacheSound("Roach.Walk")
util.PrecacheSound("Roach.Die")
util.PrecacheSound("Roach.Smash")

function ENT:InitializeData()
    if SERVER then
        self.Mode = MODE_IDLE
        self.NextSmellTime = CurTime()
        self.NextHungerTime = CurTime() + 1
        self.TargetPosition = self:GetPos()
        self.DangerPosition = Vector(0, 0, 0)
        self.SmellPosition = Vector(0, 0, 0)
    end

    self.LastThinkTime = CurTime()
end

function ENT:Initialize()
    self.LambdaCockroach = true
    self:UseClientSideAnimation(true)
    self:SetPlaybackRate(10.0)
    self:SetModel(COCKROACH_MDL)
    self:AddEffects(EF_NOSHADOW)
    self:SetModelScale(0.5, 0)
    self:AddFlags(FL_NOTARGET)

    if SERVER then
        self:SetSolid(SOLID_NONE)
        self:SetMoveType(MOVETYPE_STEP)
        self:SetHullType(HULL_TINY_CENTERED)
        self:AddSolidFlags(FSOLID_TRIGGER + FSOLID_NOT_SOLID + FSOLID_USE_TRIGGER_BOUNDS)
        self:CapabilitiesAdd(CAP_MOVE_GROUND + CAP_MOVE_CRAWL + CAP_ANIMATEDFACE + CAP_TURN_HEAD)
        self:SetHealth(1)
        self:SetMovementActivity(ACT_IDLE)
        self:SetTrigger(true)
    end

    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self.IsCurrentlyMoving = false
    self:InitializeData()
end

function ENT:SelectSchedule()
end

-- Server
function ENT:ShouldEat()
    if self.NextHungerTime > CurTime() then return false end

    return true
end

-- Server
function ENT:SetNextHungerTime(dur)
    self.NextHungerTime = CurTime() + dur
end

function ENT:GetRelationship(ent)
    local class = ent:GetClass()
    if class == "npc_lambda_cockroach" then return D_NU end
    if ent:IsPlayer() == true or ent:IsNPC() then return D_FR end

    return D_NU
end

-- Server
function ENT:GetClosestHidingSpot()
    if self.NearbyHidingSpots == nil or #self.NearbyHidingSpots == 0 then return nil end
    local curPos = self:GetPos()
    table.sort(self.NearbyHidingSpots, function(a, b) return curPos:Distance(a) < curPos:Distance(b) end)
    local maxSpots = math.min(4, #self.NearbyHidingSpots)
    local choice = math.random(1, maxSpots)

    return self.NearbyHidingSpots[choice]
end

function ENT:Look(lookDistance)
    self.DangerPosition = Vector(0, 0, 0)
    self.NearbyHidingSpots = {}
    self:ClearCondition(COND_SEE_HATE)
    self:ClearCondition(COND_SEE_DISLIKE)
    self:ClearCondition(COND_SEE_ENEMY)
    self:ClearCondition(COND_SEE_FEAR)
    local curPos = self:GetPos()
    local nearby = ents.FindInBox(self:GetPos() - Vector(128, 128, 0), self:GetPos() + Vector(128, 128, 128))
    local dangerPos = nil
    local dangerDist = 999999

    for _, v in pairs(nearby) do
        if v:IsFlagSet(FL_NOTARGET) == true then continue end
        if v == self then continue end
        if self:Visible(v) == false then continue end
        local mdl = v:GetModel()

        if mdl ~= nil and HIDING_MODELS[mdl] == true then
            local pos = v:GetPos()
            local center = v:WorldSpaceCenter()
            center.z = pos.z
            table.insert(self.NearbyHidingSpots, center)
        end

        if v:IsNPC() == false and v:IsPlayer() == false then continue end
        if v:GetClass() == "npc_furniture" then continue end
        if self:Visible(v) == false then continue end
        local relation = self:GetRelationship(v)

        if relation == D_FR then
            self:SetCondition(COND_SEE_FEAR)
            local pos = v:GetPos()
            local dist = curPos:Distance(pos)

            if dist < dangerDist then
                dangerPos = pos
                dangerDist = dist
            end
        end
    end

    if dangerPos ~= nil then
        self.DangerPosition = dangerPos
    end
end

function ENT:Smell()
    self:ClearCondition(COND_SMELL)
    self.SmellPosition = Vector(0, 0, 0)
    -- We are cheating here, no access go actual Senses.
    local nearby = ents.FindInBox(self:GetPos() - Vector(256, 256, 0), self:GetPos() + Vector(256, 256, 128))
    local sources = {}

    for _, v in pairs(nearby) do
        local mdl = v:GetModel()
        if mdl == nil then continue end --print("No model", v)
        --print(mdl)
        local isFood = FOOD_MODELS[mdl]

        if isFood == true then
            table.insert(sources, v:GetPos())
            if #sources > 5 then break end -- Enough is enough.
        end
    end

    if #sources > 0 then
        self:SetCondition(COND_SMELL)
        self.SmellPosition = table.Random(sources)
    end
end

function ENT:SetRandomGoal(minLength, dir)
    local ang = Angle(0, 0, 0)
    ang.y = math.random(0, 360)
    local vecDir = ang:Forward()
    local dist = math.random(128, 512)
    local vecDest = self:GetPos() + (vecDir * dist)

    return self:SetGoal(vecDest)
end

function ENT:SetGoal(pos)
    self:SetLastPosition(pos)
    self.TargetPosition = Vector(pos)
end

-- Server
function ENT:SetNextMode(mode)
    if mode == nil then
        error("mode can not be nil")
    end

    --DbgPrint("SetNextMode", MODES[mode])
    self.Mode = mode
    local curPos = self:GetPos() + Vector(0, 0, 4)
    local vecDest = nil
    local useTrace = false

    if mode == MODE_SMELL_FOOD then
        -- Run towards the food.
        vecDest = self.SmellPosition
    elseif mode == MODE_SCARED_BY_ENT then
        -- Try to move away from the danger.
        -- First try to find something to hide under.
        local dangerDistance = self.DangerPosition:Distance(curPos)
        local hidingSpot = self:GetClosestHidingSpot()

        if hidingSpot ~= nil and dangerDistance > 128 then
            local randOffset = VectorRand() * 5
            randOffset.z = 0
            vecDest = hidingSpot + randOffset
        else
            -- Try to just run away in the opposite direction.
            local dir = (curPos - self.DangerPosition):GetNormal()
            dir.x = dir.x + (-0.75 + (math.random() * 1.75))
            dir.y = dir.y + (-0.75 + (math.random() * 1.75))
            vecDest = curPos + (dir * 64)
            useTrace = false
        end
    elseif mode == MODE_BORED then
        -- Pick a random direction and walk there, must be at least 256 units away.
        -- TODO: Split 360 degrees into N substeps and do a binary search with traces which should be much better.
        while true do
            local ang = Angle(0, 0, 0)
            ang.y = math.random(0, 360)
            local vecDir = ang:Forward()
            local dist = math.random(128, 512)
            vecDest = curPos + (vecDir * dist)
            if vecDest:Distance(curPos) > 256 then break end
        end

        useTrace = true
    elseif mode == MODE_IDLE or mode == MODE_EAT then
        -- Sit around.
        vecDest = nil
        self:SetMovementActivity(ACT_IDLE)
        self.IsCurrentlyMoving = false
    end

    -- If we have no where to go just return.
    if vecDest == nil then return end

    -- Do a final trace to reduce errors in path finding by using hit pos as max reach point.
    if useTrace == true then
        local tr = util.TraceLine({
            start = curPos,
            endpos = vecDest,
            filter = function(e) return e ~= self and e:GetClass() ~= "npc_lambda_cockroach" end,
            -- FIXME: Ignore props?
            mask = MASK_SHOT
        })

        if tr.Fraction ~= 1 then
            vecDest = tr.HitPos
        end
    end

    vecDest.z = curPos.z
    self:SetGoal(vecDest)
    self:SetSchedule(SCHED_FORCED_GO)
    self:SetMovementActivity(ACT_WALK)
    self.IsCurrentlyMoving = true

    if math.random(0, 9) == 1 then
        self:EmitSound("roach/rch_walk.wav", 75, 100, 0.3)
    end
end

function ENT:Move(dt)
    local curPos = self:GetPos()
    local dist = self.TargetPosition:Distance(curPos)
    --DbgPrint(dist)
    self:SetArrivalSpeed(100)
    self:SetArrivalDistance(0)
    local curAng = self:GetAngles()
    local destAng = (self.TargetPosition - curPos):Angle()
    local interp = dt * 130
    local newAng = Angle(0, math.Approach(curAng.y, destAng.y, interp), 0)
    self:SetAngles(newAng)

    -- Randomly switch direction if we are not scared.
    if math.random(0, 20) == 1 and self.Mode ~= MODE_SCARED_BY_ENT then
        self:SetNextMode(self.Mode)
    end

    local failedGoal = false

    if self:IsCurrentSchedule(SCHED_FORCED_GO) == false and dist >= 20 then
        -- Task failed.
        failedGoal = true
    end

    if failedGoal == true and self.Mode == MODE_SCARED_BY_ENT then
        self:SetNextMode(self.Mode)

        return
    end

    if dist <= 4 or failedGoal == true then
        -- Reached target.
        if self.Mode == MODE_SMELL_FOOD and failedGoal == false then
            self:SetNextMode(MODE_EAT)
        else
            self:SetNextMode(MODE_IDLE)
        end
    end

    if math.random(0, 149) == 1 and self.Mode ~= MODE_SCARED_BY_LIGHT and self.Mode ~= MODE_SMELL_FOOD then
        self:SetNextMode(MODE_IDLE)
    end
end

function ENT:NPCThink(dt)
    if DEBUG_COCKROACH then
        local debugTime = self:GetThinkDelay()
        local modeText = MODE_TO_STRING[self.Mode]
        debugoverlay.Text(self:GetPos() + Vector(0, 0, 5), "Mode: " .. modeText, debugTime + 0.01)
        debugoverlay.Cross(self.TargetPosition + Vector(0, 1, 1), 3, debugTime + 0.01, true)
    end

    self:Look(LOOK_DISTANCE)

    if self.Mode == MODE_IDLE or self.Mode == MODE_EAT then
        if self:HasCondition(COND_SEE_FEAR) == true then
            -- Ignore food for a while.
            self:SetNextHungerTime(30 + math.random(0, 14))
            self:SetNextMode(MODE_SCARED_BY_ENT)
        elseif math.random(0, 10) == 1 and (self.Mode == MODE_IDLE or self.Mode == MODE_EAT) then
            -- Currently eating or doing nothing, lets do something.
            if self.Mode == MODE_EAT then
                -- Done eating, lets not be hungry for a while.
                self:SetNextHungerTime(30 + math.random(0, 14))
            end

            self:SetNextMode(MODE_BORED)
        end

        if self.Mode == MODE_IDLE then
            if self:ShouldEat() == true then
                -- Hungry.
                self:Smell()
            end

            if self:HasCondition(COND_SMELL) == true then
                self:SetNextMode(MODE_SMELL_FOOD)
            end
        end
    end

    if self.IsCurrentlyMoving == true then
        self:Move(dt)
    end
end

-- Client
function ENT:ClientThink(dt)
end

function ENT:GetThinkDelay()
    -- Better distribution, if all of them think at the same frame its a bit horrible.
    local idx = self:EntIndex() % THINK_DISTRIBUTION

    return (idx / THINK_DISTRIBUTION) * THINK_MAX_TIME
end

function ENT:Think()
    local curTime = CurTime()
    local dt = curTime - (self.LastThinkTime or curTime)
    self.LastThinkTime = curTime
    self:FrameAdvance(dt)

    if SERVER then
        self:NPCThink(dt)
    else
        self:ClientThink(dt)
    end

    local thinkDelay = self:GetThinkDelay()

    if SERVER then
        self:NextThink(CurTime() + thinkDelay)
    else
        self:SetNextClientThink(CurTime() + thinkDelay)
    end

    return true
end

local vec_zero = Vector(0, 0, 0)

function ENT:Touch(ent)
    if ent.LambdaCockroach == true then return end

    if ent:IsPlayer() then
        if ent:GetVelocity() == vec_zero then return end
    elseif ent:IsNPC() then
        if ent:GetMoveVelocity() == vec_zero then return end
    else
        local phys = ent:GetPhysicsObject()
        if not IsValid(phys) then
            return
        end
        local vel = phys:GetVelocity()
        local velLen = vel:LengthSqr()
        if velLen < 20000 then
            return
        end
    end

    self:TakeDamage(self:Health(), ent, ent)
end

function ENT:OnTakeDamage(dmginfo)
    local amount = dmginfo:GetDamage()

    if amount >= self:Health() then
        -- We'll die.
        if math.random(0, 4) == 1 then
            self:EmitSound("Roach.Die")
        else
            self:EmitSound("Roach.Smash")
        end

        local attacker = dmginfo:GetAttacker()
        local inflictor = dmginfo:GetInflictor()
        local pos = self:GetPos()
        util.Decal("YellowBlood", pos + Vector(0, 0, 8), pos - Vector(0, 0, 24), {self, attacker, inflictor})
        self:Remove()
    end
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    self:Draw()
end

function TestRoach()
    for k, v in pairs(ents.FindByClass("npc_lambda_cockroach")) do
        v:Remove()
    end

    for k, v in pairs(player.GetAll()) do
        for i = 1, 60 do
            local r = ents.Create("npc_lambda_cockroach")
            r:SetPos(v:GetEyeTrace().HitPos)
            r:Spawn()
        end
    end
end

if CLIENT then
    language.Add("npc_lambda_cockroach", "Cockroach")
end