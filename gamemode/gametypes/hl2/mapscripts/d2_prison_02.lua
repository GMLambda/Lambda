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
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["antlion_allied"] = GLOBAL_ON
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-1384.557129, 2894.679688, 384.031250),
        Ang = Angle(0, 45, 0),
        Trigger = {
            Pos = Vector(-1384.557129, 2894.679688, 384.031250),
            Mins = Vector(-100, -130, 0),
            Maxs = Vector(50, 100, 200),
        }
    },
    {
        Pos = Vector(-1951.139526, 2554.889893, 576.031250),
        Ang = Angle(0, 45, 0),
        VisiblePos = Vector(-1950.105469, 2715.927734, 512.031250),
        Trigger = {
            Pos = Vector(-1952.149292, 2550.710938, 512.023621),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 200),
        }
    },
}

function MAPSCRIPT:PostInit()
    ents.WaitForEntityByName(
        "door_2",
        function(ent)
            ent:Fire("Unlock")
        end
    )
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT
--DbgPrint("PostPlayerSpawn")