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
    ["spawn_items_template"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(1921.614014, -5632.266602, 320.031250),
        Ang = Angle(0, 180, 0),
        Trigger = {
            Pos = Vector(1921.614014, -5632.266602, 320.031250),
            Mins = Vector(-110, -110, 0),
            Maxs = Vector(110, 110, 100),
        }
    },
    {
        Pos = Vector(830.641296, -4235.453125, 128.031250),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(838.730957, -4208.859375, 128.031250),
            Mins = Vector(-50, -50, 0),
            Maxs = Vector(50, 50, 100),
        }
    },
    {
        Pos = Vector(1793.683350, -3479.405762, 320.031250),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1793.683350, -3479.405762, 320.031250),
            Mins = Vector(-100, -80, 0),
            Maxs = Vector(100, 80, 100),
        }
    },
    {
        Pos = Vector(1597.989380, -3329.118408, -63.968750),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1597.989380, -3329.118408, -63.968750),
            Mins = Vector(-60, -60, 0),
            Maxs = Vector(60, 60, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT