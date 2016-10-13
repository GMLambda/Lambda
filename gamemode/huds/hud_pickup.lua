GM.PickupHistory = {}
GM.PickupHistoryLast = 0
GM.PickupHistoryTop = ScrH() / 2
GM.PickupHistoryWide = 300
GM.PickupHistoryCorner = surface.GetTextureID( "gui/corner8" )

GM.SymbolLookupTable =
{
	["Pistol"] = "p",
	["SMG1"] = "\x72",
	["SMG1_Grenade"] = "\x5F",
	["357"] = "\x71",
	["AR2"] = "u",
	["AR2AltFire"] = "z",
	["Buckshot"] = "s",
	["XBowBolt"] = "w",
	["Grenade"] = "v",
	["RPG_Round"] = "x",

	["weapon_smg1"] = "&",
	["weapon_shotgun"] = "(",
	["weapon_pistol"] = "%",
	["weapon_357"] = "$",
	["weapon_crossbow"] = ")",
	["weapon_ar2"] = ":",
	["weapon_frag"] = "_",
	["weapon_rpg"] = ";",
	["weapon_crowbar"] = "^",
	["weapon_physcannon"] = "!",
	["weapon_physgun"] = "!",
	["weapon_bugbait"] = "~",
}

surface.CreateFont( "LAMBDA_AMMO",
{
	font		= 'halflife2',
	size		= 46
} )

--[[---------------------------------------------------------
   Name: gamemode:HUDWeaponPickedUp( wep )
   Desc: The game wants you to draw on the HUD that a weapon has been picked up
-----------------------------------------------------------]]
function GM:HUDWeaponPickedUp( wep )

	if ( !IsValid( LocalPlayer() ) || !LocalPlayer():Alive() ) then return end
	if ( !IsValid( wep ) ) then return end
	if ( !isfunction( wep.GetPrintName ) ) then return end

	local pickup = {}
	pickup.time			= CurTime()
	pickup.symbol		= self.SymbolLookupTable[wep:GetClass()]
	pickup.name			= wep:GetPrintName()
	pickup.holdtime		= 10
	pickup.fadein		= 0.04
	pickup.fadeout		= 0.3
	pickup.font			= "DermaDefaultBold"
	pickup.color		= Color( 255, 220, 0, 100 )

	surface.SetFont( pickup.font )
	local w, h = surface.GetTextSize( pickup.name )
	pickup.height		= h + 10
	pickup.width		= w

	if pickup.symbol then
		surface.SetFont("LAMBDA_AMMO")
		local w,_ = surface.GetTextSize(pickup.symbol)
		pickup.width = pickup.width + w + 16
		pickup.swidth = w
	end

	if ( self.PickupHistoryLast >= pickup.time ) then
		pickup.time = self.PickupHistoryLast + 0.05
	end

	table.insert( self.PickupHistory, pickup )
	self.PickupHistoryLast = pickup.time

end

--[[---------------------------------------------------------
   Name: gamemode:HUDItemPickedUp( itemname )
   Desc: An item has been picked up..
-----------------------------------------------------------]]
function GM:HUDItemPickedUp( itemname )

	if ( !IsValid( LocalPlayer() ) || !LocalPlayer():Alive() ) then return end

	-- Try to tack it onto an exisiting ammo pickup
	if ( self.PickupHistory ) then

		for k, v in pairs( self.PickupHistory ) do

			if ( v.name == "#" .. itemname ) then

				v.amount = v.amount + 1

				local fadeDelay = 1 - v.fadein
				local fadeOut = 1 - v.fadeout
				local elapsed = CurTime() - v.time
				if elapsed > (v.holdtime - fadeDelay - fadeOut) then
					v.time = CurTime() - v.fadein
				else
					v.time = CurTime() - fadeDelay
				end

				return

			end

		end

	end

	local pickup = {}
	pickup.time			= CurTime()
	pickup.name			= "#"..itemname
	pickup.holdtime		= 10
	pickup.fadein		= 0.04
	pickup.fadeout		= 0.3
	pickup.font			= "DermaDefaultBold"
	pickup.color		= Color( 180, 255, 180, 255 )
	pickup.amount		= 1

	surface.SetFont( pickup.font )
	local w, h = surface.GetTextSize( pickup.name )
	pickup.height		= h + 10
	pickup.width		= w

	if ( self.PickupHistoryLast >= pickup.time ) then
		pickup.time = self.PickupHistoryLast + 0.05
	end

	table.insert( self.PickupHistory, pickup )
	self.PickupHistoryLast = pickup.time

end

--[[---------------------------------------------------------
   Name: gamemode:HUDAmmoPickedUp( itemname, amount )
   Desc: Ammo has been picked up..
-----------------------------------------------------------]]
function GM:HUDAmmoPickedUp( itemname, amount )

	if ( !IsValid( LocalPlayer() ) || !LocalPlayer():Alive() ) then return end

	-- Try to tack it onto an exisiting ammo pickup
	if ( self.PickupHistory ) then

		for k, v in pairs( self.PickupHistory ) do

			if ( v.name == "#" .. itemname .. "_ammo" ) then

				v.amount = tostring( tonumber( v.amount ) + amount )

				local fadeDelay = 1 - v.fadein
				local fadeOut = 1 - v.fadeout
				local elapsed = CurTime() - v.time
				if elapsed > (v.holdtime - fadeDelay - fadeOut) then
					v.time = CurTime() - v.fadein
				else
					v.time = CurTime() - fadeDelay
				end

				return

			end

		end

	end

	--DbgPrint(itemname)

	local pickup = {}
	pickup.time			= CurTime()
	pickup.symbol		= self.SymbolLookupTable[itemname]
	pickup.name			= "#" .. itemname .. "_ammo"
	pickup.holdtime		= 10
	pickup.fadein		= 0.04
	pickup.fadeout		= 0.3
	pickup.font			= "DermaDefaultBold"
	pickup.color		= Color( 180, 200, 255, 255 )
	pickup.amount		= tostring( amount )

	surface.SetFont( pickup.font )
	local w, h = surface.GetTextSize( pickup.name )
	pickup.height	= h + 10
	pickup.width	= w

	local w, h = surface.GetTextSize( pickup.amount )
	pickup.xwidth	= w
	pickup.width	= pickup.width + w + 16

	if pickup.symbol then
		surface.SetFont("LAMBDA_AMMO")
		local w,h = surface.GetTextSize(pickup.symbol)
		pickup.width = pickup.width + w + 16
		pickup.swidth = w
	end

	if ( self.PickupHistoryLast >= pickup.time ) then
		pickup.time = self.PickupHistoryLast + 0.05
	end

	table.insert( self.PickupHistory, pickup )
	self.PickupHistoryLast = pickup.time

end

local blur = Material("pp/blurscreen")

local function DrawBlurRect(x, y, w, h)
	local X, Y = 0,0

	surface.SetDrawColor(255, 255, 255)
	--surface.SetMaterial(blur)
	--[[
	for i = 1, 5 do
		blur:SetFloat("$blur", (i / 3) * (5))
		blur:Recompute()

		render.UpdateScreenEffectTexture()

		render.SetScissorRect(x, y, x+w, y+h, true)
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
		render.SetScissorRect(0, 0, 0, 0, false)
	end
	]]

   draw.RoundedBox(3, x, y, w, h, Color(0, 0, 0, 30))

   surface.SetDrawColor(0, 0, 0)
   --surface.DrawOutlinedRect(x, y, w, h)

end

function GM:HUDDrawPickupHistory()

	if ( self.PickupHistory == nil ) then return end

	local x, y = ScrW() - self.PickupHistoryWide - 20, self.PickupHistoryTop
	local tall = 0
	local wide = 0

	for k, v in pairs( self.PickupHistory ) do

		if ( !istable( v ) ) then

			Msg( tostring( v ) .."\n" )
			PrintTable( self.PickupHistory )
			self.PickupHistory[ k ] = nil
			return

		end

		if ( v.time < CurTime() ) then

			if ( v.y == nil ) then v.y = y end

			v.y = ( v.y * 5 + y ) / 6

			local delta = ( v.time + v.holdtime ) - CurTime()
			delta = delta / v.holdtime

			local alpha = 255
			local colordelta = math.Clamp( delta, 0.6, 0.7 )

			-- Fade in/out
			if ( delta > 1 - v.fadein ) then
				alpha = math.Clamp( ( 1.0 - delta ) * ( 255 / v.fadein ), 0, 255 )
			elseif ( delta < v.fadeout ) then
				alpha = math.Clamp( delta * ( 255 / v.fadeout ), 0, 255 )
			end

			v.x = x + self.PickupHistoryWide - (self.PickupHistoryWide * ( alpha / 255 ) )

			local rx, ry, rw, rh = math.Round( v.x - 8 ), math.Round( v.y - ( v.height / 2 ) - 4 ), math.Round( self.PickupHistoryWide + 19 ), math.Round( v.height + 10 )
			local bordersize = 8

			DrawBlurRect( rx, ry, rw, rh )

			local offsetX = 0

			if v.symbol ~= nil then
				draw.SimpleText( v.symbol, "LAMBDA_AMMO", v.x + 55 , v.y - v.height, Color( 255, 220, 0, alpha ), TEXT_ALIGN_RIGHT )
				offsetX = 40
			end

			--draw.SimpleText( v.name, v.font, v.x + v.height + 4, v.y - ( v.height / 2 ) + 4, Color( 0, 0, 0, alpha * 0.5 ) )
			draw.SimpleText( v.name, v.font, offsetX + v.x + v.height + 4, v.y - ( v.height / 2 ) + 4, Color( 255, 220, 0, alpha ) )

			if ( v.amount ) then

				--draw.SimpleText( v.amount, v.font, v.x + self.PickupHistoryWide + 1, v.y - ( v.height / 2 ) + 4, Color( 0, 0, 0, alpha * 0.5 ), TEXT_ALIGN_RIGHT )
				draw.SimpleText( v.amount, v.font, v.x + self.PickupHistoryWide, v.y - ( v.height / 2 ) + 4, Color( 255, 220, 0, alpha ), TEXT_ALIGN_RIGHT )

			end

			y = y + ( v.height + 20 )
			tall = tall + v.height + 18
			wide = math.Max( wide, v.width + v.height + 24 )

			if ( alpha == 0 ) then self.PickupHistory[ k ] = nil end

		end

	end

	self.PickupHistoryTop = ( self.PickupHistoryTop * 5 + ( ScrH() * 0.75 - tall ) / 2 ) / 6
	self.PickupHistoryWide = ( self.PickupHistoryWide * 5 + wide ) / 6

end
