local border = 4
local border_w = 5
local matHover = Material( "gui/ps_hover.png", "nocull" )
local boxHover = GWEN.CreateTextureBorder( border, border, 64 - border * 2, 64 - border * 2, border_w, border_w, border_w, border_w, matHover )


cvars.AddChangeCallback("lambda_playermdl", function()
	net.Start("LambdaPlayerSettingsChanged")
	net.SendToServer()
end, "LambdaPlayerModelChanged")

local PANEL = {}

function PANEL:Init()
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

		self:AddPanel(icon, { lambda_playermdl = name })
	end
end
vgui.Register("LambdaPlayerPanel", PANEL, "DPanelSelect")