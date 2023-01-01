if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Difficulty")
local player = player
local IsValid = IsValid

DMG_SCALE_PVN = 1
DMG_SCALE_NVP = 2
DMG_SCALE_PVP = 3
DMG_SCALE_NVN = 4

local PROFICIENCY_NAME =
{
    [WEAPON_PROFICIENCY_POOR] = "Poor",
    [WEAPON_PROFICIENCY_AVERAGE] = "Average",
    [WEAPON_PROFICIENCY_GOOD] = "Good",
    [WEAPON_PROFICIENCY_VERY_GOOD] = "Very Good",
    [WEAPON_PROFICIENCY_PERFECT] = "Perfect",
}

cvars.AddChangeCallback("lambda_difficulty", function(cvar, oldVal, newVal)

    GAMEMODE:ResetMetrics()
    GAMEMODE:AdjustDifficulty()

end, "LambdaDifficulty")

function GM:InitializeDifficulty()

    DbgPrint("GM:InitializeDifficulty")

    self.RoundNumber = 0

    self.PlayerDeaths = 1
    self.PlayerKills = 1
    self.PlayerBulletsFired = 0
    self.PlayerFitness = 1
    self.PlayerFitnessScale = 0.2

    self.NPCDeaths = 1
    self.NPCKills = 1
    self.NPCFitness = 1
    self.NPCBulletsFired = 0
    self.NPCAwareness = 0
    self.NPCDamage = 1
    self.PlayerDamage = 1
    self.RoundsLost = 1
    self.RoundsWon = 1

    self:InitDifficultySettings()

end

function GM:InitDifficultySettings()

    local difficulties = {}
    for k, v in pairs(self:GetDifficultyData()) do
        difficulties[k] = v.Name
    end

    self:AddSetting("difficulty", {
        Category = "SERVER",
        NiceName = "#GM_DIFFICULTY",
        Description = "Difficulty",
        Type = "int",
        Default = 0,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Extra = {
            Type = "combo",
            Choices = difficulties,
        },
    })

end

function GM:SaveTransitionDifficulty(data)
end

function GM:LoadTransitionDifficulty(data)
end

function GM:RegisterRoundLost()
    self.RoundsLost = self.RoundsLost + 1
end

function GM:RegisterRoundWon()
    self.RoundsWon = self.RoundsWon + 1
end

function GM:GetDifficulty()
    return self:GetSetting("difficulty")
end

function GM:GetDifficultyData()
    return self:CallGameTypeFunc("GetDifficultyData")
end

function GM:GetDifficultyText(d)
    if d == nil then
        d = self:GetDifficulty()
    end
    local entries = self:GetDifficultyData()
    local entry = entries[d]
    if entry == nil then
        error("Invalid difficulty parameter: " .. tostring(d))
    end
    return entry.Name
end

function GM:GetCurrentDifficultyData()
    local difficulty = self:GetSetting("difficulty")
    local entries = self:GetDifficultyData()
    local entry = entries[difficulty]
    return entry
end

function GM:GetDifficultyDamageScale(type)

    local data = self:GetCurrentDifficultyData()
    if data == nil then
        return 1
    end

    return data.DamageScale[type]

end

function GM:GetDifficultyNPCHitgroupDamageScale(group)

    local data = self:GetCurrentDifficultyData()
    if data == nil then
        return 1
    end

    return data.HitgroupNPCDamageScale[group]

end

function GM:GetDifficultyWeaponProficiency()

    local data = self:GetCurrentDifficultyData()
    if data == nil then
        return WEAPON_PROFICIENCY_GOOD
    end

    return data.Proficiency
end

function GM:GetDifficultyWeaponProficiencyText()
    local proficiency = self:GetDifficultyWeaponProficiency()
    return PROFICIENCY_NAME[proficiency]
end

function GM:GetDifficultyPlayerHitgroupDamageScale(group)

    local data = self:GetCurrentDifficultyData()
    if data == nil then
        --error("Invalid difficulty selected")
        return 1.0
    end

    return data.HitgroupPlayerDamageScale[group]

end

-- Returns the scale the game should base on player count.
function GM:GetNPCSpawningScale()
    local data = self:GetCurrentDifficultyData()
    if data == nil then
        return 0
    end
    return data.NPCSpawningScale
end

function GM:AdjustDifficulty()

    if player.GetCount() == 0 then
        -- calling game.SetSkilLLevel can crash if gamesrules is nullptr, so we just use it once players are around.
        return
    end

    local difficulty = self:GetDifficulty()
    if difficulty == nil then
        return
    end

    DbgPrint("Difficulty Adjustment: " .. difficulty)

    local data = self:GetCurrentDifficultyData()
    if data == nil then
        return
    end

    if SERVER then
        RunConsoleCommand("skill", tostring(data.Skill))
        game.SetSkillLevel(data.Skill)

        for k,v in pairs(self.EnemyNPCs or {}) do
            if IsValid(v) then
                self:AdjustNPCDifficulty(v, data)
            end
        end
    end

end

function GM:AdjustNPCDifficulty(npc, data)

    if data == nil then
        data = self:GetCurrentDifficultyData()
        if data == nil then
            return
        end
    end

    DbgPrint("Adjusting NPC difficulty: " .. tostring(npc) .. ", Prof: " .. data.Proficiency)
    npc:SetCurrentWeaponProficiency(data.Proficiency)

end
