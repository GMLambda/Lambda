local DbgPrint = GetLogging("NPCMaker")

DEFINE_BASECLASS( "lambda_npcmaker" )

ENT.Base = "lambda_npcmaker"
ENT.Type = "point"

local TS_YN_YES = 0
local TS_YN_NO = 1
local TS_YN_DONT_CARE = 2
local TS_DIST_NEAREST = 0
local TS_DIST_FARTHEST = 1
local TS_DIST_DONT_CARE = 2

function ENT:PreInitialize()

    DbgPrint(self, "ENT:PreInitialize")

    BaseClass.PreInitialize(self)

    self.TemplateName = ""
    self.Radius = 256
    self.DestinationGroup = nil
    self.CriterionVisibility = 0
    self.CriterionDistance = 0
    self.MinSpawnDistance = 0
    self.PrecacheData = nil

    self:SetupOutput("OnAllSpawned")
    self:SetupOutput("OnAllSpawnedDead")
    self:SetupOutput("OnAllLiveChildrenDead")
    self:SetupOutput("OnSpawnNPC")

    self:SetInputFunction("SpawnNPCInRadius", self.MakeNPCInRadius )
    self:SetInputFunction("SpawnNPCInLine", self.MakeNPCInLine )
    self:SetInputFunction("SpawnMultiple", self.MakeMultipleNPCS )
    self:SetInputFunction("ChangeDestinationGroup", self.ChangeDestinationGroup )

end

function ENT:KeyValue(key, val)

    BaseClass.KeyValue(self, key, val)

    if key:iequals("TemplateName") then
        self.TemplateName = val
    elseif key:iequals("Radius") then
        self.Radius = tonumber(val)
    elseif key:iequals("DestinationGroup") then
        self.DestinationGroup = val
    elseif key:iequals("CriterionVisibility") then
        self.CriterionVisibility = tonumber(val)
    elseif key:iequals("CriterionDistance") then
        self.CriterionDistance = tonumber(val)
    elseif key:iequals("MinSpawnDistance") then
        self.MinSpawnDistance = tonumber(val)
    end

end

function ENT:Precache()

    if self.PrecacheData ~= nil then
        return
    end

    if self.PrecacheData == nil then
        self.PrecacheData = table.Copy(game.FindEntityInMapData(self.TemplateName))
        --[[
        local mapdata = game.GetMapData()
        for _,ent in pairs(mapdata.Entities) do
            if ent["targetname"] and tostring(ent["targetname"]):iequals(self.TemplateName) then
                self.PrecacheData = ent
                break
            end
        end
        ]]
    end

    if self.PrecacheData == nil then
        --ErrorNoHalt("Unable to find npc template in map data, can not precache!")
        return
    end

    if self.PrecacheData["model"] then
        util.PrecacheModel(self.PrecacheData["model"])
    end

end

function ENT:RemoveTemplateData(name)

    for k,_ in pairs(self.PrecacheData or {}) do
        if k:iequals(name) then
            self.PrecacheData[k] = nil
        end
    end

end

function ENT:AddTemplateData(key, val)

    self.PrecacheData[key] = val

end

function ENT:GetNPCClass()

    if self.PrecacheData then
        return self.PrecacheData["classname"]
    end

    return ""

end

function ENT:Initialize()

    DbgPrint(self, "ENT:Initialize")

    BaseClass.Initialize(self)

    self:Precache()

    -- NOTE: Should we add the flag only under specific circumstances?
    --self:AddSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER)

    -- NOTE: Lets figure out a way that tells us if we could apply infinite childreen.
    --       one way would be going per NPC type?
end

function ENT:FindSpawnDestination()

    local spawnDestinations = ents.FindByName(self.DestinationGroup)
    local possible = {}

    if _DEBUG then
        if table.Count(spawnDestinations) == 0 then
            ErrorNoHalt("npc_template_maker has no spawn destinations")
            return nil
        end
    end

    local vecPlayerCenter = Vector(0,0,0)
    local centerDiv = 0
    for k,v in pairs(player.GetAll()) do
        vecPlayerCenter = vecPlayerCenter + v:GetPos()
        centerDiv = centerDiv + 1
    end
    vecPlayerCenter = vecPlayerCenter / centerDiv

    for _, dest in pairs(spawnDestinations) do

        if dest.IsAvailable and dest:IsAvailable() then

            local valid = true
            local destPos = dest:GetPos()

            if self.CriterionVisibility ~= TS_YN_DONT_CARE then

                local visible = false
                for _, ply in pairs(player.GetAll()) do
                    if ply:VisibleVec(destPos) then
                        visible = true
                        break
                    end
                end

                if self.CriterionVisibility == TS_YN_YES then
                    if not visible then
                        valid = false
                    end
                else
                    if visible then
                        valid = false
                    end
                end
            end

            if valid then
                table.insert(possible, dest)
            end

        end

    end

    if table.Count(possible) < 1 then
        return nil
    end

    if self.CriterionDistance == TS_DIST_DONT_CARE then

        for i = 0, 5 do
            local dest = table.Random(possible)
            if self:HumanHullFits(dest:GetPos()) then
                return dest
            end
        end
        -- Porbably all positions are blocked.
        return nil

    elseif self.CriterionDistance == TS_DIST_NEAREST then

        local nearestDist = 0
        local nearestDest = nil

        for _,dest in pairs(possible) do

            local destPos = dest:GetPos()
            local dist = destPos:Distance(vecPlayerCenter)

            if nearestDist == 0 or dist < nearestDist then
                if self:HumanHullFits(destPos) then
                    nearestDist = dist
                    nearestDest = dest
                end
            end

        end

        return nearestDest

    elseif self.CriterionDistance == TS_DIST_FARTHEST then

        local farthestDist = 0
        local farthestDest = nil

        for _,dest in pairs(possible) do

            local destPos = dest:GetPos()
            local dist = destPos:Distance(vecPlayerCenter)

            if dist > farthestDist then
                if self:HumanHullFits(destPos) then
                    farthestDist = dist
                    farthestDest = dest
                end
            end

        end

        return farthestDest

    end

    return nil

end

function ENT:MakeNPC()

    --DbgPrint(self, "ENT:MakeNPC")

    if self.Radius > 0 and self:HasSpawnFlags(SF_NPCMAKER_ALWAYSUSERADIUS) then
        return self:MakeNPCInRadius()
    end

    if self:CanMakeNPC( self.DestinationGroup ~= nil ) == false then
        return
    end

    local dest = nil

    if self.DestinationGroup ~= nil then

        dest = self:FindSpawnDestination()
        if dest == nil then
            DbgPrint(self, "Failed to find valid spawnpoint in destination group: " .. self.DestinationGroup)
            return
        end

    end

    self:Precache()

    local ent = ents.CreateFromData(self.PrecacheData)
    if not IsValid(ent) then
        --DbgPrint(self, "Unable to create NPC!")
        return
    end

    DbgPrint(self, "Created NPC: " .. tostring(ent))

    local destObj = nil

    if dest == nil then
        dest = self
    else
        destObj = dest
    end

    ent:SetPos(dest:GetPos())

    local ang = dest:GetAngles()
    ang.x = 0
    ang.z = 0

    ent:SetAngles(ang)

    if IsValid(destObj) and destObj.OnSpawnNPC then
        --DbgPrint("Firing OnSpawnNPC in info_npc_spawn_destination")
        destObj:OnSpawnNPC()
    end

    if self:HasSpawnFlags(SF_NPCMAKER_FADE) then
        ent:AddSpawnFlags( SF_NPC_FADE_CORPSE )
    end

    ent:RemoveSpawnFlags( SF_NPC_TEMPLATE )

    if self:HasSpawnFlags(SF_NPCMAKER_NO_DROP) == false then
        ent:RemoveSpawnFlags(SF_NPC_FALL_TO_GROUND)
    end

    self:ChildPreSpawn(ent)
    self:DispatchSpawn(ent)
    ent:SetOwner(self)
    self:DispatchActivate(ent)
    self:ChildPostSpawn(ent)

    self:FireOutputs("OnSpawnNPC", ent, ent, self)
    if self.OnSpawnNPC ~= nil and isfunction(self.OnSpawnNPC) then
        self:OnSpawnNPC(ent)
    end
    --self.LiveChildren = self.LiveChildren + 1
    self:SetNWVar("LiveChildren", self:GetNWVar("LiveChildren") + 1)

    if self:HasSpawnFlags(SF_NPCMAKER_INF_CHILD) == false then

        --self.MaxNPCCount = self.MaxNPCCount - 1
        --self.CreatedCount = self.CreatedCount + 1
        self:SetNWVar("CreatedCount", self:GetNWVar("CreatedCount") + 1)

        DbgPrint("Spawned npc, count: " .. self:GetNWVar("CreatedCount") .. " / " .. self:GetScaledMaxNPCs())

        if self:IsDepleted() then
            self:FireOutputs("OnAllSpawned", nil, self)
            self.Think = self.StubThink
        end

    end

    self:UpdateScaling()

end

local HULL_SIZE_HUMAN = { Vector(-13, -13, 0), Vector(13, 13, 72) }

local KNOWN_HULLS =
{
    ["npc_combine"] = HULL_SIZE_HUMAN,
    ["npc_combine_s"] = HULL_SIZE_HUMAN,
}

function ENT:GetSpawnPosInRadius(hull, checkVisible)

    DbgPrint(self, "ENT:GetSpawnPosInRadius")

    local pos = self:GetPos()
    local radius = self.Radius
    local ang = Angle(0, 0, 0)

    local step = 360 / self:GetScaledMaxNPCs()

    local hullMins = hull[1]
    local hullMaxs = hull[2]

    --DbgPrint("NPC Hull: " .. tostring(hullMins) .. ", " .. tostring(hullMaxs))
    --DbgPrint("NPC Hulltype: " .. tostring(npc:GetHullType()))
    math.randomseed(self:EntIndex())

    for y = 0, 360, step do

        ang.y = y

        local testRadius = radius
        for radiusDivider = 5, 10 do 

            local n = radiusDivider / 10
            local subRadius = radius * n
            local traceRadius = math.random(testRadius - subRadius, testRadius)
            testRadius = testRadius - subRadius
            local dir = ang:Forward()
            local testPos = pos + (dir * traceRadius)

            -- Check if they would fall.
            local tr = util.TraceLine(
            {
                start = testPos,
                endpos = testPos - Vector(0, 0, 8192),
                mask = MASK_NPCSOLID,
            })

            if tr.Fraction == 1 then
                continue
            end

            -- See if they fit.
            local hullTr = util.TraceHull(
            {
                start = tr.HitPos,
                endpos = tr.HitPos + Vector(0, 0, 10),
                mins = hullMins,
                maxs = hullMaxs,
                mask = MASK_NPCSOLID,
            })

            if hullTr.Hit == true then
                continue
            end

            if checkVisible == true and util.IsPosVisibleToPlayers(testPos) == true then
                DbgPrint("Visible to player can not spawn NPC")
                continue
            end

            --PrintTable(hullTr)
            debugoverlay.Box(hullTr.HitPos, hullMins, hullMaxs, 0.1, Color(255, 255, 255))

            if hullTr.Fraction == 1.0 then

                -- The SDK also checks the MoveProbe for stand position, we have no access.
                return hullTr.HitPos

            end

        end

    end

    return nil

end 

function ENT:PlaceNPCInRadius(npc, checkVisible)

    DbgPrint(self, "ENT:PlaceNPCInRadius")

    local hull = { npc:GetHullMins(), npc:GetHullMaxs() }
    local spawnPos = self:GetSpawnPosInRadius(hull, checkVisible)
    if spawnPos == nil then
        return false
    end

    npc:SetPos(spawnPos)
    return true

end

function ENT:MakeNPCInRadius()

    DbgPrint(self, "ENT:MakeNPCInRadius")

    if not self:CanMakeNPC(true) then
        return
    end

    local ent
    local classname = self.PrecacheData["classname"]
    local hullData = KNOWN_HULLS[classname]
    local checkVisible = false
    if self:HasSpawnFlags(SF_NPCMAKER_HIDEFROMPLAYER) == true then
        checkVisible = true
    end

    -- We can avoid creating the NPC if we already know the hull.
    if hullData ~= nil then
        local spawnSpot = self:GetSpawnPosInRadius(hullData, checkVisible)
        if spawnSpot == nil then
            return
        end
        ent = ents.CreateFromData(self.PrecacheData)
        if not IsValid(ent) then
            ErrorNoHalt("Unable to create npc!")
            return
        end
        ent:SetPos(spawnSpot)
    else
        -- Fallback if we have no hull information.
        ent = ents.CreateFromData(self.PrecacheData)
        if not IsValid(ent) then
            ErrorNoHalt("Unable to create npc!")
            return
        end

        if self:PlaceNPCInRadius(ent, checkVisible) == false then
            DbgPrint("Failed to create NPC in radius: " .. tostring(ent))
            ent:Remove()
            return
        else
            DbgPrint("Created NPC in radius: " .. tostring(ent))
        end
    end

    ent:AddSpawnFlags(SF_NPC_FALL_TO_GROUND)
    ent:RemoveSpawnFlags(SF_NPC_TEMPLATE)

    self:ChildPreSpawn(ent)
    self:DispatchSpawn(ent)
    ent:SetOwner(self)
    self:DispatchActivate(ent)
    self:ChildPostSpawn(ent)

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
            self.Think = self.StubThink
        end

    end

    self:UpdateScaling()

end

function ENT:PlaceNPCInLine(npc)

    local fwd = self:GetForward()
    fwd = fwd * -1 -- invert

    local tr = util.TraceLine({
        startpos = self:GetPos(),
        endpos = self:GetPos() - Vector(0, 0, 8192),
        mask = MASK_SHOT,
        filter = npc,
    })

    local mins = npc:GetHullMins()
    local maxs = npc:GetHullMaxs()
    local hullWidth = maxs.y - mins.y

    local dest = tr.HitPos
    for i = 0, 10 do

        local tr = util.TraceHull({
            start = dest,
            endpos = dest + Vector(0, 0, 10),
            mins = mins,
            maxs = maxs,
            filter = npc,
            mask = MASK_SHOT,
        })

        if tr.Fraction == 1.0 then
            npc:SetPos(tr.HitPos)
            return true
        end

        dest = dest + (fwd * hullWidth)
    end

    return false

end

function ENT:MakeNPCInLine()

    DbgPrint(self, "ENT:MakeNPCInRadius")

    if not self:CanMakeNPC(true) then
        return
    end

    local ent = ents.CreateFromData(self.PrecacheData)
    if not IsValid(ent) then
        ErrorNoHalt("Unable to create npc!")
        return
    end

    if self:PlaceNPCInLine(ent) == false then
        DbgPrint("Failed to create npc in line: " .. tostring(ent))
        ent:Remove()
        return
    else
        DbgPrint("Created NPC in line: " .. tostring(ent))
    end

    ent:AddSpawnFlags(SF_NPC_FALL_TO_GROUND)
    ent:RemoveSpawnFlags(SF_NPC_TEMPLATE)

    self:ChildPreSpawn(ent)
    self:DispatchSpawn(ent)
    ent:SetOwner(self)
    self:DispatchActivate(ent)
    self:ChildPostSpawn(ent)

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
            self.Think = self.StubThink
        end

    end

    self:UpdateScaling()

end

function ENT:MakeMultipleNPCS()

    Error("MakeMultipleNPCS not implemented")

end

function ENT:ChangeDestinationGroup(data)

    --Error("ChangeDestinationGroup not implemented")
    self.DestinationGroup = data -- ??
end

function ENT:SetMinimumSpawnDistance(data)

    Error("SetMinimumSpawnDistance not implemented")

end

function TestPlayerTrace(ply)

    local hullMins = HULL_SIZE_HUMAN[1]
    local hullMaxs = HULL_SIZE_HUMAN[2]

    -- See if they fit.
    local hullTr = util.TraceHull(
    {
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0, 0, 10),
        mins = hullMins,
        maxs = hullMaxs,
        mask = MASK_NPCSOLID,
        filter = ply,
    })

    PrintTable(hullTr)

end
