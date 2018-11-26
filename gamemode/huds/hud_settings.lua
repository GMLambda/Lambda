local PANEL = {}

local W = 375
local H = 440

local COLOR_PANEL_W = 280
local COLOR_PANEL_H = 206

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
	colsetb.DoClick = function() if !IsValid(self.CMFrame) then self:ShowColorOption() else self.CMFrame:Remove() end end

	self.Sheet:AddSheet( "Player", PanelSelect, "lambda/icons/player_settings.png" )

	local PanelVote = self.Sheet:Add("DPanel")

		local buttonSizeW = 110

		local restartvoteb = vgui.Create("DButton", PanelVote)
		restartvoteb:SetPos(5, 5)
		restartvoteb:SetText("Restart map")
		restartvoteb:SetSize(buttonSizeW, 22)
		restartvoteb:SetTextColor(Color(255, 255, 255, 155))
		restartvoteb.DoClick = function() RunConsoleCommand("lambda_voterestart") self:Close() end

		local skipvoteb = vgui.Create("DButton", PanelVote)
		skipvoteb:SetPos(5, 32)
		skipvoteb:SetText("Skip to next map")
		skipvoteb:SetSize(buttonSizeW, 22)
		skipvoteb:SetTextColor(Color(255, 255, 255, 155))
		skipvoteb.DoClick = function() RunConsoleCommand("lambda_voteskip") self:Close() end

		local cmap = vgui.Create("DComboBox", PanelVote)
		local mapList = GAMEMODE:GetGameTypeData("MapList") or {}
		local curMap = string.lower(game.GetMap())
		cmap:SetPos(5 + buttonSizeW + 5, 59)
		cmap:SetSize(100, 22)
		cmap:SetVisible(false)
		for _, v in pairs(mapList) do
			if v:iequals(curMap) == true then
				continue
			end
			cmap:AddChoice(v)
		end

		local cbmap = vgui.Create("DButton", PanelVote)
		cbmap:SetPos(5 + buttonSizeW + 5 + 100 + 5, 59)
		cbmap:SetSize(22, 22)
		cbmap:SetVisible(false)
		cbmap:SetIcon("lambda/icons/tick.png")
		cbmap:SetText("")
		cbmap.DoClick = function()
			local selected = cmap:GetSelected()
			RunConsoleCommand("lambda_votemap", selected) self:Close()
		end

		local cmvoteb = vgui.Create("DButton", PanelVote)
		cmvoteb:SetPos(5, 59)
		cmvoteb:SetText("Change map")
		cmvoteb:SetSize(buttonSizeW, 22)
		cmvoteb:SetTextColor(Color(255, 255, 255, 155))
		cmvoteb.DoClick = function()
			if !cmap:IsVisible() and !cbmap:IsVisible() then
				cmap:SetVisible(true)
				cbmap:SetVisible(true)
			else
				cmap:SetVisible(false)
				cbmap:SetVisible(false)
			end
			if self.pnlPlayersFrame ~= nil then
				self.pnlPlayersFrame:Remove()
				self.pnlPlayersFrame = nil
			end
		end

		local cplayer = vgui.Create("DComboBox", PanelVote)
		cplayer:SetPos(5 + buttonSizeW + 5, 86)
		cplayer:SetSize(100, 22)
		cplayer:SetVisible(false)
		for _, v in pairs(player.GetAll()) do
			if v == LocalPlayer() then
				continue
			end
			cplayer:AddChoice(v:Name(), v:UserID())
		end

		local cbkick = vgui.Create("DButton", PanelVote)
		cbkick:SetPos(5 + buttonSizeW + 5 + 100 + 5, 86)
		cbkick:SetSize(22, 22)
		cbkick:SetVisible(false)
		cbkick:SetIcon("lambda/icons/tick.png")
		cbkick:SetText("")
		cbkick.DoClick = function()
			local ply, steamid = cplayer:GetSelected()
			RunConsoleCommand("lambda_votekick", steamid) self:Close()
		end

		local kickvoteb = vgui.Create("DButton", PanelVote)
		kickvoteb:SetPos(5, 86)
		kickvoteb:SetText("Kick player")
		kickvoteb:SetSize(buttonSizeW, 22)
		kickvoteb:SetTextColor(Color(255, 255, 255, 155))
		kickvoteb.DoClick = function()
			if cplayer:IsVisible() == true then
				cplayer:SetVisible(false)
				cbkick:SetVisible(false)
			else
				cplayer:SetVisible(true)
				cbkick:SetVisible(true)
			end
		end

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

		local PanelAdmin = self.Sheet:Add("DPanel")

		local nww = 40
		local nwh = 20

		local resp_time = vgui.Create("DNumberWang", PanelAdmin)
		resp_time:SetPos(5, 5)
		resp_time:SetSize(nww, nwh)
		resp_time:SetCursorColor(Color(255,255,255,255))
		resp_time:SetMinMax(-1, 127)
		resp_time:SetValue(cvars.Number("lambda_max_respawn_timeout"))
		function resp_time:OnValueChanged(val)
			GAMEMODE:ChangeAdminConfiguration("max_respawn_timeout", val)
		end

		local resp_time_label = vgui.Create("DLabel", PanelAdmin)
		resp_time_label:SetPos(nww + 10 , 7)
		resp_time_label:SetTextColor(Color(255,255,255,150))
		resp_time_label:SetText("Respawn time")
		resp_time_label:SizeToContents()

		local no_resp = vgui.Create("DCheckBoxLabel", PanelAdmin)
		no_resp:SetPos(nww + 100, 7)
		no_resp:SetText("No respawn")
		no_resp:SizeToContents()
		function no_resp:OnChange(val)
			resp_time:SetVisible(val == false)
			if val then resp_time:SetValue(-1) else resp_time:SetValue(GetConVar("lambda_max_respawn_timeout"):GetDefault()) end
		end

		---

		local rest_time = vgui.Create("DNumberWang", PanelAdmin)
		rest_time:SetPos(5, nwh + 10)
		rest_time:SetSize(nww, nwh)
		rest_time:SetCursorColor(Color(255,255,255,255))
		rest_time:SetValue(cvars.Number("lambda_map_restart_timeout"))
		function rest_time:OnValueChanged(val)
			GAMEMODE:ChangeAdminConfiguration("map_restart_timeout", tostring(val))
		end

		local rest_time_label = vgui.Create("DLabel", PanelAdmin)
		rest_time_label:SetPos(nww + 10 , 32)
		rest_time_label:SetTextColor(Color(255,255,255,150))
		rest_time_label:SetText("Restart time")
		rest_time_label:SizeToContents()

		---

		local change_time = vgui.Create("DNumberWang", PanelAdmin)
		change_time:SetPos(5, 2 * nwh + 15)
		change_time:SetSize(nww, nwh)
		change_time:SetCursorColor(Color(255,255,255,255))
		change_time:SetValue(cvars.Number("lambda_map_change_timeout"))
		change_time:SetMinMax(0, 100)

		function change_time:OnValueChanged(val)
			if tonumber(val) > 100 then val = 100 change_time:SetValue(val) end
			GAMEMODE:ChangeAdminConfiguration("map_change_timeout", tostring(val))
		end

		local change_time_label = vgui.Create("DLabel", PanelAdmin)
		change_time_label:SetPos(nww + 10 , 57)
		change_time_label:SetTextColor(Color(255,255,255,150))
		change_time_label:SetText("Map change timeout")
		change_time_label:SizeToContents()

		---

		local pick_delay = vgui.Create("DNumberWang", PanelAdmin)
		pick_delay:SetPos(5, 3 * nwh + 20)
		pick_delay:SetSize(nww, nwh)
		pick_delay:SetCursorColor(Color(255,255,255,255))
		pick_delay:SetDecimals(1)
		pick_delay:SetMinMax(0.0, 3.0)
		pick_delay:SetValue(cvars.Number("lambda_pickup_delay"))

		function pick_delay:OnValueChanged(val)
			GAMEMODE:ChangeAdminConfiguration("pickup_delay", tostring(val))
		end

		local pick_delay_label = vgui.Create("DLabel", PanelAdmin)
		pick_delay_label:SetPos(nww + 10 , 82)
		pick_delay_label:SetTextColor(Color(255,255,255,150))
		pick_delay_label:SetText("Pickup delay")
		pick_delay_label:SizeToContents()

		local difficulty_cmb = vgui.Create("DComboBox", PanelAdmin)
		difficulty_cmb:SetPos(5, 4 * nwh + 25)
		difficulty_cmb:SetTextColor(Color(255, 255, 255, 155))
		difficulty_cmb:SetText("Difficulty")
		difficulty_cmb:SetSize(100, 22)
		difficulty_cmb:SetSortItems(false)
		for _,v in pairs(GAMEMODE:GetDifficulties()) do
			local choice = GAMEMODE:GetDifficultyText(v)
			difficulty_cmb:AddChoice(choice, v, GAMEMODE:GetDifficulty() == v)
		end
		function difficulty_cmb:OnSelect(idx, value, data)
			GAMEMODE:ChangeAdminConfiguration("difficulty", tostring(data))
		end

		local difficulty_label = vgui.Create("DLabel", PanelAdmin)
		difficulty_label:SetPos(nww + 70 , 4 * nwh + 30)
		difficulty_label:SetTextColor(Color(255,255,255,150))
		difficulty_label:SetText("Difficulty")
		difficulty_label:SizeToContents()

		local DropModes = {
			[0] = "Nothing",
			[1] = "Active weapon",
			[2] = "Everything",
		}

		local weapondrop_cmb = vgui.Create("DComboBox", PanelAdmin)
		weapondrop_cmb:SetPos(5, 5 * nwh + 32)
		weapondrop_cmb:SetTextColor(Color(255, 255, 255, 155))
		weapondrop_cmb:SetText("Weapon Drop Mode")
		weapondrop_cmb:SetSize(100, 22)
		weapondrop_cmb:SetSortItems(false)
		for k,v in pairs(DropModes) do
			local choice = GAMEMODE:GetDifficultyText(v)
			weapondrop_cmb:AddChoice(v, k, lambda_weapondrop:GetInt() == k)
		end
		function weapondrop_cmb:OnSelect(idx, value, data)
			GAMEMODE:ChangeAdminConfiguration("weapondrop", tostring(data))
		end

		local weapondrop_label = vgui.Create("DLabel", PanelAdmin)
		weapondrop_label:SetPos(nww + 70 , 5 * nwh + 35)
		weapondrop_label:SetTextColor(Color(255,255,255,150))
		weapondrop_label:SetText("Weapon Drop Mode")
		weapondrop_label:SizeToContents()

		local player_god = vgui.Create("DCheckBoxLabel", PanelAdmin)
		player_god:SetPos(5, 6 * nwh + 38)
		player_god:SetText("Godmode")
		player_god:SizeToContents()
		player_god:SetValue(cvars.Number("lambda_player_god"))
		function player_god:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("player_god", val)
		end

		local ply_coll = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_coll:SetPos(5, 7 * nwh + 35)
		ply_coll:SetText("Player collision")
		ply_coll:SizeToContents()
		ply_coll:SetValue(cvars.Number("lambda_playercollision"))
		function ply_coll:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("playercollision", val)
		end

		local ply_track = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_track:SetPos(5, 8 * nwh + 35)
		ply_track:SetText("Player tracking")
		ply_track:SizeToContents()
		ply_track:SetValue(cvars.Number("lambda_player_tracker"))
		function ply_track:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("player_tracker", val)
		end

		local ply_friendlyfire = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_friendlyfire:SetPos(5, 9 * nwh + 35)
		ply_friendlyfire:SetText("Friendly fire. Only works with player collision on")
		ply_friendlyfire:SizeToContents()
		ply_friendlyfire:SetValue(cvars.Number("lambda_friendlyfire"))
		function ply_friendlyfire:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("friendlyfire", val)
		end

		local dynamic_checkpoints = vgui.Create("DCheckBoxLabel", PanelAdmin)
		dynamic_checkpoints:SetPos(5, 10 * nwh + 35)
		dynamic_checkpoints:SetText("Dynamic checkpoints")
		dynamic_checkpoints:SizeToContents()
		dynamic_checkpoints:SetValue(cvars.Number("lambda_dynamic_checkpoints"))
		function dynamic_checkpoints:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("dynamic_checkpoints", val)
		end

		local npc_damage = vgui.Create("DCheckBoxLabel", PanelAdmin)
		npc_damage:SetPos(5, 11 * nwh + 35)
		npc_damage:SetText("Friendly NPC damage")
		npc_damage:SizeToContents()
		npc_damage:SetValue(cvars.Number("lambda_allow_npcdmg"))
		function npc_damage:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("allow_npcdmg", val)
		end

		local limit_ammo = vgui.Create("DCheckBoxLabel", PanelAdmin)
		limit_ammo:SetPos(5, 12 * nwh + 35)
		limit_ammo:SetText("Limit default ammo")
		limit_ammo:SizeToContents()
		limit_ammo:SetValue(cvars.Number("lambda_limit_default_ammo"))
		function limit_ammo:OnChange(val)
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("limit_default_ammo", val)
		end

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
