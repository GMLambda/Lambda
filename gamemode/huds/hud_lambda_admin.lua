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
		if v.value_type == "string"  and v.extra.value_type == "combo" and v.Category == "SERVER" then
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

	self.Settings[id].cb = self:Add("DComboBox")
	self.Settings[id].cb:SetPos(x, y)
	self.Settings[id].cb:SetTextColor(colWHITE)
	self.Settings[id].cb:SetText(tbl.info)
	self.Settings[id].cb:SetSize(100, 20)
	self.Settings[id].cb:SetSortItems(false)

	self.Settings[id].cb.lbl = self:Add("DLabel")
	self.Settings[id].cb.lbl:SetPos(110, y)
	self.Settings[id].cb.lbl:SetTextColor(colWHITE)
	self.Settings[id].cb.lbl:SetText(tbl.info)

	for k, v in pairs(tbl.extra.options) do
		self.Settings[id].cb:AddChoice(v, k, GAMEMODE:CallGameTypeFunc(tbl.extra.current) == k)
	end

	self.Settings[id].cb.OnSelect = function(self, index, value, data)
		GAMEMODE:ChangeAdminConfiguration(id, data)
	end

end

function PANEL:AddCheckOption(x, y, id, tbl)

	self.Settings[id].checkb = self:Add("DCheckBoxLabel")
	self.Settings[id].checkb:SetPos(x, y)
	self.Settings[id].checkb:SetText(tbl.info)
	self.Settings[id].checkb:SizeToContents()
	self.Settings[id].checkb.extra = false

	if not tbl.extra then
		self.Settings[id].checkb:SetConVar("lambda_" .. id)
	else
		self.Settings[id].checkb:SetText(tbl.extra.info)
		self.Settings[id].checkb:SetValue(tbl.extra.value)
		self.Settings[id].checkb.extra = true
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

	self.Settings[id].checkb.OnChange = function(self, val)
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