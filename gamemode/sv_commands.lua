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
	if !ply:IsAdmin() then return end
	local curmap = game.GetMap()
	game.ConsoleCommand("changelevel " .. curmap  .. "\n")
end
concommand.Add("lambda_restart", RestartLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE))

local function PreviousLevel(ply, cmd, args)
	if !ply:IsAdmin() then return end
	local curmap = game.GetMap()
	local prevmap = table.FindPrev(GAMEMODE.MapList,curmap)
	game.ConsoleCommand("changelevel " .. prevmap .. "\n")
end
concommand.Add("lambda_prevmap", PreviousLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE))

local function NextLevel(ply, cmd, args)
	if !ply:IsAdmin() then return end
	local curmap = game.GetMap()
	local nextmap = table.FindNext(GAMEMODE.MapList,curmap)
	game.ConsoleCommand("changelevel " .. nextmap .. "\n")
end
concommand.Add("lambda_nextmap", NextLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE))

local function ResetLevel(ply, cmd, args)
	if !ply:IsAdmin() then return end
	GAMEMODE:CleanUpMap()
	DbgPrint("Lambda_RESET: Map cleanup and reset")
end
concommand.Add("lambda_reset", ResetLevel, nil, nil, bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE))
