AddCSLuaFile()

LAMBDA_TEAM_CONNECTING = 1200
LAMBDA_TEAM_DEAD = 1
LAMBDA_TEAM_ALIVE = 5
LAMBDA_TEAM_SPECTATOR = 3

GM.HurtSounds = {}

-- Zombie
GM.HurtSounds["zombie"] = {}
GM.HurtSounds["zombie"][HITGROUP_LEFTARM] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_RIGHTARM] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_LEFTLEG] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_RIGHTLEG] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_STOMACH] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_GENERIC] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_CHEST] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
GM.HurtSounds["zombie"][HITGROUP_GEAR] = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}

-- Male
GM.HurtSounds["male"] = {}
GM.HurtSounds["male"][HITGROUP_LEFTARM] = {
	"vo/npc/male01/myarm01.wav",
	"vo/npc/male01/myarm02.wav"
}
GM.HurtSounds["male"][HITGROUP_RIGHTARM] = {
	"vo/npc/male01/myarm01.wav",
	"vo/npc/male01/myarm02.wav"
}
GM.HurtSounds["male"][HITGROUP_LEFTLEG] = {
	"vo/npc/male01/myleg01.wav",
	"vo/npc/male01/myleg02.wav"
}
GM.HurtSounds["male"][HITGROUP_RIGHTLEG] = {
	"vo/npc/male01/myleg01.wav",
	"vo/npc/male01/myleg02.wav"
}
GM.HurtSounds["male"][HITGROUP_STOMACH] = {
	"vo/npc/male01/hitingut01.wav",
	"vo/npc/male01/hitingut02.wav",
	"vo/npc/male01/mygut02.wav"
}
GM.HurtSounds["male"][HITGROUP_GENERIC] = {
	"vo/npc/male01/pain01.wav",
	"vo/npc/male01/pain02.wav",
	"vo/npc/male01/pain03.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain05.wav",
	"vo/npc/male01/pain06.wav",
	"vo/npc/male01/pain07.wav",
	"vo/npc/male01/pain08.wav",
	"vo/npc/male01/pain09.wav"
}
GM.HurtSounds["male"][HITGROUP_CHEST] = {
	"vo/npc/male01/pain01.wav",
	"vo/npc/male01/pain02.wav",
	"vo/npc/male01/pain03.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain05.wav",
	"vo/npc/male01/pain06.wav",
	"vo/npc/male01/pain07.wav",
	"vo/npc/male01/pain08.wav",
	"vo/npc/male01/pain09.wav"
}
GM.HurtSounds["male"][HITGROUP_GEAR] = {
	"vo/npc/male01/pain01.wav",
	"vo/npc/male01/pain02.wav",
	"vo/npc/male01/pain03.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain05.wav",
	"vo/npc/male01/pain06.wav",
	"vo/npc/male01/pain07.wav",
	"vo/npc/male01/pain08.wav",
	"vo/npc/male01/pain09.wav"
}

-- Female
GM.HurtSounds["female"] = {}
GM.HurtSounds["female"][HITGROUP_LEFTARM] = {
	"vo/npc/female01/myarm01.wav",
	"vo/npc/female01/myarm02.wav"
}
GM.HurtSounds["female"][HITGROUP_RIGHTARM] = {
	"vo/npc/female01/myarm01.wav",
	"vo/npc/female01/myarm02.wav"
}
GM.HurtSounds["female"][HITGROUP_LEFTLEG] = {
	"vo/npc/female01/myleg01.wav",
	"vo/npc/female01/myleg02.wav"
}
GM.HurtSounds["female"][HITGROUP_RIGHTLEG] = {
	"vo/npc/female01/myleg01.wav",
	"vo/npc/female01/myleg02.wav"
}
GM.HurtSounds["female"][HITGROUP_STOMACH] = {
	"vo/npc/female01/hitingut01.wav",
	"vo/npc/female01/hitingut02.wav",
	"vo/npc/female01/mygut02.wav"
}
GM.HurtSounds["female"][HITGROUP_GENERIC] = {
	"vo/npc/female01/pain01.wav",
	"vo/npc/female01/pain02.wav",
	"vo/npc/female01/pain03.wav",
	"vo/npc/female01/pain04.wav",
	"vo/npc/female01/pain04.wav",
	"vo/npc/female01/pain05.wav",
	"vo/npc/female01/pain06.wav",
	"vo/npc/female01/pain07.wav",
	"vo/npc/female01/pain08.wav",
	"vo/npc/female01/pain09.wav"
}
GM.HurtSounds["female"][HITGROUP_CHEST] = {
	"vo/npc/female01/pain01.wav",
	"vo/npc/female01/pain02.wav",
	"vo/npc/female01/pain03.wav",
	"vo/npc/female01/pain04.wav",
	"vo/npc/female01/pain04.wav",
	"vo/npc/female01/pain05.wav",
	"vo/npc/female01/pain06.wav",
	"vo/npc/female01/pain07.wav",
	"vo/npc/female01/pain08.wav",
	"vo/npc/female01/pain09.wav"
}
GM.HurtSounds["female"][HITGROUP_GEAR] = {
	"vo/npc/female01/pain01.wav",
	"vo/npc/female01/pain02.wav",
	"vo/npc/female01/pain03.wav",
	"vo/npc/female01/pain04.wav",
	"vo/npc/female01/pain04.wav",
	"vo/npc/female01/pain05.wav",
	"vo/npc/female01/pain06.wav",
	"vo/npc/female01/pain07.wav",
	"vo/npc/female01/pain08.wav",
	"vo/npc/female01/pain09.wav"
}

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
}

GM.PLAYER_WEAPON_DAMAGE =
{
	["weapon_crowbar"] = GetConVar("sk_plr_dmg_crowbar"),
	["weapon_stunstick"] = GetConVar("sk_plr_dmg_stunstick"),
	["weapon_ar2"] = GetConVar("sk_plr_dmg_ar2"),
	["weapon_357"] = GetConVar("sk_plr_dmg_357"),
	["weapon_smg1"] = GetConVar("sk_plr_dmg_smg1"),
	["weapon_crossbow"] = GetConVar("sk_plr_dmg_crowssbow"),
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

end
