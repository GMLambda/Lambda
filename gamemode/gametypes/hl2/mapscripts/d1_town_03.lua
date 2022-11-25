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
    },
    Ammo =
    {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 3,
        ["Grenade"] = 1,
        ["Buckshot"] = 12,
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
    ["startobjects_template"] = true,
}

function MAPSCRIPT:PostInit()

    if SERVER then

        -- FIX #73: If we are starting at 03 we have to correct the blockades since prev is 02 and next is 02.
        if GAMEMODE.IsChangeLevel == false then 

            for k,v in pairs(ents.FindByClass("trigger_changelevel")) do
                
                if v.Landmark == "d1_town_03_02" then 
                    v:SetBlocked(false)
                elseif v.Landmark == "d1_town_02_03" then 
                    v:SetBlocked(true)
                end

            end

        end 

        -- The player gets stuck here, so we just put something there so it wont happen.
        --
        ents.CreateSimple("prop_physics", {
            Model = "models/props_debris/concrete_chunk02b.mdl",
            Pos = Vector(-3128.362549, -1026.139160, -3604.878906),
            Ang = Angle(2.362, -13.966, 9.108),
            MoveType = MOVETYPE_NONE,
            SpawnFlags = SF_PHYSPROP_MOTIONDISABLED,
            Flags = FL_STATICPROP,
        })

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
