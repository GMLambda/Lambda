local DbgPrint = GetLogging("Trigger")

if SERVER then

ENT.Base = "lambda_trigger"
ENT.Type = "brush"

DEFINE_BASECLASS( "lambda_trigger" )

SF_CHANGELEVEL_NOTOUCH = 0x0002
SF_CHANGELEVEL_CHAPTER = 0x0004

function ENT:PreInitialize()

    BaseClass.PreInitialize(self)

    self:SetInputFunction("ChangeLevel", self.OnTrigger)

    self.TargetMap = ""
    self.Landmark = ""
    self.DisableTouch = false

end

function ENT:Initialize()

    local timeout = GAMEMODE:GetSetting("map_change_timeout")
    
    self:SetKeyValue("teamwait", "1")
    self:SetKeyValue("timeout", timeout)
    self:SetKeyValue("lockplayers", "1")
    self:SetNWVar("DisableEndTouch", true)

    self:AddSpawnFlags(SF_TRIGGER_ALLOW_CLIENTS)

    BaseClass.Initialize(self)
    BaseClass.SetWaitTime(self, -1) -- Remove once triggered.

end

function ENT:KeyValue( key, val )

    BaseClass.KeyValue(self, key, val)

    if key:iequals("landmark") then
        self.Landmark = val
    elseif key:iequals("map") then
        self.TargetMap = val
    end

end

function ENT:EndTouch(ent)
    if self:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then
        return
    end
    return BaseClass.EndTouch(self, ent)
end

function ENT:Touch(ent)
    if self:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then
        return
    end
    return BaseClass.Touch(self, ent)
end

function ENT:StartTouch(ent)
    if self:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then
        return
    end
    return BaseClass.StartTouch(self, ent)
end

function ENT:OnTrigger()

    DbgPrint("CHANGELEVEL")
    GAMEMODE:ChangeLevel(self, string.lower(self.TargetMap), self.Landmark, self:GetTouchingObjects())

end

end
