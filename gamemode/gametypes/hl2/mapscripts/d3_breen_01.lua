AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        --"weapon_physcannon",
    },
    Ammo =
    {
    },
    Armor = 60,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
    ["env_fade"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["sprite_breen_blast_1"] = true, -- Visible thru walls.
}

MAPSCRIPT.GlobalStates =
{
    ["super_phys_gun"] = GLOBAL_ON,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        DbgPrint("Startup")

        self.AllowPhyscannon = false
        self.SpawnInPod = true
        self.Pods = {}

        ents.WaitForEntityByName("pod", function(ent)

            -- Replicate this one for each player.
            for i = 1, game.MaxPlayers() do
                
                local pod = ents.Create(ent:GetClass())
                pod:SetPos(ent:GetPos())
                pod:SetAngles(ent:GetAngles())
                pod:SetParent(ent)
                pod:SetModel(ent:GetModel())
                pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_podTooLoud.txt")
                pod:SetNoDraw(true)
                pod:DrawShadow(false)
                pod:Spawn()
                pod:Activate()
                pod:SetName("pod")

                table.insert(self.Pods, pod)
            end

            table.insert(self.Pods, ent)

        end)

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
            trigger:SetupTrigger(
                Vector(-1056.175659, 490.913574, 1271.527832),
                Angle(0, 0, 0),
                Vector(-80, -80, 0),
                Vector(80, 50, 200)
            )
            trigger:Disable()
            trigger:CloneOutputs(ent)
            trigger:SetName("Trigger_lift_control")
            trigger.OnTrigger = function(_, activator)
                GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
                self.AllowPhyscannon = true
            end
            ent:Remove()
        end)

        ents.RemoveByClass("npc_combine_s", Vector(-2298.000000, 334.000000, 576.031250))
    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    if self.SpawnInPod == true then
        
        util.RunDelayed(function()
            for _,v in pairs(self.Pods) do
                if IsValid(v:GetDriver()) == false then
                    ply:ExitVehicle()
                    ply:EnterVehicle(v)
                    break
                end
            end
        end, CurTime() + 0.1)

    end

    if self.AllowPhyscannon == true then
        ply:Give("weapon_physcannon")
    end

end

return MAPSCRIPT
