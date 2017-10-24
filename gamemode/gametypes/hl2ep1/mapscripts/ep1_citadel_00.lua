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
	HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
}

MAPSCRIPT.EntityFilterByName =
{
}

function MAPSCRIPT:Init()

	DbgPrint("MapScript EP1")

end

function MAPSCRIPT:PostInit()

	if SERVER then

		ents.WaitForEntityByName("Van", function(ent)
			ent:SetModel("models/props_unique/subwaycar_all_onetexture.mdl")
		end)
	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

end

return MAPSCRIPT
