--local DbgPrint = print
local DbgPrint = GetLogging("LogicAuto")
-- Spawnflags.
local SF_AUTO_FIREONCE = 0x0001
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

    self:SetupNWVar("Disabled", "bool", {
        Default = true,
        KeyValue = "StartDisabled"
    })

    self:SetupNWVar("GlobalState", "string", {
        Default = "",
        KeyValue = "globalstate"
    })
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
    self:NextThink(CurTime() + 0.2)
end

function ENT:Think()
    if self:GetNWVar("Disabled") == true then
        self:NextThink(CurTime() + 1)

        return true
    end

    self:NextThink(CurTime() + 0.2)
    local globalState = self:GetNWVar("GlobalState")
    if globalState ~= "" and game.GetGlobalState(globalState) ~= GLOBAL_ON then return true end
    local loadType = ""

    if GAMEMODE ~= nil then
        loadType = GAMEMODE:GetMapLoadType()
    else
        loadType = game.MapLoadType()
    end

    if loadType == "transition" then
        self:FireOutputs("OnMapTransition", nil, nil)
    elseif loadType == "newgame" then
        self:FireOutputs("OnNewGame", nil, nil)
    elseif loadType == "loadgame" then
        self:FireOutputs("OnLoadGame", nil, nil)
    elseif loadType == "background" then
        self:FireOutputs("OnBackgroundMap", nil, nil)
    end

    -- Fires without condition.
    self:FireOutputs("OnMapSpawn", nil, nil)

    if self:HasSpawnFlags(SF_AUTO_FIREONCE) == true then
        self.Think = function() end
        self:Remove()
    else
        -- Stay dormant, for whatever reason.
        self:Disable()
    end

    return true
end

function ENT:Enable()
    self:SetNWVar("Disabled", false)
    self:NextThink(CurTime())
end

function ENT:Disable()
    self:SetNWVar("Disabled", true)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_NEVER
end