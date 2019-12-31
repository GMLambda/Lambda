AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {

    },
    Ammo =
    {

    },
    Armor = 0,
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
    --["spawnitems_template"] = true,
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:Init()

        ents.WaitForEntityByName("viewcontrol", function(ent)
            ent:SetKeyValue("spawnflags", "140")
        end)

                ents.WaitForEntityByName("viewcontrol_outro", function(ent)
            ent:SetKeyValue("spawnflags", "140")
        end)

    DbgPrint("-- Mapscript: Cosmonaut08 loaded --")

end

function MAPSCRIPT:PostInit()

    if SERVER then

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
