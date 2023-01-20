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

MAPSCRIPT.InputFilters = {
    ["sniper1"] = {"Kill"},
    ["sniper2"] = {"Kill"}
}

MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items_maker"] = true
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- 7099.762695 6237.561523 0.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(7405.353516, 6305.318848, 0.031250), Angle(0, 180, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(7099.762695, 6237.561523, 0.031250), Angle(0, 0, 0), Vector(-130, -130, 0), Vector(130, 130, 100))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- 6000.681641 6446.313477 96.031250
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(6000.681641, 6446.313477, 96.031250), Angle(0, 0, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(Vector(6000.681641, 6446.313477, 96.031250), Angle(0, 0, 0), Vector(-130, -130, 0), Vector(130, 130, 100))

        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end
        --[[
        ents.WaitForEntityByName("sniper1", function(ent)
            ent:SetName("lambda_sniper1")
        end)

        ents.WaitForEntityByName("sniper2", function(ent)
            ent:SetName("lambda_sniper2")
        end)

        ents.WaitForEntityByName("sniper3", function(ent)
            ent:SetName("lambda_sniper3")
        end)

        ents.WaitForEntityByName("sniper4", function(ent)
            ent:SetName("lambda_sniper4")
        end)

        ents.WaitForEntityByName("sniper5", function(ent)
            ent:SetName("lambda_sniper5")
        end)
        ]]
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT