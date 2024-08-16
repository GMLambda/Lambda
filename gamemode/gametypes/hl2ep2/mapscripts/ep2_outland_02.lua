if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_357",
        "weapon_shotgun",
        "weapon_pistol",
    },
    Ammo = {
    },
    Armor = 30,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems_template"] = true,
    ["elevator_player_clip"] = true,
    ["elevator_door_1_playerblocker"] = true,
    ["gman_start_player_clip"] = true,
}

MAPSCRIPT.ImportantPlayerNPCNames = {
    ["sheckley"] = true,
    ["griggs"] = true,
    ["vort"] = true
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-3189, -9255, -875),
        Ang = Angle(0, 0, 0),
        Condition = function()
            return GAMEMODE:GetPreviousMap() ~= "ep2_outland_04"
        end,
        WeaponAdditions = { "weapon_smg1" },
        Trigger = {
            Pos = Vector(-2031, -8637, -715),
            Mins = Vector(-150, -150, 0),
            Maxs = Vector(150, 150, 76)
        }
    },
}

function MAPSCRIPT:PostInit()
    if GAMEMODE:GetPreviousMap() == "ep2_outland_04" then
        -- Came from 04 by the elevator.
        ents.RemoveByClass("info_player_start")

        ents.WaitForEntityByName("elevator_model", function(ent)
            -- Attach the new start to the elevator.
            local newStart = ents.Create("info_player_start")
            newStart:SetPos(ent:LocalToWorld(Vector(-26.5, -1.5, 3)))
            newStart:SetAngles(Angle(0, 0, 0))
            newStart:AddSpawnFlags(1) -- Master
            newStart:Spawn()
            newStart:SetParent(ent)

            -- Make sure the vort exists, he wen't missing on play testing.
            local vorts = ents.FindByName("Vort")
            if #vorts == 0 then
                local vort = ents.Create("npc_vortigaunt")
                vort:SetPos(ent:LocalToWorld(Vector(22, 16.75, 1)))
                vort:SetAngles(Angle(0, 0, 0))
                vort:SetModel("models/vortigaunt_blue.mdl")
                vort:Spawn()
                vort:SetName("Vort")
            end
        end)

        local doorCloseFirst = false
        GAMEMODE:WaitForInput("elevator_door_1", "SetAnimation", function(_, _, _, _, param)
            if param == "close" and doorCloseFirst == false then
                -- Prevent the elevator from closing the first time.
                doorCloseFirst = true
                return true
            end
        end)

        -- Modify the extents of player_in_elevator_trigger and set teamwait
        ents.WaitForEntityByName("player_in_elevator_trigger", function(ent)
            ent:SetupTrigger(
                ent:GetPos(),
                Angle(0, 0, 0),
                Vector(-20, -45, -36),
                Vector(55, 45, 56)
            )
            ent:SetKeyValue("teamwait", "1")
        end)
    else
        -- The default spawn gets players stuck.
        for _, v in pairs(ents.FindByClass("info_player_start")) do
            if v:HasSpawnFlags(1) then -- Master
                v:SetPos(Vector(-2293.175537, -8260.166016, -497.381989))
            end
        end

        ents.WaitForEntityByName("trigger_turret2_vcd", function(ent)
            ent:Fire("AddOutput", "OnTrigger lambda_loadout_change,RunLua,,0,-1", "0.0")
        end)
    end

end

return MAPSCRIPT