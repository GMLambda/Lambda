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
        Pos = Vector(3187.333984, 2184.848145, -312.009857),
        Ang = Angle(0, 180, 0),
        VisiblePos = Vector(3034.239258, 2188.360840, -318.995728),
        Trigger = {
            Pos = Vector(3187.333984, 2184.848145, -312.009857),
            Mins = Vector(-250, -110, 0),
            Maxs = Vector(110, 110, 100),
        }
    },
    {
        Pos = Vector(2667.206787, 3911.651367, -323.968750),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(2945.403076, 2563.369629, -319.968750),
            Mins = Vector(-30, -30, 0),
            Maxs = Vector(30, 30, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT