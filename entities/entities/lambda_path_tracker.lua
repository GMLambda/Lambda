local DbgPrint = GetLogging("PathTracker")

ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
	BaseClass.PreInitialize(self)
	DbgPrint(self, "PreInitialize")

	self:SetInputFunction("OnPass", self.OnPass)
end

function ENT:Initialize()
	BaseClass.Initialize(self)
	DbgPrint(self, "Initialize")
end

-- HACKHACK: Since we can't call CBaseEntity::OnRestore we have to manually
-- set the next track target.
function ENT:OnPass(data, activator, caller)
	local nextTarget = caller:SafeGetInternalVariable("target")
	DbgPrint(self, "Passed : " .. tostring(activator), caller, nextTarget)
	activator:SetSaveValue("target", nextTarget)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end
