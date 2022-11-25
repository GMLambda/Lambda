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
    ["npc_cscanner"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["player_spawn_items"] = true,
    ["pclip_gate1"] = true,
    ["entry_ceiling_debris_1"] = true,
    ["entry_ceiling_debris_clip_1"] = true,
}

function MAPSCRIPT:PostInit()

    if SERVER then

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-4438.691406, 274.473907, -319.968750), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-4493.349121, 297.115906, -319.968750),
            Angle(0, 0, 0),
            Vector(-20, -20, 0),
            Vector(20, 20, 100)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- -4295.874023 430.960907 96.031250
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-4295.874023, 430.960907, 96.031250), Angle(0, 90, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-4295.874023, 430.960907, 96.031250),
            Angle(0, 0, 0),
            Vector(-20, -20, 0),
            Vector(20, 20, 100)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end

        -- UGH
        --- -5204.569824 -29.101088 0.031250
        local striderTrigger = ents.Create("trigger_once")
        striderTrigger:SetupTrigger(
            Vector(-5204.569824, -29.101088, 0.031250),
            Angle(0, 0, 0),
            Vector(-300, -300, 0),
            Vector(300, 300, 100)
        )

        striderTrigger:Fire("AddOutput", "OnTrigger tunnel_strider_1,DisableCrouchWalk,,0.0,-1")
        striderTrigger:Fire("AddOutput", "OnTrigger tunnel_strider_1,Stand,,0.0,-1")
        striderTrigger:Fire("AddOutput", "OnTrigger tunnel_strider_1,SetTargetPath,tunnel_strider_1_path_3,0.1,-1")
        striderTrigger:Fire("AddOutput", "OnTrigger tunnel_strider_1,SetCannonTarget,second_floor_beam_1_bullseye_1,0.1,-1")
    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
