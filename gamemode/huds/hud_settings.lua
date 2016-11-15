local PANEL = {}

function PANEL:Init()

	self:SetSize(375, 240)
	self:Center()

end

vgui.Register("HudPlayerSettings", PANEL, "DFrame")
