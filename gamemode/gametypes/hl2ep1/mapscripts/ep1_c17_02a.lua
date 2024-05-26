if SERVER then AddCSLuaFile() end
local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_physcannon", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_shotgun", "weapon_frag", "weapon_ar2", "weapon_crossbow"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Buckshot"] = 12,
        ["Grenade"] = 3,
        ["AR2"] = 50,
        ["SMG1_Grenade"] = 1,
        ["XBowBolt"] = 4
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_physcannon"] = true,
    ["global_newgame_spawner_shotgun"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_spawner_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_OFF
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(2015, 7469, -2539),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(2002, 7463, -2484),
            Mins = Vector(-106, -111, -64),
            Maxs = Vector(106, 111, 64)
        }
    },
    {
        Pos = Vector(-514, 7612, -2556),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-413, 7602, -2406),
            Mins = Vector(-117, -98, -64),
            Maxs = Vector(117, 98, 64)
        }
    },
    {
        Pos = Vector(-682, 8611, -2552),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-861, 8608, -2506),
            Mins = Vector(-92, -112, -70),
            Maxs = Vector(92, 112, 70)
        }
    },
    {
        Pos = Vector(-682, 9518, -2684),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(-852, 9522, -2590),
            Mins = Vector(-80, -95, -105),
            Maxs = Vector(80, 95, 105)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Ugly hack to get alyx to pickup the shotgun, no clue to why this is broken in Garry's Mod.
    local alyxPickupLogic = ents.Create("lambda_lua_logic")
    alyxPickupLogic:SetName("alyx_pickup_logic")
    alyxPickupLogic:Spawn()
    alyxPickupLogic.OnRunLua = function(s)
        local alyx = ents.FindFirstByName("alyx")
        if not IsValid(alyx) then
            -- Some whacko must have killed her.
            return
        end

        -- Get nearby shotguns.
        local shotguns = ents.FindInSphere(alyx:GetPos(), 256)
        for _, shotgun in pairs(shotguns) do
            if shotgun:GetClass() == "weapon_shotgun" and IsValid(shotgun:GetOwner()) == false then
                alyx:SetSaveValue("m_hTargetEnt", shotgun)
                alyx:SetSchedule(SCHED_NEW_WEAPON)
                break
            end
        end
    end

    ents.WaitForEntityByName("trigger_shotgun", function(ent)
        -- Normally the scripted sequences deals with this but it doesn't.
        ent:Fire("AddOutput", "OnTrigger alyx_pickup_logic,RunLua,,3,-1")
    end)
end
return MAPSCRIPT