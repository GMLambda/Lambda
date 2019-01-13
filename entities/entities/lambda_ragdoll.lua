if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Ragdoll")

ENT.Base = "base_anim"
ENT.Type = "anim"

local GIB_PARTS =
{
    [1] = "models/props_junk/watermelon01_chunk02c.mdl",
    [2] = "models/props_junk/watermelon01_chunk02b.mdl",
    [3] = "models/props_junk/watermelon01_chunk02a.mdl",
}

local BLOOD_SPRAY =
{
    [4] = "blood_impact_red_01_droplets",
    [3] = "blood_impact_red_01",
    [2] = "blood_impact_red_01_goop",
    [1] = "blood_impact_red_01_smalldroplets",
}

local BONE_PARTS =
{
    ["ValveBiped.Bip01_Head1"] = {
        { Mdl = "models/gibs/hgibs.mdl", Offset = Vector(0, 0, 0), Ang = Angle(-90, -90, 0) },
    },
    ["ValveBiped.Bip01_Spine2"] = {
        { Mdl = "models/gibs/hgibs_spine.mdl", Offset = Vector(0, 0, 0), Ang = Angle(-90, -90, 0) },

        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, 5, 0), Ang = Angle(-180, -90, 50), Scale = 0.6 },
        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, 5, 2), Ang = Angle(-180, -90, 50), Scale = 0.6 },
        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, 5, 4), Ang = Angle(-180, -90, 50), Scale = 0.6 },
        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, 5, 6), Ang = Angle(-180, -90, 50), Scale = 0.6 },

        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, -5, 0), Ang = Angle(-180, 90, -50), Scale = 0.6 },
        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, -5, 2), Ang = Angle(-180, 90, -50), Scale = 0.6 },
        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, -5, 4), Ang = Angle(-180, 90, -50), Scale = 0.6 },
        { Mdl = "models/gibs/hgibs_rib.mdl", Offset = Vector(0, -5, 6), Ang = Angle(-180, 90, -50), Scale = 0.6 },
    },
    ["ValveBiped.Bip01_R_UpperArm"] = {
        { Mdl = "models/gibs/hgibs_scapula.mdl", Offset = Vector(0, 0, 0), Ang = Angle(0, 0, 0) },
    },
    ["ValveBiped.Bip01_L_UpperArm"] = {
        { Mdl = "models/gibs/hgibs_scapula.mdl", Offset = Vector(0, 0, 0), Ang = Angle(-180, 0, 0) },
    },
}

local FLESH_MAT = Material("models/flesh")
local MAX_SPEED_THRESHOLD = 300
local MAX_GIBS = 100
local GIBS_MAX_LIFETIME = 10

game.AddParticles( "particles/blood_impact.pcf" )
game.AddParticles( "particles/fire_01.pcf" )

for _,v in pairs(GIB_PARTS) do
    util.PrecacheModel(v)
end

for _,parts in pairs(BONE_PARTS) do
    for _,v in pairs(parts) do
        util.PrecacheModel(v.Mdl)
    end
end

PrecacheParticleSystem("env_fire_tiny")
PrecacheParticleSystem("blood_impact_red_01_mist")

for _,v in pairs(BLOOD_SPRAY) do
    PrecacheParticleSystem( v )
end

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Ragdoll")
    self:NetworkVar("Int", 0, "GibCycle")
    self:NetworkVar("Vector", 0, "DamageForce")
    self:NetworkVar("Bool", 0, "Exploded")
end

function ENT:Initialize()
    self:SetNoDraw(true)
    self:DrawShadow(false)
    self.Initialized = true

    if CLIENT then
        self.GibParts = {}
        self.GibQueue = {}
        self.CurrentGibCycle = 0
    end

    if SERVER then
        self:NextThink(CurTime() + 0.2)
    else
        self:SetNextClientThink(CurTime())
    end
end

function ENT:GibPlayer(dmgForce, gibPlayer, didExplode)

    DbgPrint(self, "GibPlayer", dmgForce, gibPlayer, didExplode)

    self:SetDamageForce(dmgForce)
    self:SetExploded(didExplode)
    self:SetGibCycle(self:GetGibCycle() + 1)

end

function ENT:CreateRagdoll(dmgForce, gibPlayer, didExplode)

    DbgPrint(self, "CreateRagdoll", dmgForce, gibPlayer, didExplode)

    local ent = self:GetOwner()
    if not IsValid(ent) then
        DbgPrint("No valid owner for ragdoll manager")
        return
    end

    local mdl = ent:GetModel()
    if mdl == nil then
        DbgPrint("Player has no valid model for ragdoll manager")
        return
    end

    self:RemoveRagdoll()

    if gibPlayer == true then
        return self:GibPlayer(dmgForce, gibPlayer, didExplode)
    end

    ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(mdl)
    ragdoll:SetPos(ent:GetPos())
    ragdoll:SetAngles(ent:GetAngles())
    ragdoll:SetColor(ent:GetColor())
    ragdoll:SetSkin(ent:GetSkin())
    for _,v in pairs(ent:GetBodyGroups()) do
        ragdoll:SetBodygroup(v.id, ent:GetBodygroup(v.id))
    end
    ragdoll:SetOwner(self:GetOwner())
    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    ragdoll.GetPlayerColor = function(s)
        if IsValid(owner) and owner.GetPlayerColor ~= nil then
            return owner:GetPlayerColor()
        end
    end

    local vel = ent:GetVelocity()

    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local bone = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(bone) then
            local bp, ba = ent:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
            if bp and ba then
                bone:SetPos(bp)
                bone:SetAngles(ba)
            end
            bone:SetVelocity(vel)
        end
    end

    self:SetRagdoll(ragdoll)

end

function ENT:RemoveRagdoll()

    local ragdoll = self:GetRagdoll()
    if IsValid(ragdoll) then
        ragdoll:Remove()
        self:SetRagdoll(NULL)
    end

end

function ENT:Think()
    if CLIENT and self.Initialized == false then
        self:Initialize()
    end

    local ragdoll = self:GetRagdoll()
    if ragdoll ~= nil and ragdoll ~= NULL and not IsValid(ragdoll) then
        self:SetRagdoll(NULL)
    end

    if CLIENT then
        if IsValid(ragdoll) and ragdoll.GetPlayerColor == nil then
            ragdoll:SnatchModelInstance(ragdoll:GetOwner())
            ragdoll.GetPlayerColor = function(s)
                local ownerEnt = s:GetOwner()
                if IsValid(ownerEnt) and ownerEnt.GetPlayerColor ~= nil then
                    return ownerEnt:GetPlayerColor()
                end
            end
        end

        local gibCycle = self:GetGibCycle()
        if self.CurrentGibCycle < gibCycle then
            self.CurrentGibCycle = gibCycle
            self:GibPlayerClient()
        end

        self:UpdateGibs()
    end

    if SERVER then
        self:NextThink(CurTime() + 0.2)
    else
        self:SetNextClientThink(CurTime())
    end
    return true
end

function ENT:UpdateGibPart(gib)

    local curTime = CurTime()
    if curTime - gib.StartTime >= GIBS_MAX_LIFETIME then
        gib:Remove()
        return false
    end

    if curTime - gib.LastDroplet < 0.1 or curTime > gib.DropletTimeEnd or gib.HitSomething == true then
        return true
    end

    gib.LastDroplet = curTime

    if math.random() < 0.5 then
        ParticleEffectAttach("blood_impact_red_01_droplets", PATTACH_POINT_FOLLOW, gib, -1)
    end

    if math.random() < 0.5 then
        ParticleEffectAttach("blood_impact_red_01_goop", PATTACH_POINT_FOLLOW, gib, -1)
    end

    return true

end

function ENT:HandleGibsCollision(gib, data)
    gib.HitSomething = true

    if gib.IsBone == true then
        return
    end

    if data.Speed > 20 and CurTime() - gib.LastDecal >= 0.05 then
        util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
        gib.LastDecal = CurTime()
    end

    if data.Speed >= MAX_SPEED_THRESHOLD and gib.SizeType > 1 then
        gib:EmitSound("Flesh.Break")
        table.insert(self.GibQueue, function()

            if not IsValid(gib) then
                return
            end

            -- Break into two pieces.
            local nextSizeType = gib.SizeType - 1
            local nextMdl = GIB_PARTS[nextSizeType]
            self:CreateGibPart("", gib:GetPos(), gib:GetAngles(), Vector(0, 0, 0), Angle(0, 0, 0), nextMdl, gib:GetVelocity(), nextSizeType, 1)
            self:CreateGibPart("", gib:GetPos(), gib:GetAngles(), Vector(0, 0, 0), Angle(0, 0, 0), nextMdl, gib:GetVelocity(), nextSizeType, 1)

            gib:Remove()
        end)
    end
end

function ENT:UpdateGibs()
    local fn = self.GibQueue[1]
    if fn ~= nil then
        fn()
        table.remove(self.GibQueue, 1)
    end

    -- Limit the maximum possible gibs, remove oldest.
    while #self.GibParts > MAX_GIBS do
        local gib = self.GibParts[1]
        if IsValid(gib) then
            gib:Remove()
        end
        table.remove(self.GibParts, 1)
    end

    local idx = 1
    while idx <= #self.GibParts do
        local gib = self.GibParts[idx]
        if not IsValid(gib) then
            table.remove(self.GibParts, idx)
            continue
        end
        if self:UpdateGibPart(gib) == false then
            table.remove(self.GibParts, idx)
            continue
        end
        idx = idx + 1
    end
end

function ENT:CreateGibPart(boneName, pos, ang, posOffset, angOffset, mdl, dmgForce, sizeType, exploded, isBone, scale)

    if mdl == nil then
        error("No gib model selected")
        return
    end

    local gib = ents.CreateClientProp(mdl)
    gib.Emitter = ParticleEmitter(pos)
    gib.IsBone = isBone
    gib.SizeType = sizeType
    gib:SetPos(pos + posOffset)
    gib:SetAngles(ang)
    gib:SetModel(mdl)
    if scale ~= 1 and scale ~= nil then
        gib:SetModelScale(scale)
    end
    gib:Spawn()
    gib:Activate()

    if isBone == false then
        gib:SetMaterial("model/flesh")
    else
        local localAng = gib:GetLocalAngles()
        localAng:RotateAroundAxis(localAng:Forward(), angOffset.x)
        localAng:RotateAroundAxis(localAng:Right(), angOffset.y)
        localAng:RotateAroundAxis(localAng:Up(), angOffset.z)
        gib:SetLocalAngles(localAng)
    end

    gib:PhysicsInit(SOLID_VPHYSICS)
    gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    gib:SetMoveType(MOVETYPE_VPHYSICS)
    gib:SetNotSolid(true)
    local phys = gib:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(dmgForce)
        --phys:EnableMotion(false)
    end

    -- Rendering.
    if isBone ~= true then
        gib.RenderOverride = function(e)
            render.MaterialOverride(FLESH_MAT)
            e:DrawModel()
            render.MaterialOverride(nil)
        end
    end

    gib:CallOnRemove("EmitterCleanup", function(e)
        e.Emitter:Finish()
    end, gib)

    -- Collision handling.
    gib.LastDecal = 0
    gib.HitSomething = false
    gib:AddCallback("PhysicsCollide", function(e, data)
        self:HandleGibsCollision(e, data)
    end)

    -- Update effects
    gib.StartTime = CurTime()
    gib.LastDroplet = 0
    gib.DropletTimeEnd = CurTime() + (math.random() * 4)

    -- Particles
    ParticleEffectAttach("blood_impact_red_01_goop", PATTACH_POINT_FOLLOW, gib, 0)

    if sizeType > 1 then
        local spray = BLOOD_SPRAY[sizeType]
        ParticleEffectAttach(spray, PATTACH_POINT_FOLLOW, gib, 0)
    end

    if exploded == true and math.random() > 0.8 then
        ParticleEffectAttach("env_fire_tiny", PATTACH_POINT_FOLLOW, gib, 0)
    end

    table.insert(self.GibParts, gib)

end

function ENT:GibPlayerClient()

    local ply = self:GetOwner()
    if not IsValid(ply) then
        return
    end

    local dmgForce = self:GetDamageForce()
    local didExplode = self:GetExploded()

    -- Create gibs.
    local numHitBoxGroups = ply:GetHitBoxGroupCount()
    util.Decal("Blood", ply:GetPos() + ply:GetUp(), ply:GetPos() - ply:GetUp())

    for group = 0, numHitBoxGroups - 1 do
        local numHitBoxes = ply:GetHitBoxCount( group )

        for hitbox = 0, numHitBoxes - 1 do
            local bone = ply:GetHitBoxBone( hitbox, group )
            local boneName = ply:GetBoneName(bone)
            local pos, ang = ply:GetBonePosition(bone)
            local offset = VectorRand() * dmgForce:Length2D()
            local sizeType = 3

            local boneParts = BONE_PARTS[boneName]
            if boneParts ~= nil then
                for _,v in pairs(boneParts) do
                    self:CreateGibPart(boneName, pos, ang, v.Offset, v.Ang, v.Mdl, (dmgForce * 0.8) + offset, 0, didExplode, true, v.Scale or 1)
                end
            end

            local mdl = GIB_PARTS[sizeType]
            self:CreateGibPart(boneName, pos, ang, Vector(0, 0, 0), Angle(0, 0, 0), mdl, (dmgForce * 0.8) + offset, sizeType, didExplode, false, 1)
        end
    end

end

function ENT:OnRemove()
    local ragdoll = self:GetRagdoll()
    if SERVER and IsValid(ragdoll) then
        ragdoll:Remove()
    elseif CLIENT then
        for _,gib in pairs(self.GibParts) do
            if IsValid(gib) then
                gib:Remove()
            end
        end
        self.GibParts = {}
    end
end

function ENT:Draw()
end
