if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Hands")

SWEP.PrintName = "Hands"
SWEP.Author = "Lambda"
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

SWEP.HoldType = "normal"
SWEP.Weight = -1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/weapons/c_arms.mdl"

if CLIENT then
    SWEP.Slot = 0
    SWEP.SlotPos = 0
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = false
    SWEP.DrawWeaponInfoBox = false
    SWEP.BounceWeaponIcon = false
    SWEP.RenderGroup = RENDERGROUP_OPAQUE
    SWEP.ViewModelFOV = 54
end

local HANDSSTATE_IDLE = 0
local HANDSSTATE_FIGHT = 1

--
-- Code
function SWEP:Precache()
end

function SWEP:SetupDataTables()
    DbgPrint(self, "SetupDataTables")

    self:NetworkVar("Int", 0, "HandsState")
    self:NetworkVar("Float", 0, "NextReload")
end

function SWEP:Initialize()
    DbgPrint(self, "Initialize")

    self:Precache()
    self:SetHoldType(self.HoldType)
end

function SWEP:Think()
end

function SWEP:OnRemove()
    DbgPrint(self, "OnRemove")
end

function SWEP:ChangeSequence(seq)
    local owner = self:GetOwner()
    if not IsValid(owner) then
        return
    end

    local vm = owner:GetViewModel()
    vm:SendViewModelMatchingSequence(seq)
end

function SWEP:DoImpactEffect(tr, dmgInfo)

    if tr.HitSky then
        return
    end

    DbgPrint(tr.MatType)

    local impactEffect = "Impact"
    local impactSnd = "Flesh.ImpactHard"

    if tr.MatType == MAT_FLESH then
        impactEffect = "BloodImpact"
        impactSnd = "Flesh.ImpactHard"
    elseif tr.MatType == MAT_CONCRETE then
        impactEffect = "Impact"
        impactSnd = "Concrete.ImpactSoft"
    elseif tr.MatType == MAT_METAL then
        impactEffect = "Impact"
        impactSnd = "Bounce.Metal"
    elseif tr.MatType == MAT_WOOD then
        impactEffect = "Impact"
        impactSnd = "Wood.ImpactSoft"
    elseif tr.MatType == MAT_TILE then
        impactEffect = "Impact"
        impactSnd = "Concrete.ImpactSoft"
    elseif tr.MatType == MAT_DIRT then
        impactEffect = "Impact"
        impactSnd = "Dirt.Impact"
    elseif tr.MatType == MAT_GLASS then
        impactEffect = "Impact"
        impactSnd = "Glass.ImpactSoft"
    elseif tr.MatType == MAT_PLASTIC then
        impactEffect = "Impact"
        impactSnd = "Plastic_Box.ImpactSoft"
    elseif tr.MatType == MAT_GRASS then
        impactEffect = nil
        impactSnd = "Dirt.Impact"
    elseif tr.MatType == MAT_GRATE then
        impactEffect = nil
        impactSnd = "ChainLink.ImpactSoft"
    elseif tr.MatType == MAT_VENT then
        impactEffect = nil
        impactSnd = "MetalVent.ImpactHard"
    end

    if impactEffect ~= nil then
        local effectdata = EffectData()
        effectdata:SetOrigin( tr.HitPos + tr.HitNormal )
        effectdata:SetNormal( tr.HitNormal )
        util.Effect( impactEffect, effectdata )
    end
    
    local ent = self:GetOwner()
    if IsValid(tr.Entity) then
        ent = tr.Entity
    end
    if SERVER then
        ent:EmitSound(impactSnd)
    end

    if CLIENT and tr.MatType == MAT_FLESH then
        local decal = util.DecalMaterial("Blood")
        util.DecalEx(Material(decal), ent, tr.HitPos, tr.HitNormal, Color(255, 255, 255), 0.5, 0.5)
    end

end

function SWEP:SwingAttack()

    local owner = self:GetOwner()
    local startPos = owner:GetShootPos()
    local endPos = startPos + (owner:GetAimVector() * 60)
    local dir = (endPos - startPos):GetNormalized()

    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8),
        mask = MASK_SHOT_HULL,
        filter = owner,
    })

    if tr.Hit == false then
        self:EmitSound("Weapon_Crowbar.Single")
    else
        local ent = tr.Entity

        local tr2 = util.TraceLine({
            start = startPos,
            endpos = endPos,
            mask = MASK_SHOT_HULL,
            filter = owner,
        })

        if IsValid(ent) then
            
            if SERVER then
                local dmgInfo = DamageInfo()
                dmgInfo:SetDamage(5)
                dmgInfo:SetMaxDamage(5)
                dmgInfo:SetDamageType(DMG_DIRECT)
                dmgInfo:SetAttacker(owner)
                dmgInfo:SetInflictor(owner)
                dmgInfo:SetDamageForce(dir * 1500)
                dmgInfo:SetDamagePosition(tr2.HitPos)
                if ent:Health() - dmgInfo:GetDamage() <= 0 then
                    -- Only this call will ever create gibs/break crates properly.
                    ent:DispatchTraceAttack(dmgInfo, tr2)
                else
                    ent:TakeDamageInfo(dmgInfo)
                end
            end

        end

        self:DoImpactEffect(tr, dmgInfo)

    end

    local viewPunch = Angle(0, 0, 0)
    viewPunch.x = util.SharedRandom("HandsSwingX", 1.0, 2.0, 0)
    viewPunch.y = util.SharedRandom("HandsSwingX", -2.0, -1.0, 1)

    owner:ViewPunch(viewPunch)

end

function SWEP:CanPrimaryAttack()
    local state = self:GetHandsState()
    if state ~= HANDSSTATE_FIGHT then
        DbgPrint("State", state)
        return false
    end
    return true
end

function SWEP:PrimaryAttack()

    DbgPrint(self, "PrimaryAttack")

    if self:CanPrimaryAttack() == false then
        return
    end

    self:ChangeSequence(4)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
    self:SwingAttack()

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    
    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)

end

function SWEP:CanSecondaryAttack()
    local state = self:GetHandsState()
    if state ~= HANDSSTATE_FIGHT then
        DbgPrint("State", state)
        return false
    end
    return true
end

function SWEP:SecondaryAttack()

    if self:CanSecondaryAttack() == false then
        return
    end

    self:ChangeSequence(3)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
    self:SwingAttack()

    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    
    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)

end

function SWEP:Equip()
    DbgPrint("Equip")
end

function SWEP:SwitchState(newState, deploy)
    if newState == HANDSSTATE_FIGHT then
        self:SetHandsState(HANDSSTATE_FIGHT)
        self:ChangeSequence(2)
        self:SetHoldType("fist")
    elseif newState == HANDSSTATE_IDLE then
        self:SetHandsState(HANDSSTATE_IDLE)
        if deploy == true then
            self:ChangeSequence(0)
        else
            self:ChangeSequence(1)
        end
        self:SetHoldType("normal")
    end
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
end

function SWEP:Deploy()
    DbgPrint("Deploy")
    self:SwitchState(self:GetHandsState(), true)
    return true
end

function SWEP:Holster(ent)
    DbgPrint(self, "Holster")
    if IsFirstTimePredicted() then
        self:ChangeSequence(0)
    end
    return true
end

function SWEP:Reload()

    if CurTime() < self:GetNextReload() then
        return
    end

    local curState = self:GetHandsState()
    if curState == HANDSSTATE_IDLE then
        self:SwitchState(HANDSSTATE_FIGHT)
    elseif self:GetHandsState() == HANDSSTATE_FIGHT then
        self:SwitchState(HANDSSTATE_IDLE)
    end

    DbgPrint("New State: " .. self:GetHandsState())
    self:SetNextReload(CurTime() + 0.5)

end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end

function SWEP:Ammo1()
    return 0
end

function SWEP:Ammo2()
    return 0
end

function SWEP:ShouldDropOnDie()
    return false
end