local DbgPrint = GetLogging("Resource")

function GM:AddResourceDir(dir)

	if true then
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
	else
		resource.AddWorkshop("780244493")
	end

end
