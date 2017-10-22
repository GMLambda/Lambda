include("huds/hud_numeric.lua")
include("huds/hud_suit.lua")
include("huds/hud_pickup.lua")
include("huds/hud_roundinfo.lua")
include("huds/hud_settings.lua")
include("huds/hud_hint.lua")

--local DbgPrint = GetLogging("HUD")

DEFINE_BASECLASS( "gamemode_base" )

local function AskWeapon(ply, hud, wep)
	if IsValid( wep ) and wep.HUDShouldDraw ~= nil then
		return wep.HUDShouldDraw( wep, name )
	end
end

local hidehud = GetConVar("hidehud")

function GM:HUDTick()

	local ply = LocalPlayer()
	if not IsValid(ply) then
		return
	end

	-- FIXME: Show the hud only when in color customization.
	local hideHud = false

	local wep = ply:GetActiveWeapon()
	local CHudHealth = (not wep:IsValid() or AskWeapon(ply, "CHudHealth", wep) ~= false) and hook.Call("HUDShouldDraw", nil, "CHudHealth") ~= false and not hideHud
	local CHudBattery = (not wep:IsValid() or AskWeapon(ply, "CHudBattery", wep) ~= false) and hook.Call("HUDShouldDraw", nil, "CHudBattery") ~= false and not hideHud
	local CHudSecondaryAmmo = (wep:IsValid() and AskWeapon(ply, "CHudSecondaryAmmo", wep) ~= false) and hook.Call("HUDShouldDraw", nil, "CHudSecondaryAmmo") ~= false and not hideHud

	local drawHud = ply:IsSuitEquipped() and ply:Alive() and hidehud:GetBool() ~= true

	if IsValid(self.HUDSuit) then

		local vehicle = ply:GetVehicle()

		local suit = self.HUDSuit
		suit.HUDHealth:SetVisible(CHudHealth and drawHud)
		suit.HUDArmor:SetVisible(CHudBattery and drawHud)
		suit.HUDAux:SetVisible(CHudBattery and drawHud)
		suit.HUDAmmo:SetVisible(CHudSecondaryAmmo and IsValid(wep) or IsValid(vehicle) and drawHud)

		suit:SetVisible(drawHud)

	end

end

function GM:HUDShouldDraw( hudName )

	local ply = LocalPlayer()
	if not IsValid(ply) then
		return false
	end

	local viewlock = ply:GetViewLock()

	if hidehud:GetBool() == true then
		return false
	end

	if hudName == "CHudCrosshair"  then
		if viewlock == VIEWLOCK_SETTINGS_ON or viewlock == VIEWLOCK_SETTINGS_RELEASE then
			--return false
		end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then
			return false
		end
		if lambda_dynamic_crosshair:GetBool() == true and wep.DoDrawCrosshair == nil then
			return false
		end
	elseif hudName == "CHudGeiger" then
		if not ply:IsSuitEquipped() then
			return false
		end
	elseif hudName == "CHudBattery" then
		return false
	elseif hudName == "CHudHealth" or
		hudName == "CHudAmmo" or
		hudName == "CHudSecondaryAmmo" then
		return false
	elseif hudName == "CHudDamageIndicator" then
		-- We include the lifetime because theres some weird thing going with the damage indicator.
		if ply:Alive() == false or ply:GetLifeTime() < 1.0 then
			return false
		end
	elseif hudName == "CHudHistoryResource" then
		return false
	end

	return true

end

local CROSSHAIR_W = 32
local CROSSHAIR_H = 32
local CROSSHAIR_SPACE = 4
local RT_NAME = "LambdaCrosshair" .. CurTime()
local CROSSHAIR_RT
local CROSSHAIR_MAT
local CROSSHAIR_RT_SETUP = false

local AMMO_BAR_H = 2
local AMMO_BAR_W = 32
local AMMO_BAR_SPACING = 2
local AMMO_BAR1_Y = (CROSSHAIR_H / 2) + AMMO_BAR_SPACING
local AMMO_BAR2_Y = AMMO_BAR1_Y + AMMO_BAR_H + AMMO_BAR_SPACING
local AMMO_BAR1_COLOR = Color(255, 255, 255, 50)
local AMMO_BAR2_COLOR = Color(255, 255, 255, 50)

local function UpdateCrosshair(centerX, centerY)

	local localCenterX = CROSSHAIR_W / 2
	local localCenterY = CROSSHAIR_H / 2
	local r,g,b

	--local data = render.Capture({format = "png", h = CROSSHAIR_H, w = CROSSHAIR_W, x = screenCenterX, y = screenCenterY, quality = 10})
	--DbgPrint(data)
	render.CapturePixels()

	if CROSSHAIR_RT_SETUP == false  then

		CROSSHAIR_RT = GetRenderTarget(RT_NAME, CROSSHAIR_W, CROSSHAIR_H, false)
		CROSSHAIR_MAT = CreateMaterial("LambdaCrosshair" .. CurTime(), "UnlitGeneric",
		{
			["$basetexture"] = RT_NAME,
			["$translucent"] = 1,
		})

		CROSSHAIR_MAT:SetTexture("$basetexture", CROSSHAIR_RT)

		render.ClearRenderTarget(CROSSHAIR_RT, Color(0, 0, 0, 0))
		--render.ClearDepth()
		--render.Clear( 0, 0, 0, 0 )

		CROSSHAIR_RT_SETUP = true

	end

	render.PushRenderTarget(CROSSHAIR_RT)
	render.OverrideAlphaWriteEnable( true, true )

	r,g,b = render.ReadPixel(centerX, centerY + AMMO_BAR1_Y)
	AMMO_BAR1_COLOR.r = 255 - r
	AMMO_BAR1_COLOR.g = 255 - g
	AMMO_BAR1_COLOR.b = 255 - b
	AMMO_BAR1_COLOR.a = 128

	r,g,b = render.ReadPixel(centerX, centerY + AMMO_BAR2_Y)
	AMMO_BAR2_COLOR.r = 255 - r
	AMMO_BAR2_COLOR.g = 255 - g
	AMMO_BAR2_COLOR.b = 255 - b
	AMMO_BAR2_COLOR.a = 128

	cam.Start2D()

		local pad = 1
		local alpha = 128

		-- Up
		for y = 0, (CROSSHAIR_H / 2) - CROSSHAIR_SPACE, pad do
			r,g,b = render.ReadPixel(centerX, centerY - y - CROSSHAIR_SPACE)
			surface.SetDrawColor(255 - r, 255 - g, 255 - b, alpha)
			surface.DrawLine(localCenterX, localCenterY - y - CROSSHAIR_SPACE, localCenterX, localCenterY - y - CROSSHAIR_SPACE - 1)
			--surface.DrawRect(localCenterX, localCenterY - y - CROSSHAIR_SPACE, 2, 2)
		end

		-- Down
		for y = 0, (CROSSHAIR_H / 2) - CROSSHAIR_SPACE, pad do
			r,g,b = render.ReadPixel(centerX, centerY + y + CROSSHAIR_SPACE)
			surface.SetDrawColor(255 - r, 255 - g, 255 - b, alpha)
			surface.DrawLine(localCenterX, localCenterY + y + CROSSHAIR_SPACE, localCenterX, localCenterY + y + CROSSHAIR_SPACE + 1)
			--surface.DrawRect(localCenterX, localCenterY + y + CROSSHAIR_SPACE, 2, 2)
		end

		-- Left
		for x = 0, (CROSSHAIR_W / 2) - CROSSHAIR_SPACE, pad do
			r,g,b = render.ReadPixel(centerX - x - CROSSHAIR_SPACE, centerY)
			surface.SetDrawColor(255 - r, 255 - g, 255 - b, alpha)
			surface.DrawLine(localCenterX - x - CROSSHAIR_SPACE, localCenterY, localCenterX - x - CROSSHAIR_SPACE - 1, localCenterY)
			--surface.DrawRect(localCenterX - x - CROSSHAIR_SPACE, localCenterY, 2, 2)
		end

		-- Right
		for x = 0, (CROSSHAIR_W / 2) - CROSSHAIR_SPACE, pad do
			r,g,b = render.ReadPixel(centerX + x + CROSSHAIR_SPACE, centerY)
			surface.SetDrawColor(255 - r, 255 - g, 255 - b, alpha)
			surface.DrawLine(localCenterX + x + CROSSHAIR_SPACE, localCenterY, localCenterX + x + CROSSHAIR_SPACE + 1, localCenterY)
			--surface.DrawRect(localCenterX + x + CROSSHAIR_SPACE, localCenterY, 2, 2)
		end

		-- Dot
		r,g,b = render.ReadPixel(centerX, centerY)
		surface.SetDrawColor(255 - (r / 4), math.Clamp(255 - (g * 4), 0, 255), math.Clamp(255 - (b * 4), 0, 255), 255)
		surface.DrawLine(localCenterX - 4, localCenterY - 4, localCenterX + 4, localCenterY + 4)
		surface.DrawLine(localCenterX + 4, localCenterY - 4, localCenterX - 4, localCenterY + 4)

	cam.End2D()

	render.OverrideAlphaWriteEnable( false )
	render.PopRenderTarget()

end

function GM:DrawDynamicCrosshair()

	local ply = LocalPlayer()
	local viewlock = ply:GetViewLock()

	if viewlock == VIEWLOCK_SETTINGS_ON or viewlock == VIEWLOCK_SETTINGS_RELEASE then
		return false
	end

	if ply:Alive() == true and ply:InVehicle() == true then
		local veh = ply:GetVehicle()
		if veh:GetClass() == "prop_vehicle_jeep" or veh:GetClass() == "prop_vehicle_airboat" then
			return
		end
	end

	local wep = ply:GetActiveWeapon()
	if wep == nil or not IsValid(wep) then
		return
	end
	if wep:GetClass() == "weapon_crowbar" then
		return
	end

	if wep.DoDrawCrosshair ~= nil then
		return
	end

	local scrW, scrH = ScrW(), ScrH()
	local centerX = scrW / 2
	local centerY = scrH / 2

	if FrameNumber() % 60 == 0 or CROSSHAIR_RT_SETUP == false then
		UpdateCrosshair(centerX, centerY)
	end

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial(CROSSHAIR_MAT)
	surface.DrawTexturedRect(centerX - (CROSSHAIR_W / 2), centerY - (CROSSHAIR_H / 2), CROSSHAIR_W, CROSSHAIR_H)

	local clip1 = wep:Clip1()
	if clip1 ~= -1 then
		local p = clip1 / wep:GetMaxClip1()
		local w = math.Round(p * 32)
		surface.SetDrawColor( AMMO_BAR1_COLOR.r, AMMO_BAR1_COLOR.g, AMMO_BAR1_COLOR.b, AMMO_BAR1_COLOR.a )
		surface.DrawRect(centerX - (AMMO_BAR_W / 2), centerY + AMMO_BAR1_Y, w, AMMO_BAR_H)
	end

	local ammoType = wep:GetPrimaryAmmoType()
	local ammoCount = ply:GetAmmoCount(ammoType)
	if ammoCount > 0 then
		local ammoName = game.GetAmmoName(ammoType)
		local maxVar = self.MAX_AMMO_DEF[ammoName]
		if maxVar ~= nil then
			local p = ammoCount / maxVar:GetInt()
			local w = math.Round(p * 32)
			surface.SetDrawColor( AMMO_BAR2_COLOR.r, AMMO_BAR2_COLOR.g, AMMO_BAR2_COLOR.b, AMMO_BAR2_COLOR.a )
			surface.DrawRect(centerX - (AMMO_BAR_W / 2), centerY + AMMO_BAR2_Y, w, AMMO_BAR_H)
		end
	end

end

function GM:HUDPaint()

	hook.Run( "HUDDrawPickupHistory" )
	hook.Run( "HUDDrawHintHistory" )
	hook.Run( "DrawDeathNotice", 0.85, 0.04 )
	if lambda_dynamic_crosshair:GetBool() == true then
		hook.Run( "DrawDynamicCrosshair" )
	end

end

function GM:HUDInit()

	if IsValid(self.HUDSuit) then
		self.HUDSuit:Remove()
	end

	if IsValid(self.HUDRoundInfo) then
		self.HUDRoundInfo:Remove()
	end

	self.HUDRoundInfo = vgui.Create("HUDRoundInfo")
	self.HUDSuit = vgui.Create("HudSuit")

	CROSSHAIR_RT_SETUP = false

end

function GM:SetRoundDisplayInfo(infoType, params)
	if not IsValid(self.HUDRoundInfo) then
		return
	end
	self.HUDRoundInfo:SetVisible(true)
	self.HUDRoundInfo:SetDisplayInfo(infoType, params)
end
