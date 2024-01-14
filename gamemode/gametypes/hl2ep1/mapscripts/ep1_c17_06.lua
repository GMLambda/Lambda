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
    ["door_blocker"] = true,
    ["suit"] = true,
    ["physcannon"] = true,
    ["weapons"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    /* PLACEHOLDER EXAMPLE CHECKPOINT
    {
        Pos = Vector(4352, -4260, -119),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(4292, -4130, -119),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 100)
        }
    },
    */
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- do stuff
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT