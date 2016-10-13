include("hud_numeric.lua")

local PANEL = {}

function PANEL:Init()

	self:SetSize(util.ScreenScaleH(103), util.ScreenScaleH(37))

	self:SetLabelText(Localize("#Valve_Hud_HEALTH"))
	self.LastHealth = 0
	self.LastArmor = 0

	self.AnimateHealthIncreased = Derma_Anim("HealthIncreased", self, self.AnimHealthIncreased)
	self.AnimateHealthDecreasedBelow20 = Derma_Anim("HealthDecreasedBelow20", self, self.AnimHealthDecreasedBelow20)
	self.AnimateHealthLow = Derma_Anim("HealthLow", self, self.AnimHealthLow)

	self.Animations =
	{
		self.AnimateHealthIncreased,
		self.AnimateHealthDecreasedBelow20,
		self.AnimateHealthLow,
	}

end

function PANEL:AnimHealthIncreased(anim, delta, data)
	self.Blur = (1 - delta) * 3
	self:SetBackgroundColor(0, 0, 0, 128)
	self:SetTextColor(255, 208, 64, 255)
end

function PANEL:AnimHealthDecreasedBelow20(anim, delta, data)
	self.Blur = delta * 1
	self:SetBackgroundColor(delta * 70, 0, 0, 128)
end

function PANEL:AnimHealthLow(anim, delta, data)

	if delta == 1 then
		return self.AnimateHealthLow:Start(0.8)
	end

	local r
	if delta <= 0.3 then
		r = (delta / 0.3) * 100
	else
		delta = delta - 0.3
		r = (1 - (delta / 0.7)) * 100
	end
	--DbgPrint(r)

	self:SetTextColor(255, 0, 0, 128)
	self:SetBackgroundColor(r, 0, 0, 128)

end

function PANEL:StopAnimations()
	for _,v in pairs(self.Animations) do
		v:Stop()
	end
end

function PANEL:Think()

	local ply = LocalPlayer()
	if not IsValid(ply) then
		return
	end

	for _,v in pairs(self.Animations) do
		if v:Active() then
			v:Run()
		end
	end

	local health = math.Clamp(ply:Health(), 0, ply:GetMaxHealth())

	if health == self.LastHealth then
		return
	end
	self.LastHealth = health

	if health >= 20 then
		self.AnimateHealthLow:Stop()
		self.AnimateHealthDecreasedBelow20:Stop()

		self.AnimateHealthIncreased:Start(3)
	else
		self.AnimateHealthIncreased:Stop()

		self.AnimateHealthDecreasedBelow20:Start(0.5)
		self.AnimateHealthLow:Start(1)
	end

	self:SetDisplayValue(health)

end

vgui.Register( "HudHealth", PANEL, "HudNumeric" )
