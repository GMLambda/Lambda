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
		"weapon_crossbow",
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
		["XBowBolt"] = 4,
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
	["global_newgame_template_base_items"] = true,
	["global_newgame_template_local_items"] = true,
	["global_newgame_template_ammo"] = true,
	["fall_trigger"] = true,
	["mc_both_in"] = true,
}

MAPSCRIPT.ImportantPlayerNPCNames =
{
	["vortigaunt_bugbait"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	-- -6397.890625 4632.765625 512.031250
	if SERVER then

		-- 8222.646484 1799.084961 960.000000
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(1391.161987, -4552.412598, 1201.034180), Ang = Angle(0, 45, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(1639.652832, -4384.989746, 1124.123779),
			Angle(0, 45, 0),
			Vector(-100, -250, 0),
			Vector(100, 250, 200)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- 4805.734863 -293.060852 544.752808
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(4805.734863, -293.060852, 544.752808), Ang = Angle(0, 106, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(4805.734863, -293.060852, 544.752808),
			Angle(0, 0, 0),
			Vector(-150, -150, 0),
			Vector(150, 150, 200)
		)
		checkpointTrigger2.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

		-- 4194.318848 3518.950195 371.710144
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(3319.693848, 3064.873535, 567.830078), Ang = Angle(0, 90, 0) })
		local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(4151.009277, 2739.715820, 377.123840),
			Angle(0, 0, 0),
			Vector(-1700, -150, -300),
			Vector(2400, 150, 600)
		)
		checkpointTrigger3.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end

		ents.WaitForEntityByName("generator_button", function(ent)
			ent:SetKeyValue("spawnflags", "1025")
			ent:SetKeyValue("wait", "-1")
		end)

		-- 4646.223145 6915.463867 447.677368
		local checkpoint4 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(4646.223145, 6915.463867, 447.677368), Ang = Angle(0, 90, 0) })
		local checkpointTrigger4 = ents.Create("trigger_once")
		checkpointTrigger4:SetupTrigger(
			Vector(4646.223145, 6915.463867, 447.677368),
			Angle(0, 0, 0),
			Vector(-420, -220, -200),
			Vector(220, 420, 100)
		)
		checkpointTrigger4.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint4)
		end

		local allowGuard = false
		GAMEMODE:WaitForInput("citizen_ambush_guard", "Unburrow", function(ent)
			if allowGuard == false then
				DbgPrint("Filtering antlion guard")
				return true
			end
		end)
		GAMEMODE:WaitForInput("music_antlionguard_2", "PlaySound", function(ent)
			if allowGuard == false then
				DbgPrint("Filtering antlion guard")
				return true
			end
		end)

		-- Create a better trigger for all players.
		local guardTrigger = ents.Create("trigger_once")
		guardTrigger:SetupTrigger(
			Vector(5680.671875, 8944.449219, 107.807495),
			Angle(0, 0, 0),
			Vector(-1500, -2000, -100),
			Vector(1600, 1900, 180)
		)
		guardTrigger:SetKeyValue("teamwait", "1")
		guardTrigger.OnTrigger = function(ent)
			allowGuard = true
			TriggerOutputs({
				{"citizen_ambush_guard", "Unburrow", 0, ""},
				{"music_antlionguard_2", "PlaySound", 0, ""},
			})
		end

		ents.WaitForEntityByName("vortigaunt_bugbait", function(ent)
			ent:SetKeyValue("spawnflags", "1030") -- Remove SF_NPC_WAIT_FOR_SCRIPT
		end)

		-- Some players might refuse this, let this continue anyway.
		ents.WaitForEntityByName("leadgoal_vortigaunt", function(ent)
			ent:SetKeyValue("RetrieveDistance", "3000")
			ent:SetKeyValue("LeadDistance", "3000")
			ent:SetKeyValue("LeadDistance", "3000")
			ent:SetKeyValue("WaitDistance", "3000")
		end)

		-- Some players might refuse this, let this continue anyway.
		ents.WaitForEntityByName("aigl_vort", function(ent)
			ent:SetKeyValue("RetrieveDistance", "3000")
			ent:SetKeyValue("LeadDistance", "3000")
			ent:SetKeyValue("LeadDistance", "3000")
			ent:SetKeyValue("WaitDistance", "3000")
		end)

		GAMEMODE:WaitForInput("antlion_cage_door", "Close", function(ent)
			return true -- dont close.
		end)

		-- 5166.699219 9918.750977 162.514114
		local checkpoint5 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(5166.699219, 9918.750977, 162.514114), Ang = Angle(0, 180, 0) })
		local checkpointTrigger5 = ents.Create("trigger_once")
		checkpointTrigger5:SetupTrigger(
			Vector(5166.699219, 9918.750977, 162.514114),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 100)
		)
		checkpointTrigger5.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint5)
		end

		-- Checkpoint
		-- 799.167236 11539.323242 499.299133
		local checkpoint6 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(799.167236, 11539.323242, 499.299133), Ang = Angle(0, 180, 0) })
		local checkpointTrigger6 = ents.Create("trigger_once")
		checkpointTrigger6:SetupTrigger(
			Vector(799.167236, 11539.323242, 499.299133),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 100)
		)
		checkpointTrigger6.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint6)
		end

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
