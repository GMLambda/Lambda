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
}

MAPSCRIPT.EntityFilterByName =
{
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        ents.RemoveByClass("trigger_once", Vector(-5504, -5636, 30))

        -- setpos -497.127838 29.422707 576.030090;setang 1.708000 -178.566528 0.000000
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-5478.429688, -5604.233887, -3.968750), Angle(0, 90, 0))
        local checkpointTrigger1 = ents.Create("trigger_multiple")
        checkpointTrigger1:SetupTrigger(
            Vector(-7763.793945, -6373.333496, 10.588013),
            Angle(0, 0, 0),
            Vector(-3400, -1050, -100),
            Vector(2200, 1750, 300)
        )
        checkpointTrigger1.OnEndTouchAll = function(trigger)
            TriggerOutputs({
                {"relationship_soldiers_vs_dog_like", "RevertRelationship", 0, ""},
                {"pclip_gate1", "Enable", 0, ""},
                {"lcs_dog_nag_door_loop1", "Cancel", 0, ""},
                {"lcs_dog_nag_door_loop1", "Kill", 0.10, ""},
                {"relationship_soldiers_vs_dog_hate", "ApplyRelationship", 0.20, ""},
                {"logic_dropshipStart", "Trigger", 1.00, ""},
                {"ss_dog_ThruGate", "BeginSequence", 2.50, ""},
                {"sound_dog_surprised_1", "PlaySound", 4.00, ""},
                {"sound_dog_roar_1", "PlaySound", 6.00, ""},
            })
            trigger:Remove()
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
        end

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
