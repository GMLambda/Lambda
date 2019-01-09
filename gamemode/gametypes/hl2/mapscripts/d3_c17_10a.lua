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
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["player_spawn_items"] = true,
    ["lobby_frontdoors_counter"] = true, -- Use custom counter.
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        for _,v in pairs(ents.FindByName("steps_soldier_makers")) do
            v:SetKeyValue("DisableScaling", "1")
        end

        -- Adjust some logic to support npc scaling
        local newCounter = ents.Create("math_counter")
        newCounter:SetKeyValue("max", "3")
        newCounter:SetKeyValue("StartDisabled", "0")
        newCounter:SetKeyValue("targetname", "lambda_lobby_frontdoors_counter")
        newCounter:Fire("AddOutput", "OnHitMax atrium_securitydoors,Close,,4.0,-1")
        newCounter:Fire("AddOutput", "OnHitMax lobby_frontdoors_sounds,StopSound,,14.0,-1")
        newCounter:Spawn()

        for k,v in pairs(ents.FindByName("lobby_frontdoors_soldier_makers")) do
            v:Fire("AddOutput", "OnSpawnNPC lobby_frontdoors_assault,Activate,,0.05,-1")
            v:Fire("AddOutput", "OnSpawnNPC lobby_frontdoors_assault,BeginAssault,,0.50,-1")
            v:Fire("AddOutput", "OnAllSpawned lambda_lobby_frontdoors_counter,Add,1,0.0,-1")
        end

        -- Make sure the player spawns at the correct spot.
        local spawn = ents.Create("info_player_start")
        spawn:SetPos(Vector(-3936.260010, 6800.509766, 0.031250))
        spawn:SetAngles(Angle(0, 0, 0))
        spawn:SetKeyValue("spawnflags", "1")
        spawn:Spawn()

        -- -2672.437500 6479.918945 512.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-2672.437500, 6479.918945, 512.031250), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-2672.437500, 6479.918945, 512.031250),
            Angle(0, 0, 0),
            Vector(-60, -60, 0),
            Vector(60, 60, 100)
        )
        checkpointTrigger1.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

        -- -1404.743896 8211.465820 128.031250
        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(-1404.743896, 8211.465820, 128.031250), Angle(0, 0, 0))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(-1404.743896, 8161.465820, 128.031250),
            Angle(0, 0, 0),
            Vector(-60, -60, 0),
            Vector(60, 60, 100)
        )
        checkpointTrigger3.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3)
        end

    end

end

function MAPSCRIPT:OnMapTransition()

    DbgPrint("OnMapTransition")

    -- Make sure we have barney around.
    util.RunDelayed(function()
        local foundBarney = false
        for k,v in pairs(ents.FindByName("barney")) do
            foundBarney = true
            break
        end
        if foundBarney == false then
            ents.WaitForEntityByName("player_spawn_items_maker", function(ent)
                ent:Fire("ForceSpawn")
            end)
        end
    end, CurTime() + 0.1)

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
