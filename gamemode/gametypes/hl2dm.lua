if SERVER then AddCSLuaFile() end
local GAMETYPE = {}
GAMETYPE.Name = "Half-Life 2 Deathmatch"
GAMETYPE.BaseGameType = "lambda_base"
GAMETYPE.MapScript = {}
GAMETYPE.UsingCheckpoints = false
GAMETYPE.PlayerSpawnClass = "info_player_deathmatch"
GAMETYPE.PlayerTiming = false
GAMETYPE.WaitForPlayers = false
GAMETYPE.Settings = {}
GAMETYPE.MapList = {"dm_lockdown", "dm_overwatch", "dm_steamlab", "dm_underpass", "dm_resistance", "dm_powerhouse", "dm_runoff", "halls3"}
GAMETYPE.ClassesEnemyNPC = {}
GAMETYPE.ImportantPlayerNPCNames = {}
GAMETYPE.ImportantPlayerNPCClasses = {}
GAMETYPE.PostRoundMapVote = true
function GAMETYPE:GetPlayerRespawnTime()
    local timeout = 2
    return timeout
end

function GAMETYPE:CheckpointEnablesRespawn()
    return false
end

function GAMETYPE:IsTeamOnly()
end

function GAMETYPE:GetFragLimit()
    return GAMEMODE:GetSetting("dm_fraglimit")
end

function GAMETYPE:GetTimeLimit()
    return GAMEMODE:GetSetting("dm_timelimit") * 60
end

function GAMETYPE:GetAllFrags()
    local f = 0
    for k, v in pairs(player.GetAll()) do
        f = f + v:Frags()
    end
    return f
end

function GAMETYPE:ShouldRestartRound(roundTime)
    return false
end

function GAMETYPE:ShouldEndRound(roundTime)
    if roundTime >= self:GetTimeLimit() then return true end
    for _, ply in pairs(player.GetAll()) do
        if ply:Frags() >= self:GetFragLimit() then return true end
    end
    return false
end

function GAMETYPE:PlayerDeath(ply, inflictor, attacker)
    ply:AddDeaths(1)
    -- Suicide?
    if inflictor == ply or attacker == ply then
        attacker:AddFrags(-1)
        return
    end

    if IsValid(attacker) and attacker:IsPlayer() then
        attacker:AddFrags(1)
    elseif IsValid(inflictor) and inflictor:IsPlayer() then
        inflictor:AddFrags(1)
    end
end

function GAMETYPE:PlayerShouldTakeDamage(ply, attacker, inflictor)
    -- TODO: In case of TDM we need to check the team.
    return true
end

function GAMETYPE:GetPlayerLoadout()
    return {
        Weapons = {"weapon_crowbar", "weapon_physcannon", "weapon_smg1", "weapon_pistol"},
        Ammo = {
            ["Pistol"] = 20,
            ["SMG1"] = 60
        },
        Armor = 0,
        HEV = true
    }
end

function GAMETYPE:LoadCurrentMapScript()
    self.MapScript = {}
end

function GAMETYPE:GetWeaponRespawnTime()
    -- ConVar sv_hl2mp_weapon_respawn_time( "sv_hl2mp_weapon_respawn_time", "20", FCVAR_GAMEDLL | FCVAR_NOTIFY );
    return 20
end

function GAMETYPE:GetItemRespawnTime()
    -- ConVar sv_hl2mp_item_respawn_time( "sv_hl2mp_item_respawn_time", "30", FCVAR_GAMEDLL | FCVAR_NOTIFY );
    return 30
end

function GAMETYPE:ShouldRespawnWeapon(ent)
    local SF_NORESPAWN = 1073741824 -- (1 << 30)
    if GAMEMODE:IsLevelDesignerPlacedObject(ent) == false and ent:HasSpawnFlags(SF_NORESPAWN) ~= true then return false end
    return true
end

function GAMETYPE:ShouldRespawnItem(ent)
    local SF_NORESPAWN = 1073741824 -- (1 << 30)
    if GAMEMODE:IsLevelDesignerPlacedObject(ent) == false and ent:HasSpawnFlags(SF_NORESPAWN) ~= true then return false end
    return true
end

function GAMETYPE:PlayerCanPickupWeapon(ply, wep)
    return true
end

function GAMETYPE:PlayerCanPickupItem(ply, item)
    return true
end

function GAMETYPE:CanPlayerSpawn(ply, spawn)
    local pos = spawn:GetPos()
    local tr = util.TraceHull({
        start = pos,
        endpos = pos + Vector(0, 0, 1),
        mins = HULL_HUMAN_MINS,
        maxs = HULL_HUMAN_MAXS,
        mask = MASK_SOLID,
        filter = ply
    })
    return tr.Fraction == 1.0
end

function GAMETYPE:PlayerSelectSpawn(spawns)
    return table.Random(spawns)
end

function GAMETYPE:AllowPlayerTracking()
    return false
end

function GAMETYPE:IsPlayerEnemy(ply1, ply2)
    -- TODO: TDM
    return true
end

function GAMETYPE:GetDifficultyData()
    return {
        [0] = {
            Name = "Default",
            Proficiency = WEAPON_PROFICIENCY_GOOD,
            Skill = 1,
            NPCSpawningScale = 0.0,
            DamageScale = {
                [DMG_SCALE_PVN] = 1,
                [DMG_SCALE_NVP] = 1,
                [DMG_SCALE_PVP] = 1.75,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 2.75,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 1,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            }
        }
    }
end

function GAMETYPE:InitSettings()
    self.Base:InitSettings()
    GAMEMODE:AddSetting("dm_fraglimit", {
        Category = "SERVER",
        NiceName = "#GM_DM_FRAGLIMIT",
        Description = "#GM_DM_FRAGLIMIT_DESC",
        Type = "int",
        Value = 50,
        Flags = bit.bor(0, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 1000
        }
    })

    GAMEMODE:AddSetting("dm_timelimit", {
        Category = "SERVER",
        NiceName = "#GM_DM_TIMELIMIT",
        Description = "#GM_DM_TIMELIMIT_DESC",
        Type = "int",
        Value = 10,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 30
        }
    })

    GAMEMODE:AddSetting("dm_teamonly", {
        Category = "SERVER",
        NiceName = "#GM_DM_TEAMONLY",
        Description = "#GM_DM_TEAMONLY_DESC",
        Type = "bool",
        Value = 0,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })
end

function GAMETYPE:GetScoreboardInfo()
    local timeElapsed = GAMEMODE:RoundElapsedTime()
    local timeLimit = self:GetTimeLimit()
    local timeLeft = timeLimit - timeElapsed
    if timeLeft < 0 then timeLeft = 0 end
    local fragsleft = self:GetFragLimit() - self:GetAllFrags()
    local scoreboardInfo = {
        {
            name = "LAMBDA_Map",
            value = game.GetMap()
        },
        {
            name = "LAMBDA_Timeleft",
            value = string.NiceTime(timeLeft)
        },
        {
            name = "LAMBDA_Frags",
            value = fragsleft
        }
    }
    return scoreboardInfo
end

hook.Add("LambdaLoadGameTypes", "HL2DMGameType", function(gametypes)
    --
    gametypes:Add("hl2dm", GAMETYPE)
end)