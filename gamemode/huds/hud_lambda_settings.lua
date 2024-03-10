local PANEL = {}
local COLOR_PANEL_W = 280
local COLOR_PANEL_H = 206

function PANEL:Init()
    local sheetSettings = self:Add("DPropertySheet")
    sheetSettings:Dock(LEFT)
    sheetSettings:SetSize(375 - 10, H)

    if LocalPlayer():IsAdmin() or LocalPlayer():IsSuperAdmin() then
        local PanelAdmin = sheetSettings:Add("LambdaAdminPanel")
        sheetSettings:AddSheet("SERVER", PanelAdmin)
        sheetSettings["Items"][1]["Tab"]:SetTextColor(Color(245, 10, 0, 200))
    end

    local PanelCrosshair = sheetSettings:Add("LambdaCrosshairPanel")
    sheetSettings:AddSheet("CROSSHAIR", PanelCrosshair)
    local PanelPostFx = sheetSettings:Add("LambdaFXPanel")
    sheetSettings:AddSheet("EFFECTS", PanelPostFx)
    local PanelColor = sheetSettings:Add("LambdaColorPanel")
    PanelColor:SetPaintBackground(false)
    sheetSettings:AddSheet("COLORS", PanelColor)
end

vgui.Register("LambdaSettingsPanel", PANEL, "DPanel")
local PANEL_CROSSHAIR = {}

function PANEL_CROSSHAIR:Init()
    local dyn_cross = self:Add("DCheckBoxLabel")
    dyn_cross:SetPos(5, 5)
    dyn_cross:SetText("Enhanced Crosshair")
    dyn_cross:SetConVar("lambda_crosshair")
    dyn_cross:SetValue(cvars.Number("lambda_crosshair"))
    local bgColor = Color(0, 0, 0, 255)
    local chPreview = self:Add("DImage")
    chPreview:SetPos(180, 135)
    chPreview:SetSize(128, 128)
    chPreview:SetMaterial(GAMEMODE:GetCrosshairMaterial(128, 128, bgColor), true)
    chPreview:SetPaintBorderEnabled(true)
    local actualPaint = chPreview.Paint

    chPreview.Paint = function()
        chPreview:SetMaterial(GAMEMODE:GetCrosshairMaterial(128, 128, bgColor), true)
        actualPaint(chPreview)
    end

    local function UpdateCrosshairPreview()
        chPreview:SetMaterial(GAMEMODE:GetCrosshairMaterial(128, 128, bgColor), true)
    end

    local chSize = self:Add("DNumSlider")
    chSize:SetPos(5, 30)
    chSize:SetSize(300, 20)
    chSize:SetText("Size")
    chSize:SetMin(0)
    chSize:SetMax(128)
    chSize:SetDecimals(0)
    chSize:SetValue(cvars.Number("lambda_crosshair_size"))

    function chSize:OnValueChanged(val)
        lambda_crosshair_size:SetInt(tonumber(val))
        UpdateCrosshairPreview()
    end

    local chWidth = self:Add("DNumSlider")
    chWidth:SetPos(5, 55)
    chWidth:SetSize(300, 20)
    chWidth:SetText("Width")
    chWidth:SetMin(0)
    chWidth:SetMax(64)
    chWidth:SetDecimals(0)
    chWidth:SetValue(cvars.Number("lambda_crosshair_width"))

    function chWidth:OnValueChanged(val)
        lambda_crosshair_width:SetInt(tonumber(val))
        UpdateCrosshairPreview()
    end

    local chSpace = self:Add("DNumSlider")
    chSpace:SetPos(5, 80)
    chSpace:SetSize(300, 20)
    chSpace:SetText("Space")
    chSpace:SetMin(0)
    chSpace:SetMax(24)
    chSpace:SetDecimals(0)
    chSpace:SetValue(cvars.Number("lambda_crosshair_space"))

    function chSpace:OnValueChanged(val)
        lambda_crosshair_space:SetInt(tonumber(val))
        UpdateCrosshairPreview()
    end

    local labelColor = self:Add("DLabel")
    labelColor:SetPos(5, 105)
    labelColor:SetText("Color")
    local labelR = self:Add("DLabel")
    labelR:SetPos(135, 105)
    labelR:SetText("R")
    local crosshairColor = GAMEMODE:GetCrosshairColor()
    local numCrosshairR = self:Add("DNumberWang")
    numCrosshairR:SetSize(36, 20)
    numCrosshairR:SetPos(150, 105)
    numCrosshairR:SetMin(0)
    numCrosshairR:SetMax(255)
    numCrosshairR:SetDecimals(0)
    numCrosshairR:SetValue(crosshairColor.r)

    function numCrosshairR:OnValueChange(val)
        local color = GAMEMODE:GetCrosshairColor()
        color.r = math.Clamp(tonumber(val) or 0, 0, 255)
        GAMEMODE:SetCrosshairColor(color)
        UpdateCrosshairPreview()
    end

    local labelG = self:Add("DLabel")
    labelG:SetPos(195, 105)
    labelG:SetText("G")
    local numCrosshairG = self:Add("DNumberWang")
    numCrosshairG:SetSize(36, 20)
    numCrosshairG:SetPos(210, 105)
    numCrosshairG:SetMin(0)
    numCrosshairG:SetMax(255)
    numCrosshairG:SetDecimals(0)
    numCrosshairG:SetValue(crosshairColor.g)

    function numCrosshairG:OnValueChange(val)
        local color = GAMEMODE:GetCrosshairColor()
        color.g = math.Clamp(tonumber(val) or 0, 0, 255)
        GAMEMODE:SetCrosshairColor(color)
        UpdateCrosshairPreview()
    end

    local labelB = self:Add("DLabel")
    labelB:SetPos(255, 105)
    labelB:SetText("B")
    local numCrosshairB = self:Add("DNumberWang")
    numCrosshairB:SetSize(36, 20)
    numCrosshairB:SetPos(270, 105)
    numCrosshairB:SetMin(0)
    numCrosshairB:SetMax(255)
    numCrosshairB:SetDecimals(0)
    numCrosshairB:SetValue(crosshairColor.b)

    function numCrosshairB:OnValueChange(val)
        local color = GAMEMODE:GetCrosshairColor()
        color.b = math.Clamp(tonumber(val) or 0, 0, 255)
        GAMEMODE:SetCrosshairColor(color)
        UpdateCrosshairPreview()
    end

    local chAdaptive = self:Add("DCheckBoxLabel")
    chAdaptive:SetPos(5, 135)
    chAdaptive:SetText("Adaptive Colors")
    chAdaptive:SetConVar("lambda_crosshair_adaptive")
    chAdaptive:SetValue(cvars.Number("lambda_crosshair_adaptive"))
    local chDynamic = self:Add("DCheckBoxLabel")
    chDynamic:SetPos(5, 165)
    chDynamic:SetText("Dynamic")
    chDynamic:SetConVar("lambda_crosshair_dynamic")
    chDynamic:SetValue(cvars.Number("lambda_crosshair_dynamic"))
end

vgui.Register("LambdaCrosshairPanel", PANEL_CROSSHAIR, "DPanel")
local PANEL_FX = {}

local GLOW_CHOICES = {
    [0] = "None",
    [1] = "Projected Texture + Dynamic Light (Highest performance cost)",
    [2] = "Projected Texture (High performance cost)",
    [3] = "Dynamic Light (Low performance cost)",
}

function PANEL_FX:Init()
    local postproc = self:Add("DCheckBoxLabel")
    postproc:SetPos(5, 5)
    postproc:SetText("Post Processing (Custom effects)")
    postproc:SizeToContents()
    postproc:SetConVar("lambda_postprocess")
    postproc:SetValue(cvars.Number("lambda_postprocess"))
    local gore = self:Add("DCheckBoxLabel")
    gore:SetPos(5, 25)
    gore:SetText("Gore")
    gore:SizeToContents()
    gore:SetConVar("lambda_gore")
    gore:SetValue(cvars.Number("lambda_gore"))
    local physcannon_glow = self:Add("DComboBox")
    physcannon_glow:SetSize(120, 20)
    physcannon_glow:SetSortItems(false)
    physcannon_glow:SetTextColor(Color(255, 255, 255))
    physcannon_glow:SetPos(5, 45)
    local selectedGlow = cvars.Number("lambda_physcannon_glow")
    for k, v in pairs(GLOW_CHOICES) do
        physcannon_glow:AddChoice(v, k, selectedGlow == k)
    end
    physcannon_glow.OnSelect = function(_, index, value, data)
        physcannon_glow:SetValue(value)
        -- TODO: Refactor me, we have to do this because the cvar might not exist earlier on.
        local physcannon_glow_cvar = GetConVar("lambda_physcannon_glow")
        physcannon_glow_cvar:SetInt(data)
    end
    local label = self:Add("DLabel")
    label:SetPos(134, 47)
    label:SetText("Physcannon Light")
    label:SizeToContents()
end

vgui.Register("LambdaFXPanel", PANEL_FX, "DPanel")
local PANEL_COLOR = {}

function PANEL_COLOR:Init()
    local colOptions = {
        ["ply"] = "Player",
        ["wep"] = "Weapon",
        ["hudBG"] = "HUD Background",
        ["hudTXT"] = "HUD Text"
    }

    local colTabs = {}
    local colMixers = {}

    local function strColorToVector(str)
        local color = string.Explode(" ", str)

        return Color(color[1], color[2], color[3])
    end

    local function retrieveColor(k)
        if k == "hudBG" then
            return strColorToVector(lambda_hud_bg_color:GetString())
        else
            return strColorToVector(lambda_hud_text_color:GetString())
        end
    end

    local function retrieveVec(k)
        if k == "ply" then
            return LocalPlayer():GetPlayerColor()
        else
            return LocalPlayer():GetWeaponColor()
        end
    end

    local colSheet = self:Add("DPropertySheet")
    colSheet:Dock(FILL)

    for k, v in pairs(colOptions) do
        colTabs[k] = vgui.Create("DPanel", colSheet)
        colTabs[k]:SetPaintBackground(false)
        colMixers[k] = vgui.Create("DColorMixer", colTabs[k])
        colMixers[k]:SetPos(0, 0)
        colMixers[k]:SetSize(COLOR_PANEL_W, COLOR_PANEL_H)
        colMixers[k]:SetAlphaBar(false)
        colMixers[k]:SetPalette(false)
        colSheet:AddSheet(string.upper(v), colTabs[k])
    end

    for k, v in pairs(colMixers) do
        if k == "hudTXT" or k == "hudBG" then
            v:SetColor(retrieveColor(k))
        else
            v:SetVector(retrieveVec(k))
        end

        v.ValueChanged = function()
            if k == "hudTXT" or k == "hudBG" then
                self:UpdateSettings(k, v:GetColor())
            else
                self:UpdateSettings(k, v:GetVector())
            end
        end
    end
end

function PANEL_COLOR:UpdateSettings(val, color)
    if val == "ply" then
        LocalPlayer():SetPlayerColor(color)
        lambda_player_color:SetString(util.TypeToString(color))
    elseif val == "wep" then
        LocalPlayer():SetWeaponColor(color)
        lambda_weapon_color:SetString(util.TypeToString(color))
    elseif val == "hudBG" then
        lambda_hud_bg_color:SetString(string.FromColor(color))
    elseif val == "hudTXT" then
        lambda_hud_text_color:SetString(string.FromColor(color))
    end

    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end

vgui.Register("LambdaColorPanel", PANEL_COLOR, "DPanel")