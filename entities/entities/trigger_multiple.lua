if SERVER then

ENT.Base = "lambda_trigger"
ENT.Type = "brush"

DEFINE_BASECLASS( "lambda_trigger" )

function ENT:Initialize()

	--DbgPrint(self, "trigger_multiple:Initialize")

	BaseClass.Initialize(self)
	BaseClass.SetWaitTime(self, 0.2) -- Remove once triggered.

end

end
