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
	},
	Ammo =
	{
		["Pistol"] = 20,
		["SMG1"] = 45,
		["357"] = 3,
	},
	Armor = 60,
	HEV = true,
}

MAPSCRIPT.InputFilters =
{
	["inner_door"] = { "Close" },
	["lab_exit_door_raven"] = { "Close" },
	["lab_exit_door_raven2"] = { "Close" },
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
	["trigger_startScene"] = true,
	["pclip_exit_door_raven2"] = true,
	["brush_exit_door_raven_PClip"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- Perhaps skip this entire scene, its somewhat useless.
		local entryTrigger = ents.Create("trigger_once")
		entryTrigger:SetupTrigger(Vector(-64.453362, 2733.531006, -1279.9687500), Angle(0,0,0), Vector(-80, -105, 0), Vector(80, 105, 90))
		entryTrigger:SetKeyValue("teamwait", "1")
		--entryTrigger:SetKeyValue("lockplayers", "1") -- Do we really want this?
		entryTrigger.OnTrigger = function(self)
			--DbgPrint("All players inside trigger, closing door, swapping spawnpoint.")
			-- Everyone is inside, we can close the door.
			ents.WaitForEntityByName("logic_startScene", function(ent) ent:Fire("Trigger") end)

			-- Make sure players dont spawn outside the base
			local checkpoint = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-66.911217, 2753.892822, -1279.968750), Ang = Angle(0, 0, 0) })
			GAMEMODE:SetPlayerCheckpoint(checkpoint)
		end

		-- 454.184753 1670.932373 -1281.335693
		ents.WaitForEntityByName("elevator_trigger_go_up_1", function(ent)
			DbgPrint("Setting up elevator team wait")
			ent:SetKeyValue("teamwait", "1")
			ent.OnTrigger = function(self)

				DbgPrint("All players in elevator")

				local elevator_lab = ents.FindFirstByName("elevator_lab")
				local checkpoint = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(454.184753, 1670.932373, -1281.335693), Ang = Angle(0, 90, 0) })
				checkpoint:SetParent(elevator_lab)

				GAMEMODE:SetPlayerCheckpoint(checkpoint)

			end
		end)

		-- What is it with NPCs being busy?
		ents.WaitForEntityByName("lcs_alyxtour01", function(ent)
			ent:SetKeyValue("busyactor", "0")
		end)

		ents.WaitForEntityByName("lcs_alyxtour03", function(ent)
			ent:SetKeyValue("busyactor", "0")
		end)

		ents.WaitForEntityByName("lcs_alyxtour04", function(ent)
			ent:SetKeyValue("busyactor", "0")
		end)

		ents.WaitForEntityByName("lcs_Labtalk04", function(ent)
			ent:SetKeyValue("busyactor", "0")
		end)

		ents.WaitForEntityByName("trigger_alyxtour04b", function(ent)
			ent:SetKeyValue("teamwait", "1")
		end)

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
