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
        "weapon_shotgun",
        "weapon_ar2",
        "weapon_rpg",
        "weapon_crossbow",
        "weapon_bugbait",
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
        ["XBowBolt"] = 4,
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
    ["strider2"] = { "Kill" },
    ["relay_wallDrop"] = { "Trigger" },
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["player_spawn_items"] = true,
    ["escape_attempt_killtrigger"] = true,
    ["ss_dog_drop"] = true,
    ["bigdestroy1_fade"] = true,
    ["bigdestroy2_fade"] = true,
    ["bigdestroy3_fade"] = true,
    ["damagefilter_barney"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(5895.568359, -1049.733887, -127.968750), Angle(0, -180, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(5629.913086, -1056.541016, -127.968750),
            Angle(0, 0, 0),
            Vector(-200, -300, 0),
            Vector(400, 150, 100)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- 5949.389648 125.043320 0.031250
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(5961.045898, 43.669514, 0.031250), Angle(0, -180, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(5949.389648, 125.043320, 0.031250),
            Angle(0, 0, 0),
            Vector(-20, -120, 0),
            Vector(20, 120, 100)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end


        -- 5077.874512 405.469330 -3.968750
        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(5366.176758, 302.146027, 0.031250), Angle(0, 90, 0))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(5077.874512, 405.469330, -3.968750),
            Angle(0, 0, 0),
            Vector(-250, -120, 0),
            Vector(400, 320, 200)
        )
        checkpointTrigger3.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3, activator)
        end

        -- Make sure they are only used once.
        ents.WaitForEntityByName("bigdestroy1_relay", function(ent)
            ent:Fire("AddOutput", "OnTrigger !self,Kill,,0.1,-1")
        end)
        ents.WaitForEntityByName("bigdestroy2_relay", function(ent)
            ent:Fire("AddOutput", "OnTrigger !self,Kill,,0.1,-1")
        end)
        ents.WaitForEntityByName("bigdestroy3_relay", function(ent)
            ent:Fire("AddOutput", "OnTrigger !self,Kill,,0.1,-1")
        end)

        -- Last resort.
        local striderCounter = ents.Create("math_counter")
        striderCounter:SetKeyValue("targetname", "lambda_strider_counter")
        striderCounter:SetKeyValue("max", "2")
        striderCounter:SetKeyValue("StartDisabled", "0")
        striderCounter:Fire("AddOutput", "OnHitMax bigdestroy1_relay,Trigger,,0.0,-1")
        striderCounter:Fire("AddOutput", "OnHitMax bigdestroy2_relay,Trigger,,0.0,-1")
        striderCounter:Fire("AddOutput", "OnHitMax bigdestroy3_relay,Trigger,,0.0,-1")
        striderCounter:Spawn()

        ents.WaitForEntityByName("strider1", function(ent)
            ent:Fire("AddOutput", "OnDeath lambda_strider_counter,Add,1,0.0,-1")
        end)
        ents.WaitForEntityByName("strider2", function(ent)
            ent:Fire("AddOutput", "OnDeath lambda_strider_counter,Add,1,0.0,-1")
        end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
