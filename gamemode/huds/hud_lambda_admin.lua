local PANEL = {}
local colWHITE = Color(255, 255, 255, 195)
Derma_Install_Convar_Functions(PANEL)

function PANEL:Init()
	self:Dock(FILL)
	self:DockPadding(0, 0, 22, 0)
	self.Settings = {}

	local availableSettings = GAMEMODE:GetSettingsTable() or {}

	local y, x, n = 5, 5, 0

	for k, v in pairs(availableSettings) do
		if v.Type == "int" or v.Type == "float" and v.Category == "SERVER" then
			if v.Extra ~= nil and v.Extra.Type ~= nil and v.Extra.Type == "combo" then
				continue
			end
			self:AddIntOption(x, y, k, v)
			y = y + 25
			n = n + 1
		end
	end

	local _y = (25 * n) + 10

	for k, v in pairs(availableSettings) do
		if v.Type == "bool" and v.Category == "SERVER" then
			self:AddCheckOption(x, _y, k, v)
			_y = _y + 20
			n = n + 1
		end
	end

	for k, v in pairs(availableSettings) do
		if v.Extra ~= nil and v.Extra.Type == "combo" and v.Category == "SERVER" then
			self:AddComboOption(x, _y, k, v)
			_y = _y + 25
		end
	end
end

function PANEL:OnClose()
	self.Settings = {}
end

function PANEL:AddIntOption(x, y, id, setting)
	local w, h = 40, 20

	local pnl = self:Add("DNumberWang")
	pnl:SetPos(x, 5 + y)
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
	pnl.lbl:SetPos(w + 10, y + 7)
	pnl.lbl:SetTextColor(colWHITE)
	pnl.lbl:SetText(setting.Description)
	pnl.lbl:SizeToContents()
	pnl.lbl:SetVisible(true)

	-- For options with some more information on them
	if setting.HelpText then
		pnl.tp = self:Add("DPanel")
		pnl.tp:SetPos(x, 5 + y)
		pnl.tp:SetSize(w + pnl.lbl:GetWide() + 25, y)
		pnl.tp:SetTooltip(setting.HelpText)

		pnl.ht = self:Add("DImage")
		pnl.ht:SetPos(w + pnl.lbl:GetWide() + 15, y + 9)
		pnl.ht:SetImage("lambda/icons/info.png")
		pnl.ht:SetSize(10, 10)
		pnl.ht:SetImageColor(Color(105, 105, 225, 195))
		pnl.ht:SetVisible(true)
	end

	pnl.OnValueChanged = function(self, v)
		GAMEMODE:ChangeAdminConfiguration(id, v)
	end

	self.Settings[id] = pnl

end

function PANEL:AddComboOption(x, y, id, setting)

	local pnl = self:Add("DComboBox")
	pnl:SetPos(x, y)
	pnl:SetTextColor(colWHITE)
	pnl:SetText(setting.Description)
	pnl:SetSize(100, 20)
	pnl:SetSortItems(false)

	pnl.lbl = self:Add("DLabel")
	pnl.lbl:SetPos(110, y + 3)
	pnl.lbl:SetTextColor(colWHITE)
	pnl.lbl:SetText(setting.Description)
	pnl.lbl:SizeToContents()

	for k, v in pairs(setting.Extra.Choices) do
		local isSelected = tostring(setting:GetValue()) == tostring(k)
		pnl:AddChoice(v, k, isSelected)
	end

	pnl.OnSelect = function(self, index, value, data)
		GAMEMODE:ChangeAdminConfiguration(id, data)
	end

	self.Settings[id] = pnl

end

function PANEL:AddCheckOption(x, y, id, setting)
	local pnl = self:Add("DCheckBoxLabel")
	pnl:SetPos(x, y)
	pnl:SetText(setting.Description)
	pnl:SizeToContents()
	pnl:SetValue(setting:GetValue())

	pnl.OnChange = function(self, val)
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