AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons = {
        "weapon_lambda_hands",
    },
    Ammo = {},
    Armor = 30,
    HEV = false,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByName =
{
    ["terminal_side_police_goal"] = true,
}

MAPSCRIPT.EntityFilterByClass =
{
    ["env_global"] = true,
}

MAPSCRIPT.GlobalStates =
{
    ["gordon_precriminal"] = GLOBAL_OFF,
    ["gordon_invulnerable"] = GLOBAL_OFF,
    ["super_phys_gun"] = GLOBAL_OFF,
    ["antlion_allied"] = GLOBAL_OFF,
}

MAPSCRIPT.EntityRelationships =
{
    { Class1 = "npc_metropolice", Class2 = "player", Relation = D_NU, Rank = 99 },
    { Class1 = "npc_cscanner", Class2 = "player", Relation = D_NU, Rank = 99 },
    { Class1 = "npc_metropolice", Class2 = "npc_citizen", Relation = D_LI, Rank = 99 },
    { Class1 = "npc_strider", Class2 = "npc_citizen", Relation = D_LI, Rank = 99 },
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

        local cupcop_can = nil
        local cupcop = nil
        local cupcopSpeech =
        {
            "npc/combine_soldier/vo/sectorisnotsecure.wav",
            "npc/combine_soldier/vo/reaper.wav",
            "npc/combine_soldier/vo/stayalert.wav",
            "npc/combine_soldier/vo/ghost.wav",
            "npc/combine_soldier/vo/target.wav",
            "npc/combine_soldier/vo/visualonexogens.wav",
        }

        ents.WaitForEntityByName("cupcop_can", function(ent)
            cupcop_can = ent
        end)

        ents.WaitForEntityByName("cupcop", function(ent)
            cupcop = ent
        end)

        -- swing_seat_1
        -- -4674.464844 -3538.560059 25.073853
        -- models/nova/airboat_seat.mdl
        -- prop_vehicle_prisoner_pod
        local swing_seat_1 = ents.FindFirstByName("swing_seat_1")
        local seat_1 = ents.Create("prop_vehicle_prisoner_pod")
        seat_1:SetPos(Vector(-4674.464844, -3540, 25))
        seat_1:SetModel("models/nova/airboat_seat.mdl")
        seat_1:SetAngles(Angle(0, 180, 0))
        seat_1:SetCollisionGroup(COLLISION_GROUP_NONE)
        seat_1:SetParent(swing_seat_1)
        seat_1:SetNoDraw(true)
        seat_1:Spawn()

        local phys_seat_1 = seat_1:GetPhysicsObject()
        if IsValid(phys_seat_1) then
            phys_seat_1:SetMass(1)
        end

        -- swing_seat_2
        -- -4633.555664 -3542.251465 24.702568
        -- models/nova/airboat_seat.mdl
        -- prop_vehicle_prisoner_pod
        local swing_seat_2 = ents.FindFirstByName("swing_seat_2")
        local seat_2 = ents.Create("prop_vehicle_prisoner_pod")
        seat_2:SetPos(Vector(-4633.555664, -3540, 25))
        seat_2:SetModel("models/nova/airboat_seat.mdl")
        seat_2:SetCollisionGroup(COLLISION_GROUP_NONE)
        seat_2:SetAngles(Angle(0, 180, 0))
        seat_2:SetParent(swing_seat_2)
        seat_2:SetNoDraw(true)
        seat_2:Spawn()

        local phys_seat_2 = seat_2:GetPhysicsObject()
        if IsValid(phys_seat_2) then
            phys_seat_2:SetMass(1)
        end

        -- Why not..
        hook.Add("VehicleMove", "Lambda_SwingSeat", function(ply, vehicle, cmd)

            if vehicle ~= seat_1 and vehicle ~= seat_2 then
                return
            end

            local parent = vehicle:GetParent()
            local phys = parent:GetPhysicsObject()
            if IsValid(phys) then

                if cmd:KeyDown(IN_FORWARD) then
                    local fwd = vehicle:GetForward()
                    phys:ApplyForceCenter(fwd * 30)
                elseif cmd:KeyDown(IN_BACK) then
                    local fwd = vehicle:GetForward()
                    phys:ApplyForceCenter(-fwd * 30)
                end

            end

        end)

    end

end

return MAPSCRIPT
