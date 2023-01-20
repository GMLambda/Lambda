local FONT_NUMBER = "LambdaHudNumbers"
local FONT_NUMBER_GLOW = "LambdaHudNumbersGlow"
local FONT_NUMBER_SMALL = "LambdaHudNumbersSmall"
local FONT_TEXT = "HudDefault"

local function GetTextColor()
    local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")

    return Color(col.x, col.y, col.z, 255)
end

local function GetBGColor()
    local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")

    return Color(col.x, col.y, col.z, 128)
end

local function InitFonts()
    surface.CreateFont(FONT_NUMBER, {
        font = "HalfLife2",
        size = util.ScreenScaleH(32),
        weight = 0,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        additive = true
    })

    surface.CreateFont(FONT_NUMBER_GLOW, {
        font = "HalfLife2",
        size = util.ScreenScaleH(32),
        weight = 0,
        blursize = util.ScreenScaleH(4),
        scanlines = 2,
        antialias = true,
        additive = true
    })

    surface.CreateFont(FONT_NUMBER_SMALL, {
        font = "HalfLife2",
        size = util.ScreenScaleH(16),
        weight = 1000,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        additive = true
    })
end

local PANEL = {}

function PANEL:Init()
    -- On resolution changes we simply recreate this panel.
    InitFonts()
    self.ShouldDrawBackground = true
    self.DisplayValue = true
    self.DisplaySecondaryValue = false
    self.Indent = false
    self.IsTime = false
    self.Blur = 0.0
    self.PrimaryVal = 0
    self.SecondaryVal = 0
    self.CurPrimaryVal = 0
    self.CurSecondaryVal = 0
    self.LabelText = ""
    self.LerpValues = true
    self.LerpFraction = 0.08
    self.AnimateFadeIn = Derma_Anim("FadeIn", self, self.AnimFadeIn)
    self.AnimateFadeOut = Derma_Anim("FadeIn", self, self.AnimFadeOut)
    self.TextX = 8
    self.TextY = 20
    self.DigitX = 50
    self.DigitY = 2
    self.Digit2X = 98
    self.Digit2Y = 16
    self.Alpha = 1
    self:SetTextColor(255, 220, 0, 100)
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

function PANEL:Reset()
    self.Blur = 0.0
end

function PANEL:SetDisplayValue(val)
    self.PrimaryVal = val
end

function PANEL:SetSecondaryValue(val)
    self.SecondaryVal = val
end

function PANEL:SetShouldDisplayValue(state)
    self.DisplayValue = state
end

function PANEL:SetShouldDisplaySecondaryValue(state)
    self.DisplaySecondaryValue = state
end

function PANEL:SetLabelText(text)
    self.LabelText = text
end

function PANEL:SetIndent(state)
    self.Indent = state
end

function PANEL:SetIsTime(state)
    self.IsTime = state
end

function PANEL:SetDrawBackground(state)
    self.ShouldDrawBackground = state
end

function PANEL:PaintNumbers(font, x, y, val)
    surface.SetFont(font)
    local text

    if self.IsTime then
        local mins = val / 60
        local secs = val - mins * 60
        -- Whatever.
    else
        text = tostring(val)
    end

    local w = surface.GetTextSize("0")

    if val < 100 and self.Indent then
        x = x + w
    end

    if val < 10 and self.Indent then
        x = x + w
    end

    surface.SetTextPos(x, y)
    surface.DrawText(text)
end

function PANEL:PaintLabel()
    local colText = GetTextColor()
    surface.SetFont(FONT_TEXT)
    surface.SetTextColor(colText.r, colText.g, colText.b, colText.a * self.Alpha)
    surface.SetTextPos(util.ScreenScaleH(self.TextX), util.ScreenScaleH(self.TextY))
    surface.DrawText(self.LabelText)
end

function PANEL:AnimFadeIn(anim, delta, data)
    self.Alpha = delta
end

function PANEL:AnimFadeOut(anim, delta, data)
    self.Alpha = 1 - delta
end

function PANEL:FadeIn(secs)
    self.AnimateFadeOut:Stop()
    self.AnimateFadeIn:Start(secs)
end

function PANEL:FadeOut(secs)
    self.AnimateFadeIn:Stop()
    self.AnimateFadeOut:Start(secs)
end

function PANEL:Paint(width, height)
    if self.AnimateFadeIn:Active() then
        self.AnimateFadeIn:Run()
    end

    if self.AnimateFadeOut:Active() then
        self.AnimateFadeOut:Run()
    end

    if self.ShouldDrawBackground == true then
        local col = GetBGColor()
        col.a = col.a * self.Alpha
        draw.RoundedBox(8, 0, 0, width, height, col)
    end

    local colText = GetTextColor()

    if self.DisplayValue then
        surface.SetTextColor(colText.r, colText.g, colText.b, colText.a * self.Alpha)

        if self.LerpValues == true then
            self.CurPrimaryVal = Lerp(self.LerpFraction, self.CurPrimaryVal, self.PrimaryVal)
        else
            self.CurPrimaryVal = self.PrimaryVal
        end

        self:PaintNumbers(FONT_NUMBER, util.ScreenScaleH(self.DigitX), util.ScreenScaleH(self.DigitY), math.Round(self.CurPrimaryVal))

        for i = self.Blur, 0, -1.0 do
            if i > 1.0 then
                self:PaintNumbers(FONT_NUMBER_GLOW, util.ScreenScaleH(self.DigitX), util.ScreenScaleH(self.DigitY), math.Round(self.CurPrimaryVal))
            else
                surface.SetTextColor(colText.r, colText.g, colText.b, (colText.a * i) * self.Alpha)
                self:PaintNumbers(FONT_NUMBER_GLOW, util.ScreenScaleH(self.DigitX), util.ScreenScaleH(self.DigitY), math.Round(self.CurPrimaryVal))
            end
        end
    end

    if self.DisplaySecondaryValue then
        if self.LerpValues == true then
            self.CurSecondaryVal = Lerp(self.LerpFraction, self.CurSecondaryVal, self.SecondaryVal)
        else
            self.CurSecondaryVal = self.SecondaryVal
        end

        surface.SetTextColor(colText.r, colText.g, colText.b, colText.a * self.Alpha)
        self:PaintNumbers(FONT_NUMBER_SMALL, util.ScreenScaleH(self.Digit2X), util.ScreenScaleH(self.Digit2Y), math.Round(self.CurSecondaryVal))
    end

    self:PaintLabel()
end

vgui.Register("HudNumeric", PANEL, "Panel")