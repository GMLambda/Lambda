local DbgPrint = GetLogging("Level")

if SERVER then
    ENT.Base = "lambda_trigger"
    ENT.Type = "brush"
    DEFINE_BASECLASS("lambda_trigger")
    SF_CHANGELEVEL_NOTOUCH = 0x0002
    SF_CHANGELEVEL_CHAPTER = 0x0004
    SF_CHANGELEVEL_RESTART = 0x0008

    function ENT:PreInitialize()
        BaseClass.PreInitialize(self)
        BaseClass.SetWaitTime(self, -1) -- Remove once triggered.
        self:SetInputFunction("ChangeLevel", self.InputChangeLevel)
        self.TargetMap = ""
        self.Landmark = ""
        self.DisableTouch = false
    end

    function ENT:Initialize()
        BaseClass.Initialize(self)

        local timeout = GAMEMODE:GetSetting("map_change_timeout")
        self:SetKeyValue("teamwait", "1")
        self:SetKeyValue("timeout", timeout)
        self:SetKeyValue("lockplayers", "1")
        self:SetKeyValue("timeoutteleport", "0")
        self:SetNWVar("DisableEndTouch", true)
        self:AddSpawnFlags(SF_TRIGGER_ALLOW_CLIENTS)
    end

    function ENT:KeyValue(key, val)
        BaseClass.KeyValue(self, key, val)

        if key:iequals("landmark") then
            self.Landmark = val
        elseif key:iequals("map") then
            self.TargetMap = val
        end
    end

    function ENT:EndTouch(ent)
        if self:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then return end

        return BaseClass.EndTouch(self, ent)
    end

    function ENT:Touch(ent)
        if self:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then return end

        return BaseClass.Touch(self, ent)
    end

    function ENT:StartTouch(ent)
        if self:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then return end

        return BaseClass.StartTouch(self, ent)
    end

    function ENT:OnTrigger()
        DbgPrint(self, "OnTrigger")
        self:DoChangeLevel()
    end

    function ENT:InputChangeLevel()
        DbgPrint(self, "InputChangeLevel")
        self:DoChangeLevel()
    end

    function ENT:DoChangeLevel()
        DbgPrint(self, "DoChangeLevel")
        local restart = self:HasSpawnFlags(SF_CHANGELEVEL_RESTART)
        local touchingObjects = self:GetTouchingObjects()

        if self.Landmark ~= nil and self.Landmark ~= "" then
            for _, landmark in pairs(ents.FindByName(self.Landmark)) do
                if landmark:GetClass() == "trigger_transition" and landmark.GetTouching ~= nil then
                    for _, v in pairs(landmark:GetTouching()) do
                        touchingObjects[v:EntIndex()] = v
                    end
                end
            end
        end

        GAMEMODE:RequestChangeLevel(self, string.lower(self.TargetMap), self.Landmark, touchingObjects, restart)
    end
end