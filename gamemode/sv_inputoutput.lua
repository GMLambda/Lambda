local DbgPrint = GetLogging("IO")

GM.InputFilters = {}
GM.OutputCallbacks = {}
GM.InputCallbacks = {}

function GM:ResetInputOutput()
    self.InputFilters = {}
    self.OutputCallbacks = {}
    self.InputCallbacks = {}
end

function GM:FilterEntityInput(name, input)

    self.InputFilters[name] = self.InputFilters[name] or {}
    table.insert(self.InputFilters[name], input)

end

function GM:AddOutputCallback(name, outputname, inputname, delay, cb)

    ents.WaitForEntityByName(name, function(ent)

        local infotarget = ents.Create("info_target")
        infotarget:SetName(inputname)
        infotarget:Spawn()

        DbgPrint("Added new output on " .. tostring(ent) .. " -> " .. outputname .. " " .. inputname)

        ent:Fire("AddOutput", outputname .. " " .. inputname .. ",OutputCallback", delay)

        self.OutputCallbacks[inputname] = cb

    end)

end

function GM:WaitForEntityInput(ent, input, cb)
    DbgPrint("Added new input listener on " .. tostring(ent) .. " -> " .. input)

    self.InputCallbacks[ent] = self.InputCallbacks[ent] or {}
    self.InputCallbacks[ent][input] = cb
end

-- Named entity variant.
function GM:WaitForInput(nameEnt, input, cb)

    ents.WaitForEntityByName(nameEnt, function(ent)
        self:WaitForEntityInput(ent, input, cb)
    end)

end

function GM:RemoveInputCallback(name, input)
    ents.WaitForEntityByName(name, function(ent)

        DbgPrint("Removing input listener on " .. tostring(ent) .. " -> " .. input)

        self.InputCallbacks[ent] = self.InputCallbacks[ent] or {}
        self.InputCallbacks[ent][input] = nil

    end)
end

function GM:AcceptInput(ent, input, activator, caller, value)

    local name = ent:GetName()
    local filters = self.InputFilters[name]
    if filters ~= nil then
        for _,v in pairs(filters) do
            if v == input then
                DbgPrint(ent, "Filtered input: " .. name .. " -> " .. input)
                return true
            end
        end
    end

    local inputcb = self.InputCallbacks[ent]
    if inputcb ~= nil then
        local cb = inputcb[input]
        if cb ~= nil then
            local res = cb(ent, input, activator, caller, value)
            if res == true then
                DbgPrint(ent, "Filtered input: " .. name .. " -> " .. input)
                return true
            end
        end
    end

    local output = self.OutputCallbacks[name]
    if output ~= nil then
        DbgPrint("Input Target: " .. name)
        output(name)
    end

end
