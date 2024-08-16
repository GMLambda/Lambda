if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_shotgun",
        "weapon_smg1",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_357",
    },
    Ammo = {
        ["XBowBolt"] = 5,
        ["AR2"] = 30,
        ["SMG1_Grenade"] = 3,
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 30,
    },
    Armor = 50,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_base_items"] = true,
    ["pclip_hall_attack_1"] = true -- Remove first door clip
}
MAPSCRIPT.GlobalStates = {}
MAPSCRIPT.Checkpoints = {
    {   -- When out of duct
        Pos = Vector(439, -9424, -1527),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(232, -9319, -1510),
            Mins = Vector(-9, -35, -25),
            Maxs = Vector(9, 35, 25)
        }
    },
    {   -- hallways after piperoom
        Pos = Vector(-1200, -9965, -1211),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-1212, -9804, -1144),
            Mins = Vector(-50, -42, -64),
            Maxs = Vector(50, 42, 64)
        }
    },
    {   -- tunnel stairs after hallway
        Pos = Vector(128, -11272, -1210),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(66, -11268, -1164),
            Mins = Vector(-8, -60, -76),
            Maxs = Vector(8, 60, 76)
        }
    },
    {   -- out of water
        Pos = Vector(1825, -11063, -1083),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1826, -11262, -1015),
            Mins = Vector(-204, -255, -55),
            Maxs = Vector(204, 255, 55)
        }
    },
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- Find trigger and add CP before ambush
    local atrigger
    for k, v in pairs(ents.FindByPos(Vector(2360, -11256, -38.02), "trigger_once")) do
        atrigger = v
    end

    local aCP = GAMEMODE:CreateCheckpoint(Vector(2376, -11264, -91), Angle(0, 0, 0))
    atrigger.OnTrigger = function(_, activator)
        GAMEMODE:SetPlayerCheckpoint(aCP, activator)
    end

    -- Remove trigger for players at the end before transition 
    for k, v in pairs(ents.FindByName("trigger_transition_go")) do
        if v:GetInternalVariable("filtername") == "" then
            v:Remove()
        end
    end

    -- Since we removed the trigger we have to adjust the counter
    ents.WaitForEntityByName("counter_labbydoor", function(ent)
        ent:SetKeyValue("max", "1")
    end)
end

return MAPSCRIPT