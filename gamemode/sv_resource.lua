local DbgPrint = GetLogging("Resource")

function GM:InitializeResources()
    if self.WorkshopBuild == false then
        self:AddResourceDir("models")
        self:AddResourceDir("materials")
        self:AddResourceDir("sound")
    else
        resource.AddWorkshop(self.WorkshopID)
    end
end

function GM:AddResourceDir(dir)
    local resourceDir = "lambda/content"
    local foundDir = false
    local files, folders = file.Find("gamemodes/" .. resourceDir .. "/" .. dir .. "/*", "GAME")

    for k, v in pairs(files) do
        local f = dir .. "/" .. v
        DbgPrint("Added: " .. f)
        resource.AddFile(f)
    end

    for k, v in pairs(folders) do
        local f = dir .. "/" .. v
        if file.IsDir(resourceDir .. "/" .. f, "LUA") then
            foundDir = true
            self:AddResourceDir(f)
        end
    end

    if !foundDir then
        DbgPrint("Directory " .. dir .. " was added successfully")
    end
end
