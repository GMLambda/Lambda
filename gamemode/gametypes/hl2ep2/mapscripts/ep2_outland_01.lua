if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {},
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(232, -775, 9),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(329, -770, 68),
            Mins = Vector(-76, -82, -76),
            Maxs = Vector(76, 82, 76)
        }
    },
    {
        Pos = Vector(-2848, -784, 256),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-2848, -784, 256),
            Mins = Vector(-224, -144, -16),
            Maxs = Vector(224, 144, 16)
        }
    },
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")
    if SERVER then
        -- Create the physcannon
        local createPhyscannon = ents.Create("lambda_clientcommand")
        createPhyscannon:Spawn()
        createPhyscannon.Command = function(s, data, activator, caller)
            local pos = Vector(1051, -316, -2)
            local ang = Angle(0, 0, 0)

            local wep = ents.CreateSimple("weapon_physcannon", {
                Pos = pos,
                Ang = ang
            })

            local phys = wep:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetMass(1000) -- Somewhat prevents players trying to hide the gun or moving it too far as its rather important.
            end

            table.insert(GAMEMODE:GetMapScript().DefaultLoadout.Weapons, "weapon_physcannon")
            s:Remove()

            return true
        end

        -- Remove the old clientcommand
        ents.WaitForEntityByName("command_physcannon", function(ent)
            createPhyscannon:SetName("command_physcannon")
            ent:Remove()
        end)

        -- Remove train player clip
        ents.WaitForEntityByName("clip_player", function(ent)
        ent:Remove()
        end)

        -- Remove pit player clip
        ents.WaitForEntityByName("mine_pit_clip_brush", function(ent)
        ent:Remove()
        end)

    end
end

return MAPSCRIPT