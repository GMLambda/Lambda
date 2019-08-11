AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_lambda_hands",
        "weapon_lambda_medkit",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
        "weapon_physcannon",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_ar2",
        "weapon_rpg",
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["player_spawn_items"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-4118.057617, -12352.347656, 704.031250), Angle(0, 180, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-4097.192871, -12543.278320, 704.031250),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 280)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(-4308.972656, -12341.547852, 706.201477), Angle(0, 90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)

            TriggerOutputs({
                {"house_secondwave", "ForceSpawn", 0.0, ""},
                {"secondwave_assault", "Activate", 1.0, ""},
                {"secondwave_assault", "BeginAssault", 3.0, ""},
                {"house_secondwave", "Kill", 4.0, ""}, -- Don't trigger again
            })
        end

        -- The game isnt over if someone falls down, we clear the outputs and just kill the player.
        for _,v in pairs(ents.FindByName("fall_trigger")) do
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

        -- More npcs
        local maker1 = ents.Create("npc_maker")
        maker1:SetPos(Vector(-3408.264160, -203.868591, 1084.031250))
        maker1:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER)
        maker1:SetKeyValue("StartDisabled", "1")
        maker1:SetKeyValue("NPCType", "npc_combine_s")
        maker1:SetKeyValue("NPCSquadName", "gas_station_squad")
        --maker1:SetKeyValue("NPCHintGroup", "gas_station")
        maker1:SetKeyValue("additionalequipment", "weapon_shotgun")
        maker1:SetKeyValue("MaxNPCCount", "4")
        maker1:SetKeyValue("MaxLiveChildren", "2")
        maker1:SetKeyValue("SpawnFrequency", "2")
        maker1:Spawn()

        -- -4863.671875 -3216.657471 1088.031250
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-5365.758789, -3840.734619, 1082.535034), Angle(0, 0, 0))
        checkpoint2:SetVisiblePos(Vector(-4863.499512, -3219.710205, 1088.031250))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-4863.671875, -3216.657471, 1088.031250),
            Angle(0, 0, 0),
            Vector(-300, -50, 0),
            Vector(300, 50, 280)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetVehicleCheckpoint(Vector(-5233.240723, -3937.720459, 1105.934570), Angle(0, 55, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)

            maker1:Fire("Enable")
        end


    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
