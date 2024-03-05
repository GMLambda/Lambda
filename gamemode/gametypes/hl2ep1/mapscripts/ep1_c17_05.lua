if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_crossbow", "weapon_rpg"},
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

    -- Alyx should wait for everyone at the end before closing
    ents.WaitForEntityByName("counter_everyone_in_place_for_barney_goodbye", function(ent)
        ent:SetKeyValue("max", "6")
    end)

    -- Make the doors at the end close when we are ready
    local trainCheckpoint = ents.Create("trigger_once")
    trainCheckpoint:SetupTrigger(Vector(9876, 9628, -680), Angle(0, 0, 0), Vector(-236, -220, -60), Vector(236, 220, 60))
    trainCheckpoint:SetKeyValue("teamwait", "1")
    trainCheckpoint:SetKeyValue("showwait", "0")
    trainCheckpoint.OnTrigger = function(trigger)
        local push = ents.Create("trigger_push")
        push:SetupTrigger(Vector(9648, 9784, -661), Angle(0, 0, 0), Vector(-20, -60, -80), Vector(20, 60, 80))
        push:SetKeyValue("spawnflags", "1")
        push:SetKeyValue("pushdir", "358 357 0")
        push:SetKeyValue("speed","50")
        TriggerOutputs({{"counter_everyone_in_place_for_barney_goodbye", "Add", 2.0, "1"}})
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT