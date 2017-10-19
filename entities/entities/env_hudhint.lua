if SERVER then

	util.AddNetworkString("LambdaHintText")

	SF_HUDHINT_ALLPLAYERS = 1

	ENT.Base = "lambda_entity"
	ENT.Type = "point"

	DEFINE_BASECLASS( "lambda_entity" )

	function ENT:PreInitialize()

		BaseClass.PreInitialize(self)

		self:SetInputFunction("ShowHudHint", self.InputShowHudHint)
		self:SetInputFunction("HideHudHint", self.InputHideHudHint)
		self.Message = ""

	end

	function ENT:Initialize()

		BaseClass.Initialize(self)

		self:AddSpawnFlags(SF_HUDHINT_ALLPLAYERS)

	end

	function ENT:KeyValue(key, val)

	    BaseClass.KeyValue(self, key, val)

		--DbgPrint(self, key, val)
		if key:iequals("message") == true then
			self.Message = val
		end

	end

	function ENT:InputShowHudHint(data, activator, caller)

		DbgPrint("Showing hint")

		GAMEMODE:AddHint(self.Message, 10)

	end

	function ENT:InputHideHudHint(data, activator, caller)



	end

	function ENT:Command(data, activator, caller)

	end

end
