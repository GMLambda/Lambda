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
	["gravgun_prop"] = { "Kill" }, -- We need it for spawn position.
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
	["global_newgame_spawner_ammo"] = true, -- They piled up 20 of em.

	["trigger_startScene"] = true,
	["pclip_exit_door_raven2"] = true,
	["brush_exit_door_raven_PClip"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		ents.WaitForEntityByName("filter_invulnerable", function(ent)
			ent:Remove()
		end)

		local gravgun_prop
		ents.WaitForEntityByName("gravgun_prop", function(ent) gravgun_prop = ent end)

		local createPhyscannon = ents.Create("lambda_clientcommand")
		createPhyscannon:Spawn()
		createPhyscannon.Command = function(s, data, activator, caller)

			DbgPrint("Creating gravity gun")

			local pos = Vector(-469.619568, 797.148071, -2688.000000)
			local ang = Angle(0, 0, 0)
			if IsValid(gravgun_prop) then -- Yes I've seen it break because alyx vanished.
				pos = gravgun_prop:GetPos()
				ang = gravgun_prop:GetAngles()
			end

			local wep = ents.CreateSimple("weapon_physcannon", {
				Pos = pos,
				Ang = ang,
			})
			local phys = wep:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetMass(1000) -- Somewhat prevents players trying to hide the gun or moving it too far as its rather important.
			end

			gravgun_prop:Remove()

			table.insert(GAMEMODE:GetMapScript().DefaultLoadout.Weapons, "weapon_physcannon")

			-- No longer needed.
			s:Remove()

			return true

		end

		-- Replace it with ours.
		ents.WaitForEntityByName("command_physcannon", function(ent)
			createPhyscannon:SetName("command_physcannon")
			ent:Remove()
		end)

		ents.WaitForEntityByName("airlock_south_door_exitb", function(ent)
			ent:SetKeyValue("speed", 60)
		end)

		ents.WaitForEntityByName("airlock_south_door_exit", function(ent)
			ent:SetKeyValue("speed", 60)
		end)

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-604.471130, 840.267578, -2688.000000), Ang = Angle(0, -90, 0) })

		-- Players must gather nearby alyx.
		ents.WaitForEntityByName("trigger_scrapyard_start", function(ent)
			-- Too small, causes players to freak out.
			--ent:SetKeyValue("teamwait", "1")

			local trigger = ents.Create("trigger_once")
			trigger:SetKeyValue("teamwait", "1")
			trigger:SetupTrigger(
				Vector(-608.376709, 525.137512, -2688.000000),
				Angle(0, 0, 0),
				Vector(-300, -300, 0),
				Vector(300, 300, 200)
			)
			trigger:Disable()
			trigger:CloneOutputs(ent)
			trigger:SetName("trigger_scrapyard_start")
			trigger.OnTrigger = function(self)
				DbgPrint("Starting scrapeyard scene")
				GAMEMODE:SetPlayerCheckpoint(checkpoint1)
			end

			ent:Remove()
		end)


		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-600.126587, 1066.952637, -2687.968750), Ang = Angle(0, 90, 0) })

		-- Players must be inside before doors close again.
		ents.WaitForEntityByName("trigger_attack02", function(ent)
			-- Too small, causes players to freak out.
			--ent:SetKeyValue("teamwait", "1")

			local trigger = ents.Create("trigger_once")
			trigger:SetKeyValue("teamwait", "1")
			trigger:SetupTrigger(
				Vector(-590.0, 1027.204346, -2687.968750),
				Angle(0, 0, 0),
				Vector(-100, -90, 0),
				Vector(100, 130, 100)
			)
			trigger:Disable()
			trigger:CloneOutputs(ent)
			trigger:SetName("trigger_attack02")
			trigger.OnTrigger = function(self)
				DbgPrint("Starting attack")
				GAMEMODE:SetPlayerCheckpoint(checkpoint2)
			end

			ent:Remove()
		end)

		-- Fix the door pushing players.
		GAMEMODE:WaitForInput("trigger_RavenDoor_Drop", "Enable", function()
			DbgPrint("Fixing the Ravenholm door")
			ents.WaitForEntityByName("ravenDoor", function(ent)
				ent:Fire("DisablePlayerCollision")
			end)
			return true -- Suppress, do not close that door
		end)

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
