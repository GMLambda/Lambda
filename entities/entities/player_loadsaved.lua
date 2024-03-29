if SERVER then
    ENT.Base = "lambda_entity"
    ENT.Type = "point"
    DEFINE_BASECLASS("lambda_entity")

    function ENT:PreInitialize()
        BaseClass.PreInitialize(self)
        self:SetInputFunction("Reload", self.InputReload)
        self:SetInputFunction("RestartRound", self.InputRestartRound)
    end

    function ENT:Initialize()
        BaseClass.Initialize(self)
    end

    function ENT:KeyValue(key, val)
        BaseClass.KeyValue(self, key, val)
    end

    function ENT:InputReload(data, activator, caller)
        --GAMEMODE:RestartRound()
        return true
    end

    function ENT:InputRestartRound(data, activator, caller)
        GAMEMODE:RestartRound(data)

        return true
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_NEVER
    end
end