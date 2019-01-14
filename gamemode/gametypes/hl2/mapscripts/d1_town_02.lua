AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_lambda_medkit",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
        "weapon_physcannon",
        "weapon_frag",
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 3,
        ["Grenade"] = 1,
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
    ["buildingD_roofhatch"] = { "Close" }, -- Never close it, it might close while players climb up and get stuck.
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["startobjects_template"] = true,
    ["damagefilter_monk"] = true,
    --["test_name"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- If we come from 03
        if GAMEMODE:GetPreviousMap() == "d1_town_03" then
            -- -3764.476807 -332.874481 -3327.968750
            local checkpointTransfer = GAMEMODE:CreateCheckpoint(Vector(-3764.476807, -332.874481, -3327.968750), Angle(0, 90, 0))
            GAMEMODE:SetPlayerCheckpoint(checkpointTransfer)

            -- If players fall they should rather die.
            local triggerHurt1 = ents.Create("trigger_hurt")
            triggerHurt1:SetupTrigger(
                Vector(-3212.359131, 344.832214, -3572.259033),
                Angle(0, 0, 0),
                Vector(-480, -500, 0),
                Vector(500, 780, 115)
            )
            triggerHurt1:SetKeyValue("damagetype", "32")
            triggerHurt1:SetKeyValue("damage", "200")

            -- Reposition path track so players can jump across.
            ents.WaitForEntityByName("churchtram_path_bottom", function(ent)
                ent:SetPos(Vector(-4506.009766, 964.507629, -2905.050537))
            end)

            -- Prevent players from going back.
            ents.WaitForEntityByName("returndoor", function(ent)
                ent:Fire("Close")
                -- Prevent trigger from opening it.
                ent:SetName("lambda_returndoor")
            end)

        end

        if GAMEMODE:GetPreviousMap() ~= "d1_town_03" then
            local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-1808.973267, 721.884277, -3071.968750), Angle(0, -180, 0))
            local checkpointTrigger1 = ents.Create("trigger_once")
            checkpointTrigger1:SetupTrigger(
                Vector(-1789.687012, 684.973572, -3071.968750),
                Angle(0, 0, 0),
                Vector(-50, -50, 0),
                Vector(50, 50, 70)
            )
            checkpointTrigger1.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
            end

            -- -2942.757324 895.897278 -3135.814697
            -- w = 128 (x)
            -- l = 95 (y)
            -- freightlift_lift
            local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-2948.138428, 887.582458, -3135.968750), Angle(0, -180, 0))
            local checkpointTrigger2 = ents.Create("trigger_once")
            checkpointTrigger2:SetupTrigger(
                Vector(-2942.757324, 895.897278, -3135.814697),
                Angle(0, 0, 0),
                Vector(-64, -45, 0),
                Vector(64, 45, 90)
            )
            checkpointTrigger2:SetKeyValue("teamwait", "1")
            checkpointTrigger2:Disable() -- Initially disabled, started by button.
            checkpointTrigger2.OnTrigger = function(_, activator)
                TriggerOutputs({
                    {"elevator_nodelink", "TurnOff", 10.0, ""},
                    {"freight_lift_down_relay", "Trigger", 0, ""},
                    {"freight_lift_button_2", "Lock", 0, ""},
                })
                ents.WaitForEntityByName("freightlift_lift", function(ent)
                    checkpoint2:SetParent(ent)
                end)
                GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
            end

            -- Replace the logic of that button.
            GAMEMODE:WaitForInput("freight_lift_button_2", "Use", function()
                if IsValid(checkpointTrigger2) then
                    checkpointTrigger2:Enable()
                end
                return true -- Suppress.
            end)
        else
            -- We spawn the monk in the second part sooner, players should not see him being spawned.
            -- -3396.734619 417.609131 -3327.968750
            local monkTrigger = ents.Create("trigger_once")
            monkTrigger:SetupTrigger(
                Vector(-3396.734619, 417.609131, -3327.968750),
                Angle(0, 0, 0),
                Vector(-64, -45, 0),
                Vector(64, 45, 90)
            )
            monkTrigger.OnTrigger = function()
                TriggerOutputs({
                    {"church_monk_maker", "Spawn", 0.0, ""},
                    {"church_monk_maker", "Disable", 0.0, ""},
                })
            end

            -- Reposition the awfully placed sounds.
            ents.WaitForEntityByName("bucket_machine_wav1", function(ent)
                ent:SetPos(Vector(-5022.800781, 596.170044, -3213.741211))
            end)

            ents.WaitForEntityByName("bucket_machine_wav2", function(ent)
                ent:SetPos(Vector(-5022.800781, 596.170044, -3213.741211))
            end)

            ents.WaitForEntityByName("bucket_machine_wav3", function(ent)
                ent:SetPos(Vector(-5022.800781, 596.170044, -3213.741211))
            end)

            local sparkEffect = ents.Create("lambda_entity")
            sparkEffect:DrawShadow(false)
            sparkEffect:SetNoDraw(true)
            sparkEffect:SetPos(Vector(-5022.800781, 596.170044, -3213.741211))
            sparkEffect:SetName("lambda_engine_break")
            sparkEffect:Spawn()
            sparkEffect.AcceptInput = function(e, name, activator, caller, data)
                if name == "BreakDown" then 
                    local effectdata = EffectData()
                    effectdata:SetOrigin( e:GetPos() )
                    util.Effect( "ElectricSpark", effectdata )

                    local effectdata = EffectData()
                    effectdata:SetOrigin( e:GetPos() )
                    util.Effect( "Explosion", effectdata )
                end
            end

            ents.WaitForEntityByName("churchtram_path_bottom", function(ent)
                ent:Fire("AddOutput", "OnPass lambda_engine_break,BreakDown,,0,-1")
                ent:Fire("AddOutput", "OnPass bucket_machine_wav1,StopSound,,0,-1")
                ent:Fire("AddOutput", "OnPass bucket_machine_wav2,StopSound,,0,-1")
                ent:Fire("AddOutput", "OnPass bucket_machine_wav3,StopSound,,0,-1")
            end)

            -- Checkpoints for part 2
            -- -4323.520996 1618.552734 -3135.968750
            local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(-4323.520996, 1618.552734, -3135.968750), Angle(0, -90, 0))
            checkpoint3:SetVisiblePos(Vector(-4171.976563, 1554.698975, -3135.968750))
            local checkpointTrigger3 = ents.Create("trigger_once")
            checkpointTrigger3:SetupTrigger(
                Vector(-4345.541504, 1502.828979, -3135.968750),
                Angle(0, 0, 0),
                Vector(-50, -50, 0),
                Vector(300, 150, 70)
            )
            checkpointTrigger3.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint3, activator)
            end

            local checkpoint4 = GAMEMODE:CreateCheckpoint(Vector(-4836.597168, 545.560608, -3263.968750), Angle(0, 90, 0))
            checkpoint4:SetVisiblePos(Vector(-4940.520996, 927.297485, -3263.968750))
            local checkpointTrigger4 = ents.Create("trigger_once")
            checkpointTrigger4:SetupTrigger(
                Vector(-5226.356445, 976.181213, -3263.959961),
                Angle(0, 0, 0),
                Vector(-350, -550, 0),
                Vector(580, 550, 170)
            )
            checkpointTrigger4.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint4, activator)
            end
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
