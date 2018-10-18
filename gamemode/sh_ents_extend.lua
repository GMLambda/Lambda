AddCSLuaFile()

local DbgPrint = GetLogging("EntsExt")

if SERVER then

    local persistantremovals = {}
    local delayedcallbacks = {}
    local delayedcallbacksIndex = {}

    hook.Add("PreCleanupMap", "LambadPreCleanupMap", function()
        persistantremovals = {}
        delayedcallbacks = {}
        delayedcallbacksIndex = {}
    end)

    hook.Add("OnEntityCreated", "LambdaEntityCreation", function(ent)

        -- Do this the next frame.
        util.RunNextFrame(function()

            if not IsValid(ent) then
                --DbgPrint("Entity " .. tostring(ent) .. " no longer valid")
                return
            end

            local name = ent:GetName()
            if persistantremovals[name] then

                DbgPrint("Persistant removal of entity " .. tostring(ent))
                SafeRemoveEntityDelayed(ent, 0.1)

            end

            local cbs = delayedcallbacks[name]
            if cbs ~= nil then
                for k,v in pairs(cbs) do
                    v.cb(ent)
                    if v.multiple == false then
                        delayedcallbacks[name][k] = nil
                    end
                end
            end
        end)

    end)

    function ents.WaitForEntityByName(name, cb, multiple)

        if multiple == nil then multiple = false end
        local found = ents.FindByName(name)

        for _,v in pairs(found) do
            cb(v)
        end

        local data = {}
        if found == nil or #found == 0 then
            DbgPrint("Entity " .. tostring(name) .. " not found yet, waiting for creation")
            delayedcallbacks[name] = delayedcallbacks[name] or {}
            data.cb = cb
            data.multiple = multiple
            table.insert(delayedcallbacks[name], data)
        end

    end

    function ents.WaitForEntityByIndex(index, cb)
        local ent = Entity(index)
        if IsValid(ent) then
            cb(ent)
            return
        end
        delayedcallbacksIndex[index] = delayedcallbacksIndex[index] or {}
        table.insert(delayedcallbacksIndex[index], cb)
    end

    function ents.RemoveByClass(class, pos)

        local found = ents.FindByClass(class)
        for _,v in pairs(found) do
            if pos ~= nil then
                if v:GetPos() == pos then
                    v:Remove()
                end
            else
                v:Remove()
            end
        end

    end

    function ents.RemoveByName(name, persistant)

        local found = ents.FindByName(name)
        for _,v in pairs(found) do
            v:Remove()
        end

        if persistant then

            persistantremovals[name] = true

        end

    end

    function ents.FindByGlobalName(globalname)
        for _,v in pairs(ents.GetAll()) do
            if v:GetInternalVariable("globalname") == globalname or v:GetNWString("GlobalName") == globalname then
                return v
            end
        end
        return nil
    end

    function ents.CreateSimple(class, data)

        local ent = ents.Create(class)
        ent:SetPos(data.Pos or Vector(0, 0, 0))
        if data.SpawnFlags then
            ent:SetKeyValue("spawnflags", tostring(data.SpawnFlags))
        end
        if data.KeyValues ~= nil then
            for k,v in pairs(data.KeyValues) do
                ent:SetKeyValue(k, v)
            end
        end
        ent:SetAngles(data.Ang or Angle(0, 0, 0))
        if data.Model ~= nil then
            ent:SetModel(data.Model)
        end
        if data.MoveType ~= nil then
            ent:SetMoveType(data.MoveType)
        end
        if data.UnFreezable ~= nil then
            ent:SetUnFreezable(data.UnFreezable)
        end
        if data.Flags ~= nil then
            ent:AddFlags(data.Flags)
        end

        ent:Spawn()

        if data.Freeze == true then
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end
        end

        return ent
    end

    function ents.CreateFromData(entData)
        if entData == nil then
            return nil
        end

        local classname = entData["classname"]
        if classname == nil or classname == "" then
            Error("Data has no classname")
        end

        local ent = ents.Create(classname)

        for k,v in pairs(entData) do
            if istable(v) then
                for _, v2 in pairs(v) do
                    ent:SetKeyValue(k, v2)
                    -- We process outputs and keyvalues in here, its not calling when calling SetKeyValue
                    GAMEMODE:EntityKeyValue(ent, k, v2)
                end
            else
                ent:SetKeyValue(k, v)
                -- We process outputs and keyvalues in here, its not calling when calling SetKeyValue
                GAMEMODE:EntityKeyValue(ent, k, v)
            end
        end

        return ent
    end

end

function ents.FindFirstByName(name)

    local f = ents.FindByName(name)
    if f == nil then
        return nil
    end

    return f[1]

end

function ents.FindByPos(pos, class, name)

    local tolerance = Vector(1, 1, 1)
    local found = ents.FindInBox(pos - tolerance, pos + tolerance)
    local res = {}

    for _,v in pairs(found) do

        if class ~= nil and name ~= nil then

            if v:GetClass() == class and v:GetName() == name then
                table.insert(res, v)
            end

        elseif class ~= nil and name == nil then

            if v:GetClass() == class then
                table.insert(res, v)
            end

        elseif class == nil and name ~= nil then

            if v:GetName() == name then
                table.insert(res, v)
            end

        else

            table.insert(res, v)

        end

    end

    return res

end
