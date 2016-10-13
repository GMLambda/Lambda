if SERVER then

ENT.Base = "lambda_trigger"
ENT.Type = "brush"

DEFINE_BASECLASS( "lambda_trigger" )

function ENT:Initialize()

	--DbgPrint(self, "trigger_once:Initialize")

	BaseClass.Initialize(self)
	BaseClass.SetWaitTime(self, 0) -- Never remove.

	self:AddSolidFlags(FSOLID_TRIGGER_TOUCH_DEBRIS)

end

function ENT:PassesTriggerFilters(ent)

	return true -- Anything goes in here.

end

function ENT:StartTouch(ent)

	--DbgPrint(self, "StartTouch(" .. tostring(ent) .. ")")
	return BaseClass.StartTouch(self, ent)

end

function ENT:Touch(ent)

	--DbgPrint(self, "Touch(" .. tostring(ent) .. ")")
	return BaseClass.Touch(self, ent)

end


end
