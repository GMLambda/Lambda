util.AddNetworkString("LambdaStartVote")
util.AddNetworkString("LambdaEndVote")
util.AddNetworkString("LambdaVote")
util.AddNetworkString("LambdaRevote")

local isvoting = false
local currentvote = false
local results = false

function IsVoting()
	return isvoting
end

function GM:StartVote(ply, name, time, successCallback, failedCallback, ...)
	local options = {...}

	if isvoting then
		timer.Simple(5, function() self:StartVote(name, time, callback, unpack(options)) end)
		return
	end

	if !name then
		print("no vote name specified")
		return
	end

	if !time or !isnumber(tonumber(time)) then
		print("vote time error")
		return
	end

	if !options[1] then
		print("no vote time")
		return
	end

	if ply and ply:IsValid() then ply = ply:Name() else ply = "server" end

	isvoting = true

	currentvote = {}
	currentvote.name = name
	currentvote.time = time
	currentvote.ply = ply
	currentvote.successCallback = successCallback
	currentvote.failedCallback = failedCallback
	currentvote.options = options
	currentvote.votes = {}

	results = {}

	self:SendVote()

	PrintMessage(HUD_PRINTTALK,"A vote has been started by " .. ply ..  ".")

	timer.Create("Vote", tonumber(time), 1, function()
		self:EndVote()
	end)

	return currentvote
end

function GM:SendVote(ply)
	if isvoting and currentvote then
		net.Start("LambdaStartVote")
			net.WriteString(currentvote.name)
			net.WriteString(currentvote.ply)
			net.WriteTable(currentvote.options)
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end
end

function GM:EndVote()
	net.Start("LambdaEndVote")
	net.Broadcast()

	winner = 0
	if table.Count(results) > 0 then
		for k, v in pairs(results) do
			if v != 0 and (winner == 0 or v > results[winner]) then
				winner = k
			end
		end
		if winner > 0 then currentvote.successCallback(currentvote.options[winner]) end
	end

	if winner == 0 then
		if currentvote.failedCallback then
			currentvote.failedCallback()
		else
			print("vote failed noone voted")
		end
	end

	currentvote = false
	results = false
	isvoting = false
end

net.Receive("LambdaVote",function(l,ply)
	if isvoting then
		local num = net.ReadInt(4)
		if !currentvote.votes[ply:SteamID()] and num >= 1 and num <= table.Count(currentvote.options) then
			results[num] = results[num] and results[num] + 1 or 1
			currentvote.votes[ply:SteamID()] = num
		end
	end
end)

hook.Add("PlayerInitialSpawn", "SendVoteOnSpawn", function(ply)
	GAMEMODE:SendVote(ply)
end)