AddCSLuaFile("cl_taunts.lua")

include("sh_taunts.lua")

util.AddNetworkString("PlayerStartTaunt")

local COMMANDABLE_CLASSES =
{
    ["npc_citizen"] = true,
}

local function GetNearbyAllies(ply)

    local playerPos = ply:GetPos()
    local boxMins = Vector(600, 600, 100)
    local boxMaxs = Vector(600, 600, 100)

    local nearbyEnts = ents.FindInBox(playerPos - boxMins, playerPos + boxMaxs)
    local res = {}
    for _,v in pairs(nearbyEnts) do
        if COMMANDABLE_CLASSES[v:GetClass()] ~= true then
            continue
        end
        if v:IsNPC() == false then
            continue
        end
        if v:GetNPCState() == NPC_STATE_SCRIPT then
            continue
        end
        if v:Visible(ply) == false then
            continue
        end
        if v:HasSpawnFlags(SF_CITIZEN_NOT_COMMANDABLE) == true then
            continue
        end
        if v:Disposition(ply) ~= D_LI then
            continue
        end
        table.insert(res, v)
    end

    return res

end

local function CommandAlliesToAttack(ply, target)

    if IsFriendEntityName(target:GetClass()) == false then
        return
    end

    local allies = GetNearbyAllies(ply)
    for _,v in pairs(allies) do
        v:SetEnemy(target)
        v:UpdateEnemyMemory(target, target:GetPos())
    end

end

local function CommandAlliesToPosition(ply, pos)

    local allies = GetNearbyAllies(ply)
    for _,v in pairs(allies) do
        v:ClearSchedule()
        v:SetLastPosition(pos)
        v:SetSchedule(SCHED_FORCED_GO_RUN)
    end

end

local function PlaceRunPointer(ply)

    local traceang = ply:EyeAngles()
    local playerPos = ply:EyePos()
    local tracelen = traceang:Forward() * 10000
    local filter = {ply}
    if ply:InVehicle() then
        table.insert(filter, ply:GetVehicle())
    end
    local trace = util.QuickTrace(playerPos, tracelen, filter)

    if trace.HitWorld or (IsValid(trace.Entity) and not trace.Entity:IsNPC()) then

        local effectdata = EffectData()
            effectdata:SetOrigin( trace.HitPos )
            effectdata:SetNormal( trace.HitNormal )
            effectdata:SetRadius(50)
        util.Effect( "lambda_pointer", effectdata, true )

        effectdata = EffectData()
            effectdata:SetOrigin( trace.HitPos )
            effectdata:SetStart( ply:GetShootPos() - Vector(0,0,5) )
            effectdata:SetAttachment( 1 )
            effectdata:SetEntity( ply )
        util.Effect( "ToolTracer", effectdata )

        CommandAlliesToPosition(ply, trace.HitPos)

    elseif IsValid(trace.Entity) and trace.Entity:IsNPC() then

        local npc = trace.Entity
        local isFriendly = IsFriendEntityName(npc:GetClass())
        if isFriendly == false then
            CommandAlliesToAttack(ply, npc)
        end

    end

end

local function PlaceRunPointerLocal(ply)

    local effectdata = EffectData()
        effectdata:SetOrigin( ply:GetPos() )
        effectdata:SetNormal( Vector(0,0,1) )
        effectdata:SetRadius(50)
    util.Effect( "lambda_pointer", effectdata, true )

    CommandAlliesToPosition(ply, ply:GetPos())

end

function GM:PlayPlayerTaunt(ply, category, tauntIndex)
    if ply:Alive() == false then
        return
    end

    local gender = ply:GetGender()
    local categoryId = category
    if not isnumber(categoryId) then
        categoryId = self:GetTauntCategoryId(category)
    end
    local taunts = self:GetTaunts(categoryId, gender)
    local taunt = taunts[tauntIndex]
    local snd = table.Random(taunt.Sounds)

    if taunt.Name == "Over here" then
        ply:SendLua[[RunConsoleCommand("act", "wave")]]
        PlaceRunPointerLocal(ply)
    elseif taunt.Name == "Over there" then
        ply:SendLua[[RunConsoleCommand("act", "forward")]]
        PlaceRunPointer(ply)
    elseif taunt.Name == "Scanners" then
        ply:SendLua[[RunConsoleCommand("act", "forward")]]
    elseif taunt.Name == "Nice" then
        ply:SendLua[[RunConsoleCommand("act", "agree")]]
    elseif taunt.Name == "Take cover" then
        ply:SendLua[[RunConsoleCommand("act", "halt")]]
    end

    ply:EmitSound(snd)
end

net.Receive("PlayerStartTaunt", function(len, ply)

    local categoryId = net.ReadInt(16)
    local tauntIndex = net.ReadInt(16)
    GAMEMODE:PlayPlayerTaunt(ply, categoryId, tauntIndex)

end)
