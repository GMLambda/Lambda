if SERVER then
    AddCSLuaFile()
end

local COLLISION_ID_PAIRS = {}
--local DbgPrint = GetLogging("Collision")

local function GetPairId(ent1, ent2)
    local id1 = ent1:GetCreationID()
    local id2 = ent2:GetCreationID()

    if (id2 < id1) then
        id1, id2 = id2, id1
    end

    local id = bit.lshift(id2, 16)
    id = bit.bor(id, id1)

    return id
end

hook.Add("ShouldCollide", "LambdaShouldCollide", function(ent1, ent2)
    local id = GetPairId(ent1, ent2)

    return COLLISION_ID_PAIRS[id] or true
end)

local ENTITY_META = FindMetaTable("Entity")

function ENTITY_META:SetCollideWith(ent2, state)
    local id = GetPairId(self, ent2)
    self:EnableCustomCollisions(state)
    ent2:EnableCustomCollisions(state)
    COLLISION_ID_PAIRS[id] = state
    self:CollisionRulesChanged()
    ent2:CollisionRulesChanged()
end
