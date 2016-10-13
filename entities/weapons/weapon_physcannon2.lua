-- WIP! Don't touch me

AddCSLuaFile()

SWEP.PrintName = "#HL2_GravityGun"
SWEP.Author = "Zeh Matt"
SWEP.Instructions = ""

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "physgun"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.ViewModel = "models/weapons/v_physcannon.mdl"
SWEP.WorldModel = "models/weapons/w_Physics.mdl"

if CLIENT then
	SWEP.Slot = 0
	SWEP.SlotPos = 2
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
	SWEP.DrawWeaponInfoBox = false
	SWEP.BounceWeaponIcon = false
	SWEP.WepSelectIcon = surface.GetTextureID( "weapons/swep" )
	SWEP.RenderGroup = RENDERGROUP_OPAQUE
end

--
-- ConVars
local physcannon_tracelength = GetConVar("physcannon_tracelength")
local physcannon_maxforce = GetConVar("physcannon_maxforce")
local physcannon_cone = GetConVar("physcannon_cone")
local physcannon_pullforce = GetConVar("physcannon_pullforce")

--
-- States
local ELEMENT_STATE_NONE = -1
local ELEMENT_STATE_OPEN = 0
local ELEMENT_STATE_CLOSED = 1

--
-- Effect State
local EFFECT_NONE = 0
local EFFECT_CLOSED = 1
local EFFECT_READY = 2
local EFFECT_HOLDING = 3
local EFFECT_LAUNCH = 4

--
-- Object Find Result
local OBJECT_FOUND = 0
local OBJECT_NOT_FOUND = 1
local OBJECT_BEING_DETACHED = 2


--
-- Code
function SWEP:Initialize()
	DbgPrint(self, "Initialize")

	self.CalcViewModelView = nil
	self.GetViewModelPosition = nil

	self.LastPuntedObject = nil
	self.NextPuntTime = CurTime()
	self.EffectState = EFFECT_NONE
	self.OldEffectState = EFFECT_NONE
	self.ChangeState = ELEMENT_STATE_NONE
	self.ElementDebounce = CurTime()
	self.CheckSuppressTime = CurTime()
	self.ObjectShadowParams = {}
	self.DebounceSecondary = false
	self:SetWeaponHoldType(self.HoldType)

	if SERVER then
		local motionController = ents.Create("base_entity")
		motionController:SetPos(self:GetPos())
		motionController:Spawn()
		--motionController:SetParent(self)
		motionController.PhysicsSimulate = function(mc, phys, dt)
			return self:PhysicsSimulate(phys, dt)
		end
		self:SetNW2Entity("MotionController", motionController)
	end

	self:SetNW2Vector("TargetPos", Vector(0, 0, 0))
	self:SetNW2Angle("TargetAng", Angle(0, 0, 0))
	self:SetNW2Bool("Holding", false)
	self:SetNW2Entity("AttachedEnt", nil)

	if CLIENT then
		hook.Add("EntityNetworkedVarChanged", self, function(self, ent, name, oldval, newval)
			if ent == self then
				--DbgPrint("NetworkVar Changed: ", name, oldval, newval)
			end
		end)
	end
end

function SWEP:GetMotionController()
	return self:GetNW2Entity("MotionController")
end

function SWEP:LaunchObject(ent, fwd, force)

	if self.LastPuntedObject == ent and CurTime() < self.NextPuntTime then
		return
	end

	self:DetachObject()

	self.LastPuntedObject = ent
	self.NextPuntTime = CurTime() + 0.5

	self:ApplyVelocityBasedForce(ent, fwd)

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

	self:DoEffect(EFFECT_LAUNCH, ent:WorldSpaceCenter())

end

function SWEP:PrimaryAttack()
	--DbgPrint(self, "PrimaryAttack")

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	self:SetNextPrimaryFire(CurTime() + 0.5)

	if self:GetNW2Bool("Holding") == true then

		local ent = self:GetNW2Entity("AttachedEnt")
		if not IsValid(ent) then
			return
		end

		-- Make sure its in range.
		local dist = (ent:WorldSpaceCenter() - owner:WorldSpaceCenter()):Length()
		if dist > physcannon_tracelength:GetFloat() then
			return self:DryFire()
		end

		self:LaunchObject(ent, owner:GetAimVector(), physcannon_maxforce:GetFloat())
		self:PrimaryFireEffect()
		self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

		return
	end

	-- Punt object.
	local eyeAng = owner:EyeAngles()
	local fwd = owner:GetAimVector()
	local start = owner:GetShootPos()
	local puntDist = physcannon_tracelength:GetFloat()
	local endPos = start + (fwd * puntDist)
	local trMask = bit.bor(MASK_SHOT, CONTENTS_GRATE)

	local tr = util.TraceHull({
		start = start,
		endpos = endPos,
		filter = owner,
		mins = Vector(-8, -8, -8),
		maxs = Vector(8, 8, 8),
		mask = trMask
	})

	local valid = true
	local ent = tr.Entity

	if tr.Fraction == 1 or not IsValid(ent) or ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) then
		valid = false
	elseif ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
		-- FIXME: GetInternalVariable does return nothing for m_takedamage
		local savetable = ent:GetSaveTable()
		if savetable.m_takedamage ~= nil and savetable.m_takedamage == 0 --[[DAMAGE_NO]] then
			valid = false
		end
	end

	if valid == false then
		tr = util.TraceLine({
			start = start,
			endpos = endPos,
			mask = trMask,
			filter = owner,
		})
		ent = tr.Entity
		if tr.Fraction == 1 or not IsValid(ent) or ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) then
			return self:DryFire()
		end
	end

	if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
		-- FIXME: GetInternalVariable does return nothing for m_takedamage
		local savetable = ent:GetSaveTable()
		if savetable.m_takedamage ~= nil and savetable.m_takedamage == 0 --[[DAMAGE_NO]] then
			return self:DryFire()
		end

		-- SDK: // Don't let the player zap any NPC's except regular antlions and headcrabs.
		if owner:IsPlayer() and ent:IsPlayer() then
			return self:DryFire()
		end

		return self:PuntNonVPhysics(ent, fwd, tr)
	end

	if ent:IsVPhysicsFlesh() then
		return self:DryFire()
	end

	return self:PuntVPhysics(ent, fwd, tr)

end

function SWEP:CanSecondaryAttack()

	local owner = self.Owner
	if not IsValid(owner) then
		DbgPrint("Invalid owner")
		return false
	end

	return true

end

function SWEP:SecondaryAttack()

	DbgPrint(self, "SecondaryAttack")

	if self:CanSecondaryAttack() == false then
		return
	end

	if self:GetNW2Bool("Holding") == true then

		self:SetNextPrimaryFire(CurTime() + 0.5)
		self:SetNextSecondaryFire(CurTime() + 0.5)
		self.Secondary.Automatic = true

		self:DetachObject()
		self:DoEffect(EFFECT_READY)
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	else

		local res = self:FindObject()

		if res == OBJECT_FOUND then
			self.Secondary.Automatic = false -- No longer automatic, debounce.
			self:SetNextSecondaryFire(CurTime() + 0.5)
		elseif res == OBJECT_NOT_FOUND then
			self:SetNextSecondaryFire(CurTime() + 0.1)
			self.Secondary.Automatic = true
		elseif res == OBJECT_BEING_DETACHED then
			self:SetNextSecondaryFire(CurTime() + 0.01)
			self.Secondary.Automatic = true
		end

		self:DoEffect(EFFECT_HOLDING)

	end

end

function SWEP:FindObjectInCone(start, fwd, coneSize)
	local nearestDist = physcannon_tracelength:GetFloat() + 1.0
	local mins = start - Vector(nearestDist, nearestDist, nearestDist)
	local maxs = start + Vector(nearestDist, nearestDist, nearestDist)
	local nearest

	for _,v in pairs(ents.FindInBox(mins, maxs)) do
		if not IsValid(v:GetPhysicsObject()) then
			continue
		end
		local los = v:WorldSpaceCenter() - start
		local dist = los:Length()
		los:Normalize()
		if dist >= nearestDist or los:DotProduct(fwd) < coneSize then
			continue
		end

 		local tr = util.TraceLine({
			start = start,
			endpos = v:WorldSpaceCenter(),
			mask = bit.bor(MASK_SHOT, CONTENTS_GRATE),
			filter = self.Owner
		})

		if tr.Entity == v then
			nearestDist = dist
			nearest = v
		end
	end

	return nearest
end

function SWEP:FindObject()

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	local fwd = owner:GetAimVector()
	local start = owner:GetShootPos()
	local testLength = physcannon_tracelength:GetFloat() * 4.0
	local endPos = start + (fwd * testLength)
	local trMask = bit.bor(MASK_SHOT, CONTENTS_GRATE)

	local tr = util.TraceLine({
		start = start,
		endpos = endPos,
		mask = trMask,
		filter = owner
	})

	if tr.Fraction == 1 or not IsValid(tr.Entity) or tr.HitWorld == true then
		tr = util.TraceHull({
			start = start,
			endpos = endPos,
			mask = trMask,
			filter = owner,
			mins = Vector(-4, -4, -4),
			maxs = Vector(4, 4, 4)
		})
	end

	local ent
	if IsValid(tr.Entity) then
		ent = tr.Entity:GetRootMoveParent()
	end

	local attach = false
	local pull = false

	if tr.Fraction ~= 1.0 and IsValid(tr.Entity) and tr.HitWorld == false then
		if tr.Fraction <= 0.25 then
			attach = true
		elseif tr.Fraction > 0.25 then
			pull = true
		end
	end

	local coneEnt
	if attach == false and pull == false then
		coneEnt = self:FindObjectInCone(start, fwd, physcannon_cone:GetFloat())
	end

	if IsValid(coneEnt) then
		ent = coneEnt

		if ent:WorldSpaceCenter():DistToSqr(start) <= (testLength * testLength) then
			attach = true
		else
			pull = true
		end
	end

	if false --[[CanPickupObject(ent) == false]] then
		return OBJECT_NOT_FOUND
	end

	if attach == true then
		if self:AttachObject(ent, tr) == true then
			return OBJECT_FOUND
		end
		return OBJECT_NOT_FOUND
	end

	if pull == false then
		return OBJECT_NOT_FOUND
	end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then
		return OBJECT_NOT_FOUND
	end

	local pullDir = start - ent:WorldSpaceCenter()
	pullDir = pullDir:GetNormal() * physcannon_pullforce:GetFloat()

	local mass = ent:GetPhysMass()
	if mass < 50 then
		pullDir = pullDir * ((mass + 0.5) * (1 / 50.0))
	end

	phys:ApplyForceCenter(pullDir)
	return OBJECT_NOT_FOUND

end

function SWEP:PhysicsSimulate( phys, dt )

	--DbgPrint(self, "PhysicsSimulate", phys, dt)

	self.ObjectShadowParams.deltatime = dt

	--phys:Wake()
	phys:ComputeShadowControl(self.ObjectShadowParams)

	return SIM_LOCAL_ACCELERATION

end

function SWEP:UpdateObject()

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	local lastUpdate = self.LastSimUpdate or CurTime()
	local dt = CurTime() - lastUpdate
	self.lastUpdate = CurTime()
	local attachedObject = self:GetNW2Entity("AttachedEnt")

	if not IsValid(attachedObject) then
		return self:DetachObject()
	end

	local fwd = owner:GetAimVector()
	local start = owner:GetShootPos()
	local minDist = 24
	local playerLen = owner:OBBMaxs():Length2D()
	local objLen = attachedObject:OBBMaxs():Length2D()
	local distance = minDist + playerLen + objLen

	local targetAng = self:GetNW2Angle("TargetAng")
	local targetAttachment = self:GetNW2Vector("AttachmentPoint")

	local ang = owner:LocalToWorldAngles(targetAng)
	local endPos = start + (fwd * distance)

	local attachmentPoint = Vector(targetAttachment)
	attachmentPoint:Rotate(ang)

	self.ObjectShadowParams.secondstoarrive = (1 / 33) * 0.5
	self.ObjectShadowParams.pos = endPos - attachmentPoint
	self.ObjectShadowParams.angle = ang

	self.ObjectShadowParams.maxangular = 2000
	self.ObjectShadowParams.maxangulardamp = 150
	self.ObjectShadowParams.maxspeed = 1000000
	self.ObjectShadowParams.maxspeeddamp = 2000
	self.ObjectShadowParams.dampfactor = 0.7
	self.ObjectShadowParams.teleportdistance = 200

	attachedObject:PhysWake()

	if CLIENT then
		local phys = attachedObject:GetPhysicsObject()
		if IsValid(phys) then
			self:PhysicsSimulate(phys, dt)
			--attachedObject:SetPos(phys:GetPos())
			--attachedObject:SetAngles(phys:GetAngles())
		else
			DbgPrint("Invalid phys!", phys)
		end
	end

end

function SWEP:Think()

	if self:GetNW2Bool("Holding") == true then
		self:UpdateObject()
	end

end

function SWEP:AttachObject(ent, tr)

	DbgPrint(self, "AttachObject", ent)

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	local phys
	if SERVER then
	 	phys = ent:GetPhysicsObject()
	 else
		ent:PhysicsInit(SOLID_VPHYSICS)
		ent:SetMoveType(MOVETYPE_VPHYSICS)
		ent:SetSolid(SOLID_VPHYSICS)
		phys = ent:GetPhysicsObject()
		phys:Wake()
		phys:EnableMotion(true)
	 end

	if not IsValid(phys) then
		DbgPrint("Physics invalid!")
		return
	end

	phys:AddGameFlag(FVPHYSICS_PLAYER_HELD)

	local motionController = self:GetMotionController()

	motionController:StartMotionController()
	motionController:AddToMotionController(phys)

	--if SERVER then
		if not IsValid(ent:GetOwner()) then
			ent:SetOwner(owner)
			self.ResetOwner = true
		end

		self.SavedMass = {}
		self.SavedRotDamping = {}
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys2 = ent:GetPhysicsObjectNum(i)
			if not IsValid(phys2) then
				continue
			end
			self.SavedMass[i] = phys2:GetMass()
			phys2:SetMass(1) -- Carry mass

			local linear, angular = phys2:GetDamping()
			self.SavedRotDamping[i] = angular
			phys2:SetDamping(linear, 10)
		end

		phys:SetMass(1.0)
		phys:EnableDrag(false)
	--end

	local attachmentPoint = ent:WorldToLocal(ent:WorldSpaceCenter())
	local targetAng = owner:WorldToLocalAngles(ent:GetAngles())

	self:SetNW2Angle("TargetAng", targetAng)
	self:SetNW2Vector("AttachmentPoint", attachmentPoint)
	self:SetNW2Entity("AttachedEnt", ent)
	self:SetNW2Bool("Holding", true)

	-- We call it once so it resets the positions.
	self:UpdateObject()

	return true

end

function SWEP:DetachObject()

	local ent = self:GetNW2Entity("AttachedEnt")

	DbgPrint(self, "DetachObject", ent)

	if self:GetNW2Bool("Holding") == false then
		return
	end

	if IsValid(ent) then
		--if SERVER then
			if self.ResetOwner == true then
				ent:SetOwner(nil)
			end

			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local phys = ent:GetPhysicsObjectNum(i)
				if not IsValid(phys) then
					continue
				end

				if self.SavedMass[i] ~= nil then
					phys:SetMass(self.SavedMass[i])
				end
				if self.SavedRotDamping[i] ~= nil then
					local linear,_ = phys:GetDamping()
					phys:SetDamping(linear, self.SavedRotDamping[i])
				end

				phys:EnableDrag(true)
				phys:SetVelocity(Vector(0, 0, 0))
				phys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)

			end
		--else

		if CLIENT then
			ent:PhysicsDestroy()
		end

		local motionController = self:GetMotionController()
		motionController:RemoveFromMotionController(ent:GetPhysicsObject())
	else
		DbgPrint("Invalid entity")
	end

	self.SavedMass = {}
	self.SavedRotDamping = {}

	self:SetNW2Bool("Holding", false)
	self:SetNW2Entity("AttachedEnt", nil)

end

function SWEP:DryFire()
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self:EmitSound("Weapon_PhysCannon.DryFire")
end

function SWEP:PrimaryFireEffect()

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	owner:ViewPunch( Angle(-6, util.SharedRandom("physcannonfire", -2, 2), 0) )

	if SERVER then
		--TODO: Screen fadein
	end

	self:EmitSound("Weapon_PhysCannon.Launch")

end

function SWEP:PuntNonVPhysics(ent, fwd, tr)

end

function SWEP:ApplyVelocityBasedForce(ent, fwd)
	if not SERVER then
		return
	end

	local phys = ent:GetPhysicsObject()

	local maxForce = physcannon_maxforce:GetFloat()
	local force = maxForce

	local mass = phys:GetMass()
	if mass > 100 then

	end

	local vVel = fwd * force
	--local aVel = tr.HitPos

	phys:AddVelocity(vVel)
	--phys:AddAngleVelocity(aVel * 1)
end

function SWEP:PuntVPhysics(ent, fwd, tr)

	local curTime = CurTime()

	if self.LastPuntedObject == ent and curTime < self.NextPuntTime then
		return
	end

	self.LastPuntedObject = ent
	self.NextPuntTime = curTime + 0.5

	if SERVER then

		local dmgInfo = DamageInfo()
		dmgInfo:SetAttacker(self.Owner)
		dmgInfo:SetInflictor(self)
		dmgInfo:SetDamage(0)
		dmgInfo:SetDamageType(DMG_PHYSGUN)
		ent:DispatchTraceAttack(dmgInfo, tr, fwd)

		if fwd.z < 0 then
			fwd.z = fwd.z * -0.65
		end

		-- 	Physgun_OnPhysGunPickup( pEntity, pOwner, PUNTED_BY_CANNON );
		local phys = ent:GetPhysicsObjectNum(0)
		if phys:HasGameFlag(FVPHYSICS_CONSTRAINT_STATIC) and ent:IsVehicle() then
			fwd.x = 0
			fwd.y = 0
			fwd.z = 0
		end

		if false then -- if ( !Pickup_ShouldPuntUseLaunchForces( pEntity, PHYSGUN_FORCE_PUNTED ) )

			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				phys = ent:GetPhysicsObjectNum(i)

				-- 	Physgun_OnPhysGunPickup( pEntity, pOwner, PUNTED_BY_CANNON );


			end

		else
			self:ApplyVelocityBasedForce(ent, fwd, tr)
		end
	end

	self:PrimaryFireEffect()
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

	self.ChangeState = ELEMENT_STATE_CLOSED
	self.ElementDebounce = CurTime() + 0.5
	self.CheckSuppressTime = CurTime() + 0.25

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

end

function SWEP:DoEffectNone(pos)

end

function SWEP:DoEffectClosed(pos)

end

function SWEP:DoEffectReady(pos)

end

function SWEP:DoEffectHolding(pos)

end

function SWEP:DoEffectLaunch(pos)

end

local EFFECT_TABLE =
{
	[EFFECT_NONE] = SWEP.DoEffectNone,
	[EFFECT_CLOSED] = SWEP.DoEffectClosed,
	[EFFECT_READY] = SWEP.DoEffectReady,
	[EFFECT_HOLDING] = SWEP.DoEffectHolding,
	[EFFECT_LAUNCH] = SWEP.DoEffectLaunch,
}

function SWEP:DoEffect(effect, pos)

	self.EffectState = effect

	if CLIENT then
		self.OldEffectState = self.EffectState
	end

	EFFECT_TABLE[effect](self, pos)

end

function SWEP:DrawWorldModel()

	self.Weapon:DrawModel()

end

function SWEP:DrawWorldModelTranslucent()

	self.Weapon:DrawModel()

end
