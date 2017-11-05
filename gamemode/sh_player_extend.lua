AddCSLuaFile()

local DbgPrint = GetLogging("PlayerExt")
local PLAYER_META = FindMetaTable("Player")

VIEWLOCK_NONE = 0
VIEWLOCK_ANGLE = 1
VIEWLOCK_NPC = 2
VIEWLOCK_PLAYER = 3
VIEWLOCK_SETTINGS_ON = 4
VIEWLOCK_SETTINGS_RELEASE = 5

VIEWLOCK_RELEASE_TIME = 1.0 -- Seconds

if SERVER then

	function PLAYER_META:TeleportPlayer(pos, ang, vel)
		local data = {}
		data.vel = vel or self:GetVelocity()
		data.ang = ang or self:GetAngles()
		data.pos = pos or Vector(0, 0, 0)
		self.TeleportQueue = self.TeleportQueue or {}
		table.insert(self.TeleportQueue, data)
	end

	function PLAYER_META:DisablePlayerCollide(state, temporarily)
		if state == true then
			self.NextPlayerCollideTest = CurTime() + 2
		end
		if temporarily == nil then
			temporarily = true
		end
		self:SetNW2Bool("DisablePlayerCollide", state)
		self.DisablePlayerCollisionTemporarily = temporarily
		self:CollisionRulesChanged()
		DbgPrint(self, "DisablePlayerCollide", tostring(state))
	end

	function PLAYER_META:LockPosition(poslock, viewlock, viewdata)

		poslock = poslock or false
		viewlock = viewlock or VIEWLOCK_NONE

		self.PositionLocked = self.PositionLocked or false
		self.ViewLocked = self.ViewLocked or false

		if poslock == true then
			DbgPrint("Locking player position: " .. tostring(self))
		else
			DbgPrint("Unlocking player position: " .. tostring(self))
			viewlock = VIEWLOCK_NONE
		end

		local prevPositionLock = self.PositionLocked
		local prevViewLocked = self.ViewLocked

		self.PositionLocked = poslock
		self.ViewLock = viewlock
		self.LockedViewAngles = viewdata
		self:SetNoTarget(poslock)
		self:SetNW2Bool("PositionLocked", poslock)
		self:SetNW2Int("ViewLock", viewlock)
		self:SetNW2Float("ViewLockTime", CurTime())
		self:DisablePlayerCollide(poslock)

		if viewlock == VIEWLOCK_ANGLE then
			self:SetNW2Angle("LockedViewAngles", viewdata)
		elseif viewlock == VIEWLOCK_NPC then
			self:SetNW2Entity("LockedViewEntity", viewdata)
		elseif viewlock == VIEWLOCK_SETTINGS_RELEASE then
			-- Dealt within sh_lambda_player:PlayerThink
		end

		if self.PositionLocked ~= prevPositionLock or self.ViewLock ~= prevViewLocked then
			hook.Call("Lambda_PlayerLockChanged", GAMEMODE, poslock, viewlock, viewdata)
		end

	end

end -- SERVER

function PLAYER_META:IsPositionLocked()

	if SERVER then
		self.PositionLocked = self.PositionLocked or false
		return self.PositionLocked
	end

	return self:GetNW2Bool("PositionLocked", false)

end

function PLAYER_META:GetViewLockTime()
	return self:GetNW2Float("ViewLockTime", CurTime())
end

function PLAYER_META:GetGender()
	return self:GetNW2String("Gender", "male")
end

function PLAYER_META:GetViewLock()

	if SERVER then
		self.ViewLock = self.ViewLock or VIEWLOCK_NONE
		return self.ViewLock
	end

	return self:GetNW2Int("ViewLock", VIEWLOCK_NONE)

end

function PLAYER_META:GetNearestRadiationRange()
	return self:GetNW2Int("LambdaRadiationRange", 1000)
end

function PLAYER_META:SetNearestRadiationRange(range, override)

	local current = self:GetNearestRadiationRange()

	if override == true then
		current = range
	else
		if current >= range then
			current = range
		end
	end

	self:SetNW2Int("LambdaRadiationRange", current)

end

function PLAYER_META:SetGeigerRange(range)
	self:SetNW2Int("LambdaGeigerRange", range)
end

function PLAYER_META:GetGeigerRange()
	return self:GetNW2Int("LambdaGeigerRange", 1000)
end

function PLAYER_META:AddSuitDevice(device)
	self.SuitDevices = self.SuitDevices or {}
	self.SuitDevices[device] = true
end

function PLAYER_META:RemoveSuitDevice(device)
	self.SuitDevices = self.SuitDevices or {}
	self.SuitDevices[device] = false
end

function PLAYER_META:GetSuitDevices()
	self.SuitDevices = self.SuitDevices or {}
	return table.Copy(self.SuitDevices)
end

function PLAYER_META:UsingSuitDevice(device)
	self.SuitDevices = self.SuitDevices or {}
	return self.SuitDevices[device] or false
end

function PLAYER_META:GetFlexIndexByName(name)

	self.LastModelName = self.LastModelName or ""
	self.FlexIndexCache = self.FlexIndexCache or {}
	local mdl = self:GetModel()

	if mdl ~= self.LastModelName then
		self.LastModelName = mdl
		self.FlexIndexCache = {}
		local count = self:GetFlexNum() - 1
		if count <= 0 then return end

		for i = 0, count do
			local flexName = self:GetFlexName(i)
			self.FlexIndexCache[flexName] = i
		end
	end

	return self.FlexIndexCache[name]

end

function PLAYER_META:GetSpawnTime()
	return self.LambdaSpawnTime or CurTime()
end

function PLAYER_META:GetLifeTime()
	return CurTime() - self:GetSpawnTime()
end

function PLAYER_META:IsInactive()
	return self:GetNW2Bool("Inactive", true)
end

function PLAYER_META:SetInactive(state)
	self:SetNW2Bool("Inactive", state)
end

-- 		ply:NetworkVar("Float", 0, "SuitPower")
function PLAYER_META:SetSuitPower(val)
	self:SetNW2Float("SuitPower", val)
end
function PLAYER_META:GetSuitPower()
	return self:GetNW2Float("SuitPower", 0.0)
end

--		ply:NetworkVar("Float", 1, "SuitEnergy")
function PLAYER_META:SetSuitEnergy(val)
	self:SetNW2Float("SuitEnergy", val)
end
function PLAYER_META:GetSuitEnergy()
	return self:GetNW2Float("SuitEnergy", 0.0)
end

--		ply:NetworkVar("Bool", 0, "Sprinting")
function PLAYER_META:SetSprinting(val)
	self:SetNW2Bool("Sprinting", val)
end
function PLAYER_META:GetSprinting()
	return self:GetNW2Bool("Sprinting", false)
end

--		ply:NetworkVar("Bool", 1, "StateSprinting")
function PLAYER_META:SetStateSprinting(val)
	self:SetNW2Bool("StateSprinting", val)
end

function PLAYER_META:GetStateSprinting()
	return self:GetNW2Bool("StateSprinting", false)
end

function PLAYER_META:IsSprinting()
	return self:GetSprinting()
end

-- Override the non-functional one.
function PLAYER_META:StopSprinting()
	self:SetSprinting(false)
end
