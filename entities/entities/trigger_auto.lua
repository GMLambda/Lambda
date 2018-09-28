--local DbgPrint = print
-- REFACTOR ME: lambad_entity as base
local DbgPrint = GetLogging("TriggerAuto")

-- Spawnflags.
SF_AUTO_FIREONCE = 0x0001

ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
	BaseClass.PreInitialize(self)
	DbgPrint(self, "PreInitialize")

	self:SetupOutput("OnTrigger")
end

function ENT:Initialize()
	BaseClass.Initialize(self)
	DbgPrint(self, "Initialize")

	self.Disabled = true
end

function ENT:AcceptInput(inputName, activator, called, data)
	if inputName:iequals("enable") then
		DbgPrint(self, "Enabled")
		self.Disabled = false
		return true
	elseif inputName:iequals("disable") then
		DbgPrint(self, "Disabled")
		self.Disabled = true
		return true
	end
	return BaseClass.AcceptInput(self, inputName, activator, called, data)
end

function ENT:Think()
	if self.Disabled == true then
		return
	end
	if self.GlobalState == nil or game.GetGlobalState(self.GlobalState) == GLOBAL_ON then
		DbgPrint(self, "Firing OnTrigger")
		self:FireOutputs("OnTrigger", nil, self)
		if self:HasSpawnFlags(SF_AUTO_FIREONCE) then
			self.Disabled = true
			self:Remove()
		end
	end
end

function ENT:KeyValue( key, val )

	BaseClass.KeyValue(self, key, val)

	DbgPrint(self, "KeyValue(" .. key .. ", " .. val .. ")")

	if key:iequals("globalstate") then
		self.GlobalState = val
	end

end

function ENT:OnRemove()
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end
