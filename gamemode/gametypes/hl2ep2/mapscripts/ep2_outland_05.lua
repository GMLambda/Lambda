if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_frag",
        "weapon_357",
        "weapon_shotgun",
        "weapon_pistol",
        "weapon_smg1",
    },
    Ammo = {
        ["SMG1"] = 45,
        ["Buckshot"] = 6,
        ["Pistol"] = 18,
        ["Grenade"] = 3,
        ["357"] = 6,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems"] = true,
    ["player_on_trigger"] = true, -- elevator related trigger
    ["player_off_buildingtop_trigger"] = true -- best to remove this one
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-668, -440, 6),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-696, -1025, 424),
            Mins = Vector(-182, -2024, -444),
            Maxs = Vector(182, 2024, 444)
        }
    },
    {
        Pos = Vector(-256, 3840, 84),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-192, 4032, -8),
            Mins = Vector(-224, -265, -104),
            Maxs = Vector(224, 265, 104)
        }
    },
}

function MAPSCRIPT:PostInit()
    -- Redo elevator logic to wait for everyone
    local elevator
    ents.WaitForEntityByName("basket_brushes", function(ent)
        elevator = ent
    end)

    local elevatorWait = ents.Create("trigger_once")
    elevatorWait:SetupTrigger(Vector(660, 5760, 30), Angle(0, 0, 0), Vector(-52, -36, -20), Vector(52, 36, 20))
    elevatorWait:SetKeyValue("teamwait", 1)
    elevatorWait:AddOutput("OnTrigger", "player_branch", "SetValue", "1", 0.0, "-1")
    elevatorWait.OnTrigger = function(_, activator)
        local elevCP = GAMEMODE:CreateCheckpoint(Vector(656, 5760, 35))
        elevCP:SetParent(elevator)
        GAMEMODE:SetPlayerCheckpoint(elevCP, activator)
    end
end

return MAPSCRIPT