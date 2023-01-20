include("hud_numeric.lua")
local PANEL = {}

function PANEL:Init()
    self:SetSize(util.ScreenScaleH(103), util.ScreenScaleH(37))
    self:SetLabelText(Localize("#Valve_Hud_SUIT"))
    self.LastArmor = 0
    self.AnimateValueChanged = Derma_Anim("HealthIncreased", self, self.AnimValueChanged)
    self.Animations = {self.AnimateValueChanged}
end

function PANEL:AnimValueChanged(anim, delta, data)
    self.Blur = (1 - delta) * 3
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

    local armor = ply:Armor()
    if armor == self.LastArmor then return end
    self.LastArmor = armor

    if armor >= 20 then
        self.AnimateValueChanged:Start(2)
    end

    self:SetDisplayValue(armor)
end

vgui.Register("HudArmor", PANEL, "HudNumeric")