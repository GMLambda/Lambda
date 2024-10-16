if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_357",
        "weapon_crowbar",
        "weapon_frag",
        "weapon_pistol",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_smg1",
        "weapon_shotgun",
    },
    Ammo = {
        ["Pistol"] = 18,
        ["XBowBolt"] = 4,
        ["AR2"] = 30,
        ["Buckshot"] = 30,
        ["Grenade"] = 3,
        ["357"] = 6,
        ["SMG1"] = 90,
    },
    Armor = 45,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems"] = true,
    ["velsensor_car_superjump_01"] = true,
    ["velsensor_car_superjump_00"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- Checkpoint before heli fight area
    local containerCP = GAMEMODE:CreateCheckpoint(Vector(-998, 1096, 96))
    ents.WaitForEntityByName("trigger_enter_box", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(containerCP, activator)
        end
    end)
end

function MAPSCRIPT:OnJalopyCreated(jalopy)
    local companionController = ents.Create("lambda_vehicle_companion")
    local name = "lambda_vc_" .. tostring(jalopy:EntIndex())
    companionController:SetName(name)
    companionController:SetPos(jalopy:GetPos())
    companionController:SetKeyValue("CompanionName", "alyx")
    companionController:SetParent(jalopy)
    companionController:Spawn()

    jalopy:ClearAllOutputs("PlayerOff")
    jalopy:ClearAllOutputs("PlayerOn")

    jalopy:Fire("AddOutput", "PlayerOn " .. name .. ",OnPlayerVehicleEnter,,0,-1")
    jalopy:Fire("AddOutput", "PlayerOff " .. name .. ",OnPlayerVehicleExit,,0,-1")
end

return MAPSCRIPT