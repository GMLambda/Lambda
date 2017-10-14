local HINTS = {}
local PANEL = {}

function PANEL:Init()
	self:SetDrawOnTop(true)
end

function PANEL:SetText(text)
	self.text = self:Add("DLabel")
	self.text:SetText(text)
	self.text:SetFont("TargetID")
	self.text:SetColor(Color(255, 255, 255, 255))
	self.text:SetPos(7.5, 5)
	self.text:SizeToContents()

	local w, h = self.text:GetSize()

	self:SetSize(w + 12.5, h + 12)
end

function PANEL:SetTime(time)
	self:MoveTo( ScrW(), ScrH() * 0.8, 0.1, time, 0.9,function(tbl,PANEL)
		table.remove(HINTS, PANEL.unique)

		PANEL:Remove()

		timer.Simple(0.1, function()
			local y = ScrH() * 0.8
			for i = 0, #HINTS do
				local PANEL = HINTS[#HINTS - i]
				if IsValid(PANEL) then
					PANEL:MoveTo( ScrW() -  PANEL:GetWide() - 20, y, 0.1, 0, 0.3)
					y = y -(PANEL:GetTall() + 18)
				end
			end
		end)

	end)
end

function PANEL:Paint(w, h)
	local _x, _y = self.text:GetPos()
	local x = 10 - _x
	local y = 5 - _y
	draw.RoundedBox( 0, x, h-3, w, h, Color (255, 147, 30, 220 ) )
	draw.RoundedBox( 0, x, y, w, h-3, Color( 0, 0, 0, 180 ) )

end

vgui.Register("lambda_hud_hint", PANEL, "Panel")


function GM:AddHint(text, time)
	local hint = vgui.Create("lambda_hud_hint")
	hint:SetText(text)
	hint:SetTime(time)
	hint:SetAlpha(0)
	hint:AlphaTo(255, 0.7, 0.1)

	hint:SetPos(ScrW(), ScrH() * 0.8)

	PANEL.unique = table.insert(HINTS, hint)

	local y = ScrH() * 0.8
	for i = 0, #HINTS do
		local PANEL = HINTS[#HINTS - i]
		if IsValid(PANEL) then
			local x = PANEL:GetPos()
			PANEL:MoveTo(ScrW() -  hint:GetWide() - 20, y, 0.3, 0, 0.9)
			y = y - (PANEL:GetTall() + 8)
		end
	end
end