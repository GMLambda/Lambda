local DbgPrint = GetLogging("Level")
local g_debug_transitions = GetConVar("g_debug_transitions")

function GM:InitializeCurrentLevel()

	DbgPrint("GM:InitializeCurrentLevel")

	local changelevel = tobool(util.GetPData("Lambda", "Changelevel", "0"))
	local prevMap = util.GetPData("Lambda", "PrevMap", nil)
	local targetMap = util.GetPData("Lambda", "NextMap", nil)
	local landmark = util.GetPData("Lambda", "Landmark", nil)

	self.PreviousMap = prevMap
	if targetMap == self:GetCurrentMap() then
		self.EntryLandmark = landmark
	else
		self.EntryLandmark = nil
	end

	if changelevel == true and targetMap == self:GetCurrentMap() then
		-- Reset
		self.IsChangeLevel = true
	else
		self.IsChangeLevel = false
	end

	util.RemovePData("Lambda", "Changelevel")
	util.RemovePData("Lambda", "Landmark")
	util.RemovePData("Lambda", "PrevMap")

	DbgPrint("Used Changelevel: " .. tostring(self.IsChangeLevel))

	self:InitializeTransitionData()

end

function GM:DisablePreviousMap()

	DbgPrint("GM:DisablePreviousMap")

	local landmark = self:GetEntryLandmark()
	local prevMap = self:GetPreviousMap()

	for _,v in pairs(ents.FindByClass("trigger_changelevel")) do

		if v.TargetMap == nil then
			continue
		end

		if v:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) then
			continue
		end

		if landmark ~= nil then
			if v.Landmark ~= nil and v.Landmark ~= "" then
				if v.Landmark == landmark then
					DbgPrint("Disabling previous changelevel: " .. v.Landmark)
					v:SetBlocked(true)
				end
			else
				if v.TargetMap == prevMap then
					DbgPrint("Disabling previous changelevel: " .. v.Landmark)
					v:SetBlocked(true)
				end
			end
		else
			if v.TargetMap == prevMap then
				DbgPrint("Blocking previous map (assumed): " .. prevMap)
				v:SetBlocked(true)
			end
		end

	end

end

function GM:EnablePreviousMap()

	DbgPrint("GM:EnablePreviousMap")

	local landmark = self:GetEntryLandmark()
	local prevMap = self:GetPreviousMap()

	for _,v in pairs(ents.FindByClass("trigger_changelevel")) do

		if v.TargetMap == nil then
			continue
		end

		if v.DisableTouch == true then
			continue
		end

		if landmark ~= nil then
			if v.Landmark == landmark then
				DbgPrint("Enabling previous changelevel: " .. v.Landmark)
				v:SetBlocked(false)
				v:Enable()
			end
		else
			if v.TargetMap == prevMap then
				DbgPrint("Enabling previous map (assumed): " .. prevMap)
				v:SetBlocked(false)
				v:Enable()
			end
		end

	end

end

function GM:PreChangelevel(map, landmark, playersInTrigger)

	util.SetPData("Lambda", "PrevMap", self:GetCurrentMap())
	util.SetPData("Lambda", "NextMap", map)
	util.SetPData("Lambda", "Landmark", landmark)
	util.SetPData("Lambda", "Changelevel", "1")

	-- Serialize user infos.
	if self.MapScript ~= nil and self.MapScript.PreChangelevel then
		self.MapScript:PreChangelevel(map, landmark)
	end

	hook.Call("LambdaPreChangelevel", GAMEMODE, map, landmark)

	self:TransitionToLevel(map, landmark, playersInTrigger)

end

function GM:GetNextMap()

	local gameType = self:GetGameType()
	local mapList = gameType.MapList

	local current = self:GetCurrentMapIndex()
	if current + 1 > #mapList then
		return nil
	end
	return mapList[current + 1]

end

function GM:GetPreviousMap()

	local gameType = self:GetGameType()
	local mapList = gameType.MapList

	local current = self:GetCurrentMapIndex()
	if current - 1 < 0 then
		return nil
	end
	return mapList[current - 1]

end

function GM:GetCurrentMap()
	local curMap = string.lower(game.GetMap())
	return curMap
end

function GM:GetEntryLandmark()
	return self.EntryLandmark or nil
end

function GM:GetMapIndex(prevMap, currentMap)

	local gameType = self:GetGameType()
	local mapList = gameType.MapList

	DbgPrint("Getting Map Index, Prev: " .. tostring(prevMap) .. ", Cur: " .. currentMap)
	local foundPrev = false
	local lastIndex = 0

	for k, v in pairs(mapList) do
		if foundPrev then
			if v == currentMap then
				return k
			end
			foundPrev = false
		end

		if v == currentMap then
			lastIndex = k -- In case there was a huge jump due a manual changelevel by user.
		end

		if v == prevMap then
			foundPrev = true
		elseif prevMap == nil and v == currentMap then
			return k
		end
	end

	return lastIndex

end

function GM:GetCurrentMapIndex()
	local curMap = self:GetCurrentMap()
	local index = self:GetMapIndex( self.PreviousMap, curMap )
	DbgPrint("GetCurrentMapIndex: " .. tostring(index))
	return index
end

if SERVER then

	function GM:ChangeLevel(map, landmark, playersInTrigger)

		if self.ChangingLevel == true then
			DbgError("Called ChangeLevel twice!")
			return
		end

		self.ChangingLevel = true

		DbgPrint("Changing to level: " .. map)

		self:PreChangelevel(map, landmark, playersInTrigger)

		local map = map
		if g_debug_transitions:GetBool() ~= true then
			--timer.Simple(0.1, function()
				game.ConsoleCommand("changelevel " .. map .. "\n")
			--end)
		end

	end

end
