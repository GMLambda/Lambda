if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_pistol",
        "weapon_rpg",
        "weapon_357",
        "weapon_crowbar",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_smg1",
    },
    Ammo = {
        ["AR2"] = 60,
        ["Buckshot"] = 18,
        ["Grenade"] = 5,
        ["SMG1"] = 90,
        ["SMG1_Grenade"] = 1,
        ["AR2AltFire"] = 2,
        ["RPG_Round"] = 3,
        ["Pistol"] = 54,
        ["357"] = 12,
        ["XBowBolt"] = 9,
    },
    Armor = 30,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["door_silo_lab_3"] = {"Close"},
    ["door_launchbunker_exit_a"] = {"Close"}
}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["startitems"] = true,
    ["brush_launchbunker_exit_a"] = true,
}
MAPSCRIPT.GlobalStates = {}
MAPSCRIPT.Checkpoints = {}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- 1. elevator wait and parented checkpoint
    local elev_cp = GAMEMODE:CreateCheckpoint(Vector(-376, -2180, -1559), Angle(0, 90, 0))
    ents.WaitForEntityByName("tracktrain_elevator", function(ent)
        elev_cp:SetParent(ent)
    end)

    ents.WaitForEntityByName("trigger_elevator_go_down", function(ent)
        ent:SetKeyValue("teamwait", "1")
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(elev_cp, activator)
        end
    end)

    -- 2. elevator wait and parented checkpoint
    local elev2_cp = GAMEMODE:CreateCheckpoint(Vector(1821, -2506, -1165), Angle(0, 0, 0))
    ents.WaitForEntityByName("lift_1", function(ent)
        elev2_cp:SetParent(ent)
    end)

    ents.WaitForEntityByName("trigger_start_lift_1", function(ent)
        ent:SetKeyValue("teamwait", "1")
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(elev2_cp, activator)
        end
    end)

    -- TODO: Fix final cutscene .... lets try.... UNFINISHED 
    ents.WaitForEntityByName("cvehicle.hangar", function(ent)
        for i = 1, game.MaxPlayers() do
            local seat = ents.Create("prop_vehicle_choreo_generic")
            seat:SetName("cvehicle.hangar_" .. tostring(i))
            seat:SetPos(ent:GetPos())
            seat:SetAngles(ent:GetAngles())
            seat:SetParent(ent)
            seat:SetKeyValue("vehiclescript", "scripts/vehicles/choreo_vehicle_ep2_hangar.txt")
            seat:SetKeyValue("VehicleLocked", "1")
            seat:SetModel(ent:GetModel())
            seat:Spawn()
        end
    end)

    local autoParent = ents.Create("logic_auto")
    autoParent:Fire("AddOutput", "OnMapSpawn cvehicle.hangar,SetParentAttachment,vehicle_driver_eyes,0.1,-1")

    local function GetNextVehicle()
        local vehicles = ents.FindByName("cvehicle.hangar_*")
        for _, v in pairs(vehicles) do
            local driver = v:GetInternalVariable("m_hPlayer")
            if IsValid(driver) == false then return v end
        end
    end

    GAMEMODE:WaitForInput("cvehicle.hangar", "EnterVehicle", function(ent)
        for k, v in pairs(player.GetAll()) do
            if v:Alive() == false then continue end
            local vehicle = GetNextVehicle()
            if IsValid(vehicle) then
                v:EnterVehicle(vehicle)
            end
        end

        return true
    end)
end

return MAPSCRIPT