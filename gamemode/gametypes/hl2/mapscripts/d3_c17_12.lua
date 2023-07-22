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
    ["player_spawn_items"] = true,
    ["pclip_gate1"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(645.813293, 3391.362061, 192.031250),
        Ang = Angle(0, -180, 0),
        Trigger = {
            Pos = Vector(645.813293, 3391.362061, 192.031250),
            Ang = Angle(0, 0, 0),
            Mins = Vector(-50, -50, 0),
            Maxs = Vector(50, 50, 100),
        }
    },
    {
        Pos = Vector(-2476.636963, 6708.353516, 128.031250),
        Ang = Angle(0, 90, 0),
        VisiblePos = Vector(-2494.347412, 6463.139648, 128.031250),
        Trigger = {
            Pos = Vector(-2494.347412, 6463.139648, 128.031250),
            Ang = Angle(0, 0, 0),
            Mins = Vector(-50, -50, 0),
            Maxs = Vector(50, 50, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- Make sure the player spawns at the correct spot.
        local spawn = ents.Create("info_player_start")
        spawn:SetPos(Vector(1200.359985, 3379.639893, 768.816528))
        spawn:SetAngles(Angle(0, -130, 0))
        spawn:SetKeyValue("spawnflags", "1")
        spawn:Spawn()
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT