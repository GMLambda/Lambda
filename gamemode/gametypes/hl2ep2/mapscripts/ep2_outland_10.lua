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

    -- Find trigger_once at 3448 -384 0.05
    local triggerAmbush = ents.FindByPos(Vector(3448.000000, -384.000000, 0.050000), "trigger_once")
    if #triggerAmbush == 0 then
        ErrorNoHalt("Warning: Could not find trigger_once at 3448 -384 0.05")
    else
        triggerAmbush = triggerAmbush[1]
        triggerAmbush:SetKeyValue("targetname", "lambda_trigger_ambush")
        triggerAmbush:Input("Disable")
        triggerAmbush:SetupTrigger(
            Vector(3398, -610, -133),
            Angle(0, 0, 0),
            Vector(-900, -430, -100),
            Vector(250, 350, 300)
        )
        print("Disabling")
    end

    -- Area for players to wait for the real ambush.
    local actualAmbushTrigger = ents.Create("trigger_once")
    actualAmbushTrigger:SetupTrigger(
        Vector(3398, -610, -133),
        Angle(0, 0, 0),
        Vector(-900, -430, -100),
        Vector(250, 350, 300)
    )
    actualAmbushTrigger:SetKeyValue("StartDisabled", "1")
    actualAmbushTrigger:SetKeyValue("targetname", "lambda_trigger_ambush_wait")
    actualAmbushTrigger:SetKeyValue("teamwait", "1")
    actualAmbushTrigger:Fire("AddOutput", "OnTrigger lambda_trigger_ambush,Enable,,0,-1")

    -- Create trigger that starts the first combine shield.
    local triggerStartShield = ents.Create("trigger_once")
    triggerStartShield:SetupTrigger(
        Vector(3448.000000, -384.000000, 0.050000),
        Angle(0, 0, 0),
        Vector(-130, -100, -100),
        Vector(200, 100, 100)
    )
    triggerStartShield:Fire("AddOutput", "OnTrigger relay_combineshieldwall1_on,Trigger,,0,-1")
    triggerStartShield:Fire("AddOutput", "OnTrigger combine_generator_idleon_wav,PlaySound,,0,-1")
    triggerStartShield:Fire("AddOutput", "OnTrigger lambda_trigger_ambush_wait,Enable,,0,-1")
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