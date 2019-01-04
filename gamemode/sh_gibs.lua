if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("LambdaGibPlayer")
end

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

if SERVER then

    -- SERVER
    function GM:GibPlayer(ply, dmgForce, exploded)
        net.Start("LambdaGibPlayer")
        net.WriteEntity(ply)
        net.WriteVector(dmgForce)
        net.WriteBool(exploded)
        net.Broadcast()
    end

else

    local FLESH_MAT = Material("models/flesh")
    local MAX_SPEED_THRESHOLD = 300
    local MAX_GIBS = 100
    local GIBS_MAX_LIFETIME = 10

    GM.GibParts = {}
    GM.GibQueue = {}

    -- CLIENT 
    function GM:UpdateGibs()

        local fn = self.GibQueue[1]
        if fn ~= nil then
            fn()
            table.remove(self.GibQueue, 1)
        end

        -- Limit the maximum possible gibs, remove oldest.
        while #self.GibParts > MAX_GIBS do
            local gib = self.GibParts[1]
            if IsValid(gib.Ent) then
                gib.Ent:Remove()
            end
            table.remove(self.GibParts, 1)
        end

        for k,v in pairs(self.GibParts) do
            if not IsValid(v.Ent) then
                table.remove(self.GibParts, k)
                continue
            end
            if v.Ent:Update() == false then
                table.remove(self.GibParts, k)
            end
        end

    end

    function GM:CreateGibPart(boneName, pos, ang, posOffset, angOffset, mdl, dmgForce, sizeType, exploded, isBone, scale)

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
        else
            print("Unable to create gib physics")
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

            gib.HitSomething = true

            if e.IsBone == true then
                return
            end

            if data.Speed > 20 and CurTime() - e.LastDecal >= 0.05 then
                util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
                e.LastDecal = CurTime()
            end

            if data.Speed >= MAX_SPEED_THRESHOLD and e.SizeType > 1 then
                e:EmitSound("Flesh.Break")
                table.insert(self.GibQueue, function()

                    if not IsValid(e) then
                        return
                    end

                    local nextSizeType = e.SizeType - 1
                    local mdl = GIB_PARTS[nextSizeType]
                    self:CreateGibPart("", e:GetPos(), e:GetAngles(), Vector(0, 0, 0), Angle(0, 0, 0), mdl, e:GetVelocity(), nextSizeType, 1)
                    self:CreateGibPart("", e:GetPos(), e:GetAngles(), Vector(0, 0, 0), Angle(0, 0, 0), mdl, e:GetVelocity(), nextSizeType, 1)

                    e:Remove()
                end)
            end

        end)

        -- Update effects
        gib.StartTime = CurTime()
        gib.LastDroplet = 0
        gib.DropletTimeEnd = CurTime() + (math.random() * 4)
        gib.Update = function(e)

            local curTime = CurTime()
            if curTime - e.StartTime >= GIBS_MAX_LIFETIME then
                e:Remove()
                return false
            end

            if curTime - e.LastDroplet < 0.1 or curTime > e.DropletTimeEnd or e.HitSomething == true then
                return true
            end

            e.LastDroplet = curTime
            if math.random() < 0.5 then
                ParticleEffectAttach("blood_impact_red_01_droplets", PATTACH_POINT_FOLLOW, e, 0)
            end

            if math.random() < 0.5 then
                ParticleEffectAttach("blood_impact_red_01_goop", PATTACH_POINT_FOLLOW, gib, 0)
            end

            return true
        end

        -- Particles
        ParticleEffectAttach("blood_impact_red_01_goop", PATTACH_POINT_FOLLOW, gib, 0)

        if sizeType > 1 then
            local spray = BLOOD_SPRAY[sizeType]
            ParticleEffectAttach(spray, PATTACH_POINT_FOLLOW, gib, 0)
        end

        if exploded == true and math.random() > 0.8 then
            ParticleEffectAttach("env_fire_tiny", PATTACH_POINT_FOLLOW, gib, 0)
        end

        table.insert(self.GibParts, {
            Ent = gib,
        })

    end

    function GM:GibPlayer(ply, dmgForce, exploded)

        if lambda_gore:GetBool() == false then
            -- Leave normal ragdoll intact.
            return
        end

        -- We have to wait for the ragdoll to be created first.
        local ply = ply
        local dmgForce = dmgForce
        local exploded = exploded
        local hookName = "LambdaRagdoll_" .. tostring(ply)
        local searchStart = CurTime()

        hook.Add("Think", hookName, function()

            if CurTime() - searchStart > 2 then 
                -- Timeout
                hook.Remove("Think", hookName)
                return
            end

            if not IsValid(ply) then
                -- Player left.
                hook.Remove("Think", hookName)
                return
            end

            local ragdoll = ply:GetRagdollEntity()
            if not IsValid(ragdoll) then
                return
            end

            -- Remove collision and dont draw the ragdoll.
            ragdoll:AddEffects(EF_NODRAW)
            ragdoll:SetNotSolid(true)
            ragdoll:DrawShadow(false)

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
                            self:CreateGibPart(boneName, pos, ang, v.Offset, v.Ang, v.Mdl, (dmgForce * 0.8) + offset, 0, exploded, true, v.Scale or 1)
                        end
                    end

                    local mdl = GIB_PARTS[sizeType]
                    self:CreateGibPart(boneName, pos, ang, Vector(0, 0, 0), Angle(0, 0, 0), mdl, (dmgForce * 0.8) + offset, sizeType, exploded, false, 1)
                end
            end

            -- Finally remove this nasty workaround.
            hook.Remove("Think", hookName)

        end)

    end

    net.Receive("LambdaGibPlayer",function(len)
        local ply = net.ReadEntity()
        local dmgForce = net.ReadVector()
        local exploded = net.ReadBool()
        GAMEMODE:GibPlayer(ply, dmgForce, exploded)
    end)

end

-- SHARED