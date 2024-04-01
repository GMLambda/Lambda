local MAT_PHYSBEAM = Material("sprites/physbeam.vmt")
local EFFECT_TIME = 0.01
function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local ent = data:GetEntity()
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "weapon_physcannon" then return end
    self.SourceEntity = ent
    self.TargetPos = pos
    self.DieTime = CurTime() + EFFECT_TIME
    self.Color = ent:GetWeaponColor()
    self.HasLight = false
    local efSparks = EffectData()
    efSparks:SetOrigin(pos)
    efSparks:SetMagnitude(2)
    efSparks:SetScale(2)
    util.Effect("Sparks", efSparks)
    local glowConvar = GetConVar("lambda_physcannon_glow")
    if glowConvar:GetInt() > 0 then
        self.EnableLights = true
    else
        self.EnableLights = false
    end
end

function EFFECT:GetStartPos()
    local ent = self.SourceEntity
    local wepPos
    local owner = ent:GetOwner()
    if ent:GetOwner() == LocalPlayer() then
        local vm = owner:GetViewModel()
        if not IsValid(vm) then return end
        local wepCenter = vm:GetAttachment(1)
        wepPos = ent:FormatViewModelAttachment(wepCenter.Pos, true)
        wepPos = wepPos - (wepCenter.Ang:Forward() * 10)
    else
        local wepCenter = ent:GetAttachment(1)
        wepPos = wepCenter.Pos
    end

    return wepPos
end

function EFFECT:Think()
    local ent = self.SourceEntity
    if not IsValid(ent) then return false end
    if ent:GetClass() ~= "weapon_physcannon" then return false end
    local owner = ent:GetOwner()
    if not IsValid(owner) then return false end
    if CurTime() > self.DieTime then return false end
    -- Emit light.
    if self.EnableLights and self.HasLight == false then
        local targetPos = self.TargetPos
        local startPos = self:GetStartPos()
        local dist = startPos:Distance(targetPos)
        local color = self.Color
        for i = 1, 3 do
            local p = i / 3
            local pos = LerpVector(p, startPos, targetPos)
            local index = bit.rshift(i, 16) + i
            local dlight = DynamicLight(index)
            dlight.dietime = self.DieTime
            dlight.pos = pos
            dlight.r = color.r
            dlight.g = color.g
            dlight.b = color.b
            dlight.brightness = 2
            dlight.decay = 500
            dlight.size = dist
        end

        self.HasLight = true
    end

    return true
end

function EFFECT:RenderBeam(startPos, endPos, seed)
    local numSegments = 20
    local frequency = 5 -- Adjust the frequency of the sine wave
    local color = self.Color
    local curTime = CurTime()
    local range = 5
    render.StartBeam(numSegments)
    for i = 0, numSegments - 1 do
        local t = i / numSegments
        local pos = LerpVector(t, startPos, endPos)
        if i > 0 then
            local yOffset = math.sin(i + (seed * 10) + curTime * frequency) * range
            local xOffset = math.cos(i + (seed * 20) + seed + curTime * frequency) * range
            local zOffset = math.sin(i + (seed * 30) + seed + curTime * frequency * 0.5) * range
            pos.x = pos.x + xOffset
            pos.y = pos.y + yOffset
            pos.z = pos.z + zOffset
            pos = pos + VectorRand() * 0.2
        end

        render.AddBeam(pos, 5 + (math.random() * 5), 1, color)
    end

    render.EndBeam()
end

function EFFECT:Render()
    local wepPos = self:GetStartPos()
    render.SetMaterial(MAT_PHYSBEAM)
    local targetPos = self.TargetPos
    for n = 1, 5 do
        self:RenderBeam(wepPos, targetPos, n)
    end
end