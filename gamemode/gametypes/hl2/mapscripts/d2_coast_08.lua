if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items"] = true
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.RemoveByClass("info_player_start")
        local crossbow_added = false

        local newPlayerSpawn = ents.Create("info_player_start")
        newPlayerSpawn:SetPos(Vector(3328.9, 5241.59, 1536.1))
        newPlayerSpawn:SetAngles(Angle(0, -90, 0))
        newPlayerSpawn:SetKeyValue("spawnflagas", "1") -- master
        newPlayerSpawn:Spawn()

        local cp1 = GAMEMODE:CreateCheckpoint(Vector(3122.5, 988.9, 1480.1), Angle(0, -90, 0))
        cp1:SetRenderPos(Vector(3343.7, 956.5, 1480.1))
        local cp1Trigger = ents.Create("trigger_multiple")
        cp1Trigger:SetupTrigger(
            Vector(3343.7, 956.5, 1480.1),
            Angle(0, 0, 0),
            Vector(-250, -60, 0),
            Vector(250, 60, 580)
        )

        cp1Trigger.OnTrigger = function(_, activator)
            cp1Trigger:Input("Disable")
            GAMEMODE:SetPlayerCheckpoint(cp1, activator)
            -- Add crossbow to loadout
            if crossbow_added == false then
                local loadout = GAMEMODE:GetMapScript().DefaultLoadout
                table.insert(loadout.Weapons, "weapon_crossbow")
                crossbow_added = true
                DbgPrint("Added crossbow to loadout")
            end
        end

        local cp2 = GAMEMODE:CreateCheckpoint(Vector(3257, -2004, 1551.6), Angle(0, -90, 0))
        local cp2Trigger = ents.Create("trigger_once")
        cp2Trigger:SetupTrigger(
            Vector(3257, -2004, 1551.6),
            Angle(0, 0, 0),
            Vector(-70, -60, 0),
            Vector(70, 60, 80)
        )
        cp2Trigger.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp2, activator)
        end

        local cp4 = GAMEMODE:CreateCheckpoint(Vector(3331.41, -2021.9, 1792.1), Angle(0, 90, 0))
        cp4:AddEffects(EF_NODRAW)
        local cp4Trigger = ents.Create("trigger_once")
        cp4Trigger:SetupTrigger(
            Vector(3331.41, -2021.9, 1792.1),
            Angle(0, 0, 0),
            Vector(-70, -70, 0),
            Vector(70, 70, 80)
        )

        cp4Trigger:KeyValue("StartDisabled", "1")
        cp4Trigger.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp4, activator)
            if IsValid(cp1) then
                cp1:Reset()
            end
            if IsValid(cp1Trigger) then
                cp1Trigger:Fire("Enable")
            end
        end

        local cp3 = GAMEMODE:CreateCheckpoint(Vector(2849.5, -3522.9, 1920.1), Angle(0, 0, 0))
        cp3:AddEffects(EF_NODRAW)
        local cp3Trigger = ents.Create("trigger_once")
        cp3Trigger:SetupTrigger(
            Vector(2849.5, -3522.9, 1920.1),
            Angle(0, 0, 0),
            Vector(-30, -30, 0),
            Vector(230, 30, 80)
        )

        cp3Trigger.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(cp3, activator)
            if IsValid(cp4Trigger) then
                cp4:RemoveEffects(EF_NODRAW)
                cp4Trigger:Fire("Enable")
            end
        end

        GAMEMODE:WaitForInput("button_trigger", "Use", function()
            GAMEMODE:EnablePreviousMap()
        end)

        -- Resize the trigger_transition volume, its too small so the gunship can sometimes
        -- get lost when its not killed.
        ents.WaitForEntityByName("landmark_d2_coast_07-08", function(ent)
            if ent:GetClass() == "trigger_transition" then
                ent:ResizeTriggerBox(
                    Vector(-1060, -560, 0),
                    Vector(6560, 8560, 3060)
                )
            end
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT