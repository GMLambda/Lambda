AddCSLuaFile()

ENT.Base = "lambda_entity"
ENT.Type = "anim"

DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
	BaseClass.PreInitialize(self)
end

function ENT:Initialize()

    BaseClass.Initialize(self)

	if CLIENT then
		CreateParticleSystem(self, "blood_impact_red_01", PATTACH_ABSORIGIN_FOLLOW)
		self.Emitter = ParticleEmitter(self:GetPos(), false)
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_DISSOLVING)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(true)
		end
		self:PhysWake()
	end

	self.LastDecalTime = CurTime()
	self.LastThinkTime = CurTime()
	self.BloodAmount = 100
	self.Sticky = false
	self.EmitBlood = false

end

function ENT:SetSticky(sticky)
	self.Sticky = sticky
end

function ENT:SetEmitBlood(emit)
	self.EmitBlood = emit
end

function ENT:OnRemove()
    if CLIENT then
		--self.Emitter:Finish()
	end
end

function ENT:Think()

	if CLIENT then

		local emitter = self.Emitter
		if self.EmitBlood ~= true then
			return
		end

		local curTime = CurTime()
		local elapsed = curTime - self.LastThinkTime

		self.BloodAmount = self.BloodAmount - (elapsed * 10)
		if self.BloodAmount < 0 then
			return
		end

		self.LastThinkTime = curTime

		local pos = self:GetPos()
		local nearbyGibs = false
		for k,v in pairs(ents.FindInBox(pos - Vector(15, 15, 10), pos + Vector(15, 15, 10))) do
			if v:GetClass() == "lambda_gib_part" then
				nearbyGibs = true
				break
			end
		end

		local count = math.Round(self.BloodAmount / 30)
		local mins = self:OBBMins()
		local maxs = self:OBBMaxs()
		local size = maxs - mins
		local sizeLen = size:Length() / 100
		local decalRand = 20

		if nearbyGibs == true then
			sizeLen = sizeLen / 2
			decalRand = 100
		end

		for i = 0, count do
			local particle = emitter:Add("effects/blood_core", pos + VectorRand() * 5)
			particle:SetVelocity( VectorRand() * 30 )
			particle:SetGravity(Vector(0, 0, -600))
			particle:SetDieTime( math.Rand( 0.2, 0.4 ) )
			particle:SetStartAlpha( 200 )
			particle:SetStartSize( math.Rand( 10, 20 ) * sizeLen )
			particle:SetEndSize( math.Rand( 20, 30 ) * sizeLen )
			particle:SetCollide(true)
			particle:SetRoll( math.Rand( 0, 180 ) )
			particle:SetRollDelta( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 100, 0, 0 )
			particle:SetCollideCallback(function(part, hitPos, hitNormal)
				part:SetDieTime(0.2)
				part:SetLifeTime(0)
				if math.random(1, decalRand) == 1 then
					util.Decal("Blood", hitPos + hitNormal, hitPos - hitNormal)
				end
			end)

			particle = emitter:Add("effects/blood", self:GetPos())
			particle:SetVelocity( VectorRand() * 30 )
			particle:SetGravity(Vector(0, 0, -600))
			particle:SetDieTime( 10 )
			particle:SetStartAlpha( 150 )
			particle:SetStartSize( math.Rand( 3, 6 ) )
			particle:SetEndSize( math.Rand( 6, 10 ) )
			particle:SetCollide(true)
			particle:SetRoll( math.Rand( 0, 360 ) )
			particle:SetColor( 128, 0, 0 )
			particle:SetCollideCallback(function(part, hitPos, hitNormal)
				part:SetDieTime(0.2)
				part:SetLifeTime(0)
				if math.random(1, decalRand) == 1 then
					util.Decal("Blood", hitPos + hitNormal, hitPos - hitNormal)
				end
			end)

		end

		self:SetNextClientThink(CurTime() + 0.1)
		return true
	end

end

function ENT:PhysicsCollide(data, collider)

	local curTime = CurTime()

	if curTime - (self.LastImpactTime or 0) < 0.05 then
		return
	end

	self.LastImpactTime = curTime

	if data.Speed >= 50 then
		local effectdata = EffectData()
		effectdata:SetNormal(data.HitNormal)
		effectdata:SetOrigin(data.HitPos)
		effectdata:SetMagnitude(3)
		effectdata:SetScale(10)
		effectdata:SetFlags(3)
		effectdata:SetColor(0)
		util.Effect("bloodspray", effectdata, true, true)

		local effectdata = EffectData()
		effectdata:SetNormal(data.HitNormal)
		effectdata:SetOrigin(data.HitPos)
		effectdata:SetMagnitude(data.Speed / 100)
		effectdata:SetScale(10)
		effectdata:SetFlags(3)
		effectdata:SetColor(0)
		util.Effect("BloodImpact", effectdata, true, true)

	end

	local emitBlood = false
	local emitSound = false

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(phys:GetVelocity() * 0.8)

		local ent = data.HitEntity
		if self.Sticky == true and not self:OnGround() and ent:IsWorld() == true and data.Speed > 100 then
			--phys:EnableMotion(false)
			emitBlood = true
		end
	end

	if emitBlood == true or (data.Speed > 10 and math.random(0, 5) == 1) then
		util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
	end

	if emitSound == true or (data.Speed > 25) then
		self:EmitSound( "physics/flesh/flesh_squishy_impact_hard3.wav", math.Clamp(data.Speed, 0, 75), math.Rand( 70, 100 ) )
	end

end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
