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

		local BridgePositions =
		{
			Vector(-2809.293701, 6795.291992, 144.031250),
			Vector(-2875.369141, 6793.270996, 144.031250),
			Vector(-2960.664307, 6790.913574, 144.031250),
			Vector(-3056.151855, 6790.148438, 144.031250),
			Vector(-3138.704102, 6790.096191, 144.031250),
		}

		local function SendNPCToBridge(npc)
			local bridgePos = table.Random(BridgePositions)
			util.RunDelayed(function()
				if not IsValid(npc) then
					return
				end
				npc:SetLastPosition(bridgePos)
				npc:SetSchedule(SCHED_FORCED_GO_RUN)
				DbgPrint("Sending NPC to Bridge")
			end, CurTime() + 1)
		end

		-- -2956.739746 6570.918945 -95.968781
		local npcMaker3 = ents.Create("npc_maker")
		npcMaker3:SetPos(Vector(-2264.835693, 6979.781250, 128.031250))
		npcMaker3:SetAngles(Angle(0, 180, 0))
		npcMaker3:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		npcMaker3:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker3:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker3:SetKeyValue("MaxNPCCount", "8")
		npcMaker3:SetKeyValue("MaxLiveChildren", "2")
		npcMaker3:SetKeyValue("StartDisabled", "1")
		npcMaker3:SetKeyValue("NPCSquadName", "mudcopsquad")
		--npcMaker4:SetKeyValue("Radius", "300")
		npcMaker3:SetName("lambda_npc_maker3")
		npcMaker3:Spawn()
		npcMaker3.OnSpawnNPC = function(s, ent) SendNPCToBridge(ent) end

		-- -3456.227539 6972.550293 128.031250
		local npcMaker4 = ents.Create("npc_maker")
		npcMaker4:SetPos(Vector(-3552.302979, 6977.757324, 128.031250))
		npcMaker4:SetAngles(Angle(0, 180, 0))
		npcMaker4:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER)
		npcMaker4:SetKeyValue("NPCType", "npc_metropolice")
		npcMaker4:SetKeyValue("additionalequipment", "weapon_pistol")
		npcMaker4:SetKeyValue("MaxNPCCount", "3")
		npcMaker4:SetKeyValue("MaxLiveChildren", "1")
		npcMaker4:SetKeyValue("StartDisabled", "1")
		npcMaker4:SetKeyValue("NPCSquadName", "mudcopsquad")
		--npcMaker5:SetKeyValue("Radius", "300")
		npcMaker4:SetName("lambda_npc_maker4")
		npcMaker4:Spawn()
		npcMaker4.OnSpawnNPC = function(s, ent) SendNPCToBridge(ent) end

		-- kill volume
		local bridgeKillTrigger = ents.Create("trigger_multiple")
		bridgeKillTrigger:SetupTrigger(
			Vector(-2960.003174, 6840.497559, 144.057632),
			Angle(0, 0, 0),
			Vector(-300, -100, 0),
			Vector(300, 100, 100)
		)
		bridgeKillTrigger:SetKeyValue("targetname", "lambda_bridge_killbox")
		bridgeKillTrigger:SetKeyValue("StartDisabled", "1")
		bridgeKillTrigger:SetKeyValue("spawnflags", SF_TRIGGER_ALLOW_NPCS)
		bridgeKillTrigger.OnTrigger = function(ent)
			DbgPrint("Killing all bridge NPCs")
			local t = ent:GetTouchingObjects()
			for _,v in pairs(t) do
				DbgPrint("Killing: " .. tostring(v))
				local world = game.GetWorld()
				v:TakeDamage(1000, world, world)
			end
			ent.OnTrigger = nil

			-- Lets block the bridge otherwise it looks silly.
			local prop = ents.Create("prop_physics")
			prop:SetModel("models/props_trainstation/train001.mdl")
			prop:SetPos(Vector(-2950.885742, 6831.411621, 241.852402))
			prop:SetAngles(Angle(0, 90, 0))
			prop:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
			prop:SetSolidFlags(FSOLID_NOT_SOLID)
			prop:AddEffects(EF_NODRAW)
			prop:Spawn()
			local phys = prop:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
			end

		end

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
		end

		ents.WaitForEntityByName("mud_bridge_collapse_relay", function(ent)
			ent:Fire("AddOutput", "OnTrigger lambda_bridge_killbox,Enable,,0")
		end)

		ents.WaitForEntityByName("mud_bridge_barrels", function(ent)
			ent:Fire("AddOutput", "OnBreak lambda_npc_maker3,Kill,,0")
			ent:Fire("AddOutput", "OnBreak lambda_npc_maker4,Kill,,0")
		end)

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
