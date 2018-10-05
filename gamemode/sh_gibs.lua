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

game.AddParticles( "particles/blood_impact.pcf" )
game.AddParticles( "particles/fire_01.pcf" )

for _,v in pairs(GIB_PARTS) do
    util.PrecacheModel(v)
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

        while #self.GibParts > MAX_GIBS do
            table.remove(self.GibParts, 1)
        end

        for k,v in pairs(self.GibParts) do
            if not IsValid(v.Ent) then
                table.remove(self.GibParts, k)
                continue
            end

            if CurTime() - v.StartTime >= GIBS_MAX_LIFETIME then
                v.Ent:Remove()
                table.remove(self.GibParts, k)
                continue
            end

            v.Ent:Update()
        end

    end

    function GM:CreateGibPart(boneName, pos, ang, dmgForce, sizeType, exploded)

        local mdl = nil
        local isBone = true

        if sizeType > 0 then
            mdl = GIB_PARTS[sizeType]
            isBone = false
        else
            if boneName == "ValveBiped.Bip01_Head1" then
                mdl = "models/gibs/hgibs.mdl"
            end
        end

        local gib = ents.CreateClientProp(mdl)
        gib.Emitter = ParticleEmitter(pos)
        gib.IsBone = isBone
        gib.SizeType = sizeType
        gib:SetPos(pos)
        gib:SetAngles(ang)
        gib:SetModel(mdl)
        gib:Spawn()
        gib:SetMaterial("model/flesh")

        gib:PhysicsInit(SOLID_VPHYSICS)
        gib:SetMoveType(MOVETYPE_VPHYSICS)
        gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        gib:SetNotSolid(true)
        local phys = gib:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dmgForce)
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

            if data.Speed > 20 and CurTime() - e.LastDecal >= 0.05 and e.IsBone == false then
                util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
                e.LastDecal = CurTime()
            end

            if data.Speed >= MAX_SPEED_THRESHOLD and e.SizeType > 1 then
                e:EmitSound("Flesh.Break")
                table.insert(self.GibQueue, function()

                    if not IsValid(e) then
                        return
                    end

                    self:CreateGibPart("", e:GetPos(), e:GetAngles(), e:GetVelocity(), e.SizeType - 1)
                    self:CreateGibPart("", e:GetPos(), e:GetAngles(), e:GetVelocity(), e.SizeType - 1)

                    e:Remove()
                end)
            end

        end)

        -- Update effects
        gib.LastDroplet = 0
        gib.DropletTimeEnd = CurTime() + (math.random() * 4)
        gib.Update = function(e)

            local curTime = CurTime()
            if curTime - e.LastDroplet < 0.1 or curTime > e.DropletTimeEnd or e.HitSomething == true then
                return
            end

            e.LastDroplet = curTime
            if math.random() < 0.5 then
                ParticleEffectAttach("blood_impact_red_01_droplets", PATTACH_POINT_FOLLOW, e, 0)
            end

            if math.random() < 0.5 then
                ParticleEffectAttach("blood_impact_red_01_goop", PATTACH_POINT_FOLLOW, gib, 0)
            end
        end

        -- Particles
        ParticleEffectAttach("blood_impact_red_01_goop", PATTACH_POINT_FOLLOW, gib, 0)

        if sizeType > 1 then
            local spray = BLOOD_SPRAY[sizeType]
            ParticleEffectAttach(spray, PATTACH_POINT_FOLLOW, gib, 0)
        end

        if exploded == true and math.random() < 0.2 then
            ParticleEffectAttach("env_fire_tiny", PATTACH_POINT_FOLLOW, gib, 0)
        end

        table.insert(self.GibParts, {
            StartTime = CurTime(),
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

            -- Head
            -- models/gibs/hgibs.mdl
            local boneId = ply:LookupBone("ValveBiped.Bip01_Head1")
            local offset = VectorRand() * dmgForce:Length2D()
            if boneId == nil and boneId == -1 then
                local pos, ang = ply:GetBonePosition(boneId)
                self:CreateGibPart("ValveBiped.Bip01_Head1", pos, ang, (dmgForce * 0.8) + offset, 0, exploded)
            else
                local pos, ang = ply:EyePos(),ply:GetAngles()
                self:CreateGibPart("ValveBiped.Bip01_Head1", pos, ang, (dmgForce * 0.8) + offset, 0, exploded)
            end

            for group = 0, numHitBoxGroups - 1 do
                local numHitBoxes = ply:GetHitBoxCount( group )

                for hitbox = 0, numHitBoxes - 1 do
                    local bone = ply:GetHitBoxBone( hitbox, group )
                    local boneName = ply:GetBoneName(bone)
                    local pos, ang = ply:GetBonePosition(bone)
                    local offset = VectorRand() * dmgForce:Length2D()
                    self:CreateGibPart(boneName, pos, ang, (dmgForce * 0.8) + offset, 3, exploded)
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