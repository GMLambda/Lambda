include("shared.lua")
include("cl_postprocess.lua")
include("cl_ragdoll_ext.lua")
include("cl_taunts.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")

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

function GM:Think()

	local scrW = ScrW()
	local scrH = ScrH()

	self.CurResW = self.CurResW or scrW
	self.CurResH = self.CurResH or scrH

	local resChanged = false

	if self.CurResW ~= scrW or self.CurResH ~= scrH then
		resChanged = true
	end

	if resChanged then

		local self = self
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

	for _,v in pairs(player.GetAll()) do
		self:PlayerThink(v)
	end

end

local BOBTIME = 0
local LAST_BOBTIME = CurTime()
local HL2_BOB_CYCLE_MAX = 0.40
local HL2_BOB_UP = 0.5
local MAX_SPEED = 320
local PI = math.pi
local PLAYER_SPEED = 0

local host_timescale = GetConVar("host_timescale")
local function GetTimeScale()
	if host_timescale:GetFloat() ~= 1 then
		return host_timescale:GetFloat()
	end
	return game.GetTimeScale()
end

function GM:CalcViewModelBob( wep, vm, oldPos, oldAng, pos, ang )

	local ply = LocalPlayer()

	local dt = SysTime() - (self.LastViewBob or SysTime())
	self.LastViewBob = SysTime()

	if dt >= 1/60 then
		dt = 1/60
	end

	dt = dt * GetTimeScale()

	local speed = Lerp(dt * 10, PLAYER_SPEED, ply:GetVelocity():Length2D())
	PLAYER_SPEED = speed

	speed = math.Clamp(speed, -MAX_SPEED, MAX_SPEED)

	-- NOTE: Using 0.0 instead of 0.1 causes weird behavior, hl2 uses 0.0 but lets not make it uglier than required.
	local bob_offset = math.Remap(speed, 0, MAX_SPEED, 0.0, 1.0)

	BOBTIME = BOBTIME + (dt * 1.3) * bob_offset
	LAST_BOBTIME = BOBTIME

	local cycle = BOBTIME - math.Round(BOBTIME / HL2_BOB_CYCLE_MAX, 0) * HL2_BOB_CYCLE_MAX
	cycle = cycle / HL2_BOB_CYCLE_MAX

	if cycle < HL2_BOB_UP then
		cycle = PI * (cycle / HL2_BOB_UP)
	else
		cycle = PI + PI * ((cycle - HL2_BOB_UP) / (1.0 - HL2_BOB_UP))
	end

	local vertBob = speed * 0.005
	vertBob = vertBob * 0.3 + vertBob * 0.7 * math.sin(cycle)
	vertBob = math.Clamp(vertBob, -7.0, 4.0)

	cycle = BOBTIME - math.Round(BOBTIME / HL2_BOB_CYCLE_MAX * 2, 0) * HL2_BOB_CYCLE_MAX * 2
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
	newPos.z = newPos.z + (vertBob * 0.1)

	local newAng = oldAng
	newAng.roll = newAng.roll + (vertBob * 0.5)
	newAng.pitch = newAng.pitch - (vertBob * 0.4)
	newAng.yaw = newAng.yaw - (lateralBob * 0.3)

	newPos = newPos + (right * (lateralBob * 0.8))

	return newPos, newAng

end

local LastFacing = Vector(0, 0, 0)
local MaxViewModelLag = 0.4

function GM:CalcViewModelLag( wep, vm, oldPos, oldAng, pos, ang )

	local fwd = oldAng:Forward()

	local newPos = oldPos
	local newAng = oldAng

	local dt = SysTime() - (self.LastViewLag or SysTime())
	self.LastViewLag = SysTime()

	if dt >= 1/60 then
		dt = 1/60
	end

	dt = dt * GetTimeScale()

	local frameTime = dt
	if frameTime ~= 0.0 then

		local diff = fwd - LastFacing
		local speed = 0.8

		local len = diff:Length()
		if len > MaxViewModelLag and MaxViewModelLag > 0.0 then
			local scale = len / MaxViewModelLag
			speed = speed * scale
		end

		LastFacing = LastFacing + (diff * (speed * frameTime))

		LastFacing:Normalize()

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

local HEAD_POS
local HEAD_POS_DELTA = Vector(0, 0, 0)

function GM:CalcViewModelView( wep, vm, oldPos, oldAng, pos, ang )

	if not IsValid( wep ) then
		 return
	 end

	local vm_origin, vm_angles = pos, ang
	local modified = false

	-- Controls the position of all viewmodels
	local func = wep.GetViewModelPosition
	if ( func ) then
		local pos, ang = func(wep, pos * 1, ang * 1)
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
		modified = true
	end

	-- Controls the position of individual viewmodels
	func = wep.CalcViewModelView
	if ( func ) then
		local pos, ang = func(wep, ViewModel, oldPos * 1, oldAng * 1, pos * 1, ang * 1)
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
		modified = true
	end

	-- Lets not mess with custom stuff
	if modified then
		return vm_origin, vm_angles
	end

	local newPos = oldPos
	newPos = newPos + HEAD_POS_DELTA
	local newAng = oldAng

	newPos, newAng = self:CalcViewModelBob(wep, vm, newPos, newAng, pos, ang)
	newPos, newAng = self:CalcViewModelLag(wep, vm, newPos, newAng, pos, ang)

	return newPos, newAng

end

function GM:CalcView(ply, pos, ang, fov, nearZ, farZ)

	local view = {}
	view.origin = pos
	view.ang = ang
	view.fov = fov
	view.angles = ang

	local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
	local headPos
	if headBone ~= nil then
	 	headPos = ply:GetBonePosition(headBone)
	else
		headPos = ply:EyePos()
	end

	local t = RealFrameTime() * 5

	HEAD_POS = LerpVector(t, HEAD_POS or headPos, headPos)

	local deltaX = (HEAD_POS.x - view.origin.x) * 0.05
	local deltaY = (HEAD_POS.y - view.origin.y) * 0.05
	local deltaZ = (HEAD_POS.z - view.origin.z) * 0.16

	if ply:IsSpectator() == false then
		HEAD_POS_DELTA = Vector(deltaX, deltaY, deltaZ)
	else
		HEAD_POS_DELTA = Vector(0, 0, 0)
	end

	view.origin = view.origin + HEAD_POS_DELTA

	local viewlock = ply:GetViewLock()

	if viewlock == VIEWLOCK_ANGLE then

		view.angles = ply:GetNWAngle("LockedViewAngles")
		view.fov = fov
		view.origin = pos
		return view

	elseif viewlock == VIEWLOCK_NPC or viewlock == VIEWLOCK_PLAYER then

		local npc = ply:GetNWEntity("LockedViewEntity")
		if IsValid(npc) then
			view.angles = (npc:EyePos() - ply:EyePos()):Angle()
			view.fov = fov
			view.origin = pos
			return view
		end

	else

		local Vehicle = ply:GetVehicle()
		if IsValid( Vehicle ) then
			return hook.Run( "CalcVehicleView", Vehicle, ply, view )
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

end
