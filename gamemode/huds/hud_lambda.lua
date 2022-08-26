local PANEL = {}

local W = 375
local H = 440
local isadmin = false

PANEL.Tabs = {{"Info", "info"}, {"Vote", "poll"}, {"Player", "player_settings"}, {"Settings", "settings"}}

function PANEL:Init()
	self:SetSkin("Lambda")
	self:SetSize(W, H)
	self:SetPos(20, ScrH() / 2 - (H / 2))
	self:SetTitle("SETTINGS - " .. string.upper(GAMEMODE:GetGameTypeData("Name")))

	self.Sheet = self:Add("DPropertySheet")
	self.Sheet.RootPanel = self
	self.Sheet:Dock(LEFT)
	self.Sheet:SetSize(W - 10, H)
	self.TabPanels = {}

	for k, v in ipairs(self.Tabs) do
		local pnl_name = "Lambda" .. v[1] .. "Panel"
		local pnl_icon = "lambda/icons/" .. v[2] .. ".png"
		self.TabPanels[k] = self.Sheet:Add(pnl_name)
		self.TabPanels[k].RootPanel = self
		self.Sheet:AddSheet(string.upper(v[1]),self.TabPanels[k],pnl_icon)
	end

	cookie.Set("LambdaMenuOpened", 1)
end

function PANEL:OnClose()
	net.Start("LambdaPlayerSettings")
	net.WriteBool(false)
	net.SendToServer()
end

function PANEL:OnKeyCodePressed(key)
	if key == KEY_F1 then
		self:Close()
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