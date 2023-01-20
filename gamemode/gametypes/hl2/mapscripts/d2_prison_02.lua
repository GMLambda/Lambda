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
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true
}

MAPSCRIPT.GlobalStates = {
    ["antlion_allied"] = GLOBAL_ON
}

function MAPSCRIPT:PostInit()
    ents.WaitForEntityByName("door_2", function(ent)
        ent:Fire("Unlock")
    end)

    if SERVER then
        --setpos -1384.557129 2894.679688 448.031250;setang -1.010203 -63.622845 0.000000
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-1384.557129, 2894.679688, 384.031250), Angle(0, 45, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(-1384.557129, 2894.679688, 384.031250), Angle(0, 0, 0), Vector(-100, -130, 0), Vector(50, 100, 200))

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- cp 2 setpos -1951.139526 2554.889893 576.031250;setang 6.475924 -93.248947 0.000000
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-1951.139526, 2554.889893, 576.031250), Angle(0, 45, 0))
        checkpoint2:SetVisiblePos(Vector(-1950.105469, 2715.927734, 512.031250))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(Vector(-1952.149292, 2550.710938, 512.023621), Angle(0, 0, 0), Vector(-100, -250, 0), Vector(100, 250, 200))

        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT