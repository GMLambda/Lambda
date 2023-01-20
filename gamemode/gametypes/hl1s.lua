if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("GameType")
local GAMETYPE = {}
GAMETYPE.Name = "Half-Life 1: Source"
GAMETYPE.BaseGameType = "lambda_base"
GAMETYPE.MapScript = {}
GAMETYPE.PlayerSpawnClass = "info_player_start"
GAMETYPE.UsingCheckpoints = true
GAMETYPE.WaitForPlayers = true
GAMETYPE.MapList = {"c0a0", "c0a0a", "c0a0b", "c0a0c", "c0a0d", "c0a0e", "c1a0", "c1a0d", "c1a0a", "c1a0b", "c1a0e", "c1a1a", "c1a1f", "c1a1b", "c1a1c", "c1a1d", "c1a2", "c1a2a", "c1a2b", "c1a2c", "c1a2d", "c1a3", "c1a3a", "c1a3b", "c1a3c", "c1a3d", "c1a4", "c1a4k", "c1a4b", "c1a4f", "c1a4d", "c1a4e", "c1a4i", "c1a4g", "c1a4j", "c2a1", "c2a1a", "c2a1b", "c2a2", "c2a2a", "c2a2b1", "c2a2b2", "c2a2c", "c2a2d", "c2a2e", "c2a2f", "c2a2g", "c2a2h", "c2a3", "c2a3a", "c2a3b", "c2a3c", "c2a3d", "c2a3e", "c2a4", "c2a4a", "c2a4b", "c2a4c", "c2a4d", "c2a4e", "c2a4f", "c2a4g", "c2a5", "c2a5w", "c2a5x", "c2a5a", "c2a5b", "c2a5c", "c2a5d", "c2a5e", "c2a5f", "c2a5g", "c3a1", "c3a1a", "c3a1b", "c3a2e", "c3a2", "c3a2a", "c3a2b", "c3a2c", "c3a2d", "c3a2f", "c4a1", "c4a2", "c4a2a", "c4a2b", "c4a1a", "c4a1b", "c4a1c", "c4a1d", "c4a1e", "c4a1f", "c4a3", "c5a1"}
GAMETYPE.ClassesEnemyNPC = {}
GAMETYPE.ImportantPlayerNPCNames = {}
GAMETYPE.ImportantPlayerNPCClasses = {}

function GAMETYPE:GetPlayerRespawnTime()
    local timeout = math.Clamp(GAMEMODE:GetSetting("max_respawn_timeout"), -1, 255)
    if timeout == -1 then return timeout end
    local alive = #team.GetPlayers(LAMBDA_TEAM_ALIVE)
    local total = player.GetCount() - 1

    if total <= 0 then
        total = 1
    end

    local timeoutAmount = math.Round(alive / total * timeout)

    return timeoutAmount
end

function GAMETYPE:ShouldRestartRound()
    local playerCount = 0
    local aliveCount = 0

    -- Collect how many players exist and how many are alive, in case they are all dead
    -- we have to restart the round.
    for _, ply in pairs(player.GetAll()) do
        if ply:Alive() then
            aliveCount = aliveCount + 1
        end

        playerCount = playerCount + 1
    end

    if playerCount > 0 and aliveCount == 0 then
        DbgPrint("All players are dead, restart required")

        return true
    end

    return false
end

function GAMETYPE:PlayerCanPickupWeapon(ply, wep)
    local class = wep:GetClass()

    if class == "weapon_frag" then
        if ply:HasWeapon(class) and ply:GetAmmoCount("grenade") >= sk_max_grenade:GetInt() then return false end
    elseif class == "weapon_annabelle" then
        return false -- Not supposed to have this.
    end

    if ply:HasWeapon(wep:GetClass()) == true then
        -- Only allow a new pickup once if there is ammo in the weapon.
        if wep:GetPrimaryAmmoType() == -1 and wep:GetSecondaryAmmoType() == -2 then return false end

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
    return -1
end

function GAMETYPE:ShouldRespawnWeapon(ent)
    if ent:IsItem() == true or ent.DroppedByPlayerDeath == true then return false end

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
    if playerAttacking == true and lambda_friendlyfire:GetBool() == false then return false end

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
        Weapons = {"weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow", "weapon_bugbait"},
        Ammo = {
            ["Pistol"] = 20,
            ["SMG1"] = 45,
            ["357"] = 6,
            ["Grenade"] = 3,
            ["Buckshot"] = 12,
            ["AR2"] = 50,
            ["RPG_Round"] = 8,
            ["SMG1_Grenade"] = 3,
            ["XBowBolt"] = 4
        },
        Armor = 60,
        HEV = true
    }
end

function GAMETYPE:LoadCurrentMapScript()
    self.Base.LoadMapScript(self, "lambda/gamemode/gametypes/hl1s", game.GetMap():lower())
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
        Description = "Dynamic checkpoints",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("allow_npcdmg", {
        Category = "SERVER",
        NiceName = "#GM_NPCDMG",
        Description = "Friendly NPC damage",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("player_tracker", {
        Category = "SERVER",
        NiceName = "#GM_PLYTRACK",
        Description = "Player tracking",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })
end

hook.Add("LambdaLoadGameTypes", "HL1SGameType", function(gametypes)
    gametypes:Add("hl1s", GAMETYPE)
end)

if CLIENT then end