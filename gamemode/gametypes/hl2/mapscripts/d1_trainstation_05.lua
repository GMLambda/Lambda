AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons = {},
	Ammo = {},
	Armor = 30,
	HEV = false,
}

MAPSCRIPT.InputFilters =
{
	["soda_machine_entry_door_1"] = { "Toggle" },
	["soda_door_areaportal_1"] = { "Close" },
	["lab_door"] = { "Close" },
	["lab_door_clip"] = { "Close" },
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["brush_soda_clip_player_2"] = true,
	--["Barney_lab_entry_closedoor_1"] = true,
	["brush_soda_clip_player"] = true, -- Why not
}

function MAPSCRIPT:Init()

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

	if SERVER then

		self.DefaultLoadout.HEV = false

		ents.WaitForEntityByName("player_in_teleport", function(ent)
			ent:SetKeyValue("teamwait", "1")
		end)

		ents.WaitForEntityByName("start_first_teleport_01", function(ent)
			ent:SetKeyValue("teamwait", "1")
		end)

		ents.WaitForEntityByName("kleiner_console_lift_1", function(ent)
			ent:SetKeyValue("spawnflags", "256")
			ent:SetKeyValue("dmg", "0") -- Don`t hurt the player
		end)

		local mapscript = self

		-- We gotta give all players the suit, some might be not so willing to take it and thats bad.
		GAMEMODE:WaitForInput("suiton", "Enable", function(ent)
			for _,v in pairs(player.GetAll()) do
				-- Equip suit.
				v:EquipSuit()

				-- Update model.
				GAMEMODE:PlayerSetModel(v)

				mapscript.DefaultLoadout.HEV = true
			end
		end)

		for _,v in pairs(ents.FindByClass("item_suit")) do
			v:EnableRespawn(true)
		end

		-- -6569.488281 -1150.120850 0.031250
		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-6569.488281, -1150.120850, 0.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-6482.711914, -1095.658813, 0.031250),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 180)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		ents.WaitForEntityByName("gman_fixtie_1", function(ent)
			ent:SetKeyValue("m_iszPlay", "citizen4_valve")
		end)

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
