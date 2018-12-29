local PANEL = {}
local colWHITE = Color(255, 255, 255, 195)

Derma_Install_Convar_Functions(PANEL)

function PANEL:Init()

	self.Settings = GAMEMODE:GetGameTypeData("Settings") or {}
	local y, x, n = 5, 5, 0

	for k, v in pairs(self.Settings) do
		if v.value_type == "int" or v.value_type == "float" and v.Category == "SERVER" then
			if v.extra and v.extra.value_type == "bool" then
				self:AddCheckOption(x + 130, y + 6, k, v)
			end
			self:AddIntOption(x, y, k, v)
			y = y + 25
			n = n + 1
		end
	end
	local _y = (25 * n) + 10
	for k, v in pairs(self.Settings) do
		if v.value_type == "bool" and v.Category == "SERVER" then
			self:AddCheckOption(x, _y, k, v)
			_y = _y + 20
			n = n + 1
		end
	end
	for k, v in pairs(self.Settings) do
		if v.value_type == "string"  and v.Category == "SERVER" then
			self:AddComboOption(x, _y, k, v)
			_y = _y + 20
		end
	end

end

function PANEL:AddIntOption(x, y, id, tbl)

	local w, h = 40, 20
	self.Settings[id].numw = self:Add("DNumberWang")
	self.Settings[id].numw:SetPos(x, 5 + y)
	self.Settings[id].numw:SetSize(w, h)
	self.Settings[id].numw:SetCursorColor(colWHITE)
	self.Settings[id].numw:SetMinMax(-1, tbl.maxv)
	self.Settings[id].numw:SetValue(tbl.value)
	self.Settings[id].numw:SetVisible(true)

	self.Settings[id].numw.lbl = self:Add("DLabel")
	self.Settings[id].numw.lbl:SetPos(w + 10, y + 7)
	self.Settings[id].numw.lbl:SetTextColor(colWHITE)
	self.Settings[id].numw.lbl:SetText(tbl.info)
	self.Settings[id].numw.lbl:SizeToContents()
	self.Settings[id].numw.lbl:SetVisible(true)

	local function Update(id, v)
		self.Settings[id].value = tonumber(v)
		if tbl.extra then
			self.Settings[id].extra.cached = tonumber(v)
		end
	end
	self.Settings[id].numw.OnValueChanged = function(self, v)
		GAMEMODE:ChangeAdminConfiguration(id, v)
		Update(id, v)
	end

end

function PANEL:AddComboOption(x, y, id, tbl)

	self.cb = self:Add("DComboBox")
	self.cb:SetPos(x, y)
	self.cb:SetTextColor(colWHITE)
	self.cb:SetText(tbl.info)
	self.cb:SetSize(100, 20)
	self.cb:SetSortItems(false)

	self.cb.lbl = self:Add("DLabel")
	self.cb.lbl:SetPos(110, y)
	self.cb.lbl:SetTextColor(colWHITE)
	self.cb.lbl:SetText(tbl.info)

	for k, v in pairs(tbl.choices) do
		local text = tbl.choices_text(v)
		self.cb:AddChoice(text, v, tbl.GetDifficulty() == v)
	end

	function self.cb:OnSelect(idx, val, data)
		GAMEMODE:ChangeAdminConfiguration(id,data)
	end

end

function PANEL:AddCheckOption(x, y, id, tbl)

	self.checkb = self:Add("DCheckBoxLabel")
	self.checkb:SetPos(x, y)
	self.checkb:SetText(tbl.info)
	self.checkb:SizeToContents()
	self.checkb.extra = false

	if not tbl.extra then
		self.checkb:SetConVar("lambda_" .. id)
	else
		self.checkb:SetText(tbl.extra.info)
		self.checkb:SetValue(tbl.extra.value)
		self.checkb.extra = true
		tbl.extra.cached = tbl.value
	end

	local function Toggled(b)
		if b then
			self.Settings[id].numw:SetEnabled(false)
			self.Settings[id].numw:SetEditable(false)
		else
			self.Settings[id].numw:SetEnabled(true)
			self.Settings[id].numw:SetEditable(true)
		 end
	end

	function self.checkb:OnChange(val)
		if val then val = "1" else val = "0" end
			if tbl.extra and val == "1" then
				Toggled(true)
				GAMEMODE:ChangeAdminConfiguration(id, tostring(0))
			elseif tbl.extra and val == "0" then
				Toggled(false)
				GAMEMODE:ChangeAdminConfiguration(id, tbl.extra.cached)
			else
			GAMEMODE:ChangeAdminConfiguration(id, val)
			end
	end

end
vgui.Register("LambdaAdminPanel", PANEL, "DScrollPanel")