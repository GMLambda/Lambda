local DbgPrint = GetLogging("Checkpoints")

local GRID_SIZE = 256
local GRID_SIZE_Z = 1024
local MIN_ENEMY_DISTANCE = 500
local MIN_CHECKPOINT_DISTANCE = 700
local HULL_X = 32
local HULL_Y = 32
local HULL_Z = 74
local CHECKPOINT_MINS = Vector(-(HULL_X / 2), -(HULL_Y / 2), 0)
local CHECKPOINT_MAXS = Vector(HULL_X / 2, HULL_Y / 2, HULL_Z)

function GM:GetGridData(x, y, z)

	local gridX = math.Round(x / GRID_SIZE)
	local gridY = math.Round(y / GRID_SIZE)
	local gridZ = math.Round(z / GRID_SIZE_Z)

	self.GridData = self.GridData or {}

	local mapZ = self.GridData[gridZ]
	if mapZ == nil then
		mapZ = {}
		self.GridData[gridZ] = mapZ
	end

	local key = bit.bor(bit.lshift(gridX, 16), gridY)
	local data = mapZ[key]
	if data == nil then
		data = {}
		data.gridX = gridX
		data.gridY = gridY
		data.gridZ = gridZ
		data.checkpoint = false
		mapZ[key] = data
	end

	return data

end

function GM:ResetCheckpoints()
	self.GridData = {}
	self.CurrentCheckpoint = nil
	self.CurrentCheckpointPos = nil
end

function GM:SetPlayerCheckpoint(checkpoint)
	DbgPrint("Assigned new checkpoint to: " .. tostring(checkpoint))
	self.CurrentCheckpoint = checkpoint
	local cpPos = checkpoint:GetPos()
	self.CurrentCheckpointPos = cpPos
	local gridData = self:GetGridData(cpPos.x, cpPos.y, cpPos.z)
	gridData.checkpoint = true
end

local ENEMY_CLASS_WHITELIST =
{
	["npc_barnacle"] = true,
	["npc_bullseye"] = true,
	["npc_furniture"] = true,
	["npc_turret"] = true,
	["npc_turret_floor"] = true,
}

function GM:UpdateCheckoints()

	if self.NextCheckpointTest ~= nil and CurTime() < self.NextCheckpointTest then
		return
	end
	self.NextCheckpointTest = CurTime() + 1

	if lambda_dynamic_checkpoints:GetBool() == false then
		return
	end

	local plys = {}
	local centerPos = Vector(0, 0, 0)
	local bestPos

	for _,v in pairs(player.GetAll()) do

		if v:Alive() == false  then
			continue
		end

		local pos
		local groundEnt
		local vehicle = v:GetVehicle()
		local filter

		if not IsValid(vehicle) then
			if v:OnGround() == false then
				return
			end
			groundEnt = v:GetGroundEntity()
			pos = v:GetPos()
			filter = { v }
			if groundEnt != game.GetWorld() then
				continue
			end
		else
			pos = vehicle:GetPos()
			groundEnt = vehicle:GetGroundEntity()
			filter = { v, vehicle }
		end

		-- Only update if players have enough distance to the previous checkpoint.
		if self.CurrentCheckpointPos ~= nil and pos:Distance(self.CurrentCheckpointPos) < MIN_CHECKPOINT_DISTANCE then
			continue
		end

		centerPos = centerPos + pos

		local tr = util.TraceHull({
			start = pos,
			endpos = pos,
			filter = filter,
			mins = CHECKPOINT_MINS,
			maxs = CHECKPOINT_MAXS,
			mask = MASK_PLAYERSOLID,
		})

		if tr.Fraction == 1 then
			tr = util.TraceLine({
				start = pos,
				endpos = pos - Vector(0, 0, 128),
				filter = filter,
				mask = MASK_PLAYERSOLID,
			})

			local contents = util.PointContents(tr.HitPos - Vector(0, 0, 1))
			local slime = bit.band(contents, CONTENTS_SLIME) ~= 0
			if slime == true then
				continue
			end

			local dist = pos:Distance(tr.HitPos)
			if tr.HitWorld == true and dist <= 45 then
				table.insert(plys, v)
			end
		end

	end

	if #plys == 0 then
		return
	end

	centerPos = centerPos / #plys

	-- See which player is closest to the center.
	local nearestCenter = 999999
	local selectedPlayer = nil

	for _,v in pairs(plys) do

		local pos = v:GetPos()
		local dist = pos:Distance(centerPos)

		if dist < nearestCenter then
			bestPos = pos
			nearestCenter = dist
			selectedPlayer = v
		end

	end

	local data = self:GetGridData(bestPos.x, bestPos.y, bestPos.z)

	-- Make sure we don't have a spawnpoint in enemy terrority.
	local entsInGrid = ents.FindInSphere(bestPos, MIN_ENEMY_DISTANCE)
	local enemyNearby = false
	for _,v in pairs(entsInGrid) do
		local entPos = v:GetPos()
		if entPos:Distance(bestPos) >= MIN_ENEMY_DISTANCE then
			continue
		end

		local entClass = v:GetClass()
		local npcClass = nil

		if v:IsNPC() == true then
			npcClass = entClass
		elseif entClass == "npc_maker" or entClass == "npc_template_maker" and v.GetNPCClass ~= nil then
			npcClass = v:GetNPCClass()
		end

		if npcClass ~= nil and IsFriendEntityName(npcClass) == false and ENEMY_CLASS_WHITELIST[npcClass] ~= true then
			-- Special case, they can become allies.
			if npcClass == "npc_antlion" then
				if game.GetGlobalState("antlion_allied") ~= GLOBAL_ON then
					enemyNearby = true
				end
			else
				enemyNearby = true
			end
			if enemyNearby == true then
				DbgPrint("Enemie nearby " .. tostring(v) .. " -> " .. tostring(npcClass) .. ", can not create checkpoint.")
				break
			end
		end

	end

	if data.checkpoint == false and enemyNearby == false then

		local vehicle = selectedPlayer:GetVehicle()
		if IsValid(vehicle) and vehicle.AllowVehicleCheckpoint == true then
			local pos = vehicle:GetPos()
			local ang = vehicle:GetAngles()
			self:SetVehicleCheckpoint(pos, ang)
		end

		local cp = ents.Create("lambda_checkpoint")
		cp:SetPos(bestPos)
		cp:Spawn()

		self.CurrentCheckpoint = cp
		self.CurrentCheckpointPos = bestPos
		data.checkpoint = true

		--debugoverlay.Box(bestPos, CHECKPOINT_MINS, CHECKPOINT_MAXS, 5, Color( 255, 255, 255, 100 ))

		DbgPrint("Assigned checkpoint")
	end

end

function GM:SetVehicleCheckpoint(pos, ang)

	self.VehicleCheckpoint = { Pos = pos, Ang = ang }
	DbgPrint("Assigned vehicle checkpoint")

end

function GM:ResetVehicleCheckpoint()

	self.VehicleCheckpoint = nil

end
