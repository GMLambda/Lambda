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
	--["relay_rush_downstairscops"] = { "Trigger" },
}

MAPSCRIPT.EntityFilterByClass =
{
}

MAPSCRIPT.EntityFilterByName =
{
	["logic_flr1tv_turnoffallscreens"] = true,
	["ai_breakin_cop3goal4_blockplayer"] = true,
	["ai_breakin_cop3goal4_blockplayer"] = true,
	--["attic_door_push"] = true,
	--["attic_door_push_trigger"] = true,
	--["brush_prevent_cops_getting_to_bracer"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- FIX: The cop would stand there annoying players that have not yet passed through.
		GAMEMODE:WaitForInput("brush_breakin_blockplayer1", "Kill", function()
			ents.WaitForEntityByName("npc_breakincop3", function(ent) ent:SetName("lambda_npc_breakincop3") DbgPrint("Changed name") end)
			ents.WaitForEntityByName("ai_breakin_cop3goal3_blockplayer2", function(ent) ent:SetName("lambda_ai_breakin_cop3goal3_blockplayer2") end)
			ents.WaitForEntityByName("ai_breakin_cop3goal3_blockplayer", function(ent) ent:SetName("lambda_ai_breakin_cop3goal3_blockplayer") end)
		end)

		-- Move the target a little further away from the the player path
		ents.WaitForEntityByName("mark_RaidEscape02", function(ent) ent:SetPos(Vector(-5017, -4637, 384)) end)

		local lcs_cit_RaidAnticipation
		ents.WaitForEntityByName("lcs_cit_RaidAnticipation", function(ent)
			ent:Fire("AddOutput", "OnCompletion !self,Start")
			ent:SetKeyValue("busyactor", "0")
			lcs_cit_RaidAnticipation = ent
		end)

		GAMEMODE:WaitForInput("trigger_rush_start", "Enable", function()
			DbgPrint("Preventing police rush")
			lcs_cit_RaidAnticipation:Fire("Start")
			return true
		end)

		ents.WaitForEntityByName("attic_door_close_relay", function(ent)
			ent:SetName("lambda_attic_door_close_relay")
		end)

		ents.WaitForEntityByName("attic_door_push", function(ent)
			ent:SetName("lambda_attic_door_push")
		end)

		ents.WaitForEntityByName("attic_door_push_trigger", function(ent)
			ent:SetName("lambda_attic_door_push_trigger")
		end)

		ents.WaitForEntityByName("brush_prevent_cops_getting_to_bracer", function(ent)
			ent:SetName("lambda_brush_prevent_cops_getting_to_bracer")
		end)

		local door_bracer_trigger = ents.Create("trigger_once")
		door_bracer_trigger:SetupTrigger(Vector(-4995, -4848, 512), Angle(0,0,0), Vector(-110, -80, 0), Vector(110, 110, 90))
		door_bracer_trigger:SetKeyValue("teamwait", "1")
		door_bracer_trigger.OnTrigger = function(self)
			DbgPrint("All players inside trigger, closing door, swapping spawnpoint.")
			-- Everyone is inside, we can close the door.
			ents.WaitForEntityByName("lambda_attic_door_push", function(ent) ent:Fire("Kill") end)
			ents.WaitForEntityByName("lambda_attic_door_close_relay", function(ent) ent:Fire("Trigger") end)
			ents.WaitForEntityByName("lambda_attic_door_push_trigger", function(ent) ent:Fire("Kill") end)
			ents.WaitForEntityByName("lambda_brush_prevent_cops_getting_to_bracer", function(ent) ent:Fire("Enable") end)
			ents.WaitForEntityByName("gordon_criminal_global", function(ent) ent:Fire("TurnOff") end)
		end

		-- FIX: For some reason the door pushed us away.
		ents.WaitForEntityByName("door_bracerProp", function(ent) ent:Fire("DisablePlayerCollision") end)

		-- More subtle path blocking
		ents.CreateSimple("prop_physics",
		{
			Model = "models/props_interiors/furniture_couch01a.mdl",
			SpawnFlags = 11,
			Pos = Vector(-3948.116211, -4605.383301, 405.858459),
			Ang = Angle(0, -28, 0)
		})
		ents.CreateSimple("prop_physics",
		{
			Model = "models/props_interiors/furniture_shelf01a.mdl",
			SpawnFlags = 11,
			Pos = Vector(-3978.584961, -4591.714355, 428.674622),
			Ang = Angle(2.685, -43.640, -1.595)
		})
		ents.CreateSimple("prop_physics",
		{
			Model = "models/props_interiors/furniture_couch02a.mdl",
			SpawnFlags = 11,
			 Pos = Vector(-3991.768799 -4628.245117, 413.455383),
			 Ang = Angle(48.364, 2.325, -54.165)
		})
		ents.CreateSimple("prop_physics",
		{
			Model = "models/props_interiors/furniture_cabinetdrawer01a.mdl",
			SpawnFlags = 11,
			Pos = Vector(-4001.259521, -4626.048828, 451.491089),
			Ang = Angle(32.242, 48.029, -59.341)
		})
		ents.CreateSimple("prop_physics",
		{
			Model = "models/props_interiors/furniture_couch01a.mdl",
			SpawnFlags = 11,
			Pos = Vector(-4033.726074, -4614.500000, 405.713776),
			Ang = Angle(0.035, 151.586, 0.003)
		})

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
