local PANEL = {}

local W = 375
local H = 440

local COLOR_PANEL_W = 267
local COLOR_PANEL_H = 206

function PANEL:Init()

	self:SetSkin("Lambda")
	self:SetSize(W, H)
	self:SetPos(20, ScrH() / 2 - (H / 2))
	self:SetTitle("Settings")
	self:ShowCloseButton(false)

	local closeb = self:Add("DImageButton")
	closeb:SetPos(W - 20, 4)
	closeb:SetImage("lambda/icons/close.png")
	closeb:SizeToContents()
	closeb.DoClick = function()
		self:Close()
	end

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

		PanelSelect:AddPanel(icon, { lambda_playermdl = name })
	end

	local colsetb = vgui.Create("DImageButton", PanelSelect)
	colsetb:SetPos(W - 43 , 5)
	colsetb:SetImage("lambda/icons/palette.png")
	colsetb:SizeToContents()
	colsetb:SetTooltip("Edit colors")
	colsetb.DoClick = function() if !IsValid(self.CMFrame) then self:ShowColorOption() else self.CMFrame:Remove() end end

	self.Sheet:AddSheet( "Player", PanelSelect, "lambda/icons/player_settings.png" )

	local PanelSettings = self.Sheet:Add("DPanel")

		local dyn_cross = vgui.Create("DCheckBoxLabel", PanelSettings)
		dyn_cross:SetPos(5, 5)
		dyn_cross:SetText("Dynamic crosshair")
		dyn_cross:SetConVar("lambda_dynamic_crosshair")
		dyn_cross:SetValue(cvars.Number("lambda_dynamic_crosshair"))

		local postproc = vgui.Create("DCheckBoxLabel", PanelSettings)
		postproc:SetPos(5, 25)
		postproc:SetText("Post Processing (Custom effects)")
		postproc:SizeToContents()
		postproc:SetConVar("lambda_postprocess")
		postproc:SetValue(cvars.Number("lambda_postprocess"))

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
			--pl:ConCommand("lambda_map_change_timeout " .. tonumber(val))
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
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			GAMEMODE:ChangeAdminConfiguration("pickup_delay", tostring(val))
		end

		local pick_delay_label = vgui.Create("DLabel", PanelAdmin)
		pick_delay_label:SetPos(nww + 10 , 82)
		pick_delay_label:SetTextColor(Color(255,255,255,150))
		pick_delay_label:SetText("Pickup delay")
		pick_delay_label:SizeToContents()

		local player_god = vgui.Create("DCheckBoxLabel", PanelAdmin)
		player_god:SetPos(5, 4 * nwh + 30)
		player_god:SetText("Godmode")
		player_god:SizeToContents()
		player_god:SetValue(cvars.Number("lambda_player_god"))
		function player_god:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("player_god", val)
		end

		local ply_coll = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_coll:SetPos(5, 5 * nwh + 30)
		ply_coll:SetText("Player collision")
		ply_coll:SizeToContents()
		ply_coll:SetValue(cvars.Number("lambda_playercollision"))
		function ply_coll:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("playercollision", val)
		end

		local ply_track = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_track:SetPos(5, 6 * nwh + 30)
		ply_track:SetText("Player tracking")
		ply_track:SizeToContents()
		ply_track:SetValue(cvars.Number("lambda_player_tracker"))
		function ply_track:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("player_tracker", val)
		end

		local ply_friendlyfire = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_friendlyfire:SetPos(5, 7 * nwh + 30)
		ply_friendlyfire:SetText("Friendly fire. Only works with player collision on")
		ply_friendlyfire:SizeToContents()
		ply_friendlyfire:SetValue(cvars.Number("lambda_friendlyfire"))
		function ply_friendlyfire:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("friendlyfire", val)
		end

		local dynamic_checkpoints = vgui.Create("DCheckBoxLabel", PanelAdmin)
		dynamic_checkpoints:SetPos(5, 8 * nwh + 30)
		dynamic_checkpoints:SetText("Dynamic checkpoints")
		dynamic_checkpoints:SizeToContents()
		dynamic_checkpoints:SetValue(cvars.Number("lambda_dynamic_checkpoints"))
		function dynamic_checkpoints:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("dynamic_checkpoints", val)
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
	self.CMSheet:AddSheet("Hud BG", self.Tabs.hudBG)

	self.Tabs.hudTXT =  vgui.Create("DPanel", self.CMSheet)
	self.CMSheet:AddSheet("Hud TEXT", self.Tabs.hudTXT)

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

	net.Start("LambdaPlayerColorChanged")
	net.SendToServer()

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
