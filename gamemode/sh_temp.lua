-- Before this issue is not resolved, we have to do this.
-- https://github.com/Facepunch/garrysmod-issues/issues/2657
if SERVER then
    AddCSLuaFile()
end

local ENTITY = FindMetaTable("Entity")
local PVS_DIST = 9000
local PVS_MINS = Vector(-PVS_DIST, -PVS_DIST, -PVS_DIST)
local PVS_MAXS = Vector(PVS_DIST, PVS_DIST, PVS_DIST)

if ENTITY.TestPVS == nil then
    function ENTITY:TestPVS(test)
        if IsEntity(test) then
            test = test:GetPos()
        end

        local pos = self:GetPos()
        if pos:Distance(test) > PVS_DIST then return false end

        return true
    end
end

--if ents.FindInPVS == nil then
function ents.FindInPVS(what)
    if IsEntity(what) then
        what = what:GetPos()
    end

    return ents.FindInBox(what + PVS_MINS, what + PVS_MAXS)
end
--end