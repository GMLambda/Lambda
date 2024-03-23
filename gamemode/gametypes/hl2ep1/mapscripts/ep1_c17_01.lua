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
        Pos = Vector(2828, -1360, 68),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(2828, -1360, 68),
            Mins = Vector(-75, -75, -44),
            Maxs = Vector(75, 75, 44)
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
        -- Remove counter that closes dowmn the combine wall. Maybe improve this later to close when everyone is here
        ents.WaitForEntityByName("Crushing_wall_counter", function(ent)
            ent:Remove()
        end)

        -- Create checkpoint after turning off gas
        ents.WaitForEntityByName("relay_hellskitchen_stop", function(ent)
            ent.OnTrigger = function()
                local hellscheckpoint = GAMEMODE:CreateCheckpoint(Vector(1568, 1782, 60), Angle(0, 90, 0))
                GAMEMODE:SetPlayerCheckpoint(hellscheckpoint)
            end
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