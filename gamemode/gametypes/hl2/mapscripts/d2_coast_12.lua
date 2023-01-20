if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow", "weapon_bugbait"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
        ["XBowBolt"] = 4
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items_maker"] = true
}

MAPSCRIPT.GlobalStates = {
    ["antlion_allied"] = GLOBAL_ON
}

function MAPSCRIPT:PostInit()
    if SERVER then
        --3957.129150 -5952.989258 450.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(3957.129150, -5952.989258, 450.031250), Angle(0, 45, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(3652.347900, -5942.446777, 450.478577), Angle(0, 0, 0), Vector(-100, -250, 0), Vector(100, 250, 200))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- 2141.143555 -346.152466 672.031250
        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(2141.143555, -346.152466, 672.031250), Angle(0, 45, 0))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(Vector(2141.143555, -346.152466, 672.031250), Angle(0, 0, 0), Vector(-100, -250, 0), Vector(100, 250, 200))

        checkpointTrigger3.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint3, activator)
        end

        -- 4624.031250 4047.968750 848.031250
        local checkpoint5 = GAMEMODE:CreateCheckpoint(Vector(4624.031250, 4047.968750, 848.031250), Angle(0, 45, 0))
        checkpoint5:SetVisiblePos(Vector(4958.799805, 3682.813721, 848.031250))
        local checkpointTrigger5 = ents.Create("trigger_once")
        checkpointTrigger5:SetupTrigger(Vector(4900.396973, 3745.081543, 848.031250), Angle(0, 0, 0), Vector(-100, -250, 0), Vector(100, 250, 200))

        checkpointTrigger5.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint5, activator)
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT