AddCSLuaFile("cl_taunts.lua")

include("sh_taunts.lua")

util.AddNetworkString("PlayerStartTaunt")

function PlaceRunPointer(ply)

	local traceang = ply:EyeAngles()
	local tracepos = ply:EyePos()
	local tracelen = traceang:Forward() * 10000
	local filter = {ply}
	if ply:InVehicle() then
		table.insert(filter, ply:GetVehicle())
	end
	local trace = util.QuickTrace(tracepos, tracelen, filter)

	if trace.HitWorld or (IsValid(trace.Entity) and not trace.Entity:IsNPC()) then
		local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetNormal( trace.HitNormal )
			effectdata:SetRadius(50)
		util.Effect( "lambda_pointer", effectdata, true )

		local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetStart( ply:GetShootPos() - Vector(0,0,5) )
			effectdata:SetAttachment( 1 )
			effectdata:SetEntity( ply )
		util.Effect( "ToolTracer", effectdata )
	end
end

function PlaceRunPointerLocal(ply)

	local effectdata = EffectData()
		effectdata:SetOrigin( ply:GetPos() )
		effectdata:SetNormal( Vector(0,0,1) )
		effectdata:SetRadius(50)
	util.Effect( "lambda_pointer", effectdata, true )

end

net.Receive("PlayerStartTaunt", function(len, ply)

	if ply:Alive() == false then
		return
	end

	local TauntIndex = net.ReadFloat()
	local gender = ply:GetGender()

	local taunt = Taunts[gender][TauntIndex]
	local snd = table.Random(taunt.Sounds)

	if taunt.Name == "Over here" then
		ply:SendLua[[RunConsoleCommand("act", "wave")]]
		PlaceRunPointerLocal(ply)
	elseif taunt.Name == "Over there" then
		ply:SendLua[[RunConsoleCommand("act", "forward")]]
		PlaceRunPointer(ply)
	elseif taunt.Name == "Scanners" then
		ply:SendLua[[RunConsoleCommand("act", "forward")]]
	elseif taunt.Name == "Nice" then
		ply:SendLua[[RunConsoleCommand("act", "agree")]]
	elseif taunt.Name == "Take cover" then
		ply:SendLua[[RunConsoleCommand("act", "halt")]]
	end

	ply:EmitSound(snd)

end)
