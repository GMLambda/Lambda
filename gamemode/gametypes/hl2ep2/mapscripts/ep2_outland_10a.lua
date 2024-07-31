if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_pistol",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_357",
        "weapon_frag",
        "weapon_physcannon",
        "weapon_rpg",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["AR2"] = 60,
        ["Buckshot"] = 18,
        ["Grenade"] = 3,
        ["SMG1"] = 90,
        ["SMG1_Grenade"] = 1,
        ["AR2AltFire"] = 1,
        ["RPG_Round"] = 3,
        ["Pistol"] = 54,
        ["357"] = 6,
        ["XBowBolt"] = 4,
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