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
		"weapon_physcannon",
		"weapon_frag",
		"weapon_shotgun",
	},
	Ammo =
	{
		["Pistol"] = 20,
		["SMG1"] = 45,
		["357"] = 3,
		["Grenade"] = 1,
		["Buckshot"] = 12,
	},
	Armor = 60,
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
	--["test_name"] = true,
	["startobjects_template"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- The player gets stuck here, so we just put something there so it wont happen.
		--
		ents.CreateSimple("prop_physics", {
			Model = "models/props_debris/concrete_chunk02b.mdl",
			Pos = Vector(-3128.362549, -1026.139160, -3604.878906),
			Ang = Angle(2.362, -13.966, 9.108),
			MoveType = MOVETYPE_NONE,
			SpawnFlags = SF_PHYSPROP_MOTIONDISABLED,
			Flags = FL_STATICPROP,
		})

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	--DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
