local DbgPrint = GetLogging("Checkpoints")

local GRID_SIZE = 712
local GRID_SIZE_Z = 128 -- Approximate floor height.
local GRID_VEC = Vector(GRID_SIZE, GRID_SIZE, GRID_SIZE_Z)

local MIN_ENEMY_DISTANCE = 200
local MIN_CHECKPOINT_DISTANCE = 700

local PLAYER_HULL_X = 34
local PLAYER_HULL_Y = 34
local PLAYER_HULL_Z = 74
local CHECKPOINT_PLAYER_MINS = Vector(-(PLAYER_HULL_X / 2), -(PLAYER_HULL_Y / 2), 0)
local CHECKPOINT_PLAYER_MAXS = Vector(PLAYER_HULL_X / 2, PLAYER_HULL_Y / 2, PLAYER_HULL_Z)

local VEHICLE_HULL_X = 160
local VEHICLE_HULL_Y = 160
local VEHICLE_HULL_Z = 100
local CHECKPOINT_VEHICLE_MINS = Vector(-(VEHICLE_HULL_X / 2), -(VEHICLE_HULL_Y / 2), 0)
local CHECKPOINT_VEHICLE_MAXS = Vector(VEHICLE_HULL_X / 2, VEHICLE_HULL_Y / 2, VEHICLE_HULL_Z)

local MAP_MAX = 16000

function GM:GetGridData(x, y, z)

    local posX = math.floor(x / GRID_SIZE) * GRID_SIZE
    local posY = math.floor(y / GRID_SIZE) * GRID_SIZE
    local posZ = math.floor(z / GRID_SIZE_Z) * GRID_SIZE_Z

    x = posX + MAP_MAX
    y = posY + MAP_MAX
    z = posZ + MAP_MAX

    local gridX = math.floor(x / GRID_SIZE)
    local gridY = math.floor(y / GRID_SIZE)
    local gridZ = math.floor(z / GRID_SIZE_Z)

    self.GridData = self.GridData or {}

    local mapZ = self.GridData[gridZ]
    if mapZ == nil then
        mapZ = {}
        self.GridData[gridZ] = mapZ
    end

    local key = bit.bor(bit.lshift(gridX, 16), gridY)
    --print(gridX, gridY, gridZ, key)

    local data = mapZ[key]
    if data == nil then
        data = {}
        data.gridX = gridX
        data.gridY = gridY
        data.gridZ = gridZ
        data.gridMin = Vector(posX, posY, posZ)
        data.gridMax = data.gridMin + GRID_VEC
        data.gridKey = key
        data.explored = false
        data.checkpoint = false
        data.FindInGrid = function(d, class)
            return ents.FindInBox(d.gridMin, d.gridMax)
        end
        mapZ[key] = data
    end

    return data

end

function GM:ResetCheckpoints()
    self.GridData = {}
    self.VehicleCheckpointQueue = {}
    self.CurrentCheckpoint = nil
    self.CurrentCheckpointPos = nil
    self.NextCheckpointTest = nil
end

function GM:SetPlayerCheckpoint(checkpoint, gridData)
    local gameType = self:GetGameType()
    if gameType.UsingCheckpoints == false then
        return
    end
    DbgPrint("Assigned new checkpoint to: " .. tostring(checkpoint))
    self.CurrentCheckpoint = checkpoint
    local cpPos = checkpoint:GetPos()
    self.CurrentCheckpointPos = cpPos
    gridData = gridData or self:GetGridData(cpPos.x, cpPos.y, cpPos.z)
    gridData.checkpoint = true
end

function GM:UpdateQueuedVehicleCheckpoints()

    self.VehicleCheckpointQueue = self.VehicleCheckpointQueue or {}
    while #self.VehicleCheckpointQueue > 0 do
        self.VehicleCheckpoint = self.VehicleCheckpointQueue[1]
        DbgPrint("Assigned vehicle checkpoint (Queued)")
        table.remove(self.VehicleCheckpointQueue, 1)
    end

end

local ENEMY_CLASS_WHITELIST =
{
    ["npc_barnacle"] = true,
    ["npc_bullseye"] = true,
    ["npc_headcrab"] = true,
    ["npc_furniture"] = true,
    ["npc_turret"] = true,
    ["npc_turret_floor"] = true,
    ["npc_cscanner"] = true,
}

local function checkDirectionalSpot(pos, offset, filter)
    local tr = util.TraceHull({
        start = pos,
        endpos = pos + offset,
        filter = filter,
        mins = CHECKPOINT_PLAYER_MINS,
        maxs = CHECKPOINT_PLAYER_MAXS,
        mask = MASK_SOLID,
    })
    --debugoverlay.Box(pos + offset, CHECKPOINT_PLAYER_MINS, CHECKPOINT_PLAYER_MAXS, 5, Color( 255, 255, 255, 50 ))
    return tr.Fraction == 1
end

function GM:UpdateCheckoints()

    local gameType = self:GetGameType()
    if gameType.UsingCheckpoints == false then
        return
    end

    if self.NextCheckpointTest ~= nil and CurTime() < self.NextCheckpointTest then
        return
    end
    self.NextCheckpointTest = CurTime() + 5

    if lambda_dynamic_checkpoints:GetBool() == false then
        return
    end

    DbgPrint("Testing checkpoint access")

    local plys = {}
    local centerPos = Vector(0, 0, 0)
    local bestPos
    local bestTr

    for _,v in pairs(player.GetAll()) do
        local ply = v
        if ply:Alive() == false  then
            continue
        end

        local pos
        local groundEnt
        local vehicle = ply:GetVehicle()
        local filter
        local checkpointMins
        local checkpointMaxs

        if not IsValid(vehicle) then
            if v:OnGround() == false then
                continue
            end
            local groundEnt = ply:GetGroundEntity()
            if groundEnt ~= game.GetWorld() then
                continue
            end
            pos = ply:GetPos()
            filter = v
            checkpointMins = CHECKPOINT_PLAYER_MINS
            checkpointMaxs = CHECKPOINT_PLAYER_MAXS
        else
            pos = vehicle:GetPos()
            filter = { ply, vehicle, vehicle:GetNWEntity("PassengerSeat") }
            checkpointMins = CHECKPOINT_VEHICLE_MINS
            checkpointMaxs = CHECKPOINT_VEHICLE_MAXS
        end

        local contents = util.PointContents(pos - Vector(0, 0, 0))
        local isSlime = bit.band(contents, CONTENTS_SLIME) ~= 0
        local isWater = bit.band(contents, CONTENTS_WATER) ~= 0
        if isSlime == true then
            DbgPrint("On slime, can't use checkpoint.")
            continue
        end
        centerPos = centerPos + pos

        local trPos = pos -- We add the max step height
        local tr = util.TraceHull({
            start = trPos + Vector(0, 0, 1),
            endpos = trPos,
            filter = filter,
            mins = checkpointMins,
            maxs = checkpointMaxs,
            mask = MASK_SOLID,
        })

        --debugoverlay.Box(tr.HitPos, checkpointMins, checkpointMaxs, 5, Color( 255, 0, 0, 100 ))

        if tr.Fraction == 1 and tr.HitSky == false and tr.HitWorld == false then
            tr = util.TraceLine({
                start = pos,
                endpos = pos - Vector(0, 0, 128),
                filter = filter,
                mask = MASK_SOLID,
            })
            --debugoverlay.Box(tr.HitPos, Vector(-1, -1, -1), Vector(1, 1, 1), 5, Color( 255, 255, 255, 100 ))
            local dist = pos:Distance(tr.HitPos)
            if tr.HitWorld == true and dist <= 45 then
                table.insert(plys, v)
            end
        else
            -- Debug purpose.
            if false then
                PrintTable(tr)
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
    if data.checkpoint == true then
        DbgPrint("Map section already has checkpoint.")
        return
    end

    -- Only update if players have enough distance to the previous checkpoint.
    if IsValid(self.CurrentCheckpoint) then
        local dist = self.CurrentCheckpoint:GetPos():Distance(bestPos)
        if dist < MIN_CHECKPOINT_DISTANCE then
            DbgPrint("Checkpoint distance condition not met", dist)
            return
        end
    end

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

    if enemyNearby == false then

        local vehicle = selectedPlayer:GetVehicle()
        local ang = Angle(0, 0, 0)
        local vehiclePos = nil

        if IsValid(vehicle) and vehicle.AllowVehicleCheckpoint == true then
            -- Check if we can place it right
            local plyRight = vehicle:GetRight()
            local plyFwd = vehicle:GetForward()

            local filter = { selectedPlayer, vehicle, vehicle:GetNWEntity("PassengerSeat") }
            local vehicleAng = vehicle:GetAngles()
            local len = 80
            vehiclePos = vehicle:GetPos() + Vector(0, 0, 10)

            -- NOTE: Order was handpicked, do not change it, having players infront should be the last resort.
            if checkDirectionalSpot(vehiclePos, plyRight * -len, filter) == true then
                bestPos = vehiclePos + plyRight * -len
                self:SetVehicleCheckpoint(vehiclePos, vehicleAng)
            elseif checkDirectionalSpot(vehiclePos, plyFwd * -len, filter) == true then
                bestPos = vehiclePos + (plyFwd * -len)
                self:SetVehicleCheckpoint(vehiclePos, vehicleAng)
            elseif checkDirectionalSpot(vehiclePos, plyRight * len, filter) == true then
                bestPos = vehiclePos + (plyRight * len)
                self:SetVehicleCheckpoint(vehiclePos, vehicleAng)
            elseif checkDirectionalSpot(vehiclePos, plyFwd * len, filter) == true then
                bestPos = vehiclePos + (plyFwd * len)
                self:SetVehicleCheckpoint(vehiclePos, vehicleAng)
            else
                DbgPrint("Failed to assign vehicle position, using current.")
            end
        end

        local cp = ents.Create("lambda_checkpoint")
        ang = selectedPlayer:GetAngles()
        if vehiclePos ~= nil then
            ang = (vehiclePos - bestPos):Angle()
        end
        cp:SetPos(bestPos)
        cp:SetAngles(ang)
        cp:Spawn()

        self:SetPlayerCheckpoint(cp, data)

        --debugoverlay.Box(bestPos, CHECKPOINT_MINS, CHECKPOINT_MAXS, 5, Color( 255, 255, 255, 100 ))
    end

end

function GM:SetVehicleCheckpoint(pos, ang)

    local delaySwitch = false

    if self.LastSelectedSpawnPoint ~= nil and IsValid(self.LastSelectedSpawnPoint) then
        local checkpointPos = self.LastSelectedSpawnPoint:GetPos()
        for _,v in pairs(player.GetAll()) do
            if v:Alive() == false or v:InVehicle() == true then
                continue
            end
            local plyPos = v:GetPos()
            local dist = plyPos:Distance(checkpointPos)
            if dist < 500 then
                delaySwitch = true
                break
            end
        end
    end

    local data = { Pos = pos, Ang = ang }
    if delaySwitch == true then
        self.VehicleCheckpointQueue = self.VehicleCheckpointQueue or {}
        table.insert(self.VehicleCheckpointQueue, data)
        DbgPrint("Delayed vehicle checkpoint")
    else
        self.VehicleCheckpoint = data
        DbgPrint("Assigned vehicle checkpoint")
    end

end

function GM:ResetVehicleCheckpoint()

    self.VehicleCheckpoint = nil

end
