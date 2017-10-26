-- WIP! Don't touch me
if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("physcannon")

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
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel = "models/weapons/w_Physics.mdl"

SWEP.WepSelectFont		= "WeaponIconsSelected"
SWEP.WepSelectLetter	= "m"
SWEP.IconFont			= "WeaponIconsSelected"
SWEP.IconLetter			= "m"

if CLIENT then
	SWEP.Slot = 0
	SWEP.SlotPos = 2
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
	SWEP.DrawWeaponInfoBox = false
	SWEP.BounceWeaponIcon = false
	SWEP.RenderGroup = RENDERGROUP_BOTH
	SWEP.EffectParameters = {}
	SWEP.ViewModelFOV = 54

	surface.CreateFont("LambdaPhyscannonFont",
	{
		font = "HalfLife2",
		size = util.ScreenScaleH(64),
		weight = 0,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		additive = true,
	})

	surface.CreateFont("LambdaPhyscannonFont2",
	{
		font = "HalfLife2",
		size = util.ScreenScaleH(64),
		weight = 0,
		blursize = util.ScreenScaleH(4),
		scanlines = 2,
		antialias = true,
		additive = true,
	})

end

--
-- ConVars
local physcannon_tracelength = GetConVar("physcannon_tracelength")
local physcannon_maxforce = GetConVar("physcannon_maxforce")
local physcannon_cone = GetConVar("physcannon_cone")
local physcannon_pullforce = GetConVar("physcannon_pullforce")
-- Missing convars.
local physcannon_dmg_class = CreateConVar("physcannon_dmg_class", "15", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Damage done to glass by punting")
local physcannon_mega_tracelength = CreateConVar("physcannon_mega_tracelength", "850", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED) );
local physcannon_mega_pullforce = CreateConVar("physcannon_mega_pullforce", "8000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED) );
local physcannon_ball_cone = CreateConVar("physcannon_ball_cone", "0.997", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED) );

local SPRITE_SCALE = 12

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
-- EffectType
local PHYSCANNON_CORE = 0
local PHYSCANNON_BLAST = 1
local PHYSCANNON_GLOW1 = 2
local PHYSCANNON_GLOW2 = 3
local PHYSCANNON_GLOW3 = 4
local PHYSCANNON_GLOW4 = 5
local PHYSCANNON_GLOW5 = 6
local PHYSCANNON_GLOW6 = 7
local PHYSCANNON_ENDCAP1 = 8
local PHYSCANNON_ENDCAP2 = 9
local PHYSCANNON_ENDCAP3 = 10
local PHYSCANNON_CORE_2 = 11

local EFFECT_PARAM_NAME =
{
	[PHYSCANNON_CORE] = "PHYSCANNON_CORE",
	[PHYSCANNON_BLAST] = "PHYSCANNON_BLAST",
	[PHYSCANNON_GLOW1] = "PHYSCANNON_GLOW1",
	[PHYSCANNON_GLOW2] = "PHYSCANNON_GLOW2 ",
	[PHYSCANNON_GLOW3] = "PHYSCANNON_GLOW3",
	[PHYSCANNON_GLOW4] = "PHYSCANNON_GLOW4",
	[PHYSCANNON_GLOW5] = "PHYSCANNON_GLOW5",
	[PHYSCANNON_GLOW6] = "PHYSCANNON_GLOW6",
	[PHYSCANNON_ENDCAP1] = "PHYSCANNON_ENDCAP1",
	[PHYSCANNON_ENDCAP2] = "PHYSCANNON_ENDCAP2",
	[PHYSCANNON_ENDCAP3] = "PHYSCANNON_ENDCAP3",
	[PHYSCANNON_CORE_2] = "PHYSCANNON_CORE_2",
}

local PHYSCANNON_ENDCAP_SPRITE = "sprites/physcannon_glow1.vmt"
local PHYSCANNON_GLOW_SPRITE = "sprites/physcannon_glow1.vmt"
local PHYSCANNON_CENTER_GLOW = "sprites/physcannon_core"
local PHYSCANNON_BLAST_SPRITE = "sprites/physcannon_blast"
local PHYSCANNON_CORE_WARP = "particle/warp1_warp"

local MAT_PHYSBEAM = Material("sprites/physbeam.vmt")
local MAT_WORLDMDL = Material("models/weapons/w_physics/w_physics_sheet2")
--
-- Code
function SWEP:Precache()
	util.PrecacheSound("Weapon_PhysCannon.HoldSound")
end

function SWEP:SetupDataTables()
	DbgPrint(self, "SetupDataTables")

	self:NetworkVar("Int", 0, "EffectState")
	self:NetworkVar("Bool", 0, "ElementOpen")
	self:NetworkVar("Bool", 1, "MegaEnabled")
	self:NetworkVar("Float", 0, "ElementDestination")
	self:NetworkVar("Entity", 0, "MotionController")

end

function SWEP:Initialize()
	DbgPrint(self, "Initialize")

	self:Precache()

	self.CalcViewModelView = nil
	self.GetViewModelPosition = nil

	self.LastPuntedObject = nil
	self.NextPuntTime = CurTime()

	self.OldEffectState = EFFECT_NONE
	self.GlowSprites = {}
	self.BeamSprites = {}

	--self:SetElementOpen(true)
	--self:SetElementDestination(1)

	self.ElementOpen = nil
	self.OldOpen = false
	self.UpdateName = true
	self.NextIdleTime = CurTime()
	self.EffectsSetup = false
	self.ObjectAttached = false

	if CLIENT then
		self.CurrentElementLen = 0
		self.TargetElementLen = 0
		self.UsingViewModel = self:ShouldDrawUsingViewModel()
	end

	self.ChangeState = ELEMENT_STATE_NONE

	self.ElementDebounce = CurTime()
	self.CheckSuppressTime = CurTime()
	self.ObjectShadowParams = {}
	self.DebounceSecondary = false
	self:SetWeaponHoldType(self.HoldType)
	self.ElementPosition = InterpValue(0.0, 0.0, 0)
	self.LastElementDestination = 0

	if SERVER then
		if game.GetGlobalState("super_phys_gun") == GLOBAL_ON then
			self:SetMegaEnabled(true)
		else
			self:SetMegaEnabled(false)
		end
	end

	if SERVER then
		local motionController = ents.Create("lambda_motioncontroller")
		motionController:Spawn()
		--self:SetNW2Entity("MotionController", motionController)
		self:SetMotionController(motionController)
	end

	if CLIENT then
		self:StartEffects()
		self:UpdateEffects()
	end
	self:DoEffect(EFFECT_CLOSED)
	self:CloseElements()
	self:SetElementDestination(0)

	self:SetSkin(1)

end

function SWEP:WeaponSound(snd)

	DbgPrint(self, "WeaponSound", snd)

	local ent = self

	if CLIENT then
		ent = self:GetOwner()
		if IsValid(ent) == false then
			ent = self
		end
	else
		self:EmitSound(snd)
	end

	self:EmitSound(snd)

end

function SWEP:GetMotorSound()

	DbgPrint(self, "GetMotorSound")

	if self.SndMotor == nil or self.SndMotor == NULL then

		local filter
		if SERVER then
			filter = RecipientFilter()
			filter:AddAllPlayers()
		end
		self.SndMotor = CreateSound(self, "Weapon_PhysCannon.HoldSound", filter)

	end

	DbgPrint(self, "SND: " .. tostring(self.SndMotor))
	return self.SndMotor

end

function SWEP:StopLoopingSounds()
	if self.SndMotor ~= nil and self.SndMotor ~= NULL then
		self.SndMotor:Stop()
	end
end

function SWEP:IsObjectAttached()

	local controller = self:GetMotionController()
	if IsValid(controller) == false then
		return false
	end
	if controller.IsObjectAttached == nil then
		return false
	end
	return controller:IsObjectAttached()

end

function SWEP:OnRemove()
	DbgPrint(self, "OnRemove")
	self:StopEffects()
	self:StopLoopingSounds()
	self:DetachObject()
	if SERVER then
		local motionController = self:GetMotionController()
		if IsValid(motionController) then
			motionController:Remove()
		end
	end
end

function SWEP:IsMegaPhysCannon()
	return self:GetMegaEnabled(false)
end

function SWEP:Supercharge()

	game.SetGlobalState("super_phys_gun", GLOBAL_ON)

	self:SetSequence( self:SelectWeightedSequence( ACT_PHYSCANNON_UPGRADE ) )
	self:ResetSequenceInfo()
	self:UseTriggerBounds(true, 32.0)

	for _,v in pairs(ents.FindByName("script_physcannon_upgrade")) do
		v:Input("Trigger", self, self)
	end

	-- Allow pickup again.
	self:AddSolidFlags( FSOLID_TRIGGER );
	self:OpenElements()

end

function SWEP:AcceptInput(inputName, activator, callee, data)
	if inputName:iequals("Supercharge") then
		self:Supercharge()
		return true
	end
	return false
end

--[[
function SWEP:GetMotionController()
	return self:GetNW2Entity("MotionController")
end
]]

function SWEP:LaunchObject(ent, fwd, force)

	if self.LastPuntedObject == ent and CurTime() < self.NextPuntTime then
		return
	end

	self:DetachObject(true)

	self.LastPuntedObject = ent
	self.NextPuntTime = CurTime() + 0.5

	self:ApplyVelocityBasedForce(ent, fwd)

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

	self.ElementDebounce = CurTime() + 0.1
	self.CheckSuppressTime = CurTime() + 0.25
	self.ChangeState = ELEMENT_STATE_CLOSED

	self:DoEffect(EFFECT_LAUNCH, ent:WorldSpaceCenter())

	local snd = self:GetMotorSound()
	if snd ~= nil and snd ~= NULL then
		snd:ChangeVolume(0, 1.0)
		snd:ChangePitch(50, 1.0)
	end

end

function SWEP:PrimaryAttack()

	DbgPrint(self, "PrimaryAttack")

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	self:SetNextPrimaryFire(CurTime() + 0.5)

	local controller = self:GetMotionController()

	if controller:IsObjectAttached() then
		local ent = controller:GetAttachedObject()

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

	if tr.Fraction == 1 or not IsValid(ent) or ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then
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
		if tr.Fraction == 1 or not IsValid(ent) or ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then
			-- Nothing valid.
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

		if SERVER and self:IsMegaPhysCannon() == true and ent:IsNPC() and ent:IsEFlagSet(EFL_NO_MEGAPHYSCANNON_RAGDOLL) == false and ent:CanBecomeRagdoll() == true then

			local dmgInfo = DamageInfo()
			dmgInfo:SetInflictor(owner)
			dmgInfo:SetAttacker(owner)
			dmgInfo:SetDamage(1)
			dmgInfo:SetDamageType(DMG_GENERIC)

			local ragdoll = ent:CreateServerRagdoll(dmgInfo, COLLISION_GROUP_INTERACTIVE_DEBRIS)
			local phys = ragdoll:GetPhysicsObject()
			if IsValid(phys) then
				phys:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
			end
			ragdoll:SetCollisionBounds(ent:OBBMins(), ent:OBBMaxs())
			ragdoll:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) -- Its ugly if players collide
			ragdoll.IsPhysgunDamage = true

			dmgInfo = DamageInfo()
			dmgInfo:SetInflictor(owner)
			dmgInfo:SetAttacker(owner)
			dmgInfo:SetDamage(10000)
			dmgInfo:SetDamageType(bit.bor(DMG_PHYSGUN, DMG_REMOVENORAGDOLL))
			ent:TakeDamageInfo(dmgInfo)

			self:PuntRagdoll(ragdoll, fwd, tr)

		end

		DbgPrint("Punt: " .. tostring(ent))
		return self:PuntNonVPhysics(ent, fwd, tr)
	end

	if self:IsMegaPhysCannon() == false then
		if ent:IsVPhysicsFlesh() then
			return self:DryFire()
		end
	else
		if ent:IsRagdoll() then
			-- TODO: Replace with punt ragdoll.
			return self:PuntRagdoll(ent, fwd, tr)
		end
	end

	if ent:IsWeapon() == true then
		return self:DryFire()
	end

	if owner:InVehicle() == true then
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

	if CLIENT then
		return
	end

	if self:CanSecondaryAttack() == false then
		return
	end

	if SERVER then
		SuppressHostEvents(NULL)
	end

	--DbgPrint(self, "SecondaryAttack")
	local controller = self:GetMotionController()
	--print(controller, controller:IsObjectAttached())

	if controller:IsObjectAttached() == true --[[ self:GetNW2Bool("Holding") == true ]] then

		self:SetNextPrimaryFire(CurTime() + 0.5)
		self:SetNextSecondaryFire(CurTime() + 0.5)
		self.Secondary.Automatic = true

		self:DetachObject(false)

		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

		return true

	else
		if CLIENT then
			return
		end

		local res = self:FindObject()

		if res == OBJECT_FOUND then
			self.Secondary.Automatic = false -- No longer automatic, debounce.
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
			self:WeaponSound("Weapon_PhysCannon.Pickup")
			self:SetNextSecondaryFire(CurTime() + 0.5)
			self:SetNextPrimaryFire(CurTime() + 0.5)
		elseif res == OBJECT_NOT_FOUND then
			self:SetNextSecondaryFire(CurTime() + 0.1)
			self.Secondary.Automatic = true
			self:CloseElements()
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
		if dist >= nearestDist or los:Dot(fwd) < coneSize then
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

function SWEP:FindObjectInConeMega(start, fwd, coneSize, ballCone, onlyCombineBalls)

	local maxDist = self:TraceLength() + 1.0
	local nearestDist = maxDist
	local nearestIsCombineBall = false
	if onlyCombineBalls == true then
		nearestIsCombineBall = true
	end

	local mins = start - Vector(nearestDist, nearestDist, nearestDist)
	local maxs = start + Vector(nearestDist, nearestDist, nearestDist)
	local nearest

	for _,v in pairs(ents.FindInBox(mins, maxs)) do
		if not IsValid(v:GetPhysicsObject()) then
			continue
		end

		local isBall = v:GetClass() == "prop_combine_ball"
		if not isBall and nearestIsCombineBall == true then
			continue
		end

		local los = v:WorldSpaceCenter() - start
		local dist = los:Length()
		los:Normalize()
		local dotProduct = los:Dot(fwd)

		if not isBall or nearestIsCombineBall then
			if dist >= nearestDist or dotProduct <= coneSize then
				continue
			end
		else
			if dist >= maxDist or dotProduct <= coneSize then
				continue
			end
			if dist > nearestDist and dotProduct < ballCone then
				continue
			end
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
			nearestIsCombineBall = isBall
		end
	end

	return nearest
end


local SF_PHYSPROP_ENABLE_ON_PHYSCANNON = 0x000040
local SF_PHYSBOX_ENABLE_ON_PHYSCANNON = 0x20000
local ALLOWED_PICKUP_CLASS =
{
	["bounce_bomb"] = true,
	["combine_bouncemine"] = true,
	["combine_mine"] = true,
}

function SWEP:CanPickupObject(ent, massLimit, sizeLimit)

	if not IsValid(ent) then
		return false
	end

	massLimit = massLimit or 0
	sizeLimit = sizeLimit or 0
	-- TODO: Disolving check
	if ent:IsPlayer() then
		return false
	end

	if ent:IsNPC() == true and IsFriendEntityName(ent:GetClass()) == true then
		return false
	end

	if ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then
		return false
	end

	if ent:HasSpawnFlags(SF_PHYSBOX_NEVER_PICK_UP) == true then
		return false
	end

	local owner = self:GetOwner()
	if IsValid(owner) and owner:GetGroundEntity() == ent then
		return false
	end

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) and phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) == true then
		return false
	end

	-- Hooks
	local pickupAllowed = hook.Call("GravGunPickupAllowed", GAMEMODE, owner, ent)
	if pickupAllowed == false then
		return false
	end

	if ent:IsVehicle() then
		return false
	end

	if self:IsMegaPhysCannon() == false then

		if ent:IsVPhysicsFlesh() == true then
			return false
		end

		if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
			return false
		end

		-- NOTE: This is from CBasePlayer::CanPickupObject
		do

			local physCount = ent:GetPhysicsObjectCount()
			if physCount == 0 then
				return false -- Must have physics.
			end

			local checkEnable = false
			local objectMass = 0

			for i = 0, physCount - 1 do
				local subphys = ent:GetPhysicsObjectNum(i)
				if not IsValid(subphys) then
					continue
				end
				if subphys:IsMoveable() == false then
					checkEnable = true
				end
				if subphys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP) == True then
					return false
				end
				objectMass = objectMass + subphys:GetMass()
				-- TODO: if subphys:IsHinged() == true then return false end
			end

			if massLimit > 0 and objectMass > massLimit then
				return false
			end

			if checkEnable == true then
				-- Allow things that have no motion but can be picked up.
				local class = ent:GetClass()
				if ALLOWED_PICKUP_CLASS[class] == true then
					return true
				end
				-- NOTE: We should be careful here, other objects may occupy those flags for other things, we should add a class check.
				-- The sdk checks against CPhysicsProp and CPhysBox
				if ent:HasSpawnFlags(SF_PHYSPROP_ENABLE_ON_PHYSCANNON) == false and ent:HasSpawnFlags(SF_PHYSBOX_ENABLE_ON_PHYSCANNON) == false then
					return false
				end
			end

		end

	else

		if ent:GetMoveType() ~= MOVETYPE_VPHYSICS and ent:GetMoveType() ~= MOVETYPE_STEP then
			return false
		end

	end

	return true

end

function SWEP:TraceLength()

	if self:IsMegaPhysCannon() then
		return physcannon_mega_tracelength:GetFloat()
	end

	return physcannon_tracelength:GetFloat()

end

function SWEP:FindObjectTrace(owner)

	local fwd = owner:GetAimVector()
	local start = owner:GetShootPos()
	local testLength = self:TraceLength() * 4.0
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

	return tr

end

function SWEP:GetPullForce()
	if self:IsMegaPhysCannon() then
		return physcannon_mega_pullforce:GetFloat()
	end
	return physcannon_pullforce:GetFloat()
end

function SWEP:FindObject()

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	local tr = self:FindObjectTrace(owner)

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

	local fwd = owner:GetAimVector()
	local start = owner:GetShootPos()
	local testLength = physcannon_tracelength:GetFloat() * 4.0

	local coneEnt
	if self:IsMegaPhysCannon() == false then
		if attach == false and pull == false then
			coneEnt = self:FindObjectInCone(start, fwd, physcannon_cone:GetFloat())
		end
	else
		coneEnt = self:FindObjectInConeMega(start, fwd, physcannon_cone:GetFloat(), physcannon_ball_cone:GetFloat(), attach or pull)
	end

	if IsValid(coneEnt) then
		ent = coneEnt

		if ent:WorldSpaceCenter():DistToSqr(start) <= (testLength * testLength) then
			attach = true
		else
			pull = true
		end
	end

	if self:CanPickupObject(ent) == false then
		if self.LastDenySoundPlayed ~= true then
			self:WeaponSound("Weapon_PhysCannon.TooHeavy")
			self.LastDenySoundPlayed = true
		end
		return OBJECT_NOT_FOUND
	end

	if ent:GetNW2Int("m_nPhysgunState", 0) == 1 then
		return OBJECT_FOUND
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
	pullDir = pullDir:GetNormal() * self:GetPullForce()

	local mass = ent:GetPhysMass()
	if mass < 50 then
		pullDir = pullDir * ((mass + 0.5) * (1 / 50.0))
	end

	phys:ApplyForceCenter(pullDir)
	return OBJECT_NOT_FOUND

end

function SWEP:UpdateObject()

	local owner = self.Owner

	if not IsValid(owner) then
		return false
	end

	local controller = self:GetMotionController()

	if controller:IsObjectAttached() == false then
		return
	end

	local err = controller:ComputeError()
	--DbgPrint(err)
	if err >= 12 then
		return false
	end

	local attachedObject = controller:GetAttachedObject()

	if owner:GetGroundEntity() == attachedObject then
		return false
	end

	local fwd = owner:GetAimVector()
	fwd.x = math.Clamp(fwd.x, -75, 75)

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

	local finalPos = endPos - attachmentPoint
	controller:SetTargetTransform(finalPos, ang)

	return true

end

function SWEP:OpenElements()

	--DbgPrint(self, "OpenElements")

	local owner = self:GetOwner()
	if self.ElementOpen == true or owner == nil then
		return
	end

	if SERVER then
		SuppressHostEvents(NULL)
	end
	self:WeaponSound("Weapon_PhysCannon.OpenClaws")

	--self.ElementDestination = 1
	--self:SetNW2Float("ElementDestination", 1)
	self:SetElementDestination(1)
	self.ElementOpen = true

	if self:IsMegaPhysCannon() == true then
		self:SendWeaponAnim(ACT_VM_IDLE)
	end

	self:DoEffect(EFFECT_READY)

end

function SWEP:CloseElements()

	--DbgPrint(self, "CloseElements")

	local owner = self:GetOwner()
	if owner == nil then
		return
	end

	if self.ElementOpen ~= true then
		return
	end

	-- Never close on mega
	if self:IsMegaPhysCannon() == true then
		return
	end

	local snd = self:GetMotorSound()
	if snd ~= nil and snd ~= NULL then
		snd:ChangeVolume(0, 1.0)
		snd:ChangePitch(50, 1.0)
	end

	if SERVER then
		SuppressHostEvents(NULL)
	end
	self:WeaponSound("Weapon_PhysCannon.CloseClaws")

	--self:SetNW2Float("ElementDestination", 0)
	self:SetElementDestination(0)
	self.ElementOpen = false

	if self:IsMegaPhysCannon() == true then
		self:SendWeaponAnim(ACT_VM_IDLE)
	end

	self:DoEffect(EFFECT_CLOSED)

end

function SWEP:Equip()
    -- body
	self:CloseElements()
	self:StartEffects()
	self.ShouldDrawGlow = true
	self:CloseElements()

	if self:IsMegaPhysCannon() == true then
		self:OpenElements()
	end
end

function SWEP:Deploy()

	DbgPrint("Deploy")

	self:CloseElements()
	self:StartEffects()
	self.ShouldDrawGlow = true
	self:CloseElements()

	if self:IsMegaPhysCannon() == true then
		self:OpenElements()
	end

	return true

end

function SWEP:WeaponIdle()

	if CurTime() < self.NextIdleTime then
		return
	end

	self.NextIdleTime = CurTime() + 0.2

	local owner = self:GetOwner()
	if owner == nil or owner == NULL then
		return
	end

	if owner:GetActiveWeapon() ~= self then
		return
	end
	self.LastDenySoundPlayed = false

	--DbgPrint(self, self:GetOwner(), "WeaponIdle")
	local controller = self:GetMotionController()

	if self:IsMegaPhysCannon() == true then
		self:SetElementDestination(1)
	end

	if controller:IsObjectAttached() == true then
		self:SendWeaponAnim(ACT_VM_RELOAD)
	else
		if self:IsMegaPhysCannon() == true then
			self:SendWeaponAnim(ACT_VM_RELOAD)
		else
			self:SendWeaponAnim(ACT_VM_IDLE)
		end
		self:DoEffect(EFFECT_READY)
	end

end

function SWEP:UpdateElementPosition()

	local dest = self:GetElementDestination()
	if dest ~= self.LastElementDestination then
		self.LastElementDestination = dest
		self.ElementPosition:InitFromCurrent(dest, 0.2)
	end

	local elemPos = self.ElementPosition:Interp(CurTime())
	if self:ShouldDrawUsingViewModel() == true then
		local owner = self:GetOwner()
		if owner == nil then
			--DbgPrint("No owner")
			return
		end

		local vm = owner:GetViewModel()
		if vm ~= nil then
			vm:SetPoseParameter("active", elemPos)
		end
	else
		if self:IsMegaPhysCannon() == true then
			elemPos = 1
		end
		self:SetPoseParameter("active", elemPos)
		if CLIENT then
			self:InvalidateBoneCache()
		end
	end

end

function SWEP:CheckForTarget()

	if self.CheckSuppressTime > CurTime() then
		return
	end

	if self:IsEffectActive(EF_NODRAW) then
		return
	end

	local owner = self:GetOwner()
	if owner == nil then
		return
	end

	local controller = self:GetMotionController()
	if controller:IsObjectAttached() then
		return
	end

	local tr = self:FindObjectTrace(owner)

	if tr.Fraction ~= 1.0 and IsValid(tr.Entity) then

		local dist = (tr.StartPos - tr.HitPos):Length()
		if dist <= self:TraceLength() and self:CanPickupObject(tr.Entity) then
			self.ChangeState = ELEMENT_STATE_NONE
			self:OpenElements()
			return
		end

	end

	if self.ElementDebounce < CurTime() and self.ChangeState == ELEMENT_STATE_NONE then
		self.ChangeState = ELEMENT_STATE_CLOSED
		self.ElementDebounce = CurTime() + 0.5
	end

end

function SWEP:UpdateGlow()

	-- Expiremental
	do
		return
	end

end

function SWEP:Think()

	if SERVER then
		self:NextThink(0)
	else
		self:SetNextClientThink(0)
	end

	if SERVER then
		if game.GetGlobalState("super_phys_gun") == GLOBAL_ON then
			self:SetMegaEnabled(true)
		else
			self:SetMegaEnabled(false)
		end
	end

	local controller = self:GetMotionController()

	if CLIENT then
		-- Only predict for local player.
		local ply = LocalPlayer()
		if IsValid(ply) and ply:GetObserverMode() == OBS_MODE_NONE and ply == self:GetOwner() then
			controller:ManagePredictedObject()
		end

		local effectState = self:GetEffectState(EFFECT_READY)

		if effectState ~= self.OldEffectState then
			self:DoEffect(effectState)
		end

		self:UpdateElementPosition()
		self:StartEffects()
		self:UpdateEffects()
		self:UpdateGlow()
	end

	if controller:IsObjectAttached() == true and self:UpdateObject() == false then
		self:DetachObject()
		return
	elseif controller:IsObjectAttached() == false and self.ObjectAttached == true then
		self:DetachObject()
		return
	end

	local owner = self:GetOwner()
	if not IsValid(owner) then
		return true
	end

	-- In mega its always open, no need for traces.
	if self:IsMegaPhysCannon() == false and controller:IsObjectAttached() == false then
		self:CheckForTarget()

		if self.ElementDebounce < CurTime() and self.ChangeState ~= ELEMENT_STATE_NONE then
			if self.ChangeState == ELEMENT_STATE_OPEN then
				self:OpenElements()
			elseif self.ChangeState == ELEMENT_STATE_CLOSED then
				self:CloseElements()
			end
			self.ChangeState = ELEMENT_STATE_NONE
		end
	end

	if owner:KeyDown(IN_ATTACK2) == false and self:IsObjectAttached() == false then
		self:WeaponIdle()
	end

	return true

end

function SWEP:AttachObject(ent, tr)

	DbgPrint(self, "AttachObject", ent)

	local owner = self.Owner
	if not IsValid(owner) then
		return
	end

	local useGrabPos = false
	local grabPos = tr.HitPos
	local attachmentPoint = ent:OBBCenter() -- ent:WorldToLocal(ent:OBBCenter())

	if self:IsMegaPhysCannon() == true  and
		ent:IsNPC() and
		ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == false and
		ent:IsEFlagSet(EFL_NO_MEGAPHYSCANNON_RAGDOLL) == false and
		ent:CanBecomeRagdoll() == true and
		ent:GetMoveType() == MOVETYPE_STEP then

		local dmgInfo = DamageInfo()
		dmgInfo:SetInflictor(owner)
		dmgInfo:SetAttacker(owner)
		dmgInfo:SetDamage(1)
		dmgInfo:SetDamageType(DMG_GENERIC)

		local ragdoll = ent:CreateServerRagdoll(dmgInfo, COLLISION_GROUP_INTERACTIVE_DEBRIS)
		local phys = ragdoll:GetPhysicsObject()
		if IsValid(phys) then
			phys:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
		end
		ragdoll:SetCollisionBounds(ent:OBBMins(), ent:OBBMaxs())
		ragdoll:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) -- Its ugly if players collide
		ragdoll.IsPhysgunDamage = true

		--attachmentPoint = Vector(0, 0, 0)
		dmgInfo = DamageInfo()
		dmgInfo:SetInflictor(owner)
		dmgInfo:SetAttacker(owner)
		dmgInfo:SetDamage(10000)
		dmgInfo:SetDamageType(bit.bor(DMG_PHYSGUN, DMG_REMOVENORAGDOLL))

		ent:TakeDamageInfo(dmgInfo)

		ent = ragdoll
		useGrabPos = false

	end

	if ent:IsRagdoll() then
		attachmentPoint = Vector(0, 0, -16)
	end

	local motionController = self:GetMotionController()
	motionController:AttachObject(ent, grabPos, useGrabPos)
	self.ObjectAttached = true

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then
		DbgPrint("Physics invalid!")
		return
	end

	phys:AddGameFlag(FVPHYSICS_PLAYER_HELD)

	if SERVER then
		owner:SimulateGravGunPickup(ent, false)
	end

	--if SERVER then
	if not IsValid(ent:GetOwner()) then
		ent:SetOwner(owner)
		self.ResetOwner = true
	end
	--end

	if SERVER then
		local targetAng = nil

		local preferredCarryAng = owner:GetPreferredCarryAngles(ent)
		if preferredCarryAng ~= nil and targetAng == nil then
			targetAng = preferredCarryAng
		end

		if targetAng == nil then
			targetAng = ent:GetAngles()
		end

		targetAng = owner:WorldToLocalAngles(targetAng)

		self:SetNW2Angle("TargetAng", targetAng)
		self:SetNW2Vector("AttachmentPoint", attachmentPoint)

		ent:PhysicsImpactSound()
	end

	-- We call it once so it resets the positions.
	if self:UpdateObject() == false then
		self:DetachObject()
		return false
	end

	self:DoEffect(EFFECT_HOLDING)
	self:OpenElements()

	local snd = self:GetMotorSound()
	if snd ~= nil and snd ~= NULL then
		if CLIENT then
			snd:Stop()
		end
		--snd:Play()
		snd:PlayEx(100, 50)
		snd:ChangePitch(100, 0.5)
		snd:ChangeVolume(0.8, 0.5)

		--(CSoundEnvelopeController::GetController()).Play( GetMotorSound(), 0.0f, 50 );
--(CSoundEnvelopeController::GetController()).SoundChangePitch( GetMotorSound(), 100, 0.5f );
--(CSoundEnvelopeController::GetController()).SoundChangeVolume( GetMotorSound(), 0.8f, 0.5f );
		DbgPrint(self, "Playing sound")
	end

	return true

end

function SWEP:DetachObject(launched)

	--assert(false)

	local owner = self:GetOwner()
	if owner == nil or owner == NULL then
		DbgPrint("No owner")
		return
	end

	DbgPrint(self, "DetachObject")

	if self.ObjectAttached == true then
		self:WeaponSound("Weapon_PhysCannon.Drop")
		self.ObjectAttached = false
	end

	local snd = self:GetMotorSound()
	if snd ~= nil and snd ~= NULL then
		snd:ChangeVolume(0, 1.0)
		snd:ChangePitch(50, 1.0)
	end

	local controller = self:GetMotionController()
	if not IsValid(controller) then
		DbgPrint(self, "No valid controller")
		return
	end

	if controller:IsObjectAttached() == false then
		DbgPrint(self, "No object attached")
		return
	end

	local ent = controller:GetAttachedObject()
	if not IsValid(ent) then
		DbgPrint(self, "Invalid attached object")
		return
	end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then
		DbgPrint("No physics object")
		return
	end

	phys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)

	if self.ResetOwner == true then
		ent:SetOwner(nil)
	end

	if SERVER then
		owner:SimulateGravGunDrop(ent, launched)
	end

	local motionController = self:GetMotionController()
	motionController:DetachObject()

	if self:IsMegaPhysCannon() == false then
		self:SendWeaponAnim(ACT_VM_DRYFIRE)
	end

	self:DoEffect(EFFECT_READY)

	if launched ~= true and ent:GetClass() == "prop_combine_ball" and IsValid(phys) then
		-- If we just release it then it will be simply stuck mid air.
		phys:Wake()
		phys:SetVelocity( (owner:GetAimVector() + (VectorRand() * 0.8)) * 4000)
	end

end

function SWEP:DryFire()

	local owner = self:GetOwner()
	owner:SetAnimation(PLAYER_ATTACK1)

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

	DbgPrint("PuntNonVPhysics")

	if hook.Call("GravGunPunt", GAMEMODE, self:GetOwner(), ent) == false then
		return
	end

	if ent:IsNPC() == true and IsFriendEntityName(ent:GetClass()) == true then
		return
	end

	if SERVER then

		local dmgAmount = 1.0
		if ent:GetClass() == "func_breakable" and ent:GetMaterialType() == MAT_GLASS then
			dmgAmount = physcannon_dmg_class:GetFloat()
		end

		local dmgInfo = DamageInfo()
		dmgInfo:SetAttacker(self:GetOwner())
		dmgInfo:SetInflictor(self)
		dmgInfo:SetDamage(dmgAmount)
		dmgInfo:SetDamageType(bit.bor(DMG_CRUSH, DMG_PHYSGUN))
		dmgInfo:SetDamageForce(fwd)
		dmgInfo:SetDamagePosition(tr.HitPos)

		ent:DispatchTraceAttack(dmgInfo, tr, fwd)
		self:DoEffect(EFFECT_LAUNCH, tr.HitPos)

	end

	self:PrimaryFireEffect()
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

	self.ElementDebounce = CurTime() + 0.5
	self.CheckSuppressTime = CurTime() + 0.25
	self.ChangeState = ELEMENT_STATE_CLOSED

end

function SWEP:ApplyVelocityBasedForce(ent, fwd)
	if not SERVER then
		return
	end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then
		return
	end

	local maxForce = physcannon_maxforce:GetFloat()
	local force = maxForce

	local mass = phys:GetMass()
	if mass > 100 then

	end

	local vVel = fwd * force
	--local aVel = tr.HitPos

	if ent:IsRagdoll() then
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys2 = ent:GetPhysicsObjectNum(i)
			if not IsValid(phys2) then
				continue -- Yes this can actually happen
			end
			phys2:AddVelocity(vVel)
		end
	else
		phys:AddVelocity(vVel)
	end

	--phys:AddAngleVelocity(aVel * 1)
end

function SWEP:PuntVPhysics(ent, fwd, tr)

	local curTime = CurTime()
	local owner = self:GetOwner()

	if self.LastPuntedObject == ent and curTime < self.NextPuntTime then
		return
	end

	if self:IsMegaPhysCannon() == false and ent:IsVPhysicsFlesh() == true then
		return
	end

	DbgPrint("PuntVPhysics")

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

		-- 	TODO: Physgun_OnPhysGunPickup( pEntity, pOwner, PUNTED_BY_CANNON );
		owner:SimulateGravGunPickup(ent, true)

		local phys = ent:GetPhysicsObjectNum(0)
		if not IsValid(phys) then
			return
		 end

		if phys:HasGameFlag(FVPHYSICS_CONSTRAINT_STATIC) and ent:IsVehicle() then
			fwd.x = 0
			fwd.y = 0
			fwd.z = 0
		end

		if self:IsMegaPhysCannon() == false then -- if ( !Pickup_ShouldPuntUseLaunchForces( pEntity, PHYSGUN_FORCE_PUNTED ) )

			local totalMass = 0
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local subphys = ent:GetPhysicsObjectNum(i)
				totalMass = totalMass + subphys:GetMass()
			end

			local maxMass = 250
			local actualMass = math.min(totalMass, maxMass)
			local mainPhys = ent:GetPhysicsObject()

			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local subphys = ent:GetPhysicsObjectNum(i)
				local ratio = phys:GetMass() / totalMass
				if subphys == mainPhys then
					ratio = ratio + 0.5
					ratio = math.min(ratio, 1.0)
				else
					ratio = ratio * 0.5
				end
				subphys:ApplyForceCenter(fwd * 15000 * ratio)
				subphys:ApplyForceOffset(fwd * actualMass * 600 * ratio, tr.HitPos)
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

	self:DoEffect(EFFECT_LAUNCH, tr.HitPos)

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

end

function SWEP:PuntRagdoll(ent, fwd, tr)

	local curTime = CurTime()
	local owner = self:GetOwner()

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

		-- 	TODO: Physgun_OnPhysGunPickup( pEntity, pOwner, PUNTED_BY_CANNON );
		owner:SimulateGravGunPickup(ent, true)

		local vel = fwd * 1500

		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys = ent:GetPhysicsObject()
			phys:AddVelocity(vel)
		end

	end

	self:PrimaryFireEffect()
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

	self.ChangeState = ELEMENT_STATE_CLOSED
	self.ElementDebounce = CurTime() + 0.5
	self.CheckSuppressTime = CurTime() + 0.25

	self:DoEffect(EFFECT_LAUNCH, tr.HitPos)

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

end

function SWEP:DoEffectNone(pos)

	if SERVER then
		return
	end

	DbgPrint("DoEffectNone")

	self.EffectParameters[PHYSCANNON_CORE].Visible = false
	self.EffectParameters[PHYSCANNON_BLAST].Visible = false

	for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
		self.EffectParameters[i].Visible = false
	end

	for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
		local data = self.EffectParameters[i]
		if data == nil then continue end
		data.Visible = false

		local beamdata = self.BeamParameters[i]
		beamdata.Visible = true
		beamdata.Scale:InitFromCurrent(0.0, 0.1)
	end

	local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
	core2.Scale:InitFromCurrent(14.0, 0.1)
	core2.Alpha:InitFromCurrent(255, 0.2)

end

function SWEP:DoEffectClosed(pos)
	if SERVER then
		return
	end

	DbgPrint("DoEffectClosed")

	for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
		local data = self.EffectParameters[i]
		if data == nil then continue end
		data.Visible = false

		local beamdata = self.BeamParameters[i]
		beamdata.Visible = true
		beamdata.Scale:InitFromCurrent(0.0, 0.1)
	end

	local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
	core2.Scale:InitFromCurrent(14.0, 0.1)
	core2.Alpha:InitFromCurrent(64, 0.2)

end

function SWEP:DoEffectReady(pos)

	if SERVER then
		return
	end

	DbgPrint("DoEffectReady")

	local core = self.EffectParameters[PHYSCANNON_CORE]

	if self:ShouldDrawUsingViewModel() == true then
		core.Scale:InitFromCurrent(20.0, 0.2)
	else
		core.Scale:InitFromCurrent(12.0, 0.2)
	end

	core.Alpha:InitFromCurrent(128.0, 0.2)
	core.Visible = true

	self.EffectParameters[PHYSCANNON_CORE_2].Scale:InitFromCurrent(0.0, 0.2)

	for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
		local data = self.EffectParameters[i]
		data.Scale:InitFromCurrent(0.4 * SPRITE_SCALE, 0.2)
		data.Alpha:InitFromCurrent(64.0, 0.2)
		data.Visible = true
	end

	for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
		local data = self.EffectParameters[i]
		if data ~= nil then
			data.Visible = self:IsMegaPhysCannon()
		end
		local beamdata = self.BeamParameters[i]
		if beamdata ~= nil then
			beamdata.Visible = true
			beamdata.Scale:InitFromCurrent(0.0, 0.1)
		end
	end

	local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
	core2.Scale:InitFromCurrent(5.0, 0.1)
	core2.Alpha:InitFromCurrent(255, 0.2)

end

function SWEP:DoEffectHolding(pos)

	if SERVER then
		return
	end

	DbgPrint("DoEffectHolding")

	if self:ShouldDrawUsingViewModel() == true then

		local core = self.EffectParameters[PHYSCANNON_CORE]
		core.Scale:InitFromCurrent(20.0, 0.2)
		core.Alpha:InitFromCurrent(255.0, 0.1)

		local blast = self.EffectParameters[PHYSCANNON_BLAST]
		blast.Visible = false

		for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
			local data = self.EffectParameters[i]
			data.Scale:InitFromCurrent(0.5 * SPRITE_SCALE, 0.2)
			data.Alpha:InitFromCurrent(64.0, 0.2)
			data.Visible = true
		end

		for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
			local data = self.EffectParameters[i]
			if data ~= nil then
				data.Visible = true
			end

			local beamdata = self.BeamParameters[i]
			if beamdata ~= nil then
				beamdata.Lifetime = -1
				beamdata.Scale:InitFromCurrent(0.5, 0.1)
			end
		end

	else

		local core = self.EffectParameters[PHYSCANNON_CORE]
		core.Scale:InitFromCurrent(16.0, 0.2)
		core.Alpha:InitFromCurrent(255.0, 0.1)

		local blast = self.EffectParameters[PHYSCANNON_BLAST]
		blast.Visible = false

		for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
			local data = self.EffectParameters[i]
			data.Scale:InitFromCurrent(0.5 * SPRITE_SCALE, 0.2)
			data.Alpha:InitFromCurrent(64.0, 0.2)
			data.Visible = true
		end

		for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
			local data = self.EffectParameters[i]
			if data == nil then continue end
			data.Visible = true

			local beamdata = self.BeamParameters[i]
			if beamdata ~= nil then
				beamdata.Scale:InitFromCurrent(0.6, 0.1)
				beamdata.Lifetime = -1
			end
		end

	end

	local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
	core2.Scale:InitFromCurrent(18.0, 0.1)
	core2.Alpha:InitFromCurrent(220, 0.2)
end

function SWEP:DoEffectLaunch(pos)

	DbgPrint("DoEffectLaunch")

	local owner = self:GetOwner()
	local endPos
	local shotDir

	local controller = self:GetMotionController()
	local attachedEnt = controller:GetAttachedObject()

	if pos == nil then
		if attachedEnt ~= nil then
			endPos = attachedEnt:WorldSpaceCenter()
			shotDir = endPos - owner:GetShootPos()
		else
			endPos = owner:GetShootPos()
			shotDir = owner:GetAimVector()

			local tr = util.TraceLine({
				start = endPos,
				endpos = endPos + (shotDir * 1900),
				mask = MASK_SHOT,
				filter = owner,
			})

			endPos = tr.HitPos
			shotDir = endPos - owner:GetShootPos()
		end
	else
		endPos = pos
		shotDir = endPos - owner:GetShootPos()
	end

	shotDir:Normalize()

	local ef = EffectData()
	ef:SetOrigin(endPos)
	ef:SetEntity(self)

	if CLIENT and IsFirstTimePredicted() then
		util.Effect("PhyscannonImpact", ef)
	elseif SERVER then
		util.Effect("PhyscannonImpact", ef)
	end

	if CLIENT then
		local blast = self.EffectParameters[PHYSCANNON_BLAST]
		blast.Scale:Init(8.0, 64, 0.1)
		blast.Alpha:Init(255, 0, 0.2)
		blast.Visible = true
	end

end

local EFFECT_NAME =
{
	[EFFECT_NONE] = "EFFECT_NONE",
	[EFFECT_CLOSED] = "EFFECT_CLOSED",
	[EFFECT_READY] = "EFFECT_READY",
	[EFFECT_HOLDING] = "EFFECT_HOLDING",
	[EFFECT_LAUNCH] = "EFFECT_LAUNCH",
}

local EFFECT_TABLE =
{
	[EFFECT_NONE] = SWEP.DoEffectNone,
	[EFFECT_CLOSED] = SWEP.DoEffectClosed,
	[EFFECT_READY] = SWEP.DoEffectReady,
	[EFFECT_HOLDING] = SWEP.DoEffectHolding,
	[EFFECT_LAUNCH] = SWEP.DoEffectLaunch,
}

function SWEP:DoEffect(effect, pos)

	if self.CurrentEffect == effect then
		return
	end

	self:StartEffects()

	if CLIENT then
		self.OldEffectState = effect
	end

	self.CurrentEffect = effect
	if SERVER then
		--self:SetNW2Int("EffectState2", effect)
		self:SetEffectState(effect)
	end
	DbgPrint("Assigned Current Effect: " .. (EFFECT_NAME[effect] or "Unknown!") .. " (" .. effect .. ")")

	EFFECT_TABLE[effect](self, pos)

end

function SWEP:DrawWorldModel()

	local effectState = self:GetEffectState(EFFECT_READY)

	if effectState ~= self.OldEffectState then
		self:DoEffect(effectState)
	end

	self:UpdateElementPosition()
	self:StartEffects()
	self:UpdateEffects()
	self:UpdateGlow()

	self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
	self:DrawModel()
	self:DrawEffects()
end

function SWEP:Holster(ent)
	DbgPrint(self, "Holster")

	if not IsFirstTimePredicted() then
		return
	end

	local controller = self:GetMotionController()
	if controller:IsObjectAttached() == true then
		return false
	end

	self:StopLoopingSounds()
	self:StopEffects()
	self:DetachObject()
	self.ShouldDrawGlow = false

	return true
end

function SWEP:FormatViewModelAttachment(pos, inverse)

	local origin = EyePos()
	local fov = LocalPlayer():GetFOV()
	local worldx = math.tan( fov * math.pi / 360.0 )
	local viewx = math.tan( self.ViewModelFOV * math.pi / 360.0 )
	local factorX = worldx / viewx
	local factorY = factorX

	local ang = EyeAngles()
	local right = ang:Right()
	local up = ang:Up()
	local fwd = ang:Forward()

	local tmp = pos - origin
	local transformed = Vector( right:Dot(tmp), up:Dot(tmp), fwd:Dot(tmp) )

	if inverse then
		if factorX ~= 0 and factorY ~= 0 then
			transformed.x = transformed.x / factorX
			transformed.y = transformed.y / factorX
		else
			transformed.x = 0
			transformed.y = 0
		end
	else
		transformed.x = transformed.x * factorX
		transformed.y = transformed.y * factorX
	end

	local res = origin + (right * transformed.x) + (up * transformed.y) + (fwd * transformed.z)
	return res

end

function SWEP:ShouldDrawUsingViewModel()
	if SERVER then
		return false
	end
	return self:IsCarriedByLocalPlayer() and LocalPlayer():ShouldDrawLocalPlayer() == false
end

function SWEP:DrawEffectType(id)

	local data = self.EffectParameters[id]
	if data == nil then
		return
	end

	if data.Visible == false then
		return
	end

	local curTime = CurTime()
	local scale = data.Scale:Interp(curTime)

	local alpha = data.Alpha:Interp(curTime)
	if alpha < 0 then
		return
	end

	local mat = data.Mat
	local attachmentId = data.Attachment
	local owner = self:GetOwner()
	local pos = self:GetPos()
	local color = data.Col

	if self:ShouldDrawUsingViewModel() == true then
		if owner ~= nil then
			local vm = owner:GetViewModel()
			local attachmentData = vm:GetAttachment(attachmentId)
			if attachmentData == nil then
				return
			end
			pos = self:FormatViewModelAttachment(attachmentData.Pos, true)
		end
	else
		local attachmentData = self:GetAttachment(attachmentId)
		if attachmentData == nil then
			--print("Missing attachment: " .. attachmentId)
			return
		end
		pos = attachmentData.Pos
	end

	render.SetMaterial(mat)
	if self:ShouldDrawUsingViewModel() == false then
		--scale = scale * 5
	end

	local colorScale = 0.7
	if self:IsMegaPhysCannon() then
		colorScale = 1
	end

	--DbgPrint(pos, scale, scale, data.Col)
	local newColor = Color(color.r * colorScale, color.g * colorScale, color.b * colorScale, alpha)

	render.DrawSprite(pos, scale, scale, newColor)

	---debugoverlay.Box(pos, Vector(-0.5,-0.5,-0.5),Vector(0.5, 0.5, 0.5),0.05,Color(255, 0, 0))

end

function SWEP:DrawBeam(startPos, endPos, width, color)

	color = color or Color(255, 255, 255, 255)

	local delta = endPos - startPos
	local len = delta:Length()
	local texcoord = util.RandomFloat(0, 1)

	render.SetMaterial(MAT_PHYSBEAM)
	render.DrawBeam( startPos,
					 endPos,
					width,
					texcoord,
					texcoord + (len / 32),
					color )

end

function SWEP:DrawCoreBeams()
	local corePos
	local owner = self:GetOwner()

	if self:ShouldDrawUsingViewModel() == true then
		if owner ~= nil then
			local vm = owner:GetViewModel()
			local attachmentData = vm:GetAttachment(1)
			if attachmentData == nil then
				return
			end
			corePos = self:FormatViewModelAttachment(attachmentData.Pos, true)
		end
		maxEndCap = PHYSCANNON_ENDCAP2
	else
		local attachmentData = self:GetAttachment(1)
		if attachmentData == nil then
			--print("Missing attachment: " .. attachmentId)
			return
		end
		corePos = attachmentData.Pos
	end

	local colorScale = 0.6
	if self:IsMegaPhysCannon() == true then
		colorScale = 1
	end

	local wepColor = self:GetWeaponColor() * colorScale
	local color = Color(wepColor.x * 255, wepColor.y * 255, wepColor.z * 255, 255)

	for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do

		local beamdata = self.BeamParameters[i]
		if beamdata == nil then
			continue
		end

		if beamdata.Lifetime ~= nil and beamdata.Lifetime ~= -1 then
			if beamdata.Lifetime <= 0 then
				continue
			end
			beamdata.Lifetime = beamdata.Lifetime - FrameTime()
		end

		local endPos
		local params = self.EffectParameters[i]
		if params == nil then continue end

		local attachmentData = self:GetAttachment(params.Attachment)
		if attachmentData == nil then
			continue
		end

		if self:ShouldDrawUsingViewModel() == true then
			if owner ~= nil then
				local vm = owner:GetViewModel()
				attachmentData = vm:GetAttachment(params.Attachment)
				if attachmentData == nil then
					return
				end
				endPos = self:FormatViewModelAttachment(attachmentData.Pos, true)
			end
		else
			attachmentData = self:GetAttachment(params.Attachment)
			if attachmentData == nil then
				return
			end
			endPos = attachmentData.Pos
		end

		local width = (5 + util.RandomFloat(0, 5)) * beamdata.Scale:Interp(CurTime())
		self:DrawBeam(endPos, corePos, width, color)

	end

end

function SWEP:DrawEffects()

	self:DrawCoreBeams()

	for k,v in pairs(self.EffectParameters) do
		self:DrawEffectType(k)
	end

end

local ATTACHMENTS_GAPS_FP =
{
	"fork1t",
	"fork2t",
}

local ATTACHMENTS_GAPS_TP =
{
	"fork1t",
	"fork2t",
	"fork3t",
}

local ATTACHMENTS_GLOW_FP =
{
	"fork1b",
	"fork1m",
	"fork1t",
	"fork2b",
	"fork2m",
	"fork2t"
}

local ATTACHMENTS_GLOW_TP =
{
	"fork1m",
	"fork1t",
	"fork1b",
	"fork2m",
	"fork2t",
	"fork3m",
	"fork3t",
}

function SWEP:SetupEffects(viewModel)

	local effects = {}
	local beams = {}

	local init = false

	-- Core
	do
		local data = {
			Scale = InterpValue(0.0, 1.0, 0.1),
			Alpha = InterpValue(255, 255, 0.1),
			Attachment = 1,
			Mat = Material(PHYSCANNON_CENTER_GLOW),
			Visible = false,
			Col = Color(255, 255, 255),
		}
		effects[PHYSCANNON_CORE] = data
		init = true
	end

	-- Blast
	do
		local data = {
			Scale = InterpValue(0.0, 1.0, 0.1),
			Alpha = InterpValue(255, 255, 0.1),
			Attachment = 1,
			Mat = Material(PHYSCANNON_BLAST_SPRITE),
			Visible = false,
			Col = Color(255, 255, 255),
		}
		effects[PHYSCANNON_BLAST] = data
		init = true
	end

	-- Glow sprites
	local n = 1
	for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
		local data = {
			Scale = InterpValue(0.05 * SPRITE_SCALE, 0.05 * SPRITE_SCALE, 0.0),
			Alpha = InterpValue(64, 64, 0),
			Mat = Material(PHYSCANNON_GLOW_SPRITE),
			Visible = true,
			Col = Color(255, 128, 0),
		}

		local attachmentName
		if viewModel == true then
			attachmentName = ATTACHMENTS_GLOW_FP[n]
		else
			attachmentName = ATTACHMENTS_GLOW_TP[n]
		end

		data.Attachment = self:LookupAttachment(attachmentName)

		if data.Attachment == 0 then
			DbgPrint("Missing attachment: " .. tostring(attachmentName))
		end

		effects[i] = data
		n = n + 1
		init = true
	end

	if viewModel == true then
		attachmentGaps = ATTACHMENTS_GAPS_FP
	else
		attachmentGaps = ATTACHMENTS_GAPS_TP
	end

	-- Endcap Sprites
	n = 1
	for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do

		local beamdata = {
			Scale = InterpValue(0.00, 0.1, 0.01),
			Alpha = InterpValue(255, 255, 0),
			Visible = false,
			Col = Color(255, 128, 0, 255),
			Lifetime = -1,
		}
		beams[i] = beamdata

		local attachmentName = attachmentGaps[n]
		if attachmentName == nil then
			continue
		end

		local data = {
			Scale = InterpValue(0.05 * SPRITE_SCALE, 0.05 * SPRITE_SCALE, 0.0),
			Alpha = InterpValue(255, 255, 0),
			Attachment = self:LookupAttachment(attachmentName),
			Visible = false,
			Mat = Material(PHYSCANNON_ENDCAP_SPRITE),
			Col = Color(255, 128, 0, 255),
		}

		effects[i] = data

		n = n + 1
		init = true

	end

	do
		local data = {
			Scale = InterpValue(0.0, 0.0, 0.1),
			Alpha = InterpValue(255, 255, 0.1),
			Attachment = 1,
			Mat = Material(PHYSCANNON_CORE_WARP),
			Visible = true,
			Col = Color(255, 0, 0),
		}
		effects[PHYSCANNON_CORE_2] = data
		init = true
	end

	if init == true then
		for k, v in pairs(effects) do
			v.Name = EFFECT_PARAM_NAME[k]
		end
	end

	return effects, beams

end

function SWEP:StartEffects()

	--DbgPrint("StartEffects")

	if SERVER then
		return
	end

	-- In case we swap from first to third person, this will recreate all data.
	local viewChanged = false
	local effect = self.CurrentEffect

	local usingViewModel = self:ShouldDrawUsingViewModel()
	if self.LastUsingViewModel ~= usingViewModel then
		local effects, beams = self:SetupEffects(self:ShouldDrawUsingViewModel())
		self.EffectParameters = effects
		self.BeamParameters = beams
		self.LastUsingViewModel = usingViewModel
	end

	if effect ~= nil then
		self:DoEffect(effect)
	end


end

function SWEP:StopEffects(stopSound)

	self:DoEffect(EFFECT_NONE)

	if SERVER then
		if stopSound == nil then
			stopSound = true
		end

		local snd = self:GetMotorSound()
		if stopSound == true and snd ~= nil and snd ~= NULL then
			snd:ChangeVolume(0, 1.0)
			snd:ChangePitch(50, 1.0)
		end
	end

end

function SWEP:GetWeaponColor()

	local owner = self:GetOwner()
	local wepColor = Vector(1, 1, 1)

	if IsValid(owner) then
		wepColor = owner:GetWeaponColor()
	else
		local f = .3
		local i = math.sin(CurTime()) * 32
		local r = math.sin(f * i + 0 * math.pi / 3) * 127 + 128
		local g = math.sin(f * i + 2 * math.pi / 3) * 127 + 128
		local b = math.sin(f * i + 4 * math.pi / 3) * 127 + 128

		wepColor.x = r / 255
		wepColor.y = g / 255
		wepColor.z = b / 255
	end

	return wepColor
end

function SWEP:UpdateEffects()

	self:StartEffects()

	local owner = self:GetOwner()

	local colorMax = 128
	if self:IsMegaPhysCannon() then
		colorMax = 255
	end

	local wepColor = self:GetWeaponColor()
	if not IsValid(owner) then
		-- Manually change it we are right before a draw call.
		MAT_WORLDMDL:SetVector("$selfillumtint", wepColor)
	end

	local r = wepColor.x * colorMax
	local g = wepColor.y * colorMax
	local b = wepColor.z * colorMax
	-- Update the 3 endpoints to rotate color

	for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
		local data = self.EffectParameters[i]
		data.Scale:SetAbsolute( util.RandomFloat(0.075, 0.05) * 160 )
		data.Alpha:SetAbsolute( util.RandomFloat(25, 32)  )
	end

	for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
		local data = self.EffectParameters[i]
		if data == nil then continue end
		data.Scale:SetAbsolute( util.RandomFloat(3, 5) )
		data.Alpha:SetAbsolute( util.RandomFloat(200, 255)  )
	end

	for i,data in pairs(self.EffectParameters) do
		data.Col = Color(r, g, b)
	end

	if CLIENT and self:IsMegaPhysCannon() == true then

		local endCapMax = PHYSCANNON_ENDCAP3
		if self:ShouldDrawUsingViewModel() == true then
			endCapMax = PHYSCANNON_ENDCAP2
		end

		local i = math.random(PHYSCANNON_ENDCAP1, endCapMax)
		local beamdata = self.BeamParameters[i]

		if self:IsObjectAttached() == false and math.random(0, 100) == 0 then
			self:EmitSound( "Weapon_MegaPhysCannon.ChargeZap" );
			beamdata.Scale:InitFromCurrent(0.5, 0.1)
			beamdata.Lifetime = 0.05 + (math.random() * 0.1)
		end

	end

end

function SWEP:ViewModelDrawn(vm)
	self:DrawEffects()
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )

	surface.SetTextColor( 255, 220, 0, alpha )

	surface.SetFont( "LambdaPhyscannonFont" )
	local w, h = surface.GetTextSize( "m" )

	surface.SetTextPos( x + ( wide / 2 ) - ( w / 2 ),
						y + ( tall / 2 ) - ( h / 2 ) )

	surface.SetFont( "LambdaPhyscannonFont2" )
	surface.DrawText( "m" )

	surface.SetTextPos( x + ( wide / 2 ) - ( w / 2 ),
						y + ( tall / 2 ) - ( h / 2 ) )

	surface.SetFont( "LambdaPhyscannonFont" )
	surface.DrawText( "m" )

end
