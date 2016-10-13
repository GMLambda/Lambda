DEFINE_BASECLASS( "gamemode_base" )

local DbgPrint = GetLogging("NPC")

if SERVER then

	AddCSLuaFile()

end

	local sk_npc_head = GetConVar("sk_npc_head")
	local sk_npc_chest = GetConVar("sk_npc_chest")
	local sk_npc_stomach = GetConVar("sk_npc_stomach")
	local sk_npc_arm = GetConVar("sk_npc_arm")
	local sk_npc_leg = GetConVar("sk_npc_leg")

	local HITGROUP_SCALE =
	{
		[HITGROUP_GENERIC] = function() return 1.0 end,
		[HITGROUP_HEAD] = function() return sk_npc_head:GetFloat() end,
		[HITGROUP_CHEST] = function() return sk_npc_chest:GetFloat() end,
		[HITGROUP_STOMACH] = function() return sk_npc_stomach:GetFloat() end,
		[HITGROUP_LEFTARM] = function() return sk_npc_arm:GetFloat() end,
		[HITGROUP_RIGHTARM] = function() return sk_npc_arm:GetFloat() end,
		[HITGROUP_LEFTLEG] = function() return sk_npc_leg:GetFloat() end,
		[HITGROUP_RIGHTLEG] = function() return sk_npc_leg:GetFloat() end,
	}

	local SOLIDER_GEAR_SOUNDS =
	{
		"npc/combine_soldier/gear1.wav",
		"npc/combine_soldier/gear2.wav",
		"npc/combine_soldier/gear3.wav",
		"npc/combine_soldier/gear4.wav",
		"npc/combine_soldier/gear5.wav",
		"npc/combine_soldier/gear6.wav"
	}

	function GM:NPCFootstep(npc, data)

		local class = npc:GetClass()
		if class == "npc_combine" or class == "npc_combine_s" then
			--npc:EmitSound(table.Random(SOLIDER_GEAR_SOUNDS))
			local vel = npc:GetVelocity()
			local len = vel:Length()
			if vel:Length() >= 40 then
				EmitSound(table.Random(SOLIDER_GEAR_SOUNDS), npc:GetPos(), npc:EntIndex(), CHAN_BODY)
			end
		end

	end

if SERVER then

	function GM:ScaleNPCDamage(npc, hitgroup, dmginfo)

		local attacker = dmginfo:GetAttacker()
		local inflictor = dmginfo:GetInflictor()

		--DbgPrint("ScaleNPCDamage -> Attacker: " .. tostring(attacker) .. ", Inflictor: " .. tostring(inflictor))

		-- For the lazy matt to test things more quickly.
		if attacker:IsPlayer() then
			--dmginfo:ScaleDamage(100)
			if not IsValid(npc:GetEnemy()) then
				DbgPrint("Making the attacker the NPC enemy")
				npc:SetEnemy(attacker)
			end
		end

		self:ApplyCorrectedDamage(dmginfo)

		local hitgroupScale = HITGROUP_SCALE[hitgroup]  or function() return 1.0 end

		if dmginfo:IsDamageType(DMG_BLAST) then

		else

			if hitgroup == HITGROUP_GEAR then
				dmginfo:SetDamage(0.1)
				return
			else
				local scale = hitgroupScale()
				--DbgPrint("Scaling damage with: " .. scale)
				dmginfo:ScaleDamage( scale )
			end

			local difficulty = game.GetSkillLevel()
			if difficulty == 3 then
				dmginfo:ScaleDamage( 0.7 )
			end

		end

		--DbgPrint("ScaleNPCDamage -> Applying " .. dmginfo:GetDamage() .. " damage to: " .. tostring(npc))

	end

	function GM:RegisterNPC(npc)

		-- Enable lag compensation on NPCs
		npc:SetLagCompensated(true)

		self.EnemyNPCs = self.EnemyNPCs or {}

		local gametype = self:GetGameType()

		if gametype and gametype.ClassesEnemyNPC and gametype.ClassesEnemyNPC[npc:GetClass()] == true then
			table.insert(self.EnemyNPCs, npc)
		end

		self:AdjustNPCDifficulty(npc)

		if npc:GetClass() == "npc_combine_s" then

			-- HACKHACK: I'm guessing garry removed loading skins based on their weapons at some point.
			if npc:GetInternalVariable("additionalequipment") == "ai_weapon_shotgun" then
				npc:SetSkin(1)
			end

		end

		npc:SetCustomCollisionCheck(true)

	end

	function GM:OnNPCKilled(npc, attacker, inflictor)
		local ply = nil
		if IsValid(attacker) and attacker:IsPlayer() then
			ply = attacker
		elseif IsValid(inflictor) and inflictor:IsPlayer() then
			ply = inflictor
		end
		if IsValid(ply) then
			if IsFriendEntityName(npc:GetClass()) then
				ply:AddFrags(-1)
			else
				ply:AddFrags(1)
			end
		end

		self:RegisterNPCDeath(npc, attacker, inflictor)

		BaseClass.OnNPCKilled(self, npc, attacker, inflictor)
	end

	local function GetClosestPlayer(pos, minRange)
		-- Hunt closest player.
		local minDist = minRange
		local ply
		for _,v in pairs(player.GetAll()) do
			if bit.band(v:GetFlags(), FL_NOTARGET) ~= 0 then
				continue
			end
			local dist = v:GetPos():Distance(pos)
			if dist < minDist then
				minDist = dist
				ply = v
			end
		end
		return ply
	end

	local IDLE_SCHEDULES =
	{
		SCHED_COMBAT_PATROL,
		SCHED_PATROL_RUN,
		SCHED_COMBAT_STAND,
		SCHED_COMBAT_SWEEP,
		SCHED_COMBAT_WALK,
	}

	function GM:NPCThink()

		local curTime = CurTime()

		self.NextNPCThink = self.NextNPCThink or curTime

		if curTime < self.NextNPCThink then
			return
		end

		self.NextNPCThink = curTime + 0.1

		local precriminal = false
		for _,v in pairs(ents.FindByClass("env_global")) do
			local state = v:GetInternalVariable("globalstate")
			if isstring(state) and state == "gordon_precriminal" then
				--DbgPrint("Gordon precriminal")
				precriminal = true
			end
		end

		-- Don't chase players if they are not criminals.
		if precriminal == true then
			return
		end

		self.IdleEnemyNPCs = {}

		for k,v in pairs(self.EnemyNPCs or {}) do

			if not IsValid(v) or not v:IsNPC() then
				--self.EnemyNPCs[k] = nil
				continue
			end

			--[[
			local enemy = v:GetEnemy()
			if IsValid(enemy) then
				if v:VisibleVec(enemy:GetPos()) == false then
					--DbgPrint("Enemy is not visible")
					--v:SetEnemy(nil)
					--v:SetTarget(v)
					--v:ClearSchedule()
					--v:SetSchedule(SCHED_IDLE_STAND)
				end
			end
			]]

			local idleNPC = v:IsCurrentSchedule(SCHED_ALERT_STAND) or
				v:IsCurrentSchedule(SCHED_IDLE_STAND) or
				v:IsCurrentSchedule(SCHED_FAIL) or
				v:IsCurrentSchedule(SCHED_COMBAT_STAND)

			if idleNPC == false then
				continue
			end

			--DbgPrint("Found idle NPC: " .. tostring(v))

			local npc = v
			table.insert(self.IdleEnemyNPCs, npc)
			npc:SetSchedule(SCHED_COMBAT_PATROL)

		end

	end

end

function GM:NotifyNPCFootsteps( ply, pos, foot, sound, volume)

	for _,npc in pairs(self.IdleEnemyNPCs or {}) do

		if not IsValid(npc) then
			continue
		end

		local dist = npc:GetPos():Distance(pos)
		if dist < 1000 then
			npc:SetLastPosition(pos)
			npc:SetSchedule(SCHED_FORCED_GO)
		end

	end

end
