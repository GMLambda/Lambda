include("hud_primary_ammo.lua")
include("hud_secondary_ammo.lua")

local PANEL = {}

function PANEL:Init()

	self:SetSize(util.ScreenScaleH(143), util.ScreenScaleH(37))

	self.AnimateValueChanged = Derma_Anim("AmmoIncreased", self, self.AnimValueChanged)
	self.AnimateShowAlt = Derma_Anim("AmmoShowAlt", self, self.AnimShowAlt)

	self.Animations =
	{
		self.AnimateValueChanged,
		self.AnimateShowAlt,
	}

	self.HUDPrimary = vgui.Create("HudPrimaryAmmo", self)
	self.HUDSecondary = vgui.Create("HudSecondaryAmmo", self)
	self.LastAltCount = 0
	self.LastClipVal = 0
	self.InitialThink = true
	self.LastWeapon = nil
	self.LastPrimaryAmmo = -1

end

function PANEL:AnimValueChanged(anim, delta, data)
	self.Blur = (1 - delta) * 3
end

function PANEL:AnimShowAlt(anim, delta, data)

	local w,_ = self:GetSize()
	local targetW = Lerp(delta, w, data.targetW)
	local targetX, _ = self:GetPos()
	targetX = Lerp(delta, targetX, data.targetX)

	self:SetSize(targetW, util.ScreenScaleH(37))
	self:SetPos(targetX, data.targetY)

end

function PANEL:StopAnimations()
	for _,v in pairs(self.Animations) do
		v:Stop()
	end
end

function PANEL:Think()

	local ply = LocalPlayer()
	if not IsValid(ply) then
		return
	end

	for _,v in pairs(self.Animations) do
		if v:Active() then
			v:Run()
		end
	end

	local animateSize = false
	local animType = -1
	local primaryAmmoType = -1
	local secondaryAmmoType = -1
	local w, h = 0, 0
	local altAmmo = 0
	local clip1 = -1
	local totalW = 0

	local vehicle = ply:GetVehicle()
	if vehicle ~= nil and IsValid(vehicle) and vehicle:GetNWBool("IsPassengerSeat", false) == false then

		if self.LastWeapon ~= vehicle then
			animateSize = true
		end
		self.LastWeapon = vehicle

		if vehicle.GetAmmo ~= nil then
			primaryAmmoType, clip, num = vehicle:GetAmmo()
		else
			primaryAmmoType = -1
		end

		secondaryAmmoType = -1
		altAmmo = 0
		clip1 = -1

	else

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then
			return
		end

		if self.LastWeapon ~= wep then
			animateSize = true
		end
		self.LastWeapon = wep

		primaryAmmoType = wep:GetPrimaryAmmoType()
		secondaryAmmoType = wep:GetSecondaryAmmoType()
		altAmmo = ply:GetAmmoCount(wep:GetSecondaryAmmoType())
		clip1 = wep:Clip1()

	end

	if clip1 ~= -1 then
		self.HUDPrimary:ShowAmmoCount(true)
	else
		self.HUDPrimary:ShowAmmoCount(false)
	end

	if self.LastClipVal ~= clip1 then
		animateSize = true
	end

	self.LastClipVal = clip1

	local firstOffset = 0
	if primaryAmmoType ~= -1 then

		w, h = self.HUDPrimary:GetSize()
		totalW = w + util.ScreenScaleH(10)

		self.HUDPrimary:SetVisible(true)
		firstOffset = util.ScreenScaleH(10)
	else
		self.HUDPrimary:SetVisible(false)
	end

	if self.LastPrimaryAmmo ~= primaryAmmoType then
		animateSize = true
	end

	self.LastPrimaryAmmo = primaryAmmoType

	if secondaryAmmoType ~= -1 and altAmmo > 0 then

		if self.LastAltCount <= 0 then
			animateSize = true
			animType = 0
		end

		self.HUDSecondary:SetVisible(true)
		self.HUDSecondary:SetPos(w + firstOffset, 0)

		w, h = self.HUDSecondary:GetSize()
		totalW = totalW + w + util.ScreenScaleH(10)

	else

		if self.LastAltCount > 0 then
			animateSize = true
			animType = 1
		end

		self.HUDSecondary:SetVisible(false)

	end

	self.LastAltCount = altAmmo
	self.HUDPrimary:SetPos(0, 0)

	if animateSize == true then
		local targetX = ScrW() - totalW - 15
		local targetY = ScrH() - h - util.ScreenScaleH(10)
		local targetW = totalW
		if animType == 0 then
			self.HUDSecondary:Reset()
			self.HUDSecondary:FadeIn(0.5)
		elseif animType == 1 then
			self.HUDSecondary:FadeOut(0.5)
		end
		self.AnimateShowAlt:Start(1, { targetX = targetX, targetY = targetY, targetW = targetW })
	end

end

vgui.Register( "HudAmmo", PANEL, "Panel" )
