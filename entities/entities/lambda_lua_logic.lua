local DbgPrint = GetLogging("LuaLogic")
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetInputFunction("RunLua", self.OnRunLua)
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
end

function ENT:OnRunLua(data, activator, caller)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_NEVER
end