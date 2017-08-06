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
        "weapon_bugbait",
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
	["alyx_briefingroom_exitdoor"] = { "Close", "Lock" },
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["pclip_gate1"] = true,
}

function MAPSCRIPT:Init()

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

    if SERVER then

		-- 5487.663574 1408.772949 0.031250 10.626 -1.579 0.000
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(5329.144043, 1568.602905, 0.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(5487.663574, 1408.772949, 0.031250),
			Angle(0, 0, 0),
			Vector(-30, -30, 0),
			Vector(30, 30, 100)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- 4817.152344 1203.166138 0.031250
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(4817.152344, 1203.166138, 0.031250), Ang = Angle(0, -90, 0) })
		ents.WaitForEntityByName("lcs_pregate01_trigger", function(ent)
			ent:ResizeTriggerBox(Vector(-180, -100, -40), Vector(180, 400, 60))
			ent:SetKeyValue("teamwait", "1")
			ent.OnTrigger = function(ent)
				GAMEMODE:SetPlayerCheckpoint(checkpoint2)
			end
		end)

		ents.WaitForEntityByName("gate_close_trigger", function(ent)
			ent:Remove()
		end)


		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(7399.153809, 1336.154907, 0.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(8031.499512, 1544.012939, -3.968811),
			Angle(0, 0, 0),
			Vector(-800, -1000, -600),
			Vector(2600, 1600, 200)
		)
		checkpointTrigger2:SetKeyValue("teamwait", "1")
		checkpointTrigger2.OnTrigger = function(ent)
			TriggerOutputs({
				{"gate_close_counter", "Add", 0, "1"},
			})
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
