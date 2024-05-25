if SERVER then
    ENT.Base = "lambda_trigger"
    ENT.Type = "brush"
    DEFINE_BASECLASS("lambda_trigger")

    function ENT:PreInitialize()
        BaseClass.PreInitialize(self)
        BaseClass.SetWaitTime(self, -1) -- Remove once triggered.
    end
end