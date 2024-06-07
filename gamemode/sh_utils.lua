if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Util")
local ents = ents
local IsValid = IsValid
local table = table
local CurTime = CurTime

-- Any utility function should go in here.
if SERVER then
    function TriggerOutputs(outputs)
        DbgPrint("Firing outputs")

        for _, out in pairs(outputs) do
            local entname = out[1] or ""
            local cmd = out[2] or ""
            local delay = out[3] or 0
            local param = out[4] or ""
            local targetents = ents.FindByName(entname) or {}
            local times = -1

            for k, v in pairs(targetents) do
                DbgPrint("Firing " .. tostring(v) .. "(" .. tostring(entname) .. ") -> Cmd: " .. tostring(cmd) .. ", Delay: " .. tostring(delay) .. ", Param: " .. tostring(param) .. ", Times: " .. tostring(times) .. ")")
                v:Fire(cmd, param, delay)
            end
        end
    end

    function util.TriggerOutputs(outputs, activator, caller, parameter, this)
        local count = table.Count(outputs)

        if count > 0 then
            DbgPrint("Firing " .. tostring(count) .. " outputs")
        end

        local removedOutput = false

        for k, data in pairs(outputs) do
            local out = string.Split(data[1], ",")
            local entname = out[1] or ""
            local cmd = out[2] or ""
            local param = parameter

            if out[3] and out[3] ~= "" then
                param = string.Trim(out[3])
            end

            if IsEntity(param) and IsValid(param) then
                param = param:GetName()
            end

            param = param or ""
            local delay = tonumber(out[4] or 0)
            local times = tonumber(out[5] or "-1")
            local called = data[2] + 1
            outputs[k][2] = called
            local callerName = ""

            if IsValid(caller) then
                callerName = caller:GetName()
            end

            DbgPrint("Output: (Caller: " .. tostring(caller) .. ", " .. callerName .. ") -> (Target: " .. tostring(entname) .. ", Cmd: " .. tostring(cmd) .. ", Delay:" .. tostring(delay) .. ", Param:" .. tostring(param) .. ", Times: " .. tostring(times) .. ")")

            local triggerOutput = function()
                local targetents

                if entname == "!activator" then
                    targetents = {activator}
                elseif entname == "!caller" then
                    targetents = {caller}
                elseif entname == "!self" then
                    targetents = {this}
                elseif entname == "!player" or entname == "player" then
                    targetents = player.GetAll()
                elseif entname == "!pvsplayer" then
                    ErrorNoHalt("Unhandled output targetname: " .. entname)
                    targetents = {}
                else
                    targetents = ents.FindByName(entname)
                end

                if #targetents == 0 then
                    DbgPrint("Unable to find target entity: " .. entname)
                end

                for _, ent in pairs(targetents) do
                    if IsValid(ent) then
                        DbgPrint("Firing " .. tostring(ent) .. "(" .. tostring(entname) .. ") -> Cmd: " .. tostring(cmd) .. ", Delay: " .. tostring(delay) .. ", Param: " .. tostring(param) .. ", Times: " .. tostring(times) .. ")")
                        ent:Input(cmd, activator, caller, param)
                    else
                        DbgPrint("Firing Output: Ent (" .. tostring(entname) .. ") is invalid, can not trigger output!")
                    end
                end
            end

            util.EnqueueOutput(triggerOutput, CurTime() + delay)

            if times > 0 and called >= times then
                --DbgPrint("Removing output")
                outputs[k] = nil
                removedOutput = true
            end
        end

        return outputs, removedOutput
    end

    function util.SimpleTriggerOutputs(outputs, activator, caller, parameter, myself)
        --DbgPrint("Firing " .. tostring(table.Count(outputs)) .. " outputs")
        for k, data in pairs(outputs) do
            local out = string.Split(data, ",")
            local entname = out[1] or ""
            local cmd = out[2] or ""
            local param = parameter

            if out[3] and out[3] ~= "" then
                param = string.Trim(out[3])
            end

            if IsEntity(param) and IsValid(param) then
                param = param:GetName()
            end

            param = param or ""
            local delay = tonumber(out[4] or 0)
            local times = tonumber(out[5] or "-1")
            local called = 1

            --[k].Times = outputs[k].Times or times
            --times = outputs[k].Times
            --DbgPrint("Output: (Caller: " .. tostring(caller) .. ", " .. caller:GetName() .. ") -> (Target: " .. tostring(entname) .. ", Cmd: " .. cmd .. ", Delay:" .. tostring(delay) .. ", Param:" .. param .. ", Times: " .. tostring(times) .. ")")
            util.EnqueueOutput(function()
                local targetents

                if entname == "!activator" then
                    targetents = {activator}
                elseif entname == "!caller" then
                    targetents = {caller}
                elseif entname == "!self" then
                    targetents = {myself}
                elseif entname == "!player" or entname == "player" then
                    targetents = player.GetAll()
                elseif entname == "!pvsplayer" then
                    ErrorNoHalt("Unhandled output targetname: " .. entname)
                    targetents = {}
                else
                    targetents = ents.FindByName(entname)
                end

                for _, ent in pairs(targetents) do
                    if IsValid(ent) then
                        DbgPrint("Firing " .. tostring(ent) .. "(" .. entname .. ") -> Cmd: " .. cmd .. ", Delay: " .. tostring(delay) .. ", Param: " .. param .. ", Times: " .. tostring(times) .. ")")
                        ent:Input(cmd, activator, caller, param)
                    else
                        if false then
                            DbgPrint("Firing Output: Ent (" .. tostring(entname) .. ") is invalid, can not trigger output!")
                        end
                    end
                end
            end, CurTime() + delay)

            if times > 0 and called >= times then
                --DbgPrint("Removing output")
                outputs[k] = nil
            end
        end

        return outputs
    end

    local ENTITY_OUTPUTS = {
        ["OnAnimationBegun"] = true,
        ["OnAnimationDone"] = true,
        ["OnIgnite"] = true,
        ["OnBreak"] = true,
        ["OnTakeDamage"] = true,
        ["OnHealthChanged"] = true,
        ["OnPhysCannonDetach"] = true,
        ["OnPhysCannonAnimatePreStarted"] = true,
        ["OnPhysCannonAnimatePullStarted"] = true,
        ["OnPhysCannonAnimatePostStarted"] = true,
        ["OnPhysCannonPullAnimFinished"] = true,
        ["OnUser1"] = true,
        ["OnUser2"] = true,
        ["OnUser3"] = true,
        ["OnUser4"] = true,
        ["OnKilled"] = true,
        ["OnDeploy"] = true,
        ["OnTipped"] = true,
        ["OnMotionEnabled"] = true,
        ["OnAwakened"] = true,
        ["OnPhysGunOnlyPickup"] = true,
        ["OnPhysGunPickup"] = true,
        ["OnPlayerPickup"] = true,
        ["OnPlayerTouch"] = true,
        ["OnPhysGunDrop"] = true,
        ["OnPlayerUse"] = true,
        ["OnHitByTank"] = true,
        ["OnFinishInteractWithObject"] = true,
        ["OnDamaged"] = true,
        ["OnDeath"] = true,
        ["OnHalfHealth"] = true,
        ["OnHalfEmpty"] = true,
        ["OnEmpty"] = true,
        ["OnFull"] = true,
        ["OnHearWorld"] = true,
        ["OnCacheInteraction"] = true,
        ["OnNPCPickup"] = true,
        ["OnHearPlayer"] = true,
        ["OnHearCombat"] = true,
        ["OnFoundEnemy"] = true,
        ["OnLostEnemyLOS"] = true,
        ["OnLostEnemy"] = true,
        ["OnFoundPlayer"] = true,
        ["OnLostPlayerLOS"] = true,
        ["OnLostPlayer"] = true,
        ["OnDamagedByPlayer"] = true,
        ["OnDamagedByPlayerSquad"] = true,
        ["OnDenyCommanderUse"] = true,
        ["OnWake"] = true,
        ["OnSpawnNPC"] = true,
        ["OnSpawn"] = true,
        ["OnAllSpawned"] = true,
        ["OnAllLiveChildrenDead"] = true,
        ["ImpactForce"] = true,
        ["OnStartTouch"] = true,
        ["OnTrigger"] = true,
        ["OnTrigger1"] = true,
        ["OnTrigger2"] = true,
        ["OnTrigger3"] = true,
        ["OnTrigger4"] = true,
        ["OnTrigger5"] = true,
        ["OnTrigger6"] = true,
        ["OnTrigger7"] = true,
        ["OnTrigger8"] = true,
        ["OnTrigger9"] = true,
        ["OnTrigger10"] = true,
        ["OnTrigger11"] = true,
        ["OnTrigger12"] = true,
        ["OnTrigger13"] = true,
        ["OnTrigger14"] = true,
        ["OnTrigger15"] = true,
        ["OnTrigger16"] = true,
        ["OnStartTouchAll"] = true,
        ["OnEndTouch"] = true,
        ["OnEndTouchAll"] = true,
        ["OnEqualTo"] = true,
        ["OnGreaterThan"] = true,
        ["OnLessThan"] = true,
        ["OnNotEqualTo"] = true,
        ["NoValidActor"] = true,
        ["OnConditionsSatisfied"] = true,
        ["OnConditionsTimeout"] = true,
        ["OnIn"] = true,
        ["OnPressed"] = true,
        ["OnOut"] = true,
        ["OnUseLocked"] = true,
        ["OnBackgroundMap"] = true,
        ["OnLoadGame"] = true,
        ["OnMapSpawn"] = true,
        ["OnMapTransition"] = true,
        ["OnMultiNewMap"] = true,
        ["OnMultiNewRound"] = true,
        ["OnNewGame"] = true,
        ["OnGetValue"] = true,
        ["OnHitMax"] = true,
        ["OnHitMin"] = true,
        ["PlayerOff"] = true,
        ["PlayerOn"] = true,
        ["OnCompanionEnteredVehicle"] = true,
        ["OnCompanionExitedVehicle"] = true,
        ["OnHostileEnteredVehicle"] = true,
        ["OnHostileExitedVehicle"] = true,
        ["PressedAttack"] = true,
        ["PressedAttack2"] = true,
        ["AttackAxis"] = true,
        ["Attack2Axis"] = true,
    }

    function util.IsOutputValue(key)
        for k, v in pairs(ENTITY_OUTPUTS) do
            if k:iequals(key) then return true end
        end

        return false
    end

    function util.TracePlayerHull(ply, origin)
        local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
        local pos = origin or ply:GetPos()

        local tr = util.TraceHull({
            start = pos,
            endpos = pos + Vector(0, 0, 1),
            filter = function(ent) return not ent:IsPlayer() end,
            mins = mins,
            maxs = maxs,
            mask = MASK_PLAYERSOLID
        })

        return tr
    end

    -- NOTE: If we still get stuck we should perhaps decrease this.
    local STEP_SIZE = 1
    local STEP_ITERATIONS = 100

    local function GetPlayerLineTrace(ply, dir, space, useCenter, swap)
        local pos = ply:GetPos()

        if useCenter == true or useCenter == nil then
            pos = pos + ply:OBBCenter()
        end

        local startPos = pos + (dir * space)
        local endPos = pos

        if swap == true then
            --DbgPrint("Swapped")
            local tmp = startPos
            startPos = endPos
            endPos = tmp
        end

        local tr = util.TraceLine({
            start = startPos,
            endpos = endPos,
            filter = function(ent) return ent:IsPlayer() end,
            mask = MASK_DEADSOLID
        })

        tr.TotalFraction = tr.Fraction

        if tr.FractionLeftSolid > 0 then
            tr.TotalFraction = tr.TotalFraction + (1 - tr.FractionLeftSolid)
        end

        debugoverlay.Line(startPos, endPos, 5, Color(255, 0, 0), true)

        return tr
    end

    function util.PlayerUnstuck(ply)
        local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
        local vecUp = Vector(0, 0, 1) --ply:GetUp()
        local vecRight = Vector(0, 1, 0) --ply:GetRight()
        local vecFwd = Vector(1, 0, 0) --ply:GetForward()
        local height = (maxs.z - mins.z) * 3
        local width = (maxs.y - mins.y) * 2
        local plyPos = ply:GetPos()
        local offset = Vector(0, 0, 0)
        --local i = 1
        local iterations = 0

        for i = 0, STEP_ITERATIONS do
            local tr = util.TracePlayerHull(ply)
            if tr.Fraction == 1 then break end

            local traces = {
                Up = GetPlayerLineTrace(ply, vecUp, height, true, true), -- z
                Down = GetPlayerLineTrace(ply, vecUp, -height, true, true), -- z
                Forward = GetPlayerLineTrace(ply, -vecFwd, width, true, true), -- x
                Back = GetPlayerLineTrace(ply, vecFwd, width, true, true), -- x
                Right = GetPlayerLineTrace(ply, vecRight, width, true, true), -- y
                Left = GetPlayerLineTrace(ply, -vecRight, width, true, true) -- y
            }

            if fractions == 6 then break end --DbgPrint("No more solving required")

            --DbgPrint("Left: " .. traces.Left.Fraction)
            --DbgPrint("Right: " .. traces.Right.Fraction)
            if traces.Left.TotalFraction > traces.Right.TotalFraction then
                offset.y = offset.y - (STEP_SIZE + traces.Left.TotalFraction)
                --DbgPrint("Moving to left")
            end

            if traces.Right.TotalFraction > traces.Left.TotalFraction then
                offset.y = offset.y + (STEP_SIZE + traces.Right.TotalFraction)
                --DbgPrint("Moving to right")
            end

            if traces.Forward.TotalFraction > traces.Back.TotalFraction then
                offset.x = offset.x - (STEP_SIZE + traces.Forward.TotalFraction)
                --DbgPrint("Moving forward")
            end

            if traces.Back.TotalFraction > traces.Forward.TotalFraction then
                offset.x = offset.x + (STEP_SIZE + traces.Back.TotalFraction)
                --DbgPrint("Moving back")
            end

            if traces.Up.TotalFraction > traces.Down.TotalFraction then
                offset.z = offset.z + (STEP_SIZE + traces.Up.TotalFraction)
                --DbgPrint("Moving Up")
            end

            if traces.Down.TotalFraction > traces.Up.TotalFraction then
                offset.z = offset.z - (STEP_SIZE + traces.Down.TotalFraction)
                --DbgPrint("Moving down")
            end

            ply:SetPos(plyPos + offset)
            iterations = iterations + 1
        end

        DbgPrint("Solved within " .. iterations .. " iterations")
    end

    function util.IsEntVisibleToPlayers(ent)
        for _, v in pairs(player.GetAll()) do
            if v:IsFlagSet(FL_NOTARGET) then continue end
            if v:Visible(ent) == true then return true end
        end

        return false
    end

    function util.IsPosVisibleToPlayers(pos)
        for _, v in pairs(player.GetAll()) do
            if v:IsFlagSet(FL_NOTARGET) then continue end
            if v:InsideViewCone(pos) == true and v:VisibleVec(pos) == true then return true end
        end

        return false
    end
else -- CLIENT
    function util.ScreenScaleH(n)
        return n * (ScrH() / 480)
    end

    function util.ScreenScaleW(n)
        return ScreenScale(n)
    end
end

local LAMBDA_CURRENT_TICK = 0
local LAMBDA_FUNCTION_QUEUE = {}

hook.Add("Think", "LambdaRunNextFrame", function()
    local k = 1

    while k <= #LAMBDA_FUNCTION_QUEUE do
        local v = LAMBDA_FUNCTION_QUEUE[k]

        if v.thinkId == LAMBDA_CURRENT_TICK then
            -- In case it was added before Think was called.
            k = k + 1
            continue
        end

        if v.timestamp ~= nil and CurTime() < v.timestamp then
            k = k + 1
            continue
        end

        table.remove(LAMBDA_FUNCTION_QUEUE, k)
        v.func()
    end

    LAMBDA_CURRENT_TICK = LAMBDA_CURRENT_TICK + 1
end)

function util.RunNextFrame(func)
    local data = {
        func = func,
        thinkId = LAMBDA_CURRENT_TICK,
        output = false
    }

    table.insert(LAMBDA_FUNCTION_QUEUE, data)
end

function util.RunDelayed(func, ts)
    local data = {
        func = func,
        timestamp = ts,
        thinkId = LAMBDA_CURRENT_TICK,
        output = false
    }

    table.insert(LAMBDA_FUNCTION_QUEUE, data)
end

function util.ResetFunctionQueue()
    LAMBDA_CURRENT_TICK = 0
    LAMBDA_FUNCTION_QUEUE = {}
end

function util.EnqueueOutput(func, ts)
    local data = {
        func = func,
        thinkId = LAMBDA_CURRENT_TICK,
        output = true
    }

    if ts ~= nil then
        data.timestamp = ts
    end

    table.insert(LAMBDA_FUNCTION_QUEUE, data)
end

function util.ResetOutputQueue()
    -- Safely remove all elements
    for i = #LAMBDA_FUNCTION_QUEUE, 1, -1 do
        local v = LAMBDA_FUNCTION_QUEUE[i]

        if v.output == true then
            table.remove(LAMBDA_FUNCTION_QUEUE, i)
        end
    end
end

function util.RandomFloat(min, max)
    return min + (math.random() * (max - min))
end

function util.RandomInt(min, max)
    -- This sucks, who cares tho.
    return math.Clamp(math.Round(math.random(min, max)), min, max)
end

local PLAYER_LIST_CACHE_TICK = 0
local PLAYER_LIST_CACHE = {}

function util.GetAllPlayers()
    local curTick = engine.TickCount()

    if PLAYER_LIST_CACHE_TICK ~= curTick then
        PLAYER_LIST_CACHE = player.GetAll()
    else
        local curCount = player.GetCount()

        if #PLAYER_LIST_CACHE ~= curCount then
            -- Ensure the cache is up to date at all times, this should rarerly
            -- to never happen.
            PLAYER_LIST_CACHE = player.GetAll()
        end
    end

    return PLAYER_LIST_CACHE
end

local function IsPlayerNearby(pos, ply, radius)
    if ply:Alive() == false then
        return false
    end
    if ply:GetPos():Distance(pos) <= radius then
        return true
    end
    return false
end

function util.IsPlayerNearby(entOrPos, radius)
    local pos = entOrPos

    if IsEntity(entOrPos) then
        pos = entOrPos:GetPos()
    end

    for _, ply in pairs(util.GetAllPlayers()) do
        if IsPlayerNearby(pos, ply, radius) then
            return true
        end
    end

    return false
end