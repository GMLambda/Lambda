AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons = {},
    Ammo = {},
    Armor = 30,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
    ["station_cop_2"] = { "Kill" },
    ["station_cop_1"] = { "Kill" },
    ["station_cop_4"] = { "Kill" },
    ["rappeller_cop_2_maker"] = { "Spawn" },
    ["rappeller_cop_2_maker_2"] = { "Spawn" },
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["player_spawn_items"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        -- Make sure the door is there and lock it.
        local transition_door = ents.FindFirstByName("transition_door")
        if not IsValid(transition_door) then
            transition_door = ents.Create("prop_door_rotating")
            transition_door:SetPos(Vector(-9943.000000, -3970.000000, 374.000000))
            transition_door:SetAngles(Angle(0, -90, 0))
            transition_door:SetModel("models/props_c17/door01_left.mdl")
            transition_door:SetSkin(5)
            transition_door:Spawn()
            transition_door:Activate()
        end
        transition_door:Fire("close")
        transition_door:Fire("lock")

        -- Fix barney beeing strict about standing infront of him
        local scriptCond_seeBarney = ents.FindFirstByName("scriptCond_seeBarney")
        scriptCond_seeBarney:SetKeyValue("PlayerActorFOV", "-1")
        scriptCond_seeBarney:SetKeyValue("PlayerTargetLOS", "3")

        -- Lets lift up the spawn a little, theres some invisible object that gets players stuck inside.
        local spawns = ents.FindByClass("info_player_start")
        for k,v in pairs(spawns) do
            local pos = v:GetPos()
            v:SetPos(pos + Vector(0,0,5))
        end

        -- Lets automatically scale some enemies.
        -- -7871.712891 -1510.040405 -63.968754
        local maker1 = ents.Create("npc_template_maker")
        maker1:SetPos(Vector(-8490.908203, -2256.173096, -63.968750))
        maker1:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
        maker1:SetKeyValue("StartDisabled", "1")
        maker1:SetKeyValue("TemplateName", "chaser_cop_1")
        maker1:SetKeyValue("MaxNPCCount", "2")
        maker1:SetKeyValue("MaxLiveChildren", "2")
        maker1:SetKeyValue("SpawnFrequency", "0.2")
        maker1:SetKeyValue("Radius", "800")
        maker1:Spawn()

        -- -8038.701660 -2541.850098 -63.968746
        local maker2 = ents.Create("npc_template_maker")
        maker2:SetPos(Vector(-8038.701660, -2541.850098, -63.968746))
        maker2:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
        maker2:SetKeyValue("StartDisabled", "1")
        maker2:SetKeyValue("TemplateName", "chaser_cop_1")
        maker2:SetKeyValue("MaxNPCCount", "2")
        maker2:SetKeyValue("MaxLiveChildren", "2")
        maker2:SetKeyValue("SpawnFrequency", "0.2")
        maker2:SetKeyValue("Radius", "800")
        maker2:Spawn()

        local maker3 = ents.Create("npc_template_maker")
        maker3:SetPos(Vector(-6699.455078, -1714.247314, -63.968750))
        maker3:SetKeyValue("spawnflags", SF_NPCMAKER_HIDEFROMPLAYER + SF_NPCMAKER_ALWAYSUSERADIUS)
        maker3:SetKeyValue("StartDisabled", "1")
        maker3:SetKeyValue("TemplateName", "chaser_cop_1")
        maker3:SetKeyValue("MaxNPCCount", "2")
        maker3:SetKeyValue("MaxLiveChildren", "2")
        maker3:SetKeyValue("SpawnFrequency", "0.2")
        maker3:SetKeyValue("Radius", "800")
        maker3:Spawn()

        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-8169.935059, -3181.270508, 192.031250), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-8169.935059, -3181.270508, 192.031250),
            Angle(0, 0, 0),
            Vector(-50, -50, 0),
            Vector(50, 50, 70)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
            maker1:Fire("Enable")
            maker2:Fire("Enable")
            maker3:Fire("Enable")
        end

        local inputEnt = ents.Create("lambda_entity")
        inputEnt:SetName("lambda_crowbar")
        inputEnt.AcceptInput = function(s, input, caller, activator, param)
            if input == "AddCrowbar" then
                local loadout = GAMEMODE:GetMapScript().DefaultLoadout
                loadout.HEV = true
                table.insert(loadout.Weapons, "weapon_crowbar")
                table.insert(loadout.Weapons, "weapon_lambda_medkit")
                s:Remove()
            end
        end
        inputEnt:Spawn()

        ents.WaitForEntityByName("lcs_crowbar_intro", function(ent)
            ent:Fire("AddOutput", "OnCompletion lambda_crowbar,AddCrowbar,,0.0,-1")
        end)

        local headcrabMaker = ents.Create("npc_maker")
        headcrabMaker:SetPos(Vector(-9627.166992, -3429.462891, 340.428101))
        headcrabMaker:SetAngles(Angle(0, 100, 0))
        headcrabMaker:SetKeyValue("NPCType", "npc_headcrab")
        headcrabMaker:SetKeyValue("StartDisabled", "1")
        headcrabMaker:SetName("lambda_headcrab_maker")
        headcrabMaker:Spawn()

        local crate = ents.Create("prop_physics")
        crate:SetPos(Vector(-9627.166992, -3429.462891, 340.428101))
        crate:SetAngles(Angle(0, 100, 0))
        crate:SetModel("models/props_junk/wood_crate002a.mdl")
        crate:Spawn()
        crate:SetHealth(100)
        local physObj = crate:GetPhysicsObject()
        if IsValid(physObj) then
            physObj:SetMass(500)
        end
        crate:CallOnRemove("Broke", function()
            headcrabMaker:SetPos(crate:GetPos())
            headcrabMaker:SetAngles(crate:GetAngles())
            headcrabMaker:Fire("Spawn")
        end)

        local medkit = ents.Create("weapon_lambda_medkit")
        medkit:SetPos(Vector(-8176.953613, -3195.601563, 233.364426))
        medkit:SetAngles(Angle(0, -148.108, 0))
        medkit:Spawn()

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
