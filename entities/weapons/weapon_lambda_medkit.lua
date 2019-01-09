if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Medkit")

SWEP.PrintName = "Medkit"
SWEP.Author = "Lambda"
SWEP.Instructions = ""

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "lambda_health"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "physgun"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"

if CLIENT then
    SWEP.Slot = 0
    SWEP.SlotPos = 2
    SWEP.DrawAmmo = true
    SWEP.DrawCrosshair = true
    SWEP.DrawWeaponInfoBox = false
    SWEP.BounceWeaponIcon = false
    SWEP.RenderGroup = RENDERGROUP_OPAQUE
    SWEP.ViewModelFOV = 54
end

game.AddAmmoType( {
    name = "lambda_health",
    dmgtype = DMG_DIRECT,
    tracer = TRACER_NONE,
    plydmg = -10,
    npcdmg = -10,
    force = 0,
    minsplash = 0,
    maxsplash = 0,
} )

local TRACE_LEN = 52

local HEAL_AMOUNT = 10
local REVIVE_AMOUNT = 50

local STATE_IDLE = 0
local STATE_CHARGING = 1

--
-- ConVars

-- Missing convars.

--
-- Code
function SWEP:Precache()
end

function SWEP:SetupDataTables()
    DbgPrint(self, "SetupDataTables")

    self:NetworkVar("Float", 0, "NextHealTime")
    self:NetworkVar("Float", 1, "Energy")
    self:NetworkVar("Float", 2, "ChargeEnergy")
    self:NetworkVar("Int", 0, "State")
end

function SWEP:Initialize()
    DbgPrint(self, "Initialize")

    self:Precache()

    self.AmmoID = game.GetAmmoID(self.Primary.Ammo)

    if SERVER then
        self:SetEnergy(100)
    end

end

function SWEP:Think()
    local owner = self:GetOwner()
    if IsValid(owner) and owner:KeyDown(IN_ATTACK2) == false and self:GetState() ~= STATE_IDLE then
        self:StopCharging()
    end
end

-- Ugly hack, SWEP.Think is not what it seems.
function SWEP:PredictedThink()
    local owner = self:GetOwner()
    if not IsValid(owner) then
        return
    end

    local rechargeAmount = 1 * FrameTime()
    local energy = math.Clamp(self:GetEnergy() + rechargeAmount, 0, 100)
    self:SetEnergy(energy)
end

function SWEP:OnRemove()
    DbgPrint(self, "OnRemove")
end

function SWEP:GetActorForHealing()
    local owner = self:GetOwner()
    local startPos = owner:GetShootPos()
    local endPos = startPos + (owner:GetAimVector() * TRACE_LEN)
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SHOT,
        filter = owner,
    })
    if tr.Hit == true and IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then
        return tr.Entity
    end
    return nil
end

function SWEP:GetActorForReviving()

    local owner = self:GetOwner()
    local startPos = owner:GetShootPos()
    local endPos = startPos + (owner:GetAimVector() * TRACE_LEN)
    local things = ents.FindAlongRay( startPos, endPos, Vector(-1, -1, -1), Vector(1, 1, 1) )

    local ragdoll = nil
    local minDist = 9999999

    -- Because the ray doesn't stop we have to picked the closest.
    for _,v in pairs(things) do
        if v:IsRagdoll() and IsValid(v:GetOwner()) and v:GetOwner():IsPlayer() then
            local dist = v:GetPos():Distance(startPos)
            if dist < minDist then
                ragdoll = v
                minDist = dist
            end
        end
    end

    return ragdoll

end

function SWEP:CanPrimaryAttack()
    return true
end

function SWEP:CanHealActor(actor)
    if actor:Health() >= actor:GetMaxHealth() then
        return false
    end

    local healAmount = HEAL_AMOUNT
    if actor:Health() + healAmount > actor:GetMaxHealth() then
        healAmount = actor:GetMaxHealth() - actor:Health()
    end

    local energy = self:GetEnergy()
    if energy - healAmount < 0 then
        return false
    end
    return true
end

function SWEP:ConsumeEnergy(amount)

    local energy = self:GetEnergy()
    energy = math.Clamp(energy - amount, 0, 100)
    self:SetEnergy(energy)

end

function SWEP:DryFire()
    if CLIENT and IsFirstTimePredicted() == true then
        self:EmitSound("items/medshotno1.wav")
    end
end

function SWEP:PrimaryAttack()

    DbgPrint(self, "PrimaryAttack")

    if self:CanPrimaryAttack() == false then
        print("Cant attack")
        return
    end

    local actor = self:GetActorForHealing()

    if not IsValid(actor) or self:CanHealActor(actor) == false then
        self:SetNextPrimaryFire(CurTime() + 0.5)
        self:DryFire()
        return
    end

    local healAmount = HEAL_AMOUNT
    if actor:Health() + healAmount > actor:GetMaxHealth() then
        healAmount = actor:GetMaxHealth() - actor:Health()
    end

    actor:SetHealth(actor:Health() + healAmount)

    self:EmitSound("items/medshot4.wav")
    self:ConsumeEnergy(healAmount)

    self:SetNextPrimaryFire(CurTime() + 1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

function SWEP:CanSecondaryAttack()
    return true
end

local CHARGE_TIME = 2.0
local STEP_TIME = 0.1
local TOTAL_STEPS = CHARGE_TIME / STEP_TIME
local CHARGE_AMOUNT = REVIVE_AMOUNT / TOTAL_STEPS

function SWEP:CreateChargeSound()
    if self.SndCharge == nil or self.SndCharge == NULL then

        local filter
        if SERVER then
            filter = RecipientFilter()
            filter:AddAllPlayers()
        end
        self.SndCharge = CreateSound(self, "lambda/defibrillator_charge.wav", filter)

    end

    DbgPrint(self, "SND: " .. tostring(self.SndCharge))
    return self.SndCharge
end

function SWEP:EmitChargingSound()
    local snd = self:CreateChargeSound()
    if snd ~= nil and snd ~= NULL then
        if CLIENT then
            snd:Stop()
        end
        --snd:Play()
        snd:PlayEx(100, 50)
        snd:ChangePitch(100, 0.5)
        snd:ChangeVolume(0.8, 0.5)

        DbgPrint(self, "Playing sound")
    end
end

function SWEP:StopChargeSound()
    if self.SndCharge ~= nil and self.SndCharge ~= NULL then
        self.SndCharge:Stop()
    end
end

function SWEP:StartCharging()
    self:SetChargeEnergy(0.0)
    self:EmitChargingSound()
    self:SetState(STATE_CHARGING)
    self:SetNextSecondaryFire(CurTime() + STEP_TIME)
end

function SWEP:StopCharging()
    self:StopChargeSound()
    self:SetState(STATE_IDLE)
    self:SetChargeEnergy(0.0)
    self:SetNextSecondaryFire(CurTime() + 0.5)
end

function SWEP:UpdateCharging()
    local current = self:GetChargeEnergy()
    current = current + CHARGE_AMOUNT
    self:SetChargeEnergy(current)
    if current >= REVIVE_AMOUNT then
        return self:ReleaseCharge()
    end
    self:SetNextSecondaryFire(CurTime() + STEP_TIME)
end

function SWEP:ReleaseCharge()
    self:EmitSound("lambda/defibrillator_release.wav")
    self:SetState(STATE_IDLE)
    self:SetNextSecondaryFire(CurTime() + 1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:ConsumeEnergy(self:GetChargeEnergy())
    self:SetChargeEnergy(0.0)
    if SERVER then
        local ragdoll = self:GetActorForReviving()
        if IsValid(ragdoll) then
            local owner = ragdoll:GetOwner()
            if IsValid(owner) then
                owner:Revive(ragdoll:GetPos(), ragdoll:GetAngles(), 30)
            end
        end
    end
end

function SWEP:SecondaryAttack()

    if self:CanPrimaryAttack() == false then
        print("Cant secondary attack")
        return
    end

    local ragdoll = self:GetActorForReviving()
    if ragdoll == nil or self:GetEnergy() < REVIVE_AMOUNT then
        self:SetNextSecondaryFire(CurTime() + 0.5)
        self:DryFire()
        self:SetState(STATE_IDLE)
        return
    end

    local currentState = self:GetState()
    if currentState == STATE_IDLE then
        self:StartCharging()
    elseif currentState == STATE_CHARGING then
        self:UpdateCharging()
    end

end

function SWEP:Equip()
    DbgPrint("Equip")
end

function SWEP:Deploy()
    DbgPrint("Deploy")
    self:SendWeaponAnim(ACT_VM_DEPLOY)
    return true
end

function SWEP:Holster(ent)
    DbgPrint(self, "Holster")
    self:SendWeaponAnim(ACT_VM_HOLSTER)
    return true
end

function SWEP:DrawWorldModel()
    self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
    self:DrawModel()
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

function SWEP:ViewModelDrawn(vm)
end

function SWEP:Ammo1()
    local energy = math.Clamp(self:GetEnergy() - self:GetChargeEnergy(), 0, 100)
    return energy
end