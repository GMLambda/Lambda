if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_physcannon", "weapon_pistol", "weapon_shotgun"},
    Ammo = {
        ["Pistol"] = 18,
        ["Buckshot"] = 12
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {
    ["weapon_physcannon"] = true,
    ["weapon_pistol"] = true,
    ["weapon_shotgun"] = true
}

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
    {
        Pos = Vector(2660, -1324, 8),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(2828, -1360, 68),
            Mins = Vector(-75, -75, -44),
            Maxs = Vector(75, 75, 44)
        }
    },
    {
        Pos = Vector(1871, 2071, 33),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(1844, 1878, 78),
            Mins = Vector(-100, -160, -75),
            Maxs = Vector(100, 160, 75)
        }
    },
    {
        Pos = Vector(100, 695, 174),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(109, 692, 216),
            Mins = Vector(-65, -30, -40),
            Maxs = Vector(65, 30, 40)
        }
    },
    {
        Pos = Vector(-848, 160, 64),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-848, 160, 64),
            Mins = Vector(-105, -105, -65),
            Maxs = Vector(105, 105, 65)
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- Use the combine wall open trigger to add weapon_smg1 to the map loadout
        ents.WaitForEntityByName("trigger_combine_wall", function (ent)
            local loadout = GAMEMODE:GetMapScript().DefaultLoadout
            table.insert(loadout.Weapons, "weapon_smg1")
        end)

        -- Remove counter that closes dowmn the combine wall. Maybe improve this later to close when everyone is here
        ents.WaitForEntityByName("Crushing_wall_counter", function(ent)
            ent:Remove()
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

function MAPSCRIPT:EntityKeyValue(ent, key, val)
    -- Known engine bug with func_movelinear. If parented the move direction is incorrect.
    if ent:GetClass() == "func_movelinear" and key == "parentname" then
        return "0"
    end
end

return MAPSCRIPT