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

        local triggers = ents.FindByPos(Vector(10624, 4592, -1664), "trigger_once")
        for _,v in pairs(triggers) do v:Remove() end

        triggers = ents.FindByPos(Vector(11880, 5888, -1672), "trigger_multiple")
        for _,v in pairs(triggers) do v:Remove() end

        triggers = ents.FindByPos(Vector(11176, 5888, -1672), "trigger_once")
        for _,v in pairs(triggers) do v:Remove() end

        ents.WaitForEntityByName("fade_out", function(ent)
            ent:SetKeyValue("spawnflags", "4") -- Activator only
            ent:SetKeyValue("holdtime", "9999") -- Make this long enough.
        end)

        -- Create better fade-out trigger.
        local fadeTrigger = ents.Create("trigger_multiple")
        fadeTrigger:SetupTrigger(
            Vector(11176, 5888, -1672),
            Angle(0, 0, 0),
            Vector(-90, -90, -50),
            Vector(150, 90, 100),
            true,
            SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES
        )
        fadeTrigger:Fire("AddOutput", "OnStartTouch fade_out,Fade,,0,-1")

        ents.WaitForEntityByName("player_track4", function(ent)
            
            local newTrack = ents.Create("path_track")
            newTrack:SetPos(ent:GetPos())
            newTrack:SetAngles(ent:GetAngles())
            newTrack:SetKeyValue("speed", "0")
            newTrack:SetKeyValue("orientationtype", "0")
            newTrack:SetKeyValue("target", "pod_bay_track1")
            newTrack:SetName("lambda_player_track4")
            newTrack:Spawn()
            newTrack:Activate()

            ent:Remove()
        end)

        ents.WaitForEntityByName("player_track2", function(ent)
            ent:Fire("AddOutput", "OnPass playerpod_ready_relay,Trigger,,0,-1")
        end)

        ents.WaitForEntityByName("player_track3", function(ent)
            ent:Fire("AddOutput", "OnPass playerpod_ready_relay,Trigger,,0,-1")
            ent:SetKeyValue("target", "lambda_player_track4")
            ent:Activate()
        end)

        ents.WaitForEntityByName("pod_bay_track9", function(ent)
            ent:Fire("EnableAlternatePath")
        end)

        -- Kick players out of vehicle
        local kickTrigger = ents.Create("trigger_multiple")
        kickTrigger:SetupTrigger(
            Vector(11776, 5888, -1672),
            Angle(0, 0, 0),
            Vector(-40, -90, -70),
            Vector(60, 90, 100),
            true,
            SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES
        )
        kickTrigger.OnStartTouch = function(s, ent)
            ent:ExitVehicle()
            ent:TeleportPlayer(Vector(12091.439453, 5889.092773, -1775.968750))
            ent:SetNoDraw(true)
        end

        -- Move changelevel trigger behind
        ents.RemoveByClass("trigger_changelevel")

        local changelevelTrigger = ents.Create("trigger_changelevel")
        changelevelTrigger:SetupTrigger(
            Vector(11776, 5888, -1672),
            Angle(0, 0, 0),
            Vector(-40, -90, -70),
            Vector(370, 90, 100)
        )
        changelevelTrigger:SetKeyValue("map", "d3_citadel_02")
        changelevelTrigger:SetKeyValue("landmark", "trans_cit01_cit02")

        ents.WaitForEntityByName("terd", function(ent)
            ent:Fire("SetDensity", "1.0")
            ent:SetKeyValue("spawnflags", "1")
            ent:SetKeyValue("ParticleDrawWidth", "800")
            ent:Activate()
        end)

        local test = ents.Create("env_lightglow")
        test:SetKeyValue("origin", "12064 5886 -1671")
        test:SetKeyValue("GlowProxySize", "128")
        test:SetKeyValue("HDRColorScale", ".6")
        test:SetKeyValue("HorizontalGlowSize", "700")
        test:SetKeyValue("VerticalGlowSize", "700")
        test:SetKeyValue("MaxDist", "1000")
        test:SetKeyValue("MinDist", "16")
        test:SetKeyValue("OuterMaxDist", "2000")
        test:SetKeyValue("rendercolor", "211 211 211")
        test:Spawn()
        test:Activate()

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
