include("hud_numeric.lua")
local PANEL = {}

function PANEL:Init()
    self:SetShouldDisplaySecondaryValue(true)
    self:SetSize(util.ScreenScaleH(103), util.ScreenScaleH(37))
    self:SetLabelText(Localize("#Valve_Hud_AMMO"))
    self.LastClip1 = 0
    self.LastClip2 = 0
    self.LerpValues = false
    self.AnimateValueChanged = Derma_Anim("AmmoChanged", self, self.AnimValueChanged)
    self.Animations = {self.AnimateValueChanged}
end

function PANEL:Reset()
    self.LastClip1 = -1
    self.LastClip2 = 0
end

function PANEL:ShowAmmoCount(state)
    self:SetShouldDisplaySecondaryValue(state)

    if state == false then
        self:SetSize(util.ScreenScaleH(103), util.ScreenScaleH(37))
    else
        self:SetSize(util.ScreenScaleH(130), util.ScreenScaleH(37))
    end
end

function PANEL:AnimValueChanged(anim, delta, data)
    self.Blur = (1 - delta) * 3
    --self:SetBackgroundColor(0, 0, 0, 128)
    --self:SetTextColor(255, 208, 64, 255)
end

function PANEL:StopAnimations()
    for _, v in pairs(self.Animations) do
        v:Stop()
    end
end

function PANEL:Think()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, v in pairs(self.Animations) do
        if v:Active() then
            v:Run()
        end
    end

    local vehicle = ply:GetVehicle()
    local clip1
    local ammo = 0
    local ammotype = -1

    if vehicle ~= nil and IsValid(vehicle) and vehicle:GetNWBool("IsPassengerSeat", false) == false then
        if vehicle.GetAmmo ~= nil then
            ammotype, clip1, num = vehicle:GetAmmo()
        end

        if clip1 ~= self.LastClip1 then
            self.AnimateValueChanged:Start(2)
            self.LastClip1 = clip1
        end

        self:SetDisplayValue(num)
        self:SetShouldDisplaySecondaryValue(false)
        self:SetSecondaryValue(0)
    else
        local wep = ply:GetActiveWeapon()
        if wep ~= nil and not IsValid(wep) then return end

        if wep.Ammo1 ~= nil and isfunction(wep.Ammo1) then
            ammo = wep:Ammo1()
        else
            ammotype = wep:GetPrimaryAmmoType()
            ammo = ply:GetAmmoCount(ammotype)
        end

        clip1 = wep:Clip1()

        if clip1 == -1 then
            if wep.Ammo1 ~= nil and isfunction(wep.Ammo1) then
                clip1 = wep:Ammo1()
            else
                clip1 = ply:GetAmmoCount(ammotype)
            end
        end

        if clip1 ~= self.LastClip1 then
            self.AnimateValueChanged:Start(2)
            self.LastClip1 = clip1
        end

        self:SetDisplayValue(clip1)
        self:SetSecondaryValue(ammo)
    end
end

vgui.Register("HudPrimaryAmmo", PANEL, "HudNumeric")