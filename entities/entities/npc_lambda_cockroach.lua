local DbgPrint = GetLogging("Roach")

AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.Spawnable = true
ENT.AutomaticFrameAdvance = true

ENT.m_fMaxYawSpeed = 500 -- Max turning speed

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

local MODES =
{
    [MODE_IDLE] = "MODE_IDLE",
    [MODE_EAT] = "MODE_EAT",
    [MODE_BORED] = "MODE_BORED",
    [MODE_SMELL_FOOD] = "MODE_SMELL_FOOD",
    [MODE_SCARED_BY_ENT] = "MODE_SCARED_BY_ENT",
    [MODE_SCARED_BY_LIGHT] = "MODE_SCARED_BY_LIGHT",
}

local LOOK_DISTANCE = 100

local FOOD_MODELS =
{
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
    ["models/props_junk/trashdumpster01a.mdl"] = true,
}

local HIDING_MODELS =
{
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
    ["models/props_junk/trashdumpster01a.mdl"] = true,
}

util.PrecacheModel(COCKROACH_MDL);

util.PrecacheSound( "Roach.Walk" );
util.PrecacheSound( "Roach.Die" );
util.PrecacheSound( "Roach.Smash" );

local NON_BLOCKING_CLASSES =
{
    ["prop_physics"] = true,
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_physbox"] = true,
}

hook.Add("ShouldCollide", "CockroachCollision", function(ent1, ent2)

    if ent2.LambdaCockroach == true then
        local tmp = ent2
        ent2 = ent1
        ent1 = tmp
    end

    if ent1.LambdaCockroach == true then
        local class = ent2:GetClass()
        if NON_BLOCKING_CLASSES[class] == true then
            return false
        end
    end

end)

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

    if SERVER then
        self:SetSolid( SOLID_BBOX )
        self:SetMoveType( MOVETYPE_STEP )
        self:SetHullType( HULL_TINY_CENTERED )
        self:CapabilitiesAdd( CAP_MOVE_GROUND + CAP_MOVE_CRAWL + CAP_ANIMATEDFACE + CAP_TURN_HEAD )
        self:SetHealth(1)
        self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        self:SetMovementActivity(ACT_IDLE)
        self.IsCurrentlyMoving = false
    end

    self:SetCustomCollisionCheck(true)
    self:UseClientSideAnimation(true)
    self:SetPlaybackRate(10.0)
    self:SetModel( COCKROACH_MDL )
    self:SetCollisionBounds(Vector(-1.2, -1.2, 0), Vector(1.2, 1.2, 0.2))
    self:AddEffects(EF_NOSHADOW)
    self:SetModelScale(0.5, 0)
    self:AddFlags(FL_NOTARGET)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(1)
    end

    self:InitializeData()

end

function ENT:SelectSchedule()
end

-- Server
function ENT:ShouldEat()
    if self.NextHungerTime > CurTime() then
        return false
    end
    return true
end

-- Server
function ENT:SetNextHungerTime(dur)
    self.NextHungerTime = CurTime() + dur
end

function ENT:GetRelationship( ent )

    local class = ent:GetClass()
    if class == "npc_lambda_cockroach" then
        return D_NU
    end

    if ent:IsPlayer() == true or ent:IsNPC() then
        return D_FR
    end

    return D_NU

end

-- Server
function ENT:GetClosestHidingSpot()

    if self.NearbyHidingSpots == nil or #self.NearbyHidingSpots == 0 then
        return nil
    end

    local curPos = self:GetPos()
    table.sort(self.NearbyHidingSpots, function(a, b)
        return curPos:Distance(a) < curPos:Distance(b)
    end)

    local maxSpots = math.min(4, #self.NearbyHidingSpots)
    local choice = math.random(1, maxSpots)

    return self.NearbyHidingSpots[choice]

end

function ENT:Look(lookDistance)

    self.DangerPosition = Vector(0, 0, 0)
    self.NearbyHidingSpots = {}

    self:ClearCondition( COND_SEE_HATE )
    self:ClearCondition( COND_SEE_DISLIKE )
    self:ClearCondition( COND_SEE_ENEMY )
    self:ClearCondition( COND_SEE_FEAR )

    local curPos = self:GetPos()
    local nearby = ents.FindInBox(self:GetPos() - Vector(128, 128, 0), self:GetPos() + Vector(128, 128, 128))
    local dangerPos = nil
    local dangerDist = 999999

    for _,v in pairs(nearby) do

        if v:IsFlagSet(FL_NOTARGET) == true then
            continue
        end

        if v == self then
            continue
        end

        if self:Visible(v) == false then
            continue
        end

        local mdl = v:GetModel()
        if mdl ~= nil and HIDING_MODELS[mdl] == true then
            local pos = v:GetPos()
            local center = v:WorldSpaceCenter()
            center.z = pos.z
            table.insert(self.NearbyHidingSpots, center)
        end

        if v:IsNPC() == false and v:IsPlayer() == false then
            continue
        end

        if v:GetClass() == "npc_furniture" then
            continue
        end

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

    self:ClearCondition( COND_SMELL )
    self.SmellPosition = Vector(0, 0, 0)

    -- We are cheating here, no access go actual Senses.
    local nearby = ents.FindInBox(self:GetPos() - Vector(256, 256, 0), self:GetPos() + Vector(256, 256, 128))
    local sources = {}

    for _,v in pairs(nearby) do
        local mdl = v:GetModel()
        if mdl == nil then
            --print("No model", v)
            continue
        end
        --print(mdl)
        local isFood = FOOD_MODELS[mdl]
        if isFood == true then
            table.insert(sources, v:GetPos())
            if #sources > 5 then
                -- Enough is enough.
                break
            end
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
            vecDest = hidingSpot
        else
            -- Try to just run away in the opposite direction.
            local dir = (curPos - self.DangerPosition):GetNormal()
            dir.x = dir.x + (-0.6 + (math.random() * 1.2))
            dir.y = dir.y + (-0.6 + (math.random() * 1.2))

            --DbgPrint("Direction", dir)
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

            if vecDest:Distance(curPos) > 256 then
                break
            end
        end

        useTrace = true

    elseif mode == MODE_IDLE or mode == MODE_EAT then
   
        -- Sit around.
        vecDest = nil

        self:SetMovementActivity(ACT_IDLE)
        self.IsCurrentlyMoving = false

    end

    -- If we have no where to go just return.
    if vecDest == nil then
        return
    end

    -- Do a final trace to reduce errors in path finding by using hit pos as max reach point.
    if useTrace == true then
        local tr = util.TraceLine({
            start = curPos,
            endpos = vecDest,
            filter = function(e)
                return e ~= self and e:GetClass() ~= "npc_lambda_cockroach"
            end,
            -- FIXME: Ignore props?
            mask = MASK_SHOT,
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
        self:EmitSound("roach/rch_walk.wav", 50, 100, 1)
    end

end

function ENT:Move(dt)

    debugoverlay.Cross(self.TargetPosition + Vector(0, 0, 1), 3, 0.5, true)

    local dist = self.TargetPosition:Distance(self:GetPos())
    --DbgPrint(dist)

    self:SetArrivalSpeed(100)
    self:SetArrivalDistance(0)

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

    if SERVER then
        self:NextThink(CurTime() + 0.2)
    else
        self:SetNextClientThink(CurTime() + 0.2)
    end

    return true

end

local vec_zero = Vector(0, 0, 0)

function ENT:Touch(ent)
    if ent.LambdaCockroach == true then
        return
    end
    if ent:GetVelocity() == vec_zero or (ent:IsPlayer() == false and ent:IsNPC() == false) then
        return
    end
    self:TakeDamage(self:Health(), ent, ent)
end

function ENT:OnTakeDamage( dmginfo )

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
        util.Decal("YellowBlood", pos + Vector(0, 0, 8), pos - Vector(0, 0, 24), { self, attacker, inflictor } )

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

    for k,v in pairs(ents.FindByClass("npc_lambda_cockroach")) do
        v:Remove()
    end

    for k,v in pairs(player.GetAll()) do

        for i = 1, 10 do
            local r = ents.Create("npc_lambda_cockroach")
            r:SetPos(v:GetEyeTrace().HitPos)
            r:Spawn()
        end
    end

end

if CLIENT then
    language.Add("npc_lambda_cockroach", "Cockroach")
end
