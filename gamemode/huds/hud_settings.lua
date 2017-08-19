local PANEL = {}

local W = 375
local H = 440

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

	local PanelHelp = self.Sheet:Add("DPanel")
	self.Sheet:AddSheet("Help",PanelHelp, "lambda/icons/help.png")

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

	local plycolb = vgui.Create("DImageButton", PanelSelect)
	plycolb:SetPos(W - 45 , 5)
	plycolb:SetImage("lambda/icons/palette.png")
	plycolb:SizeToContents()
	plycolb:SetTooltip("Change player color")
	plycolb.DoClick = function() if !IsValid(self.CMFrame) then self:ShowColorMixer(1) else self.CMFrame:Remove() end end

	local wepcolb = vgui.Create("DImageButton", PanelSelect)
	wepcolb:SetPos(W - 45, 35)
	wepcolb:SetImage("lambda/icons/palette.png")
	wepcolb:SizeToContents()
	wepcolb:SetTooltip("Change weapon color")
	wepcolb.DoClick = function() if !IsValid(self.CMFrame) then self:ShowColorMixer(2) else self.CMFrame:Remove() end end

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
		rest_time_label:SetText("Restart timeout")
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
		player_god:SetText("God Mode.")
		player_god:SizeToContents()
		player_god:SetValue(cvars.Number("lambda_player_god"))
		function player_god:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("player_god", val)
		end

		local ply_coll = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_coll:SetPos(5, 5 * nwh + 30)
		ply_coll:SetText("Player collision.")
		ply_coll:SizeToContents()
		ply_coll:SetValue(cvars.Number("lambda_playercollision"))
		function ply_coll:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("playercollision", val)
		end

		local ply_track = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_track:SetPos( 5, 6*nwh+30 )
		ply_track:SetText("Player tracking")
		ply_track:SizeToContents()
		ply_track:SetValue(cvars.Number("lambda_player_tracker"))
		function ply_track:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("player_tracker", val)
		end

		local ply_friendlyfire = vgui.Create("DCheckBoxLabel", PanelAdmin)
		ply_friendlyfire:SetPos(5, 7*nwh+30)
		ply_friendlyfire:SetText("Friendly fire. Only works with player collision on.")
		ply_friendlyfire:SizeToContents()
		ply_friendlyfire:SetValue(cvars.Number("lambda_friendlyfire"))
		function ply_friendlyfire:OnChange(val)
			--pl:ConCommand("lambda_pickup_delay " .. tonumber(val))
			if val then val = "1" else val = "0" end
			GAMEMODE:ChangeAdminConfiguration("friendlyfire", val)
		end

		local dynamic_checkpoints = vgui.Create("DCheckBoxLabel", PanelAdmin)
		dynamic_checkpoints:SetPos(5, 8*nwh+30)
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

function PANEL:ShowColorMixer(type)


	self.CMFrame = vgui.Create("DFrame")
	self.CMFrame:SetPos(395, ScrH() / 2 - (H / 2))
	self.CMFrame:SetSize(267, 186)
	self.CMFrame:SetSkin("Lambda")
	self.CMFrame:ShowCloseButton(false)
	self.CMFrame:SetDraggable(false)

	self.ColorMixer = vgui.Create("DColorMixer", self.CMFrame)
	self.ColorMixer:Dock(FILL)
	self.ColorMixer:SetAlphaBar(false)

	self.CMFrame:MakePopup()

	if ( type == 1 ) then
		self.ColorMixer:SetVector(LocalPlayer():GetPlayerColor())
		self.CMFrame:SetTitle("Player color")
	else
		self.ColorMixer:SetVector(LocalPlayer():GetWeaponColor())
		self.CMFrame:SetTitle("Weapon color")
	end

	self.ColorMixer.ValueChanged = function() self:UpdatePlayerColor(type, self.ColorMixer:GetVector()) end

end

function PANEL:UpdatePlayerColor(type,color)

	if type == 1 then
		LocalPlayer():SetPlayerColor(color)
		lambda_player_color:SetString(util.TypeToString(color))
	else
		LocalPlayer():SetWeaponColor(color)
		lambda_weapon_color:SetString(util.TypeToString(color))
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
