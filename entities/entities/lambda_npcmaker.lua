local DbgPrint = GetLogging("NPCMaker")

DEFINE_BASECLASS("lambda_entity")

ENT.Base = "lambda_entity"
ENT.Type = "point"

--ENT.Outputs = table.Merge(BaseClass.Outputs, { "OnAllSpawned", "OnAllSpawnedDead", "OnAllLiveChildrenDead", "OnSpawnNPC" })

SF_NPCMAKER_START_ON = 1    -- start active ( if has targetname )
SF_NPCMAKER_NPCCLIP = 8 -- Children are blocked by NPCclip
SF_NPCMAKER_FADE = 16   -- Children's corpses fade
SF_NPCMAKER_INF_CHILD = 32  -- Infinite number of children
SF_NPCMAKER_NO_DROP = 64    -- Do not adjust for the ground's position when checking for spawn
SF_NPCMAKER_HIDEFROMPLAYER = 128 -- Don't spawn if the player's looking at me
SF_NPCMAKER_ALWAYSUSERADIUS = 256   -- Use radius spawn whenever spawning
SF_NPCMAKER_NOPRELOADMODELS = 512   -- Suppress preloading into the cache of all referenced .mdl files

local HULL_HUMAN_MINS = Vector(-13, -13, 0)
local HULL_HUMAN_MAXS = Vector(13, 13, 72)

function ENT:PreInitialize()

    DbgPrint(self, "ENT:PreInitialize")

    BaseClass.PreInitialize(self)

    self:SetupOutput("OnAllSpawned")
    self:SetupOutput("OnAllSpawnedDead")
    self:SetupOutput("OnAllLiveChildrenDead")
    self:SetupOutput("OnSpawnNPC")

    self:SetInputFunction("Enable", self.Enable)
    self:SetInputFunction("Disable", self.Disable)
    self:SetInputFunction("Toggle", self.Toggle)
    self:SetInputFunction("Spawn", self.InputSpawnNPC)

    self:SetInputFunction("SetMaxChildren", self.SetMaxChildren)
    self:SetInputFunction("AddMaxChildren", self.AddMaxChildren)
    self:SetInputFunction("SetMaxLiveChildren", self.SetMaxLiveChildren)
    self:SetInputFunction("SetSpawnFrequency", self.SetSpawnFrequency)

    self:SetupNWVar("Disabled", "bool", { Default = false, KeyValue = "StartDisabled" })
    self:SetupNWVar("MaxNPCCount", "int", { Default = 0, KeyValue = "MaxNPCCount", OnChange = self.OnChangedMaxValues })
    self:SetupNWVar("MaxLiveChildren", "int", { Default = 0, KeyValue = "MaxLiveChildren", OnChange = self.OnChangedMaxValues })
    self:SetupNWVar("DisableScaling", "bool", { Default = 0, KeyValue = "DisableScaling", OnChange = self.OnChangedMaxValues })
    self:SetupNWVar("SpawnFrequency", "float", { Default = 0, KeyValue = "SpawnFrequency" })
    self:SetupNWVar("LiveChildren", "int", { Default = 0 })
    self:SetupNWVar("CreatedCount", "int", { Default = 0 })
    self:SetupNWVar("ScaleLiveChildren", "bool", { Default = true, KeyValue = "ScaleLiveChildren" })

end

function ENT:OnChangedMaxValues()

    self.CachedMaxNPCCount = nil
    self.CachedMaxLiveChildren = nil
    self.CachedPlayerCount = player.GetCount()

end

function ENT:KeyValue(key, val)

    return BaseClass.KeyValue(self, key, val)

end

function ENT:Initialize()

    DbgPrint(self, "ENT:Initialize")

    BaseClass.Initialize(self)

    self:SetSolid(SOLID_NONE)

    if self:GetNWVar("Disabled") == false then
        self:NextThink( CurTime() + 0.1 )
        self.Think = self.MakerThink
    else
        self.Think = self.StubThink
    end

end

function ENT:SetMaxChildren(data)
    self:SetNWVar("MaxNPCCount", tonumber(data or 0))
end

function ENT:AddMaxChildren(data)
    self:SetNWVar("MaxNPCCount", self:GetNWVar("MaxNPCCount", 0) + tonumber(data or 0))
end

function ENT:SetMaxLiveChildren(data)
    self:SetNWVar("MaxLiveChildren", tonumber(data or 0))
end

function ENT:SetDisableScaling(scaling)
    self:SetNWVar("DisableScaling", tobool(scaling))
end

function ENT:SetSpawnFrequency(data)
    self:SetNWVar("SpawnFrequency", tonumber(data))
end

function ENT:InputSpawnNPC()
    DbgPrint(self, "ENT:InputSpawnNPC")

    if not self:IsDepleted() then
        self:MakeNPC()
    end
end

function ENT:HumanHullFits(pos)

    -- ai_hull_t  Human_Hull            (bits_HUMAN_HULL,           "HUMAN_HULL",           Vector(-13,-13,   0),   Vector(13, 13, 72),     Vector(-8,-8,   0),     Vector( 8,  8, 72) );
    local tr = util.TraceHull(
    {
        start = pos,
        endpos = pos + Vector(0, 0, 1),
        mins = HULL_HUMAN_MINS,
        maxs = HULL_HUMAN_MAXS,
        mask = MASK_NPCSOLID,
    })

    return tr.Fraction == 1.0

end

function ENT:AcceptInput(name, activator, caller, data)

    return BaseClass.AcceptInput(self, name, activator, caller, data)

end

function ENT:GetScaledMaxLiveChildren()

    if self.CachedMaxLiveChildren ~= nil then
        return self.CachedMaxLiveChildren
    end

    local maxLiveChildren = self:GetNWVar("MaxLiveChildren")
    local res = 0

    if self:GetNWVar("DisableScaling") == true or
        self:GetNWVar("ScaleLiveChildren") ~= true or
        (GAMEMODE.MapScript and GAMEMODE.MapScript.DisableNPCScaling == true) then
        DbgPrint("Using original MaxLiveChildren: " .. maxLiveChildren)
        res = maxLiveChildren
        self.CachedMaxLiveChildren = res
        return res
    end

    if self.PrecacheData ~= nil then
        local class = self.PrecacheData["classname"]

        if IsFriendEntityName(class) then
            res = maxLiveChildren
            self.CachedMaxLiveChildren = res
            return res
        end
    end

    local playerCount = player.GetCount()
    local scale = GAMEMODE:GetNPCSpawningScale()
    local extraCount = math.ceil(playerCount * scale)

    res = maxLiveChildren + extraCount
    self.CachedMaxLiveChildren = res

    return res

end

function ENT:GetScaledMaxNPCs()

    if self.CachedMaxNPCCount ~= nil then
        return self.CachedMaxNPCCount
    end

    local maxNPCCount = self:GetNWVar("MaxNPCCount")
    local res = 0

    if self:GetNWVar("DisableScaling") == true or
        (GAMEMODE.MapScript and GAMEMODE.MapScript.DisableNPCScaling == true) then
        return maxNPCCount
    end

    local playerCount = player.GetCount()
    local scale = GAMEMODE:GetNPCSpawningScale()
    local extraCount = math.ceil(playerCount * scale)
    
    local res = maxNPCCount + extraCount

    if self.PrecacheData ~= nil then
        local class = self.PrecacheData["classname"]
        if IsFriendEntityName(class) then
            res = maxNPCCount
        end
    end

    return res

end

-- To prevent spawning NPCs if players just turn their backs for a brief moment
-- This will check various conditions to see if we should consider distance.
function ENT:ShouldUseDistance()
    local multiSpawn = false
    if self:HasSpawnFlags(SF_NPCMAKER_INF_CHILD) == true then
        multiSpawn = true
    elseif self:GetNWVar("MaxNPCCount") == 1 and self:GetScaledMaxNPCs() > self:GetNWVar("MaxNPCCount") then
        multiSpawn = true
    end
    if self:HasSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER) == true and multiSpawn == true and self:GetNWVar("CreatedCount") > 0 then
        return true
    end
    return false
end

function ENT:IsDepleted()
    if self:HasSpawnFlags(SF_NPCMAKER_INF_CHILD) or self:GetNWVar("CreatedCount") < self:GetScaledMaxNPCs() then
        return false
    end
    return true
end

function ENT:Toggle()
    if self:GetNWVar("Disabled") == true then
        self:Enable()
    else
        self:Disable()
    end
end

function ENT:Enable()

    if self:IsDepleted() then
        --DbgPrint("Can not enable because entity is depleted!")
        --return
    end

    self:SetNWVar("Disabled", false)

    --self.Disabled = false
    self.Think = self.MakerThink
    self:NextThink( CurTime() )
end

function ENT:Disable()
    --self.Disabled = true
    self:SetNWVar("Disabled", true)
    self.Think = self.StubThink
end

local ForcedNPCS =
{
    ["npc_rollermine"] = true,
    ["npc_breen"] = true,
}

function ENT:CanMakeNPC(ignoreSolidEnts)

    ignoreSolidEnts = ignoreSolidEnts or false

    if self:IsDepleted() then
        DbgPrint(self, "Depleted")
        return false
    end

    local maxLiveChildren = self:GetNWVar("MaxLiveChildren")
    local liveChildren = self:GetNWVar("LiveChildren")
    local scaledMaxLiveChildren = self:GetScaledMaxLiveChildren()

    if maxLiveChildren > 0 and liveChildren >= scaledMaxLiveChildren then
        DbgPrint(self, "Too many live children, live: " .. tostring(liveChildren) .. ", max scaled: " .. tostring(scaledMaxLiveChildren))
        return false
    end

    local pos = self:GetPos()
    local mins = pos - Vector(34, 34, 0)
    local maxs = pos + Vector(34, 34, pos.z)

    if ignoreSolidEnts == false then

        for _,ent in pairs(ents.FindInBox(mins, maxs)) do

            if not ent:IsPlayer() and not ent:IsNPC() then
                continue
            end

            if bit.band(ent:GetSolidFlags(), FSOLID_NOT_SOLID) == 0 then

                -- This is used for striders because of the big bounding box,
                -- NOTE: This is all based on monstermaker.cpp from the Source SDK

                local tr = util.TraceHull({
                    start = self:GetPos() + Vector(0, 0, 2),
                    endpos = self:GetPos() - Vector(0, 0, 8192),
                    mins = HULL_HUMAN_MINS,
                    maxs = HULL_HUMAN_MAXS,
                    mask = MASK_NPCSOLID,
                })

                if not self:HumanHullFits(tr.HitPos + Vector(0, 0, 1)) then
                    return false
                end

            end

        end

    end

    if self:HasSpawnFlags( SF_NPCMAKER_HIDEFROMPLAYER ) then

        local class = self:GetNPCClass()

        -- Make sure we spawn friendlies and enforced npcs.
        if ForcedNPCS[class] == nil and IsFriendEntityName(class) == false and util.IsPosVisibleToPlayers(pos) == true then
            DbgPrint("Can not make NPC, maker is visible to player")
            return false
        end

        local closestDist = 999999
        if self:ShouldUseDistance() == true then
            for _,v in pairs(player.GetAll()) do
                if v:IsFlagSet(FL_NOTARGET) then
                    continue
                end
                local dist = v:GetPos():Distance(pos)
                if dist < closestDist then
                    closestDist = dist
                end
            end
            -- Seems to be optimal for now.
            if closestDist < 750 then
                return false
            end
        end

    end

    return true

end

function ENT:StubThink()

    --DbgPrint(self, "ENT:StubThink", ent)

end

function ENT:MakerThink()

    --DbgPrint(self, "ENT:MakerThink", ent)
    if self.CachedPlayerCount ~= player.GetCount() then
        self.CachedMaxNPCCount = nil
        self.CachedMaxLiveChildren = nil
        self.CachedPlayerCount = player.GetCount()
    end

    self:NextThink( CurTime() + self:GetNWVar("SpawnFrequency") )
    self:MakeNPC()

    return true

end

function ENT:DeathNotice(ent)

    if self:GetNWVar("LiveChildren", 0) <= 0 then
        DbgError(self, "No live children but death notice! Investigate me")
    end

    self:SetNWVar("LiveChildren", self:GetNWVar("LiveChildren") - 1)

    if self:GetNWVar("LiveChildren") <= 0 then

        self:FireOutputs("OnAllLiveChildrenDead", nil, self)

        if self:HasSpawnFlags(SF_NPCMAKER_INF_CHILD) == false and self:IsDepleted() == true then

            DbgPrint("All spawned NPCs are dead.")

            self:FireOutputs("OnAllSpawnedDead", nil, self)

            if self.OnAllSpawnedDead ~= nil then
                self:OnAllSpawnedDead()
            end

        end

    end

end

function ENT:DispatchSpawn(ent)

    DbgPrint(self, "ENT:DispatchSpawn", ent)

    if not IsValid(ent) then
        return
    end

    ent:Spawn()

    -- Check again, spawn can remove the ent.
    if not IsValid(ent) then
        return
    end

end

function ENT:DispatchActivate(ent)

    DbgPrint(self, "ENT:DispatchActivate", ent)

    if not IsValid(ent) then
        return
    end

    ent:Activate()

end

function ENT:ChildPreSpawn(ent)

end

function ENT:ChildPostSpawn(ent)

    -- TODO: Check if ent is stuck and remove it.

    local maker = self

    -- Usually the entities would do that based on npc_template_maker but we are not C++ the object where it could call it.
    ent:CallOnRemove(self, function(npc)
        if IsValid(maker) then
            DbgPrint("NPC (" .. tostring(npc) .. ") dead, notifying npc_maker: " .. tostring(maker))
            self:DeathNotice(npc)
        end
    end)

    -- HACKHACK: Some of the weapons appear to have EF_NODRAW set, that shouldn't be the case.
    local wep = ent:GetActiveWeapon()
    if IsValid(wep) then
        wep:RemoveEffects(EF_NODRAW)
    end
    
    DbgPrint(self, "Created new NPC: " .. tostring(ent))

end

function ENT:UpdateScaling()

    DbgPrint(self, "ENT:UpdateScaling", ent)

    local maxCount = self:GetNWVar("MaxNPCCount")
    if self:HasSpawnFlags(SF_NPCMAKER_INF_CHILD) == false and maxCount == 1 and self:GetNWVar("CreatedCount") == maxCount then
        -- From this point on only spawn when not visible.
        DbgPrint("Adjusted flags, hiding from player, CreatedCount == 1 and MaxNPCCount == 1")
        self:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)
    end

    self.CachedMaxNPCCount = nil
    self.CachedMaxLiveChildren = nil

end

function ENT:MakeNPC()
    -- Override me.
    DbgPrint(self, "ENT:MakeNPC", ent)
end

function ENT:GetNPCClass()
    DbgPrint(self, "ENT:GetNPCClass", ent)
    return ""
end

function ENT:UpdateTransmitState()

    return TRANSMIT_NEVER

end
