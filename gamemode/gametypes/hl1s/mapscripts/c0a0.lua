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
	for k,v in pairs(ents.FindByClass("info_player_start")) do
		v:Remove()
	end

	ents.WaitForEntityByName("train", function(ent)
		ent:Fire("Stop")

		local playerStart = ents.Create("info_player_start")
		playerStart:SetPos(ent:GetPos() + Vector(50, 40, 20))
		playerStart:SetAngles(Angle(0, -180, 0))
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
