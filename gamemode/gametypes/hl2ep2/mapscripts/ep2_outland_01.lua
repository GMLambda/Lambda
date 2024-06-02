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
    ["clip_player"] = true,
    ["clip_player_train"] = true,
    ["mine_pit_clip_brush"] = true,
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
    {
        Pos = Vector(-3777, 1764, 141),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-3777, 1764, 141),
            Mins = Vector(-224, -144, -16),
            Maxs = Vector(224, 144, 16)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Don't make the train fall.
    ents.WaitForEntityByName("prop.phys.train.04", function(ent)
        ent:SetName("lambda_prop.phys.train.04")
    end)

    ents.WaitForEntityByName("prop.train.02", function(ent)
        ent:SetName("lambda_prop.train.02")
    end)

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

    -- Rename the door and add a new trigger to EnableMotion
    ents.WaitForEntityByName("physbox_floor_door", function(ent)
        ent:SetName("lambda_physbox_floor_door")
    end)

    local openDoorTrigger = ents.Create("trigger_once")
    openDoorTrigger:SetName("lambda_trigger_open_door")
    openDoorTrigger:SetKeyValue("teamwait", "1")
    openDoorTrigger:SetKeyValue("StartDisabled", "1")
    openDoorTrigger:SetupTrigger(
        Vector(-5613.831543, 4506.608398, -135.968750),
        Angle(0, 0, 0),
        Vector(-150, -100, 0),
        Vector(150, 120, 128)
    )
    openDoorTrigger:Fire("AddOutput", "OnTrigger lambda_physbox_floor_door,EnableMotion,,0,-1", "0.0")

    ents.WaitForEntityByName("gate_control_lever", function(ent)
        ent:Fire("AddOutput", "OnPressed lambda_trigger_open_door,Enable,,0,-1", "0.0")
    end)

    -- Wait for team before we can pull the crowbar and trigger the elevator
    local multiple = ents.FindByPos(Vector(-6289, 3807, -288),"trigger_multiple")
    for k, v in pairs(multiple) do
        v:Remove()
    end

    local elevatorTrigger = ents.Create("trigger_once")
    elevatorTrigger:SetupTrigger(Vector(-6289, 3807, -288), Angle(0, 0, 0), Vector(-47, -25, -36), Vector(47, 25, 36))
    elevatorTrigger:SetKeyValue("teamwait", "1")
    elevatorTrigger:Fire("AddOutput", "OnTrigger crowbar,EnablePhyscannonPickup,,0,-1")
    elevatorTrigger:Fire("AddOutput", "OnTrigger crowbar_cover,Disable,,0,-1")
    elevatorTrigger:Fire("AddOutput", "OnTrigger timer.vort.nag.01,Disable,,0,1")
    elevatorTrigger:Fire("AddOutput", "OnTrigger lcs_intro_vort_carefull,Start,,0,1")

    ents.WaitForEntityByName("relay_crowbar_grabbed", function(ent)
        ent.OnTrigger = function(_,activator)
            local loadout = GAMEMODE:GetMapScript().DefaultLoadout
            table.insert(loadout.Weapons, "weapon_crowbar")
        end
    end)
end

return MAPSCRIPT