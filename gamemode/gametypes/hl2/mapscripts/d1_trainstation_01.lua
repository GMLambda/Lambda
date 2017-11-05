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

MAPSCRIPT.EntityFilterByClass =
{
	--["point_teleport"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	--["teleport_to_start"] = true,
	--["teleport_to_train"] = true,
	--["teleport_to_trainstation"] = true,
	--["teleport_to_citadel"] = true,
	--["teleport_to_test_chamber"] = true,
}

MAPSCRIPT.InputFilters =
{
	["train_door_2_counter"] = {"Add"},
	["razortrain_gate_cop_2"] = {"SetPoliceGoal"},
	["cage_playerclip"] = {"Enable"},
	["cage_door_counter"] = {"Add"},
	["logic_kill_citizens"] = {"Trigger"},
	["storage_room_door"] = {"Close", "Lock"},
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:ResetPlayerPos(ply)

	if self.PlayersLocked == true then
		local gman = ents.FindFirstByName("gman")
		ply:SetPos(Vector(-14576, -13924, -1290))
		ply:LockPosition(true, VIEWLOCK_NPC, gman)
	end

end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- Override env_global so combines dont flip shit on everyone
		game.SetGlobalState("gordon_invulnerable", GLOBAL_ON)
		game.SetGlobalState("gordon_precriminal", GLOBAL_ON)

		self.PlayersLocked = true

		-- Remove all default spawnpoints.
		ents.RemoveByClass("info_player_start")

		-- Annoying stuff.
		ents.RemoveByName("cage_playerclip")
		--ents.RemoveByName("barney_room_blocker")
		ents.RemoveByName("barney_room_blocker_2")
		ents.RemoveByName("barney_hallway_clip")
		ents.RemoveByName("logic_kill_citizens")

		-- Fix spawn position
		ents.WaitForEntityByName("teleport_to_start", function(ent)
			ent:SetPos(Vector(-14576, -13924, -1290))
		end)

		-- Spawn infront of G-Man
		local spawn1 = ents.Create("info_player_start")
		spawn1:SetPos(Vector(-14576, -13924, -1274))
		spawn1:SetAngles(Angle(0, 90, 0))
		spawn1:Spawn()
		spawn1.MasterSpawn = true

		-- Spawn after the intro.
		local spawn2 = ents.Create("info_player_start")
		spawn2:SetPos(Vector(-5182, -2106, -31))
		spawn2:SetAngles(Angle(0, 0, 0))
		spawn2:Spawn()
		spawn2.MasterSpawn = false

		-- Spawn after barney
		local spawn3 = ents.Create("info_player_start")
		spawn3:SetPos(Vector(-3549, -347, -31))
		spawn3:SetAngles(Angle(0, 0, 0))
		spawn3:Spawn()
		spawn3.MasterSpawn = false

		-- Fix point_viewcontrol, setup All Players flag.
		for k,v in pairs(ents.FindByClass("point_viewcontrol")) do
			v:SetKeyValue("spawnflags", "128")
		end

		-- Make the cop go outside the hallway so other players can still pass by.
		local mark_cop_security_room_leave = ents.FindFirstByName("mark_cop_security_room_leave");
		mark_cop_security_room_leave:SetPos(Vector(-4304, -464, -16))

		GAMEMODE:WaitForInput("logic_start_train", "Trigger", function()

			DbgPrint("Assigning new spawnpoint")

			spawn1.MasterSpawn = false
			spawn2.MasterSpawn = true

			-- Unlock players.
			self.PlayersLocked = false

			for k,v in pairs(player.GetAll()) do
				v:LockPosition(false, false)
				v:SetNoDraw(false)
			end

		end)

		-- Block players from escaping control gate.
		local cage_playerclip = ents.Create("func_brush")
		cage_playerclip:SetPos(Vector(-4226.9350585938, -417.03271484375,-31.96875))
		cage_playerclip:SetModel("*68")
		cage_playerclip:SetKeyValue("spawnflags", "2")
		cage_playerclip:Spawn()

		-- Setup the door to not close anymore once we entered the trigger.
		GAMEMODE:WaitForInput("razor_train_gate_2", "Close", function()
			DbgPrint("Preventing barney_door_1 to close")
			GAMEMODE:FilterEntityInput("barney_door_1", "Close")
		end)

		-- Create a trigger once all players are inside we setup a new spawnpoint and close the door.
		ents.RemoveByClass("trigger_once", Vector(-3442, -316, 8)) -- We will take over.

		local barney_room_trigger = ents.Create("trigger_once")
		barney_room_trigger:SetupTrigger(Vector(-3450, -255, 20), Angle(0,0,0), Vector(-150, -150, -50), Vector(150, 150, 50))
		barney_room_trigger:SetKeyValue("teamwait", 1)
		barney_room_trigger.OnTrigger = function(self)
			spawn2.MasterSpawn = false
			spawn3.MasterSpawn = true
			--ents.WaitForEntityByName("barney_door_2", function(ent) ent:Fire("Close") end)
			--ents.WaitForEntityByName("barney_door_2", function(ent) ent:Fire("Lock") end)
			ents.WaitForEntityByName("security_intro_02", function(ent) ent:Fire("Start") end)
			ents.WaitForEntityByName("barney_room_blocker", function(ent) ent:Fire("Enable") end)
		end

		ents.WaitForEntityByName("barney_door_2", function(ent)
			ent:SetKeyValue("opendir", "2")
		end)

		--[[
		GAMEMODE:WaitForInput("barney_door_2", "Close", function()
			GAMEMODE:RemoveInputCallback("barney_door_2", "Close")
			GAMEMODE:RemoveInputCallback("barney_door_2", "Lock")
			barney_room_trigger:Fire("Enable")
			return true -- Supress
		end)
		]]

		-- Use a better spot for barney
		local mark_barneyroom_comblock_4 = ents.FindFirstByName("mark_barneyroom_comblock_4")
		mark_barneyroom_comblock_4:SetPos(Vector(-3588, 3, -31))
	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	DbgPrint("PostPlayerSpawn")

	if self.PlayersLocked == true then
		self:ResetPlayerPos(ply)
		ply:SetNoDraw(true)
	else
		ply:SetNoDraw(false)
	end

end

return MAPSCRIPT
