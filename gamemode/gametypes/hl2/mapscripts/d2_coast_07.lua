if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items_maker"] = true
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        if GAMEMODE:GetPreviousMap() == "d2_coast_08" then
            --- 3304.103271 5262.621094 1536.031250
            local checkpointTransfer = GAMEMODE:CreateCheckpoint(Vector(3304.103271, 5262.621094, 1536.031250), Angle(0, 90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpointTransfer)

            ents.WaitForEntityByName("village_squad", function(ent)
                ent:Fire("ForceSpawn")
            end)

            ents.WaitForEntityByName("assault_trigger", function(ent)
                ent:Fire("Enable")
            end)
        end

        -- -1074.218628 9386.666016 1664.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-1469.086060, 9136.386719, 1666.920044), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(-1074.218628, 9386.666016, 1664.031250), Angle(0, 0, 0), Vector(-150, -305, 0), Vector(150, 305, 200))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(-1375.794800, 9251.247070, 1665.878174), Angle(0, -90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        --[[
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(3302.857178, 5274.505859, 1536.031250), Angle(0, 180, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(3302.857178, 5274.505859, 1536.031250),
            Angle(0, 0, 0),
            Vector(-150, -80, 0),
            Vector(150, 80, 100)
        )
        checkpointTrigger2.OnTrigger = function()
            GAMEMODE:SetVehicleCheckpoint(Vector(1950.889160, 6521.036621, 1538.650757), Angle(0.372, 3.839, 1.433))
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end
        ]]
        -- The game isnt over if someone falls down, we clear the outputs and just kill the player.
        for _, v in pairs(ents.FindByName("fall_trigger")) do
            v:ClearOutputs()

            v.OnTrigger = function(_, activator)
                if activator:IsVehicle() then
                    local driver = activator:GetDriver()

                    if IsValid(driver) and driver:Alive() then
                        driver:Kill()
                    end

                    local passengerSeat = activator:GetNWEntity("PassengerSeat")

                    if IsValid(passengerSeat) then
                        local passenger = passengerSeat:GetDriver()

                        if IsValid(passenger) and passenger:Alive() then
                            passenger:Kill()
                        end
                    end

                    -- If someone shoves the vehicle down it would be lost forever.
                    activator:Remove()
                elseif activator:IsPlayer() and activator:Alive() then
                    activator:Kill()
                end
            end
        end

        -- Lets make sure its closed.
        ents.WaitForEntityByName("bridge_door_1", function(ent)
            ent:Fire("Close")
        end)

        -- Workaround: Make sure we let the dropship fly off, atm theres lua way to tell the contents of a specific model shape.
        -- 3031.886963 5218.268066 1532.155762
        local hackTrigger1 = ents.Create("trigger_once")
        hackTrigger1:SetupTrigger(Vector(3031.886963, 5218.268066, 1532.155762), Angle(0, 0, 0), Vector(-150, -80, 0), Vector(150, 80, 100))

        hackTrigger1.OnTrigger = function()
            TriggerOutputs({{"dropship", "Activate", 0.0, ""}})
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT