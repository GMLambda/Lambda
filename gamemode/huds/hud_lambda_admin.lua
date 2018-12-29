local PANEL = {}
local colWHITE = Color(255, 255, 255, 195)

Derma_Install_Convar_Functions(PANEL)

function PANEL:Init()

	self.Settings = GAMEMODE:GetGameTypeData("Settings") or {}
	local y = 5
	local n = 0

	for k, v in pairs(self.Settings) do
		if v.value_type == "int" or v.value_type == "float" and v.Category == "SERVER" then
			self:AddIntOption(y, k, v)
			y = y + 25
			n = n + 1
		end
	end
	local _y = (25 * n) + 10
	for k, v in pairs(self.Settings) do
		if v.value_type == "bool" and v.Category == "SERVER" then
			self:AddCheckOption(_y, k, v)
			_y = _y + 20
			n = n + 1
		end
	end
	for k, v in pairs(self.Settings) do
		if v.value_type == "string"  and v.Category == "SERVER" then
			self:AddComboOption(_y, k, v)
			_y = _y + 20
		end
	end

end

function PANEL:AddIntOption(y, id, tbl)

	local w, h = 40, 20
	self.numw = self:Add("DNumberWang")
	self.numw:SetPos(5, 5 + y)
	self.numw:SetSize(w, h)
	self.numw:SetCursorColor(colWHITE)
	self.numw:SetMinMax(-1, tbl.maxv)
	self.numw:SetValue(tbl.value)
	self.numw:SetVisible(true)

	self.numw.lbl = self:Add("DLabel")
	self.numw.lbl:SetPos(w + 10, y + 7)
	self.numw.lbl:SetTextColor(colWHITE)
	self.numw.lbl:SetText(tbl.info)
	self.numw.lbl:SizeToContents()
	self.numw.lbl:SetVisible(true)

	local function Update(id, v)
		self.Settings[id].value = tonumber(v)
	end

	function self.numw:OnValueChanged(v)
		GAMEMODE:ChangeAdminConfiguration(id, v)
		Update(id, v)
	end

end

function PANEL:AddComboOption(y, id, tbl)

	self.cb = self:Add("DComboBox")
	self.cb:SetPos(5, y)
	self.cb:SetTextColor(colWHITE)
	self.cb:SetText(tbl.info)
	self.cb:SetSize(100, 20)
	self.cb:SetSortItems(false)

	self.cb.lbl = self:Add("DLabel")
	self.cb.lbl:SetPos(110, y)
	self.cb.lbl:SetTextColor(colWHITE)
	self.cb.lbl:SetText(tbl.info)

	for k, v in pairs(GAMEMODE:GetDifficulties()) do
		local choice = GAMEMODE:GetDifficultyText(v)
		self.cb:AddChoice(choice, v, GAMEMODE:GetDifficulty() == v)
	end

	function self.cb:OnSelect(idx, val, data)
		GAMEMODE:ChangeAdminConfiguration(id,tostring(data))
	end

end

function PANEL:AddCheckOption(y, id, tbl)

	self.checkb = self:Add("DCheckBoxLabel")
	self.checkb:SetPos(5, y)
	self.checkb:SetText(tbl.info)
	self.checkb:SizeToContents()
	self.checkb:SetConVar("lambda_" .. id)

	function self.checkb:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration(id, val)
	end

end
vgui.Register("LambdaAdminPanel", PANEL, "DScrollPanel")