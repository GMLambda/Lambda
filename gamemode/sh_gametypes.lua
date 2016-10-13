AddCSLuaFile()

include("gametypes/hl2.lua")

local DEFAULT_MAPSCRIPT = {}
DEFAULT_MAPSCRIPT.InputFilters = {}
DEFAULT_MAPSCRIPT.DefaultLoadout =
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
		"weapon_ar2",
		"weapon_rpg",
		"weapon_crossbow",
        "weapon_bugbait",
	},
	Ammo =
	{
		["Pistol"] = 20,
		["SMG1"] = 45,
		["357"] = 6,
		["Grenade"] = 3,
		["Buckshot"] = 12,
		["AR2"] = 50,
		["RPG_Round"] = 8,
		["SMG1_Grenade"] = 3,
		["XBowBolt"] = 4,
	},
	Armor = 60,
	HEV = true,
}
DEFAULT_MAPSCRIPT.EntityCleanupFilter =
{
}

-- Default functions.
DEFAULT_MAPSCRIPT.Init = function(self) end
DEFAULT_MAPSCRIPT.PostInit = function(self) end
DEFAULT_MAPSCRIPT.PrePlayerSpawn = function(self, ply) end
DEFAULT_MAPSCRIPT.PostPlayerSpawn = function(self, ply) end
DEFAULT_MAPSCRIPT.OnNewGame = function(self) end

GameTypes = GameTypes or {}
GameTypes.Registered = {}

function GameTypes:Add(name, tbl)
	local mappedName = name:lower()
	if self.Registered[mappedName] ~= nil then
		error("GameType name is already taken: " .. name)
	end
	self.Registered[mappedName] = tbl
end

function GameTypes:Get(name)
	local mappedName = name:lower()
	return self.Registered[mappedName]
end

function GM:LoadGameTypes()
	hook.Run("LambdaLoadGameTypes", GameTypes)
end

function GM:SetGameType(gametype)
	local gametype = GameTypes:Get(gametype)
	if gametype == nil then
		error("Unable to find gametype: " .. gametype)
		return
	end
	self.GameType = gametype
	self.MapScript = gametype.MapScript or table.Copy(DEFAULT_MAPSCRIPT)
end

function GM:GetGameType()
	return self.GameType
end
