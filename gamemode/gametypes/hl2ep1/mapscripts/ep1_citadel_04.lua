AddCSLuaFile()
local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.DefaultLoadout = 
{
    Weapons = {
        "weapon_physcannon"
    },
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = 
{
    ["global_newgame_template_base_items"] = true,
}

MAPSCRIPT.GlobalStates =
{
    ["super_phys_gun"] = GLOBAL_ON,
}

function MAPSCRIPT:PostInit()

    if SERVER then

        local multipleTrigger = ents.FindByPos(Vector(3424, 12808, 3696), "trigger_multiple")
        for k, v in pairs(multipleTrigger) do
            v:Remove()
        end
        
        local doorCloseTrigger = ents.Create("trigger_once")
        doorCloseTrigger:SetupTrigger(
            Vector(3424, 12808, 3696),
            Angle(0, 0, 0),
            Vector(-208, -472, -96),
            Vector(208, 472, 96)
        )
        doorCloseTrigger:SetKeyValue("teamwait", "1")
        doorCloseTrigger:SetKeyValue("showwait", "0")
        doorCloseTrigger:Fire("AddOutput", "OnTrigger trigger_alyx_close_airlock,Enable,0.0,-1")
        doorCloseTrigger.OnTrigger = function(_, activator)
            local checkpoint = GAMEMODE:CreateCheckpoint(Vector(3424, 13184, 3604))
            GAMEMODE:SetPlayerCheckpoint(checkpoint, activator)
        end

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(3400, 11723, 3616), Angle(0, 0, 0))
        ents.WaitForEntityByName("trigger_player_closedoor", function(ent) 
            ent:SetKeyValue("teamwait", "1")
            ent.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
            end
        end)

        ents.WaitForEntityByName("trigger_stalkercar_inside", function(ent)
            ent:SetKeyValue("teamwait", "1")
        end)
        
    end
    
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

return MAPSCRIPT