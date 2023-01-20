include("hud_numeric.lua")
local PANEL = {}

function PANEL:Init()
    self:SetShouldDisplaySecondaryValue(false)
    self:SetSize(util.ScreenScaleH(80), util.ScreenScaleH(37))
    self:SetLabelText(Localize("#Valve_Hud_AMMO_ALT"))
    self.LastClip1 = 0
    self.LastClip2 = 0
    self.LerpValues = false
    self.AnimateValueChanged = Derma_Anim("AmmoChanged", self, self.AnimValueChanged)
    self.Animations = {self.AnimateValueChanged}
end

function PANEL:Reset()
    self.LastClip1 = 0
    self.LastClip2 = 0
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
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    for _, v in pairs(self.Animations) do
        if v:Active() then
            v:Run()
        end
    end

    local altAmmo = 0

    if wep.Ammo2 ~= nil and isfunction(wep.Ammo2) then
        altAmmo = wep:Ammo2()
    else
        altAmmo = ply:GetAmmoCount(wep:GetSecondaryAmmoType())
    end

    if altAmmo ~= self.LastClip1 then
        self.AnimateValueChanged:Start(2)
        self.LastClip1 = altAmmo
    end

    self:SetDisplayValue(altAmmo)
end

vgui.Register("HudSecondaryAmmo", PANEL, "HudNumeric")