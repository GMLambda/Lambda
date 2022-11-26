if SERVER then
    AddCSLuaFile()
end

LAMBDA_TEAM_CONNECTING = 1200
LAMBDA_TEAM_DEAD = 1
LAMBDA_TEAM_ALIVE = 5
LAMBDA_TEAM_SPECTATOR = 3
-- TDM Teams
LAMBDA_TEAM_REBEL = 10
LAMBDA_TEAM_COMBINE = 11

DEATH_BYSELF = 1
DEATH_BYPLAYER = 2
DEATH_NORMAL = 3
DEATH_BYNPC = 4
DEATH_NPC = 5

sk_max_pistol = GetConVar("sk_max_pistol")
sk_max_smg1  = GetConVar("sk_max_smg1")
sk_max_smg1_grenade = GetConVar("sk_max_smg1_grenade")
sk_max_357 = GetConVar("sk_max_357")
sk_max_ar2 = GetConVar("sk_max_ar2")
sk_max_ar2_altfire = GetConVar("sk_max_ar2_altfire")
sk_max_buckshot = GetConVar("sk_max_buckshot")
sk_max_crossbow = GetConVar("sk_max_crossbow")
sk_max_grenade = GetConVar("sk_max_grenade")
sk_max_rpg_round = GetConVar("sk_max_rpg_round")
-- For compatibility reasons we need those ConVars.
sk_max_slam = CreateConVar("sk_max_slam", "3", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "")
sk_plr_dmg_crowbar = CreateConVar("sk_plr_dmg_crowbar", 10, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "")
sk_npc_dmg_crowbar = CreateConVar("sk_npc_dmg_crowbar", 5, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "")
sk_plr_dmg_stunstick = CreateConVar("sk_plr_dmg_stunstick", 10, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "")
sk_npc_dmg_stunstick = CreateConVar("sk_npc_dmg_stunstick", 40, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "")

GM.MAX_AMMO_DEF =
{
    ["Pistol"] = sk_max_pistol,
    ["SMG1"] = sk_max_smg1,
    ["SMG1_Grenade"] = sk_max_smg1_grenade,
    ["357"] = sk_max_357,
    ["AR2"] = sk_max_ar2,
    ["Buckshot"] = sk_max_buckshot,
    ["AR2AltFire"] = sk_max_ar2_altfire,
    ["XBowBolt"] = sk_max_crossbow,
    ["Grenade"] = sk_max_grenade,
    ["RPG_Round"] = sk_max_rpg_round,
    ["slam"] = sk_max_slam,
}

GM.ITEM_DEF =
{
    ["item_ammo_pistol"] = { ["Type"] = "Pistol", ["Max"] = sk_max_pistol, ["1"] = 24, ["2"] = 20, ["3"] = 12 },
    ["item_ammo_pistol_large"] = { ["Type"] = "Pistol", ["Max"] = sk_max_pistol, ["1"] = 120, ["2"] = 100, ["3"] = 60 },
    ["item_ammo_smg1"] = { ["Type"] = "SMG1", ["Max"] = sk_max_smg1, ["1"] = 54, ["2"] = 45, ["3"] = 27 },
    ["item_ammo_smg1_large"] = { ["Type"] = "SMG1", ["Max"] = sk_max_smg1, ["1"] = 225, ["2"] = 225, ["3"] = 135 },
    ["item_ammo_smg1_grenade"] = { ["Type"] = "SMG1_Grenade", ["Max"] = sk_max_smg1_grenade, ["1"] = 1, ["2"] = 1, ["3"] = 1 },
    ["item_ammo_357"] = { ["Type"] = "357", ["Max"] = sk_max_357, ["1"] = 7, ["2"] = 6, ["3"] = 3 },
    ["item_ammo_357_large"] = { ["Type"] = "357", ["Max"] = sk_max_357, ["1"] = 12, ["2"] = 12, ["3"] = 12 },
    ["item_ammo_ar2"] = { ["Type"] = "AR2", ["Max"] = sk_max_ar2, ["1"] = 24, ["2"] = 20, ["3"] = 12 },
    ["item_ammo_ar2_large"] = { ["Type"] = "AR2", ["Max"] = sk_max_ar2, ["1"] = 60, ["2"] = 60, ["3"] = 60 },
    ["item_ammo_ar2_altfire"] = { ["Type"] = "AR2AltFire", ["Max"] = sk_max_ar2_altfire, ["1"] = 1, ["2"] = 1, ["3"] = 1 },
    ["item_box_buckshot"] = { ["Type"] = "Buckshot", ["Max"] = sk_max_buckshot, ["1"] = 24, ["2"] = 20, ["3"] = 12 },
    ["item_ammo_crossbow"] = { ["Type"] = "XBowBolt", ["Max"] = sk_max_crossbow, ["1"] = 7, ["2"] = 6, ["3"] = 3 },
    ["item_ammo_crossbow"] = { ["Type"] = "XBowBolt", ["Max"] = sk_max_crossbow, ["1"] = 7, ["2"] = 6, ["3"] = 3 },
    ["item_rpg_round"] = { ["Type"] = "RPG_Round", ["Max"] = sk_max_rpg_round, ["1"] = 1, ["2"] = 1, ["3"] = 1 },
    ["weapon_frag"] = { ["Type"] = "Grenade", ["Max"] = sk_max_grenade, ["1"] = 1, ["2"] = 1, ["3"] = 1 },
    ["weapon_slam"] = { ["Type"] = "slam", ["Max"] = sk_max_slam, ["1"] = 1, ["2"] = 1, ["3"] = 1 },
}

GM.PLAYER_WEAPON_DAMAGE =
{
    ["weapon_crowbar"] = GetConVar("sk_plr_dmg_crowbar"),
    ["weapon_stunstick"] = GetConVar("sk_plr_dmg_stunstick"),
    ["weapon_ar2"] = GetConVar("sk_plr_dmg_ar2"),
    ["weapon_357"] = GetConVar("sk_plr_dmg_357"),
    ["weapon_smg1"] = GetConVar("sk_plr_dmg_smg1"),
    ["weapon_shotgun"] = GetConVar("sk_plr_dmg_buckshot"),
    ["weapon_pistol"] = GetConVar("sk_plr_dmg_pistol"),
    ["weapon_physcannon"] = GetConVar("string name")
}

GM.NPC_WEAPON_DAMAGE =
{
    ["weapon_crowbar"] = GetConVar("sk_npc_dmg_crowbar"),
    ["weapon_stunstick"] = GetConVar("sk_npc_dmg_stunstick"),
    ["weapon_ar2"] = GetConVar("sk_npc_dmg_ar2"),
    ["weapon_357"] = GetConVar("sk_npc_dmg_357"),
    ["weapon_shotgun"] = GetConVar("sk_npc_dmg_buckshot"),
}

GM.GameWeapons =
{
    ["weapon_357"] = true,
    ["weapon_alyxgun"] = true,
    ["weapon_annabelle"] = true,
    ["weapon_ar2"] = true,
    ["weapon_brickbat"] = true,
    ["weapon_bugbait"] = true,
    ["weapon_crossbow"] = true,
    ["weapon_crowbar"] = true,
    ["weapon_frag"] = true,
    ["weapon_physcannon"] = true,
    ["weapon_pistol"] = true,
    ["weapon_rpg"] = true,
    ["weapon_shotgun"] = true,
    ["weapon_smg1"] = true,
    ["weapon_striderbuster"] = true,
    ["weapon_stunstick"] = true,
}

-- FIXME: No longer required but keep for now.
GM.AITranslatedGameWeapons =
{
    ["ai_weapon_357"] = "weapon_357",
    ["ai_weapon_ar2"] = "weapon_ar2",
    ["ai_weapon_smg1"] = "weapon_smg1",
    ["ai_weapon_shotgun"] = "weapon_shotgun",
}

function GM:CreateTeams()

    team.SetUp(LAMBDA_TEAM_ALIVE, "Alive", Color(255, 130, 0), true)
    team.SetUp(LAMBDA_TEAM_DEAD, "Dead", Color(255, 30, 0), true)
    team.SetUp(LAMBDA_TEAM_SPECTATOR, "Spectating", Color(100, 100, 100), true)
    team.SetUp(LAMBDA_TEAM_CONNECTING, "Connecting", Color(100, 100, 100), true)

    team.SetUp(LAMBDA_TEAM_REBEL, "Rebels", Color(255, 0, 0, 100), true)
    team.SetUp(LAMBDA_TEAM_COMBINE, "Combine", Color(0, 0, 255, 100), true)

end

if CLIENT then
    language.Add("LAMBDA_Timeleft", "TIME LEFT")
    language.Add("LAMBDA_Map", "MAP")
    language.Add("LAMBDA_Uptime", "UPTIME")
    language.Add("LAMBDA_Campaign", "CAMPAIGN")
    language.Add("LAMBDA_Chapter", "CHAPTER")
    language.Add("LAMBDA_Frags", "FRAGS LEFT")
end
