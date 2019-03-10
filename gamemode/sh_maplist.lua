if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapList")

function GM:InitializeMapList()
    self.MapList = table.Copy(self:GetGameTypeData("MapList") or {})
    hook.Call("LambdaInitializeMapList", GAMEMODE, self.MapList)
end

function GM:GetMapList()
    if self.MapList == nil then
        error("InitializeMapList not called")
        return {}
    end
    -- Returns copy to prevent modifications.
    return table.Copy(self.MapList)
end

function GM:GetNextMap()

    local mapList = self.MapList

    local current = self:GetCurrentMapIndex()
    if current + 1 > #mapList then
        return mapList[1]
    end
    return mapList[current + 1]

end

function GM:GetPreviousMap()

    if self.PreviousMap ~= nil then
        return self.PreviousMap
    end

    local mapList = self.MapList

    local current = self:GetCurrentMapIndex()
    if current - 1 < 0 then
        return nil
    end
    return mapList[current - 1]

end

function GM:GetCurrentMap()
    local curMap = string.lower(game.GetMap())
    return curMap
end

function GM:GetEntryLandmark()
    return self.EntryLandmark
end

function GM:GetMapIndex(prevMap, currentMap)

    local mapList = self.MapList

    DbgPrint("Getting Map Index, Prev: " .. tostring(prevMap) .. ", Cur: " .. currentMap)
    local foundPrev = false
    local lastIndex = 0

    for k, v in pairs(mapList) do
        if foundPrev then
            if v == currentMap then
                return k
            end
            foundPrev = false
        end

        if v == currentMap then
            lastIndex = k -- In case there was a huge jump due a manual changelevel by user.
        end

        if v == prevMap then
            foundPrev = true
        elseif prevMap == nil and v == currentMap then
            return k
        end
    end

    return lastIndex

end

function GM:GetCurrentMapIndex()
    local curMap = self:GetCurrentMap()
    local index = self:GetMapIndex( self.PreviousMap, curMap )
    DbgPrint("GetCurrentMapIndex: " .. tostring(index))
    return index
end