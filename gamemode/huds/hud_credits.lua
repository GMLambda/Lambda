local PANEL = {}
local ROW_SPACING = 5
CREDITS_TYPE_NONE = 0
CREDITS_TYPE_INTRO = 1
CREDITS_TYPE_OUTRO = 2
CREDITS_TYPE_PARAMS = 3

local CREDITS_SECTION_NAME = {
    [CREDITS_TYPE_INTRO] = "IntroCreditsNames",
    [CREDITS_TYPE_OUTRO] = "OutroCreditsNames",
    [CREDITS_TYPE_PARAMS] = "CreditsParams"
}

local function CreateFonts()
    surface.CreateFont("LambdaCreditsOutroTextRemap", {
        font = "Verdana",
        size = util.ScreenScaleH(9),
        weight = 900,
        antialias = true,
        additive = false
    })

    surface.CreateFont("LambdaCreditsOutroLogosRemap", {
        font = "HalfLife2",
        size = util.ScreenScaleH(48),
        weight = 0,
        antialias = true,
        additive = true,
        custom = true
    })

    surface.CreateFont("LambdaCreditsTextRemap", {
        font = "Verdana",
        size = util.ScreenScaleH(12),
        weight = 900,
        antialias = true,
        additive = true
    })

    surface.CreateFont("LambdaWeaponIconsRemap", {
        font = "HalfLife2",
        size = util.ScreenScaleH(64),
        weight = 0,
        antialias = true,
        additive = true,
        custom = true
    })
end

local FONT_REMAP = {
    ["CreditsOutroText"] = "LambdaCreditsOutroTextRemap",
    ["CreditsOutroLogos"] = "LambdaCreditsOutroLogosRemap",
    ["CreditsOutroValve"] = "LambdaCreditsOutroTextRemap",
    ["CreditsText"] = "LambdaCreditsTextRemap",
    ["WeaponIcons"] = "LambdaWeaponIconsRemap"
}

function PANEL:Init()
    self.Credits = nil
    self.SizeData = {}
    self.TotalHeight = 0
    self.ScrollEndTime = 0
    self.CreditsType = CREDITS_TYPE_NONE
    self.Section = nil
    self:SetSize(ScrW(), ScrH())
    CreateFonts()
end

local function GetSection(tab, key)
    local name = CREDITS_SECTION_NAME[key]

    for k, v in pairs(tab) do
        if v.Key == name then return v.Value end
    end
end

function PANEL:ShowCredits(credits, params, creditsType, startTime, finishTime)
    self.Credits = table.Copy(credits)
    self.Params = params
    self.Section = GetSection(self.Credits, creditsType)

    if self.Section == nil then
        local name = CREDITS_SECTION_NAME[creditsType] or "<invalid>"
        error("Invalid credits section supplied: " .. name)
    end

    self.CreditsTime = finishTime - startTime

    if creditsType == CREDITS_TYPE_OUTRO then
        self:ComputeSize()
        self.ScrollEndTime = finishTime
        self.ScrollY = 0
    elseif creditsType == CREDITS_TYPE_INTRO then
        local i = 0
        local creditsSize = #self.Section
        local ts = startTime
        local fadeInTime = self.Params["fadeintime"] or 1.0
        local fadeOutTime = self.Params["fadeouttime"] or 1.0
        local fadeHoldTime = self.Params["fadeholdtime"] or 1.0
        local nextFadeTime = self.Params["nextfadetime"] or 1.0
        local pauseBetweenWaves = self.Params["pausebetweenwaves"] or 1.0
        local entryLength = fadeInTime + fadeOutTime + fadeHoldTime

        while i < creditsSize do
            local len = 3

            if i + len > creditsSize then
                len = creditsSize - i
            end

            for n = 1, len do
                local entry = self.Section[i + n]
                entry.startTime = ts
                entry.finishTime = ts + entryLength
                ts = ts + nextFadeTime
            end

            ts = ts + pauseBetweenWaves
            i = i + len
        end
    end

    self.CreditsType = creditsType
end

function PANEL:ComputeSize()
    local section = self.Section
    self.TotalHeight = 0
    self.SizeData = {}

    for k, v in pairs(section) do
        local font = FONT_REMAP[v.Value] or v.Value
        surface.SetFont(font)
        local w, h = surface.GetTextSize(v.Key)

        self.SizeData[k] = {
            w = w,
            h = h
        }

        self.TotalHeight = self.TotalHeight + h + ROW_SPACING
    end
end

function PANEL:DrawCreditsEntry(entry, curTime, posX, posY)
    local elapsed = curTime - entry.startTime
    local fadeInTime = self.Params["fadeintime"] or 1.0
    local fadeOutTime = self.Params["fadeouttime"] or 1.0
    local fadeHoldTime = self.Params["fadeholdtime"] or 1.0
    local alpha = 0

    if elapsed < fadeInTime then
        alpha = elapsed / fadeInTime
    elseif elapsed > fadeInTime and elapsed < (fadeInTime + fadeHoldTime) then
        alpha = 1
    elseif elapsed >= fadeInTime + fadeHoldTime then
        local fadeElapsed = elapsed - fadeInTime - fadeHoldTime
        alpha = 1.0 - (fadeElapsed / fadeOutTime)
    end

    local font = FONT_REMAP[entry.Value] or entry.Value
    surface.SetFont(font)
    surface.SetTextPos(util.ScreenScaleH(posX), util.ScreenScaleH(posY))
    local color = self.Params["color"]

    if color ~= nil then
        surface.SetTextColor(color.r, color.g, color.b, color.a * alpha)
    else
        surface.SetTextColor(255, 255, 255)
    end

    surface.DrawText(entry.Key)
end

function PANEL:PaintIntroCredits(width, height)
    local curTime = CurTime()
    local posX = self.Params["posx"]
    local posY = self.Params["posy"]
    local i = 0
    local creditsSize = #self.Section

    while i < creditsSize do
        local len = 3

        if i + len > creditsSize then
            len = creditsSize - i
        end

        for n = 1, len do
            local entry = self.Section[i + n]
            if curTime < entry.startTime or curTime > entry.finishTime then continue end
            self:DrawCreditsEntry(entry, curTime, posX + 100, posY + ((n - 1) * 20))
        end

        i = i + len
    end
end

function PANEL:PaintOutroCredits(width, height)
    local section = self.Section
    local timeLeft = math.max(self.ScrollEndTime - CurTime(), 0)
    local elapsed = self.CreditsTime - timeLeft
    local scrollOffset = (elapsed / self.CreditsTime) * (self.TotalHeight + ScrH())
    local lineX = ScrW() / 2
    local lineY = ScrH()

    for k, v in pairs(section) do
        local sizeData = self.SizeData[k]
        local font = FONT_REMAP[v.Value] or v.Value
        surface.SetFont(font)
        surface.SetTextPos(lineX - (sizeData.w / 2), lineY - scrollOffset)
        local color = self.Params["color"]

        if color ~= nil then
            surface.SetTextColor(color.r, color.g, color.b, color.a)
        else
            surface.SetTextColor(255, 255, 255)
        end

        surface.DrawText(v.Key)
        lineY = lineY + sizeData.h + ROW_SPACING
    end

    self.ScrollY = self.ScrollY + (40 * FrameTime())
end

function PANEL:Paint(width, height)
    if self.CreditsType == CREDITS_TYPE_INTRO then
        self:PaintIntroCredits(width, height)
    elseif self.CreditsType == CREDITS_TYPE_OUTRO then
        self:PaintOutroCredits(width, height)
    end
end

vgui.Register("HudCredits", PANEL, "Panel")