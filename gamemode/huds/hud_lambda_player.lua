local border = 4
local border_w = 5
local matHover = Material("gui/ps_hover.png", "nocull")
local boxHover = GWEN.CreateTextureBorder(border, border, 64 - border * 2, 64 - border * 2, border_w, border_w, border_w, border_w, matHover)

local PANEL = {}

cvars.AddChangeCallback("lambda_playermdl", function()
    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end, "LambdaPlayerModelChanged")

cvars.AddChangeCallback("lambda_playermdl_skin", function()
    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end, "LambdaPlayerModelSkinChanged")

cvars.AddChangeCallback("lambda_playermdl_bodygroup", function()
    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end, "LambdaPlayerModelBGChanged")

function PANEL:Init()
    local sheetPanel = self:Add("DPropertySheet")
    sheetPanel:Dock(FILL)

    local mdlPanel = sheetPanel:Add("DPanel")
    mdlPanel:Dock(FILL)

    local searchBar = mdlPanel:Add("DTextEntry")
    searchBar:Dock(TOP)
    searchBar:DockMargin(0, 0, 0, 8)
    searchBar:SetUpdateOnType(true)
    searchBar:SetPlaceholderText("Search for model")
    searchBar:SetPlaceholderColor(Color(255, 255, 255, 255))

    local mdlListPanel = mdlPanel:Add("DPanelSelect")
    mdlListPanel:Dock(FILL)

    local modelTbl = GAMEMODE:GetAvailablePlayerModels()
    for name, v in pairs(modelTbl) do
        local item = mdlListPanel:Add("SpawnIcon")
        item:SetModel(v)
        item:SetSize(64, 64)
        item:SetTooltip(name)
        item.plymdl = name
        item.mdlPath = player_manager.TranslatePlayerModel(name)
        item.PaintOver = function(this, w, h)
            if this.OverlayFade > 0 then
                boxHover(0, 0, w, h, Color(255, 255, 255, this.OverlayFade))
            end
            this:DrawSelections()
        end
        mdlListPanel:AddPanel(item, {lambda_playermdl = name})
    end

    searchBar.OnValueChange = function(s, str)
        for i, pnl in pairs(mdlListPanel:GetItems()) do
            if not pnl.plymdl:find(str, 1, true) and not pnl.mdlPath:find(str, 1, true) then
                pnl:SetVisible(false)
            else
                pnl:SetVisible(true)
            end
        end
        mdlListPanel:InvalidateLayout()
    end

    sheetPanel:AddSheet("MODEL", mdlPanel)

    local bgPanel = sheetPanel:Add("DPanel")

    local bgList = bgPanel:Add("DPanelList")
    bgList:Dock(FILL)
    bgList:EnableVerticalScrollbar(true)

    local bgTab = sheetPanel:AddSheet("BODYGROUPS", bgPanel)

    local function SetMdlChanges(pnl, val)
        if pnl.type == "skin" then
            lambda_playermdl_skin:SetString(math.Round(val))
        end

        if pnl.type == "bg" then
            local str = string.Explode(" ", lambda_playermdl_bodygroup:GetString())
            if #str < pnl.n + 1 then
                for i = 1, pnl.n + 1 do
                    str[i] = str[i] or 0 end
            end
            str[pnl.n + 1] = math.Round(val)
            lambda_playermdl_bodygroup:SetString(table.concat(str, " "))
        end
    end

    local function RebuildBgPnl()
        bgList:Clear()
        -- Slight delay to make sure model is set on entity
        timer.Simple(0.1, function()
            bgTab.Tab:SetVisible(false)

            local ply = LocalPlayer()
            local mdlStr = player_manager.TranslatePlayerModel(lambda_playermdl:GetString())
            local numSkins = NumModelSkins(mdlStr) - 1
            if numSkins > 0 then
                local slider = vgui.Create("DNumSlider")
                slider:Dock(TOP)
                slider:DockMargin(20, 0, 0, 0)
                slider:SetText("SKIN")
                slider:SetSkin("Lambda")
                slider:SetTall(30)
                slider:SetDecimals(0)
                slider:SetMax(numSkins)
                slider:SetValue(lambda_playermdl_skin:GetString())
                slider:GetTextArea():SetFont("TargetIDSmall")
                slider:GetTextArea():SetTextColor(Color(255, 255, 255, 255))
                slider.Label:SetFont("TargetIDSmall")
                slider.Label:SetTextColor(Color(255, 255, 255, 255))
                slider.type = "skin"
                slider.OnValueChanged = SetMdlChanges

                bgList:AddItem(slider)
                bgTab.Tab:SetVisible(true)
            end

            local bgroups = string.Explode(" ", lambda_playermdl_bodygroup:GetString())
            for k = 0, ply:GetNumBodyGroups() - 1 do
                if ply:GetBodygroupCount(k) <= 1 then continue end

                local bgsldr = vgui.Create("DNumSlider")
                bgsldr:Dock(TOP)
                bgsldr:DockMargin(20, 0, 0, 0)
                bgsldr:SetText(string.upper(ply:GetBodygroupName(k)))
                bgsldr:SetSkin("Lambda")
                bgsldr:SetTall(30)
                bgsldr:SetDecimals(0)
                bgsldr:SetMax(ply:GetBodygroupCount(k) - 1)
                bgsldr:SetValue(bgroups[k + 1] or 0)
                bgsldr:GetTextArea():SetFont("TargetIDSmall")
                bgsldr:GetTextArea():SetTextColor(Color(255, 255, 255, 255))
                bgsldr.Label:SetFont("TargetIDSmall")
                bgsldr.Label:SetTextColor(Color(255, 255, 255, 255))
                bgsldr.type = "bg"
                bgsldr.n = k
                bgsldr.OnValueChanged = SetMdlChanges

                bgList:AddItem(bgsldr)
                bgTab.Tab:SetVisible(true)
            end
            sheetPanel.tabScroller:InvalidateLayout()
        end)
    end

    function RebuildPanel()
        RebuildBgPnl()
    end

    RebuildPanel()

    function mdlListPanel:OnActivePanelChanged(old, new)
        if old != new then
            lambda_playermdl_skin:SetString("0")
            lambda_playermdl_bodygroup:SetString("0")
        end
        timer.Simple(0.1, function()
            RebuildPanel()
        end)
    end
end

vgui.Register("LambdaPlayerPanel", PANEL, "DPanel")