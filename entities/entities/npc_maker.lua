local DbgPrint = GetLogging("NPC")

if SERVER then

    ENT.Base = "lambda_npcmaker"
    ENT.Type = "point"

    DEFINE_BASECLASS( "lambda_npcmaker" )

    function ENT:PreInitialize()

        DbgPrint(self, "ENT:PreInitialize")

        BaseClass.PreInitialize(self)

        self.NPCType = ""
        self.NPCTargetname = ""
        self.NPCSquadName = ""
        self.AdditionalEquipment = ""
        self.NPCHintGroup = ""
        self.Relationship = ""

    end

    function ENT:Initialize()

        DbgPrint(self, "ENT:Initialize")

        BaseClass.Initialize(self)

    end

    function ENT:KeyValue(key, value)

        BaseClass.KeyValue(self, key, value)

        if key:iequals("NPCType") then
            self.NPCType = value
        elseif key:iequals("NPCTargetname") then
            self.NPCTargetname = value
        elseif key:iequals("NPCSquadName") then
            self.NPCSquadName = value
        elseif key:iequals("additionalequipment") then
            self.AdditionalEquipment = value
        elseif key:iequals("NPCHintGroup") then
            self.NPCHintGroup = value
        elseif key:iequals("Relationship") then
            self.Relationship = value
        end
    end

    function ENT:GetNPCClass()
        return self.NPCType or ""
    end

    function ENT:MakeNPC()

        --DbgPrint(self, "ENT:MakeNPC")

        if self:CanMakeNPC() == false then
            return
        end

        DbgPrint("Creating NPC: " .. self.NPCType)

        local ent = ents.Create(self.NPCType)
        if not IsValid(ent) then
            --DbgPrint(self, "Unable to create NPC!")
            return
        end

        ent:SetKeyValue("Relationship", self.Relationship)

        local self = self
        local ent = ent

        ent:SetPos(self:GetPos())

        local ang = self:GetAngles()
        ang.x = 0
        ang.z = 0

        ent:SetAngles(ang)

        if self:HasSpawnFlags(SF_NPCMAKER_FADE) then
            ent:AddSpawnFlags( SF_NPC_FADE_CORPSE )
        end

        ent:SetKeyValue("additionalequipment", self.AdditionalEquipment)
        ent:SetKeyValue("squadname", self.NPCSquadName)
        ent:SetKeyValue("hintgroup", self.NPCHintGroup)

        if self:HasSpawnFlags(SF_NPCMAKER_NO_DROP) == false then
            ent:RemoveSpawnFlags(SF_NPC_FALL_TO_GROUND)
        end

        self:ChildPreSpawn(ent)

        self:DispatchSpawn(ent)
        ent:SetOwner(self)
        self:DispatchActivate(ent)

        DbgPrint("Created NPC: " .. tostring(ent))

        self:ChildPostSpawn(ent)

        ent:SetName(self.NPCTargetname)

        self:FireOutputs("OnSpawnNPC", ent, ent, self)
        if self.OnSpawnNPC ~= nil and isfunction(self.OnSpawnNPC) then
            self:OnSpawnNPC(ent)
        end
        self:SetNWVar("LiveChildren", self:GetNWVar("LiveChildren") + 1)

        if self:HasSpawnFlags(SF_NPCMAKER_INF_CHILD) == false then

            --self.MaxNPCCount = self.MaxNPCCount - 1
            --self.CreatedCount = self.CreatedCount + 1
            self:SetNWVar("CreatedCount", self:GetNWVar("CreatedCount") + 1)

            DbgPrint("Spawned npc, count: " .. self:GetNWVar("CreatedCount") .. " / " .. self:GetScaledMaxNPCs())

            if self:IsDepleted() then
                self:FireOutputs("OnAllSpawned", nil, self)
                --self.Think = self.StubThink
            end

        else

            DbgPrint("Infinite NPCs!")

        end

        self:UpdateScaling()

    end

end
