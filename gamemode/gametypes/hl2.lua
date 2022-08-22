if SERVER then
    AddCSLuaFile()
end

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
    local timeout = math.Clamp(GAMEMODE:GetSetting("max_respawn_timeout"), -1, 255)
    if timeout == -1 then
        return timeout
    end
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
        Description = "Dynamic checkpoints",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("allow_npcdmg", {
        Category = "SERVER",
        NiceName = "#GM_NPCDMG",
        Description = "Friendly NPC damage",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("player_tracker", {
        Category = "SERVER",
        NiceName = "#GM_PLYTRACK",
        Description = "Player tracking",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("friendly_antlion_collision", {
        Category = "SERVER",
        NiceName = "#GM_ANTLIONCOLLISION",
        Description = "Friendly Antlion collision",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
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
    gametypes:Add("hl2", GAMETYPE)
end)

if CLIENT then
    language.Add("HL2_Chapter1_Title", "POINT INSERTION")
    language.Add("HL2_Chapter2_Title", "\"A RED LETTER DAY\"")
    language.Add("HL2_Chapter3_Title", "ROUTE KANAL")
    language.Add("HL2_Chapter4_Title", "WATER HAZARD")
    language.Add("HL2_Chapter5_Title", "BLACK MESA EAST")
    language.Add("HL2_Chapter6_Title", "\"WE DON'T GO TO RAVENHOLM...\"")
    language.Add("HL2_Chapter7_Title", "HIGHWAY 17")
    language.Add("HL2_Chapter8_Title", "SANDTRAPS")
    language.Add("HL2_Chapter9_Title", "NOVA PROSPEKT")
    language.Add("HL2_Chapter9a_Title", "ENTANGLEMENT")
    language.Add("HL2_Chapter10_Title", "ANTICITIZEN ONE")
    language.Add("HL2_Chapter11_Title", "\"FOLLOW FREEMAN!\"")
    language.Add("HL2_Chapter12_Title", "OUR BENEFACTORS")
    language.Add("HL2_Chapter13_Title", "DARK ENERGY")
    language.Add("HL2_Chapter14_Title", "CREDITS")
    language.Add("hl2_AmmoFull", "FULL")
    language.Add("HL2_GameOver_Object", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: FAILURE TO PRESERVE MISSION-CRITICAL RESOURCES")
    language.Add("HL2_GameOver_Ally", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: FAILURE TO PRESERVE MISSION-CRITICAL PERSONNEL")
    language.Add("HL2_GameOver_Timer", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: FAILURE TO PREVENT TIME-CRITICAL SEQUENCE")
    language.Add("HL2_GameOver_Stuck", "ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: DEMONSTRATION OF EXCEEDINGLY POOR JUDGMENT")
    language.Add("HL2_357Handgun", ".357 MAGNUM")
    language.Add("HL2_Pulse_Rifle", "PULSE-RIFLE")
    language.Add("HL2_Bugbait", "BUGBAIT")
    language.Add("HL2_Crossbow", "CROSSBOW")
    language.Add("HL2_Crowbar", "CROWBAR")
    language.Add("HL2_Grenade", "GRENADE")
    language.Add("HL2_GravityGun", "GRAVITY GUN")
    language.Add("HL2_Pistol", "9MM PISTOL")
    language.Add("HL2_RPG", "RPG")
    language.Add("HL2_Shotgun", "SHOTGUN")
    language.Add("HL2_SMG1", "SMG")
    language.Add("HL2_Saved", "Saved...")
    language.Add("HL2_Credits_VoicesTitle", "Voices:")
    language.Add("HL2_Credits_Eli", "Robert Guillaume - Dr. Eli Vance")
    language.Add("HL2_Credits_Breen", "Robert Culp - Dr. Wallace Breen")
    language.Add("HL2_Credits_Vortigaunt", "Lou Gossett, Jr. - Vortigaunt")
    language.Add("HL2_Credits_Mossman", "Michelle Forbes - Dr. Judith Mossman")
    language.Add("HL2_Credits_Alyx", "Merle Dandridge - Alyx Vance")
    language.Add("HL2_Credits_Barney", "Mike Shapiro - Barney Calhoun")
    language.Add("HL2_Credits_Gman", "Mike Shapiro - Gman")
    language.Add("HL2_Credits_Kleiner", "Harry S. Robins - Dr. Isaac Kleiner")
    language.Add("HL2_Credits_Grigori", "Jim French - Father Grigori")
    language.Add("HL2_Credits_Misc1", "John Patrick Lowrie - Citizens\\Misc. characters")
    language.Add("HL2_Credits_Misc2", "Mary Kae Irvin - Citizens\\Misc. characters")
    language.Add("HL2_Credits_Overwatch", "Ellen McLain - Overwatch")
    language.Add("HL2_Credits_VoiceCastingTitle", "Voice Casting:")
    language.Add("HL2_Credits_VoiceCastingText", "Shana Landsburg\\Teri Fiddleman")
    language.Add("HL2_Credits_VoiceRecordingTitle", "Voice Recording:")
    language.Add("HL2_Credits_VoiceRecordingText1", "Pure Audio, Seattle, WA")
    language.Add("HL2_Credits_VoiceRecordingText2", "LA Studios, LA, CA")
    language.Add("HL2_Credits_VoiceSchedulingTitle", "Voice recording scheduling and logistics:")
    language.Add("HL2_Credits_VoiceSchedulingText", "Pat Cockburn, Pure Audio")
    language.Add("HL2_Credits_LegalTeam", "Crack Legal Team:")
    language.Add("HL2_Credits_FacesThanks", "Thanks to the following for the use of their faces:")
    language.Add("HL2_Credits_SpecialThanks", "Special thanks to everyone at:")
    language.Add("HL2_HIT_CANCOP_WITHCAN_NAME", "Defiant")
    language.Add("HL2_HIT_CANCOP_WITHCAN_DESC", "Hit the trashcan cop with the can.")
    language.Add("HL2_PUT_CANINTRASH_NAME", "Submissive")
    language.Add("HL2_PUT_CANINTRASH_DESC", "Put the can in the trash.")
    language.Add("HL2_ESCAPE_APARTMENTRAID_NAME", "Malcontent")
    language.Add("HL2_ESCAPE_APARTMENTRAID_DESC", "Escape the apartment block raid.")
    language.Add("HL2_BREAK_MINITELEPORTER_NAME", "What cat?")
    language.Add("HL2_BREAK_MINITELEPORTER_DESC", "Break the mini-teleporter in Kleiner's lab.")
    language.Add("HL2_GET_CROWBAR_NAME", "Trusty Hardware")
    language.Add("HL2_GET_CROWBAR_DESC", "Get the crowbar.")
    language.Add("HL2_KILL_BARNACLESWITHBARREL_NAME", "Barnacle Bowling")
    language.Add("HL2_KILL_BARNACLESWITHBARREL_DESC", "Kill five barnacles with one barrel.")
    language.Add("HL2_GET_AIRBOAT_NAME", "Anchor's Aweigh!")
    language.Add("HL2_GET_AIRBOAT_DESC", "Get the airboat.")
    language.Add("HL2_FLOAT_WITHAIRBOAT_NAME", "Catching Air")
    language.Add("HL2_FLOAT_WITHAIRBOAT_DESC", "Float five seconds in the air with the airboat.")
    language.Add("HL2_GET_AIRBOATGUN_NAME", "Heavy Weapons")
    language.Add("HL2_GET_AIRBOATGUN_DESC", "Get the airboat's mounted gun.")
    language.Add("HL2_FIND_VORTIGAUNTCAVE_NAME", "Vorticough")
    language.Add("HL2_FIND_VORTIGAUNTCAVE_DESC", "Discover the hidden singing vortigaunt cave in chapter Water Hazard.")
    language.Add("HL2_KILL_CHOPPER_NAME", "Revenge!")
    language.Add("HL2_KILL_CHOPPER_DESC", "Destroy the hunter-chopper in Half-Life 2.")
    language.Add("HL2_FIND_HEVFACEPLATE_NAME", "Blast from the Past")
    language.Add("HL2_FIND_HEVFACEPLATE_DESC", "Find the HEV Suit Charger faceplate in Eli's scrapyard.")
    language.Add("HL2_GET_GRAVITYGUN_NAME", "Zero-Point Energy")
    language.Add("HL2_GET_GRAVITYGUN_DESC", "Get the Gravity Gun in Black Mesa East.")
    language.Add("HL2_MAKEABASKET_NAME", "Two Points")
    language.Add("HL2_MAKEABASKET_DESC", "Use DOG's ball to make a basket in Eli's scrapyard.")
    language.Add("HL2_BEAT_RAVENHOLM_NOWEAPONS_NAME", "Zombie Chopper")
    language.Add("HL2_BEAT_RAVENHOLM_NOWEAPONS_DESC", "Play through Ravenholm using only the Gravity Gun.")
    language.Add("HL2_BEAT_CEMETERY_NAME", "Hallowed Ground")
    language.Add("HL2_BEAT_CEMETERY_DESC", "Escort Grigori safely through the church cemetery.")
    language.Add("HL2_KILL_ENEMIES_WITHCRANE_NAME", "OSHA Violation")
    language.Add("HL2_KILL_ENEMIES_WITHCRANE_DESC", "Kill 3 enemies using the crane.")
    language.Add("HL2_PIN_SOLDIER_TOBILLBOARD_NAME", "Targetted Advertising")
    language.Add("HL2_PIN_SOLDIER_TOBILLBOARD_DESC", "Pin a soldier to the billboard in chapter Highway 17.")
    language.Add("HL2_KILL_ODESSAGUNSHIP_NAME", "Where Cubbage Fears to Tread")
    language.Add("HL2_KILL_ODESSAGUNSHIP_DESC", "Defend Little Odessa from the gunship attack.")
    language.Add("HL2_KILL_THREEGUNSHIPS_NAME", "One Man Army")
    language.Add("HL2_KILL_THREEGUNSHIPS_DESC", "Destroy six gunships in Half-Life 2.")
    language.Add("HL2_BEAT_DONTTOUCHSAND_NAME", "Keep Off the Sand!")
    language.Add("HL2_BEAT_DONTTOUCHSAND_DESC", "Cross the antlion beach in chapter Sandtraps without touching the sand.")
    language.Add("HL2_KILL_BOTHPRISONGUNSHIPS_NAME", "Uninvited Guest")
    language.Add("HL2_KILL_BOTHPRISONGUNSHIPS_DESC", "Kill both gunships in the Nova Prospekt courtyard.")
    language.Add("HL2_KILL_ENEMIES_WITHANTLIONS_NAME", "Bug Hunt")
    language.Add("HL2_KILL_ENEMIES_WITHANTLIONS_DESC", "Use the antlions to kill 50 enemies.")
    language.Add("HL2_KILL_ENEMY_WITHTOILET_NAME", "Flushed")
    language.Add("HL2_KILL_ENEMY_WITHTOILET_DESC", "Kill an enemy with a toilet.")
    language.Add("HL2_BEAT_TURRETSTANDOFF2_NAME", "Warden Freeman")
    language.Add("HL2_BEAT_TURRETSTANDOFF2_DESC", "Survive the second turret standoff in Nova Prospekt.")
    language.Add("HL2_FOLLOWFREEMAN_NAME", "Follow Freeman")
    language.Add("HL2_FOLLOWFREEMAN_DESC", "Gain command of a squad of rebels in the uprising.")
    language.Add("HL2_BEAT_TOXICTUNNEL_NAME", "Radiation Levels Detected")
    language.Add("HL2_BEAT_TOXICTUNNEL_DESC", "Get through the toxic tunnel under City 17 in Half-Life 2.")
    language.Add("HL2_BEAT_PLAZASTANDOFF_NAME", "Plaza Defender")
    language.Add("HL2_BEAT_PLAZASTANDOFF_DESC", "Survive the generator plaza standoff in chapter Anticitizen One.")
    language.Add("HL2_KILL_ALLC1709SNIPERS_NAME", "Counter-Sniper")
    language.Add("HL2_KILL_ALLC1709SNIPERS_DESC", "Kill all of the snipers in City 17.")
    language.Add("HL2_BEAT_SUPRESSIONDEVICE_NAME", "Fight the Power")
    language.Add("HL2_BEAT_SUPRESSIONDEVICE_DESC", "Shut down the supression device by disabling its generators.")
    language.Add("HL2_BEAT_C1713STRIDERSTANDOFF_NAME", "Giant Killer")
    language.Add("HL2_BEAT_C1713STRIDERSTANDOFF_DESC", "Survive the rooftop strider battle in the ruins of City 17.")
    language.Add("HL2_DISINTEGRATE_SOLDIERSINFIELD_NAME", "Atomizer")
    language.Add("HL2_DISINTEGRATE_SOLDIERSINFIELD_DESC", "Disintegrate 15 soldiers by throwing them into a Combine ball field.")
    language.Add("HL2_BEAT_GAME_NAME", "Singularity Collapse")
    language.Add("HL2_BEAT_GAME_DESC", "Destroy the Citadel's reactor core.")
    language.Add("HL2_FIND_ALLLAMBDAS_NAME", "Lambda Locator")
    language.Add("HL2_FIND_ALLLAMBDAS_DESC", "Find all lambda caches in Half-Life 2.")
    language.Add("World", "Cruel World")
    language.Add("base_ai", "Creature")
end