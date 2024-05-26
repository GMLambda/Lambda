local DbgPrint = GetLogging("LuaLogic")
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetInputFunction("RunLua", self.InputRunLua)
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
end

function ENT:InputRunLua(data, activator, caller)
    if self.OnRunLua ~= nil then
        self:OnRunLua(data, activator, caller)
    else
        DbgPrint(self, "No OnRunLua function defined.")
    end
end

function ENT:OnRunLua(data, activator, caller)
    -- Override this function.
end

function ENT:UpdateTransmitState()
    return TRANSMIT_NEVER
end