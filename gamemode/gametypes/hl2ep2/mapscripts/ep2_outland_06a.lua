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
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- Power room checkpoint
    local cp1_powerroom = GAMEMODE:CreateCheckpoint(Vector(-3330, -9731, -1519))
    ents.WaitForEntityByName("trigger_alyx_standby", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp1_powerroom, activator)
        end
    end)
end

return MAPSCRIPT