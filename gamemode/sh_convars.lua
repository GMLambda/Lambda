if SERVER then
	AddCSLuaFile()
end

GM.ConVars = {}

function GM:RegisterConVar(name, value, flags, helptext)
	local prefix = "lambda_"
	local actualName = prefix .. name
	local actualValue = ""

	if isbool(value) then
		actualValue = tostring(tonumber(value))
	elseif isstring(value) then
		actualValue = value
	else
		actualValue = tostring(value)
	end

	local convar = CreateConVar(actualName, actualValue, flags, helptext)
	self.ConVars[name] = convar

	return convar

end

function GM:GetRegisteredConVar(name)
	return self.ConVars[name]
end

if SERVER then
	-- Server --
	lambda_max_respawn_timeout = GM:RegisterConVar("max_respawn_timeout", 20, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Time before player can respawn")
	lambda_map_restart_timeout = GM:RegisterConVar("map_restart_timeout", 20, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Time before a new round starts when all players are dead")
	lambda_instance_id = GM:RegisterConVar("instance_id", 1, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Allows to assign a unique instance id to support multiple srcds instances at once from the same directory.")
	lambda_map_change_timeout = GM:RegisterConVar("map_change_timeout", 60, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Time before changing level as soon first player gets to it")
	lambda_player_god = GM:RegisterConVar("player_god", 0, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "No player damage")
	lambda_pickup_delay = GM:RegisterConVar("pickup_delay", 0.5, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "The time to wait before player can pickup again")
	lambda_dynamic_checkpoints = GM:RegisterConVar("dynamic_checkpoints", 1, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Dynamically creates checkpoints if the position is appropriate")
	-- Client side --
else
	lambda_dynamic_crosshair = GM:RegisterConVar("dynamic_crosshair", 1, bit.bor(0, FCVAR_ARCHIVE), "Dynamic crosshair")
	lambda_postprocess = GM:RegisterConVar("postprocess", 1, bit.bor(0, FCVAR_ARCHIVE), "Postprocessing")
	lambda_hud_text_color = GM:RegisterConVar("hud_text_color", "255 208 64", bit.bor(0, FCVAR_ARCHIVE), "HUD Text Color R(0-255), G(0-255), B(0-255)")
	lambda_hud_bg_color = GM:RegisterConVar("hud_bg_color", "0 0 0", bit.bor(0, FCVAR_ARCHIVE), "HUD BG Color R(0-255), G(0-255), B(0-255)")
	lambda_player_color = GM:RegisterConVar("player_color", "0.3 1 1", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Player color")
	lambda_weapon_color = GM:RegisterConVar("weapon_color", "0.3 1 1", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Weapon color")
	lambda_playermdl = GM:RegisterConVar("playermdl", "male_01", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Player model")
end

lambda_gametype = GM:RegisterConVar("gametype", "hl2", bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Current gametype")
lambda_walkspeed = GM:RegisterConVar("walkspeed", 150, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Walk speed")
lambda_normspeed = GM:RegisterConVar("normspeed", 190, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Walk speed")
lambda_sprintspeed = GM:RegisterConVar("sprintspeed", 320, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Sprint speed")
lambda_connect_timeout = GM:RegisterConVar("connect_timeout", 120, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Time required before player is considered to time out.")
lambda_playercollision = GM:RegisterConVar("playercollision", 1, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Enables or disables collisions between players.")
lambda_friendlyfire = GM:RegisterConVar("friendlyfire", 0, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Enables friendly fire, only works if player collisions enabled.")
lambda_playertracker = GM:RegisterConVar("player_tracker", 1, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Allows to see players through walls")
