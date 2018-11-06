AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
        "weapon_physcannon",
        "weapon_frag",
        "weapon_shotgun",
        "weapon_ar2",
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
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
    --["test_name"] = true,
    ["player_spawn_items"] = true,
    ["invulnerable"] = true,
}

MAPSCRIPT.ImportantPlayerNPCNames =
{
    ["citizen_b_regular_original"] = true,
    ["rocketman"] = true,
    ["gatekeeper"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        ents.WaitForEntityByName("citizen_b_regular_original", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("rocketman", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("gatekeeper", function(ent)
            ent:SetHealth(100)
        end)

        ents.WaitForEntityByName("killed_critical_npc", function(ent)
            ent:SetName("killed_critical_npc_2")
        end)

        ents.WaitForEntityByName("rocketman", function(ent)
            ent:Fire("AddOutput", "OnDeath killed_critical_npc_2,ShowMessage,0") -- Use one with no delay.
        end)

        GAMEMODE:WaitForInput("spawner_rpg", "ForceSpawn", function(ent)

            local entityData = game.FindEntityInMapData("rpg_weapon")
            local pos = util.StringToType(entityData["origin"], "Vector")
            local ang = util.StringToType(entityData["angles"], "Angle")

            local newRPG = ents.Create("weapon_rpg")
            newRPG:SetPos(pos)
            newRPG:SetAngles(ang)
            newRPG:Spawn()

            TriggerOutputs({
                {"first_train_rl", "Trigger", 0.0, ""},
                {"train_horn", "PlaySound", 0.0, ""},
                {"template_rpg", "Kill", 0.0, ""},
                {"spawner_rpg", "Kill", 0.1, ""},
            })

            return true -- Suppress

        end)

        local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-5971.663574, 3534.091064, 269.338867), Ang = Angle(4.653, 55.612, 0.000) })
        if not IsValid(checkpoint1) then
            DbgError("Unable to create checkpoint")
        end

        GAMEMODE:WaitForInput("spypost_template", "ForceSpawn", function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
            GAMEMODE:SetVehicleCheckpoint(Vector(-5811.580566, 3605.574463, 257.262878), Angle(0, 0, 0))
        end)

        local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(6494.825195, 4199.202637, 260.031250), Ang = Angle(0, 0, 0) })
        if not IsValid(checkpoint2) then
            DbgError("Unable to create checkpoint")
        end
        GAMEMODE:WaitForInput("aisc_pre_ingreeterrange", "Enable", function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
            GAMEMODE:SetVehicleCheckpoint(Vector(6610.592285, 4405.477539, 264.207794), Angle(0.091, -121.466, 0.363))
        end)

        GAMEMODE:WaitForInput("gunship_spawner_2", "Spawn", function(ent)
            ent:RemoveTemplateData("OnDeath")
            ent:AddTemplateData("squadname", "lambda_gunships")
            ent:SetKeyValue("SpawnFrequency", "10")
            ent:Enable()
            ent.OnAllSpawnedDead = function(ent)
                TriggerOutputs({
                    {"ag_siren", "StopSound", 0.0, ""},
                    {"lr_radioloop", "Disable", 0.0, ""},
                    {"citizen_standoff", "Kill", 0.0, ""},
                    {"aigf_combat", "Kill", 0.0, ""},
                    {"aisc_odessapostgunship", "Enable", 0.0, ""},
                    {"lr_squad_follow_*", "Kill", 0.0, ""},
                    {"post_gunship_jeep_relay*", "Enable", 0.0, ""},
                    {"aigf_odessapostgunship*", "Activate", 0.10, ""},
                    {"ss_post**", "BeginSequence", 2.00, ""},
                    {"gunshipdown_music*", "PlaySound", 3.00, ""},
                })
            end
            return true
        end)


    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
