--local DbgPrint = print
local DbgPrint = GetLogging("RoachManager")
local CurTime = CurTime
local util = util
local ents = ents
local player = player
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
    ["models/props_junk/wood_crate001a_damagedmax.mdl"] = true
}

local MAX_COCKROACHES = 60

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

function ENT:SpawnRoach()
    local spawnPos = nil
    local plys = player.GetHumans()
    local attempts = 0

    while attempts < 3 do
        attempts = attempts + 1
        local picked = table.Random(self.HidingSpots)
        if not IsValid(picked) then continue end
        local pos = picked:GetPos()
        local tooClose = false

        for _, v in pairs(plys) do
            local dist = pos:Distance(v:GetPos())

            if dist < 512 then
                tooClose = true
                break
            end
        end

        if tooClose == true then continue end
        local contents = util.PointContents(pos)
        if bit.band(contents, CONTENTS_WATER) ~= 0 or bit.band(contents, CONTENTS_SLIME) ~= 0 then continue end
        spawnPos = pos
    end

    if spawnPos == nil then return end
    local roach = ents.Create("npc_lambda_cockroach")
    roach:SetPos(spawnPos)
    roach:Spawn()

    roach:CallOnRemove("RoachRemove", function(e)
        table.RemoveByValue(self.Roaches, e)
    end, roach)

    table.insert(self.Roaches, roach)
    DbgPrint(self, "Spawned roach " .. #self.Roaches .. " / " .. MAX_COCKROACHES)
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

function ENT:Think()
    self:NextThink(CurTime() + 1)

    if self.InitialThink == nil then
        -- Ignore the first time.
        self.InitialThink = true

        return true
    end

    if self:GetNWVar("Disabled") == true then return true end
    self:MaintainHidingSpots()

    if #self.Roaches < MAX_COCKROACHES then
        self:SpawnRoach()
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