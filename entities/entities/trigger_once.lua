if SERVER then

ENT.Base = "lambda_trigger"
ENT.Type = "brush"

DEFINE_BASECLASS( "lambda_trigger" )

function ENT:Initialize()

	--DbgPrint(self, "trigger_once:Initialize")

	BaseClass.Initialize(self)
	BaseClass.SetWaitTime(self, -1) -- Remove once triggered.

end

end
