if SERVER then
    ENT.Base = "lambda_entity"
    ENT.Type = "point"
    DEFINE_BASECLASS("lambda_entity")

    function ENT:PreInitialize()
        BaseClass.PreInitialize(self)
        self:SetInputFunction("Command", self.InputCommand)
    end

    function ENT:Initialize()
        BaseClass.Initialize(self)
    end

    function ENT:KeyValue(key, val)
        BaseClass.KeyValue(self, key, val)
    end

    function ENT:InputCommand(data, activator, caller)
        DbgPrint("Command: " .. data .. ", " .. tostring(activator) .. ", " .. tostring(caller))

        return self:Command(data, activator, caller)
    end

    function ENT:Command(data, activator, caller)
        -- Stub
    end
end