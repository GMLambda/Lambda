local PANEL = {}
local colWHITE = Color(255, 255, 255, 195)
Derma_Install_Convar_Functions(PANEL)

-- This is in dire need of a rewrite but we'll leave it for now
function PANEL:Init()
    self:Dock(FILL)
    self:DockPadding(0, 0, 22, 0)
    self.Settings = {}
    local availableSettings = GAMEMODE:GetSettingsTable() or {}
    local y, x, n = 5, 5, 0

    for k, v in pairs(availableSettings) do
        if v.Type == "int" or v.Type == "float" and v.Category == "SERVER" then
            if v.Extra ~= nil and v.Extra.Type ~= nil and v.Extra.Type == "combo" then continue end
            self:AddIntOption(x, y, k, v)
            self:AddDesc(x, y + 8, "- " .. v.Description)
            y = y + 57
            n = n + 1
        end
    end

    local _y = (57 * n) + 10

    for k, v in pairs(availableSettings) do
        if v.Type == "bool" and v.Category == "SERVER" then
            self:AddCheckOption(x, _y, k, v)
            self:AddDesc(x, _y, "- " .. v.Description)
            _y = _y + 50
            n = n + 1
        end
    end

    for k, v in pairs(availableSettings) do
        if v.Extra ~= nil and v.Extra.Type == "combo" and v.Category == "SERVER" then
            self:AddComboOption(x, _y, k, v)
            self:AddDesc(x, _y, "- " .. v.Description)
            _y = _y + 50
        end
    end
end

function PANEL:OnClose()
    self.Settings = {}
end

function PANEL:AddDesc(x,y, help)
    local tlbl = self:Add("DTextEntry")
    tlbl:SetPos(x, y + 22)
    tlbl:SetFont("DefaultSmall")
    tlbl:SetEditable(false)
    tlbl:SetText(help)
    tlbl:SetSize(310, 50)
    tlbl:SetMultiline(true)
    tlbl:SetPaintBackground(false)
end

function PANEL:AddRevertButton(x, y, id)
    local btn = self:Add("DImageButton")
    btn:SetPos(x, y)
    btn:SetImage("icon16/arrow_undo.png")
    btn:SizeToContents()
    btn:SetTooltip("Revert setting")
    return btn
end

function PANEL:AddIntOption(x, y, id, setting)
    local w, h = 40, 20
    local pnl = self:Add("DNumberWang")
    pnl:SetPos(w + 240, 7 + y)
    pnl:SetSize(w, h)
    pnl:SetCursorColor(colWHITE)
    local minVal = 0
    local maxValue = 0xFFFFFFFF

    if setting.Clamp ~= nil then
        if setting.Clamp.Min ~= nil then
            minVal = setting.Clamp.Min
        end

        if setting.Clamp.Max ~= nil then
            maxValue = setting.Clamp.Max
        end
    end

    pnl:SetMinMax(minVal, maxValue)
    pnl:SetVisible(true)
    pnl:SetValue(setting:GetValue())
    pnl.lbl = self:Add("DLabel")
    pnl.lbl:SetPos(x, y + 7)
    pnl.lbl:SetTextColor(colWHITE)
    pnl.lbl:SetFont("CreditsText")
    pnl.lbl:SetTextColor(Color(255, 147, 30, 190))
    pnl.lbl:SetText(setting.NiceName)
    pnl.lbl:SizeToContents()
    pnl.lbl:SetVisible(true)

    if setting:GetValue() ~= tonumber(setting.CVar:GetDefault()) then
        local revert = self:AddRevertButton(280 - 20, y + 10)
        revert.DoClick = function(slf)
            GAMEMODE:ChangeAdminConfiguration(id, setting.CVar:GetDefault())
            slf:Remove()
            pnl:SetValue(setting.CVar:GetDefault())
        end
    end
    pnl.OnValueChanged = function(this, v)
        GAMEMODE:ChangeAdminConfiguration(id, v)
    end

    self.Settings[id] = pnl
end

function PANEL:AddComboOption(x, y, id, setting)
    local pnl = self:Add("DComboBox")
    pnl:SetPos(220, y)
    pnl:SetTextColor(colWHITE)
    pnl:SetText(setting.NiceName)
    pnl:SetSize(100, 20)
    pnl:SetSortItems(false)
    pnl.lbl = self:Add("DLabel")
    pnl.lbl:SetPos(x, y)
    pnl.lbl:SetTextColor(colWHITE)
    pnl.lbl:SetFont("CreditsText")
    pnl.lbl:SetTextColor(Color(255, 147, 30, 190))
    pnl.lbl:SetText(setting.NiceName)
    pnl.lbl:SizeToContents()

    for k, v in pairs(setting.Extra.Choices) do
        local isSelected = tostring(setting:GetValue()) == tostring(k)
        pnl:AddChoice(v, k, isSelected)
    end
    if setting:GetValue() ~= tonumber(setting.CVar:GetDefault()) then
        local revert = self:AddRevertButton(205 - 20, y)
        revert.DoClick = function(slf)
            GAMEMODE:ChangeAdminConfiguration(id, setting.CVar:GetDefault())
            slf:Remove()
            pnl:ChooseOptionID(tonumber(setting.CVar:GetDefault()) + 1)
        end
    end

    pnl.OnSelect = function(this, index, value, data)
        GAMEMODE:ChangeAdminConfiguration(id, data)
    end

    self.Settings[id] = pnl
end

function PANEL:AddCheckOption(x, y, id, setting)
    local pnl = self:Add("DCheckBoxLabel")
    pnl:SetPos(305, y)
    pnl:SetText("")
    pnl:SetTextColor(Color(255, 147, 30, 190))
    pnl:SizeToContents()
    pnl:SetValue(setting:GetValue())

    pnl.lbl = self:Add("DLabel")
    pnl.lbl:SetPos(x, y)
    pnl.lbl:SetText(setting.NiceName)
    pnl.lbl:SetFont("CreditsText")
    pnl.lbl:SetTextColor(Color(255, 147, 30, 190))
    pnl.lbl:SizeToContents()

    if setting:GetValue() ~= tobool(setting.CVar:GetDefault()) then
        local revert = self:AddRevertButton(305 - 20, y)
        revert.DoClick = function(slf)
            GAMEMODE:ChangeAdminConfiguration(id, setting.CVar:GetDefault())
            slf:Remove()
            pnl:SetValue(setting.CVar:GetDefault())
        end
    end
    pnl.OnChange = function(this, val)
        if val then
            val = "1"
        else
            val = "0"
        end
        GAMEMODE:ChangeAdminConfiguration(id, val)
    end

    self.Settings[id] = pnl
end

vgui.Register("LambdaAdminPanel", PANEL, "DScrollPanel")