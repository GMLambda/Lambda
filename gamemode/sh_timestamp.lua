-- If you are wondering what this is about, this is just producing a synced timestamp not affected by any scale such
-- as host_timescale or game.GetTimeScale
if SERVER then
	AddCSLuaFile()
end

CURRENT_TIMESTAMP = CURRENT_TIMESTAMP or 0

local UpdateTimestamp

if SERVER then

	util.AddNetworkString("LambdaTimeSync")
	util.AddNetworkString("LambdaTimeClientSync")

	local lastUpdate = SysTime()

	hook.Add("Tick", "LambdaTimeSync", function()
		UpdateTimestamp()
	end)

	UpdateTimestamp = function()

		CURRENT_TIMESTAMP = SysTime()

		if CURRENT_TIMESTAMP - lastUpdate >= 1 then

			net.Start("LambdaTimeSync")
			net.WriteDouble(CURRENT_TIMESTAMP)
			net.Broadcast()

			lastUpdate = CURRENT_TIMESTAMP
		end

		local world = game.GetWorld()
		if IsValid(world) then
			world:SetNWFloat("LambdaTimeSync", CURRENT_TIMESTAMP)
		end
	end

else

	TIMESTAMP_UPDATE_TIME = TIMESTAMP_UPDATE_TIME or 0

	net.Receive("LambdaTimeSync", function(len)

		local ply = LocalPlayer()
		TIMESTAMP_UPDATE_TIME = SysTime()
		CURRENT_TIMESTAMP = net.ReadDouble()
		if IsValid(ply) then
			CURRENT_TIMESTAMP = CURRENT_TIMESTAMP + ((ply:Ping() / 2) / 1000)
		end
		--DbgPrint("Update")

	end)

end

function GetSyncedTimestamp()
	if CURRENT_TIMESTAMP == 0 then
		if SERVER then
			UpdateTimestamp()
		else
			local world = game.GetWorld()
			if IsValid(world) then
				CURRENT_TIMESTAMP = world:GetNWFloat("LambdaTimeSync", 0)
			else
				CURRENT_TIMESTAMP = 0
			end
		end
	end

	local res = CURRENT_TIMESTAMP

	if CLIENT then
		local delta = (SysTime() - TIMESTAMP_UPDATE_TIME)
		res = res + delta
	end

	return res
end

--[[
if SERVER then

	util.AddNetworkString("SyncTest")

	timer.Create("test", 1, 10, function()
		net.Start("SyncTest")
		net.WriteDouble(os.clock())
		net.WriteDouble(SysTime())
		net.WriteDouble(CurTime())
		net.WriteDouble(GetSyncedTimestamp())
		net.Broadcast()
	end)

else

	DbgPrint("  ", "os.clock", "SysTime", "CurTime", "SyncedTimestamp")
	net.Receive("SyncTest",function(len)

		local network1 = net.ReadDouble()
		local network2 = net.ReadDouble()
		local network3 = net.ReadDouble()
		local network4 = net.ReadDouble()
		local cl1 = os.clock()
		local cl2 = SysTime()
		local cl3 = CurTime()
		local cl4 = GetSyncedTimestamp()
		local diff1 = cl1 - network1
		local diff2 = cl2 - network2
		local diff3 = cl3 - network3
		local diff4 = cl4 - network4

		DbgPrint("SV", network1, network2, network3, network4)
		DbgPrint("CL", cl1, cl2, cl3, cl4)
		DbgPrint("Diff", diff1, diff2, diff3, diff4)

	end)

end
]]
