--local DbgPrint = print
local DbgPrint = GetLogging("LogicAuto")

-- Spawnflags.
local SF_AUTO_FIREONCE = 0x0001
local SF_AUTO_FIREONRELOAD = 0x0002

ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
	BaseClass.PreInitialize(self)
	DbgPrint(self, "PreInitialize")

	self:SetupOutput("OnMapSpawn")
	self:SetupOutput("OnNewGame")
	self:SetupOutput("OnLoadGame")
	self:SetupOutput("OnMapTransition")
	self:SetupOutput("OnBackgroundMap")
	self:SetupOutput("OnMultiNewMap")
	self:SetupOutput("OnMultiNewRound")

	self:SetInputFunction("Enable", self.Enable)
	self:SetInputFunction("Disable", self.Disable)

	self:SetupNWVar("Disabled", "bool", { Default = true, KeyValue = "StartDisabled" })
	self:SetupNWVar("GlobalState", "string", { Default = "", KeyValue = "globalstate" })
end

function ENT:Initialize()
	BaseClass.Initialize(self)
	DbgPrint(self, "Initialize")

	self:NextThink(CurTime() + 0.2)
end

function ENT:Think()

	self:NextThink(CurTime() + 0.2)

	if self:GetNWVar("Disabled") == true then 
		return true
	end 

	local globalState = self:GetNWVar("GlobalState")
	if globalState ~= "" and game.GetGlobalState(globalState) ~= GLOBAL_ON then 
		return true
	end

	local loadType = ""
	local mapScript = nil
	if GAMEMODE ~= nil then 
		loadType = GAMEMODE:GetMapLoadType()
		mapScript = GAMEMODE:GetMapScript()
	else 
		loadType = game.MapLoadType()
	end 

	if loadType == "transition" then 
		if mapScript ~= nil and mapScript.OnMapTransition ~= nil then
			mapScript:OnMapTransition()
		end
		self:FireOutputs("OnMapTransition", nil, nil)
	elseif loadType == "newgame" then 
		if mapScript ~= nil and mapScript.OnNewGame ~= nil then
			mapScript:OnNewGame()
		end
		self:FireOutputs("OnNewGame", nil, nil)
	elseif loadType == "loadgame" then 
		if mapScript ~= nil and mapScript.OnLoadGame ~= nil then
			mapScript:OnLoadGame()
		end
		self:FireOutputs("OnLoadGame", nil, nil)
	elseif loadType == "background" then 
		if mapScript ~= nil and mapScript.OnBackgroundMap ~= nil then
			mapScript:OnBackgroundMap()
		end
		self:FireOutputs("OnBackgroundMap", nil, nil)
	end

	-- Fires without condition.
	self:FireOutputs("OnMapSpawn", nil, nil)

	if self:HasSpawnFlags(SF_AUTO_FIREONCE) == true then 
		self.Think = function() end
		self:Remove()
	end

	return true

end 

function ENT:Enable()
	self:SetNWVar("Disabled", false)
end 

function ENT:Disable()
	self:SetNWVar("Disabled", true)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end
