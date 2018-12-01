local DbgPrint = GetLogging("Level")
local g_debug_transitions = GetConVar("g_debug_transitions")

function GM:InitializeCurrentLevel()

    DbgPrint("GM:InitializeCurrentLevel")

    local changelevel = tobool(util.GetPData("Lambda" .. self:GetSetting("instance_id"):GetString(), "Changelevel", "0"))
    local prevMap = util.GetPData("Lambda" .. self:GetSetting("instance_id"):GetString(), "PrevMap", nil)
    local targetMap = util.GetPData("Lambda" .. self:GetSetting("instance_id"):GetString(), "NextMap", nil)
    local landmark = util.GetPData("Lambda" .. self:GetSetting("instance_id"):GetString(), "Landmark", nil)

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

    self.ChangingLevel = false

    util.RemovePData("Lambda" .. self:GetSetting("instance_id"):GetString(), "Changelevel")
    util.RemovePData("Lambda" .. self:GetSetting("instance_id"):GetString(), "Landmark")
    util.RemovePData("Lambda" .. self:GetSetting("instance_id"):GetString(), "PrevMap")

    DbgPrint("Used Changelevel: " .. tostring(self.IsChangeLevel))

    self:InitializeTransitionData()

end

function GM:GetEntryLandmark()
    return self.EntryLandmark
end

function GM:DisablePreviousMap()

    DbgPrint("GM:DisablePreviousMap")

    local landmark = self:GetEntryLandmark()
    local prevMap = self:GetPreviousMap()
    local changelevelPrev = nil
    local disabledPrev = false

    for _,v in pairs(ents.FindByClass("trigger_changelevel")) do

        if v.TargetMap == nil then
            continue
        end

        if v:HasSpawnFlags(SF_CHANGELEVEL_NOTOUCH) == true then
            DbgPrint("Skipping trigger_changelevel, has SF_CHANGELEVEL_NOTOUCH")
            continue
        end

        if v.TargetMap == prevMap then
            changelevelPrev = v
        end

        if landmark ~= nil and ignoreLandmark ~= true then
            if v.Landmark ~= nil and v.Landmark ~= "" then
                DbgPrint(v, "Landmark: " .. v.Landmark .. " == " .. landmark)
                if v.Landmark == landmark then
                    DbgPrint("Disabling previous changelevel: " .. v.Landmark)
                    v:SetBlocked(true)
                    disabledPrev = true
                end
            else
                if v.TargetMap == prevMap then
                    DbgPrint("Disabling previous changelevel: " .. v.Landmark)
                    v:SetBlocked(true)
                    disabledPrev = true
                end
            end
        end

    end

    -- If we are unable to find a landmark that points back we will assume its the previous map.
    if disabledPrev ~= true and IsValid(changelevelPrev) then
        DbgPrint("Blocking previous map (assumed): " .. prevMap)
        changelevelPrev:SetBlocked(true)
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

    util.SetPData("Lambda" .. lambda_instance_id:GetString(), "PrevMap", self:GetCurrentMap())
    util.SetPData("Lambda" .. lambda_instance_id:GetString(), "NextMap", map)
    util.SetPData("Lambda" .. lambda_instance_id:GetString(), "Landmark", landmark)
    util.SetPData("Lambda" .. lambda_instance_id:GetString(), "Changelevel", "1")

    -- Serialize user infos.
    if self.MapScript ~= nil and self.MapScript.PreChangelevel then
        self.MapScript:PreChangelevel(map, landmark)
    end

    hook.Call("LambdaPreChangelevel", GAMEMODE, map, landmark)

    self:TransitionToLevel(map, landmark, playersInTrigger or {})

end

function GM:ChangeLevel(map, landmark, playersInTrigger)

    if playersInTrigger == nil then
        playersInTrigger = {}
    end

    if self.ChangingLevel == true and g_debug_transitions:GetBool() == false then
        DbgError("Called ChangeLevel twice!")
        return
    end

    self.ChangingLevel = true

    DbgPrint("Changing to level: " .. map)

    self:PreChangelevel(map, landmark, playersInTrigger)

    local nextMap = map
    if g_debug_transitions:GetBool() ~= true then
        --timer.Simple(0.1, function()
            game.ConsoleCommand("changelevel " .. nextMap .. "\n")
        --end)
    end

end

function GM:ChangeToNextLevel()

    local nextMap = self:GetNextMap()

    for k,v in pairs(ents.FindByClass("trigger_changelevel")) do
        if v.TargetMap == nextMap then

            local landmark = v.Landmark
            return self:ChangeLevel(nextMap, landmark, {})

        end
    end

    return self:ChangeLevel(nextMap, nil, {})

end
