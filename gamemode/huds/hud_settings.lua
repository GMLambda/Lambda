local PANEL = {}

local W = 375
local H = 440

local COLOR_PANEL_W = 280
local COLOR_PANEL_H = 206

local colWHITE = Color(255, 255, 255, 195)

local border = 4
local border_w = 5
local matHover = Material( "gui/ps_hover.png", "nocull" )
local boxHover = GWEN.CreateTextureBorder( border, border, 64 - border * 2, 64 - border * 2, border_w, border_w, border_w, border_w, matHover )


cvars.AddChangeCallback("lambda_playermdl", function()
	net.Start("LambdaPlayerSettingsChanged")
	net.SendToServer()
end, "LambdaPlayerModelChanged")

function PANEL:Init()

	self:SetSkin("Lambda")
	self:SetSize(W, H)
	self:SetPos(20, ScrH() / 2 - (H / 2))
	self:SetTitle("Settings")

	self.Sheet = self:Add("DPropertySheet")
	self.Sheet:Dock(LEFT)
	self.Sheet:SetSize(W - 10, H)

	PanelSelect = self.Sheet:Add("DPanelSelect")

	local mdls = GAMEMODE:GetAvailablePlayerModels()

	for name, v in pairs(mdls) do

		local icon = vgui.Create("SpawnIcon")
		if istable(v) and #v > 1 then
			icon:SetModel(v[2])
		elseif istable(v) then
			icon:SetModel(v[1])
		else
			icon:SetModel(v)
		end

		icon:SetSize(64, 64)
		icon:SetTooltip(name)

		icon.PaintOver = function(self, w, h) if self.OverlayFade > 0 then boxHover( 0, 0, w, h, Color( 255, 255, 255, self.OverlayFade ) ) end self:DrawSelections() end

		PanelSelect:AddPanel(icon, { lambda_playermdl = name })
	end

	local colsetb = vgui.Create("DImageButton", self.Sheet)
	colsetb:SetPos(W - 30 , 3)
	colsetb:SetImage("lambda/icons/palette.png")
	colsetb:SizeToContents()
	colsetb:SetTooltip("Edit colors")
	colsetb.DoClick = function() if not IsValid(self.CMFrame) then self:ShowColorOption() else self.CMFrame:Remove() end end

	self.Sheet:AddSheet( "Player", PanelSelect, "lambda/icons/player_settings.png" )

	local PanelVote = self.Sheet:Add("VoteTabPanel")
	self.Sheet:AddSheet("Vote", PanelVote, "lambda/icons/poll.png")

	local PanelSettings = self.Sheet:Add("DPanel")
	do
		local sheetSettings = vgui.Create("DPropertySheet", PanelSettings)
		sheetSettings:Dock(LEFT)
		sheetSettings:SetSize(W - 10, H)

		local PanelCrosshair = sheetSettings:Add("DPanel")
		do
			local dyn_cross = vgui.Create("DCheckBoxLabel", PanelCrosshair)
			dyn_cross:SetPos(5, 5)
			dyn_cross:SetText("Enhanced Crosshair")
			dyn_cross:SetConVar("lambda_crosshair")
			dyn_cross:SetValue(cvars.Number("lambda_crosshair"))

			local bgColor = Color(0, 0, 0, 255)

			local chPreview = vgui.Create("DImage", PanelCrosshair)
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

			local chSize = vgui.Create("DNumSlider", PanelCrosshair)
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

			local chWidth = vgui.Create("DNumSlider", PanelCrosshair)
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

			local chSpace = vgui.Create("DNumSlider", PanelCrosshair)
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

			local labelColor = vgui.Create("DLabel", PanelCrosshair)
			labelColor:SetPos(5, 105)
			labelColor:SetText("Color")

			local labelR = vgui.Create("DLabel", PanelCrosshair)
			labelR:SetPos(135, 105)
			labelR:SetText("R")

			local crosshairColor = GAMEMODE:GetCrosshairColor()

			local numCrosshairR = vgui.Create("DNumberWang", PanelCrosshair)
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

			local labelG = vgui.Create("DLabel", PanelCrosshair)
			labelG:SetPos(195, 105)
			labelG:SetText("G")

			local numCrosshairG = vgui.Create("DNumberWang", PanelCrosshair)
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

			local labelB = vgui.Create("DLabel", PanelCrosshair)
			labelB:SetPos(255, 105)
			labelB:SetText("B")

			local numCrosshairB = vgui.Create("DNumberWang", PanelCrosshair)
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

			local chAdaptive = vgui.Create("DCheckBoxLabel", PanelCrosshair)
			chAdaptive:SetPos(5, 135)
			chAdaptive:SetText("Adaptive Colors")
			chAdaptive:SetConVar("lambda_crosshair_adaptive")
			chAdaptive:SetValue(cvars.Number("lambda_crosshair_adaptive"))

			local chAdaptive = vgui.Create("DCheckBoxLabel", PanelCrosshair)
			chAdaptive:SetPos(5, 165)
			chAdaptive:SetText("Dynamic")
			chAdaptive:SetConVar("lambda_crosshair_dynamic")
			chAdaptive:SetValue(cvars.Number("lambda_crosshair_dynamic"))
		end
		sheetSettings:AddSheet("Crosshair", PanelCrosshair)

		local PanelPostFx = sheetSettings:Add("DPanel")
		do
			local postproc = vgui.Create("DCheckBoxLabel", PanelPostFx)
			postproc:SetPos(5, 5)
			postproc:SetText("Post Processing (Custom effects)")
			postproc:SizeToContents()
			postproc:SetConVar("lambda_postprocess")
			postproc:SetValue(cvars.Number("lambda_postprocess"))

			local gore = vgui.Create("DCheckBoxLabel", PanelPostFx)
			gore:SetPos(5, 25)
			gore:SetText("Gore")
			gore:SizeToContents()
			gore:SetConVar("lambda_gore")
			gore:SetValue(cvars.Number("lambda_gore"))

			local physcannon_glow = vgui.Create("DCheckBoxLabel", PanelPostFx)
			physcannon_glow:SetPos(5, 45)
			physcannon_glow:SetText("Gravity Gun Glow")
			physcannon_glow:SizeToContents()
			physcannon_glow:SetConVar("physcannon_glow")
			physcannon_glow:SetValue(cvars.Number("physcannon_glow"))
		end
		sheetSettings:AddSheet("Effects", PanelPostFx)
	end
	self.Sheet:AddSheet("Settings", PanelSettings, "lambda/icons/settings.png")

	local pl = LocalPlayer()
	if pl:IsAdmin() then
			local PanelAdmin = self.Sheet:Add("SettingsTabPanel")
			self.Sheet:AddSheet("Admin Settings", PanelAdmin, "lambda/icons/admin_settings.png")
		end

end


function PANEL:OnClose()

	if IsValid(self.CMFrame) then self.CMFrame:Remove() end

	net.Start("LambdaPlayerSettings")
	net.WriteBool(false)
	net.SendToServer()

end

function PANEL:ShowColorOption()

	self.Tabs = {}
	self.CMs = {}

	self.CMFrame = vgui.Create("DFrame")
	self.CMFrame:SetPos(395, ScrH() / 2 - (H / 2))
	self.CMFrame:SetSize(COLOR_PANEL_W, COLOR_PANEL_H)
	self.CMFrame:SetSkin("Lambda")
	self.CMFrame:ShowCloseButton(false)
	self.CMFrame:SetDraggable(false)
	self.CMFrame:SetTitle("Color Settings")

	local function strColorToVector(str)
		local color = string.Explode(" ", str)
		return Color(color[1] , color[2],color[3])
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


	self.CMSheet = vgui.Create("DPropertySheet", self.CMFrame)
	self.CMSheet:Dock(FILL)

	self.Tabs.ply =  vgui.Create("DPanel", self.CMSheet)
	self.CMSheet:AddSheet("Player", self.Tabs.ply)

	self.Tabs.wep =  vgui.Create("DPanel", self.CMSheet)
	self.CMSheet:AddSheet("Weapon", self.Tabs.wep)

	self.Tabs.hudBG =  vgui.Create("DPanel", self.CMSheet)
	self.CMSheet:AddSheet("HUD Background", self.Tabs.hudBG)

	self.Tabs.hudTXT =  vgui.Create("DPanel", self.CMSheet)
	self.CMSheet:AddSheet("HUD Text", self.Tabs.hudTXT)

	for k,v in pairs(self.Tabs) do
		self.CMs[k] = vgui.Create("DColorMixer", self.Tabs[k])
		self.CMs[k]:SetAlphaBar(false)
		self.CMs[k]:SetPalette(false)
		self.CMs[k]:Dock(FILL)

		if k == "hudTXT" or k == "hudBG" then
			self.CMs[k]:SetColor(retrieveColor(k))
		else
			self.CMs[k]:SetVector(retrieveVec(k))
		end

		self.CMs[k].ValueChanged = function()
			if k == "hudTXT" or k == "hudBG" then
				self:UpdateColorSettings(k, self.CMs[k]:GetColor())
			else
				self:UpdateColorSettings(k, self.CMs[k]:GetVector())
			end
		end
	end

	self.CMFrame:MakePopup()

end

function PANEL:UpdateColorSettings(val,color)

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

function PANEL:OnKeyCodePressed(key)
	if key == KEY_F1 then
		self:Close()
	end
end


function PANEL:Think()

	if self.Sheet.OldActiveTab ~= self.Sheet:GetActiveTab() then
		self.Sheet.OldActiveTab = self.Sheet:GetActiveTab()
		if IsValid( self.CMFrame ) then
			self.CMFrame:Remove()
		end
	end

end
vgui.Register("HudPlayerSettings", PANEL, "DFrame")

local VoteTab = {}

VoteTab.Options = {["lambda_voterestart"] = "Restart Map", ["lambda_voteskip"] = "Skip map", ["lambda_votemap"] = "Change map", ["lambda_votekick"] = "Kick player"}
VoteTab.Extended = {["lambda_votemap"] = function(map) RunConsoleCommand("lambda_votemap", map) end, ["lambda_votekick"] = function(sid) RunConsoleCommand("lambda_votekick",sid) end}

function VoteTab:Init()

	self.Selected = nil
	local btnW, btnH, x, y = 110, 22, 5, 5

	for k, v in pairs(self.Options) do
		self.z = self:Add("DButton")
		self.z:SetPos(x, y)
		self.z:SetSize(btnW, btnH)
		self.z:SetTextColor(colWHITE)
		self.z:SetText(v)
		self.z.DoClick = function()
			if self.Extended[k] then
				self.Combo:SetPos(130, 5)
				self.Combo:SetVisible(true)
				self.btn:SetVisible(true)
				self:Extend(k)
			else
				RunConsoleCommand(k)
			end
	end
		y = y + btnH + 5
	end

	self.Combo = self:Add("DComboBox")
	self.Combo:SetSize(100, 22)
	self.Combo:SetVisible(false)
	self.Combo:SetTextColor(colWHITE)
	self.btn = self:Add("DButton")
	self.btn:SetPos(240, 5)
	self.btn:SetSize(btnH, btnH)
	self.btn:SetVisible(false)
	self.btn:SetIcon("lambda/icons/tick.png")
	self.btn:SetText("")
	self.btn.DoClick = function()
		local w, z = self.Combo:GetSelected()
		if not self.Combo:GetSelected() then
			self:Hide() return
		end
		if w and z then
			self.Extended[self.Selected](z)
		else
			self.Extended[self.Selected](w)
		end
		self:Hide()
	end

end

function VoteTab:Extend(vote)

	local mapList = GAMEMODE:GetGameTypeData("MapList") or {}
	self.Selected = vote
	if vote == "lambda_votemap" then
		for _, v in pairs(mapList) do
			if v:iequals(game.GetMap()) == true then
				continue
			end
			self.Combo:AddChoice(v)
		end
	end
	if vote == "lambda_votekick" then
		for _, v in pairs(player.GetAll()) do
			if v == LocalPlayer() then
				continue
			end
			self.Combo:AddChoice(v:Name(), v:UserID())
		end
	end

end

function VoteTab:Hide()

	self.Combo:SetVisible(false)
	self.btn:SetVisible(false)
	self.Combo:Clear()

end
vgui.Register("VoteTabPanel", VoteTab, "DPanel")

local SettingsTab = {}

Derma_Install_Convar_Functions(SettingsTab)

function SettingsTab:Init()

	local gametypeSettings = GAMEMODE:GetGameTypeData("Settings") or {}
	local y = 5
	local n = 0

	for k, v in pairs(gametypeSettings) do
		if v.value_type == "int" and v.Category == "SERVER" then
			self:AddIntOption(y, k, v)
			y = y + 25
			n = n + 1
		end
	end
	local _y = (25 * n) + 10
	for k, v in pairs(gametypeSettings) do
		if v.value_type == "bool" and v.Category == "SERVER" then
			self:AddCheckOption(_y, k, v)
			_y = _y + 20
		end
	end
	for k, v in pairs(gametypeSettings) do
		if v.value_type == "string"  and v.Category == "SERVER" then
			self:AddComboOption(10, k, v)
		end
	end

end

function SettingsTab:AddIntOption(y, id, tbl)

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

	function self.numw:OnValueChanged(v)
		GAMEMODE:ChangeAdminConfiguration(id, v)
	end

end

function SettingsTab:AddComboOption(y, id, tbl)

	self.cb = self:Add("DComboBox")
	self.cb:SetPos( 5 + 2 * 60, y)
	self.cb:SetTextColor(colWHITE)
	self.cb:SetText(tbl.info)
	self.cb:SetSize(100, 20)
	self.cb:SetSortItems(false)

	self.cb.lbl = self:Add("DLabel")
	self.cb.lbl:SetPos(135 + 100, y)
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

function SettingsTab:AddCheckOption(y, id, tbl)

	self.checkb = self:Add("DCheckBoxLabel")
	self.checkb:SetPos(5, y)
	self.checkb:SetText(tbl.info)
	self.checkb:SizeToContents()
	self.checkb:SetConVar("lambda_" .. id)

end
vgui.Register("SettingsTabPanel", SettingsTab, "DScrollPanel")

net.Receive("LambdaPlayerSettings", function(len)

	local state = net.ReadBool()

	if LAMBDA_PLAYER_SETTINGS ~= nil then
		LAMBDA_PLAYER_SETTINGS:Remove()
	end

	if state == true then
		LAMBDA_PLAYER_SETTINGS = vgui.Create("HudPlayerSettings")
		LAMBDA_PLAYER_SETTINGS:MakePopup()
		LAMBDA_PLAYER_SETTINGS:SetSkin("Lambda")
	end

end)

function ShowSettings()
	if LAMBDA_PLAYER_SETTINGS ~= nil then
		LAMBDA_PLAYER_SETTINGS:Remove()
	end
	LAMBDA_PLAYER_SETTINGS = vgui.Create("HudPlayerSettings")
	LAMBDA_PLAYER_SETTINGS:MakePopup()
	LAMBDA_PLAYER_SETTINGS:SetSkin("Lambda")
end
