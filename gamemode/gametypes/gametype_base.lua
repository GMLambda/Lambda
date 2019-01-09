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
GAMETYPE.DifficultyData = {}

function GAMETYPE:GetData(name)
    local base = self

    while base ~= nil do
        local var = base[name]
        if var ~= nil and isfunction(var) == false then return var end
        base = base.Base
    end

    return nil
end

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
    ply:AddDeaths(1)

    -- Suicide?
    if inflictor == ply or attacker == ply then
        attacker:AddFrags(-1)

        return
    end

    -- Friendly kill?
    if IsValid(attacker) and attacker:IsPlayer() then
        attacker:AddFrags(-1)
    elseif IsValid(inflictor) and inflictor:IsPlayer() then
        inflictor:AddFrags(-1)
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

function GAMETYPE:InitSettings()
    local difficulties = {}

    for k, v in pairs(self.DifficultyData or {}) do
        difficulties[k] = v.Name
    end

    --SERVER
    GAMEMODE:AddSetting("walkspeed", {
        Category = "SERVER",
        NiceName = "#GM_WALKSPEED",
        Description = "Walk speed",
        Type = "int",
        Default = 150,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Min = 1, Max = 1000 },
    })

    GAMEMODE:AddSetting("normspeed", {
        Category = "SERVER",
        NiceName = "#GM_NORMSPEED",
        Description = "Run speed",
        Type = "int",
        Default = 190,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Min = 1, Max = 1000 },
    })

    GAMEMODE:AddSetting("sprintspeed", {
        Category = "SERVER",
        NiceName = "#GM_SPRINTSPEED",
        Description = "Sprint speed",
        Type = "int",
        Default = 320,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Min = 1, Max = 1000 },
    })

    GAMEMODE:AddSetting("connect_timeout", {
        Category = "SERVER",
        NiceName = "#GM_CONNECTTIMEOUT",
        Description = "Timeout limit",
        Type = "int",
        Default = 120,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Max = 60 * 3 },
    })

    GAMEMODE:AddSetting("playercollision", {
        Category = "SERVER",
        NiceName = "#GM_PLAYERCOLLISION",
        Description = "Player collision",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("friendlyfire", {
        Category = "SERVER",
        NiceName = "#GM_FRIENDLYFIRE",
        Description = "Friendly fire",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("prevent_item_move", {
        Category = "SERVER",
        NiceName = "#GM_PREVENTITEMMOVE",
        Description = "Prevent item moving",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("limit_default_ammo", {
        Category = "SERVER",
        NiceName = "#GM_DEFAMMO",
        Description = "Limit default ammo",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("allow_auto_jump", {
        Category = "SERVER",
        NiceName = "#GM_AUTOJUMP",
        Description = "Auto jump",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("max_respawn_timeout", {
        Category = "SERVER",
        NiceName = "#GM_RESPAWNTIME",
        Description = "Respawn time",
        Type = "int",
        Default = 20,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Min = -1, Max = 600 },
    })

    GAMEMODE:AddSetting("map_restart_timeout", {
        Category = "SERVER",
        NiceName = "#GM_RESTARTTIME",
        Description = "Restart time",
        Type = "int",
        Default = 20,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Min = 0, Max = 100 },
    })

    GAMEMODE:AddSetting("map_change_timeout", {
        Category = "SERVER",
        NiceName = "#GM_MAPCHANGETIME",
        Description = "Map change time",
        Type = "int",
        Default = 60,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = { Min = 0, Max = 100 },
    })

    GAMEMODE:AddSetting("player_god", {
        Category = "SERVER",
        NiceName = "#GM_GODMODE",
        Description = "Player god mode",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("pickup_delay", {
        Category = "SERVER",
        NiceName = "#GM_PICKUPDELAY",
        Description = "Pickup delay",
        Type = "float",
        Default = 0.5,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        maxv = 10,
    })

    GAMEMODE:AddSetting("difficulty_metrics", {
        Category = "DEVELOPER",
        NiceName = "#GM_DIFFMETRICS",
        Description = "NPC/Player metrics",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_REPLICATED),
        maxv = 1,
    })

    GAMEMODE:AddSetting("difficulty", {
        Category = "SERVER",
        NiceName = "#GM_DIFFICULTY",
        Description = "Difficulty",
        Type = "int",
        Default = 2,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Extra = {
            Type = "combo",
            Choices = difficulties,
        },
    })

    GAMEMODE:AddSetting("weapondropmode", {
        Category = "SERVER",
        NiceName = "#GM_WEAPONDROP",
        Description = "Weapon Drop Mode",
        Type = "int",
        Default = 1,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Extra = {
            Type = "combo",
            Choices = { [0] = "Nothing", [1] = "Active", [2] = "Everything" },
        },
    })

end

function GAMETYPE:GetScoreboardInfo()
    return {}
end

hook.Add("LambdaLoadGameTypes", "LambdaBaseGameType", function(gametypes)
    gametypes:Add("lambda_base", GAMETYPE)
end)