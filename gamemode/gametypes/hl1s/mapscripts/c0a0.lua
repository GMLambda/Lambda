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

function MAPSCRIPT:LevelPostInit()
	DbgPrint("LevelPostInit")
	for k,v in pairs(ents.FindByClass("info_player_start")) do
		v:Remove()
	end

	ents.WaitForEntityByName("train", function(ent)
		DbgPrint("Fixing spawn position")
		ent:Fire("Stop")

		local pos = ent:LocalToWorld(Vector(50, 40, 8))
		local ang = ent:LocalToWorldAngles(Angle(0, 0, 0))
		local playerStart = ents.Create("info_player_start")
		playerStart:SetPos(pos)
		playerStart:SetAngles(ang)
		playerStart:Spawn()
		playerStart.MasterSpawn = true

		playerStart:SetParent(ent)
	end)

end

function MAPSCRIPT:PostInit()

	if SERVER then

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)
	--DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT
