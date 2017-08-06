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
		"weapon_physcannon",
		"weapon_frag",
		"weapon_shotgun",
		"weapon_ar2",
		"weapon_rpg",
	},
	Ammo =
	{
		["Pistol"] = 20,
		["SMG1"] = 45,
		["357"] = 6,
		["Grenade"] = 3,
		["Buckshot"] = 12,
		["AR2"] = 50,
		["RPG_Round"] = 8,
		["SMG1_Grenade"] = 3,
	},
	Armor = 60,
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
	["player_spawn_items"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- 3233.962402 -5601.413086 1564.521851

		-- 3330.477539 1352.385864 1536.031250
		local checkpoint0 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3332.003174, 1683.768311, 1536.031250), Ang = Angle(0, -90, 0) })
		GAMEMODE:SetPlayerCheckpoint(checkpoint0)

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3237.011963, -1235.819336, 1792.031250), Ang = Angle(0, -90, 0) })
		local checkpoint1rev = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3237.011963, -1235.819336, 1792.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger1 = ents.Create("trigger_multiple")
		checkpointTrigger1:SetupTrigger(
			Vector(3313.845215, -1269.754028, 1792.031250),
			Angle(0, 0, 0),
			Vector(-250, -105, 0),
			Vector(250, 105, 200)
		)
		checkpointTrigger1.OnTrigger = function(trigger)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
			checkpoint1 = checkpoint1rev
			trigger:Disable()
		end

		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3336.251709, -2644.284424, 1480.031250), Ang = Angle(0, -90, 0) })
		local checkpoint2rev = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3336.251709, -2644.284424, 1480.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger2 = ents.Create("trigger_multiple")
		checkpointTrigger2:SetupTrigger(
			Vector(3336.251709, -2644.284424, 1480.031250),
			Angle(0, 0, 0),
			Vector(-250, -105, 0),
			Vector(250, 105, 200)
		)
		checkpointTrigger2.OnTrigger = function(trigger)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
			if checkpoint2 == checkpoint2rev then
				checkpointTrigger1:Enable()
			else
				checkpoint2 = checkpoint2rev
			end
			trigger:Disable()
		end

		-- 3338.592041 -4066.411621 1792.031250
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3415.853760, -4052.803955, 1792.031250), Ang = Angle(0, -90, 0) })
		local checkpoint3rev = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3415.853760, -4052.803955, 1792.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger3 = ents.Create("trigger_multiple")
		checkpointTrigger3:SetupTrigger(
			Vector(3338.592041, -4066.411621, 1792.031250),
			Angle(0, 0, 0),
			Vector(-250, -105, 0),
			Vector(250, 105, 200)
		)
		checkpointTrigger3.OnTrigger = function(trigger)
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
			if checkpoint3 == checkpoint3rev then
				checkpointTrigger2:Enable()
			else
				checkpoint3 = checkpoint3rev
			end
			trigger:Disable()
		end


		-- 3302.523193 -5592.021484 1536.031250
		local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3325.756836, -5639.022461, 1536.031250), Ang = Angle(0, 0, 0) })
		local checkpoint4rev = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3187.962402, -5593.404297, 1551.531250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger4 = ents.Create("trigger_multiple")
		checkpointTrigger4:SetupTrigger(
			Vector(3302.523193, -5592.021484, 1536.031250),
			Angle(0, 0, 0),
			Vector(-250, -105, 0),
			Vector(250, 105, 200)
		)
		checkpointTrigger4.OnTrigger = function(trigger)
			GAMEMODE:SetPlayerCheckpoint(checkpoint4)
			if checkpoint4 == checkpoint4rev then
				checkpointTrigger3:Enable()
			else
				checkpoint4 = checkpoint4rev
			end
			trigger:Disable()
		end

		GAMEMODE:WaitForInput("button_trigger", "Use", function()
			checkpointTrigger4:Enable()
			GAMEMODE:EnablePreviousMap()
		end)

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
