if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_physcannon"},
    Ammo = {},
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_local_items"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_ON
}

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName("citadel_trigger_elevatorride_up", function(elevatorTrigger)
            elevatorTrigger:SetKeyValue("teamwait", "1")

            ents.WaitForEntityByName("citadel_train_lift01_1", function(elevator)
                -- Checkpoint on elevator.
                local pos = elevator:GetPos()
                local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(262.721558, 803.862915, pos.z + 5), Angle(0, -180, 0))
                checkpoint1:SetParent(elevator)

                elevatorTrigger.OnTrigger = function(_, activator)
                    GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
                end
            end)
        end)

    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT