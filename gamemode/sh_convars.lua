AddCSLuaFile()

include("sh_debug.lua")

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

if SERVER then
	-- Server --
	lambda_max_respawn_timeout = GM:RegisterConVar("max_respawn_timeout", 20, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Time before player can respawn")
	lambda_map_restart_timeout = GM:RegisterConVar("map_restart_timeout", 20, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Time before a new round starts when all players are dead")
	lambda_instance_id = GM:RegisterConVar("instance_id", 1, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Allows to assign a unique instance id to support multiple srcds instances at once from the same directory.")
	lambda_map_change_timeout = GM:RegisterConVar("map_change_timeout", 60, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Time before changing level as soon first player gets to it")
	lambda_player_god = GM:RegisterConVar("player_god", 0, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "No player damage")
	lambda_pickup_delay = GM:RegisterConVar("pickup_delay", 0.5, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "The time to wait before player can pickup again")
	-- Client side --
else
	lambda_sound_override = GM:RegisterConVar("sound_override", 0, bit.bor(0, FCVAR_ARCHIVE), "Expiremental sound override system")
	lambda_dynamic_crosshair = GM:RegisterConVar("dynamic_crosshair", 1, bit.bor(0, FCVAR_ARCHIVE), "Dynamic crosshair")
	lambda_postprocess = GM:RegisterConVar("postprocess", 1, bit.bor(0, FCVAR_ARCHIVE), "Postprocessing")
end

lambda_gametype = GM:RegisterConVar("gametype", "hl2", bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Current gametype")
lambda_walkspeed = GM:RegisterConVar("walkspeed", 150, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Walk speed")
lambda_normspeed = GM:RegisterConVar("normspeed", 190, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Walk speed")
lambda_sprintspeed = GM:RegisterConVar("sprintspeed", 320, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Sprint speed")
