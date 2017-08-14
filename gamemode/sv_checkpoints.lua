local DbgPrint = GetLogging("Checkpoints")

local GRID_SIZE = 256
local GRID_SIZE_Z = 1024
local MIN_ENEMY_DISTANCE = 700
local MIN_CHECKPOINT_DISTANCE = 1024
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

		if v:Alive() == false or v:OnGround() == false or v:GetMoveType() ~= MOVETYPE_WALK then
			continue
		end

		local groundEnt = v:GetGroundEntity()
		if groundEnt:IsWorld() == false then
			-- Only solid world brush.
			continue
		end

		local pos = v:GetPos()
		centerPos = centerPos + pos

		local tr = util.TraceHull({
			start = pos,
			endpos = pos,
			filter = v,
			mins = CHECKPOINT_MINS,
			maxs = CHECKPOINT_MAXS,
			mask = MASK_PLAYERSOLID,
		})

		-- Only update if players have enough distance to the previous checkpoint.
		if self.CurrentCheckpointPos ~= nil and pos:Distance(self.CurrentCheckpointPos) < MIN_CHECKPOINT_DISTANCE then
			continue
		end

		if tr.Fraction == 1 then
			table.insert(plys, v)
		end

		DbgPrint(tr.Fraction, tr.Entity)

	end

	if #plys == 0 then
		return
	end

	centerPos = centerPos / #plys

	-- See which player is closest to the center.
	local nearestCenter = 999999
	for _,v in pairs(plys) do

		local pos = v:GetPos()
		local dist = pos:Distance(centerPos)

		if dist < nearestCenter then
			bestPos = pos
			nearestCenter = dist
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
		local class = v:GetClass()
		if v:IsNPC() == true and class ~= "npc_bullseye" and IsFriendEntityName(class) == false then
			enemyNearby = true
			DbgPrint("Enemie nearby " .. tostring(v) .. ", can not create checkpoint.")
			break
		elseif class == "npc_maker" or class == "npc_template_maker" and v.GetNPCClass ~= nil then
			local npcclass = v:GetNPCClass()
			if npctype ~= nil and IsFriendEntityName(npcclass) == false then
				enemyNearby = true
				DbgPrint("Enemy spawner nearby, can not create checkpoint.")
				break
			end
		end
	end

	if data.checkpoint == false and enemyNearby == false then

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
