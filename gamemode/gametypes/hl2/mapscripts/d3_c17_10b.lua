AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.DayTime = "morning"

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
	["s_room_panelswitch"] = { "Lock" }, -- Prevent it from locking the button.
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

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

    if SERVER then

		-- 3887.857910 -514.078979 512.031250
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(4184.389160, -740.649597, 512.031250), Ang = Angle(0, 180, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(3887.857910, -514.078979, 512.031250),
			Angle(0, 0, 0),
			Vector(-160, -160, 0),
			Vector(160, 160, 100)
		)
		checkpointTrigger1.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- Add another logic relay that disables all turrets once the button is pressed.
		local turretsOffRelay = ents.Create("logic_relay")
		turretsOffRelay:SetKeyValue("targetname", "s_room_off_relay")
		turretsOffRelay:SetKeyValue("StartDisabled", "0")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_1,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_2,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_3,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_4,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_5,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_6,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_7,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_turret_8,Disable,,0,-1")
		turretsOffRelay:SetKeyValue("OnTrigger", "s_room_doors,Open,,0,-1")
		turretsOffRelay:Spawn()

		-- 2657.141357 1033.785645 256.031250
		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2657.141357, 1033.785645, 256.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(2657.141357, 1033.785645, 256.031250),
			Angle(0, 0, 0),
			Vector(-60, -60, 0),
			Vector(60, 60, 100)
		)
		checkpointTrigger2.OnTrigger = function(ent)
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
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
