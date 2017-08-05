local DbgPrint = GetLogging("Vehicle")

AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
	if CLIENT then
		-- I know this seems insane but otherwise it would clip the purpose.
		self:SetRenderBounds(Vector(-10000, -10000, -10000), Vector(10000, 10000, 10000))

		hook.Add("HUDPaint", self, function(ent)
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

		local pos = self:GetPos() + self:OBBCenter() + Vector(0, 0, 50)
		local localPly = LocalPlayer()

		local plyPos = localPly:GetPos()
		local alphaDist = 1.0 - (plyPos:Distance(pos) / 1500)
		if alphaDist <= 0.0 then
			return
		end

		if IsVehicleBehind(vehicle) then
			-- Dont bother
			return
		end

		local ownedVehicle = localPly:GetNW2Entity("LambdaOwnedVehicle")
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

		if displayIcon ~= true then
			return
		end

		local eyePos = EyePos()
		local distance = eyePos:Distance(pos)
		local distanceScale = distance * 0.0008
		distanceScale = math.Clamp(distanceScale, 0.25, 5.5)

		local bounce = math.sin(CurTime() * 5) + math.cos(CurTime() * 5) * 5
		pos = pos + (Vector(0, 0, 1) * bounce)
		pos = pos + (Vector(0, 0, 60) * distanceScale)

		local screenPos = pos:ToScreen()

		surface.SetDrawColor( 255, 255, 255, alphaDist * 200 )
		surface.SetMaterial( VEHICLE_MAT )
		surface.DrawTexturedRect( screenPos.x, screenPos.y, 60, 60 )

	end

	function ENT:Draw()
	end

	function ENT:DrawTranslucent()
	end

end
