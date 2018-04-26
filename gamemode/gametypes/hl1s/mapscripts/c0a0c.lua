AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons =
	{

	},
	Ammo =
	{

	},
	Armor = 0,
	HEV = false,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	--["spawnitems_template"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)
	--DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT
