local DbgPrint = GetLogging("IO")
local table = table
GM.InputFilters = {}
GM.InputCallbacks = {}
function GM:ResetInputOutput()
    self.InputFilters = {}
    self.InputCallbacks = {}
end

function GM:FilterEntityInput(entName, inputName)
    self.InputFilters[entName] = self.InputFilters[entName] or {}
    table.insert(self.InputFilters[entName], inputName)
end

function GM:WaitForEntityInput(entName, inputName, cb)
    DbgPrint("Added new input listener on " .. entName .. " -> " .. inputName)
    self.InputCallbacks[entName] = self.InputCallbacks[entName] or {}
    self.InputCallbacks[entName][inputName] = cb
end

-- Named entity variant.
function GM:WaitForInput(entName, inputName, cb)
    self:WaitForEntityInput(entName, inputName, cb)
end

function GM:RemoveInputCallback(entName, inputName)
    DbgPrint("Removing input listener on " .. tostring(entName) .. " -> " .. inputName)
    self.InputCallbacks[entName] = self.InputCallbacks[entName] or {}
    self.InputCallbacks[entName][inputName] = nil
end

function GM:AcceptInput(ent, inputName, activator, caller, value)
    local entName = ent:GetName()
    local filters = self.InputFilters[entName]
    if filters ~= nil then
        for _, v in pairs(filters) do
            if v == inputName then
                DbgPrint(ent, "Filtered input: " .. entName .. " -> " .. inputName)
                return true
            end
        end
    end

    local inputcb = self.InputCallbacks[entName]
    if inputcb ~= nil then
        local cb = inputcb[inputName]
        if cb ~= nil then
            local res = cb(ent, inputName, activator, caller, value)
            if res == true then
                DbgPrint(ent, "Filtered input: " .. entName .. " -> " .. inputName)
                return true
            end
        end
    end

    -- HACKHACK: We handle this here since its a Portal 2 specific feature.
    if inputName == "DisableDraw" then
        ent:SetNoDraw(true)
    elseif inputName == "EnableDraw" then
        ent:SetNoDraw(false)
    end

    -- MORE HACKHACK: Handle the case where companions entered the jalopy.
    if inputName == "LambdaCompanionEnteredVehicle" and activator:IsVehicle() then
        print("LambdaCompanionEnteredVehicle", ent, inputName, activator, caller, value)
        self:OnCompanionEnteredVehicle(activator, caller)
        return true
    elseif inputName == "LambdaCompanionExitedVehicle" and activator:IsVehicle() then
        print("LambdaCompanionExitedVehicle", ent, inputName, activator, caller, value)
        self:OnCompanionExitedVehicle(activator, caller)
        return true
    end

    -- Deal with AddOutput.
    if inputName == "AddOutput" and self.IsCreatingInternalOutputs ~= true then
        -- Split outputname and output parameters.
        local outputName, outputParams = string.match(value, "(%w+)%s+(.*)")

        -- AddOutput uses double point instead of comma, replace that.
        outputParams = string.gsub(outputParams, ":", ",")

        DbgPrint("Handling AddOutput", ent, outputName, outputParams)

        ent.EntityOutputs = ent.EntityOutputs or {}
        local outputs = ent.EntityOutputs[outputName] or {}
        table.insert(outputs, outputParams)
        ent.EntityOutputs[outputName] = outputs
    end

end