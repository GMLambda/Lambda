if SERVER then

ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS( "lambda_entity" )

function ENT:PreInitialize()

	BaseClass.PreInitialize(self)
	--self:SetInputFunction("ShowMessage", self.InputCommand)

end

function ENT:Initialize()

	BaseClass.Initialize(self)

end

function ENT:KeyValue(key, val)

    BaseClass.KeyValue(self, key, val)

end

end
