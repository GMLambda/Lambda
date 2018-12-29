local PANEL = {}

local W = 375
local H = 440
local isadmin = false

PANEL.Tabs = {{"Vote", "poll"}, {"Player", "player_settings"}, {"Settings", "settings"}}

function PANEL:Init()
	self:SetSkin("Lambda")
	self:SetSize(W, H)
	self:SetPos(20, ScrH() / 2 - (H / 2))
	self:SetTitle("Settings - " .. GAMEMODE:GetGameTypeData("Name"))

	self.Sheet = self:Add("DPropertySheet")
	self.Sheet:Dock(LEFT)
	self.Sheet:SetSize(W - 10, H)
	self.TabPanels = {}

	local ply = LocalPlayer()
	if ply:IsAdmin() and not isadmin then
		table.insert(self.Tabs, {"Admin", "admin_settings"})
		isadmin = true
	end

	for k, v in ipairs(self.Tabs) do
		local pnl_name = "Lambda" .. v[1] .. "Panel"
		local pnl_icon = "lambda/icons/" .. v[2] .. ".png"
		self.TabPanels[k] = self.Sheet:Add(pnl_name)
		self.Sheet:AddSheet(v[1],self.TabPanels[k],pnl_icon)
	end
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