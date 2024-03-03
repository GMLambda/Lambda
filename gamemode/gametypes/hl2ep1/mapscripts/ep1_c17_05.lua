if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_crossbow"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 12,
        ["Grenade"] = 3,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 1,
        ["XBowBolt"] = 4
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_dynamic"] = true,
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_physgun"] = true,
    ["global_newgame_spawner_shotgun"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_ar2"] = true,
    ["global_newgame_spawner_rpg"] = true,
    ["global_newgame_spawner_xbow"] = true,
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {}
function MAPSCRIPT:PostInit()
    -- Force the NPCs to follow the player. Squads in Garry's Mod are a bit broken, the replacement
    -- lambda_player_follow entity is a bit more reliable but also quite hacky.
    local playerFollow = ents.Create("lambda_player_follow")
    playerFollow:SetName("lambda_follow_player")
    playerFollow:SetKeyValue("actor", "citizen_refugees*")
    playerFollow:Spawn()
    playerFollow:Activate()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT