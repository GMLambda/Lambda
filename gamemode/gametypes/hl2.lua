if SERVER then AddCSLuaFile() end
local DbgPrint = GetLogging("GameType")
local GAMETYPE = {}
GAMETYPE.Name = "Half-Life 2"
GAMETYPE.BaseGameType = "lambda_base"
GAMETYPE.MapScript = {}
GAMETYPE.PlayerSpawnClass = "info_player_start"
GAMETYPE.UsingCheckpoints = true
GAMETYPE.WaitForPlayers = true
GAMETYPE.MapList = {"d1_trainstation_01", "d1_trainstation_02", "d1_trainstation_03", "d1_trainstation_04", "d1_trainstation_05", "d1_trainstation_06", "d1_canals_01", "d1_canals_01a", "d1_canals_02", "d1_canals_03", "d1_canals_05", "d1_canals_06", "d1_canals_07", "d1_canals_08", "d1_canals_09", "d1_canals_10", "d1_canals_11", "d1_canals_12", "d1_canals_13", "d1_eli_01", "d1_eli_02", "d1_town_01", "d1_town_01a", "d1_town_02", "d1_town_03", "d1_town_02", "d1_town_02a", "d1_town_04", "d1_town_05", "d2_coast_01", "d2_coast_03", "d2_coast_04", "d2_coast_05", "d2_coast_07", "d2_coast_08", "d2_coast_07", "d2_coast_09", "d2_coast_10", "d2_coast_11", "d2_coast_12", "d2_prison_01", "d2_prison_02", "d2_prison_03", "d2_prison_04", "d2_prison_05", "d2_prison_06", "d2_prison_07", "d2_prison_08", "d3_c17_01", "d3_c17_02", "d3_c17_03", "d3_c17_04", "d3_c17_05", "d3_c17_06a", "d3_c17_06b", "d3_c17_07", "d3_c17_08", "d3_c17_09", "d3_c17_10a", "d3_c17_10b", "d3_c17_11", "d3_c17_12", "d3_c17_12b", "d3_c17_13", "d3_citadel_01", "d3_citadel_02", "d3_citadel_03", "d3_citadel_04", "d3_citadel_05", "d3_breen_01"}
GAMETYPE.ClassesEnemyNPC = {
    ["npc_metropolice"] = true,
    ["npc_combine"] = true,
    ["npc_combine_s"] = true,
    ["npc_zombie"] = true,
    ["npc_fastzombie"] = true,
    ["npc_poisonzombie"] = true,
    ["npc_headcrab"] = true,
    ["npc_sniper"] = true,
    ["npc_strider"] = true,
    ["npc_headcrab_fast"] = true,
    ["npc_headcrab_black"] = true,
    ["npc_manhack"] = true,
    ["npc_cscanner"] = true,
    ["npc_clawscanner"] = true,
    ["npc_helicopter"] = true,
    ["npc_combinedropship"] = true,
    ["npc_combinegunship"] = true
}

GAMETYPE.DefaultGlobalState = {
    ["gordon_precriminal"] = GLOBAL_OFF,
    ["gordon_invulnerable"] = GLOBAL_OFF,
    ["antlion_allied"] = GLOBAL_OFF,
    ["super_phys_gun"] = GLOBAL_OFF,
    ["friendly_encounter"] = GLOBAL_OFF
}

GAMETYPE.ImportantPlayerNPCClasses = {
    ["npc_alyx"] = true,
    ["npc_barney"] = true,
    ["npc_odessa"] = true,
    ["npc_kleiner"] = true,
    ["npc_dog"] = true,
    ["npc_eli"] = true,
    ["npc_mossman"] = true,
    ["npc_monk"] = true,
    ["npc_breen"] = true
}

GAMETYPE.CampaignNames = {
    ["POINT INSERTION"] = {
        s = 1,
        e = 4
    },
    ["A RED LETTER DAY"] = {
        s = 5,
        e = 6
    },
    ["ROUTE KANAL"] = {
        s = 7,
        e = 11
    },
    ["WATER HAZARD"] = {
        s = 12,
        e = 19
    },
    ["BLACK MESA EAST"] = {
        s = 20,
        e = 21
    },
    ["WE DON'T GO TO RAVENHOLM"] = {
        s = 22,
        e = 29
    },
    ["HIGHWAY 17"] = {
        s = 30,
        e = 36
    },
    ["SANDTRAPS"] = {
        s = 37,
        e = 41
    },
    ["NOVA PROSPEKT"] = {
        s = 42,
        e = 45
    },
    ["ENTANGLEMENT"] = {
        s = 46,
        e = 49
    },
    ["ANTICITIZEN ONE"] = {
        s = 50,
        e = 57
    },
    ["FOLLOW FREEMAN!"] = {
        s = 58,
        e = 64
    },
    ["OUR BENEFACTORS"] = {
        s = 65,
        e = 69
    },
    ["DARK ENERGY"] = {
        s = 70,
        e = 70
    }
}

GAMETYPE.Settings = {}
function GAMETYPE:GetPlayerRespawnTime()
    local timeout = math.Clamp(GAMEMODE:GetSetting("max_respawn_timeout"), 0, 255)
    local alive = #team.GetPlayers(LAMBDA_TEAM_ALIVE)
    local total = player.GetCount() - 1
    if total <= 0 then total = 1 end
    local timeoutAmount = math.Round(alive / total * timeout)
    return timeoutAmount
end

function GAMETYPE:CheckpointEnablesRespawn()
    return GAMEMODE:GetSetting("checkpoint_respawn")
end

function GAMETYPE:ShouldRestartRound()
    local playerCount = 0
    local aliveCount = 0
    -- Collect how many players exist and how many are alive, in case they are all dead
    -- we have to restart the round.
    for _, ply in pairs(player.GetAll()) do
        if ply:Alive() then aliveCount = aliveCount + 1 end
        playerCount = playerCount + 1
    end

    if playerCount > 0 and aliveCount == 0 then
        DbgPrint("All players are dead, restart required")
        return true
    end
    return false
end

function GAMETYPE:PlayerCanPickupWeapon(ply, wep)
    if wep:IsFlagSet(FL_DISSOLVING) then -- Do not let player E pick a dissolving weapon.
        return false
    end

    local class = wep:GetClass()
    if class == "weapon_frag" then
        if ply:HasWeapon(class) and ply:GetAmmoCount("grenade") >= sk_max_grenade:GetInt() then return false end
    elseif class == "weapon_annabelle" then
        return false -- Not supposed to have this.
    end

    if ply:HasWeapon(wep:GetClass()) == true then
        -- Only allow a new pickup once if there is ammo in the weapon.
        if wep:GetPrimaryAmmoType() == -1 and wep:GetSecondaryAmmoType() == -1 then return false end
        return ply.ObjectPickupTable[wep.UniqueEntityId] ~= true
    end
    return true
end

function GAMETYPE:PlayerCanPickupItem(ply, item)
    return true
end

function GAMETYPE:GetWeaponRespawnTime()
    return 0.5
end

function GAMETYPE:GetItemRespawnTime()
    return 0.5
end

function GAMETYPE:ShouldRespawnWeapon(ent)
    if ent:IsItem() == true or ent.DroppedByPlayerDeath == true then return false end
    if ent.ShouldRespawnWeapon ~= nil and ent:ShouldRespawnWeapon() == false then return false end
    return true
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
    local playerAttacking = (IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer())
    -- Friendly fire is controlled by convar in this case.
    if playerAttacking == true and GAMEMODE:GetSetting("friendlyfire") == false then return false end
    return true
end

function GAMETYPE:CanPlayerSpawn(ply, spawn)
    return true
end

function GAMETYPE:ShouldRespawnItem(ent)
    return false
end

function GAMETYPE:PlayerSelectSpawn(spawns)
    for k, v in pairs(spawns) do
        if v.MasterSpawn == true then return v end
    end

    for k, v in pairs(spawns) do
        if v:HasSpawnFlags(1) == true then return v end
    end
    return spawns[1]
end

function GAMETYPE:GetPlayerLoadout()
    return self.MapScript.DefaultLoadout or {
        Weapons = {},
        Ammo = {},
        Armor = 0,
        HEV = true
    }
end

function GAMETYPE:LoadCurrentMapScript()
    self.Base.LoadMapScript(self, "lambda/gamemode/gametypes/hl2", game.GetMap():lower())
end

function GAMETYPE:LoadLocalisation(lang, gmodLang)
end

function GAMETYPE:AllowPlayerTracking()
    return GAMEMODE:GetSetting("player_tracker")
end

function GAMETYPE:InitSettings()
    self.Base:InitSettings()
    GAMEMODE:AddSetting("dynamic_checkpoints", {
        Category = "SERVER",
        NiceName = "#GM_DYNCHECKPOINT",
        Description = "#GM_DYNCHECKPOINT_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("allow_npcdmg", {
        Category = "SERVER",
        NiceName = "#GM_NPCDMG",
        Description = "#GM_NPCDMG_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("player_tracker", {
        Category = "SERVER",
        NiceName = "#GM_PLYTRACK",
        Description = "#GM_PLYTRACK_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("friendly_antlion_collision", {
        Category = "SERVER",
        NiceName = "#GM_ANTLIONCOLLISION",
        Description = "#GM_ANTLIONCOLLISION_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("player_speech", {
        Category = "SERVER",
        NiceName = "#GM_PLAYERSPEECH",
        Description = "#GM_PLAYERSPEECH_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("player_damage_speech", {
        Category = "SERVER",
        NiceName = "#GM_PLAYERHURTSOUNDS",
        Description = "#GM_PLAYERHURTSOUNDS_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })
end

function GAMETYPE:GetCampaignName(map)
    local curMap = GAMEMODE:GetCurrentMap()
    local n = GAMEMODE:GetMapIndex(GAMEMODE:GetPreviousMap(), curMap)
    for k, v in pairs(self.CampaignNames) do
        if n >= v.s and n <= v.e then return k end
    end
end

function GAMETYPE:GetScoreboardInfo()
    local scoreboardInfo = {
        {
            name = "LAMBDA_Map",
            value = game.GetMap()
        }
    }

    local campaign = self:GetCampaignName(GAMEMODE:GetCurrentMap())
    if campaign ~= nil then
        table.insert(scoreboardInfo, {
            name = "LAMBDA_Chapter",
            value = campaign
        })
    end
    return scoreboardInfo
end

hook.Add("LambdaLoadGameTypes", "HL2GameType", function(gametypes)
    --
    gametypes:Add("hl2", GAMETYPE)
end)