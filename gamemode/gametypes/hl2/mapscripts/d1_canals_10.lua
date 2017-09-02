AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons =
	{
		"weapon_crowbar",
		"weapon_pistol",
		"weapon_smg1",
		"weapon_357",
	},
	Ammo =
	{
		["Pistol"] = 60,
		["SMG1"] = 60,
		["357"] = 3,
	},
	Armor = 0,
	HEV = true,
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
	["global_newgame_entmaker"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	DbgPrint("MAPSCRIPT:PostInit")

	if SERVER then

		for k,v in pairs(ents.FindByClass("info_player_start")) do
			v:Remove()
		end

		local playerStart = ents.Create("info_player_start")
		playerStart:SetPos(Vector(11876.291016, -12289.263672, -526.052246))
		playerStart:SetAngles(Angle(0, 100, 0))
		playerStart:Spawn()
		playerStart.MasterSpawn = true

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(4757.852051, 9866.387695, -111.968750), Ang = Angle(0, 180, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(5046.067871, 9267.515625, -127.968750),
			Angle(0, 0, 0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetVehicleCheckpoint(Vector(4270.903320, 9841.201172, -124.578499), Angle(0, 180, 0))
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
