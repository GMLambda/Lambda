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
GAMETYPE.PlayerTiming = false
GAMETYPE.WaitForPlayers = false
GAMETYPE.Settings = {}

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

function GAMETYPE:IsPlayerEnemy(ply1, ply2)
    return false
end

function GAMETYPE:AddSetting(id, option)

    if CLIENT and bit.band(option.flags, FCVAR_REPLICATED) ~= 0 and bit.band(option.flags, FCVAR_ARCHIVE) ~= 0 then 
        DbgPrint("Removing FCVAR_ARCHIVE from " .. id)
        flags = bit.band(option.flags, bit.bnot(FCVAR_ARCHIVE))
    end

    local value = option.value
    local prefix = "lambda_"
    local actualName = prefix .. id
    local actualValue = ""

    if isbool(value) then
        actualValue = tostring(tonumber(value))
    elseif isstring(value) then
        actualValue = value
    else
        actualValue = tostring(value)
    end

    local convar = CreateConVar(actualName, actualValue, option.flags, option.info)
    --local gametypeSettings = self.Settings
    self.Settings[id] = option

    if fn ~= nil and isfunction(fn) then
        cvars.AddChangeCallback(actualName, fn)
    end

    return convar

end


function GAMETYPE:InitSettings()

    --SERVER
    self:AddSetting("walkspeed",{Category = "SERVER", NiceName = "#GM_WALKSPEED", value_type = "string", value = 150, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Walk speed" })
    self:AddSetting("normspeed",{Category = "SERVER", NiceName = "#GM_NORMSPEED", value_type = "string", value = 190, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Walk speed" })
    self:AddSetting("sprintspeed",{Category = "SERVER", NiceName = "#GM_SPRINTSPEED", value_type = "string", value = 320, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Sprint speed" })
    self:AddSetting("connect_timeout",{Category = "SERVER", NiceName = "#GM_CONNECTTIMEOUT", value_type = "string", value = 120, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Time required before player is considered to time out." })
    self:AddSetting("playercollision",{Category = "SERVER", NiceName = "#GM_PLAYERCOLLISION", value_type = "bool", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Enables or disables collisions between players." })
    self:AddSetting("friendlyfire",{Category = "SERVER", NiceName = "#GM_FRIENDLYFIRE", value_type = "bool", value = 0, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Enables friendly fire, only works if player collisions enabled." })
    self:AddSetting("weapon_strip_force",{Category = "SERVER", NiceName = "#GM_PREVENTITEMMOVE", value_type = "bool", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Prevents players from moving weapons and items from by shooting." })
    self:AddSetting("limit_default_ammo",{Category = "SERVER", NiceName = "#GM_DEFAMMO", value_type = "bool", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "If enabled weapons default ammo will use the sk_* settings for max limit." })
    self:AddSetting("allow_auto_jump",{Category = "SERVER", NiceName = "#GM_AUTOJUMP", value_type = "bool", value = 150, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Allow automatically jumping if on ground" })
    self:AddSetting("max_respawn_timeout",{Category = "SERVER", NiceName = "#GM_RESPAWNTIME", value_type = "string", value = 20, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Time before player can respawn" })
    self:AddSetting("map_restart_timeout",{Category = "SERVER", NiceName = "#GM_RESTARTTIME", value_type = "string", value = 20, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), info = "Time before a new round starts when all players are dead" })
    self:AddSetting("instance_id",{Category = "SERVER", NiceName = "#GM_INSTANCEID", value_type = "string", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), info = "Allows to assign a unique instance id to support multiple srcds instances at once from the same directory." })
    self:AddSetting("map_change_timeout",{Category = "SERVER", NiceName = "#GM_MAPCHANGETIME", value_type = "string", value = 60, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), info = "Time before changing level as soon first player gets to it." })
    self:AddSetting("player_god",{Category = "SERVER", NiceName = "#GM_GODMODE", value_type = "bool", value = 0, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), info = "Player god mode." })
    self:AddSetting("pickup_delay",{Category = "SERVER", NiceName = "#GM_PICKUPDELAY", value_type = "string", value = 0.5, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), info = "The time to wait before player can pickup again" })

end

function GAMETYPE:GetScoreboardInfo()
    return {}
end

hook.Add("LambdaLoadGameTypes", "LambdaBaseGameType", function(gametypes)
    gametypes:Add("lambda_base", GAMETYPE)
end)
