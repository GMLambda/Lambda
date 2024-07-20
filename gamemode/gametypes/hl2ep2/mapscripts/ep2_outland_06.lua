if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_shotgun",
        "weapon_smg1",
        "weapon_357",
        "weapon_frag",
    },
    Ammo = {
        ["SMG1"] = 45,
        ["Buckshot"] = 6,
        ["Pistol"] = 18,
        ["Grenade"] = 3,
        ["357"] = 6,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 15,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_physcannon"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_local_items"] = true,
    ["trigger_goopit3_ladder_up"] = true, -- remove all fall related stuff
    ["trigger_goopit3_ladder_down"] = true,
    ["trigger_goopit3_hurt"] = true
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(737, 480, 101), -- 2
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(600, 506, 156),
            Mins = Vector(-4, -56, -60),
            Maxs = Vector(4, 56, 60)
        }
    },
    {
        Pos = Vector(731, 2040, 101), -- 4
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(728, 1988, 128),
            Mins = Vector(-40, -60, -40),
            Maxs = Vector(40, 60, 40)
        }
    },
    {
        Pos = Vector(2848, 1358, -280), -- 8
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(2873, 1314, -258),
            Mins = Vector(-42, -122, -16),
            Maxs = Vector(42, 122, 16)
        }
    },
}

function MAPSCRIPT:PostInit()
    ents.WaitForEntityByName("trigger_alyxChoreoArrive06", function(ent)
        ent.OnTrigger = function()
            local loadout = GAMEMODE:GetMapScript().DefaultLoadout
            table.insert(loadout.Weapons, "weapon_ar2")
        end
    end)

    -- triggers actually have names on this map, lets make use of that for checkpoints
    local cp1 = GAMEMODE:CreateCheckpoint(Vector(331, 506, 785))
    ents.WaitForEntityByName("bldg1_trigger", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp1, activator)
        end
    end)

    local cp3 = GAMEMODE:CreateCheckpoint(Vector(1874, 1079, -123))
    ents.WaitForEntityByName("alyx_sniperGuide00", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp3, activator)
        end
    end)

    local cp5 = GAMEMODE:CreateCheckpoint(Vector(22, 3296, -114))
    ents.WaitForEntityByName("trigger_warehouse_noisesInTheDark", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp5, activator)
        end
    end)

    local cp6 = GAMEMODE:CreateCheckpoint(Vector(1118, 2798, -252))
    ents.WaitForEntityByName("trigger_startspawn_goopit1", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp6, activator)
        end
    end)

    local cp7 = GAMEMODE:CreateCheckpoint(Vector(1904, 2032, -282))
    ents.WaitForEntityByName("zombieTrigger_topofPipeHeadCrabs", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp7, activator)
        end
    end)

    local cp9 = GAMEMODE:CreateCheckpoint(Vector(3961, 2340, 637))
    ents.WaitForEntityByName("autoSave_beforeJeep", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp9, activator)
        end
    end)

    local cp10 = GAMEMODE:CreateCheckpoint(Vector(-400, 2344, 693))
    ents.WaitForEntityByName("trigger_alyxComeDownToJeep", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp10, activator)
        end
    end)
end

return MAPSCRIPT