if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_rpg", "weapon_crossbow"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 12,
        ["Grenade"] = 3,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 1,
        ["XBowBolt"] = 4,
        ["RPG_Round"] = 3,
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

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(12302, 9626, -728),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(12308, 9405, -678),
            Mins = Vector(-68, -19, -54),
            Maxs = Vector(68, 19, 54)
        }
    },
    {
        Pos = Vector(11934, 8531, -728),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(11946, 8528, -696),
            Mins = Vector(-101, -64, -40),
            Maxs = Vector(101, 64, 40)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Replace the train start trigger with a bigger one and a teamwait keyvalue and create a checkpoint parented to the train
    local trainCheckpoint = GAMEMODE:CreateCheckpoint(Vector(11986, 8409, -759), Angle(0, 90, 0))

    ents.WaitForEntityByName("razortrain3", function(ent)
        trainCheckpoint:SetParent(ent)
    end)

    ents.WaitForEntityByName("trigger_playerontrain", function(ent)
        local trigger = ents.Create("trigger_once")
        trigger:SetupTrigger(Vector(11986, 8374, -737), Angle(0, 0, 0), Vector(-25, -50, -33), Vector(25, 50, 33))
        trigger:SetName("trigger_playerontrain")
        trigger:SetKeyValue("teamwait", "1")
        trigger:CloneOutputs(ent)

        trigger.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(trainCheckpoint, activator)
        end

        ent:Remove()
    end)
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT