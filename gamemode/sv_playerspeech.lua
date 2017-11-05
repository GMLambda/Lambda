local DbgPrint = GetLogging("PlayerSpeech")

local SPEECH_GROUPS =
{
	["teammate_death"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/gordead_ans01.wav",
				"vo/npc/male01/gordead_ans02.wav",
				"vo/npc/male01/gordead_ans03.wav",
				"vo/npc/male01/gordead_ans04.wav",
				"vo/npc/male01/gordead_ans05.wav",
				"vo/npc/male01/gordead_ans06.wav",
				"vo/npc/male01/gordead_ans07.wav",
				"vo/npc/male01/gordead_ans08.wav",
				"vo/npc/male01/gordead_ans09.wav",
				"vo/npc/male01/gordead_ans10.wav",
				"vo/npc/male01/gordead_ans11.wav",
				"vo/npc/male01/gordead_ans12.wav",
				"vo/npc/male01/gordead_ans13.wav",
				"vo/npc/male01/gordead_ans14.wav",
				"vo/npc/male01/gordead_ans15.wav",
				"vo/npc/male01/gordead_ans16.wav",
				"vo/npc/male01/gordead_ans18.wav",
				"vo/npc/male01/gordead_ans19.wav",
				"vo/npc/male01/wetrustedyou01.wav",
				"vo/npc/male01/wetrustedyou02.wav",
			},
			["female"] = { "vo/npc/female01/gordead_ans01.wav",
				"vo/npc/female01/gordead_ans02.wav",
				"vo/npc/female01/gordead_ans03.wav",
				"vo/npc/female01/gordead_ans04.wav",
				"vo/npc/female01/gordead_ans05.wav",
				"vo/npc/female01/gordead_ans06.wav",
				"vo/npc/female01/gordead_ans07.wav",
				"vo/npc/female01/gordead_ans08.wav",
				"vo/npc/female01/gordead_ans09.wav",
				"vo/npc/female01/gordead_ans10.wav",
				"vo/npc/female01/gordead_ans11.wav",
				"vo/npc/female01/gordead_ans12.wav",
				"vo/npc/female01/gordead_ans13.wav",
				"vo/npc/female01/gordead_ans14.wav",
				"vo/npc/female01/gordead_ans15.wav",
				"vo/npc/female01/gordead_ans16.wav",
				"vo/npc/female01/gordead_ans18.wav",
				"vo/npc/female01/gordead_ans19.wav",
				"vo/npc/female01/wetrustedyou01.wav",
				"vo/npc/female01/wetrustedyou02.wav",
			},
		},
		FallbackTime = 3,
	},
	["death_imminent"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/uhoh.wav", "vo/npc/male01/whoops01.wav" },
			["female"] = { "vo/npc/female01/uhoh.wav", "vo/npc/female01/whoops01.wav" },
		},
		FallbackTime = 3,
	},
	["grenade"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/watchout.wav", "vo/npc/male01/takecover02.wav" },
			["female"] = { "vo/npc/female01/watchout.wav", "vo/npc/female01/takecover02.wav" },
		},
		FallbackTime = 3,
	},
	["reload"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/coverwhilereload02.wav", "vo/npc/male01/coverwhilereload01.wav" },
			["female"] = { "vo/npc/female01/coverwhilereload02.wav", "vo/npc/female01/coverwhilereload01.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_combine_s"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/combine01.wav", "vo/npc/male01/combine02.wav" },
			["female"] = { "vo/npc/female01/combine01.wav", "vo/npc/female01/combine02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_combine"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/combine01.wav", "vo/npc/male01/combine02.wav" },
			["female"] = { "vo/npc/female01/combine01.wav", "vo/npc/female01/combine02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_zombie"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/zombies01.wav", "vo/npc/male01/zombies02.wav" },
			["female"] = { "vo/npc/female01/zombies01.wav", "vo/npc/female01/zombies02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_zombie_fast"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/zombies01.wav", "vo/npc/male01/zombies02.wav" },
			["female"] = { "vo/npc/female01/zombies01.wav", "vo/npc/female01/zombies02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_manhack"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/herecomehacks01.wav", "vo/npc/male01/herecomehacks02.wav", "vo/npc/male01/hacks01.wav", "vo/npc/male01/hacks02.wav" },
			["female"] = { "vo/npc/female01/herecomehacks01.wav", "vo/npc/female01/herecomehacks02.wav", "vo/npc/female01/hacks01.wav", "vo/npc/female01/hacks02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_headcrab"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/headcrabs01.wav", "vo/npc/male01/headcrabs02.wav" },
			["female"] = { "vo/npc/female01/headcrabs01.wav", "vo/npc/female01/headcrabs02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_headcrab_black"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/headcrabs01.wav", "vo/npc/male01/headcrabs02.wav" },
			["female"] = { "vo/npc/female01/headcrabs01.wav", "vo/npc/female01/headcrabs02.wav" },
		},
		FallbackTime = 3,
	},
	["encounter_npc_headcrab_fast"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/headcrabs01.wav", "vo/npc/male01/headcrabs02.wav" },
			["female"] = { "vo/npc/female01/headcrabs01.wav", "vo/npc/female01/headcrabs02.wav" },
		},
		FallbackTime = 3,
	},
	["enemy_kill"] =
	{
		VO =
		{
			["male"] = { "vo/npc/male01/gotone01.wav", "vo/npc/male01/gotone02.wav" },
			["female"] = { "vo/npc/female01/gotone01.wav", "vo/npc/female01/gotone02.wav" },
		},
		FallbackTime = 3,
	},
	["enemy_kill_10"] =
	{
		VO =
		{
			["male"] = { "vo/coast/odessa/male01/nlo_cheer01.wav", "vo/coast/odessa/male01/nlo_cheer02.wav", "vo/coast/odessa/male01/nlo_cheer03.wav"  },
			["female"] = { "vo/coast/odessa/female01/nlo_cheer02.wav", "vo/coast/odessa/female01/nlo_cheer03.wav"  },
		},
		FallbackTime = 3,
	},
	["enemy_kill_5"] =
	{
		VO =
		{
			["male"] = { "vo/coast/odessa/male01/nlo_cheer01.wav", "vo/coast/odessa/male01/nlo_cheer02.wav", "vo/coast/odessa/male01/nlo_cheer03.wav"  },
			["female"] = { "vo/coast/odessa/female01/nlo_cheer02.wav", "vo/coast/odessa/female01/nlo_cheer03.wav"  },
		},
		FallbackTime = 3,
	},
}

local InSpeechUpdate = false
local NextSpeech = nil

local function EmitPlayerSpeech(ply, group, minWait)

	if InSpeechUpdate == false then
		NextSpeech = { ply, group, minWait }
		return true
	end

	if ply:Alive() == false then
		return false
	end

	local curTime = CurTime()
	if ply.NextSpeechTime > curTime then
		return false -- Busy
	end
	if minWait ~= nil and ply.LastSpeechTime ~= nil and CurTime() - ply.LastSpeechTime < minWait then
		return false -- Busy
	end

	local groupData = SPEECH_GROUPS[group]
	if groupData == nil then
		return false
	end

	local vos = groupData.VO[ply:GetGender()]
	local vo = table.Random(vos)
	local dur = SoundDuration(vo)

	util.RunDelayed(function()
		if not IsValid(ply) then return end
		ply:EmitSound(vo)
	end, CurTime() + 0.2)

	if dur ~= nil and dur > 0 then
		ply.NextSpeechTime = curTime + dur
	else
		ply.NextSpeechTime = curTime + (groupData.FallbackTime or 5) -- Fallback
	end
	ply.LastSpeechTime = CurTime()

	return true

end

function GM:InitializeGlobalSpeechContext()

	self.EnemyClassEncounters = {}

end

function GM:InitializePlayerSpeech(ply)

	ply.LastSpeechUpdate = CurTime()
	ply.NextSpeechTime = CurTime()
	ply.EnemyInSight = false
	ply.EnemyNearby = false
	ply.FriendlyInSight = false
	ply.FriendlyNearby = false
	ply.KillStreakTime = 0
	ply.KillStreak = 0

end

function GM:OnPlayerKilledEnemy(ply, npc)

	if ply.KillStreakTime == nil or CurTime() > ply.KillStreakTime then
		ply.KillStreak = 0
	end

	ply.KillStreakTime = CurTime() + 5	-- 1 per second is ok.
	ply.KillStreak = ply.KillStreak + 1

	if ply.FriendlyNearby == false then
		return
	end

	if ply.KillStreak >= 20 then
		ply.KillStreak = 0	-- Reset
	elseif ply.KillStreak == 10 then
		EmitPlayerSpeech(ply, "enemy_kill_10")
	elseif ply.KillStreak == 5 then
		EmitPlayerSpeech(ply, "enemy_kill_5")
	else
		if math.random(0, 10) == 0 then
			EmitPlayerSpeech(ply, "enemy_kill", 3)
		end
	end

end

function GM:OnPlayerWatchPlayerDie(viewer, ply)

	if viewer.FriendlyInSight == false then
		return
	end

end

function GM:HandleNPCContact(viewer, npc)

	if viewer.FriendlyInSight == false then
		return
	end

	local class = npc:GetClass()
	local curTime = CurTime()

	local encounterData = self.EnemyClassEncounters[class]
	local newEncounter = false

	if encounterData ~= nil then
		if curTime - encounterData.LastSeen > 60 then
			newEncounter = true
		end
	else
		newEncounter = true
	end

	if newEncounter == true and EmitPlayerSpeech(viewer, "encounter_" .. class) == true then
		self.EnemyClassEncounters[class] = { LastSeen = curTime }
	elseif newEncounter == false then
		encounterData.LastSeen = curTime
	end

end

function GM:HandlePlayerContact(viewer, ply)

	local alive = ply:Alive()
	local emitSpeech = false

	if alive == false and ply.ResetAliveState ~= true then
		ply.ResetAliveState = true
		emitSpeech = true
	else if alive == true and ply.ResetAliveState == true then
			ply.ResetAliveState = false
		end
	end

	if viewer.FriendlyInSight == false then
		return
	end

	if emitSpeech == true then
		EmitPlayerSpeech(viewer, "teammate_death")
	end

end

function GM:HandleWeaponContact(viewer, wep)
end

function GM:HandleGrenadeContact(viewer, nate)

	if viewer.FriendlyInSight == false then
		return
	end

	local pos = viewer:GetPos()
	local natePos = nate:GetPos()
	if natePos:Distance(pos) < 400 then
		return
	end

	-- TODO: Approximate the direction.

	if (nate.ExplosionAcknolwedged ~= true and
	   nate:GetPos():Distance(pos) <= 150 and
	   viewer:Health() <= 60 and
	   nate:GetInternalVariable("m_flDetonateTime") <= 0.6)
	then
		if EmitPlayerSpeech(viewer, "death_imminent") == true then
			nate.ExplosionAcknolwedged = true
			return
		end
	end

	if nate.Acknowledged == true then
		return
	end

	if EmitPlayerSpeech(viewer, "grenade") == true then
		nate.Acknowledged = true
	end

end

function GM:OnPlayerReload(ply, event, data)

	if ply.FriendlyInSight == false or ply.EnemyNearby == false then
		return
	end

	-- Don't annoy the player too much.
	if math.random(0, 5) ~= 0 then
		return
	end

	local wep = ply:GetActiveWeapon()
	local wepclass = wep:GetClass()
	if wepclass == "weapon_smg1" or wepclass == "weapon_pistol" or wepclass == "weapon_shotgun" or wepclass == "weapon_357" then
		EmitPlayerSpeech(ply, "reload")
	end

end

local ENTITY_CLASS_HANDLER =
{
	["npc_grenade_frag"] = GM.HandleGrenadeContact,
}

function GM:UpdatePlayerSpeech(ply)

	if ply:Alive() == false then
		return
	end

	local curTime = CurTime()
	if curTime - ply.LastSpeechUpdate < 0.5 then
		return
	end
	ply.LastSpeechUpdate = curTime
	
	local pos = ply:GetPos()

	ply.FriendlyInSight = false
	ply.FriendlyNearby = false
	ply.EnemyInSight = false
	ply.EnemyNearby = false

	local nearbyEnts = ents.FindInBox(pos - Vector(500, 500, 0), pos + Vector(500, 500, 164))
	local actions = {}

	for k,v in pairs(nearbyEnts) do
		if v == ply then
			continue
		end

		local isVisible = ply:Visible(v)
		if isVisible or v:IsPlayer() then

			local class = v:GetClass()
			if v:IsNPC() then
				if IsFriendEntityName(class) == false then
					ply.EnemyInSight = isVisible
					ply.EnemyNearby = true
				end
			elseif v:IsPlayer() == true and v:Alive() == true then
				ply.FriendlyInSight = isVisible
				ply.FriendlyNearby = true
			end

			local handler = ENTITY_CLASS_HANDLER[class]
			if handler ~= nil then
				handler(self, ply, v)
			else
				if v:IsNPC() then
					table.insert(actions, function() self:HandleNPCContact(ply, v) end)
				elseif v:IsPlayer() then
					table.insert(actions, function() self:HandlePlayerContact(ply, v) end)
				elseif v:IsWeapon() then
					table.insert(actions, function() self:HandleWeaponContact(ply, v) end)
				end
			end

		end
	end

	for _,v in pairs(actions) do
		v()
	end

	InSpeechUpdate = true

	if NextSpeech ~= nil and IsValid(NextSpeech[1]) then
		EmitPlayerSpeech(NextSpeech[1], NextSpeech[2], NextSpeech[3])
		NextSpeech = nil
	end

	InSpeechUpdate = false

end
