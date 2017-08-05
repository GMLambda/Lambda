include("sh_taunts.lua")

--local DbgPrint = GetLogging("Taunts")

local TauntIndex = 1
local TauntMaxDisplay = 3 -- Each direction
local TauntSelection = false

surface.CreateFont("TauntFont",
{
	font = "Arial",
	size = 30,
	weight = 500,
	blursize = 1,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true
})

surface.CreateFont("TauntFont2",
{
	font = "Arial",
	size = 30,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

function DrawTauntElement(text, xpos, size, alpha, offset)

	local w, h = ScrW(), ScrH()
	local x = 100
	local y = (h / 2) + xpos
	offset = offset or 0
	--mat:Translate( Vector( w/2, h/2 ) )
	--mat:Rotate( Angle( 0,0,0 ) )

	local mat1 = Matrix()
	mat1:Scale( Vector(1, 1, 1) * size )
	mat1:SetTranslation( Vector( x, y, 0 ) )
	--mat:Translate( -Vector( w/2, h/2 ) )

	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	cam.PushModelMatrix(mat1)
		surface.SetTextPos(offset, 0)
		surface.SetFont("TauntFont")
		surface.SetTextColor(0, 0, 0, alpha * 0.5)
		surface.DrawText(text)
	cam.PopModelMatrix()

	local mat2 = Matrix()
	mat2:Scale( Vector(1, 1, 1) * size )
	mat2:SetTranslation( Vector( x, y, 0 ) )

	cam.PushModelMatrix(mat2)
			surface.SetTextPos(offset, 0)
			surface.SetFont("TauntFont2")
			surface.SetTextColor(255, 255, 255, alpha)
			surface.DrawText(text)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()

	return w, h

end

function DrawTauntsMenu()

	local ply = LocalPlayer()
	local gender = ply:GetGender()
	local taunts = Taunts[gender]
	local count = 0
	if taunts ~= nil then
		count = #taunts
	end

	if TauntIndex > count then
		TauntIndex = count
	end
	if TauntIndex < 1 then
		TauntIndex = 1
	end

	local x
	local xpos = (3 * 20) + math.pow(3, 1.5)

	-- Back
	local back_max = TauntIndex - TauntMaxDisplay
	if back_max < 1 then
		back_max = 1
	end

	x = 1
	for i = (TauntIndex - 1), back_max, -1 do
		local taunt = Taunts[gender][i]
		if not taunt then
			break
		end
		local alpha = (1 - (x / 4)) * 50
		DrawTauntElement(taunt.Name, xpos, 1.2 - (x / 3), alpha)
		x = x + 1
		xpos = xpos - 35 - math.pow(x + 1, 1.1)
	end

	xpos = (3 * 20) + math.pow(3, 1.2) + 40

	-- Current
	local taunt = Taunts[gender][TauntIndex]
	if not taunt then
		return
	end

	--text, xpos, size, alpha
	local scaleTime = CurTime() * 4
	local offset = 10 + (math.sin(scaleTime) * math.cos(scaleTime)) * 10
	DrawTauntElement(taunt.Name, xpos, 1.3, 255, offset)
	xpos = xpos + 50

	-- Front
	local front_max = TauntIndex + TauntMaxDisplay
	if front_max > count then
		front_max = count
	end

	x = 1
	for i = (TauntIndex + 1), front_max do
		taunt = Taunts[gender][i]
		if not taunt then
			break
		end
		local alpha = (1 - (x / 4)) * 50
		DrawTauntElement(taunt.Name, xpos, 1.2 - (x / 3), alpha)
		x = x + 1
		xpos = xpos + 35 + math.pow(x + 1, 1.1)
	end

end

function SendSelectedTaunt()

	local ply = LocalPlayer()
	ply.LastTaunt = ply.LastTaunt or (RealTime() - 5)

	if RealTime() - ply.LastTaunt < 2 then
		return false
	end

	ply.LastTaunt = RealTime()

	local gender = ply:GetGender()
	local taunts = Taunts[gender]
	local count = #taunts

	if TauntIndex < 1 or TauntIndex > count then
		return false
	end

	local taunt = Taunts[gender][TauntIndex]
	if not taunt then
		return false
	end

	net.Start("PlayerStartTaunt")
	net.WriteFloat(TauntIndex)
	net.SendToServer()
end

hook.Add( "OnContextMenuOpen", "Lambda_Taunts", function()

	local ply = LocalPlayer()
	if IsValid(ply) and ply:Alive() == false then
		return
	end

	TauntSelection = true
	hook.Add("HUDPaint", "LambdaTaunts", DrawTauntsMenu)
end)

hook.Add( "OnContextMenuClose", "Lambda_Taunts", function()
	TauntSelection = false
	SendSelectedTaunt()
	hook.Remove("HUDPaint", "LambdaTaunts")
end)

--[[
concommand.Add("+showtaunts", function()
	TauntSelection = true
	hook.Add("HUDPaint", "LambdaTaunts", DrawTauntsMenu)
end)

concommand.Add("-showtaunts", function()
	TauntSelection = false
	SendSelectedTaunt()
	hook.Remove("HUDPaint", "LambdaTaunts")
end)
]]

hook.Add("PlayerBindPress", "LambdaTaunts", function(ply, bind, pressed)

	if TauntSelection then
		if bind == "invnext" and pressed then
			TauntIndex = TauntIndex + 1
			return true
		elseif bind == "invprev" and pressed then
			TauntIndex = TauntIndex - 1
			return true
		end
	end

end)
