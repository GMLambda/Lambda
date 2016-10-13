-- Used base scoreboard for... base
local DbgPrint = GetLogging("Scoreboard")

local function DrawPingMeter(x, y, ping)
	surface.SetDrawColor(Color(90,90,92,200))
	surface.DrawRect(x,y+15,3,4)
	surface.DrawRect(x+4,y+12,3,7)
	surface.DrawRect(x+8,y+8,3,11)
	surface.DrawRect(x+12,y+4,3,15)

	if ping <= 50 then
		surface.SetDrawColor(Color(0,255,0,200))
		surface.DrawRect(x,y+15,3,4)
		surface.DrawRect(x+4,y+12,3,7)
		surface.DrawRect(x+8,y+8,3,11)
		surface.DrawRect(x+12,y+4,3,15)
	elseif ping <= 100 and ping > 50 then
		surface.SetDrawColor(Color(255,227,0,200))
		surface.DrawRect(x,y+15,3,4)
		surface.DrawRect(x+4,y+12,3,7)
		surface.DrawRect(x+8,y+8,3,11)
	elseif ping <= 150 and ping > 100 then
		surface.SetDrawColor(Color(255,80,0,200))
		surface.DrawRect(x,y+15,3,4)
		surface.DrawRect(x+4,y+12,3,7)
	elseif ping > 150 then
		surface.SetDrawColor(Color(255,0,0,200))
		surface.DrawRect(x,y+15,3,4)
	end
	surface.SetFont("ScoreboardDefaultSmall")
	surface.SetTextColor(255,255,255,255)
	surface.SetTextPos(x+20,y+4)
	surface.DrawText(ping)
end

surface.CreateFont( "ScoreboardDefault", {
	font	= "Roboto",
	size	= 22,
	weight	= 500,
	antialias = true,
})

surface.CreateFont( "ScoreboardDefaultSmall", {
	font	= "Roboto",
	size	= 15,
	weight	= 400,
	antialias = true,
	shadow	= true,
})

surface.CreateFont( "ScoreboardTitle", {
	font	= "HalfLife2",
	size	= 32,
	weight	= 700
})

local PLAYER_PANEL = {
	Init = function( self )

		self.AvatarButton = self:Add( "DButton" )
		self.AvatarButton:Dock( LEFT )
		self.AvatarButton:DockMargin(6, 0, 0, 0)
		self.AvatarButton:SetSize( 32, 32 )
		self.AvatarButton.DoClick = function()
			usrm = DermaMenu()
			usrp = usrm:AddOption("Steam profile", function() self.Player:ShowProfile() end)
			usrp:SetIcon("icon16/vcard.png")
			usrm:AddSpacer()
			usrm:Open()
			if LocalPlayer() ~= self.Player then
				if self.Player:IsMuted() then
					usrvm = usrm:AddOption("Unmute", function() self.Player:SetMuted(false) end)
					usrvm:SetIcon("icon16/sound.png")
				else
					usrv = usrm:AddOption("Mute", function() self.Player:SetMuted(true) end)
					usrv:SetIcon("icon16/sound_mute.png")
				end
			else return
			end
		end

		self.Avatar = vgui.Create( "AvatarImage", self.AvatarButton )
		self.Avatar:SetSize( 32, 32 )
		self.Avatar:DockMargin(6, 0, 0, 0)
		self.Avatar:SetMouseInputEnabled( false )

		self.Name = self:Add( "DLabel" )
		self.Name:Dock( FILL )
		self.Name:SetFont( "ScoreboardDefault" )
		self.Name:SetTextColor( Color( 250, 250, 250 ) )
		self.Name:DockMargin( 8, 0, 0, 0 )

		self.Ping = self:Add( "DLabel" )
		self.Ping:Dock( RIGHT )
		self.Ping:DockMargin( 8, 0, 0, 0 )
		self.Ping:SetWidth( 50 )
		self.Ping:SetFont( "ScoreboardDefaultSmall" )
		self.Ping:SetTextColor( Color( 250, 250, 250 ) )
		self.Ping:DockPadding( 20, 0, 0, 0 )

		self.Deaths = self:Add( "DLabel" )
		self.Deaths:Dock( RIGHT )
		self.Deaths:SetWidth( 50 )
		self.Deaths:SetFont( "ScoreboardDefault" )
		self.Deaths:SetTextColor( Color( 250, 250, 250 ) )
		self.Deaths:SetContentAlignment( 5 )

		self.Kills = self:Add( "DLabel" )
		self.Kills:Dock( RIGHT )
		self.Kills:SetWidth( 50 )
		self.Kills:SetFont( "ScoreboardDefault" )
		self.Kills:SetTextColor( Color( 250, 250, 250 ) )
		self.Kills:SetContentAlignment( 5 )

		self:Dock( TOP )
		self:DockPadding( 3, 3, 3, 3 )
		self:SetHeight( 32 + 3 * 2 )
		self:DockMargin( 2, 0, 2, 2 )

	end,

	Setup = function( self, pl )

		self.Player = pl

		self.Avatar:SetPlayer( pl )

		self:Think( self )

	end,

	Think = function( self )

		if ( !IsValid( self.Player ) ) then
			self:SetZPos( 9999 ) -- Causes a rebuild
			self:Remove()
			return
		end

		if ( self.PName == nil or self.PName ~= self.Player:Nick() ) then
			self.PName = self.Player:Nick()
			self.Name:SetText( self.PName )
		end

		if ( self.NumKills == nil or self.NumKills ~= self.Player:Frags() ) then
			self.NumKills = self.Player:Frags()
			self.Kills:SetText( self.NumKills )
		end

		if ( self.NumDeaths == nil or self.NumDeaths ~= self.Player:Deaths() ) then
			self.NumDeaths = self.Player:Deaths()
			self.Deaths:SetText( self.NumDeaths )
		end

		if ( self.NumPing == nil or self.NumPing ~= self.Player:Ping() ) then
			self.NumPing = self.Player:Ping()
			self.Ping:SetText( "" )
		end

		if ( self.Player:Team() == TEAM_CONNECTING ) then
			self:SetZPos( 2000 + self.Player:EntIndex() )
			return
		end

		self:SetZPos( ( self.NumKills * -50 ) + self.NumDeaths + self.Player:EntIndex() )

	end,

	Paint = function( self, w, h )

		if ( !IsValid( self.Player ) ) then
			return
		end

		-- KNOXED: If player is alive it will have a yellow bar on the left, if connecting or dead the bar will be gray
		if ( self.Player:Team() == TEAM_CONNECTING ) then
			draw.RoundedBox(0,0,0,4,h, Color(93,93,93,200 ))
		draw.RoundedBox(0, 4, 0, w, h, Color(0, 0, 0, 150))
			return
		end

		if ( !self.Player:Alive() ) then
			draw.RoundedBox(0,0,0,4,h, Color(93,93,93,200 ))
		draw.RoundedBox(0, 4, 0, w, h, Color(0, 0, 0, 150))
			DrawPingMeter(650, 6,self.Player:Ping())
			return
		end

		draw.RoundedBox(0,0,0,4,h, Color(255,227,0,200 ))
		draw.RoundedBox(0, 4, 0, w, h, Color(0, 0, 0, 150))
		DrawPingMeter(650, 6,self.Player:Ping())

	end
}

PLAYERLINE = vgui.RegisterTable( PLAYER_PANEL, "DPanel" )

local SCOREBOARD_PANEL = {
	Init = function( self )

		self.Header = self:Add( "Panel" )
		self.Header:Dock( TOP )
		self.Header:SetHeight( 100 )

		self.Name = self.Header:Add( "DLabel" )
		self.Name:SetFont( "ScoreboardTitle" )
		self.Name:SetTextColor( Color( 255, 255, 255, 255 ) )
		self.Name:Dock( TOP )
		self.Name:SetHeight( 40 )
		self.Name:SetContentAlignment( 5 )
		self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )


		self.Scores = self:Add( "DScrollPanel" )
		self.Scores:Dock( FILL )

	end,

	PerformLayout = function( self )

		self:SetSize( 700, ScrH() - 200 )
		self:SetPos( ScrW() / 2 - 350, 100 )

	end,

	Paint = function( self, w, h )

		draw.RoundedBox( 0, 1, 94, w-3, 1, Color(0, 0, 0, 150))
		surface.SetFont("ScoreboardDefaultSmall")
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos(1,80)
		surface.DrawText( #player.GetAll() .. "/" .. game.MaxPlayers() .. " PLAYERS ON " .. string.upper(game.GetMap()) )
		surface.SetTextPos(545, 80)
		surface.DrawText("KILLS")
		surface.SetTextPos(590,80)
		surface.DrawText("DEATHS")
		surface.SetTextPos(650,80)
		surface.DrawText("PING")

	end,

	Think = function( self, w, h )

		self.Name:SetText( "HALF-LIFE'" )

		local plyrs = player.GetAll()
		for id, pl in pairs( plyrs ) do

			if ( IsValid( pl.ScoreEntry ) ) then continue end

			pl.ScoreEntry = vgui.CreateFromTable( PLAYERLINE, pl.ScoreEntry )
			pl.ScoreEntry:Setup( pl )

			self.Scores:AddItem( pl.ScoreEntry )

		end

	end
}

SCOREBOARD = vgui.RegisterTable( SCOREBOARD_PANEL, "EditablePanel" )

function GM:ScoreboardShow()

	if ( !IsValid( g_Scoreboard ) ) then
		g_Scoreboard = vgui.CreateFromTable( SCOREBOARD )
	end

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Show()
		g_Scoreboard:MakePopup()
	end
	return false

end


function GM:ScoreboardHide()

	if ( IsValid(usrm)) then
		usrm:Hide()
	end

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Hide()
	end
	return false

end
