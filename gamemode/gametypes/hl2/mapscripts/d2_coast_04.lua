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
	--["test_name"] = true,
	["global_newgame_template_base_items"] = true,
	["global_newgame_template_local_items"] = true,
	["global_newgame_template_ammo"] = true,
	["fall_trigger"] = true, -- We replaced it by a more friendly variant
	["crane_soldier_kill"] = true, -- Why?
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		--PrintTable(dock_soldiers)
		-- 2219.829834 -2778.555176 256.031250
		local dock_soldiers = game.FindEntityInMapData("dock_soldiers_ontherun")
		local crane_soldier = game.FindEntityInMapData("crane_soldier1")

		-- This is a far better spot to create all the npcs, it sucks if the player sees them spawning.
		-- -4059.708252 54.849800 -10.067627
		local trigger1 = ents.Create("trigger_once")
		trigger1:SetupTrigger(
			Vector(-4059.708252, 54.849800, -10.067627),
			Angle(0, 0, 0),
			Vector(-100, -800, 0),
			Vector(100, 800, 280)
		)
		trigger1.OnTrigger = function()
			TriggerOutputs({
				{"dock_soldier_template", "ForceSpawn", 0.0, ""},
				{"dock_soldier_template", "Kill", 0.1, ""},
				{"dock_antlion_spawner", "Spawn", 0.2, ""},
				{"dock_spawn", "ForceSpawn", 0.0, ""},
				{"ontherun_begin_assault", "Activate", 0.5, ""},
			})

			-- Few extra npcs
			local npc

			npc = ents.CreateFromData(dock_soldiers)
			npc:SetPos(Vector(4175.628906, -2315.031738, 384.031250))
			npc:Spawn()

			npc = ents.CreateFromData(dock_soldiers)
			npc:SetPos(Vector(4163.271973, -2513.076660, 384.031250))
			npc:Spawn()

			npc = ents.CreateFromData(dock_soldiers)
			npc:SetPos(Vector(3997.812012, -2928.038086, 384.031250))
			npc:Spawn()

			npc = ents.CreateFromData(dock_soldiers)
			npc:SetPos(Vector(4213.705078, -1796.927490, 672.031250))
			npc:Spawn()

			npc = ents.CreateFromData(dock_soldiers)
			npc:SetPos(Vector(1731.862427, -2624.286377, 512.031250))
			npc:Spawn()

			npc = ents.CreateFromData(dock_soldiers)
			npc:SetPos(Vector(1157.538452, -2616.800537, 512.031250))
			npc:Spawn()

		end

		-- The thumper should be enabled, the combine did take over the place so why is it shut off?
		ents.WaitForEntityByName("thumper_1", function(ent)
			util.RunNextFrame(function()
				ent:Fire("Enable")
			end)
		end)

		-- rush checkpoint
		-- 2835.472412 -1599.243896 142.031235, 1864.473999 -3026.903076 256.031250
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1864.473999, -3026.903076, 256.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(2835.472412, -1599.243896, 142.031235),
			Angle(0, 0, 0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetVehicleCheckpoint(Vector(3377.796875, -1352.083008, 9.863693), Angle(0, 0, 0))
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- bridge checkpoint
		-- 5068.378418 -2688.673828 384.031250
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(5189.114258, -2913.917236, 384.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(5068.378418, -2688.673828, 384.031250),
			Angle(0, 0, 0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger2.OnTrigger = function()
			GAMEMODE:SetVehicleCheckpoint(Vector(5128.125488, -2679.885986, 384.031250), Angle(0, -90, 0))
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

		-- More enemies inside the warehouse
		local npc
		npc = ents.CreateFromData(crane_soldier)
		npc:SetPos(Vector(5337.789551, -4445.919922, 416.031250))
		npc:Spawn()

		npc = ents.CreateFromData(crane_soldier)
		npc:SetPos(Vector(5846.189453, -4383.688965, 416.031250))
		npc:Spawn()

		npc = ents.CreateFromData(crane_soldier)
		npc:SetPos(Vector(5758.164063, -4566.489746, 416.031250))
		npc:Spawn()

		npc = ents.CreateFromData(crane_soldier)
		npc:SetPos(Vector(5775.033203, -4182.553711, 384.031250))
		npc:Spawn()

		ents.WaitForEntityByName("push_car_superjump_01", function(ent)
			ent:Fire("Enable")
			ent:SetName("lambda_push_car_superjump_01") -- Prevent disabling it.
		end)

		-- Setup a trigger that hurts the falling players,
		-- it would take a immense effort to get back up there with the crane and all.
		local bridgeKillTrigger = ents.Create("trigger_multiple")
		bridgeKillTrigger:SetupTrigger(
			Vector(-1835.606934, 1068.328979, 669.459900),
			Angle(0, 0, 0),
			Vector(-400, -350, 0),
			Vector(400, 350, 100)
		)
		bridgeKillTrigger.OnTrigger = function(self, ent)
			if ent:IsVehicle() then
				local driver = ent:GetDriver()
				if IsValid(driver) and driver:Alive() then
					driver:Kill()
				end
				local passengerSeat = ent.PassengerSeat
				if IsValid(passengerSeat) then
					local passenger = passengerSeat:GetDriver()
					if IsValid(passenger) and passenger:Alive() then
						passenger:Kill()
					end
				end
			elseif ent:IsPlayer() and ent:Alive() then
				ent:Kill()
			end
		end

		-- fall checkpoint
		-- 1826.217529 2.297394 928.031250
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1328.088135, -1649.725464, 958.014343), Ang = Angle(0, 90, 0) })
		local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(-1823.722290, -1220.703369, 928.031250),
			Angle(0, 0, 0),
			Vector(-200, -100, 0),
			Vector(200, 100, 180)
		)
		checkpointTrigger3.OnTrigger = function()
			GAMEMODE:SetVehicleCheckpoint(Vector(-1352.137207, -1540.197876, 951.312805), Angle(0, 90, 0))
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end


	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
