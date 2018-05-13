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
	},
	Ammo =
	{
		["Pistol"] = 20,
		["SMG1"] = 45,
		["357"] = 3,
		["Grenade"] = 1,
	},
	Armor = 60,
	HEV = true,
}

MAPSCRIPT.InputFilters =
{
	["buildingD_roofhatch"] = { "Close" }, -- Never close it, it might close while players climb up and get stuck.
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["startobjects_template"] = true,
	["damagefilter_monk"] = true,
	--["test_name"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- If we come from 03
		if GAMEMODE:GetPreviousMap() == "d1_town_03" then
			-- -3764.476807 -332.874481 -3327.968750
			local checkpointTransfer = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-3764.476807, -332.874481, -3327.968750), Ang = Angle(0, 90, 0) })
			GAMEMODE:SetPlayerCheckpoint(checkpointTransfer)

			-- If players fall they should rather die.
			local triggerHurt1 = ents.Create("trigger_hurt")
			triggerHurt1:SetupTrigger(
				Vector(-3212.359131, 344.832214, -3572.259033),
				Angle(0, 0, 0),
				Vector(-480, -500, 0),
				Vector(500, 780, 115)
			)
			triggerHurt1:SetKeyValue("damage", "200")

			-- Reposition path track so players can jump across.
			ents.WaitForEntityByName("churchtram_path_bottom", function(ent)
				ent:SetPos(Vector(-4530.682129, 940.989685, -2902.0))
			end)
		end

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1808.973267, 721.884277, -3071.968750), Ang = Angle(0, -180, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-1789.687012, 684.973572, -3071.968750),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 70)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- -2942.757324 895.897278 -3135.814697
		-- w = 128 (x)
		-- l = 95 (y)
		-- freightlift_lift
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-2948.138428, 887.582458, -3135.968750), Ang = Angle(0, -180, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(-2942.757324, 895.897278, -3135.814697),
			Angle(0, 0, 0),
			Vector(-64, -45, 0),
			Vector(64, 45, 90)
		)
		checkpointTrigger2:SetKeyValue("teamwait", "1")
		checkpointTrigger2:Disable() -- Initially disabled, started by button.
		checkpointTrigger2.OnTrigger = function()
			TriggerOutputs({
				{"elevator_nodelink", "TurnOff", 10.0, ""},
				{"freight_lift_down_relay", "Trigger", 0, ""},
				{"freight_lift_button_2", "Lock", 0, ""},
			})
			ents.WaitForEntityByName("freightlift_lift", function(ent)
				checkpoint2:SetParent(ent)
			end)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

		-- Replace the logic of that button.
		GAMEMODE:WaitForInput("freight_lift_button_2", "Use", function()
			if IsValid(checkpointTrigger2) then
				checkpointTrigger2:Enable()
			end
			return true -- Suppress.
		end)

		-- We spawn the monk in the second part sooner, players should not see him being spawned.
		-- -3396.734619 417.609131 -3327.968750
		local monkTrigger = ents.Create("trigger_once")
		monkTrigger:SetupTrigger(
			Vector(-3396.734619, 417.609131, -3327.968750),
			Angle(0, 0, 0),
			Vector(-64, -45, 0),
			Vector(64, 45, 90)
		)
		monkTrigger.OnTrigger = function()
			TriggerOutputs({
				{"church_monk_maker", "Spawn", 0.0, ""},
				{"church_monk_maker", "Disable", 0.0, ""},
			})
		end

		-- Checkpoints for part 2
		-- -4323.520996 1618.552734 -3135.968750
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-4323.520996, 1618.552734, -3135.968750), Ang = Angle(0, -90, 0) })
		local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(-4345.541504, 1502.828979, -3135.968750),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 70)
		)
		checkpointTrigger3.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end

		local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-4836.597168, 545.560608, -3263.968750), Ang = Angle(0, 90, 0) })
		local checkpointTrigger4 = ents.Create("trigger_once")
		checkpointTrigger4:SetupTrigger(
			Vector(-4522.980469, 838.613159, -3065.248779),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 170)
		)
		checkpointTrigger4.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint4)
		end
	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
