if SERVER then
    ENT.Base = "lambda_trigger"
    ENT.Type = "brush"
    DEFINE_BASECLASS("lambda_trigger")
    SF_TELEPORT_PRESERVE_ANGLES = 32 -- 0x20
    SF_TELEPORT_LAMBDA_CHECKPOINT = 8192

    function ENT:PreInitialize()
        BaseClass.PreInitialize(self)
        self.Landmark = ""
        self.Target = ""
    end

    function ENT:Initialize()
        BaseClass.Initialize(self)
    end

    function ENT:KeyValue(key, val)
        BaseClass.KeyValue(self, key, val)

        if key:iequals("landmark") then
            self.Landmark = val
        elseif key:iequals("target") then
            self.Target = val
        end
    end

    function ENT:Touch(ent)
        if self:IsDisabled() == true then return end
        if self:PassesTriggerFilters(ent) == false then return end
        local targetEnt = ents.FindFirstByName(self.Target)
        if not IsValid(targetEnt) then return end
        local landmarkEnt = nil
        local landmarkOffset = Vector(0, 0, 0)

        if self.Landmark ~= "" then
            landmarkEnt = ents.FindFirstByName(self.Landmark)

            if IsValid(landmarkEnt) then
                landmarkOffset = ent:GetPos() - landmarkEnt:GetPos()
            end
        end

        if ent.SetGroundEntity ~= nil then
            ent:SetGroundEntity(NULL)
        end

        local tmp = targetEnt:GetPos()

        if not IsValid(landmarkEnt) and ent:IsPlayer() then
            tmp.z = tmp.z - ent:OBBMins().z
        end

        -- Only modify velocity if no landmark is specified.
        local ang = ent:GetAngles()
        local vel = ent:GetVelocity()

        if not IsValid(landmarkEnt) and self:HasSpawnFlags(SF_TELEPORT_PRESERVE_ANGLES) == false then
            ang = targetEnt:GetAngles()
            vel = Vector(0, 0, 0)
        end

        tmp = tmp + landmarkOffset

        if ent:IsPlayer() then
            ent:TeleportPlayer(tmp, ang, vel)

            if self:HasSpawnFlags(SF_TELEPORT_LAMBDA_CHECKPOINT) == true and self.CheckpointSet ~= true then
                GAMEMODE:SetPlayerCheckpoint({
                    Pos = tmp,
                    Ang = ang
                })

                self.CheckpointSet = true
            end
        else
            ent:SetPos(tmp)
            ent:SetVelocity(vel)
            ent:SetAngles(ang)
        end
    end
end