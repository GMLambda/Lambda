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
	},
	Ammo =
	{
		["Pistol"] = 10,
	},
	Armor = 0,
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
	["spawnitems_template"] = true,
}

function MAPSCRIPT:Init()

	DbgPrint("-- Mapscript: Template loaded --")

end

function MAPSCRIPT:PostInit()

	if SERVER then

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1183.380615, 6344.419922, -59.326172), Ang = Angle(0, -180, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-1183.380615, 6344.419922, 6.326172),
			Angle(0,0,0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		--- 1215.137695 6346.565430 -59.008865


		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-3002.406494, 7870.711426, 12.031250), Ang = Angle(0, 90, 0) })
		local checkpointTrigger2 = ents.Create("trigger_once")
		checkpointTrigger2:SetupTrigger(
			Vector(-3002.406494, 7870.711426, 48.031250),
			Angle(0,0,0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger2.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint2)
		end

		-- 2104.908447 5759.881348 -95.968750
		local checkpoint3 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(2104.908447, 5759.881348, -95.968750), Ang = Angle(0, 45, 0) })
		local checkpointTrigger3 = ents.Create("trigger_once")
		checkpointTrigger3:SetupTrigger(
			Vector(2104.908447, 5759.881348, -95.968750),
			Angle(0,0,0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger3.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint3)
		end

		local npcMaker1 = ents.Create("npc_maker")
		npcMaker1:SetPos(Vector(-2174.593262, 9086.971680, 288.031250))
		npcMaker1:SetAngles(Angle(0, 180, 0))
		npcMaker1:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker1:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker1:SetKeyValue("MaxNPCCount", "4")
		npcMaker1:SetKeyValue("MaxLiveChildren", "4")
		npcMaker1:SetKeyValue("StartDisabled", "1")
		npcMaker1:SetKeyValue("NPCSquadName", "Overwatch")
		npcMaker1:Spawn()

		local npcMaker2 = ents.Create("npc_maker")
		npcMaker2:SetPos(Vector(-3895.005615, 9614.399414, 288.031250))
		npcMaker2:SetAngles(Angle(0, 180, 0))
		npcMaker2:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		npcMaker2:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker2:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker2:SetKeyValue("MaxNPCCount", "2")
		npcMaker2:SetKeyValue("MaxLiveChildren", "2")
		npcMaker2:SetKeyValue("StartDisabled", "1")
		npcMaker2:SetKeyValue("NPCSquadName", "Overwatch")
		npcMaker2:SetKeyValue("Radius", "200")
		npcMaker2:SetName("lambda_npc_maker2")
		npcMaker2:Spawn()

		-- gallery_destgroup_1
		ents.WaitForEntityByName("gallery_destgroup_1", function(ent)
			ent:SetPos(Vector(-47.880901, 6160.045898, -58.842937))
		end, true)

		-- room3_cop
		-- Lets not wait for the explosion, thats boring.
		ents.WaitForEntityByName("room3_cop", function(ent)
			ent:Fire("AddOutput", "OnDeath gallerycop_maker2,Enable")
			ent:Fire("AddOutput", "OnDeath gallerycop_maker3,Enable")
		end)

		--1251.081177 5989.771484 -95.968750
		--[[
		local trigger1 = ents.Create("trigger_once")
		trigger1:SetupTrigger(
			Vector(1251.081177, 5989.771484, -95.968750),
			Angle(0,0,0),
			Vector(-150, -150, 0),
			Vector(150, 150, 180)
		)
		trigger1.OnTrigger = function()
			TriggerOutputs({
				{"gallery_start_relay", "Trigger", 0.0, ""},
				--{"escape_foil_brush", "Kill", 0.2, ""},
				{"gallerycop_maker1", "Enable", 0.0, ""},
			})
		end
		]]
		ents.WaitForEntityByName("massacre_initiate_trigger", function(ent)
			ent:Fire("AddOutput", "OnTrigger gallery_start_relay,Trigger,,0.0")
			ent:Fire("AddOutput", "OnTrigger gallerycop_maker1,Enable,,0.0")
			ent:Fire("AddOutput", "OnTrigger lambda_npc_maker2,Enable,,0.0")
		end)

		-- -2849.247314 8805.366211 47.039879
		local trigger2 = ents.Create("trigger_once")
		trigger2:SetupTrigger(
			Vector(-2849.247314, 8805.366211, 47.039879),
			Angle(0,0,0),
			Vector(-150, -150, 0),
			Vector(150, 150, 180)
		)
		trigger2.OnTrigger = function()
			npcMaker1:Fire("Enable")
			npcMaker2:Fire("Enable")
		end

		local npcMaker3 = ents.Create("npc_maker")
		npcMaker3:SetPos(Vector(-3001.867676, 6401.143066, -88.595261))
		npcMaker3:SetAngles(Angle(0, 180, 0))
		npcMaker3:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		npcMaker3:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker3:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker3:SetKeyValue("MaxNPCCount", "2")
		npcMaker3:SetKeyValue("MaxLiveChildren", "2")
		npcMaker3:SetKeyValue("StartDisabled", "1")
		npcMaker3:SetKeyValue("NPCSquadName", "mudcopsquad")
		npcMaker3:SetKeyValue("Radius", "200")
		npcMaker3:SetName("lambda_npc_maker3")
		npcMaker3:Spawn()

		-- -2956.739746 6570.918945 -95.968781
		local npcMaker4 = ents.Create("npc_maker")
		npcMaker4:SetPos(Vector(-2264.835693, 6979.781250, 128.031250))
		npcMaker4:SetAngles(Angle(0, 180, 0))
		npcMaker4:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		npcMaker4:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker4:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker4:SetKeyValue("MaxNPCCount", "8")
		npcMaker4:SetKeyValue("MaxLiveChildren", "2")
		npcMaker4:SetKeyValue("StartDisabled", "1")
		npcMaker4:SetKeyValue("NPCSquadName", "mudcopsquad")
		--npcMaker4:SetKeyValue("Radius", "300")
		npcMaker4:SetName("lambda_npc_maker4")
		npcMaker4:Spawn()

		-- -3456.227539 6972.550293 128.031250
		local npcMaker5 = ents.Create("npc_maker")
		npcMaker5:SetPos(Vector(-3552.302979, 6977.757324, 128.031250))
		npcMaker5:SetAngles(Angle(0, 180, 0))
		npcMaker5:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER)
		npcMaker5:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker5:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker5:SetKeyValue("MaxNPCCount", "3")
		npcMaker5:SetKeyValue("MaxLiveChildren", "1")
		npcMaker5:SetKeyValue("StartDisabled", "1")
		npcMaker5:SetKeyValue("NPCSquadName", "mudcopsquad")
		--npcMaker5:SetKeyValue("Radius", "300")
		npcMaker5:SetName("lambda_npc_maker4")
		npcMaker5:Spawn()


		-- -2620.882813 5306.772949 -45.723671
		local trigger3 = ents.Create("trigger_once")
		trigger3:SetupTrigger(
			Vector(-2620.882813, 5306.772949, -45.723671),
			Angle(0,0,0),
			Vector(-150, -150, 0),
			Vector(150, 150, 180)
		)
		trigger3.OnTrigger = function()
			npcMaker3:Fire("Enable")
			npcMaker4:Fire("Enable")
			npcMaker5:Fire("Enable")
		end

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
