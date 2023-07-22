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
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["antlion_allied"] = GLOBAL_ON
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-497.127838, 29.422707, 512.03009),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-497.127838, 29.422707, 576.030090),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 200),
        }
    },
    {
        Pos = Vector(-2766.497314, 166.390900, 662.811646),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-2766.497314, 166.390900, 662.811646),
            Mins = Vector(-100, -150, 0),
            Maxs = Vector(100, 150, 100),
        }
    },
    {
        Pos = Vector(-4656.063477, -734.348145, 640.03125),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-2744.281250, 191.008423, 658.094666),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- Rename some things.
        ents.WaitForEntityByName(
            "combine_crusherwall1_ss",
            function(ent)
                ent:SetName("lambda_combine_crusherwall1_ss")
            end
        )

        ents.WaitForEntityByName(
            "combine_crusherwall2_ss",
            function(ent)
                ent:SetName("lambda_combine_crusherwall2_ss")
            end
        )

        ents.WaitForEntityByName(
            "combine_crusherwall3_ss",
            function(ent)
                ent:SetName("lambda_combine_crusherwall3_ss")
            end
        )

        ents.WaitForEntityByName(
            "combine_crusherwall4_ss",
            function(ent)
                ent:SetName("lambda_combine_crusherwall4_ss")
            end
        )

        ents.WaitForEntityByName(
            "point_of_no_return",
            function(ent)
                ent:SetName("lambda_point_of_no_return")
            end
        )

        -- 1386.760010 946.409973 385.000000
        -- Make sure the player spawns at the correct spot.
        local spawn = ents.Create("info_player_start")
        spawn:SetPos(Vector(1386.760010, 946.409973, 385.000000))
        spawn:SetAngles(Angle(0, -180, 0))
        spawn:SetKeyValue("spawnflags", "1")
        spawn:Spawn()
        -- Allow all players to be crushed in a safe non game breaking way.
        -- -4733.655273 -775.621887 498.795654
        local crushTrigger = ents.Create("trigger_once")
        crushTrigger:SetupTrigger(Vector(-4733.655273, -775.621887, 498.795654), Angle(0, 0, 0), Vector(-1200, -550, -100), Vector(1100, 550, 200))
        crushTrigger:SetKeyValue("TeamWait", "1")
        crushTrigger:SetKeyValue("ShowWait", "0")
        crushTrigger:Fire("AddOutput", "OnTrigger lambda_point_of_no_return,Enable,,0.0")
        crushTrigger:Fire("AddOutput", "OnTrigger lambda_combine_crusherwall3_ss,BeginSequence,,1.0")
        crushTrigger:Fire("AddOutput", "OnTrigger lambda_combine_crusherwall1_ss,BeginSequence,,15.0")
        crushTrigger:Fire("AddOutput", "OnTrigger lambda_combine_crusherwall4_ss,BeginSequence,,30.0")
        crushTrigger:Fire("AddOutput", "OnTrigger lambda_combine_crusherwall2_ss,BeginSequence,,45.0")
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT