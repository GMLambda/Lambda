if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
    },
    Ammo = {
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems_template"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-10951, -7040, 1302),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-10947, -7060, 1358),
            Mins = Vector(-66, -85, -60),
            Maxs = Vector(66, 85, 60)
        }
    },
    {
        Pos = Vector(-10538, -7397, 169),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-10539, -7437, 238),
            Mins = Vector(-65, -18, -43),
            Maxs = Vector(65, 18, 43)
        }
    },
    {
        Pos = Vector(-8317, -8745, 46),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-8382, -8616, 102),
            Mins = Vector(-100, -80, -25),
            Maxs = Vector(100, 80, 25)
        }
    },
    {
        Pos = Vector(-7103, -8731, 23),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-7136, -8618, 62),
            Mins = Vector(-100, -80, -44),
            Maxs = Vector(100, 80, 44)
        }
    },
    {
        Pos = Vector(-5928, -6626, -86),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-6062, -6950, -220),
            Mins = Vector(-70, -140, -130),
            Maxs = Vector(70, 140, 130)
        }
    },
    {
        Pos = Vector(-4573, -6412, -83),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-4612, -6364, -32),
            Mins = Vector(-125, -205, -160),
            Maxs = Vector(125, 205, 160)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Apply enough force to do more than one player.
    ents.WaitForEntityByName("platform_2_thruster_1", function(ent)
        ent:SetKeyValue("force", "1000")
    end)

    -- This is one ugly hack, we want to keep the velocity of the platform in check due to the force applied.
    -- Without enough force it won't budge and with too much force it sends players flying.
    ents.WaitForEntityByName("platform_2", function(ent)
        hook.Add("Think", "PlatformVelocityControl", function()
            if not IsValid(ent) then
                return
            end
            local physObj = ent:GetPhysicsObject()
            if not IsValid(physObj) then
                return
            end
            local vel = physObj:GetVelocity()
            local len = vel:LengthSqr()
            local maxSpeed = 150
            local maxLen = maxSpeed * maxSpeed
            if len > maxLen then
                physObj:SetVelocity(vel:GetNormalized() * maxSpeed)
            end
        end)
    end)

    -- Create trigger to add pistol to loadout table
    local pistolTrigger = ents.Create("trigger_once")
    pistolTrigger:SetupTrigger(Vector(-11136, -7123, 1660), Angle(0, 0, 0), Vector(-16, -40, -62), Vector(16, 40, 62))
    pistolTrigger.OnTrigger = function(_, activator)
        local loadout = GAMEMODE:GetMapScript().DefaultLoadout
        table.insert(loadout.Weapons, "weapon_pistol")
    end

    -- Create trigger to populate loadout table with weapons
    local wpnTrigger = ents.Create("trigger_once")
    wpnTrigger:SetupTrigger(Vector(-7637, -7834, 66), Angle(0, 0, 0), Vector(-60, -50, -50), Vector(60, 50, 50))
    wpnTrigger.OnTrigger = function(_, activator)
        local loadout = GAMEMODE:GetMapScript().DefaultLoadout
        table.insert(loadout.Weapons, "weapon_shotgun")
        table.insert(loadout.Weapons, "weapon_frag")
        table.insert(loadout.Weapons, "weapon_357")
    end
end

return MAPSCRIPT