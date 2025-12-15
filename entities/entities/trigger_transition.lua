if SERVER then
    ENT.Base = "lambda_trigger"
    ENT.Type = "brush"
    DEFINE_BASECLASS("lambda_trigger")

    function ENT:Initialize()
        --DbgPrint(util.EntityName(self), "trigger_once:Initialize")
        BaseClass.Initialize(self)
        BaseClass.SetWaitTime(self, 0) -- Never remove.
        self:AddSolidFlags(FSOLID_TRIGGER_TOUCH_DEBRIS)
    end

    function ENT:PassesTriggerFilters(ent)
        -- Anything goes in here.
        return true
    end

    function ENT:StartTouch(ent)
        --DbgPrint(util.EntityName(self), "StartTouch(" .. tostring(ent) .. ")")
        return BaseClass.StartTouch(self, ent)
    end

    function ENT:Touch(ent)
        --DbgPrint(util.EntityName(self), "Touch(" .. tostring(ent) .. ")")
        return BaseClass.Touch(self, ent)
    end

    function ENT:GetTouching()
        local trList = {}

        util.TraceEntity({
            start = self:GetPos(),
            endpos = self:GetPos(),
            mask = MASK_ALL,
            ignoreworld = true,
            filter = function(ent)
                table.insert(trList, ent)

                return false
            end
        }, self)

        return trList
    end
end