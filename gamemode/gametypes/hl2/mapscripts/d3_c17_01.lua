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

MAPSCRIPT.InputFilters = {
    ["doors_elevator_2"] = {"Close"},
    ["doors_elevator_1"] = {"Close"},
    ["timer_nag_leave_1"] = {"Kill"},
    ["logic_nag_leave_1"] = {"Kill"}
}

MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["trigger_closeTPDoor"] = true,
    ["teleport_screenoverlay_Kleiner_1"] = true
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-497.127838, 29.422707, 512.03009),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-497.127838, 29.422707, 576.030090),
            Mins = Vector(-100, -250, 0),
            Maxs = Vector(100, 250, 200),
        }
    },
}

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName(
            "kleiner",
            function(ent)
                ent:SetHealth(100)
            end
        )
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT