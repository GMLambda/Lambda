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
        self:SetupOutput("OnChangeLevel")
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

        self:FireOutputs("OnChangeLevel", nil, nil)

        local restart = self:HasSpawnFlags(SF_CHANGELEVEL_RESTART)
        local touchingObjects = self:GetTouchingObjects()
        local targetMap = string.lower(self.TargetMap)
        local landmarkName = self.Landmark

        if landmarkName ~= nil and landmarkName ~= "" then
            for _, landmark in pairs(ents.FindByName(landmarkName)) do
                if landmark:GetClass() == "trigger_transition" and landmark.GetTouching ~= nil then
                    for _, v in pairs(landmark:GetTouching()) do
                        touchingObjects[v:EntIndex()] = v
                    end
                end
            end
        end

        -- Because OnChangeLevel might do some things we have to delay this a bit.
        util.RunDelayed(function()
            -- Remove invalid entities from touching objects, might have been killed by OnChangeLevel.
            for k, v in pairs(touchingObjects) do
                local ent = Entity(k)
                if not IsValid(ent) or ent:IsEFlagSet(EFL_KILLME) then
                    DbgPrint("Removing killed entity #" .. tostring(k) .. " from touch list.")
                    touchingObjects[k] = nil
                end
            end
            -- Request a change level.
            GAMEMODE:RequestChangeLevel(targetMap, landmarkName, touchingObjects, restart)
        end, CurTime() + 0.1)
    end
end