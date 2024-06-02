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
local VEHICLE_JEEP = 0
local VEHICLE_AIRBOAT = 1
local VEHICLE_JALOPY = 2
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

        for k, _ in pairs(self.ActiveVehicles) do
            if IsValid(k) then
                DbgPrint("Removing vehicle: " .. tostring(k))
                k:Remove()
                local ply = k.LambdaPlayer

                if IsValid(ply) and ply.OwnedVehicle == k then
                    ply.OwnedVehicle = nil
                end
            else
                DbgPrint("Vehicle " .. tostring(k) .. " invalid")
            end
        end

        self:ResetVehicleCheck()
    end

    function GM:ResetVehicleCheck()
        self.NextVehicleThink = CurTime() + VEHICLE_THINK
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
        vehicle:Fire("AddOutput", "OnCompanionEnteredVehicle !self,LambdaCompanionEnteredVehicle,0,-1", "0.0")
        vehicle:Fire("AddOutput", "OnCompanionExitedVehicle !self,LambdaCompanionExitedVehicle,1,-1", "0.0")

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
            vehicle:SetCustomCollisionCheck(true)

            vehicle:CallOnRemove("LambdaVehicleCleanup", function(ent)
                self.ActiveVehicles[ent] = nil
                local ply = ent.LambdaPlayer

                if IsValid(ply) and ply.OwnedVehicle == ent then
                    ply.OwnedVehicle = nil
                end
            end)

            vehicle.AllowVehicleCheckpoint = true
            vehicle.LambdaVehicleType = vehicleType

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
        seat:SetNWBool("IsPassengerSeat", true)
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
        if ply:IsSprinting() == true then
            ply:StopSprinting()
        end

        if vehicle:GetClass() == "prop_vehicle_jeep" or vehicle:GetClass() == "prop_vehicle_airboat" or vehicle:GetClass() == "prop_vehicle_jalopy" then
            if vehicle.LambdaPlayer ~= nil and vehicle.LambdaPlayer ~= ply then
                DbgError("Bogus vehicle logic: Player entering vehicle that does not belong to him")
            elseif vehicle.LambdaPlayer == nil then
                -- Now belongs to the specific player.
                DbgPrint("Player " .. tostring(ply) .. " gets ownership of vehicle: " .. tostring(vehicle))
                vehicle.LambdaPlayer = ply
                ply.OwnedVehicle = vehicle
                ply:SetNWEntity("LambdaOwnedVehicle", vehicle)
            end
        end

        local ang = vehicle:GetForward():Angle()
        ang = vehicle:WorldToLocalAngles(ang)
        ply:SetEyeAngles(ang)

        if vehicle:GetNWBool("IsPassengerSeat", false) then
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

        if ply:Alive() == false then
            DbgPrint("Player who left is now dead, we shall remove this")
            -- We give the driver a chance to pick up this vehicle.
            local passengerSeat = vehicle:GetNWEntity("PassengerSeat")

            if IsValid(passengerSeat) then
                local passenger = passengerSeat:GetDriver()

                if IsValid(passenger) and passenger:IsPlayer() then
                    DbgPrint("Giving passenger temporary ownership of vehicle")
                    vehicle.LambdaPlayer = nil
                    vehicle.LambdaAllowEnter = passenger
                    ply.OwnedVehicle = nil
                    ply:SetNWEntity("LambdaOwnedVehicle", nil)
                end
            end
        else
            -- Make sure players won't collide if they exit strangely.
            ply:DisablePlayerCollide(true)
        end

        if ply:Alive() and vehicle:GetNWBool("IsPassengerSeat", false) == true then
            local ang = vehicle:GetAngles()
            local pos = vehicle:GetPos()
            local exitpos = pos + (ang:Forward() * 50)
            -- Look towards the seat.
            local exitang = (pos - exitpos):Angle()
            ply:TeleportPlayer(exitpos, exitang)
            vehicle:GetParent().Passenger = nil

            local parent = vehicle:GetParent()
            if IsValid(parent) and parent:GetNWEntity("PassengerSeat") == vehicle then
                self:OnPlayerPassengerExitedVehicle(ply, parent, vehicle)
            end
        end
    end

    function GM:CanPlayerEnterVehicle(ply, vehicle, role)
        DbgPrint("CanPlayerEnterVehicle", ply, vehicle)

        if ply.OwnedVehicle ~= nil and IsValid(ply.OwnedVehicle) == false then
            -- Just to make sure, its possible it might error somewhere and did not unassign it.
            ply.OwnedVehicle = nil
        end

        if vehicle:GetNWBool("IsPassengerSeat", false) == true then
            vehicle:SetKeyValue("limitview", "0")
            ply:SetAllowWeaponsInVehicle(true)
        else
            ply:SetAllowWeaponsInVehicle(false)
        end

        if vehicle.SetVehicleEntryAnim ~= nil then
            vehicle.ResetVehicleEntryAnim = true
            vehicle:SetVehicleEntryAnim(false)
        else
            vehicle.ResetVehicleEntryAnim = false
        end

        if vehicle:GetClass() == "prop_vehicle_jeep" or vehicle:GetClass() == "prop_vehicle_airboat" then
            if vehicle.LambdaPlayer == nil and ply.OwnedVehicle == nil then
                -- Not yet owned.
                return true
            elseif vehicle.LambdaPlayer == nil and ply.OwnedVehicle ~= nil then
                if vehicle.LambdaAllowEnter == ply then
                    -- Important to set this, RemovePlayerVehicles cleans up those where we are allowed to enter.
                    vehicle.LambdaAllowEnter = nil
                    -- Remove his old vehicle.
                    self:RemovePlayerVehicles(ply)

                    return true
                end

                -- TODO: Add notification of whats happening.
                return false
            elseif vehicle.LambdaPlayer ~= nil then
                -- Check if we own the vehicle.
                if vehicle.LambdaPlayer == ply then
                    DbgPrint("Player can enter")

                    return true
                else
                    DbgPrint("Player not allowed to enter")

                    return false
                end
            end
        end

        return true
    end

    function GM:RemovePlayerVehicles(ply)
        DbgPrint("GM:RemovePlayerVehicles", ply)

        for vehicle, _ in pairs(self.ActiveVehicles) do
            if vehicle.LambdaPlayer == ply then
                DbgPrint("Removing player vehicle: " .. tostring(vehicle))
                vehicle:Remove()
            elseif vehicle.LambdaAllowEnter == ply and vehicle.LambdaPlayer == nil then
                DbgPrint("Passenger took no ownership of the vehicle, no owner, removing.")
                vehicle:Remove()
            end
        end

        ply.OwnedVehicle = nil
        ply:SetNWEntity("LambdaOwnedVehicle", nil)
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

    function GM:VehiclesThink()
        if self:IsRoundRunning() == false and self:RoundElapsedTime() >= 1 then return end
        local curTime = CurTime()
        if curTime < self.NextVehicleThink then return end
        self.NextVehicleThink = curTime + VEHICLE_THINK

        if self:CanSpawnVehicle() then
            DbgPrint("Spawning vehicles...")
            for _, v in pairs(self.MapVehicles) do
                self:SpawnVehicleAtSpot(v)
            end
        end

        local playerPosTable = {}
        local centerPos = Vector(0, 0, 0)
        local inVehicle = 0
        local alivePlayers = 0

        for _, v in pairs(player.GetAll()) do
            if v:Alive() == false then continue end
            alivePlayers = alivePlayers + 1

            if v:InVehicle() == true then
                inVehicle = inVehicle + 1
            end

            local pos = v:GetPos()
            table.insert(playerPosTable, pos)
            centerPos = centerPos + pos
        end

        if #playerPosTable > 0 then
            centerPos = centerPos / #playerPosTable
        end

        -- Make sure we clean up vehicles from disconnected players.
        for vehicle, _ in pairs(self.ActiveVehicles or {}) do
            if vehicle.LambdaPlayer ~= nil then
                local ply = vehicle.LambdaPlayer

                if not IsValid(ply) then
                    DbgPrint("Removing player vehicle")
                    vehicle:Remove()
                end
            else
                local passenger = self:GetVehiclePassenger(vehicle)
                if IsValid(passenger) then
                    -- Can't remove, has a passenger inside.
                    continue
                end

                local isVisible = false
                for _, ply in pairs(player.GetAll()) do
                    if ply:Visible(vehicle) then
                        isVisible = true
                        break
                    end
                end

                if isVisible then
                    -- Vehicle is visible, don't remove it.
                    continue
                end

                -- If all the players are too far away remove it, its most likely abondended.
                -- and will be recreated at the current vehicle checkpoint.
                if #playerPosTable > 0 and inVehicle < alivePlayers then
                    local vehiclePos = vehicle:GetPos()
                    local centerDist = centerPos:Distance(vehiclePos)
                    local nearby = false

                    if centerDist > 1024 then
                        for _, p in pairs(playerPosTable) do
                            local dist = p:Distance(vehiclePos)

                            if dist < 4500 then
                                nearby = true
                                break
                            end
                        end

                        -- If no player is nearby we can remove the old unowned vehicle.
                        if nearby == false then
                            vehicle:Remove()
                            continue
                        end
                    end
                end
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