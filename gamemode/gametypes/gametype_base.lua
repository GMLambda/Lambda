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

    local function GetCVarValue(cvar)
        if ConVarExists(cvar) then
            if option.value_type == "int" and option.value_type == "bool" then
                return GetConVar(cvar):GetInt()
            elseif option.value_type == "float" then
                    return GetConVar(cvar):GetFloat()
            else
                    return GetConVar(cvar):GetString()
            end
        else
            return false
        end
    end

    if CLIENT and bit.band(option.flags, FCVAR_REPLICATED) ~= 0 and bit.band(option.flags, FCVAR_ARCHIVE) ~= 0 then
        DbgPrint("Removing FCVAR_ARCHIVE from " .. id)
        flags = bit.band(option.flags, bit.bnot(FCVAR_ARCHIVE))
    end

    local value = option.value
    local prefix = "lambda_"
    local actualName = prefix .. id
    local actualValue = ""

    local storedVal = GetCVarValue(actualName)

    if storedVal then
        value = storedVal
    end

    if option.value_type == "int" or option.value_type == "float" or option.value_type == "bool" then
        actualValue = tonumber(value)
    end

    if option.value_type == "string" then
        actualValue = tostring(value)
    end

    local convar = CreateConVar(actualName, actualValue, option.flags, option.info)
    self.Settings[id] = option
    self.Settings[id].getCvar = convar
    self.Settings[id].value = actualValue

    cvars.AddChangeCallback(actualName, function(cvar, oldval, newval)
        local cv = string.TrimLeft(cvar, prefix)
        self.Settings[cv].value = newval
    end)

    return convar

end


function GAMETYPE:InitSettings()

    --SERVER
    self:AddSetting("walkspeed",{Category = "SERVER", NiceName = "#GM_WALKSPEED", value_type = "int", value = 150, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1000, info = "Walk speed" })
    self:AddSetting("normspeed",{Category = "SERVER", NiceName = "#GM_NORMSPEED", value_type = "int", value = 190, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1000, info = "Walk speed" })
    self:AddSetting("sprintspeed",{Category = "SERVER", NiceName = "#GM_SPRINTSPEED", value_type = "int", value = 320, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1000, info = "Sprint speed" })
    self:AddSetting("connect_timeout",{Category = "SERVER", NiceName = "#GM_CONNECTTIMEOUT", value_type = "int", value = 120, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 300, info = "Timeout limit" })
    self:AddSetting("playercollision",{Category = "SERVER", NiceName = "#GM_PLAYERCOLLISION", value_type = "bool", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1, info = "Player collision" })
    self:AddSetting("friendlyfire",{Category = "SERVER", NiceName = "#GM_FRIENDLYFIRE", value_type = "bool", value = 0, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1, info = "Friendly fire" })
    self:AddSetting("prevent_item_move",{Category = "SERVER", NiceName = "#GM_PREVENTITEMMOVE", value_type = "bool", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1, info = "Prevent item moving" })
    self:AddSetting("limit_default_ammo",{Category = "SERVER", NiceName = "#GM_DEFAMMO", value_type = "bool", value = 1, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1, info = "Limit default ammo" })
    self:AddSetting("allow_auto_jump",{Category = "SERVER", NiceName = "#GM_AUTOJUMP", value_type = "bool", value = 150, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 1, info = "Auto jump" })
    self:AddSetting("max_respawn_timeout",{Category = "SERVER", NiceName = "#GM_RESPAWNTIME", value_type = "int", value = 20, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 300, extra = {NiceName = "#GM_NORESPAWN", value_type = "bool", value = 0, cached = 0, info = "No Respawn"}, info = "Respawn time" })
    self:AddSetting("map_restart_timeout",{Category = "SERVER", NiceName = "#GM_RESTARTTIME", value_type = "int", value = 20, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 300, info = "Restart time" })
    self:AddSetting("map_change_timeout",{Category = "SERVER", NiceName = "#GM_MAPCHANGETIME", value_type = "int", value = 60, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), maxv = 300, info = "Map change time" })
    self:AddSetting("player_god",{Category = "SERVER", NiceName = "#GM_GODMODE", value_type = "bool", value = 0, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), maxv = 1, info = "Player god mode" })
    self:AddSetting("pickup_delay",{Category = "SERVER", NiceName = "#GM_PICKUPDELAY", value_type = "float", value = 0.5, flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), maxv = 10, info = "Pickup delay" })
    self:AddSetting("difficulty",{Category = "SERVER", NiceName = "#GM_DIFFICULTY", value_type = "string", value = "2", flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), maxv = 5, GetDifficulty = function() return GAMEMODE:GetDifficulty() end, choices = GAMEMODE:GetDifficulties(), choices_text = function(n) return GAMEMODE:GetDifficultyText(n) end, info = "Difficulty" })
    self:AddSetting("difficulty_metrics",{Category = "DEVELOPER", NiceName = "#GM_DIFFMETRICS", value_type = "bool", value = 0, flags = bit.bor(0, FCVAR_REPLICATED), maxv = 1, info = "NPC/Player metrics" })


end

function GAMETYPE:GetScoreboardInfo()
    return {}
end

hook.Add("LambdaLoadGameTypes", "LambdaBaseGameType", function(gametypes)
    gametypes:Add("lambda_base", GAMETYPE)
end)
