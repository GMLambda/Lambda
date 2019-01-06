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
    ["player_items_template"] = true,
    ["pclip_gate1"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- 1448.796265 4695.322266 960.031250
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(917.399902, 4806.428223, 960.031250), Angle(0, 0, 0))
        checkpoint2:SetVisiblePos(Vector(1350.315063, 4729.931641, 960.031250))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(1448.796265, 4695.322266, 960.031250),
            Angle(0, 0, 0),
            Vector(-160, -40, 0),
            Vector(60, 40, 100)
        )
        checkpointTrigger2.OnTrigger = function(ent)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2)
        end

        ents.WaitForEntityByName("dropship_maker", function(ent)
            ent:Fire("AddOutput", "OnSpawnNPC !self,Kill,,0.0,-1")
        end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
