if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_pistol",
        "weapon_357",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["lambda_health"] = 1,
        ["357"] = 6,
        ["AR2"] = 60,
        ["Grenade"] = 3,
        ["Buckshot"] = 18,
        ["Pistol"] = 18,
        ["XBowBolt"] = 4,
        ["SMG1"] = 90,
    },
    Armor = 45,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")
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