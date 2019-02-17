if SERVER then
    AddCSLuaFile()
end

local GAMETYPE = {}

GAMETYPE.Name = "Half-Life 2: Episode 1"
GAMETYPE.BaseGameType = "hl2"
GAMETYPE.MapScript = {}
GAMETYPE.MapList =
{
    "ep1_citadel_00",
    "ep1_citadel_01",
    "ep1_citadel_02",
    "ep1_citadel_02b",
    "ep1_citadel_03",
    "ep1_citadel_04",
    "ep1_c17_00",
    "ep1_c17_00a",
    "ep1_c17_01",
    "ep1_c17_02",
    "ep1_c17_02b",
    "ep1_c17_02a",
    "ep1_c17_05",
    "ep1_c17_06",
}

GAMETYPE.CampaignNames = {
    ["UNDUE ALARM"] = {
        s = 1,
        e = 4
    },
    ["DIRECT INTERVENTION"] = {
        s = 5,
        e = 6
    },
    ["LOWLIFE"] = {
        s = 7,
        e = 8
    },
    ["URBAN FLIGHT"] = {
        s = 9,
        e = 13
    },
    ["EXIT 17"] = {
        s = 14,
        e = 15
    }
}

function GAMETYPE:InitSettings()
    self.Base:InitSettings()
end

function GAMETYPE:LoadCurrentMapScript()
    self.Base.LoadMapScript(self, "hl2ep1", game.GetMap():lower())
end

function GAMETYPE:GetPlayerLoadout()
    return self.MapScript.DefaultLoadout
end

hook.Add("LambdaLoadGameTypes", "HL2EP1GameType", function(gametypes)
    gametypes:Add("hl2ep1", GAMETYPE)
end)

if CLIENT then
    language.Add("episodic_Chapter1_Title", "Undue Alarm")
    language.Add("episodic_Chapter2_Title", "Direct Intervention")
    language.Add("episodic_Chapter4_Title", "Urban Flight")
    language.Add("episodic_Chapter3_Title", "Lowlife")
    language.Add("episodic_Chapter5_Title", "Exit 17")
    language.Add("episodic_Chapter6_Title", "Coming Soon")

    language.Add("mod_episodic_Chapter1_Title", "Undue Alarm")
    language.Add("mod_episodic_Chapter2_Title", "Direct Intervention")
    language.Add("mod_episodic_Chapter4_Title", "Urban Flight")
    language.Add("mod_episodic_Chapter3_Title", "Lowlife")
    language.Add("mod_episodic_Chapter5_Title", "Exit 17")
    language.Add("mod_episodic_Chapter6_Title", "Coming Soon")

    language.Add("halflife-vr-ep1_Chapter1_Title", "Undue Alarm")
    language.Add("halflife-vr-ep1_Chapter2_Title", "Direct Intervention")
    language.Add("halflife-vr-ep1_Chapter4_Title", "Urban Flight")
    language.Add("halflife-vr-ep1_Chapter3_Title", "Lowlife")
    language.Add("halflife-vr-ep1_Chapter5_Title", "Exit 17")
    language.Add("halflife-vr-ep1_Chapter6_Title", "Coming Soon")

    language.Add("HL2_GameOver_Object","IT ENDS HERE\nTHE FREEMAN HAS FAILED TO PRESERVE RESOURCES\nDEEMED CRITICAL TO VICTORY\nINESCAPABLE GLIMPSES OF DOOM CLOUD THE VORTESSENCE")
    language.Add("HL2_GameOver_Ally","SO IT ENDS\nTHE FREEMAN HAS FAILED TO PRESERVE A LIFE REQUIRED FOR VICTORY\nSUCH ARE THE SHAPES WE SEE IN THE VORTESSENCE")
    language.Add("HL2_GameOver_Timer","ALL IS DONE\nTHE FREEMAN'S FAILURE TO SEIZE A SWIFT VICTORY\nLEADS TO OUR TOTAL DEFEAT")
    language.Add("HL2_GameOver_Stuck","ASSIGNMENT: TERMINATED\nSUBJECT: FREEMAN\nREASON: DEMONSTRATION OF EXCEEDINGLY POOR JUDGMENT")
    language.Add("Episodic_GameOver_AlyxDead", "THE ALYX VANCE HAS DIED\nWITHOUT HER WE CANNOT PERSEVERE")

    language.Add("HL2_357Handgun", ".357 MAGNUM")
    language.Add("HL2_Pulse_Rifle", "OVERWATCH STANDARD ISSUE\n(PULSE-RIFLE)")
    language.Add("HL2_Bugbait", "PHEROPOD\n(BUGBAIT)")
    language.Add("HL2_Crossbow", "CROSSBOW")
    language.Add("HL2_Crowbar", "CROWBAR")
    language.Add("HL2_Grenade", "GRENADE")
    language.Add("HL2_GravityGun", "ZERO-POINT ENERGY GUN\n(GRAVITY GUN)")
    language.Add("HL2_Pistol", "9MM PISTOL")
    language.Add("HL2_RPG", "RPG\n(ROCKET PROPELLED GRENADE)")
    language.Add("HL2_Shotgun", "SHOTGUN")
    language.Add("HL2_SMG1", "SMG\n(SUBMACHINE GUN)")
    language.Add("HL2_Saved", "Saved...")
    language.Add("HL2_Enable_Commentary", "Enable commentary track")

    language.Add("Valve_Hint_EnterVan", "%+use% ENTER VAN")
    language.Add("Valve_Hint_ExitVan", "%+use% EXIT VAN")

    language.Add("Valve_Hint_Crouch", "%+duck% CROUCH")
    language.Add("Valve_Hint_Sprint", "%+speed% SPRINT")
    language.Add("Valve_Hint_PushButton", "%+use% PUSH BUTTON")
    language.Add("Valve_Hint_PicKUp", "%+use% PICK UP")
    language.Add("Valve_Hint_Interact", "%+use% INTERACT")
    language.Add("Valve_Hint_GravGun", "%+attack% PUNT OBJECT %+attack2% PULL OBJECT")
    language.Add("Valve_Hint_CarryTurret", "%+use% OR GRAVITY GUN TO PICK UP TURRET")
    language.Add("Valve_Hint_CROSSBOW", "%+attack2% CROSSBOW ZOOM")

    language.Add("HL2_Credits_VoicesTitle", "Voices:")
    language.Add("HL2_Credits_Eli","Robert Guillaume - Dr. Eli Vance")
    language.Add("HL2_Credits_Breen","Robert Culp - Dr. Wallace Breen")
    language.Add("HL2_Credits_Vortigaunt", "Lou Gossett, Jr. - Vortigaunt")
    language.Add("HL2_Credits_Mossman","Michelle Forbes - Dr. Judith Mossman")
    language.Add("HL2_Credits_Alyx","Merle Dandridge - Alyx Vance")
    language.Add("HL2_Credits_Barney","Mike Shapiro - Barney Calhoun")
    language.Add("HL2_Credits_Gman","Mike Shapiro - Gman")
    language.Add("HL2_Credits_Kleiner","Harry S. Robins - Dr. Isaac Kleiner")
    language.Add("HL2_Credits_Grigori","Jim French - Father Grigori")
    language.Add("HL2_Credits_Misc1", "John Patrick Lowrie - Citizens\nMisc. characters")
    language.Add("HL2_Credits_Misc2","Mary Kae Irvin - Citizens\nMisc. characters")
    language.Add("HL2_Credits_Overwatch","Ellen McLain - Overwatch")
    language.Add("HL2_Credits_VoiceCastingTitle", "Voice Casting:")
    language.Add("HL2_Credits_VoiceCastingText", "Shana Landsburg\nTeri Fiddleman")
    language.Add("HL2_Credits_VoiceRecordingTitle", "Voice Recording:")
    language.Add("HL2_Credits_VoiceRecordingText1", "Pure Audio, Seattle, WA")
    language.Add("HL2_Credits_VoiceRecordingText2", "LA Studios, LA, CA")
    language.Add("HL2_Credits_VoiceSchedulingTitle", "Voice recording scheduling and logistics:")
    language.Add("HL2_Credits_VoiceSchedulingText", "Pat Cockburn, Pure Audio")
    language.Add("HL2_Credits_LegalTeam","Crack Legal Team:")
    language.Add("HL2_Credits_FacesThanks", "Thanks to the following for the use of their faces:")
    language.Add("HL2_Credits_SpecialThanks", "Special thanks to everyone at:")

    language.Add("EP1_BEAT_MAINELEVATOR_NAME", "Watch Your Head!")
    language.Add("EP1_BEAT_MAINELEVATOR_DESC", "Make it to the bottom of the Citadel's main elevator shaft in one piece.")
    language.Add("EP1_BEAT_CITADELCORE_NAME", "Containment")
    language.Add("EP1_BEAT_CITADELCORE_DESC", "Contain the Citadel core.")
    language.Add("EP1_BEAT_CITADELCORE_NOSTALKERKILLS_NAME", "Pacifist")
    language.Add("EP1_BEAT_CITADELCORE_NOSTALKERKILLS_DESC", "Contain the Citadel core without killing any stalkers.")
    language.Add("EP1_KILL_ANTLIONS_WITHCARS_NAME", "Car Crusher")
    language.Add("EP1_KILL_ANTLIONS_WITHCARS_DESC", "Use the cars to squash 15 antlions in Episode One.")
    language.Add("EP1_BEAT_GARAGEELEVATORSTANDOFF_NAME", "Elevator Action")
    language.Add("EP1_BEAT_GARAGEELEVATORSTANDOFF_DESC", "Survive long enough to get on the parking garage elevator.")
    language.Add("EP1_KILL_ENEMIES_WITHSNIPERALYX_NAME", "Live Bait")
    language.Add("EP1_KILL_ENEMIES_WITHSNIPERALYX_DESC", "Help Alyx snipe 30 enemies in Episode One.")
    language.Add("EP1_BEAT_HOSPITALATTICGUNSHIP_NAME", "Attica!")
    language.Add("EP1_BEAT_HOSPITALATTICGUNSHIP_DESC", "Destroy the gunship in the hospital attic.")
    language.Add("EP1_BEAT_CITIZENESCORT_NOCITIZENDEATHS_NAME", "Citizen Escort")
    language.Add("EP1_BEAT_CITIZENESCORT_NOCITIZENDEATHS_DESC", "Don't let any citizens die when escorting them to the escape train.")
    language.Add("EP1_BEAT_GAME_NAME", "Escape From City 17")
    language.Add("EP1_BEAT_GAME_DESC", "Escape City 17 with Alyx.")
    language.Add("EP1_BEAT_GAME_ONEBULLET_NAME", "The One Free Bullet")
    language.Add("EP1_BEAT_GAME_ONEBULLET_DESC", "Finish the game firing exactly one bullet. Grenade, crowbar, rocket, and Gravity Gun kills are okay!")

    language.Add("World", "Cruel World")
    language.Add("base_ai", "Creature")
end
