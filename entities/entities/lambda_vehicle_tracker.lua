local DbgPrint = GetLogging("Vehicle")

AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
	if CLIENT then
		-- I know this seems insane but otherwise it would clip the purpose.
		self:SetRenderBounds(Vector(-10000, -10000, -10000), Vector(10000, 10000, 10000))

		hook.Add("PostDrawTranslucentRenderables", self, function(ent, bDrawingDepth, bDrawingSkybox)
			if bDrawingDepth == true or bDrawingSkybox == true then
				return
			end
			ent:RenderVehicleStatus()
		end)
	end
	self:DrawShadow(false)
	self:AddEffects(EF_NODRAW)
end

function ENT:AttachToVehicle(vehicle)
	self:SetModel(vehicle:GetModel())
	self:SetPos(vehicle:GetPos())
	self:SetAngles(vehicle:GetAngles())
	self:SetParent(vehicle)
	self:AddEffects(EF_NODRAW)
	self:DrawShadow(false)

	self.Vehicle = vehicle
	self.Player = vehicle.LambdaPlayer
	self:SetNW2Entity("LambdaVehicleOwner", self.Player)
	self:SetNW2Bool("LambdaVehicleTaken", IsValid(self.Player))

end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

if SERVER then

	function ENT:Think()

		local vehicle = self:GetParent()
		if not IsValid(vehicle) then
			self:Remove()
			return
		end

		if self.Player ~= vehicle.LambdaPlayer then
			self.Player = vehicle.LambdaPlayer
			self:SetNW2Entity("LambdaVehicleOwner", self.Player)
			self:SetNW2Bool("LambdaVehicleTaken", IsValid(self.Player))
			DbgPrint("Owner changed")
		end

		self:NextThink(CurTime() + 0.1)
		return true
	end

elseif CLIENT then

	local pixVis = util.GetPixelVisibleHandle()
	local font = "DermaLarge"
	local pad = 2
	local health_w = 100
	local health_h = 5
	local aux_w = 100
	local aux_h = 5

	local function IsVehicleVisible(vehicle)

		local localPly = LocalPlayer()
		if localPly:IsLineOfSightClear(vehicle:EyePos()) then
			return true
		end

		local visibility = util.PixelVisible(vehicle:GetPos(), 0, pixVis)
		return visibility > 0

	end

	local function IsVehicleBehind(vehicle)

		local dir = (vehicle:GetPos() - EyePos()):GetNormal()
		local dot = dir:Dot(EyeAngles():Forward())
		if dot < 0 then
			return true
		end
		return false

	end

	local VEHICLE_MAT = Material("lambda/vehicle.png")

	function ENT:RenderVehicleStatus()

		local vehicle = self:GetParent()
		if not IsValid(vehicle) then
			return
		end

		-- We could do this but its rather ugly.
		--[[
		if IsVehicleVisible(vehicle) == false then
			cam.IgnoreZ(true)
			vehicle:DrawModel()
			cam.IgnoreZ(false)
		end
		]]

		local pos = self:GetPos() + self:OBBCenter() + Vector(0, 0, 50)
		local localPly = LocalPlayer()

		if IsVehicleBehind(vehicle) then
			-- Dont bother
			return
		end

		local ownedVehicle = localPly:GetNW2Entity("LambdaOwnedVehicle")
		--DbgPrint("Owned: " .. tostring(ownedVehicle))
		local isTaken = self:GetNW2Bool("LambdaVehicleTaken")
		local vehiclePly = self:GetNW2Entity("LambdaVehicleOwner")
		local displayIcon = false


		if isTaken == false then
			displayIcon = true
		else
			if localPly:GetVehicle() ~= vehicle and vehiclePly == localPly then
				displayIcon = true
			end
		end

		if (ownedVehicle ~= nil and ownedVehicle ~= NULL) and ownedVehicle ~= vehicle then
			displayIcon = false
		end

		if displayIcon == true then

			local eyePos = EyePos()
			local distance = eyePos:Distance(pos)
			local distanceScale = distance * 0.0008
			distanceScale = math.Clamp(distanceScale, 0.25, 5.5)

			local bounce = math.sin(CurTime() * 5) + math.cos(CurTime() * 5)
			pos = pos + (Vector(0, 0, 1) * bounce)

			local diff = pos - eyePos
			ang = diff:Angle()

			ang:RotateAroundAxis(ang:Up(), 90)
			ang:RotateAroundAxis(ang:Forward(), 90)

			pos = pos + (Vector(0, 0, 60) * distanceScale)

			local mat1 = Matrix()
			mat1:SetTranslation( pos )
			mat1:Scale( Vector(1, 1, 1) * distanceScale  )
			mat1:SetTranslation( pos )
			mat1:SetAngles(ang)
			mat1:Rotate(Angle(0, 180, 0))
			mat1:SetTranslation( pos )

			diff = pos - eyePos
			ang = diff:Angle()

			ang:RotateAroundAxis(ang:Up(), 45)
			ang:RotateAroundAxis(ang:Forward(), 180)

			cam.IgnoreZ(true)
			cam.Start3D2D(pos, Angle(0,0,0), 0.1)

				cam.PushModelMatrix(mat1)
					surface.SetDrawColor( 255, 255, 255, 200 )
					surface.SetMaterial( VEHICLE_MAT )
					surface.DrawTexturedRect( -32, 0 + (-bounce * 10), 60, 60 )
				cam.PopModelMatrix()

			cam.End3D2D()
			cam.IgnoreZ(false)

		end

	end

	function ENT:Draw()
	end

	function ENT:DrawTranslucent()
	end

end
