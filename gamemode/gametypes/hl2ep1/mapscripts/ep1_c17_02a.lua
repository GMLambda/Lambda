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
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_physcannon"] = true,
    ["global_newgame_spawner_shotgun"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_spawner_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(2015, 7469, -2539),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(2002, 7463, -2484),
            Mins = Vector(-106, -111, -64),
            Maxs = Vector(106, 111, 64)
        }
    },
    {
        Pos = Vector(-514, 7612, -2556),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-413, 7602, -2406),
            Mins = Vector(-117, -98, -64),
            Maxs = Vector(117, 98, 64)
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName("trigger_shotgun", function(ent)
            ent:Fire("AddOutput", "OnTrigger lcs_hos_enterance,Start,5,0")
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT