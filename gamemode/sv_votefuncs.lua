local voteinfo = {}
voteinfo.voting = false
voteinfo.rtv = false
voteinfo.map = false
voteinfo.ply = false
voteinfo.time = 20

function GM:StartSkipMapVote(t, ply)
	local time =  t or voteinfo.time
	local nextmap = table.KeyFromValue(self:GetGameTypeData("MapList"), game.GetMap())

	voteinfo.map = self:GetGameTypeData("MapList")[nextmap + 1]
	voteinfo.voting = true
	voteinfo.options = {"Yes","No"}

	self:StartVote(false,"Vote to skip the map.", time, VoteEnd, VoteFailed, unpack(voteinfo.options))
end

function GM:StartRestartMapVote(t, ply)
	local time =  t or voteinfo.time
	voteinfo.map = game.GetMap()

	voteinfo.voting = true
	voteinfo.options = {"Yes","No"}

	self:StartVote(ply,"Vote to restart the map.", time, VoteEnd, VoteFailed, unpack(voteinfo.options))
end

function GM:StartMapVote(map, t, ply)
	local time =  t or voteinfo.time
	if !map or !file.Exists("maps/" .. map .. ".bsp", "GAME") then print("map doesnt exist") return end
	voteinfo.map = map

	voteinfo.voting = true
	voteinfo.options = {"Yes","No"}

	self:StartVote(ply,"Vote to change the map to " .. voteinfo.map, time, VoteEnd, VoteFailed, unpack(voteinfo.options))
end

function GM:StartKickVote(id, t, ply)
	local time = t or voteinfo.time
	if !Player(id) then return end
	voteinfo.ply = Player(id)

	voteinfo.voting = true
	voteinfo.options = {"Yes","No"}

	self:StartVote(ply, "Vote to kick player " .. voteinfo.ply:Nick(), time, VoteEnd, VoteFailed, unpack(voteinfo.options))
end

function VoteEnd(choice)
	if !voteinfo.voting then return end
	if choice == voteinfo.options[1] then
		if voteinfo.map and !voteinfo.ply then
			print("Vote passed. Changing map in 5 seconds.")
			PrintMessage(HUD_PRINTTALK,"Vote passed. Changing map in 5 seconds.")
			timer.Simple(5, function() VoteExec(voteinfo.map) end)
		else
			print("Vote passed. Kicking player " .. voteinfo.ply:Nick())
			voteinfo.ply:Kick("You have been votekicked.")
			voteinfo.ply = false
		end
	else
		print("Vote failed.")
	end
end

function VoteExec(map)

	if map == game.GetMap() then
		GAMEMODE:CleanUpMap()
	else
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end

	voteinfo.voting = false
	voteinfo.map = false
	voteinfo.ply = false
end

function VoteFailed()
	if !voteinfo.voting then return end

	PrintMessage(HUD_PRINTTALK,"Vote failed. No one voted.")
	voteinfo.voting = false
	voteinfo.map = false
	voteinfo.ply = false
end