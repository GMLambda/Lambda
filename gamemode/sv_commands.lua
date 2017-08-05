-- Function to check if it is ran by an admin player or the server console
local function whoisrunning(ply)
	if IsValid(ply) and ply:IsAdmin() then
		return true
	elseif !IsValid(ply) then
		return true
	else
		return false
	end
end

local function PlayerNoTarget(ply, cmd, args, argStr)
	local flags = ply:GetFlags()
	if bit.band(flags, FL_NOTARGET) ~= 0 then
		DbgPrint("Player: " .. tostring(ply) .. " target")
		ply:SetNoTarget(false)
	else
		DbgPrint("Player: " .. tostring(ply) .. " notarget")
		ply:SetNoTarget(true)
	end
end
concommand.Add("lambda_notarget", PlayerNoTarget, nil, nil, bit.bor(FCVAR_CHEAT, FCVAR_CLIENTCMD_CAN_EXECUTE))

local function RestartLevel(ply, cmd, args)
	if whoisrunning(ply) == false then return end
	game.ConsoleCommand("changelevel " .. game.GetMap()  .. "\n")
end
concommand.Add("lambda_restart", RestartLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_SERVER_CAN_EXECUTE))

local function PreviousLevel(ply, cmd, args)
	if whoisrunning(ply) == false then return end
	local prevmap = table.FindPrev(GAMEMODE.MapList, game.GetMap())
	game.ConsoleCommand("changelevel " .. prevmap .. "\n")
end
concommand.Add("lambda_prevmap", PreviousLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_SERVER_CAN_EXECUTE))

local function NextLevel(ply, cmd, args)
	if whoisrunning(ply) == false then return end
	local nextmap = table.FindNext(GAMEMODE.MapList, game.GetMap())
	game.ConsoleCommand("changelevel " .. nextmap .. "\n")
end
concommand.Add("lambda_nextmap", NextLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_SERVER_CAN_EXECUTE))

local function ResetLevel(ply, cmd, args)
	if whoisrunning(ply) == false then return end
	GAMEMODE:CleanUpMap()
	DbgPrint("Lambda_RESET: Map cleanup and reset")
end
concommand.Add("lambda_reset", ResetLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE))
