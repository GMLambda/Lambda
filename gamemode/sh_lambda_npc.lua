DEFINE_BASECLASS( "gamemode_base" )

if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("NPC")
local DbgPrintDmg = GetLogging("Damage")

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
		if vel:Length() >= 40 then
			EmitSound(table.Random(SOLIDER_GEAR_SOUNDS), npc:GetPos(), npc:EntIndex(), CHAN_BODY)
		end
	end

end

if SERVER then

	function GM:ScaleNPCDamage(npc, hitgroup, dmginfo)

		local DbgPrint = DbgPrintDmg 

		DbgPrint("ScaleNPCDamage", npc, hitgroup)

		-- Must be called here not in EntityTakeDamage as that runs after so scaling wouldn't work.
		self:ApplyCorrectedDamage(dmginfo)

		local attacker = dmginfo:GetAttacker()

		if dmginfo:IsDamageType(DMG_BULLET) == true then 
			self:MetricsRegisterBulletHit(attacker, npc, hitgroup)
		end 

		-- First scale hitgroups.
		local scale = self:GetDifficultyNPCHitgroupDamageScale(hitgroup)
		DbgPrint("Hitgroup Scale", npc, scale)
		dmginfo:ScaleDamage(scale)

		-- Scale by difficulty.
		local scaleType = 0
		if attacker:IsPlayer() == true then 
			scaleType = DMG_SCALE_PVN
		elseif attacker:IsNPC() == true then 
			scaleType = DMG_SCALE_NVN
		end
		if scaleType ~= 0 then 
			local scale = self:GetDifficultyDamageScale(scaleType)
			if scale ~= nil then 
				DbgPrint("Scaling difficulty damage: " .. tostring(scale))
				dmginfo:ScaleDamage(scale)
			end
		end 

		DbgPrint("ScaleNPCDamage -> Applying " .. dmginfo:GetDamage() .. " damage to: " .. tostring(npc))

	end

	function GM:RegisterNPC(npc)

		-- Enable lag compensation on NPCs
		npc:SetLagCompensated(true)

		self.EnemyNPCs = self.EnemyNPCs or {}

		local enemyClasses = self:GetGameTypeData("ClassesEnemyNPC") or {}
		if enemyClasses[npc:GetClass()] == true then
			self.EnemyNPCs[npc] = npc
		end

		self:AdjustNPCDifficulty(npc)

		local equip = npc:GetInternalVariable("additionalequipment")
		if npc:GetClass() == "npc_combine_s" and (equip == "ai_weapon_shotgun" or equip == "weapon_shotgun") then
			-- HACKHACK: I'm guessing garry removed loading skins based on their weapons at some point.
			npc:SetSkin(1)
		end

		if self.MapScript.OnRegisterNPC ~= nil then
			self.MapScript:OnRegisterNPC(npc)
		end

	end

	local function DissolveEntity(ent)

		local name = "dissolve_" .. tostring(ent:EntIndex())
		ent:SetName(name)

		local dissolver = ents.Create("env_entity_dissolver")
		dissolver:SetKeyValue("target", name)
		dissolver:SetKeyValue("dissolvetype", "0")
		dissolver:Spawn()
		dissolver:Activate()

		dissolver:Fire("Dissolve", ent:GetName(), 0)
		dissolver:Fire("Kill", ent:GetName(), 0.1)

	end

	function GM:HandleCriticalNPCDeath(npc)

		local gameType = self:GetGameType()
		local mapScript = self.MapScript
		local name = npc:GetName()
		local class = npc:GetClass()
		local missionFailure = false

		if gameType.ImportantPlayerNPCNames[name] == true then
			missionFailure = true
		elseif gameType.ImportantPlayerNPCClasses[class] == true then
			missionFailure = true
		elseif mapScript ~= nil and mapScript.ImportantPlayerNPCNames ~= nil and mapScript.ImportantPlayerNPCNames[name] == true then
			missionFailure = true
		elseif mapScript ~= nil and mapScript.ImportantPlayerNPCClasses ~= nil and mapScript.ImportantPlayerNPCClasses[class] == true then
			missionFailure = true
		elseif npc.ImportantNPC == true then
			missionFailure = true
		end

		if missionFailure == true then
			self:RestartRound()
			self:RegisterRoundLost()
		end

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
				hook.Run("OnPlayerKilledFriendly", ply, npc)
			else
				ply:AddFrags(1)
				hook.Run("OnPlayerKilledEnemy", ply, npc)
			end
		end

		local wep = nil
		if npc.GetActiveWeapon then 
			wep = npc:GetActiveWeapon()
			if not IsValid(wep) then
				wep = nil
			end
		end
		if npc:HasSpawnFlags(8192) == true and wep ~= nil then
			--wep:Remove()
			DissolveEntity(wep)
			wep = nil
		end
		if wep ~= nil then
			-- FIXME: https://github.com/Facepunch/garrysmod-issues/issues/3377
			if IsEnemyEntityName(npc:GetClass()) == true then
				wep.HeldByEnemy = true
			else
				wep.HeldByFriendly = true
			end
			--print("Marked weapon: " .. tostring(wep))
		end

		self:HandleCriticalNPCDeath(npc)
		self:RegisterNPCDeath(npc, attacker, inflictor)

	end

	function GM:RegisterNPCDeath(npc, attacker, inflictor)

		if npc:GetClass() == "npc_bullseye" or npc:GetClass() == "npc_launcher" then return end
		if IsValid(attacker) and attacker:GetClass() == "trigger_hurt" then attacker = npc end
		if IsValid(attacker) and attacker:IsVehicle() and IsValid(attacker:GetDriver()) then attacker = attacker:GetDriver() end
		if not IsValid(inflictor) and IsValid(attacker) then inflictor = attacker end
		
		if IsValid(inflictor) and attacker == inflictor and inflictor:IsPlayer() or inflictor:IsNPC() then
			inflictor = inflictor:GetActiveWeapon()
			if not IsValid(attacker) then inflictor =  attacker end
		end

		local inflictor_class = "worldspawn"
		local attacker_class = "worldspawn"

		local data = {}

		if IsValid(inflictor) then inflictor_class = inflictor:GetClass() end
		if IsValid(attacker) then
			attacker_class = attacker:GetClass()
			if attacker:IsPlayer() then
				data.type = DEATH_NPC
				data.npcclass = npc:GetClass()
				data.infclass = inflictor_class
				data.attacker = attacker
				net.Start("LambdaDeathEvent")
					net.WriteTable(data)
				net.Broadcast()
			return end
		end

		if npc:GetClass() == "npc_turret_floor" then attacker_class = npc:GetClass() end

		local data = {}
		data.type = DEATH_BYNPC
		data.npcclass = npc:GetClass()
		data.infclass = inflictor_class
		data.attclass = attacker_class
		if IsValid(attacker) then 
			data.attacker = attacker
		end
		net.Start("LambdaDeathEvent")
			net.WriteTable(data)
		net.Broadcast()

	end

	function GM:NPCThink()

		local curTime = CurTime()

		self.NextNPCThink = self.NextNPCThink or curTime

		if curTime < self.NextNPCThink then
			return
		end

		self.NextNPCThink = curTime + 0.1

		-- Don't chase players if they are not criminals.
		local precriminal = game.GetGlobalState("gordon_precriminal") == GLOBAL_ON
		if precriminal == true then
			return
		end

		self.IdleEnemyNPCs = {}

		for k,v in pairs(self.EnemyNPCs or {}) do

			if not IsValid(v) or not v:IsNPC() then
				self.EnemyNPCs[k] = nil
				continue
			end

			if v:GetName() ~= "" or v:GetNPCState() ~= NPC_STATE_IDLE then
				continue
			end

			local idleNPC = v:IsCurrentSchedule(SCHED_IDLE_STAND)
			if idleNPC == false then
				continue
			end

			local npc = v
			table.insert(self.IdleEnemyNPCs, npc)

		end

	end

end

function GM:NotifyNPCFootsteps( ply, pos, foot, sound, volume)
	-- Appears to be still called in pods, so lets not notify them.
	if ply:InVehicle() == true or ply:KeyDown(IN_DUCK) == true then
		return
	end

	for _,npc in pairs(self.IdleEnemyNPCs or {}) do

		if not IsValid(npc) then
			continue
		end

		local dist = npc:GetPos():Distance(pos)
		-- Slight chance that they will hear the footsteps and go towards the sound position.
		if dist < 500 and math.random(0, 5) == 0 then
			npc:SetLastPosition(pos)
			npc:SetSchedule(SCHED_FORCED_GO)
		end

	end

end
