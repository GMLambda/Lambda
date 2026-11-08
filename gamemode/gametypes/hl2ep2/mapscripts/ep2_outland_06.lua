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
        "weapon_shotgun",
        "weapon_smg1",
        "weapon_357",
        "weapon_frag",
    },
    Ammo = {
        ["SMG1"] = 45,
        ["Buckshot"] = 6,
        ["Pistol"] = 18,
        ["Grenade"] = 3,
        ["357"] = 6,
        ["SMG1_Grenade"] = 1,
    },
    Armor = 15,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["goo_pit3_ladder_relay"] = {"Trigger"}
}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_physcannon"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_local_items"] = true,
    ["trigger_goopit3_ladder_up"] = true, -- remove all fall related stuff
    ["trigger_goopit3_ladder_down"] = true,
    ["trigger_goopit3_hurt"] = true
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(737, 480, 101), -- 2
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(600, 506, 156),
            Mins = Vector(-4, -56, -60),
            Maxs = Vector(4, 56, 60)
        }
    },
    {
        Pos = Vector(731, 2040, 101), -- 4
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(728, 1988, 128),
            Mins = Vector(-40, -60, -40),
            Maxs = Vector(40, 60, 40)
        }
    },
    {
        Pos = Vector(2848, 1358, -280), -- 8
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(2873, 1314, -258),
            Mins = Vector(-42, -122, -16),
            Maxs = Vector(42, 122, 16)
        }
    },
}

local VEHICLE_PIECES = {
    { Mdl = "models/vehicle/vehicle_engine_block.mdl", Pos = Vector(0, 0.7, 0.4) },
    { Mdl = "models/props_vehicles/carparts_wheel01a.mdl", Pos = Vector(-0.85, 0.6, 0.2) },
    { Mdl = "models/props_vehicles/carparts_wheel01a.mdl", Pos = Vector(0.85, 0.6, 0.2) },
    { Mdl = "models/props_vehicles/carparts_tire01a.mdl", Pos = Vector(-0.85, -0.6, 0.2) },
    { Mdl = "models/props_vehicles/carparts_tire01a.mdl", Pos = Vector(0.85, -0.6, 0.2) },
    { Mdl = "models/props_vehicles/carparts_door01a.mdl", Pos = Vector(-0.95, 0, 0.45) },
    { Mdl = "models/props_vehicles/carparts_axel01a.mdl", Pos = Vector(0, -0.6, 0.15) },
    { Mdl = "models/props_vehicles/carparts_muffler01a.mdl", Pos = Vector(-0.3, -0.9, 0.1) },
}

function MAPSCRIPT:PostInit()
    local alyxMayEnterVehicle = false
    GAMEMODE:WaitForInput("jeep", "UnlockEntrance", function()
        alyxMayEnterVehicle = true
    end)

    GAMEMODE:WaitForInput("alyx", "EnterVehicle", function()
        if alyxMayEnterVehicle == false then return true end
    end)

    ents.WaitForEntityByName("trigger_alyxChoreoArrive06", function(ent)
        ent.OnTrigger = function()
            local loadout = GAMEMODE:GetMapScript().DefaultLoadout
            table.insert(loadout.Weapons, "weapon_ar2")
        end
    end)

    -- triggers actually have names on this map, lets make use of that for checkpoints
    local cp1 = GAMEMODE:CreateCheckpoint(Vector(331, 506, 785))
    ents.WaitForEntityByName("bldg1_trigger", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp1, activator)
        end
    end)

    local cp3 = GAMEMODE:CreateCheckpoint(Vector(1874, 1079, -123))
    ents.WaitForEntityByName("alyx_sniperGuide00", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp3, activator)
        end
    end)

    local cp5 = GAMEMODE:CreateCheckpoint(Vector(22, 3296, -114))
    ents.WaitForEntityByName("trigger_warehouse_noisesInTheDark", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp5, activator)
        end
    end)

    local cp6 = GAMEMODE:CreateCheckpoint(Vector(1118, 2798, -252))
    ents.WaitForEntityByName("trigger_startspawn_goopit1", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp6, activator)
        end
    end)

    local cp7 = GAMEMODE:CreateCheckpoint(Vector(1904, 2032, -282))
    ents.WaitForEntityByName("zombieTrigger_topofPipeHeadCrabs", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp7, activator)
        end
    end)

    local cp9 = GAMEMODE:CreateCheckpoint(Vector(3961, 2340, 637))
    ents.WaitForEntityByName("autoSave_beforeJeep", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp9, activator)
        end
    end)

    local cp10 = GAMEMODE:CreateCheckpoint(Vector(-400, 2344, 693))
    ents.WaitForEntityByName("trigger_alyxComeDownToJeep", function(ent)
        ent.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp10, activator)
        end
    end)

    for _, piece in ipairs(VEHICLE_PIECES) do
        util.PrecacheModel(piece.Mdl)
    end

    local function SpawnVehiclePieces(vehicle, center)
        local mins = vehicle:OBBMins()
        local maxs = vehicle:OBBMaxs()
        local mid = (mins + maxs) * 0.5
        local half = (maxs - mins) * 0.5
        local vehicleVel = vehicle:GetVelocity()
        local vehicleAng = vehicle:GetAngles()
        for _, piece in ipairs(VEHICLE_PIECES) do
            local localPos = Vector(mid.x + half.x * piece.Pos.x, mid.y + half.y * piece.Pos.y, mins.z + (maxs.z - mins.z) * piece.Pos.z)
            local worldPos = vehicle:LocalToWorld(localPos)
            local prop = ents.Create("prop_physics")
            prop:SetModel(piece.Mdl)
            prop:SetPos(worldPos)
            prop:SetAngles(vehicleAng)
            prop:Spawn()
            prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
            local phys = prop:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(vehicleVel + (worldPos - center):GetNormalized() * 350 + Vector(0, 0, 250))
                phys:AddAngleVelocity(VectorRand() * 300)
            end
        end
    end

    local function ExplodeFallenVehicle(vehicle)
        if not IsValid(vehicle) or vehicle.LambdaFallExploded == true then return end
        vehicle.LambdaFallExploded = true
        local pos = vehicle:WorldSpaceCenter()
        local explosion = ents.Create("env_explosion")
        explosion:SetPos(pos)
        explosion:SetKeyValue("iMagnitude", "0")
        explosion:Spawn()
        local occupants = {vehicle:GetDriver(), GAMEMODE:VehicleGetPassenger(vehicle)}
        for i = 1, 2 do
            local ply = occupants[i]
            if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
                ply:SetArmor(0)
                local dmgInfo = DamageInfo()
                dmgInfo:SetDamage(100000)
                dmgInfo:SetDamageType(bit.bor(DMG_BLAST, DMG_VEHICLE))
                dmgInfo:SetDamagePosition(pos)
                dmgInfo:SetAttacker(game.GetWorld())
                dmgInfo:SetInflictor(explosion)
                ply:TakeDamageInfo(dmgInfo)
            end
        end

        explosion:Fire("Explode")
        SpawnVehiclePieces(vehicle, pos)
        vehicle:Remove()
    end

    ents.WaitForEntityByName("fall_trigger", function(ent)
        ent:Fire("AddOutput", "OnTrigger !self,LambdaFallExplode,,1,-1")
    end)

    GAMEMODE:WaitForInput("fall_trigger", "LambdaFallExplode", function(_, _, activator)
        ExplodeFallenVehicle(activator)
        return true
    end)
end

return MAPSCRIPT
