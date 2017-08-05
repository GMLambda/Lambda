local DbgPrint = GetLogging("Checkpoints")

local GRID_SIZE = 256
local HULL_X = 32
local HULL_Y = 32
local HULL_Z = 74
local CHECKPOINT_MINS = Vector(-(HULL_X / 2), -(HULL_Y / 2), 0)
local CHECKPOINT_MAXS = Vector(HULL_X / 2, HULL_Y / 2, HULL_Z)

function GM:GetGridData(x, y, z)

	local gridX = math.Round(x / GRID_SIZE)
	local gridY = math.Round(y / GRID_SIZE)
	local gridZ = math.Round(z / GRID_SIZE)

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

	--DbgPrint("Testing checkpoints")

	self.NextCheckpointTest = CurTime() + 1

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
		if self.CurrentCheckpointPos ~= nil and pos:Distance(self.CurrentCheckpointPos) < 1024 then
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
	if data.checkpoint == false then

		local cp = ents.Create("lambda_checkpoint")
		cp:SetPos(bestPos)
		cp:Spawn()

		self.CurrentCheckpoint = cp
		self.CurrentCheckpointPos = bestPos
		data.checkpoint = true

		debugoverlay.Box(bestPos, CHECKPOINT_MINS, CHECKPOINT_MAXS, 5, Color( 255, 255, 255, 100 ))

		DbgPrint("Assigned checkpoint")
	end

end
