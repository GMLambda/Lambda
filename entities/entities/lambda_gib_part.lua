AddCSLuaFile()

ENT.Base = "lambda_entity"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

game.AddParticles( "particles/blood_impact.pcf" )
game.AddParticles( "particles/fire_01.pcf" )

PrecacheParticleSystem( "blood_impact_red_01_mist" )

-- models/gibs/hgibs_spine.mdl

local CURRENT_GIBS = {}
local GIBS_MAX = 100
local GIBS_LIFETIME = 10
local GIBS_FADETIME = 5

local GIB_PARTS = 
{
	[1] = "models/props_junk/watermelon01_chunk02c.mdl",
	[2] = "models/props_junk/watermelon01_chunk02b.mdl",
	[3] = "models/props_junk/watermelon01_chunk02a.mdl",
}

local BLOOD_SPRAY = 
{
	[3] = "blood_advisor_pierce_spray",
	[2] = "blood_advisor_pierce_spray_b",
	[1] = "blood_advisor_pierce_spray_c",
}

DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
	BaseClass.PreInitialize(self)
end

function ENT:PlaySound(snd)

	if self.NextSoundTime == nil or CurTime() > self.NextSoundTime then 
		self:EmitSound(snd)
		self.NextSoundTime = CurTime() + 0.1
	end

end 

function ENT:Initialize()

    BaseClass.Initialize(self)
    self.StartTime = self.StartTime or CurTime()
    self.Alpha = self.Alpha or 255
    self.Size = self.Size or 0
    self.BoneName = self.BoneName or ""
    self.LastDecal = CurTime()
    self.Queue = self.Queue or {}

    if SERVER then
    	ParticleEffectAttach("blood_impact_red_01_mist", PATTACH_POINT_FOLLOW, self, 0)

    	for k,v in pairs(CURRENT_GIBS) do
    		if not IsValid(v) then 
    			table.remove(CURRENT_GIBS, k)
    		end
    	end

    	table.insert(CURRENT_GIBS, self)
    	while #CURRENT_GIBS > GIBS_MAX do 
    		table.remove(CURRENT_GIBS, 1)
    	end 
    end 

end

function ENT:InitializeGibs(boneName, pos, ang, force, size, exploded)

	local mdl
	local mat
	local physMat
	local isFlesh = false 

	if size == 0 and boneName == "ValveBiped.Bip01_Head1" then
		mdl = "models/gibs/hgibs.mdl"
	else
		mdl = GIB_PARTS[size]
		mat = "models/flesh"
		physMat = "flesh"
		isFlesh = true
	end 

	self.Size = size
	self.BoneName = boneName
	self.IsFlesh = isFlesh

	self:SetModel(mdl)
	self:SetPos(pos)
	self:SetAngles(ang)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	if mat ~= nil then
		self:SetMaterial(mat)
	end 

	self:Spawn()
	self:PhysWake()
	self.StartTime = CurTime()
	self:SetColor(Color(255, 255, 255, 255))
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self.Queue = {}

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:SetVelocity(force or Vector(0, 0, 0))
		if physMat ~= nil then
			phys:SetMaterial(physMat)
		end
	end

	if isFlesh == true then
		ParticleEffectAttach("blood_impact_red_01_mist", PATTACH_POINT_FOLLOW, self, 0)

		local spray = BLOOD_SPRAY[size]
		ParticleEffectAttach(spray, PATTACH_POINT_FOLLOW, self, 0)

		if exploded == true then 
			if math.random() > 0.5 then 
				-- env_fire_small
				ParticleEffectAttach("env_fire_tiny", PATTACH_POINT_FOLLOW, self, 0)
			end
		end 
	end 

end 

function ENT:RunQueue()
	local fn = self.Queue[1]
	if fn ~= nil then 
		fn()
		table.remove(self.Queue, 1)
	end
end 

function ENT:Think()

	local elapsed = CurTime() - (self.StartTime or CurTime())
	if SERVER then 
		if elapsed >= GIBS_LIFETIME then
			--print("Fading out.")
			self.FadeFinish = CurTime() + GIBS_FADETIME
			self.Think = self.ThinkFade
		end
		self:RunQueue()
	end 

end 

function ENT:ThinkFade()
	local left = self.FadeFinish - CurTime()
	if left < 0 then 
		self:Remove()
		return
	end 
	self:RunQueue()
	left = left / GIBS_FADETIME
	--self:SetColor(Color(255, 255, 255, left * 255))
	--self:SetModelScale(left, 0.1)
end

local MAX_SPEED_THRESHOLD = 300

function ENT:PhysicsCollide(data, collider)

	if data.Speed > 20 and CurTime() - self.LastDecal >= 0.05 and self.IsFlesh == true then
		util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
		self.LastDecal = CurTime()
	end 

	--print(self.Size, data.Speed)
	if data.Speed >= MAX_SPEED_THRESHOLD then 
		if self.Size > 1 then 
			self:SplitGib()
		else 
			self:DestroyGib()
		end
	else 
		self:HandleImpact(data, collider)
	end 

end

function ENT:HandleImpact(data, collider)

	local snd = nil
	if self.IsFlesh == true then
		if data.Speed >= 150 then
			snd = "Flesh.ImpactHard"
		elseif data.Speed >= 50 then 
			snd = "Flesh.ImpactSoft"
		end 
	end 

	if snd ~= nil then
		self:EmitSound(snd)
	end 

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then 
		return 
	end 

	local vel = data.OurOldVelocity --phys:GetVelocity()
	local diff = (vel * 0.5) * -1
	phys:SetVelocity(diff)

end 

function ENT:DestroyGib()

	--print("Removing gibs")
	--self:Remove()

end 

function ENT:SplitGib()

	-- We have to run this in a queue otherwise we get warnings in the console.
	table.insert(self.Queue, function()
		self:PlaySound("Flesh.Break")

		local gib1 = ents.Create("lambda_gib_part")
		gib1:InitializeGibs("", self:GetPos(), self:GetAngles(), self:GetVelocity(), self.Size - 1)

		local gib2 = ents.Create("lambda_gib_part")
		gib2:InitializeGibs("", self:GetPos(), self:GetAngles(), self:GetVelocity(), self.Size - 1)

		self:Remove()
	end)

end

if CLIENT then

	function ENT:DrawTranslucent()
		self:DrawModel()
	end

end
