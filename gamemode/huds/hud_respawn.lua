include("hud_numeric.lua")

local FONT_TEXT = "HudDefault"
local PANEL = {}

function PANEL:Init()
	local h = util.ScreenScaleH(40)

	self:SetSize(ScrW(), h)
	self:SetTimeout(GetSyncedTimestamp(), 10)
	self.TextColor = Color(255, 220, 0, 100)
	self.Alpha = 100

	-- Dont popup initially.
	self:SetVisible(false)

end

function PANEL:PaintText(font, val, x, y, w, h)

	surface.SetTextColor(self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a * self.Alpha)

	surface.SetFont(font)
	local text = tostring(val)

	local textW, textH = surface.GetTextSize(text)
	x = x + (w / 2) - (textW / 2)
	y = y + (textH / 2)

	surface.SetTextPos(x, y)
	surface.DrawText(text)

	return textW, textH

end

function PANEL:Paint()

	local w,h = self:GetSize()
	surface.SetDrawColor(0, 0, 0, 64)
	surface.DrawRect(0, 0, ScrW(), h)

	local timeEnd = self.StartTime + self.Timeout
	local remain = timeEnd - GetSyncedTimestamp()

	local text
	local x,y

	if self.Timeout == -1 then
		text = string.upper("Respawning next round")
		self:PaintText(FONT_TEXT, text, 0, h / 4, w, h)
	else
		if remain > 0 then
			text = string.upper("Time remaining until respawn")
			x, y = self:PaintText(FONT_TEXT, text, 0, h / 6, w, h)
			text = string.format("%0.2f", remain)
			self:PaintText(FONT_TEXT, text, 0, h / 4 + y, w, h)
			self:PaintText(FONT_TEXT, text, 0, h / 4 + y, w, h)
		else
			local keyName = input.LookupBinding("+jump", true)
			text = string.format("Press <%s> to respawn", keyName)
			x, y = self:PaintText(FONT_TEXT, text, 0, h / 4, w, h)
		end
	end

end

function PANEL:Think()
end

function PANEL:SetTimeout(startTime, timeout)
	self.StartTime = startTime
	self.Timeout = timeout
end


vgui.Register( "HudRespawn", PANEL )
