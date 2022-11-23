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
    },
    Ammo =
    {
        ["Pistol"] = 18,
    },
    Armor = 0,
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
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_pistol"] = true,
}

function MAPSCRIPT:PostInit()

    if SERVER then

        -- The map has two spawns both with the priority flag, so we gonna wipe them.
        for _,v in pairs(ents.FindByClass("info_player_start")) do
            DbgPrint("Removing start: " .. tostring(v))
            v:Remove()
        end
        -- And create a default one.
        local spawn = ents.CreateSimple("info_player_start", { Pos = Vector(2896, -2272, -604), Ang = Angle(0, 90, 0) })
        spawn.MasterSpawn = true

        ents.RemoveByClass("prop_physics", Vector(367, 70, -846.01397705078)) -- wooden plate shortcut

        -- -114.632774 -1179.170288 -847.968750

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-114.632774, -1179.170288, -847.968750), Angle(0, 90, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-114.632774, -1179.170288, -847.968750),
            Angle(0,0,0),
            Vector(-100, -100, 0),
            Vector(100, 100, 180)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end
    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
