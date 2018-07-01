local DbgPrint = GetLogging("Trigger")

ENT.Base = "lambda_trigger"
ENT.Type = "brush"

DEFINE_BASECLASS("lambda_trigger")

DAMAGEMODEL_NORMAL = 0
DAMAGEMODEL_DOUBLE_FORGIVENESS = 1
TRIGGER_HURT_FORGIVE_TIME = 3.0

function ENT:HasDamageType(dmgtype)
	return bit.band(self.DamageType, DMG_RADIATION) ~= 0
end

local THINKTYPE_NONE = 0
local THINKTYPE_HURT = 1
local THINKTYPE_RADIATION = 2

function ENT:PreInitialize()

	BaseClass.PreInitialize(self)

	self:SetupOutput("OnHurtPlayer")
	self:SetupOutput("OnHurt")

	self.DamageType = 0
	self.Damage = 0
	self.DamageCap = 0
	self.DamageModel = 0
	self.NoDamageForce = false
	self.DamageResetTime = 0
	self.WaitTime = 0.2
	self.ThinkType = THINKTYPE_NONE

end

function ENT:Initialize()

	BaseClass.Initialize(self)

	self.OriginalDamage = self.Damage
	self.LastDamageTime = 0

	self.ThinkType = THINKTYPE_NONE

	if self:HasDamageType(DMG_RADIATION) then

		self.ThinkType = THINKTYPE_RADIATION

	end

end

function ENT:KeyValue( key, val )

	BaseClass.KeyValue(self, key, val)

	if key:iequals("damage") then
		self.Damage = tonumber(val)
	elseif key:iequals("damagecap") then
		self.DamageCap = tonumber(val)
	elseif key:iequals("damagetype") then
		self.DamageType = tonumber(val)
	elseif key:iequals("damagemodel") then
		self.DamageModel = tonumber(val)
	elseif key:iequals("nodmgforce") then
		self.NoDamageForce = tobool(val)
	end

end

function ENT:Think()

	BaseClass.Think(self)

	if self.ThinkType == THINKTYPE_HURT then
		return self:HurtThink()
	elseif self.ThinkType == THINKTYPE_RADIATION then
		return self:RadiationThink()
	end

end

function ENT:Touch(ent)

	if self.ThinkType == THINKTYPE_NONE then
		self.ThinkType = THINKTYPE_HURT
	end

	return BaseClass.Touch(self, ent)

end

function ENT:EndTouch(ent)

    if self:PassesTriggerFilters(ent) then

		self.HurtEntities = self.HurtEntities or {}

		if self.HurtEntities[ent] == nil then
			self:HurtEntity(ent, self.Damage * 0.5 )
		end

	end

	return BaseClass.EndTouch(self, ent)

end

function ENT:HurtThink()

	if self:HurtTouchingObjects(0.5) <= 0 then
		self.ThinkType = THINKTYPE_NONE
	end

	self:NextThink(CurTime() + 0.5)
	return true

end

function ENT:CalcDistanceFromPoint(vec)

	local nearestPoint = self:NearestPoint(vec)
	return nearestPoint:Distance(vec)

end

function ENT:RadiationThink()

	for _,v in pairs(player.GetAll()) do

		local pos2 = v:GetPos()

		local nearestPoint = self:NearestPoint(pos2)
		local range = nearestPoint:Distance(pos2)

		v:SetNearestRadiationRange(range * 3)

	end

	local curTime = CurTime()

	local dt = curTime - self.LastDamageTime
	if dt >= 0.5 then
		self.LastDamageTime = curTime
		self:HurtTouchingObjects( dt )
	end

	self:NextThink(curTime + 0.25)

	return true

end

function ENT:HurtTouchingObjects(dt)

	self.HurtEntities = {}

	if self:GetNWVar("Disabled") == true then
		return 0
	end

	local dmgAmount = self.Damage * dt
	local hurtCount = 0

	local touching = self:GetTouchingObjects()
	for _, ent in pairs(touching) do

		if IsValid(ent) then
			if self:HurtEntity(ent, dmgAmount) == true then
				hurtCount = hurtCount + 1
			end
		end

	end

	local curTime = CurTime()

	if self.DamageModel == DAMAGEMODEL_DOUBLE_FORGIVENESS then

		if hurtCount == 0 then

			if curTime > self.DamageResetTime then
				self.Damage = self.OriginalDamage
			end

		else

			self.Damage = self.Damage * 2

			if self.Damage > self.DamageCap then
				self.Damage = self.DamageCap
			end

			self.DamageResetTime = curTime + TRIGGER_HURT_FORGIVE_TIME

		end

	end

	return hurtCount

end

local POUNDS_PER_KG	= 2.2
local KG_PER_POUND = 1.0 / POUNDS_PER_KG
local BULLET_IMPULSE_EXAGGERATION = 3.5

local function lbs2kg(x)
	return x * KG_PER_POUND
end

local function BULLET_MASS_GRAINS_TO_LB(grains)
	return 0.002285 * grains / 16.0
end

local function BULLET_MASS_GRAINS_TO_KG(grains)
	return lbs2kg(BULLET_MASS_GRAINS_TO_LB(grains))
end

local function BULLET_IMPULSE(grains, ftpersec)

	return ftpersec * 12 * BULLET_MASS_GRAINS_TO_KG(grains) * BULLET_IMPULSE_EXAGGERATION

end

local SMG1_FORCE = BULLET_IMPULSE( 200, 1225 )
local phys_pushscale = GetConVar("phys_pushscale")

function ENT:CalculateBulletForce(d, forceDir, forcePos, scale)

	d:SetDamagePosition( forcePos );

	local vecForce = forceDir;
	vecForce:Normalize()

	vecForce = vecForce * SMG1_FORCE -- Hardcoded in Source SDK as SMG1.
	vecForce = vecForce * phys_pushscale:GetFloat();
	vecForce = vecForce * scale;

	d:SetDamageForce( vecForce );

end

function ENT:CalculateExplosiveDamageForce(d, forceDir, forcePos, scale)

	d:SetDamagePosition(forcePos)

	-- ImpulseScale(targetMass, desiredSpeed) = (targetMass * desiredSpeed)

	local clampForce = 30000 -- ImpulseScale( 75, 400 )
	local forceScale = d:GetBaseDamage() * 300 -- ImpulseScale( 75, 4 )

	if forceScale > clampForce then
		forceScale = clampForce
	end

	local rnd = math.random()
	forceScale = forceScale * (0.85 + ((rnd * 1.15) - 0.85))

	local vecForce = forceDir
	vecForce:Normalize()

	vecForce = vecForce * forceScale
	vecForce = vecForce * phys_pushscale:GetFloat()
	vecForce = vecForce * scale

	d:SetDamageForce(vecForce)

end

function ENT:CalculateMeleeDamageForce(d, forceDir, forcePos, scale)

	d:SetDamagePosition(forcePos)

	-- ImpulseScale(targetMass, desiredSpeed) = (targetMass * desiredSpeed)

	-- impulse large enough to push a 75kg man 4 in/sec per point of damage
	local forceScale = d:GetBaseDamage() * 300 -- ImpulseScale( 75, 4 )

	local vecForce = forceDir
	vecForce:Normalize()
	vecForce = vecForce * forceScale
	vecForce = vecForce * phys_pushscale:GetFloat()
	vecForce = vecForce * scale

	d:SetDamageForce(vecForce)

end

function ENT:GuessDamageForce(d, forceDir, forcePos, scale)

	scale = scale or 1

	if self:HasDamageType(DMG_BULLET) then
		self:CalculateBulletForce(d, forceDir, forcePos, scale)
	elseif self:HasDamageType(DMG_BLAST) then
		self:CalculateExplosiveDamageForce(d, forceDir, forcePos, scale)
	else
		self:CalculateMeleeDamageForce(d, forceDir, forcePos, scale)
	end

end

function ENT:HurtEntity(ent, amount)

	if self:GetNWVar("Disabled") == true then
		return false
	end

	if not IsValid(ent) then
		return false
	end

	if self:PassesTriggerFilters(ent) == false then
		return false
	end

	if self.Damage < 0 then

		ent:SetHealth(ent:GetHealth() - (-self.Damage))

	else

		local pos = self:WorldSpaceCenter()
		local damagePos = ent:NearestPoint(pos)

		local d = DamageInfo()
		d:SetDamage( amount )
		d:SetDamageType( self.DamageType )
		d:SetInflictor(self)
		d:SetAttacker(self)
		if self.NoDamageForce then
			d:SetDamageForce( Vector(0, 0, 0) )
		else
			self:GuessDamageForce(d, damagePos - pos, damagePos)
		end

		ent:TakeDamageInfo(d)
	end

	--DbgPrint(self, "Causing damage to " .. tostring(ent))

	if ent:IsPlayer() then
		self:FireOutputs("OnHurtPlayer", ent, self)
	else
		self:FireOutputs("OnHurt", ent, self)
	end

	self.HurtEntities = self.HurtEntities or {}
	self.HurtEntities[ent] = true

	return true

end
