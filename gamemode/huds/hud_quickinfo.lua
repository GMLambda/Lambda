-- Straight port from source-sdk-2013

local PANEL = {}

local QUICKINFO_EVENT_DURATION = 1.0
local QUICKINFO_BRIGHTNESS_FULL = 255
local QUICKINFO_BRIGHTNESS_DIM = 64
local QUICKINFO_FADE_IN_TIME = 0.5
local QUICKINFO_FADE_OUT_TIME = 2.0
local CLIP_PERC_THRESHOLD = 0.75
local HEALTH_WARNING_THRESHOLD = 25

local colorDngr = Color(255, 48, 0, 255)

surface.CreateFont("LambdaQuickInfo", {
    font = "HL2cross",
    antialias = true,
    size = util.ScreenScaleH(28),
    weight = 0,
    additive = true
})

-- Need to make this a global function
local function GetTextColor()
    local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")
    return Color(col.x, col.y, col.z, 255)
end

function PANEL:Init()
    self.m_ammoFade = 0.0
    self.m_healthFade = 0.0
    self.m_lastAmmo = 0.0
    self.m_lastHealth = 100
    self.m_warnAmmo = false
    self.m_warnHealth = false
    self.m_bFadedOut = false
    self.m_bDimmed = false
    self.m_fLastEventTime = 0.0

    self.m_iFont = "LambdaQuickInfo"
    surface.SetFont(self.m_iFont)

    self.m_leftEmpty = "{"
    self.m_rightEmpty = "}"
    self.m_leftFull = "["
    self.m_rightFull = "]"

    self.charW, self.charH = surface.GetTextSize(self.m_rightEmpty)
    self.bracketW, self.bracketH = surface.GetTextSize(self.m_leftFull)

    self:ParentToHUD()
    self:SetSize(ScrW(), ScrH())
end

function PANEL:Think()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local bFadeOut = false

    -- Zoomed in hack since we dont have IsZoomed
    if ply:GetInternalVariable("m_hZoomOwner") ~= NULL then
        bFadeOut = true
    end

    if self.m_bFadedOut ~= bFadeOut then
        self.m_bFadedOut = bFadeOut
        self.m_bDimmed = false
        if bFadeOut then
            self.m_AnimList = nil
            self:AlphaTo(0, 0.25, 0)
        else
            self.m_AnimList = nil
            self:AlphaTo(QUICKINFO_BRIGHTNESS_FULL, QUICKINFO_FADE_IN_TIME, 0.0 )
        end
    elseif not self.m_bFadedOut then
        if self:EventTimeElapsed() then
            if not self.m_bDimmed then
                self.m_bDimmed = true
                self.m_AnimList = nil
                self:AlphaTo(QUICKINFO_BRIGHTNESS_DIM, QUICKINFO_FADE_OUT_TIME, 0.0)
            end
        elseif self.m_bDimmed then
            self.m_bDimmed = false
            self.m_AnimList = nil
            self:AlphaTo(QUICKINFO_BRIGHTNESS_FULL, QUICKINFO_FADE_IN_TIME, 0.0)
        end
    end
end

function PANEL:UpdateEventTime()
    self.m_fLastEventTime = CurTime()
end

function PANEL:EventTimeElapsed()
    if (CurTime() - self.m_fLastEventTime) > QUICKINFO_EVENT_DURATION then
        return true
    end

    return false
end

function PANEL:DrawWarning(x, y, char, time)
    local scale = math.floor(math.abs(math.sin(CurTime() * 8)) * 128)

    if time <= (RealFrameTime() * 200) then
        if scale < 40 then
            time = 0.0
            return time
        else
            time = time + (RealFrameTime() * 200)
        end
    end

    time = time - (RealFrameTime() * 200)
    local caution = colorDngr
    caution.a = scale * 255

    surface.SetFont(self.m_iFont)
    surface.SetTextColor(caution)
    surface.SetTextPos(x, y)
    surface.DrawText(char)

    return time
end

function PANEL:DrawIconProgressChar(empty, full, x, y, w, h, perc, clr)
    surface.SetFont(self.m_iFont)

    local sx, sy = self:LocalToScreen(x, y)
    local sp = 1 - perc
    sp = math.Round(h * sp)

    surface.SetTextColor(clr)

    if sp > 0 then
        surface.SetTextPos(x, y)
        render.SetScissorRect(sx, sy, sx + w, sy + sp, true)
        surface.DrawText(empty)
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    if sp < h then
        surface.SetTextPos(x, y)
        render.SetScissorRect(sx, sy + sp, sx + w, sy + h, true)
        surface.DrawText(full)
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

local scalar = 138 / 255

function PANEL:Paint(w, h)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    if ply:InVehicle() then return end

    local cenX, cenY = w / 2, h / 2

    DisableClipping(true)

    local health = ply:Health()
    if health ~= self.m_lastHealth then
        self:UpdateEventTime()
        self.m_lastHealth = health
        if health <= HEALTH_WARNING_THRESHOLD then
            if not self.m_warnHealth then
                self.m_healthFade = 255
                self.m_warnHealth = true

                ply:EmitSound("HUDQuickInfo.LowHealth")
            end
        else
            self.m_warnHealth = false
        end
    end

    local ammo = wep:Clip1()
    if ammo ~= self.m_lastAmmo then
        self:UpdateEventTime()
        self.m_lastAmmo = ammo

        local ammoPerc = ammo / wep:GetMaxClip1()
        if wep:GetMaxClip1() > 1 and ammoPerc <= (1 - CLIP_PERC_THRESHOLD) then
            if self.m_warnAmmo == false then
                self.m_ammoFade = 255
                self.m_warnAmmo = true

                ply:EmitSound("HUDQuickInfo.LowAmmo")
            end
        else
            self.m_warnAmmo = false
        end
    end

    local sinScale = math.floor(math.abs(math.sin(CurTime() * 8)) * 128)

    if self.m_healthFade > 0.0 then
        self.m_healthFade = self:DrawWarning(cenX - self.bracketW * 2, cenY - self.bracketH / 2, self.m_leftFull, self.m_healthFade)
    else
        local healthPerc = health / ply:GetMaxHealth()
        healthPerc = math.Clamp(healthPerc, 0.0, 1.0)

        local healthClr = self.m_warnHealth and colorDngr or GetTextColor()

        if self.m_warnHealth then
            healthClr.a = 255 * sinScale
        else
            healthClr.a = 255 * scalar
        end

        self:DrawIconProgressChar(self.m_leftEmpty, self.m_leftFull, cenX - self.bracketW * 2, cenY - self.bracketH / 2, self.bracketW, self.bracketH, healthPerc, healthClr)
    end

    if self.m_ammoFade > 0.0 then
        self.m_ammoFade = self:DrawWarning(cenX + self.bracketW, cenY - self.bracketH / 2, self.m_rightFull, self.m_ammoFade)
    else
        local ammoPerc

        if wep:GetMaxClip1() <= 0 then
            ammoPerc = 1
        else
            ammoPerc = ammo / wep:GetMaxClip1()
        end

        local ammoClr = self.m_warnAmmo and colorDngr or GetTextColor()

        if self.m_warnAmmo then
            ammoClr.a = 255 * sinScale
        else
            ammoClr.a = 255 * scalar
        end

        self:DrawIconProgressChar(self.m_rightEmpty, self.m_rightFull, cenX + self.bracketW, cenY - self.bracketH / 2, self.bracketW, self.bracketH, ammoPerc, ammoClr)
    end

    DisableClipping(false)
end

vgui.Register("LQuickInfo", PANEL, "Panel")

