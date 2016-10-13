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
	["gate1"] = { "EnableMotion" }
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["global_newgame_template"] = true,
	["relay_guncave_gate_exit_close"] = true,
}

MAPSCRIPT.VehicleGuns = false

function MAPSCRIPT:Init()

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

	local self = self
	if SERVER then

		self.VehicleGuns = false

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(6457.725586, 4986.333984, -953.968750), Ang = Angle(0, 180, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(6338.301270, 5018.617188, -953.968750),
			Angle(0, 0, 0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetVehicleCheckpoint(Vector(6363.024902, 4874.115234, -967.214539), Angle(0, 90, 0))
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		GAMEMODE:WaitForInput("global_newgame_spawner_airboat", "Unlock", function(ent)
			self.VehicleGuns = true
		end)

		ents.WaitForEntityByName("teleport_guncave_airboat", function(ent)
			-- This should fix the issue where airboats gone missing, also it properly lines em up
			-- given by our specific stack mode within point_teleport
			ent:SetKeyValue("stackmode", "1")
			ent:SetKeyValue("stackdir", util.TypeToString(ent:GetAngles():Right()))
			ent:SetKeyValue("stacklength", "200")
			ent:SetPos(Vector(5992.192383, 4864.584473, -926.774841))
		end)

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
