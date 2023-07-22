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
MAPSCRIPT.EntityFilterByClass = {} --["env_global"] = true,
MAPSCRIPT.EntityFilterByName = {
    ["pclip_gate1"] = true,
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-2706.719727, -2843.710449, -3.968750),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-2706.719727, -2843.710449, -3.968750),
            Mins = Vector(-350, -300, 0),
            Maxs = Vector(350, 300, 100),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName(
            "trigger_tower",
            function(ent)
                -- Fail safe in case one decides to kill his allies.
                ent:Fire("AddOutput", "OnTrigger plaza_exit_relay,Trigger,,40,-1")
            end
        )
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT