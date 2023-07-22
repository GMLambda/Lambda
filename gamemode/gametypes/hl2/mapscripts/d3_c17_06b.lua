if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow", "weapon_bugbait"},
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

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["pclip_gate1"] = true,
    ["player_spawn_template"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(2843.645508, 1058.373169, 64.031250),
        Ang = Angle(0, 0, 0),
        VisiblePos = Vector(2904.702881, 1060.976196, 64.031250),
        Trigger = {
            Pos = Vector(2894.431396, 1052.031250, 64.031250),
            Mins = Vector(-20, -20, 0),
            Maxs = Vector(20, 20, 100),
        }
    },
    {
        Pos = Vector(3477.289062, 1116.633179, 0.031250),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(3477.289062, 1116.633179, 0.031250),
            Mins = Vector(-60, -60, 0),
            Maxs = Vector(60, 60, 100),
        }
    },
    {
        Pos = Vector(3648.722412, 1569.612793, 256.031250),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(3575.494873, 1570.045532, 256.031250),
            Mins = Vector(-60, -60, 0),
            Maxs = Vector(60, 60, 100),
        }
    },
    {
        Pos = Vector(3314.308350, 1882.039551, 0.031250),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(3314.308350, 1882.039551, 0.031250),
            Mins = Vector(-30, -30, 0),
            Maxs = Vector(30, 30, 100),
        }
    },
    {
        Pos = Vector(3940.753906, 1200.170898, 384.031250),
        Ang = Angle(0, 180, 0),
        Trigger = {
            Pos = Vector(4022.167480, 1330.496826, 387.531250),
            Mins = Vector(-40, -40, 0),
            Maxs = Vector(40, 40, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- This NPC should not can be killed by player.
        ents.WaitForEntityByName(
            "citizen_2_ct_mkr",
            function(ent)
                ent:ClearOutputs()
                ent:Fire("AddOutput", "OnSpawnNPC citizen_2_ct_aiss_1,StartSchedule,,0.1,1")
            end
        )

        ents.WaitForEntityByName(
            "wench_1_lever_1",
            function(ent)
                ent:SetKeyValue("spawnflags", "122")
            end
        )

        ents.WaitForEntityByName(
            "wench_2_lever_1",
            function(ent)
                ent:Fire("AddOutput", "OnOpen !self,Lock")
            end
        )
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT