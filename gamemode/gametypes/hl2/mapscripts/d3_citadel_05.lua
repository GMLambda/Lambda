AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_physcannon",
    },
    Ammo =
    {
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
    ["pod_ready_counter"] = { "Kill" },
    ["relay_playerpod_resume"] = { "Kill" },
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
    ["env_fade"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
}

MAPSCRIPT.GlobalStates =
{
    ["super_phys_gun"] = GLOBAL_ON,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        ents.WaitForEntityByName("citadel_trigger_elevatorride_up", function(ent)
            ent:SetKeyValue("teamwait", "1")
        end)

        ents.WaitForEntityByName("pod_02_track0", function(ent)
            ent:Fire("AddOutput", "OnPass pod_02_track_inspection,DisableAlternatePath,,0.0")
        end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
