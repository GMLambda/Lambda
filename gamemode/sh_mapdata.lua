if SERVER then
    AddCSLuaFile()
end

local function ReadLump(f)
    local data = {}
    data.pos = f:ReadLong()
    data.len = f:ReadLong()
    data.ver = f:ReadLong()
    data.reserved = f:Read(4)

    return data
end

local function ReadHeader(f)
    local header = {}
    header.sig = f:Read(4)

    if header.sig ~= "VBSP" then
        ErrorNoHalt("Signature mismatch expected 'VBSP' got '" .. header.signature .. "'")

        return nil
    end

    header.ver = f:ReadLong()
    header.lumps = {}

    for i = 0, 63 do
        header.lumps[i] = ReadLump(f)
    end

    return header
end

local function ReadEntities(header, f)
    local pos = header.lumps[0].pos
    local len = header.lumps[0].len
    f:Seek(pos)
    local data = f:Read(len)
    local entities = {}

    for s in string.gmatch(data, "%{.-%}") do
        -- We can not use util.KeyValuesToTable because of multiple keys with same name.
        local entData = util.KeyValuesToTablePreserveOrder('"xd"\r\n' .. s)
        -- Lets create a more efficient table.
        local newData = {}

        for _, v in pairs(entData) do
            local entry = newData[v.Key]

            if entry ~= nil then
                if istable(entry) then
                    table.insert(entry, v.Value)
                else
                    entry = {entry, v.Value}
                end
            else
                entry = v.Value
            end

            newData[v.Key] = entry
        end

        table.insert(entities, newData)
    end

    return entities
end

local function ReadBSPFormat(f)
    local header = ReadHeader(f)
    if header == nil then return nil end
    local entities = ReadEntities(header, f)
    if entities == nil then return nil end

    return {
        Header = header,
        Entities = entities
    }
end

local function LoadMapData()
    local map = game.GetMap()
    local f = file.Open("maps/" .. map .. ".bsp", "rb", "GAME")
    if f == nil then return nil end
    local res = ReadBSPFormat(f)
    f:Close()

    return res
end

local cachedMapdata = nil

function game.GetMapData()
    if cachedMapdata == nil then
        cachedMapdata = LoadMapData()
    end

    return cachedMapdata
end

function game.FindEntityInMapData(name)
    local mapdata = game.GetMapData()
    if mapdata == nil then return nil end

    for _, v in pairs(mapdata.Entities) do
        local targetname = v["targetname"]
        if targetname and isstring(targetname) and targetname:iequals(name) then return v end
    end

    return nil
end

function game.FindEntityByGlobalNameInMapData(name)
    local mapdata = game.GetMapData()
    if mapdata == nil then return nil end

    for _, v in pairs(mapdata.Entities) do
        local targetname = v["globalname"]
        if targetname and isstring(targetname) and targetname:iequals(name) then return v end
    end

    return nil
end

function game.FindEntityByClassInMapData(class)
    local mapdata = game.GetMapData()
    if mapdata == nil then return nil end

    for _, v in pairs(mapdata.Entities) do
        local classname = v["classname"]
        if classname and isstring(classname) and classname:iequals(class) then return v end
    end

    return nil
end