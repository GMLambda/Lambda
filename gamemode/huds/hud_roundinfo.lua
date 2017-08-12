include("hud_numeric.lua")

local FONT_TEXT = "HudDefault"
local BAR_HEIGHT = util.ScreenScaleH(40)

local PANEL = {}

function PANEL:Init()

	self:SetSize(ScrW(), BAR_HEIGHT)
	self.TextColor = Color(255, 220, 0, 100)
	self.Alpha = 100
	self.InfoType = ROUND_INFO_NONE
	self.Parameters = {}

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

function PANEL:SetDisplayInfo(infoType, parameters)

	DbgPrint("PANEL:SetDisplayInfo")

	if infoType ~= ROUND_INFO_NONE then
		self:SetVisible(true)
	else
		self:SetVisible(false)
	end

	self.InfoType = infoType
	self.Parameters = parameters

end

function PANEL:Paint()

	local infoType = self.InfoType
	if infoType == ROUND_INFO_NONE then
		return
	end

	-- Background.
	surface.SetDrawColor(0, 0, 0, 64)
	surface.DrawRect(0, 0, ScrW(), BAR_HEIGHT)

	if infoType == ROUND_INFO_PLAYERRESPAWN then
		self:PaintInfoPlayerRespawn()
	elseif infoType == ROUND_INFO_ROUNDRESTART then
		self:PaintInfoRoundRestart()
	elseif infoType == ROUND_INFO_WAITING_FOR_PLAYER then
		self:PaintInfoWaitingForPlayers()
	end

end

function PANEL:GetParameters()
	return self.Parameters
end

function PANEL:PaintInfoPlayerRespawn()
	local text
	local x, y
	local w = ScrW()
	local h = BAR_HEIGHT

	local startTime = self.Parameters["StartTime"]
	local timeout = self.Parameters["Timeout"]

	timeout = math.Clamp(timeout, -1, 127)
	if timeout == -1 then
		text = string.upper("Respawning next round")
		self:PaintText(FONT_TEXT, text, 0, h / 4, w, h)
	else
		local timeEnd = startTime + timeout
		local remain = timeEnd - GetSyncedTimestamp()

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

function PANEL:PaintInfoRoundRestart()
	local text
	local w = ScrW()
	local h = BAR_HEIGHT

	local startTime = self.Parameters["StartTime"]
	local timeout = self.Parameters["Timeout"]

	timeout = math.Clamp(timeout, -1, 127)

	local timeEnd = startTime + timeout
	local remain = timeEnd - GetSyncedTimestamp()
	remain = math.Clamp(remain, 0, 127)

	text = string.upper("Restarting Round in...")
	local _,y = self:PaintText(FONT_TEXT, text, 0, h / 6, w, h)
	text = string.format("%0.2f", remain)
	self:PaintText(FONT_TEXT, text, 0, h / 4 + y, w, h)
	self:PaintText(FONT_TEXT, text, 0, h / 4 + y, w, h)

	local reverse = timeout - remain
	local ralpha = 1 - (remain / timeout)
	local brightness = 0
	if reverse <= 0.5 then
		brightness = (0.5 - reverse) * 1.3
	else
		brightness = 0
	end

	local tab =
	{
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = brightness,
		["$pp_colour_contrast"] = (1 - ralpha * 0.2),
		["$pp_colour_colour"] = 0.8 - (ralpha * 0.5),
		["$pp_colour_mulr"] = ralpha * 3,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0,
	}

	DrawColorModify( tab )

end


function PANEL:PaintInfoWaitingForPlayers()
	local text
	local w = ScrW()
	local h = BAR_HEIGHT

	local startTime = self.Parameters["StartTime"]
	local timeout = self.Parameters["Timeout"]

	timeout = math.Clamp(timeout, -1, 127)

	local timeEnd = startTime + timeout
	local remain = timeEnd - GetSyncedTimestamp()
	remain = math.Clamp(remain, 0, 127)

	local connecting = self.Parameters["Connecting"]
	local fullyConnected = self.Parameters["FullyConnected"]
	local total = connecting + fullyConnected

	text = string.upper("Waiting for players " .. tostring(connecting) .. " / " .. tostring(total))
	local _,y = self:PaintText(FONT_TEXT, text, 0, h / 6, w, h)
	text = string.format("%0.2f", remain)
	self:PaintText(FONT_TEXT, text, 0, h / 4 + y, w, h)
	self:PaintText(FONT_TEXT, text, 0, h / 4 + y, w, h)
end

function PANEL:Think()
end

vgui.Register( "HUDRoundInfo", PANEL )
