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
        "weapon_357",
        "weapon_frag",
    },
    Ammo = {
        ["SMG1"] = 45,
        ["Buckshot"] = 6,
        ["Pistol"] = 18,
        ["Grenade"] = 5,
        ["AR2"] = 50,
        ["357"] = 6,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 90,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["playerclip_powerroom"] = true,
    ["playerclip_elevator"] = true,
    ["teleport_jeep"] = true,
    ["fade_start"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-1763.0, -9607.42, -1536),
        Ang = Angle(0, 109, 0),
        RenderPos = Vector(-1814.464355, -9021.433594, -1556.093262),
        Trigger = {
            Pos = Vector(-1312.065430, -9076.086914, -1576.651123),
            Mins = Vector(-100, -100, 0),
            Maxs = Vector(100, 100, 100)
        },
        Vehicle = {
            Pos = Vector(-1724.15, -9506.5, -1533),
            Ang = Angle(0, 40, 0),
        },
    },
}

function MAPSCRIPT:PostInit()
    -- Power room checkpoint
    local cp1_powerroom = GAMEMODE:CreateCheckpoint(Vector(-3330, -9731, -1519))
    ents.WaitForEntityByName("trigger_alyx_standby", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp1_powerroom, activator)
        end
    end)
end

return MAPSCRIPT