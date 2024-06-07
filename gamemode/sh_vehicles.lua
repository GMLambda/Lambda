-- Those are the returned collision bounds for the airboat, big enough to work on the jeep.
local DbgPrint = GetLogging("Vehicle")
local util = util
local ents = ents
local IsValid = IsValid
local table = table
local CurTime = CurTime
local VEHICLE_THINK = 1
VEHICLE_SPAWN_MINS = Vector(-85, -132, -40)
VEHICLE_SPAWN_MAXS = Vector(85, 104, 110)
local VEHICLE_JEEP = 1
local VEHICLE_AIRBOAT = 2
local VEHICLE_JALOPY = 3
local VEHICLE_PASSENGER = 4
local NEXT_VEHICLE_SPAWN = CurTime()
local VEHICLE_SPAWN_TIME = 2

if SERVER then
    AddCSLuaFile()

    function GM:InitializeMapVehicles()
        DbgPrint("InitializeMapVehicles")
        -- Because autoreload..
        self.ActiveVehicles = {}
        self.MapVehicles = {}
        self.SpawnPlayerVehicles = true
        self.NextVehicleThink = 0

        local mapdata = game.GetMapData()
        for _, v in pairs(mapdata.Entities) do
            if v["classname"] == "prop_vehicle_airboat" then
                table.insert(self.MapVehicles, v)
            elseif v["classname"] == "prop_vehicle_jeep" and v["model"] == "models/buggy.mdl" then
                table.insert(self.MapVehicles, v)
            elseif v["classname"] == "prop_vehicle_jeep" and v["model"] == "models/vehicle.mdl" then
                table.insert(self.MapVehicles, v)
            end
        end
    end

    function GM:CleanUpVehicles()
        DbgPrint("Cleaning up vehicles..")

        for vehicle, _ in pairs(self.ActiveVehicles) do
            if IsValid(k) then
                DbgPrint("Removing vehicle: " .. tostring(vehicle))
                vehicle:ClearAllOutputs()
                vehicle:Remove()
            else
                DbgPrint("Vehicle " .. tostring(vehicle) .. " invalid")
            end
        end

        self:ResetVehicleCheck()
    end

    function GM:ResetVehicleCheck()
        self.NextVehicleThink = CurTime() + VEHICLE_THINK
    end

    function GM:VehicleSetPlayerOwner(vehicle, ply)
        vehicle:SetNWEntity("LambdaVehicleOwner", ply)
    end

    function GM:PlayerSetVehicleOwned(ply, vehicle)
        ply:SetNWEntity("LambdaOwnedVehicle", vehicle)
    end

    function GM:SetVehicleType(vehicle, vehicleType)
        vehicle:SetNWInt("LambdaVehicleType", vehicleType)
    end

    function GM:VehicleSetPassengerSeat(vehicle, seat)
        vehicle:SetNWEntity("PassengerSeat", seat)
    end

    function GM:HandleVehicleCreation(vehicle)
        DbgPrint("HandleVehicleCreation")
        local class = vehicle:GetClass()
        local vehicleType = nil
        if class ~= "prop_vehicle_airboat" and class ~= "prop_vehicle_jeep" then return end

        -- This has to be set this frame.
        if self.MapScript.VehicleGuns == true then
            DbgPrint("Enabling Gun")
            vehicle:SetKeyValue("EnableGun", "1")
        else
            DbgPrint("No guns enabled")
        end

        -- Akward hack to know if an NPC passenger is inside. We handle this with our AcceptInput hook.
        self.IsCreatingInternalOutputs = true
        vehicle:Input("AddOutput", NULL, NULL, "OnCompanionEnteredVehicle !self,LambdaCompanionEnteredVehicle,,0,-1")
        vehicle:Input("AddOutput", NULL, NULL, "OnCompanionExitedVehicle !self,LambdaCompanionExitedVehicle,,1,-1")
        self.IsCreatingInternalOutputs = false

        -- We only get a model next frame, delay it.
        util.RunNextFrame(function()
            if not IsValid(vehicle) then return end
            local mdl = vehicle:GetModel()

            if class == "prop_vehicle_airboat" and mdl == "models/airboat.mdl" then
                vehicleType = VEHICLE_AIRBOAT
            elseif class == "prop_vehicle_jeep" and mdl == "models/buggy.mdl" then
                vehicleType = VEHICLE_JEEP
            elseif class == "prop_vehicle_jeep" and mdl == "models/vehicle.mdl" then
                vehicleType = VEHICLE_JALOPY
            else
                return
            end

            DbgPrint(vehicle, "Vehicle type: " .. tostring(vehicleType))

            self.ActiveVehicles[vehicle] = true
            --vehicle:SetCustomCollisionCheck(true)

            vehicle:CallOnRemove("LambdaVehicleCleanup", function(ent)
                self.ActiveVehicles[ent] = nil
            end)

            vehicle.AllowVehicleCheckpoint = true
            self:SetVehicleType(vehicle, vehicleType)

            local tracker = ents.Create("lambda_vehicle_tracker")
            tracker:AttachToVehicle(vehicle)
            tracker:Spawn()

            if vehicleType == VEHICLE_JEEP then
                self:HandleJeepCreation(vehicle)
            elseif vehicleType == VEHICLE_AIRBOAT then
                self:HandleAirboatCreation(vehicle)
            elseif vehicleType == VEHICLE_JALOPY then
                self:HandleJalopyCreation(vehicle)
            end
        end)
    end

    local function CreatePassengerSeat(parent, localPos, localAng, mdl)
        local seat = ents.Create("prop_vehicle_prisoner_pod")
        seat:SetPos(parent:LocalToWorld(localPos))
        seat:SetAngles(parent:LocalToWorldAngles(localAng))
        seat:SetModel(mdl)
        seat:SetParent(parent)
        seat:Spawn()
        -- TODO: Remove this, legacy.
        seat:SetNWBool("IsPassengerSeat", true)
        GAMEMODE:SetVehicleType(seat, VEHICLE_PASSENGER)
        return seat
    end

    function GM:HandleJeepCreation(jeep)
        local seat = jeep:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Already exists.
            return
        end
        seat = CreatePassengerSeat(jeep,
            Vector(19.369112, -37.018456, 18.896046),
            Angle(-0.497, -3.368, 0.259),
            "models/nova/jeep_seat.mdl"
        )
        jeep:SetNWEntity("PassengerSeat", seat)
    end

    function GM:HandleJalopyCreation(jalopy)
        local seat = jalopy:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Already exists.
            return
        end
        seat = CreatePassengerSeat(jalopy,
            Vector(21.498613, -27.285204, 18.695107),
            Angle(-0.211, 0.621, -0.145),
            "models/nova/jalopy_seat.mdl"
        )
        -- Make it invisible, we just want the functionality.
        seat:SetNoDraw(true)

        jalopy:SetNWEntity("PassengerSeat", seat)
    end

    function GM:OnCompanionEnteredVehicle(jalopy, passenger)
        DbgPrint("Companion entered vehicle")
        jalopy:SetNWEntity("LambdaPassenger", passenger)
        passenger:SetNWEntity("LambdaVehicle", jalopy)

        local seat = jalopy:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Lock this seat as we have the passenger inside the vehicle.
            seat:Fire("Lock")
        else
            DbgPrint("No passenger seat on jalopy: " .. tostring(jalopy))
        end
    end

    function GM:OnCompanionExitedVehicle(jalopy, passenger)
        DbgPrint("Companion exited vehicle")
        jalopy:SetNWEntity("LambdaPassenger", NULL)
        passenger:SetNWEntity("LambdaVehicle", NULL)

        local seat = jalopy:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Lock this seat as we have the passenger inside the vehicle.
            seat:Fire("Unlock")
        end
    end

    function GM:OnPlayerPassengerEnteredVehicle(ply, vehicle, seat)
        DbgPrint("Player entered passenger seat", ply, vehicle, seat)

        -- Prevent NPC companions from entering as passengers.
        vehicle:Fire("LockEntrance")
    end

    function GM:OnPlayerPassengerExitedVehicle(ply, vehicle, seat)
        DbgPrint("Player exited passenger seat", ply, vehicle, seat)

        -- Allow NPC companions to enter as passengers.
        vehicle:Fire("UnlockEntrance")
    end

    function GM:HandleAirboatCreation(airboat)
    end

    function GM:FindVehicleSeat(ply, vehicle)
        if vehicle:GetDriver() == NULL then return vehicle end
        -- Allow players to enter the passenger seat directly by swapping it.
        local passengerSeat = vehicle:GetNWEntity("PassengerSeat")
        if IsValid(passengerSeat) and passengerSeat:GetDriver() == NULL then return passengerSeat end

        return vehicle
    end

    function GM:PlayerEnteredVehicle(ply, vehicle, role)
        DbgPrint("PlayerEnteredVehicle", ply, vehicle, role)

        if ply:IsSprinting() == true then
            ply:StopSprinting()
        end

        local vehicleType = self:VehicleGetType(vehicle)
        if vehicleType ~= VEHICLE_PASSENGER then
            -- Clear the previous vehicle owner.
            local prevVehicle = self:PlayerGetVehicleOwned(ply)
            if IsValid(prevVehicle) then
                self:VehicleSetPlayerOwner(prevVehicle, nil)
            end

            local owner = self:VehicleGetPlayerOwner(vehicle)
            if IsValid(owner) and owner ~= ply then
                DbgError("Bogus vehicle logic: Player entering vehicle that does not belong to him", owner, ply, vehicle)
            elseif owner == nil then
                -- Now belongs to the specific player.
                DbgPrint("Player " .. tostring(ply) .. " gets ownership of vehicle: " .. tostring(vehicle))
                self:VehicleSetPlayerOwner(vehicle, ply)
                self:PlayerSetVehicleOwned(ply, vehicle)
            end
        end

        local ang = vehicle:GetForward():Angle()
        ang = vehicle:WorldToLocalAngles(ang)
        ply:SetEyeAngles(ang)

        if self:VehicleIsPassengerSeat(vehicle) then
            local parent = vehicle:GetParent()
            if IsValid(parent) and parent:GetNWEntity("PassengerSeat") == vehicle then
                self:OnPlayerPassengerEnteredVehicle(ply, parent, vehicle)
            end
        end

        if self.MapScript ~= nil and self.MapScript.OnEnteredVehicle ~= nil then
            self.MapScript:OnEnteredVehicle(ply, vehicle, role)
        end
    end

    function GM:CanExitVehicle(vehicle, ply)
        DbgPrint("CanPlayerExitVehicle", vehicle, ply)
        local locked = vehicle:GetInternalVariable("vehiclelocked")
        if locked ~= nil then return locked == false end

        return true
    end

    function GM:PlayerLeaveVehicle(ply, vehicle)
        -- Reset, we disabled it for transition probably
        DbgPrint("Player leave: " .. tostring(ply))

        if vehicle.ResetVehicleEntryAnim == true then
            vehicle:SetVehicleEntryAnim(true)
        end

        local vehicleType = self:VehicleGetType(vehicle)

        if ply:Alive() == false then
            if vehicleType ~= VEHICLE_PASSENGER then
                self:VehicleSetPlayerOwner(vehicle, nil)
                self:VehicleDriverKilled(vehicle, ply)
            end
        else
            -- Make sure players won't collide if they exit strangely.
            ply:DisablePlayerCollide(true)
        end

        if ply:Alive() and vehicleType == VEHICLE_PASSENGER then
            local ang = vehicle:GetAngles()
            local pos = vehicle:GetPos()
            local exitpos = pos + (ang:Forward() * 50)
            -- Look towards the seat.
            local exitang = (pos - exitpos):Angle()
            ply:TeleportPlayer(exitpos, exitang)
            vehicle:GetParent().Passenger = nil

            local parent = vehicle:GetParent()
            if IsValid(parent) and self:VehicleGetPassengerSeat(parent) == vehicle then
                self:OnPlayerPassengerExitedVehicle(ply, parent, vehicle)
            end
        end
    end

    function GM:CanPlayerEnterVehicle(ply, vehicle, role)
        DbgPrint("CanPlayerEnterVehicle", ply, vehicle)

        -- Disallow by default.
        ply:SetAllowWeaponsInVehicle(false)

        local vehicleType = self:VehicleGetType(vehicle)
        if vehicleType ~= VEHICLE_PASSENGER then
            local vehicleOwner = self:VehicleGetPlayerOwner(vehicle)
            -- Check if the vehicle is owned by someone else.
            if IsValid(vehicleOwner) and vehicleOwner ~= ply then
                DbgPrint("Player not allowed to enter vehicle, owned by: " .. tostring(vehicleOwner))
                return false
            end

            -- Check if the vehicle is already owned by us.
            if vehicleOwner == ply then
                DbgPrint("Player owns the vehicle")
                return true
            end

            -- Check if the player already owns a vehicle other than this one.
            if vehicle.LambdaPlayerTakeover ~= ply then
                local playerVehicle = self:PlayerGetVehicleOwned(ply)
                if IsValid(playerVehicle) and playerVehicle ~= vehicle then
                    DbgPrint("Player already owns a vehicle")
                    return false
                end
            end

            -- Take ownership of the vehicle.
            self:VehicleSetPlayerOwner(vehicle, ply)
            self:PlayerSetVehicleOwned(ply, vehicle)

        elseif vehicleType == VEHICLE_PASSENGER then
            vehicle:SetKeyValue("limitview", "0")
            ply:SetAllowWeaponsInVehicle(true)

            if vehicle.SetVehicleEntryAnim ~= nil then
                vehicle.ResetVehicleEntryAnim = true
                vehicle:SetVehicleEntryAnim(false)
            else
                vehicle.ResetVehicleEntryAnim = false
            end
        end

        return true
    end

    function GM:RemovePlayerVehicles(ply)
        DbgPrint("GM:RemovePlayerVehicles", ply)

        for vehicle, _ in pairs(self.ActiveVehicles) do
            local vehicleOwner = self:VehicleGetPlayerOwner(vehicle)
            local passenger = self:GetVehiclePassenger(vehicle)
            if vehicleOwner == ply and not IsValid(passenger) then
                DbgPrint("Removing player vehicle: " .. tostring(vehicle))
                self:VehicleSetPlayerOwner(vehicle, nil)
                vehicle:Remove()
            end
        end

        self:PlayerSetVehicleOwned(ply, nil)
    end

    function GM:SetSpawnPlayerVehicles(state)
        self.SpawnPlayerVehicles = state

        if self.SpawnPlayerVehicles == nil then
            self.SpawnPlayerVehicles = true
        end
    end

    function GM:CanSpawnVehicle()
        if CurTime() < NEXT_VEHICLE_SPAWN then return false end
        local alivePlayers = 0
        local playerCount = 0

        for _, v in pairs(util.GetAllPlayers()) do
            if v:Alive() then
                alivePlayers = alivePlayers + 1
            end

            playerCount = playerCount + 1
        end

        if alivePlayers == 0 then return false end
        if self.SpawnPlayerVehicles ~= true then return false end
        if table.Count(self.ActiveVehicles) < playerCount then return true end

        return false
    end

    function GM:GetVehicleSpawnPos()
        if self.VehicleCheckpoint ~= nil then
            return self.VehicleCheckpoint.Pos
        end
        if #self.MapVehicles == 0 then
            return nil
        end
        return util.StringToType(self.MapVehicles[1]["origin"], "Vector")
    end

    function GM:SpawnVehicleAtSpot(vehicle)
        local pos = util.StringToType(vehicle["origin"], "Vector")

        if self.VehicleCheckpoint ~= nil then
            pos = self.VehicleCheckpoint.Pos
        end

        -- Check if there is already one.
        local nearbyEnts = ents.FindInBox(pos + VEHICLE_SPAWN_MINS, pos + VEHICLE_SPAWN_MAXS)

        for _, v in pairs(nearbyEnts) do
            if v:GetClass() == vehicle["classname"] then
                -- We normally dont want this, but its possible to spawn two of them at the same spot.
                -- TODO: Create a convar and let the server owner decide.
                return false
            end
            -- The box is somewhat big, we should deal with players standing directly in the way.
        end

        DbgPrint("Spawning vehicle...")
        local newVehicle = ents.CreateFromData(vehicle)

        if self.VehicleCheckpoint ~= nil then
            newVehicle:SetPos(self.VehicleCheckpoint.Pos)
            newVehicle:SetAngles(self.VehicleCheckpoint.Ang)
        end

        if self.EnableVehicleGuns then
            newVehicle:SetKeyValue("EnableGun", "1")
        end

        newVehicle:Spawn()
        newVehicle:Activate()
        DbgPrint("Created new vehicle: " .. tostring(newVehicle))
        NEXT_VEHICLE_SPAWN = CurTime() + VEHICLE_SPAWN_TIME
    end

    function GM:CheckRemoveVehicle(vehicle)
        local passenger = self:GetVehiclePassenger(vehicle)
        if IsValid(passenger) then
            -- Never remove vehicles that have a passenger.
            return
        end

        local vehiclePos = vehicle:GetPos()
        local vehicleOwner = self:VehicleGetPlayerOwner(vehicle)
        if IsValid(vehicleOwner) then
            -- Check how far away the vehicle owner is.
            local ownerDist = vehicleOwner:GetPos():Distance(vehiclePos)
            if ownerDist < 1024 then
                return
            end
        end

        if vehicleOwner ~= nil and not IsValid(vehicleOwner) then
            -- Probably disconnected client.
            self:VehicleSetPlayerOwner(vehicle, nil)
        end

        local spawnPos = self:GetVehicleSpawnPos()
        if spawnPos ~= nil then
            -- See if the checkpoint has moved.
            local dist = vehiclePos:Distance(spawnPos)
            if dist < 256 then
                return
            end
        end

        -- Check if there are players nearby.
        if util.IsPlayerNearby(vehiclePos, 1024) then
            return
        end

        vehicle:Remove()
    end

    function GM:VehiclesThink()
        if self:IsRoundRunning() == false and self:RoundElapsedTime() >= 1 then
            return
        end

        if #self.MapVehicles == 0 then
            -- No vehicles on this map.
            return
        end

        local curTime = CurTime()
        if curTime < self.NextVehicleThink then return end
        self.NextVehicleThink = curTime + VEHICLE_THINK

        for vehicle, _ in pairs(self.ActiveVehicles) do
            if not IsValid(vehicle) then
                self.ActiveVehicles[vehicle] = nil
            else
                self:CheckRemoveVehicle(vehicle)
            end
        end

        if self:CanSpawnVehicle() then
            for _, v in pairs(self.MapVehicles) do
                self:SpawnVehicleAtSpot(v)
            end
        end
    end
else -- CLIENT
    function GM:CalcVehicleView(vehicle, ply, view)
        --print("CalcVehicleView")
        if ply.VehicleSteeringView == true then
            local viewPos = view.origin
            local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")

            if headBone ~= nil then
                viewPos = ply:GetBonePosition(headBone)
            end

            view.origin = viewPos + (view.angles:Forward() * 3)
        end

        -- Don't roll the camera
        view.angles.z = 0
        if vehicle.GetThirdPersonMode == nil or ply:GetViewEntity() ~= ply then return end -- This should never happen.
        if vehicle:GetThirdPersonMode() == false then return view end
        local mn, mx = vehicle:GetRenderBounds()
        local radius = (mn - mx):Length()
        radius = radius + radius * vehicle:GetCameraDistance()
        -- Trace back from the original eye position, so we don't clip through walls/objects
        local TargetOrigin = view.origin + (view.angles:Forward() * -radius)
        local WallOffset = 4

        local tr = util.TraceHull({
            start = view.origin,
            endpos = TargetOrigin,
            filter = function(e)
                local c = e:GetClass() -- Avoid contact with entities that can potentially be attached to the vehicle. Ideally, we should check if "e" is constrained to "Vehicle".

                return not c:StartWith("prop_physics") and not c:StartWith("prop_dynamic") and not c:StartWith("prop_ragdoll") and not e:IsVehicle() and not c:StartWith("gmod_")
            end,
            mins = Vector(-WallOffset, -WallOffset, -WallOffset),
            maxs = Vector(WallOffset, WallOffset, WallOffset)
        })

        view.origin = tr.HitPos
        view.drawviewer = true

        --
        -- If the trace hit something, put the camera there.
        --
        if tr.Hit and not tr.StartSolid then
            view.origin = view.origin + tr.HitNormal * WallOffset
        end

        return view
    end
end

function GM:VehicleShouldCollide(veh1, veh2)
    -- FIXME: When vehicles initially intersect they shouldn't collide as long they do.
    do
        return
    end
end

function GM:VehicleDriverKilled(vehicle, ply)
    DbgPrint("Vehicle driver dead", ply, vehicle)

    local vehicleType = self:VehicleGetType(vehicle)
    if vehicleType == VEHICLE_PASSENGER then
        return
    end

    local passenger = self:GetVehiclePassenger(vehicle)
    if IsValid(passenger) then
        DbgPrint("Notifying passenger")

        -- Send a hint that the passenger can take over.
        self:AddHint("#LAMBDA_VEHICLE_TAKE_OVER", 7, passenger)

        vehicle.LambdaPlayerTakeover = passenger
    end
end

function GM:VehiclePromotePassenger(ply, vehicle)
    local parent = vehicle:GetParent()
    if not IsValid(parent) then
        return
    end

    if IsValid(parent:GetDriver()) then
        return
    end

    local owner = self:VehicleGetPlayerOwner(vehicle)
    if IsValid(owner) then
        return
    end

    print("Switch time")
    util.RunNextFrame(function()
        -- Enter the driver side.
        ply:EnterVehicle(parent)
    end)
end

function GM:VehicleMove(ply, vehicle, mv)
    -- We have to call it here because PlayerTick wont be called if we are inside a vehicle.
    self:UpdateSuit(ply, mv)
    self:PlayerWeaponTick(ply, mv)

    --
    -- On duck toggle third person view
    --
    if mv:KeyPressed(IN_DUCK) and vehicle.SetThirdPersonMode then
        vehicle:SetThirdPersonMode(not vehicle:GetThirdPersonMode())
    end

    if SERVER then
        if mv:KeyDown(IN_SPEED) and mv:KeyDown(IN_USE) then
            if self:VehicleIsPassengerSeat(vehicle) then
                self:VehiclePromotePassenger(ply, vehicle)
            end
        end
    end

    --
    -- Adjust the camera distance with the mouse wheel
    --
    local iWheel = ply:GetCurrentCommand():GetMouseWheel()

    if iWheel ~= 0 and vehicle.SetCameraDistance then
        -- The distance is a multiplier
        -- Actual camera distance = ( renderradius + renderradius * dist )
        -- so -1 will be zero.. clamp it there.
        local newdist = math.Clamp(vehicle:GetCameraDistance() - iWheel * 0.03 * (1.1 + vehicle:GetCameraDistance()), -1, 10)
        vehicle:SetCameraDistance(newdist)
    end

    if ply:IsPositionLocked() ~= true then return end
    mv:SetButtons(0)
    local phys = vehicle:GetPhysicsObject()

    if IsValid(phys) then
        local vel = phys:GetVelocity()
        local len = vel:Length()

        if vel:Length() >= 1 then
            vel = vel - (vel * 0.015)
            phys:SetVelocity(vel)
        end

        if len < 50 and (vehicle:GetClass() == "prop_vehicle_jeep" or vehicle:GetClass() == "prop_vehicle_jalopy") then
            vehicle:Fire("HandBrakeOn")
        end
    end
end

function GM:GetVehiclePassenger(vehicle)
    local npcPassenger = vehicle:GetNWEntity("LambdaPassenger")
    if IsValid(npcPassenger) then
        -- There is an NPC sitting in the vehicle.
        return npcPassenger
    end
    local seat = vehicle:GetNWEntity("PassengerSeat")
    if IsValid(seat) then
        return seat:GetDriver()
    end
    return nil
end

function GM:VehicleGetPlayerOwner(vehicle)
    if not IsValid(vehicle) then
        DbgError("VehicleGetPlayerOwner: Invalid vehicle")
        return nil
    end
    return vehicle:GetNWEntity("LambdaVehicleOwner", nil)
end

function GM:PlayerGetVehicleOwned(ply)
    if not IsValid(ply) then
        DbgError("PlayerGetVehicleOwned: Invalid player")
        return nil
    end
    return ply:GetNWEntity("LambdaOwnedVehicle", nil)
end

function GM:VehicleGetType(vehicle, vehicleType)
    if not IsValid(vehicle) then
        DbgError("VehicleGetType: Invalid vehicle")
        return nil
    end
    if vehicle:GetNWBool("IsPassengerSeat", false) then
        return VEHICLE_PASSENGER
    end
    vehicle:GetNWInt("LambdaVehicleType", vehicleType)
end

function GM:VehicleIsPassengerSeat(vehicle)
    return self:VehicleGetType(vehicle) == VEHICLE_PASSENGER
end

function GM:VehicleGetPassengerSeat(vehicle)
    return vehicle:GetNWEntity("PassengerSeat")
end