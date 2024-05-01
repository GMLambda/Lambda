--local DbgPrint = print
local DbgPrint = GetLogging("RoachManager")
local CurTime = CurTime
local util = util
local ents = ents
local IsValid = IsValid
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")

local HIDING_MODELS = {
    ["models/props_junk/wood_crate001a.mdl"] = true,
    ["models/props_junk/wood_pallet001a.mdl"] = true,
    ["models/props_junk/cardboard_box001a.mdl"] = true,
    ["models/props_junk/cardboard_box001b.mdl"] = true,
    ["models/props_junk/trashdumpster01a.mdl"] = true,
    ["models/props_junk/metalbucket01a.mdl"] = true,
    ["models/props_c17/furniturecouch001a.mdl"] = true,
    ["models/props_c17/furnituredrawer001a.mdl"] = true,
    ["models/props_wasteland/prison_bedframe001a.mdl"] = true,
    ["models/props_interiors/furniture_couch01a.mdl"] = true,
    ["models/props_interiors/furniture_couch02a.mdl"] = true,
    ["models/props_junk/wood_crate002a.mdl"] = true,
    ["models/props_c17/oildrum001.mdl"] = true,
    ["models/props_c17/furnituredresser001a.mdl"] = true,
    ["models/props_vehicles/car004b_physics.mdl"] = true,
    ["models/props_junk/wood_crate001a_damagedmax.mdl"] = true,
    ["models/props_lab/scrapyarddumpster_static.mdl"] = true,
}

local MAX_IN_GROUP = 4
local SAFE_ZONE_MINS = Vector(-256, -256, -64)
local SAFE_ZONE_MAXS = Vector(256, 256, 64)

local function GetMaxCockroaches()
    local maxRoaches = GAMEMODE:GetSetting("max_cockroaches")
    if maxRoaches == nil then
        return 0
    end
    return maxRoaches
end

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetInputFunction("Enable", self.Enable)
    self:SetInputFunction("Disable", self.Disable)

    self:SetupNWVar("Disabled", "bool", {
        Default = false,
        KeyValue = "StartDisabled"
    })

    self.Roaches = {}
    self.HidingSpots = {}
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
    self:NextThink(CurTime() + 1)
end

local function IsSuitableSpawnPos(pos)
    local nearbyEnts = ents.FindInBox(pos + SAFE_ZONE_MINS, pos + SAFE_ZONE_MAXS)
    local groupCount = 0

    for _, v in pairs(nearbyEnts) do
        if v:IsPlayer() and v:Alive() then return false end

        if v:IsNPC() then
            if v.LambdaCockroach ~= nil then
                groupCount = groupCount + 1
            elseif v:Health() > 0 then
                return false
            end
        end
    end

    if groupCount >= MAX_IN_GROUP then return false end

    return true
end

local function FindSpawnPos(hidingSpots)
    local picked = table.Random(hidingSpots)
    if not IsValid(picked) then return nil end
    local pos = picked:GetPos()
    if IsSuitableSpawnPos(pos) == false then return nil end
    local contents = util.PointContents(pos)
    if bit.band(contents, CONTENTS_WATER) ~= 0 or bit.band(contents, CONTENTS_SLIME) ~= 0 then return nil end
    if util.IsInWorld(pos) == false then return nil end

    return pos
end

function ENT:SpawnRoach()
    local spawnPos = FindSpawnPos(self.HidingSpots)
    if spawnPos == nil then return false end
    local roach = ents.Create("npc_lambda_cockroach")
    roach:SetPos(spawnPos)
    roach:Spawn()

    roach:CallOnRemove("RoachRemove", function(e)
        table.RemoveByValue(self.Roaches, e)
    end, roach)

    table.insert(self.Roaches, roach)
    
    local maxRoaches = GetMaxCockroaches()
    DbgPrint(self, "Spawned roach " .. #self.Roaches .. " / " .. maxRoaches)

    return true
end

function ENT:FindHidingSpots()
    if self.EmptyMap == true or #self.HidingSpots > 0 then return end
    local unique = {}

    for v, _ in pairs(HIDING_MODELS) do
        local found = ents.FindByModel(v)

        for id, e in pairs(found) do
            if e:GetVelocity():Length() == 0 then
                unique[e] = true
            end
        end
    end

    local spots = {}

    for k, _ in pairs(unique) do
        table.insert(spots, k)
    end

    self.HidingSpots = spots
    self.EmptyMap = #spots == 0
end

function ENT:MaintainHidingSpots()
    self:FindHidingSpots()

    for k, v in pairs(self.HidingSpots) do
        if not IsValid(v) then
            table.remove(self.HidingSpots, k)
        end
    end
end

function ENT:AttemptSpawnRoach()
    for i = 1, 3 do
        if self:SpawnRoach() == true then return true end
    end

    return false
end

function ENT:Think()
    self:NextThink(CurTime() + 0.2)

    if self.InitialThink == nil then
        -- Ignore the first time.
        self.InitialThink = true

        return true
    end

    if self:GetNWVar("Disabled") == true then return true end
    self:MaintainHidingSpots()

    local maxRoaches = GetMaxCockroaches()
    if #self.Roaches < maxRoaches then
        self:AttemptSpawnRoach()
    end

    while (#self.Roaches > maxRoaches) do
        local roach = self.Roaches[1]
        if IsValid(roach) then
            DbgPrint(self, "Removing roach", roach)
            roach:Remove()
        end
        table.remove(self.Roaches, 1)
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