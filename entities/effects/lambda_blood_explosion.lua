local ParticleEmitter = ParticleEmitter

function EFFECT:Init(data)
    local size = 64
    local ply = data:GetEntity()
    self:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))
    self:SetAngles(data:GetNormal():Angle() + Angle(0.01, 0.01, 0.01))
    self.Pos = data:GetOrigin()
    self.Normal = data:GetNormal()
    self.Magnitude = data:GetMagnitude()
    self.Alpha = 1
    self.Player = ply
    --self.Force = data:GetVelocity()
    self:SetPos(data:GetOrigin())
    local emitter = ParticleEmitter(ply:GetPos())
    self.Emitter = emitter
    self:AddEffects(EF_NODRAW)
end

function EFFECT:Think()
    local emitter = self.Emitter
    local ply = self.Player

    for i = 0, 3 do
        local particle = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Pos)
        particle:SetVelocity(self.Normal * self.Magnitude)
        particle:SetDieTime(0.2)
        particle:SetStartAlpha(255)
        particle:SetEndAlpha(0)
        particle:SetStartSize(10)
        particle:SetEndSize(50)
        --particle:SetRoll( math.Rand(150, 360) )
        --particle:SetRollDelta( math.Rand(-1, 1) )
        particle:SetAirResistance(0)
        --particle:SetGravity( Vector( math.Rand( -200 , 200 ), math.Rand( -200 , 200 ), math.Rand( 10 , 100 ) ) )
        particle:SetColor(64, 0, 0)
    end

    local particle = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Pos)
    particle:SetVelocity(self.Normal * self.Magnitude)
    particle:SetDieTime(1.2)
    particle:SetStartAlpha(255)
    particle:SetEndAlpha(0)
    particle:SetStartSize(10)
    particle:SetEndSize(150)
    --particle:SetRoll( math.Rand(150, 360) )
    --particle:SetRollDelta( math.Rand(-1, 1) )
    particle:SetAirResistance(0)
    --particle:SetGravity( Vector( math.Rand( -200 , 200 ), math.Rand( -200 , 200 ), math.Rand( 10 , 100 ) ) )
    particle:SetColor(64, 0, 0)
    self:Remove()
end

function EFFECT:OnRemove()
    --self.Emitter:Finish()
end

function EFFECT:Draw()
end