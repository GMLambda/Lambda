include("shared.lua")
include("cl_skin_lambda.lua")
include("cl_postprocess.lua")
include("cl_ragdoll_ext.lua")
include("cl_taunts.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")
--include("cl_pathobserve.lua")

DEFINE_BASECLASS( "gamemode_base" )

local DbgPrint = GetLogging("Client")

-- This is nasty
function GM:OnSpawnMenuOpen()
	RunConsoleCommand("lastinv")
end

function GM:NetworkEntityCreated( ent )

	if ent.PVSInitialize then
		ent:PVSInitialize()
	end

	local class = ent:GetClass()
	if class == "class C_HL2MPRagdoll" then
		self:HandleRagdollCreation(ent)
	end

end

function GM:OnResolutionChanged(oldW, oldH, newW, newH)
	self:HUDInit()
end

function GM:ClientThink()
	local scrW = ScrW()
	local scrH = ScrH()

	self.CurResW = self.CurResW or scrW
	self.CurResH = self.CurResH or scrH

	local resChanged = false

	if self.CurResW ~= scrW or self.CurResH ~= scrH then
		resChanged = true
	end

	if resChanged then

		local curW = self.CurResW
		local curH = self.CurResH

		-- We can not just load fonts at this point, it actually freezes gmod.
		timer.Simple(1, function()
			hook.Call("OnResolutionChanged", self, curW, curH, scrW, scrH)
		end)

		self.CurResH = resH
		self.CurResW = resW

		DbgPrint("Resolution changed")
	end

	self:BulletsThink()
end

local HL2_BOB_CYCLE_MAX = 0.40
local HL2_BOB_UP = 0.5
local MAX_SPEED = 320
local PI = math.pi
local HL2_MAX_VIEWDT = 1 / 60

local host_timescale = GetConVar("host_timescale")

local function GetTimeScale()
	if host_timescale:GetFloat() ~= 1 then
		return host_timescale:GetFloat()
	end
	return game.GetTimeScale()
end

function GM:CalcViewModelBob( wep, vm, oldPos, oldAng, pos, ang )

	local ply = LocalPlayer()

	self.LastPlayerSpeed = self.LastPlayerSpeed or 0

	local dt = SysTime() - (self.LastViewBob or SysTime())
	self.LastViewBob = SysTime()

	if dt >= HL2_MAX_VIEWDT then
		dt = HL2_MAX_VIEWDT
	end

	dt = dt * GetTimeScale()

	local speed
	if ply:OnGround() then
		speed = Lerp(dt * 10, self.LastPlayerSpeed, ply:GetVelocity():Length2D())
	else
		speed = Lerp(dt * 2, self.LastPlayerSpeed, 0)
	end

	speed = math.Clamp(speed, -MAX_SPEED, MAX_SPEED)
	self.LastPlayerSpeed = speed

	local bob_offset = math.Remap(speed, 0, MAX_SPEED, 0.0, 1.0)

	self.ViewBobTime = (self.ViewBobTime or 0) + (dt * 1.3) * bob_offset

	local cycle = self.ViewBobTime - math.Round(self.ViewBobTime / HL2_BOB_CYCLE_MAX, 0) * HL2_BOB_CYCLE_MAX
	cycle = cycle / HL2_BOB_CYCLE_MAX

	if cycle < HL2_BOB_UP then
		cycle = PI * (cycle / HL2_BOB_UP)
	else
		cycle = PI + PI * ((cycle - HL2_BOB_UP) / (1.0 - HL2_BOB_UP))
	end

	local vertBob = speed * 0.005
	vertBob = vertBob * 0.3 + vertBob * 0.7 * math.sin(cycle)
	vertBob = math.Clamp(vertBob, -7.0, 4.0)

	cycle = self.ViewBobTime - math.Round(self.ViewBobTime / HL2_BOB_CYCLE_MAX * 2, 0) * HL2_BOB_CYCLE_MAX * 2
	cycle = cycle / (HL2_BOB_CYCLE_MAX * 2)

	if cycle < HL2_BOB_UP then
		cycle = PI * (cycle / HL2_BOB_UP)
	else
		cycle = PI + PI * (cycle - HL2_BOB_UP) / (1.0 - HL2_BOB_UP)
	end

	local lateralBob = speed * 0.005
	lateralBob = lateralBob * 0.3 + lateralBob * 0.7 * math.sin(cycle)
	lateralBob = math.Clamp(lateralBob, -7.0, 4.0)

	local fwd = oldAng:Forward()
	local right = oldAng:Right()

	local newPos = oldPos + (fwd * (vertBob * 0.1))
	newPos.z = (newPos.z or 0) + (vertBob * 0.1)

	local newAng = oldAng
	newAng.roll = newAng.roll + (vertBob * 0.5)
	newAng.pitch = newAng.pitch - (vertBob * 0.4)
	newAng.yaw = newAng.yaw - (lateralBob * 0.3)

	newPos = newPos + (right * (lateralBob * 0.8))

	return newPos, newAng

end

local HL2_MAX_VIEWMODEL_LAG = 0.4

function GM:CalcViewModelLag( wep, vm, oldPos, oldAng, pos, ang )

	local fwd = oldAng:Forward()

	local newPos = oldPos
	local newAng = oldAng

	self.LastViewDir = self.LastViewDir or fwd

	local dt = SysTime() - (self.LastViewLag or SysTime())
	self.LastViewLag = SysTime()

	if dt >= HL2_MAX_VIEWDT then
		dt = HL2_MAX_VIEWDT
	end

	dt = dt * GetTimeScale()

	local frameTime = dt
	if frameTime ~= 0.0 then

		local diff = fwd - self.LastViewDir
		local speed = 0.8

		local len = diff:Length()
		if len > HL2_MAX_VIEWMODEL_LAG and HL2_MAX_VIEWMODEL_LAG > 0.0 then
			local scale = len / HL2_MAX_VIEWMODEL_LAG
			speed = speed * scale
		end

		self.LastViewDir = self.LastViewDir + (diff * (speed * frameTime))
		self.LastViewDir:Normalize()

		newPos = oldPos + (diff * -1.0 * speed)

	end

	local up = oldAng:Up()
	local right = oldAng:Right()

	local pitch = oldAng.pitch
	if pitch > 180 then
		pitch = pitch - 360
	elseif pitch < -180 then
		pitch = pitch + 360
	end

	newPos = newPos + (fwd * (-pitch * 0.035))
	newPos = newPos + (right * (-pitch * 0.03))
	newPos = newPos + (up * (-pitch * 0.03))

	return newPos, newAng

end

function GM:CalcViewModelView( wep, vm, oldPos, oldAng, vm_origin, vm_angles )

	if not IsValid( wep ) then
		 return
	 end

	local modified = false

	-- Controls the position of all viewmodels
	local func = wep.GetViewModelPosition
	if ( func ) then
		local pos, ang = func(wep, vm_origin * 1, vm_angles * 1)
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
		modified = true
	end

	-- Controls the position of individual viewmodels
	func = wep.CalcViewModelView
	if ( func ) then
		local pos, ang = func(wep, ViewModel, oldPos * 1, oldAng * 1, vm_origin * 1, vm_angles * 1)
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
		modified = true
	end

	-- Lets not mess with custom stuff
	if modified then
		return vm_origin, vm_angles
	end

	local newPos = oldPos
	local newAng = oldAng

	newPos, newAng = self:CalcViewModelBob(wep, vm, newPos, newAng, vm_origin, vm_angles)
	newPos, newAng = self:CalcViewModelLag(wep, vm, newPos, newAng, vm_origin, vm_angles)

	return newPos, newAng

end

function GM:CalcView(ply, pos, ang, fov, nearZ, farZ)

	local view = {}
	view.origin = pos
	view.angles = ang
	view.fov = fov
	view.znear = znear
	view.zfar = zfar
	view.drawviewer	= false

	local viewlock = ply:GetViewLock()
	local lastViewLock = ply.LastViewLock or -1
	ply.LastViewLock = viewlock

	if viewlock == VIEWLOCK_ANGLE then

		view.angles = ply:GetNW2Angle("LockedViewAngles")
		view.fov = fov
		view.origin = pos
		return view

	elseif viewlock == VIEWLOCK_NPC or viewlock == VIEWLOCK_PLAYER then

		local npc = ply:GetNW2Entity("LockedViewEntity")
		if IsValid(npc) then
			view.angles = (npc:EyePos() - ply:EyePos()):Angle()
			view.fov = fov
			view.origin = pos
			return view
		end

	elseif viewlock == VIEWLOCK_SETTINGS_ON then

		local timeSet = ply:GetNW2Float("ViewLockTime", CurTime())
		local elapsed = CurTime() - timeSet
		local p = elapsed / VIEWLOCK_RELEASE_TIME

		if lastViewLock ~= viewlock then
			self.StartViewPos = pos
			self.StartViewAng = ang
		end

		if p < 1 then
			local targetPos = ply:EyePos()
			local plyAng = ply:GetAngles()
			plyAng.p = 0
			local fwd = plyAng:Forward() + (-plyAng:Right() * 0.3)
			targetPos = targetPos + (fwd * 150)

			local targetAng = (pos - targetPos):Angle()

			self.CurrentViewPos = LerpVector(p, self.StartViewPos, targetPos)
			self.CurrentViewAng = LerpAngle(p, self.StartViewAng, targetAng)
		end

		view.origin = self.CurrentViewPos
		view.angles = self.CurrentViewAng
		view.drawviewer = true

		return view

	elseif viewlock == VIEWLOCK_SETTINGS_RELEASE then

		local timeSet = ply:GetNW2Float("ViewLockTime", CurTime())
		local elapsed = CurTime() - timeSet
		local p = elapsed / VIEWLOCK_RELEASE_TIME

		if lastViewLock ~= viewlock then
			self.StartViewPos = self.CurrentViewPos
			self.StartViewAng = self.CurrentViewAng
		end

		if p < 1 then
			local targetPos = ply:EyePos()
			local targetAng = ply:EyeAngles()

			self.CurrentViewPos = LerpVector(p, self.StartViewPos, targetPos)
			self.CurrentViewAng = LerpAngle(p, self.StartViewAng, targetAng)
		end

		view.origin = self.CurrentViewPos
		view.angles = self.CurrentViewAng

		return view

	else

		self.StartViewPos = pos
		self.StartViewAng = ang

		local vehicle = ply:GetVehicle()
		if IsValid( vehicle ) then
			return hook.Run( "CalcVehicleView", vehicle, ply, view )
		end

	end

	return view

end

function GM:ShouldDrawLocalPlayer(ply)

	local vehicle = ply:GetVehicle()
	if vehicle ~= nil and IsValid(vehicle) then
		local class = vehicle:GetClass()
		if class == "prop_vehicle_jeep" or class == "prop_vehicle_airboat" then
			ply.VehicleSteeringView = true
			return true
		end
	else
		ply.VehicleSteeringView = false
	end

	local viewlock = ply:GetViewLock()
	if viewlock == VIEWLOCK_SETTINGS_ON or viewlock == VIEWLOCK_SETTINGS_RELEASE then
		return true
	end

end
