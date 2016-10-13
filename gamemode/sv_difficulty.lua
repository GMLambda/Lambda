local DbgPrint = GetLogging("Difficulty")

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

	--self:CalculateDifficulty()

end

function GM:SaveTransitionDifficulty(data)
end

function GM:LoadTransitionDifficulty(data)

end

function GM:RegisterBulletFired(attacker, bullets)
end

function GM:RegisterNPCDamage(npc, attacker, dmginfo)
end

function GM:RegisterPlayerDamage(ply, attacker, dmginfo)
end

function GM:RegisterRoundLost()
	self.RoundsLost = self.RoundsLost + 1
end

function GM:RegisterRoundWon()
	self.RoundsWon = self.RoundsWon + 1
end

function GM:GetPVN()
	-- FIXME: Add some scaling that doesnt suck.
	return 1
end

function GM:GetNVP()
	-- FIXME: Add some scaling that doesnt suck.
	return 1
end

function GM:RegisterPlayerDeath(ply, attacker, inflictor)
end

function GM:RegisterNPCDeath(npc, attacker, inflictor)
end

function GM:GetDifficultyPlayerDamageScale(attacker)

	local scale = self:GetNVP()
	return scale

end

function GM:GetDifficultyNPCDamageScale()

	local scale = self:GetPVN()
	return scale

end

function GM:GetDifficulty()

	return 3

end

function GM:AdjustDifficulty()

	if player.GetCount() == 0 then
		-- calling game.SetSkilLLevel can crash if gamesrules is nullptr, so we just use it once players are around.
		return
	end

	local difficulty = self:GetDifficulty()

	DbgPrint("Difficulty: " .. difficulty)

	game.SetSkillLevel(difficulty)

	for k,v in pairs(self.EnemyNPCs or {}) do
		if IsValid(v) then
			self:AdjustNPCDifficulty(v, difficulty)
		end
	end

end

local WEAPON_PROFICIENCY =
{
	WEAPON_PROFICIENCY_AVERAGE,
	WEAPON_PROFICIENCY_GOOD,
	WEAPON_PROFICIENCY_PERFECT,
}

function GM:AdjustNPCDifficulty(npc, difficulty)

	difficulty = difficulty or self:GetDifficulty()
	local proficiency = WEAPON_PROFICIENCY[difficulty]

	npc:SetCurrentWeaponProficiency(proficiency)

end
