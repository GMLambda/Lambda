if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("GameType")

include("gametypes/gametype_base.lua")
include("gametypes/hl2.lua")
include("gametypes/hl2ep1.lua")
include("gametypes/hl2dm.lua")
include("gametypes/hl1s.lua")

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
	-- Don't reference the table.
	local data = table.Copy(tbl)
	data.GameType = mappedName

	local meta = {}
	meta.__index = function(i, k)
		local base = i
		while base ~= nil do
			local v = rawget(base, k)
			if v ~= nil then
				return v
			end
			base = rawget(base, "Base")
		end
	end

	setmetatable(data, meta)

	self.Registered[mappedName] = data
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
	for k,v in pairs(GameTypes.Registered) do
		if v.BaseGameType ~= nil then
			local base = GameTypes.Registered[v.BaseGameType]
			if base == nil then
				print("GameType '" .. k .. "' references missing base: '" .. tostring(v.BaseGameType) .. "'")
				continue
			end
			v.Base = base
		end
	end
end

function GM:CallGameTypeFunc(name, ...)
	local base = self:GetGameType()
	while base ~= nil do
		if base[name] ~= nil and isfunction(base[name]) then
			return base[name](base, ...)
		end
		base = base.Base
	end
	return nil
end

function GM:GetGameTypeData(name)
	local base = self:GetGameType()
	while base ~= nil do
		if base[name] ~= nil and not isfunction(base[name]) then
			return base[name]
		end
		base = base.Base
	end
	return nil
end

function GM:SetGameType(gametype, isFallback)
	DbgPrint("SetGameType: " .. tostring(gametype))
	local gametypeData = GameTypes:Get(gametype)
	if gametypeData == nil then
		error("Unable to find gametype: " .. gametype)
		if isFallback ~= true then
			DbgPrint("Fallback: hl2")
			return self:SetGameType("hl2", true)
		end
	end

	if gametypeData.LoadCurrentMapScript ~= nil then
		gametypeData:LoadCurrentMapScript()
	end

	if CLIENT and gametypeData.LoadLocalisation ~= nil then
		local lang = "english"
		local gmodLang = GetConVarString("gmod_language")
		if gmodLang == "en" then
			lang = "english"
		elseif gmodLang == "cz" then
			lang = "czech"
		elseif gmodLang == "nl" then
			lang = "dutch"
		elseif gmodLang == "de" then
			lang = "german"
		elseif gmodLang == "it" then
			lang = "italian"
		elseif gmodLang == "pl" then
			lang = "polish"
		elseif gmodLang == "ru" then
			lang = "russian"
		elseif gmodLang == "fr" then
			lang = "french"
		elseif gmodLang == "ko" then
			lang = "korean"
		elseif gmodLang == "sp" then
			lang = "spanish"
		elseif gmodLang == "ja" then
			lang = "japanese"
		else
			gmodLang = "en"
		end
		gametypeData:LoadLocalisation(lang, gmodLang)
	end

	self.GameType = gametypeData
	self:ResetMapScript()

end

function GM:ReloadGameType()

	if self.GameType ~= nil then
		self:ResetMapScript()
	end

end

function GM:ResetMapScript()
	local gametype = self.GameType
	if gametype.LoadCurrentMapScript ~= nil then
		gametype:LoadCurrentMapScript()
	end
	self.MapScript = gametype.MapScript or table.Copy(DEFAULT_MAPSCRIPT)
end

function GM:GetGameType()
	return self.GameType
end

function GM:GetMapScript()
	return self.MapScript or table.Copy(DEFAULT_MAPSCRIPT)
end 
