AddCSLuaFile()

local DbgPrint = GetLogging("Util")

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
			for k,v in pairs(targetents) do
				v:Fire(cmd, param, delay)
			end
		end

	end

	function util.TriggerOutputs(outputs, activator, caller, param, self)

		local count = table.Count(outputs)
		if count > 0 then
			DbgPrint("Firing " .. tostring(count) .. " outputs")
		end

		local removedOutput = false

		for k, data in pairs(outputs) do

			out = string.Split(data[1], ",")

			local entname = out[1] or ""
			local cmd = out[2] or ""
			local param = param
			if out[3] and out[3] ~= "" then
				param = out[3]
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
			DbgPrint("Output: (Caller: " .. tostring(caller) .. ", " .. callerName .. ") -> (Target: " .. entname .. ", Cmd: " .. cmd .. ", Delay:" .. tostring(delay) .. ", Param:" .. param .. ", Times: " .. tostring(times) .. ")")

			local triggerOutput = function()
				local targetents

				if entname == "!activator" then
					targetents = { activator }
				elseif entname == "!caller" then
					targetents = { caller }
				elseif entname == "!self" then
					targetents = { self }
				elseif entname == "!player" or entname == "player" then
					targetents = player.GetAll()
				elseif entname == "!pvsplayer" then
					ErrorNoHalt("Unhandled output targetname: " .. entname)
					targetents = {}
				else
					targetents = ents.FindByName(entname)
				end

				for _,ent in pairs(targetents) do
					if IsValid(ent) then
						DbgPrint("Firing " .. tostring(ent) .. "(" .. entname .. ") -> Cmd: " .. cmd .. ", Delay: " .. tostring(delay) .. ", Param: " .. param .. ", Times: " .. tostring(times) .. ")")
						ent:Input(cmd, activator, caller, param)
					else
						DbgPrint("Firing Output: Ent (" .. tostring(entname) .. ") is invalid, can not trigger output!")
					end
				end
			end

			-- With 0 it must be called this frame, timer.Simple delays everything.
			if delay == 0 then
				triggerOutput()
			else
				timer.Simple(delay, triggerOutput)
			end

			if times > 0 and called >= times then
				--DbgPrint("Removing output")
				outputs[k] = nil
				removedOutput = true
			end

		end

		return outputs, removedOutput

	end

	function util.SimpleTriggerOutputs(outputs, activator, caller, param, self)

		--DbgPrint("Firing " .. tostring(table.Count(outputs)) .. " outputs")

		for k, data in pairs(outputs) do

			out = string.Split(data, ",")

			local entname = out[1] or ""
			local cmd = out[2] or ""
			local param = param
			if out[3] and out[3] ~= "" then
				param = out[3]
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
			DbgPrint("Output: (Caller: " .. tostring(caller) .. ", " .. caller:GetName() .. ") -> (Target: " .. entname .. ", Cmd: " .. cmd .. ", Delay:" .. tostring(delay) .. ", Param:" .. param .. ", Times: " .. tostring(times) .. ")")

			timer.Simple(delay, function()

				local targetents

				if entname == "!activator" then
					targetents = { activator }
				elseif entname == "!caller" then
					targetents = { caller }
				elseif entname == "!self" then
					targetents = { self }
				elseif entname == "!player" or entname == "player" then
					targetents = player.GetAll()
				elseif entname == "!pvsplayer" then
					ErrorNoHalt("Unhandled output targetname: " .. entname)
					targetents = {}
				else
					targetents = ents.FindByName(entname)
				end

				for _,ent in pairs(targetents) do
					if IsValid(ent) then

						DbgPrint("Firing " .. tostring(ent) .. "(" .. entname .. ") -> Cmd: " .. cmd .. ", Delay: " .. tostring(delay) .. ", Param: " .. param .. ", Times: " .. tostring(times) .. ")")
						ent:Input(cmd, activator, caller, param)

					else
						--DbgPrint("Firing Output: Ent (" .. tostring(entname) .. ") is invalid, can not trigger output!")
					end
				end

			end)

			if times > 0 and called >= times then
				--DbgPrint("Removing output")
				outputs[k] = nil
			end

		end

		return outputs

	end

	local ENTITY_OUTPUTS =
	{
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
		["OnMotionEnabled"] = true,
		["OnAwakened"] = true,
		["OnPhysGunOnlyPickup"] = true,
		["OnPlayerPickup"] = true,
		["OnPhysGunDrop"] = true,
		["OnPlayerUse"] = true,
		["OnHitByTank"] = true,
		["OnFinishInteractWithObject"] = true,
		["OnDamaged"] = true,
		["OnDeath"] = true,
		["OnHalfHealth"] = true,
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
	}

	function util.IsOutputValue(key)
		for k, v in pairs(ENTITY_OUTPUTS) do
			if k:iequals(key) then
				return true
			end
		end
		return false
 	end

	function util.TracePlayerHull(ply, origin)

		local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
		local height = maxs.z - mins.z

		local pos = origin or ply:GetPos()

		--DbgPrint(mins, maxs)

		local tr = util.TraceHull(
		{
			start = pos,
			endpos = pos + Vector(0, 0, 1),
			filter = function(ent) return not ent:IsPlayer() end,
			mins = mins,
			maxs = maxs,
			mask = MASK_PLAYERSOLID,
		})

		debugoverlay.Cross(pos, 10, 7, Color(255, 255, 255), true)

		debugoverlay.Box(tr.HitPos, Vector(0, 0, 0), Vector(1, 1, 1), 7, Color(255, 0, 0))
		debugoverlay.Box(tr.StartPos, Vector(0, 0, 0), Vector(2, 2, 2), 7, Color(0, 255, 0))

		--debugoverlay.Box(tr.HitPos, mins, maxs, 5 )

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
			mask = MASK_DEADSOLID,
		})

		tr.TotalFraction = tr.Fraction
		if tr.FractionLeftSolid > 0 then
			tr.TotalFraction = tr.TotalFraction + (1 - tr.FractionLeftSolid)
		end

		debugoverlay.Line(startPos, endPos, 5, Color(255, 0, 0), true )

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
			if tr.Fraction == 1 then
				break
			end

			local traces =
			{
				Up = GetPlayerLineTrace(ply, vecUp, height, true, true), -- z
				Down = GetPlayerLineTrace(ply, vecUp, -height, true, true), -- z
				Forward = GetPlayerLineTrace(ply, -vecFwd, width, true, true), -- x
				Back = GetPlayerLineTrace(ply, vecFwd, width, true, true), -- x
				Right = GetPlayerLineTrace(ply, vecRight, width, true, true), -- y
				Left = GetPlayerLineTrace(ply, -vecRight, width, true, true), -- y
			}

			if fractions == 6 then
				--DbgPrint("No more solving required")
				break
			end

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

			if  traces.Down.TotalFraction > traces.Up.TotalFraction then
				offset.z = offset.z - (STEP_SIZE + traces.Down.TotalFraction )
				--DbgPrint("Moving down")
			end

			ply:SetPos(plyPos + offset)

			iterations = iterations + 1

		end

		DbgPrint("Solved within " .. iterations .. " iterations")

	end

	function util.IsEntVisibleToPlayers(ent)

		for _,v in pairs(player.GetAll()) do
			if v:Visible(ent) == true then
				return true
			end
		end

		return false

	end

	function util.IsPosVisibleToPlayers(pos)

		for _,v in pairs(player.GetAll()) do
			if v:VisibleVec(pos) == true then
				return true
			end
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

local thinkCount = 0
local funcQueue = {}

hook.Add("Think", "LambdaRunNextFrame", function()

	for k,v in ipairs(funcQueue) do
		if v.thinkId == thinkCount then
			-- In case it was added before Think was called.
			continue
		end
		v.func()
		table.remove(funcQueue, k)
	end

	thinkCount = thinkCount + 1

end)

function util.RunNextFrame(func)

	local data =
	{
		func = func,
		thinkId = thinkCount,
	}
	table.insert(funcQueue, data)

end

function util.RandomFloat(min, max)

	return min + (math.random() * (max - min))

end

function util.RandomInt(min, max)

	-- This sucks, who cares tho.
	return math.Clamp(math.Round(math.random(min, max)), min, max)

end
