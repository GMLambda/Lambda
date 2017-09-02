-- If you are wondering what this is about, this is just producing a synced timestamp not affected by any scale such
-- as host_timescale or game.GetTimeScale
if SERVER then
	AddCSLuaFile()
end

CURRENT_TIMESTAMP = CURRENT_TIMESTAMP or 0
TIMESTAMP_UPDATE_TIME = TIMESTAMP_UPDATE_TIME or 0

local UpdateTime = 1
local UpdateTimestamp

if SERVER then

	util.AddNetworkString("LambdaTimeSync")
	util.AddNetworkString("LambdaTimeClientSync")

	hook.Add("Tick", "LambdaTimeSync", function()
		UpdateTimestamp()
	end)

	UpdateTimestamp = function()

		-- Entry update, make sure also set on world.
		local updateTimestamp = CURRENT_TIMESTAMP == 0

		CURRENT_TIMESTAMP = SysTime()

		if CURRENT_TIMESTAMP - TIMESTAMP_UPDATE_TIME >= UpdateTime then

			net.Start("LambdaTimeSync")
			net.WriteDouble(CURRENT_TIMESTAMP)
			net.Broadcast()

			TIMESTAMP_UPDATE_TIME = CURRENT_TIMESTAMP
			updateTimestamp = true
		end

		if updateTimestamp == true then
			local world = game.GetWorld()
			if IsValid(world) then
				world:SetNW2Float("LambdaTimeSync", CURRENT_TIMESTAMP)
			end
		end

	end

else

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
			-- This is a fallback to the last known timestamp before we are able to compensate.
			local world = game.GetWorld()
			if IsValid(world) then
				CURRENT_TIMESTAMP = world:GetNW2Float("LambdaTimeSync", 0)
				TIMESTAMP_UPDATE_TIME = SysTime()
			else
				CURRENT_TIMESTAMP = 0
			end
		end
	end

	if SERVER then
		return SysTime()
	end

	local res = CURRENT_TIMESTAMP

	if CLIENT then
		local delta = SysTime() - TIMESTAMP_UPDATE_TIME
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
