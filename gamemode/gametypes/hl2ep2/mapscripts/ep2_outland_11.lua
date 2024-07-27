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
        "weapon_357",
        "weapon_shotgun",
        "weapon_smg1",
        "weapon_ar2",
        "weapon_crossbow",
    },
    Ammo = {
        ["Pistol"] = 20,
        ["357"] = 6,
        ["Buckshot"] = 18,
        ["SMG1"] = 45,
        ["SMG1_Grenade"] = 3,
        ["AR2"] = 30,
        ["Grenade"] = 3,
        ["XBowBolt"] = 4,
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["door_silo_lab_4"] = {"Close"},
    ["brush_pclip_door_silo_lab_4"] = {"Enable"}
}

MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["trigger_unlock_ele"] = true,
    ["npcclip_alyx_hall_1"] = true
}

MAPSCRIPT.GlobalStates = {}

MAPSCRIPT.Checkpoints = {
    {   -- Silo entrance
        Pos = Vector(1490, -9934, -316),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(1514, -9936, -249),
            Mins = Vector(-75, -75, -65),
            Maxs = Vector(75, 75, 65)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Remove triggers that close doors
    for k, v in pairs(ents.FindByName("trigger_dog_walk")) do
        v:Remove()
    end
    for k, v in pairs(ents.FindByName("trigger_closegarage")) do
        v:Remove()
    end

    ents.WaitForEntityByName("trigger_gunschool", function(ent)
        ent:SetKeyValue("StartDisabled", "0")
    end)

    ents.WaitForEntityByName("trigger_start_entry_01", function(ent)
        ent:SetKeyValue("StartDisabled", "0")
    end)

    -- Elevator 1
    local elevcp = GAMEMODE:CreateCheckpoint(Vector(412, -9936, 60))
    ents.WaitForEntityByName("lift_1", function(ent)
        elevcp:SetParent(ent)
    end)

    ents.WaitForEntityByName("trigger_start_lift_1", function(ent)
        ent:SetKeyValue("teamwait", "1")
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(elevcp, activator)
        end
    end)

    -- Elevator no. 2
    local elevcp2 = GAMEMODE:CreateCheckpoint(Vector(1344, -9936, -561))
    ents.WaitForEntityByName("lift_2", function(ent)
        elevcp2:SetParent(ent)
    end)

    local elevTrigger = ents.Create("trigger_once")
    elevTrigger:SetupTrigger(Vector(1324, -9936, -541), Angle(0, 0, 0), Vector(-45, -56, -73), Vector(45, 56, 73))
    elevTrigger:SetName("trigger_unlock_ele")
    elevTrigger:SetKeyValue("teamwait", "1")
    elevTrigger:Fire("AddOutput", "OnTrigger button_ele_2,Unlock,,0,-1")
    elevTrigger.OnTrigger = function(_, activator)
        GAMEMODE:SetPlayerCheckpoint(elevcp2, activator)
    end
end

return MAPSCRIPT