local RESOURCE_FOLDER =
{
	"materials/lambda",
	"materials/models",
	"materials/models/gibs",
	"models/gibs",
	"models",
	"scripts",
	"models",
	"sound",
}

local BASE_PATH = GM.Folder .. "/content"
local FOLDERS = {}

for _,v in ipairs(RESOURCE_FOLDER) do
	table.insert(FOLDERS, BASE_PATH .. "/" .. v)
end

while #FOLDERS > 0 do

	local folder = FOLDERS[1]
	table.remove(FOLDERS, 1)

	local res = file.Find(folder .. "/*", "GAME")
	for _, filename in ipairs(res) do
		local filepath = folder .. "/" .. filename
		if file.IsDir(filepath, "GAME") then
			table.insert(FOLDERS, filepath)
		else
			resource.AddSingleFile(filepath)
		end
	end

end
