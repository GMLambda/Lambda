local PANEL = {}
local colWHITE = Color(255, 255, 255, 195)

PANEL.Options = {["lambda_voterestart"] = "Restart Map", ["lambda_voteskip"] = "Skip map", ["lambda_votemap"] = "Change map", ["lambda_votekick"] = "Kick player"}
PANEL.Extended = {["lambda_votemap"] = function(map) RunConsoleCommand("lambda_votemap", map) end, ["lambda_votekick"] = function(sid) RunConsoleCommand("lambda_votekick",sid) end}

function PANEL:Init()

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
				if IsValid(self.RootPanel) then
					self.RootPanel:Close()
				end
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
		if IsValid(self.RootPanel) then
			self.RootPanel:Close()
		end
		self:Hide()
	end

end

function PANEL:Extend(vote)

	local mapList = GAMEMODE:GetMapList() or {}
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

function PANEL:Hide()

	self.Combo:SetVisible(false)
	self.btn:SetVisible(false)
	self.Combo:Clear()

end
vgui.Register("LambdaVotePanel", PANEL, "DPanel")