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
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["player_spawn_items"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

		-- -2672.437500 6479.918945 512.031250
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-2672.437500, 6479.918945, 512.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-2672.437500, 6479.918945, 512.031250),
			Angle(0, 0, 0),
			Vector(-60, -60, 0),
			Vector(60, 60, 100)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- -1407.534912 4417.064453 128.031250
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1416.659668, 4142.781738, 128.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(-1407.534912, 4417.064453, 128.031250),
			Angle(0, 0, 0),
			Vector(-60, -60, 0),
			Vector(60, 60, 100)
		)
		checkpointTrigger2.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

		-- -1404.743896 8211.465820 128.031250
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1404.743896, 8211.465820, 128.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(-1404.743896, 8161.465820, 128.031250),
			Angle(0, 0, 0),
			Vector(-60, -60, 0),
			Vector(60, 60, 100)
		)
		checkpointTrigger3.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end

    end

end

function MAPSCRIPT:OnNewGame()

	DbgPrint("OnNewGame")

	-- TODO: Validate me.
	if not IsValid(ents.FindFirstByName("barney")) then
		ents.WaitForEntityByName("player_spawn_items_maker", function(ent)
			ent:Fire("ForceSpawn")
		end)
	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
