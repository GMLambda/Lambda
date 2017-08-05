local DbgPrint = GetLogging("Player")

if SERVER then
	AddCSLuaFile()

	util.AddNetworkString("LambdaPlayerModels")

	GM.DefaultPlayerModels =
	{
		["male_01"] = { "models/player/group01/male_01.mdl", "models/player/group03/male_01.mdl" },
		["female_01"] = { "models/player/group01/female_01.mdl", "models/player/group03/female_01.mdl" },
		["male_02"] = { "models/player/group01/male_02.mdl", "models/player/group03/male_02.mdl" },
		["female_02"] = { "models/player/group01/female_02.mdl", "models/player/group03/female_02.mdl" },
		["male_03"] = { "models/player/group01/male_03.mdl", "models/player/group03/male_03.mdl" },
		["female_03"] = { "models/player/group01/female_03.mdl", "models/player/group03/female_03.mdl" },
		["male_04"] = { "models/player/group01/male_04.mdl", "models/player/group03/male_04.mdl" },
		["female_04"] = { "models/player/group01/female_04.mdl", "models/player/group03/female_04.mdl" },
		["male_05"] = { "models/player/group01/male_05.mdl", "models/player/group03/male_05.mdl" },
		["female_05"] = { "models/player/group01/female_05.mdl", "models/player/group03/female_05.mdl" },
		["male_06"] = { "models/player/group01/male_06.mdl", "models/player/group03/male_06.mdl" },
		["female_06"] = { "models/player/group01/female_06.mdl", "models/player/group03/female_06.mdl" },
		["male_07"] = { "models/player/group01/male_07.mdl", "models/player/group03/male_07.mdl" },
		["male_08"] = { "models/player/group01/male_08.mdl", "models/player/group03/male_08.mdl" },
		["male_09"] = { "models/player/group01/male_09.mdl", "models/player/group03/male_09.mdl" },
		["male_09"] = { "models/player/group01/male_09.mdl", "models/player/group03/male_09.mdl" },
		["odessa"] = { "models/player/odessa.mdl", "models/player/odessa.mdl" },
	}

	--[[
	local function GetPossibleModels()
		for i = 1, 40 do
			local idx = string.format("%02d", i)
			local female = "female_" .. idx .. ".mdl"
			local male = "male_" .. idx .. ".mdl"

			if util.IsValidModel("models/player/group01/" .. male) and util.IsValidModel("models/player/group03/" .. male) then
				local out = string.format("[\"%s\"] = { \"models/player/group01/%s\", \"models/player/group03/%s\" }, ", male, male, male)
				print(out)
			end

			if util.IsValidModel("models/player/group01/" .. female) and util.IsValidModel("models/player/group03/" .. female) then
				local out = string.format("[\"%s\"] = { \"models/player/group01/%s\", \"models/player/group03/%s\" }, ", female, female, female)
				print(out)
			end
		end
	end
	GetPossibleModels()
	]]

	function GM:InitializePlayerModels()
		local mdls = table.Copy(self.DefaultPlayerModels)
		-- TODO: Call LambdaGetPlayerModels hook
		self.AvailablePlayerModels = mdls
	end

	function GM:SendPlayerModelList(ply)
		if self.AvailablePlayerModels == nil then
			error("GM:InitializePlayerModels was never called")
		end
		net.Start("LambdaPlayerModels")
		net.WriteTable(self.AvailablePlayerModels)
		net.Send(ply)
		DbgPrint("Sending player model list to: " .. tostring(ply))
	end

else -- CLIENT

	function GM:SetPlayerModelList(mdls)
		self.AvailablePlayerModels = mdls
	end

	net.Receive("LambdaPlayerModels", function(len)
		local mdls = net.ReadTable()
		GAMEMODE:SetPlayerModelList(mdls)
		DbgPrint("Received player model list")
		--PrintTable(mdls)
	end)

end

function GM:GetAvailablePlayerModels()
	if SERVER and self.AvailablePlayerModels == nil then
		error("GM:InitializePlayerModels was never called")
	end
	return self.AvailablePlayerModels
end
