surface.CreateFont("lambda_sb_def", {
	font = "Roboto",
	size = 24,
	weight = 400,
	antialias = true
})

surface.CreateFont("lambda_sb_def_sm", {
	font = "Roboto Light",
	size = 16,
	weight = 300,
	antialias = true
})

local lambda_logo = Material("lambda/logo_512.png", "noclamp smooth")
local SB_PING_METER = {}
local SB_PLY_LINE = {}
local SB_PANEL = {}

function SB_PING_METER:Init()
	self:Dock(FILL)
	self:DockMargin(0, 3, 0, 0)
	self.PingNum = self:Add("DLabel")
	self.PingNum:SetPos(10, 1)
	self.PingNum:SetFont("lambda_sb_def_sm")
	self.PingNum:SetTextColor(Color(250, 250, 250, 250))
	self.PingNum:SetContentAlignment(4)
	self:SetWidth(50)
end

function SB_PING_METER:Setup(ply)
	self.Player = ply
	self.Think(self)
end

function SB_PING_METER:Think()
	if not IsValid(self.Player) then return end
	self.PlyPing = self.Player:Ping()
	self.PingNum:SetText("   " .. self.PlyPing)
end

function SB_PING_METER:Paint(w, h)
	surface.SetDrawColor(Color(90, 90, 92, 200))
	surface.DrawRect(0, 15, 3, 4)
	surface.DrawRect(4, 12, 3, 7)
	surface.DrawRect(8, 8, 3, 11)
	surface.DrawRect(12, 4, 3, 15)

	if self.PlyPing <= 50 then
		surface.SetDrawColor(Color(0, 255, 0, 200))
		surface.DrawRect(0, 15, 3, 4)
		surface.DrawRect(4, 12, 3, 7)
		surface.DrawRect(8, 8, 3, 11)
		surface.DrawRect(12, 4, 3, 15)
	elseif self.PlyPing <= 100 and self.PlyPing > 50 then
		surface.SetDrawColor(Color(255, 227, 0, 200))
		surface.DrawRect(0, 15, 3, 4)
		surface.DrawRect(4, 12, 3, 7)
		surface.DrawRect(8, 8, 3, 11)
	elseif self.PlyPing <= 150 and self.PlyPing > 100 then
		surface.SetDrawColor(Color(255, 80, 0, 200))
		surface.DrawRect(0, 15, 3, 4)
		surface.DrawRect(4, 12, 3, 7)
	elseif self.PlyPing > 150 then
		surface.SetDrawColor(Color(255, 0, 0, 200))
		surface.DrawRect(0, 15, 3, 4)
	end
end

derma.DefineControl("SBPingmeter", "Draws ping", SB_PING_METER, "DPanel")

function SB_PLY_LINE:Init()

	self.AvatarButton = self:Add("DButton")
	self.AvatarButton:Dock(LEFT)
	self.AvatarButton:DockMargin(6, 0, 0, 0)
	self.AvatarButton:SetSize(32, 32)
	self.AvatarButton.DoClick = function() end

	self.Avatar = vgui.Create("AvatarImage", self.AvatarButton)
	self.Avatar:SetSize(32, 32)
	self.Avatar:DockMargin(6, 0, 0, 0)
	self.Avatar:SetMouseInputEnabled(false)

	self.AvatarDeath = vgui.Create("DImage", self.Avatar)
	self.AvatarDeath:SetSize(32, 32)
	self.AvatarDeath:SetImage("lambda/cross.png")
	self.AvatarDeath:SetMouseInputEnabled(false)
	self.AvatarDeath:SetVisible(false)

	self.Name = self:Add("DLabel")
	self.Name:Dock(FILL)
	self.Name:SetFont("lambda_sb_def")
	self.Name:SetTextColor(Color(255, 255, 255, 240))
	self.Name:DockMargin(8, 0, 0, 0)
	self.Ping = self:Add("SBPingmeter")
	self.Ping:Dock(RIGHT)
	self.Ping:SetWidth(50)
	self.Deaths = self:Add("DLabel")
	self.Deaths:Dock(RIGHT)
	self.Deaths:SetWidth(50)
	self.Deaths:SetFont("lambda_sb_def")
	self.Deaths:SetTextColor(Color(255, 255, 255, 240))
	self.Deaths:SetContentAlignment(5)
	self.Kills = self:Add("DLabel")
	self.Kills:Dock(RIGHT)
	self.Kills:SetWidth(50)
	self.Kills:SetFont("lambda_sb_def")
	self.Kills:SetTextColor(Color(255, 255, 255, 240))
	self.Kills:SetContentAlignment(5)
	self:Dock(TOP)
	self:DockPadding(3, 3, 3, 3)
	self:SetHeight(32 + 3 * 2)
	self:DockMargin(2, 0, 2, 2)
end

function SB_PLY_LINE:Setup(ply)
	self.Player = ply
	self.Avatar:SetPlayer(ply)
	self.Think(self)
	self.Ping:Setup(ply)
end

function SB_PLY_LINE:Think()
	if not IsValid(self.Player) then
		self:SetZPos(9999)
		self:Remove()
		return
	end

	self.AvatarDeath:SetVisible(not self.Player:Alive())
	self.Name:SetText(self.Player:Nick())
	self.Kills:SetText(self.Player:Frags())
	self.Deaths:SetText(self.Player:Deaths())

	if self.Player:Team() == TEAM_CONNECTING then
		self:SetZPos(2000 + self.Player:EntIndex())
		return
	end

	local kd = self.Player:Frags()
	if self.Player:Deaths() > 0 then 
		kd = kd / self.Player:Deaths()
	end 
	if kd < 0 then 
		kd = 0
	end
	self:SetZPos((kd * -50) + self.Player:EntIndex())
end

function SB_PLY_LINE:Paint(w, h)
	if not IsValid(self.Player) then
		return
	end 
	if self.Player:Team() == TEAM_CONNECTING then
		surface.SetDrawColor(93, 93, 93, 230)
		surface.DrawRect(0, 0, 4, h)
		surface.SetDrawColor(0, 0, 0, 170)
		surface.DrawRect(0, 4, 0, w, h)
		return
	end

	if not self.Player:Alive() then
		surface.SetDrawColor(93, 93, 93, 230)
		surface.DrawRect(0, 0, 4, h)
		surface.SetDrawColor(0, 0, 0, 170)
		surface.DrawRect(4, 0, w, h)
		return
	end

	draw.RoundedBox(0, 0, 0, 4, h, Color(255, 147, 30, 230))
	draw.RoundedBox(0, 4, 0, w, h, Color(0, 0, 0, 170))
end

SBPlayerLine = vgui.RegisterTable(SB_PLY_LINE, "DPanel")

function SB_PANEL:Init()
	self.Scores = self:Add("DScrollPanel")
	self.Scores:Dock(FILL)
	self.Scores:DockMargin(0, 200, 0, 0)
end

function SB_PANEL:PerformLayout()
	self:SetSize(700, ScrH() - 200)
	self:SetPos(ScrW() / 2 - 350, 0)
end

function SB_PANEL:Paint(w, h)
	local _, y = self.Scores:GetPos()
	-- this was the best way to get an image in here... screw u dimage and power of 2
	surface.SetMaterial(lambda_logo)
	surface.SetDrawColor(255, 255, 255, 250)
	surface.DrawTexturedRect(94, -160, 512, 512)

	surface.SetDrawColor(255, 147, 30, 230)
	surface.DrawRect(2, y - 28, 4, 24)

	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawRect(6, y - 28, w - 8, 24)

	draw.SimpleTextOutlined("Currently playing on " .. game.GetMap() .. " with " .. player.GetCount() .. " players.", "lambda_sb_def_sm", 10, y - 24, Color(255, 255, 255, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 0, Color(0, 0, 0, 250))
	draw.SimpleTextOutlined("FRAGS", "lambda_sb_def_sm", 545, y - 24, Color(255, 255, 255, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 0.2, Color(0, 0, 0, 250))
	draw.SimpleTextOutlined("DEATHS", "lambda_sb_def_sm", 595, y - 24, Color(255, 255, 255, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 0.2, Color(0, 0, 0, 250))
end

function SB_PANEL:Think()

	self.ScoreEntries = self.ScoreEntries or {}

	for k, v in pairs(player.GetAll()) do
		if self.ScoreEntries[v] ~= nil then 
			continue 
		end

		local entry = vgui.CreateFromTable(SBPlayerLine, v.ScoreEntry)
		entry:Setup(v)

		self.ScoreEntries[v] = entry
		self.Scores:AddItem(entry)
	end

end

SBMain = vgui.RegisterTable(SB_PANEL, "EditablePanel")

LAMBDA_SCOREBOARD = LAMBDA_SCOREBOARD or nil
if IsValid(LAMBDA_SCOREBOARD) then 
	LAMBDA_SCOREBOARD:Remove()
	LAMBDA_SCOREBOARD = nil 
end 

function GM:ScoreboardShow(keepOpen)

	if not IsValid(LAMBDA_SCOREBOARD) then
		LAMBDA_SCOREBOARD = vgui.CreateFromTable(SBMain)
	end

	if IsValid(LAMBDA_SCOREBOARD) then
		LAMBDA_SCOREBOARD:Show()
	end

	if LAMBDA_SCOREBOARD.KeepOpen ~= true then
		LAMBDA_SCOREBOARD.KeepOpen = keepOpen
	end 

	return false
end

function GM:ScoreboardHide()

	if IsValid(LAMBDA_SCOREBOARD) then
		if LAMBDA_SCOREBOARD.KeepOpen ~= true then
			LAMBDA_SCOREBOARD:Hide()
		end
	end

	return false

end
