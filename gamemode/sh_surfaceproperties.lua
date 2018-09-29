if SERVER then
    AddCSLuaFile()
end

surfacedata = {}

function surfacedata.load(filename, groups)

    local f = file.Open(filename, "r", "GAME")
    if f == nil then
        error("Unable to open file")
        return false
    end

    local groupName
    while true do

        local b1 = f:Read(1)
        if b1 == nil then
            break
        end

        if b1 == "/" then
            -- Possible Line comment?
            local comment = b1
            local b2 = f:Read(1)
            if b2 == "/" then
                while b2 ~= "\n" do
                    comment = comment .. b2
                    b2 = f:Read(1)
                end
                --print(comment)
            end
        elseif b1 == "\"" then
            -- Read group name
            local b2 = f:Read(1)
            local group = ""
            while b2 ~= "\"" do
                group = group .. b2
                b2 = f:Read(1)
            end
            groupName = group
        elseif b1 == "{" then
            -- Group content
            local b2 = f:Read(1)
            local depth = 1
            local data = b1
            while depth > 0 do
                data = data .. b2
                if b2 == "{" then
                    depth = depth + 1
                elseif b2 == "}" then
                    depth = depth - 1
                else
                    b2 = f:Read(1)
                end
            end
            groups[groupName:lower()] = util.KeyValuesToTable("\"" .. groupName .. "\"\n" .. data)
        end

    end

    local merged = {}
    local defaultData = groups["default"]

    for k, data in pairs(groups) do
        if k == "default" then
            continue
        end
        -- Construct from default.
        local newData = table.Copy(defaultData)

        -- Collect all base properties and reverse the order.
        local baseChain = {}
        local baseGroupName = data["base"]
        while baseGroupName ~= nil do
            baseGroupName = baseGroupName:lower()
            table.insert(baseChain, baseGroupName)
            local baseGroup = groups[baseGroupName]
            if baseGroup ~= nil then
                baseGroupName = baseGroup["base"]
            end
        end
        baseChain = table.Reverse(baseChain)

        -- Now merge the base chains into the data.
        for _, baseGroupNameIt in pairs(baseChain) do
            local base = groups[baseGroupNameIt]
            if base == nil then
                print("Base missing: " .. baseGroup)
            else
                for key, val in pairs(base) do
                    newData[key] = val
                end
            end
        end

        -- Overrides
        for key,val in pairs(data) do
            newData[key] = val
        end
        merged[k] = newData
    end

    f:Close()

    --PrintTable(merged)
    return merged

end

function surfacedata.loadmanifest()

    if surfacedata.ManifestData ~= nil then
        return surfacedata.ManifestData
    end

    local f = file.Open("scripts/surfaceproperties_manifest.txt", "r", "GAME")
    if f == nil then
        return nil
    end

    local manifestData = f:Read(f:Size())
    local manifest = util.KeyValuesToTablePreserveOrder(manifestData)

    local surfacedataTable = {}
    local groups = {}

    for k,v in pairs(manifest) do
        if v.Key == "file" then
            local res = surfacedata.load(v.Value, groups)
            table.Merge(surfacedataTable, res)
        end
    end

    surfacedata.ManifestData = surfacedataTable
    return surfacedata.ManifestData

end

function surfacedata.GetByName(name)

    local data = surfacedata.loadmanifest()
    if data == nil then
        return nil
    end

    return data[name:lower()]

end
