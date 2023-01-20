include("hud_health.lua")
include("hud_armor.lua")
include("hud_ammo.lua")
include("hud_aux.lua")
local PANEL = {}

function PANEL:Init()
    self:ParentToHUD()
    self:SetSize(ScrW(), ScrH())
    local posX = 35
    local w, h
    self.HUDHealth = vgui.Create("HudHealth", self)
    w, h = self.HUDHealth:GetSize()
    self.HUDHealth:SetPos(posX, ScrH() - h - util.ScreenScaleH(10))
    self.HUDAux = vgui.Create("HudAux", self)
    local _, h2 = self.HUDAux:GetSize()
    self.HUDAux:SetPos(posX, ScrH() - h - util.ScreenScaleH(10) - h2 - util.ScreenScaleH(5))
    posX = posX + w + util.ScreenScaleW(10)
    self.HUDArmor = vgui.Create("HudArmor", self)
    self.HUDArmor:SetPos(posX, ScrH() - h - util.ScreenScaleH(10))
    self.HUDAmmo = vgui.Create("HudAmmo", self)
    w, h = self.HUDAmmo:GetSize()
    self.HUDAmmo:SetPos(ScrW() - w - util.ScreenScaleH(35), ScrH() - h - util.ScreenScaleH(10))
end

function PANEL:Think()
end

vgui.Register("HudSuit", PANEL, "Panel")