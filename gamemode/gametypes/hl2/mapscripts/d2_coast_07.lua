if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
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
    ["player_spawn_items"] = true,
    ["fall_trigger"] = true,
    ["train_pusher"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        if GAMEMODE:GetPreviousMap() == "d2_coast_08" then
            --- 3304.103271 5262.621094 1536.031250
            local checkpointTransfer = GAMEMODE:CreateCheckpoint(Vector(3304.103271, 5262.621094, 1536.031250), Angle(0, 90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpointTransfer)
            GAMEMODE:SetVehicleCheckpoint(Vector(1227.954468, 6228.015137, 1531.526611), Angle(0, -90, 0))

            -- Not sure how this worked before and why did it break
            -- That button at the other side of the bridge in coast_08 sets a global state
            -- It also tries to fire these outputs, unsuccessfully
            -- gunship_trigger_10 disappears on transition back to 07 so it's best to trigger it when spawned
            if game.GetGlobalState("bridge_gate_open") == GLOBAL_ON then
                DbgPrint("Global state bridge_gate_open is ON")
                local returned = ents.Create("trigger_once")
                returned:SetupTrigger(Vector(3306, 5280, 1592), Angle(0, 0, 0), Vector(-242, -96, -55), Vector(242, 96, 55))
                -- Outputs from gunship_trigger_10 
                returned:Fire("AddOutput", "OnTrigger antspawner,Enable,,0,1")
                returned:Fire("AddOutput", "OnTrigger bridge_field_02,Disable,,0,1")
                returned:Fire("AddOutput", "OnTrigger gate_sprite,color,0 255 0,0,1")
                returned:Fire("AddOutput", "OnTrigger field_wall_poles,skin,1,0,1")
                returned:Fire("AddOutput", "OnTrigger field_trigger,Disable,,0,-1")
                returned:Fire("AddOutput", "OnTrigger forcefield3_sound_far,StopSound,,0,-1")
                returned:Fire("AddOutput", "OnTrigger return_cliff_fight_spawn,ForceSpawn,,0,1")
                returned:Fire("AddOutput", "OnTrigger zombie_blocker,Disable,,0,-1")
                returned:Fire("AddOutput", "OnTrigger forcefield3_sound_far,Kill,,0.1,-1")
                returned:Fire("AddOutput", "OnTrigger forcefield3_sound_close,Kill,,0.1,-1")
                -- Remove dropship and some assault triggers
                returned:Fire("AddOutput", "OnTrigger dropship,Kill,,0,-1")
                returned:Fire("AddOutput", "OnTrigger el_gimp,Kill,,0,-1")
                returned:Fire("AddOutput", "OnTrigger halt_guy,Kill,,0,-1")
                returned:Fire("AddOutput", "OnTrigger assault_trigger,Kill,,0,-1")
            end

            ents.WaitForEntityByName("village_squad", function(ent)
                ent:Fire("ForceSpawn")
            end)

            ents.WaitForEntityByName("assault_trigger", function(ent)
                ent:Fire("Enable")
            end)

            -- Workaround for a func_brush that has a white square when transitioning.
            ents.WaitForEntityByName("bridge_field_01", function(ent)
                ent:Remove()
            end)

            -- In case the gunship made it over set it to the right track which fails for some reason.
            ents.WaitForEntityByName("gunship", function(ent)
                ent:Fire("SetTrack", "path_a_22")
            end)
        end

        -- Better kill trigger, players would be stuck otherwise.
        local killTrigger1 = ents.Create("trigger_hurt")
        killTrigger1:SetupTrigger(
            Vector(0, 1180, 50),
            Angle(0, 0, 0),
            Vector(-8500, -8500, -180),
            Vector(8500, 8500, 180)
        )
        killTrigger1:SetKeyValue("damagetype", "32")
        killTrigger1:SetKeyValue("damage", "999999")
        killTrigger1:SetName("lambda_fall_trigger")

        -- -1074.218628 9386.666016 1664.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-1469.086060, 9136.386719, 1666.920044), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(-1074.218628, 9386.666016, 1664.031250), Angle(0, 0, 0), Vector(-150, -305, 0), Vector(150, 305, 200))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(-1375.794800, 9251.247070, 1665.878174), Angle(0, -90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

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

        -- Workaround: Make sure we let the dropship fly off, atm theres is no lua way to tell the contents of a specific model shape.
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