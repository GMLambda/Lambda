AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons = {},
	Ammo = {},
	Armor = 30,
	HEV = true,
}

MAPSCRIPT.InputFilters =
{
	["station_cop_2"] = { "Kill" },
	["station_cop_1"] = { "Kill" },
	["station_cop_4"] = { "Kill" },
	["rappeller_cop_2_maker"] = { "Spawn" },
	["rappeller_cop_2_maker_2"] = { "Spawn" },
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

		-- Make sure the door is there and lock it.
		local transition_door = ents.FindFirstByName("transition_door")
		if not IsValid(transition_door) then
			transition_door = ents.Create("prop_door_rotating")
			transition_door:SetPos(Vector(-9943.000000, -3970.000000, 374.000000))
			transition_door:SetAngles(Angle(0, -90, 0))
			transition_door:SetModel("models/props_c17/door01_left.mdl")
			transition_door:SetSkin(5)
			transition_door:Spawn()
			transition_door:Activate()
		end
		transition_door:Fire("close")
		transition_door:Fire("lock")

		-- Fix barney beeing strict about standing infront of him
		local scriptCond_seeBarney = ents.FindFirstByName("scriptCond_seeBarney")
		scriptCond_seeBarney:SetKeyValue("PlayerActorFOV", "-1")
		scriptCond_seeBarney:SetKeyValue("PlayerTargetLOS", "3")

		-- Lets lift up the spawn a little, theres some invisible object that gets players stuck inside.
		local spawns = ents.FindByClass("info_player_start")
		for k,v in pairs(spawns) do
			local pos = v:GetPos()
			v:SetPos(pos + Vector(0,0,5))
		end

		-- Lets automatically scale some enemies.
		-- -7871.712891 -1510.040405 -63.968754
		local maker1 = ents.Create("npc_maker")
		maker1:SetPos(Vector(-8490.908203, -2256.173096, -63.968750))
		maker1:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		maker1:SetKeyValue("StartDisabled", "1")
		maker1:SetKeyValue("NPCType", "npc_metropolice")
		maker1:SetKeyValue("NPCSquadName", "baton_cop_squad")
		maker1:SetKeyValue("additionalequipment", "weapon_pistol")
		maker1:SetKeyValue("MaxNPCCount", "2")
		maker1:SetKeyValue("MaxLiveChildren", "2")
		maker1:SetKeyValue("SpawnFrequency", "0.2")
		maker1:SetKeyValue("Radius", "1000")
		maker1:Spawn()

		-- -8038.701660 -2541.850098 -63.968746
		local maker2 = ents.Create("npc_maker")
		maker2:SetPos(Vector(-8038.701660, -2541.850098, -63.968746))
		maker2:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		maker2:SetKeyValue("StartDisabled", "1")
		maker2:SetKeyValue("NPCType", "npc_metropolice")
		maker2:SetKeyValue("NPCSquadName", "baton_cop_squad")
		maker2:SetKeyValue("additionalequipment", "weapon_pistol")
		maker2:SetKeyValue("MaxNPCCount", "2")
		maker2:SetKeyValue("MaxLiveChildren", "2")
		maker2:SetKeyValue("SpawnFrequency", "0.2")
		maker2:SetKeyValue("Radius", "1000")
		maker2:Spawn()

		local maker3 = ents.Create("npc_maker")
		maker3:SetPos(Vector(-6699.455078, -1714.247314, -63.968750))
		maker3:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
		maker3:SetKeyValue("StartDisabled", "1")
		maker3:SetKeyValue("NPCType", "npc_metropolice")
		maker3:SetKeyValue("NPCSquadName", "baton_cop_squad")
		maker3:SetKeyValue("additionalequipment", "weapon_pistol")
		maker3:SetKeyValue("MaxNPCCount", "2")
		maker3:SetKeyValue("MaxLiveChildren", "2")
		maker3:SetKeyValue("SpawnFrequency", "0.2")
		maker3:SetKeyValue("Radius", "1000")
		maker3:Spawn()

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-8169.935059, -3181.270508, 192.031250), Ang = Angle(0, 0, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(-8169.935059, -3181.270508, 192.031250),
			Angle(0, 0, 0),
			Vector(-50, -50, 0),
			Vector(50, 50, 70)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
			maker1:Fire("Enable")
			maker2:Fire("Enable")
			maker3:Fire("Enable")
		end

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
