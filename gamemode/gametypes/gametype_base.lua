if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("GameType")
local GAMETYPE = {}

GAMETYPE.Name = "Lambda Base"
GAMETYPE.MapScript = {}
GAMETYPE.PlayerSpawnClass = "info_player_start"
GAMETYPE.UsingCheckpoints = true
GAMETYPE.MapList = {}
GAMETYPE.ClassesEnemyNPC = {}
GAMETYPE.ImportantPlayerNPCNames = {}
GAMETYPE.ImportantPlayerNPCClasses = {}

function GAMETYPE:GetPlayerRespawnTime()
	return 0
end

function GAMETYPE:ShouldRestartRound()
	return false
end

function GAMETYPE:PlayerCanPickupWeapon(ply, wep)
	return true
end

function GAMETYPE:PlayerCanPickupItem(ply, item)
	return true
end

function GAMETYPE:GetWeaponRespawnTime()
	return 1
end

function GAMETYPE:GetItemRespawnTime()
	return -1
end

function GAMETYPE:ShouldRespawnWeapon(ent)
	return false
end

function GAMETYPE:PlayerDeath(ply, inflictor, attacker)
	ply:AddDeaths( 1 )

	-- Suicide?
	if inflictor == ply or attacker == ply then
		attacker:AddFrags(-1)
		return
	end

	-- Friendly kill?
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:AddFrags( -1 )
	elseif IsValid(inflictor) and inflictor:IsPlayer() then
		inflictor:AddFrags( -1 )
	end
end

function GAMETYPE:PlayerShouldTakeDamage(ply, attacker, inflictor)
	return true
end

function GAMETYPE:CanPlayerSpawn(ply, spawn)
	return true
end

function GAMETYPE:ShouldRespawnItem(ent)
	return false
end

function GAMETYPE:GetPlayerLoadout()
	return self.MapScript.DefaultLoadout or {}
end

function GAMETYPE:LoadMapScript(path, name)
	local MAPSCRIPT_FILE = "lambda/gamemode/gametypes/" .. path .. "/mapscripts/" .. name .. ".lua"
	self.MapScript = nil
	if file.Exists(MAPSCRIPT_FILE, "LUA") == true then
		self.MapScript = include(MAPSCRIPT_FILE)
		if self.MapScript ~= nil then
			DbgPrint("Loaded mapscript: " .. MAPSCRIPT_FILE)
		else
			self.MapScript = {}
		end
	else
		DbgPrint("No mapscript available.")
		self.MapScript = {}
	end
end

function GAMETYPE:LoadLocalisation(lang)
	-- Stub
end

function GAMETYPE:AllowPlayerTracking()
	return true
end

hook.Add("LambdaLoadGameTypes", "LambdaBaseGameType", function(gametypes)
	gametypes:Add("lambda_base", GAMETYPE)
end)
