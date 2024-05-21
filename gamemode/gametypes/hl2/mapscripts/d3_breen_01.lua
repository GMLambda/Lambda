if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {},
    Ammo = {},
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["pod"] = {"EnterVehicleImmediate"}
}

MAPSCRIPT.EntityFilterByClass = {
}

MAPSCRIPT.EntityFilterByName = {
    ["citadel_template_combinewall_start1"] = true,
    ["trigger_gameover_toplevelfallmessage"] = true,
    ["trigger_gameover_toplevelfallhurt"] = true,
    ["relay_riftcleanup"] = true
}

MAPSCRIPT.GlobalStates = {
    ["super_phys_gun"] = GLOBAL_ON
}

function MAPSCRIPT:PostInit()
    if SERVER then
        DbgPrint("Startup")
        self.AllowPhyscannon = false
        self.SpawnInPod = true
        self.Pods = {}

        GAMEMODE:WaitForInput("logic_playerExitPod", "Trigger", function()
            self.SpawnInPod = false
            local cp = GAMEMODE:CreateCheckpoint(Vector(-2173.593018, 847.748901, 576.031250), Angle(0, -45, 0))
            GAMEMODE:SetPlayerCheckpoint(cp, nil)
        end)

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-1965.112183, 24.634741, 578.822021), Angle(0, -90, 0))

        ents.WaitForEntityByName("Train_lift", function(ent)
            checkpoint1:SetParent(ent)
        end)

        ents.WaitForEntityByName("trigger_player_Breenelevator", function(ent)
            ent:SetKeyValue("teamwait", "1")

            ent.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
            end
        end)

        local inputEnt = ents.Create("lambda_entity")
        inputEnt:SetName("lambda_physcannon")

        inputEnt.AcceptInput = function(s, input, caller, activator, param)
            if input == "AddPhyscannon" then
                DbgPrint("Adding physcannon")
                table.insert(GAMEMODE:GetMapScript().DefaultLoadout.Weapons, "weapon_physcannon")
                s:Remove()
                s.AcceptInput = function() end
            end
        end

        inputEnt:Spawn()

        ents.WaitForEntityByName("w_physgun", function(ent)
            ent:Fire("AddOutput", "OnPlayerPickup lambda_physcannon,AddPhyscannon,,0.0,-1")
        end)

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-1059.245605, 455.159790, 1302.171143), Angle(0, -90, 0))

        ents.WaitForEntityByName("Train_lift_TP", function(ent)
            checkpoint2:SetParent(ent)
        end)

        ents.WaitForEntityByName("Trigger_lift_control", function(ent)
            local trigger = ents.Create("trigger_once")
            trigger:SetKeyValue("teamwait", "1")
            trigger:SetupTrigger(Vector(-1056.175659, 490.913574, 1271.527832), Angle(0, 0, 0), Vector(-80, -80, 0), Vector(80, 50, 200))
            trigger:Disable()
            trigger:CloneOutputs(ent)
            trigger:SetName("Trigger_lift_control")

            trigger.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
                self.AllowPhyscannon = true
            end

            ent:Remove()
        end)

        local breenchair = ents.FindByModel("models/props_combine/breenchair.mdl")

        for _, v in ipairs(breenchair) do
            v:SetPos(Vector(-1972.93, 836.43, 591.45))
            v:SetAngles(Angle(0.04, -89.85, 0.04))

            -- Make sure it's asleep.
            local phys = v:GetPhysicsObject()
            if IsValid(phys) then
                phys:Sleep()
            end
        end

        ents.WaitForEntityByName("pod", function(ent)
            local podParent = ent:GetParent()
            local parentAttachment = ent:GetParentAttachment()
            DbgPrint("Pod parent: " .. tostring(podParent))

            local podPos = ent:GetPos()
            local podAng = ent:GetAngles()
            local podMdl = ent:GetModel()
            table.insert(self.Pods, ent)

            local function initPod(pod)
                pod:SetNotSolid(true)
                pod:SetPos(podPos)
                pod:SetAngles(podAng)
                pod:SetModel(podMdl)
                pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_podTooLoud.txt")
                pod:DrawShadow(false)
                pod:SetNoDraw(true)
                pod:SetName("pod")
                pod:SetParent(podParent, parentAttachment)
            end

            -- Insert the ones we transitioned.
            for _, v in pairs(ents.FindByName("lambda_pod_*")) do
                DbgPrint("Merging pod " .. tostring(v) .. " with " .. tostring(ent))
                initPod(v)
                table.insert(self.Pods, v)
            end

            -- Create pods for empty player slots.
            for i = 1, game.MaxPlayers() - #self.Pods do
                local pod = ents.Create(ent:GetClass())
                initPod(pod)
                pod:Spawn()
                pod:Activate()
                table.insert(self.Pods, pod)
            end
        end)

        local podExitTeleport = ents.Create("point_teleport")
        podExitTeleport:SetKeyValue("target", "!players")
        podExitTeleport:SetName("lambda_pod_teleport")
        podExitTeleport:SetPos(Vector(-1875, 887, 627))
        podExitTeleport:SetAngles(Angle(0, 265, 0))
        podExitTeleport:Spawn()

        ents.WaitForEntityByName("blackout_viewcontroller", function(ent)
            ent:SetKeyValue("spawnflags", "188")
        end)

        ents.WaitForEntityByName("view_gman_end_1", function(ent)
            ent:SetKeyValue("spawnflags", "188")
        end)

        ents.WaitForEntityByName("viewcontrol_lamarr", function(ent)
            ent:SetKeyValue("spawnflags", "140")
        end)

        ents.WaitForEntityByName("relay_breenwins", function(ent)
            ent:Fire("AddOutput", "OnTrigger fade_breen_wins,RestartRound,GAMEOVER_TIMER,5.50,-1")
        end)

        ents.WaitForEntityByName("message_breenwins", function(ent)
            ent:SetKeyValue("spawnflags", "2") -- All players
        end)

        ents.RemoveByClass("npc_combine_s", Vector(-2298.000000, 334.000000, 576.031250))
        local changeLevel = ents.Create("trigger_changelevel")
        changeLevel:SetKeyValue("map", "d1_trainstation_01")
        changeLevel:SetKeyValue("StartDisabled", "1")
        changeLevel:SetKeyValue("spawnflags", tostring(SF_CHANGELEVEL_RESTART))
        changeLevel:SetName("lambda_changelevel")
        changeLevel:SetPos(Vector(0, 0, 0))
        changeLevel:Spawn()

        ents.WaitForEntityByName("credits", function(ent)
            ent:Fire("AddOutput", "OnCreditsDone lambda_changelevel,ChangeLevel,,10,-1")
        end)

        -- Increase the delay for the pod exit as it looks otherwise strange.
        ents.WaitForEntityByName("logic_playerExitPod", function(ent)
            ent:ClearAllOutputs()
            ent:Fire("AddOutput", "OnTrigger pod,Open,,0.0,-1")
            ent:Fire("AddOutput", "OnTrigger pod,Unlock,,2.65,-1")
            ent:Fire("AddOutput", "OnTrigger pod,ExitVehicle,,2.75,-1")
        end)

        -- Replace physgun_soldier with the weapon_physcannon.
        local function ReplacePhyscannon(ent)
            local newGun = ents.Create("weapon_physcannon")
            -- Make sure no player can ever pick this up.
            newGun.CreatedForPlayer = newGun
            newGun:SetPos(ent:GetPos())
            newGun:SetAngles(ent:GetAngles())
            newGun:SetSolid(SOLID_NONE)
            newGun:SetSolidFlags(FSOLID_NOT_SOLID)
            newGun:SetParent(ent)
            newGun:SetTrigger(false)
            newGun:Spawn()
            newGun:DrawShadow(false)
            ent:SetRenderMode(RENDERMODE_NONE)
        end

        ents.WaitForEntityByName("physgun_soldier", function(ent)
            ReplacePhyscannon(ent)
        end)

        -- Replace the physgun_breen with the weapon_physcannon.
        ents.WaitForEntityByName("physgun_breen", function(ent)
            ReplacePhyscannon(ent)
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    if self.AllowPhyscannon == true then
        ply:Give("weapon_physcannon")
    end

    if self.SpawnInPod == true and IsValid(ply:GetVehicle()) == false then
        DbgPrint("Player " .. tostring(ply) .. " has no vehicle, setting into empty pod...")

        for _, v in pairs(self.Pods) do
            if IsValid(v:GetDriver()) == false then
                DbgPrint("Putting player into vehicle " .. tostring(v))
                ply:EnterVehicle(v)
                break
            end
        end
    end
end

return MAPSCRIPT
