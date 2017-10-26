if SERVER then
	AddCSLuaFile()
end

GMA = {}

local GMA_MAGIC = 0x44414D47
local GMA_VERSION = 3

local function GetFileContent(filepath, gamepath)
	local f = file.Open(filepath, "rb", gamepath)
	if f == nil then
		return nil
	end

	local data = f:Read(f:Size())
	f:Close()
	return data
end

local function GetFileInfo(filepath, gamepath)

	local f = file.Open(filepath, "rb", gamepath)
	if f == nil then
		return nil
	end

	local data = f:Read(f:Size())
	local info =
	{
		CRC = util.CRC(data),
		Size = f:Size(),
	}

	f:Close()
	return info
end

function GMA.CreatePackage(filelist, outpath)

	local f = file.Open(outpath, "wb", "DATA")
	if f == nil then
		print("Unable to open file: " .. outpath)
		return false
	end

	-- Header
	f:WriteLong(GMA_MAGIC) -- GMAD
	f:WriteByte(GMA_VERSION)

	-- uint64: SteamID
	f:WriteLong(0)
	f:WriteLong(0)

	-- uint64: Timestamp
	f:WriteLong(0)
	f:WriteLong(0)

	-- Unused
	f:WriteByte(0)

	-- Title
	f:Write("Test Title")
	f:WriteByte(0)

	-- Desc
	f:Write("Test Desc")
	f:WriteByte(0)

	-- Author
	f:Write("Author")
	f:WriteByte(0)

	-- Addon Version (4) [unused]
	f:WriteLong(1)

	local fileNum = 1

	for _,v in pairs(filelist) do

		local filepath = v[1]
		local gamepath = v[2]
		local info = GetFileInfo(filepath, gamepath)
		if info == nil then
			print("Missing file: " .. filepath .. " : " .. gamepath)
			return false
		end

		-- File id.
		f:WriteLong(fileNum)

		-- Path.
		f:Write(filepath)
		f:WriteByte(0)

		-- Size
		f:WriteLong(info.Size)

		-- Timestamp
		f:WriteLong(0)

		-- CRC
		f:WriteLong(info.CRC)

		fileNum = fileNum + 1

	end

	f:WriteLong(0)

	for _,v in pairs(filelist) do

		local filepath = v[1]
		local gamepath = v[2]
		local data = GetFileContent(filepath, gamepath)
		if data ~= nil then
			f:Write(data)
		else
			print("Unable to read file: " .. filepath .. " : " .. gamepath)
			return false
		end

	end

	f:Flush()

	local curData = file.Read(outpath, "DATA")
	f:Write(util.CRC(curData))

	f:Close()

	return true
	
end
