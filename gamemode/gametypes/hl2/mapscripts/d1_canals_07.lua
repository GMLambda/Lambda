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
	},
	Ammo =
	{
		["Pistol"] = 60,
		["SMG1"] = 60,
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
	["global_newgame_entmaker"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(11292.084961, 2207.724365, -255.968750), Ang = Angle(0, -90, 0) })
		local checkpointTrigger1 = ents.Create("trigger_once")
		checkpointTrigger1:SetupTrigger(
			Vector(11296.274414, 2074.708008, -255.968750),
			Angle(0, 0, 0),
			Vector(-100, -100, 0),
			Vector(100, 100, 180)
		)
		checkpointTrigger1.OnTrigger = function()
			GAMEMODE:SetVehicleCheckpoint(Vector(10367.498047, 1265.902466, -487.621826), Angle(0, 90, 0))
			GAMEMODE:SetPlayerCheckpoint(checkpoint1)
		end

		-- Subtile rush blocking.
		ents.CreateSimple("prop_physics", {
			Model = "models/props_wasteland/laundry_washer003.mdl",
			Pos = Vector(7780.393555, 1381.725220, -228.653198),
			Ang = Angle(0, -90, 0),
			MoveType = MOVETYPE_NONE,
			SpawnFlags = SF_PHYSPROP_MOTIONDISABLED,
			Flags = FL_STATICPROP,
		})

		-- Remove the default explose barrels, too easy to shoot from the gate.
		local searchPos = Vector(6975.288574, 1361.227783, -255.968735)
		for _,v in pairs(ents.FindInBox(searchPos - Vector(250, 250, 0), searchPos + Vector(255, 255, 100))) do
			if v:GetClass() == "prop_physics" and v:GetModel() == "models/props_c17/oildrum001_explosive.mdl" then
				v:Remove()
			end
		end

		-- Create better positioned ones.

		-- 6899.897461 1423.682495 -255.634171, 0.003 -171.758 0.005
		ents.CreateSimple("prop_physics", {
			Model = "models/props_c17/oildrum001_explosive.mdl",
			Pos = Vector(6991.625488, 1304.797119, -255.640411),
		})

		-- 6871.656250 1421.762695 -255.474014, -0.403 136.494 0.118
		ents.CreateSimple("prop_physics", {
			Model = "models/props_c17/oildrum001_explosive.mdl",
			Pos = Vector(7020.829102, 1305.285522, -255.544678),
		})

		-- Block the view to the barrels
		ents.CreateSimple("prop_physics", {
			Model = "models/props_debris/metal_panel01a.mdl",
			Pos = Vector(7050.838379, 1287.056885, -231.276840),
			Ang = Angle(6.208, -89.358, 90.071),
		})

		ents.CreateSimple("prop_physics", {
			Model = "models/props_c17/oildrum001.mdl",
			Pos = Vector(7131.379883, 1305.574463, -255.968750),
		})

		ents.CreateSimple("prop_physics", {
			Model = "models/props_c17/oildrum001.mdl",
			Pos = Vector(7089.489258, 1304.665649, -255.525589),
		})

		-- Additional fancy
		ents.CreateSimple("prop_dynamic", {
			Model = "models/props_buildings/row_res_1_fullscale.mdl",
			Pos = Vector(9748.061523, -1349.575928, -6.638969),
			MoveType = MOVETYPE_NONE,
		})

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
