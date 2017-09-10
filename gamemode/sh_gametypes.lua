if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("GameType")

include("gametypes/hl2.lua")
include("gametypes/hl2ep1.lua")
include("gametypes/hl2dm.lua")

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
	if SERVER then
		print("-- Loaded GameTypes --")
		for k,v in pairs(GameTypes.Registered) do
			print("> " .. k)
		end
	end
end

function GM:SetGameType(gametype)
	DbgPrint("SetGameType: " .. tostring(gametype))
	local gametypeData = GameTypes:Get(gametype)
	if gametypeData == nil then
		error("Unable to find gametype: " .. gametype)
		return
	end
	if gametypeData.LoadMapScript ~= nil then
		gametypeData:LoadMapScript()
	end
	self.GameType = gametypeData
	self.MapScript = gametypeData.MapScript or table.Copy(DEFAULT_MAPSCRIPT)

end

function GM:ReloadGameType()

	if self.GameType ~= nil then
		local gametype = self.GameType
		gametype:LoadMapScript()
		self.MapScript = gametype.MapScript or table.Copy(DEFAULT_MAPSCRIPT)
	end

end

function GM:GetGameType()
	return self.GameType
end
