GM.HintHistory = {}
GM.HintHistoryLast = 0
GM.HintHistoryMax = 3

local FONT_TEXT = "LambdaHintFont"
local FONT_TEXT_GLOW = "LambdaHintFontGlow"
local TEXT_SIZE = 10
local TEXT_OFFSET_X = 4
local TEXT_OFFSET_Y = 4
local HINT_HEIGHT = 32
local HINT_SPACING = 4

surface.CreateFont(FONT_TEXT,
{
	font = "Verdana",
	size = util.ScreenScaleH(TEXT_SIZE),
	weight = 0,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	additive = true,
})

surface.CreateFont(FONT_TEXT_GLOW,
{
	font = "Verdana",
	size = util.ScreenScaleH(TEXT_SIZE),
	weight = 0,
	blursize = util.ScreenScaleH(2),
	scanlines = 2,
	antialias = true,
	additive = true,
})

local function GetTextColor()
	local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")
	return Color(col.x, col.y, col.z, 255)
end

local function GetBGColor()
	local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")
	return Color(col.x, col.y, col.z, 128)
end

function GM:DrawHintText(font, x, y, val)
	surface.SetFont(font)
	surface.SetTextPos(x, y)
	surface.DrawText(val)
end

function GM:DrawHintHistory(x, y, w, h, data, alpha)

	-- Box
	draw.RoundedBox( 0, x, y, w, h-3, GetBGColor() )

	-- Stripe
	draw.RoundedBox( 0, x, y+h-3, w, 3, Color (255, 147, 30, 220 ) )

	local colText = GetTextColor()
	surface.SetTextColor(colText.r, colText.g, colText.b, colText.a * 1)

	self:DrawHintText(FONT_TEXT, x + TEXT_OFFSET_X, y + TEXT_OFFSET_Y, data.text)

	if data.elapsed < 2 then

		local a = 1 - (data.elapsed / 2)
		local blur = 3.5 * a
		for i = blur, 0, -1.0 do

			surface.SetTextColor(colText.r, colText.g, colText.b, (colText.a * i) * a)
			self:DrawHintText(FONT_TEXT_GLOW, x + TEXT_OFFSET_X, y + TEXT_OFFSET_Y, data.text)

		end

	end

end

local lastHintHistoryUpdate = SysTime()

function GM:HUDDrawHintHistory()

	local curSysTime = SysTime()
	local dt = curSysTime - lastHintHistoryUpdate
	lastHintHistoryUpdate = curSysTime

	local x, y = ScrW() - 10, ScrH() * 0.8
	local tall = 0
	local wide = 0
	local shouldUpdate = false

	for k, v in pairs( self.HintHistory ) do

		if v.elapsed > v.holdtime then
			table.remove(self.HintHistory, k)
			shouldUpdate = true
			continue
		end

		if v.y == nil then
			v.y = y
		end

		v.y = v.y or y
		v.y = math.Approach(v.y, v.targetY, dt * 100)
		v.elapsed = v.elapsed + (dt * 2 * v.timescale)

		local delta = v.holdtime - v.elapsed
		delta = delta / v.holdtime

		local alpha = 255

		-- Fade in/out
		if ( delta > 1 - v.fadein ) then
			alpha = math.Clamp( ( 1.0 - delta ) * ( 255 / v.fadein ), 0, 255 )
		elseif ( delta < v.fadeout ) then
			alpha = math.Clamp( delta * ( 255 / v.fadeout ), 0, 255 )
		end

		v.x = x - v.width + (v.width - ((v.width + 20) * ( alpha / 255 ) )) + 20

		local rx = math.Round( v.x )
		local ry = math.Round( v.y - ( v.height / 2 ) - 4 )
		local rw = math.Round( v.width )
		local rh = math.Round( v.height )
		local bordersize = 8

		self:DrawHintHistory(rx, ry, rw, rh, v, alpha)

		y = y + ( v.height + 2 )
		tall = tall + v.height + 18
		wide = v.width

		if alpha == 0 then
			shouldUpdate = true
			table.remove(self.HintHistory, k)
		end

	end

	if shouldUpdate == true then
		self:UpdateHintHistory(true)
	end

end


function GM:UpdateHintHistory()

	local i = 0
	for _,v in pairs(self.HintHistory) do
		v.timescale = math.Clamp(table.Count(self.HintHistory) - i / self.HintHistoryMax * 10, 1, 10)
		v.targetY = (ScrH() * 0.8) - ((i + 1) * (HINT_HEIGHT + HINT_SPACING))
		i = i + 1
	end

end

function GM:AddHint(text, time)

	local count = #self.HintHistory

	local hint = {}
	hint.time = CurTime()
	hint.elapsed = 0
	hint.timescale = 1
	hint.holdtime = time
	hint.fadein = 0.04
	hint.fadeout = 0.03
	hint.text = string.upper(text)
	hint.y = (ScrH() * 0.8) - ((count + 1) * (HINT_HEIGHT + HINT_SPACING))

	surface.SetFont( FONT_TEXT_GLOW )
	local w, h = surface.GetTextSize( hint.text )
	hint.theight = h
	hint.twidth = w
	hint.height = HINT_HEIGHT
	hint.width = w + 10

	if ( self.HintHistoryLast >= hint.time ) then
		hint.time = self.HintHistoryLast + 0.05
	end

	table.insert( self.HintHistory, hint )
	self.HintHistoryLast = hint.time

	self:UpdateHintHistory(false)

end
