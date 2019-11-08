local FONT_TEXT = "HudDefault"
local PANEL = {}

-- TODO: Make those shared.
local SUIT_DEVICE_BREATHER = 1
local SUIT_DEVICE_SPRINT = 2
local SUIT_DEVICE_FLASHLIGHT = 3

local function GetTextColor()
	local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")
	return Color(col.x, col.y, col.z, 255)
end

local function GetBGColor()
	local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")
	return Color(col.x, col.y, col.z, 128)
end

function PANEL:Init()

	self.ShouldDrawBackground = true

	self:SetSize(util.ScreenScaleH(103), util.ScreenScaleH(28))

	self.AnimateSizeChange = Derma_Anim("SizeChange", self, self.AnimSizeChange)
	self.AnimateFadeIn = Derma_Anim("FadeIn", self, self.AnimFadeIn)
	self.AnimateFadeOut = Derma_Anim("FadeIn", self, self.AnimFadeOut)
	self.Animations =
	{
		self.AnimateSizeChange,
		self.AnimateFadeIn,
		self.AnimateFadeOut,
	}

	self.TextX = 8
	self.TextY = 15
	self.Text2X = 8
	self.Text2Y = 25
	self.Text2Gap = 1

	self.BarInsetX = 8
	self.BarInsetY = 8
	self.BarWidth = 80
	self.BarHeight = 4
	self.BarChunkWidth = 4
	self.BarChunkGap = 2
	self.SprintActive = false
	self.OxygenActive = false
	self.LastPower = 0

	self.Alpha = 1
	self.LabelText = Localize("#Valve_Hud_AUX_POWER", "AUX")
	self.LabelOxygen = Localize("#Valve_Hud_OXYGEN", "OXYGEN")
	self.LabelSprint = Localize("#Valve_Hud_SPRINT", "SPRINT")

	self:SetTextColor(255, 208, 64, 255)
	self:SetBackgroundColor(0, 0, 0, 76)

end

function PANEL:GetBackgroundColor()
	return self.BackgroundColor
end

function PANEL:SetBackgroundColor(r, g, b, a)
	self.BackgroundColor = Color(r, g, b, a)
end

function PANEL:SetTextColor(r, g, b, a)
	self.TextColor = Color(r, g, b, a)
end

function PANEL:AnimSizeChange(anim, delta, data)

	local w,h = self:GetSize()
	local targetW = Lerp(delta, w, data.targetW)
	local targetH = Lerp(delta, h, data.targetH)
	local targetX, targetY = self:GetPos()
	targetX = Lerp(delta, targetX, data.targetX)
	targetY = Lerp(delta, targetY, data.targetY)

	self:SetSize(targetW, targetH)
	self:SetPos(targetX, targetY)

end

function PANEL:AnimFadeIn(anim, delta, data)
	self.Alpha = Lerp(delta, data.Alpha, 1)
end

function PANEL:AnimFadeOut(anim, delta, data)
	self.Alpha = Lerp(delta, data.Alpha, 0)
	--DbgPrint(self.Alpha)
end

function PANEL:FadeIn(secs)
	self.AnimateFadeOut:Stop()
	self.AnimateFadeIn:Start(secs, { Alpha = self.Alpha })
end

function PANEL:FadeOut(secs)
	self.AnimateFadeIn:Stop()
	self.AnimateFadeOut:Start(secs, { Alpha = self.Alpha })
end

function PANEL:StopAnimations()
	for _,v in pairs(self.Animations) do
		v:Stop()
	end
end

function PANEL:Think()

end

function PANEL:PaintLabel()

	local textColor = GetTextColor()
	surface.SetFont(FONT_TEXT)
	surface.SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a * self.Alpha)
	surface.SetTextPos(util.ScreenScaleH(self.TextX), util.ScreenScaleH(self.TextY))
	surface.DrawText(self.LabelText)

end

function PANEL:Paint(width, height)

	local ply = LocalPlayer()
	if not IsValid(ply) then
		return
	end

	for _,v in pairs(self.Animations) do
		if v:Active() then
			v:Run()
		end
	end

	if self.ShouldDrawBackground == true then
		local col = GetBGColor()
		col.a = col.a * self.Alpha
		draw.RoundedBox( 8, 0, 0, width, height, col )
	end

	local suitPower = ply:GetLambdaSuitPower()
	if suitPower ~= self.LastPower and suitPower == 100.0 then
		--DbgPrint("Fade out")
		self:FadeOut(5)
	elseif suitPower ~= self.LastPower and suitPower < 100.0 then
		--DbgPrint("Fade in")
		self:FadeIn(0.2)
	end
	self.LastPower = suitPower

	local chunkCount = util.ScreenScaleH(self.BarWidth) / (util.ScreenScaleH(self.BarChunkWidth) + util.ScreenScaleH(self.BarChunkGap))
	local enabledChunks = math.ceil(chunkCount * (suitPower * 1.0 / 100.0) )
	local lowPower = false

	local textColor = GetTextColor()
	local density = 0.3 + ((suitPower / 100.0) * 0.5)

	local red = ((enabledChunks / chunkCount) * 1.2) * 208
	self:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a * self.Alpha)

	local xpos = util.ScreenScaleH(self.BarInsetX)
	local ypos = util.ScreenScaleH(self.BarInsetY)

	local enabledColor = Color(textColor.r * density, textColor.g * density, textColor.b * density, textColor.a * self.Alpha)
	local emptyColor = Color(textColor.r, textColor.g, textColor.b, 20 * self.Alpha)

	local chunkWidth = util.ScreenScaleH(self.BarChunkWidth)
	local barHeight =  util.ScreenScaleH(self.BarHeight)

	surface.SetDrawColor(enabledColor.r, enabledColor.g, enabledColor.b, enabledColor.a)
	for i = 1, enabledChunks + 1, 1 do
		surface.DrawRect(xpos, ypos, chunkWidth, barHeight)
		xpos = xpos + (chunkWidth + util.ScreenScaleH(self.BarChunkGap))
	end

	surface.SetDrawColor(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a)
	for i = enabledChunks, chunkCount, 1 do
		surface.DrawRect(xpos, ypos, chunkWidth, barHeight)
		xpos = xpos + (chunkWidth + util.ScreenScaleH(self.BarChunkGap))
	end

	self:PaintLabel()

	local sizeChange = false

	xpos = util.ScreenScaleH(self.Text2X)
	ypos = util.ScreenScaleH(self.Text2Y)
	local newH = 0
	local gap = util.ScreenScaleH(self.Text2Gap)

	if ply:UsingSuitDevice(SUIT_DEVICE_BREATHER) then
		surface.SetTextPos(xpos, ypos)
		surface.DrawText(self.LabelOxygen)
		ypos = ypos + gap
		newH = newH + gap
		if self.OxygenActive == false then
			sizeChange = true
		end
		self.OxygenActive = true
	else
		if self.OxygenActive == true then
			sizeChange = true
		end
		self.OxygenActive = false
	end

	if ply:UsingSuitDevice(SUIT_DEVICE_SPRINT) then
		surface.SetTextPos(xpos, ypos)
		surface.DrawText(self.LabelSprint)
		ypos = ypos + gap
		newH = newH + gap
		if self.SprintActive == false then
			sizeChange = true
		end
		self.SprintActive = true
	else
		if self.SprintActive == true then
			sizeChange = true
		end
		self.SprintActive = false
	end

	if sizeChange == true then

		--DbgPrint("Changign Size: ")

		local targetH = util.ScreenScaleH(30) + newH
		local targetW = util.ScreenScaleH(103)
		local targetY = ScrH() - util.ScreenScaleH(30) - util.ScreenScaleH(10) - util.ScreenScaleH(30) - util.ScreenScaleH(10)
		if newH > 0 then
			targetH = targetH + util.ScreenScaleH(10)
			targetY = targetY - newH - util.ScreenScaleH(10)
		end
		local targetX = 35

		self.AnimateSizeChange:Start(1, { targetH = targetH, targetW = targetW, targetY = targetY, targetX = targetX })

	end

end

vgui.Register( "HudAux", PANEL, "Panel" )
