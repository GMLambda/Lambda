if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("LambdaWaterBullet")
end

local DbgPrint = GetLogging("Bullets")

if CLIENT then

	local BULLET_STEP_SIZE = 2500
	local BULLET_STEP_DISTANCE = 15
	local BUBBLES_PER_UNIT = 1.5

	function GM:CreateWaterBulletParticles(bullet, newPos, distance)

		local ply = LocalPlayer()
		if IsValid(ply) == false or ply:WaterLevel() ~= 3 then
			return
		end

		local curPos = bullet.CurPos
		--debugoverlay.Box(curPos, Vector(-2, -2, -2), Vector(2, 2, 2), 1, Color(0, 255, 0))

		local newAmount = math.Round(distance)
		if newAmount < 1 then
			newAmount = 1
		end

		local dir = bullet.Dir

		local offset
		for i = 0, newAmount, BULLET_STEP_DISTANCE do

			offset = curPos + (dir * (distance / newAmount) * i) + (VectorRand() * 2.5)

			if offset:Distance(bullet.StartPos) >= bullet.Dist then
				continue
			end

			local inWater = bit.band(util.PointContents(offset), CONTENTS_WATER) ~= 0
			if inWater == false then
				continue
			end

			local p1 = bullet.Emitter:Add("effects/bubble", offset)
			if p1 ~= nil then
				p1:SetLifeTime(0.0)
				p1:SetDieTime(util.RandomFloat(0.75, 1.25))
				p1:SetRoll(0)
				p1:SetRollDelta(0)
				local col = util.RandomInt(128, 255)
				p1:SetColor(col, col, col)
				p1:SetStartAlpha(128)
				p1:SetEndAlpha(0)
				local size = util.RandomInt(1, 2)
				p1:SetStartSize(1)
				p1:SetEndSize(0)
				p1:SetVelocity( (dir * 64.0) + Vector(0, 0, 32) )
				p1:SetAirResistance(0.1)
				p1:SetNextThink(CurTime() + 0.01)
				p1.CurPos = p1:GetPos()
				p1:SetThinkFunction(function(bubble)
					-- Because the bubble effect does not affect the position
					-- this is based on the best result, its not precise but its close
					-- enough to not really notice
					local curPos = bubble.CurPos
					curPos = curPos + (bubble:GetVelocity() * FrameTime() * 40)
					bubble.CurPos = curPos
					local inWater = bit.band(util.PointContents(curPos), CONTENTS_WATER) ~= 0
					if inWater == false then
						bubble:SetDieTime(0)
						bubble:SetLifeTime(0)
					end
				end)
			end

			local p2 = bullet.Emitter:Add("effects/splash2", offset)
			if p2 ~= nil then
				p2:SetLifeTime(0.0)
				p2:SetDieTime(0.2)
				p2:SetRoll(util.RandomInt(0, 360))
				p2:SetRollDelta(util.RandomInt(-4, 4))

				local col = util.RandomInt(200, 255)

				p2:SetColor(col, col, col)
				p2:SetStartAlpha(80)
				p2:SetEndAlpha(0)
				local size = 1
				p2:SetStartSize(size)
				p2:SetEndSize(size * 4)
				p2:SetVelocity( (dir * 64.0)  )
			end

			--DbgPrint("Created particle: " .. tostring(p))

		end

	end

	function GM:BulletsThink()

		if self.SimulatingBullets == nil then
			return
		end

		local curTime = CurTime()

		for k,v in pairs(self.SimulatingBullets) do

			local timeDelta = FrameTime() --((1 / 33) * game.GetTimeScale()) * v.Decay
			local newPos = v.CurPos + ((v.Dir * BULLET_STEP_SIZE) * timeDelta)

			if newPos:Distance(v.StartPos) >= v.Dist then
				self.SimulatingBullets[k] = nil
				continue
			end

			local dist = newPos:Distance(v.CurPos)

			self:CreateWaterBulletParticles(v, newPos, dist)

			v.CurPos = newPos
			v.LastTime = curTime
			v.Decay = 1

			--debugoverlay.Box(newPos, Vector(-1, -1, -1), Vector(1, 1, 1), 1, Color(255, 255, 0))

			self.SimulatingBullets[k] = v

		end

	end

	function GM:AddWaterBullet(timestamp, startPos, endPos, ang, force)

		self.SimulatingBullets = self.SimulatingBullets or {}

		local curTime = CurTime()
		local dir = ang:Forward()
		local timeDelta = curTime - timestamp
		local pos = startPos + ((dir * BULLET_STEP_SIZE) * timeDelta)
		local dist = startPos:Distance(endPos)

		local bullet =
		{
			StartPos = startPos,
			EndPos = endPos,
			Dist = dist,
			Dir = dir,
			CurPos = startPos,
			Force = force,
			LastTime = curTime,
			Decay = 1,
			Emitter = ParticleEmitter(startPos, false),
		}

		--debugoverlay.Box(startPos, Vector(-2, -2, -2), Vector(2, 2, 2), 1, Color(0, 255, 0))

		table.insert(self.SimulatingBullets, bullet)

	end

	net.Receive("LambdaWaterBullet", function(len)

		local timestamp = net.ReadFloat()
		local startPos = net.ReadVector()
		local endPos = net.ReadVector()
		local ang = net.ReadAngle()
		local force = net.ReadFloat()

		GAMEMODE:AddWaterBullet(timestamp, startPos, endPos, ang, force)

	end)

end

function GM:HandleShotImpactingWater(ent, attacker, tr, dmginfo, data)

	DbgPrint("HandleShotImpactingWater")

	local waterTr = util.TraceLine({
		start = tr.StartPos,
		endpos = tr.HitPos,
		filter = { ent, attacker, dmginfo:GetInflictor() },
		mask = bit.bor(MASK_SHOT, CONTENTS_WATER, CONTENTS_SLIME)
	})

	local ang = (tr.HitPos - tr.StartPos):Angle()
	local fwd = ang:Forward()
	local startPos = waterTr.HitPos
	local endPos = tr.HitPos + (fwd * 400)

	local startedInWater = bit.band(util.PointContents(data.Src), CONTENTS_WATER) ~= 0
	if startedInWater == true then
		startPos = data.Src
	end

	--debugoverlay.Box(startPos, Vector(-2, -2, -2), Vector(2, 2, 2), 1, Color(0, 255, 0))
	--debugoverlay.Box(endPos, Vector(-2, -2, -2), Vector(2, 2, 2), 1, Color(255, 0, 0))

	local timestamp = CurTime()

	--print(dmginfo:GetDamageForce())
	ent.NextBulletCheck = ent.NextBulletCheck or timestamp
	if timestamp > ent.NextBulletCheck then
		--return
	end
	ent.NextBulletCheck = timestamp + 0.1

	if ent:IsPlayer() then
		if CLIENT then
			self:AddWaterBullet(timestamp, startPos, endPos, ang, 0)
		else
			local plys = {}
			for _,v in pairs(player.GetAll()) do
				-- TODO: Should we really just show it the person who is in water?, I couldn`t see them from above
				if v ~= ent and v:WaterLevel() == 3 then
					table.insert(plys, v)
				end
			end
			-- Everything else does not work.
			net.Start("LambdaWaterBullet")
			net.WriteFloat(timestamp)
			net.WriteVector(startPos)
			net.WriteVector(endPos)
			net.WriteAngle(ang)
			net.WriteFloat(dmginfo:GetDamageForce():Length())
			net.Send(plys)
		end
	else
		-- Everything else does not work.
		net.Start("LambdaWaterBullet")
		net.WriteFloat(timestamp)
		net.WriteVector(startPos)
		net.WriteVector(endPos)
		net.WriteAngle(ang)
		net.WriteFloat(dmginfo:GetDamageForce():Length())
		net.SendPVS(ent:GetPos())
	end

end

function GM:GetPlayerBulletSpread(ply)

	local wep = ply:GetActiveWeapon()
	if wep == nil then
		return Vector(0, 0, 0)
	end

	vel = ply:GetAbsVelocity()
	local velLen = vel:Length2D()

	return Vector(0.005, 0.005, 0.005) * ((velLen * 0.5) + 1)

end

function GM:EntityFireBullets(ent, data)

	local class
	local scale = false
	local wep

	if ent:IsPlayer() or ent:IsNPC() then

		if SERVER then
			self:RegisterBulletFired(ent, data.Num)
		end

		-- We have to assume its fired by the weapon.
		wep = ent:GetActiveWeapon()
		if IsValid(wep) then

			class = wep:GetClass()
			class = self.AITranslatedGameWeapons[class] or class

			local ammo = game.GetAmmoName(wep:GetPrimaryAmmoType())

			if self.GameWeapons[class] == true and data.AmmoType == ammo then
				scale = true
				--DbgPrint("Scaling recoil")
			end

			local vel = Vector(0, 0, 0)
			if ent:IsPlayer() then

				local primaryAmmo = ent:GetAmmoCount(wep:GetPrimaryAmmoType())
				local secondaryAmmo = ent:GetAmmoCount(wep:GetSecondaryAmmoType())
				local clip1 = wep:Clip1()
				local clip2 = wep:Clip2()

				-- Treat as empty.
				if clip2 == -1 then clip2 = 0 end

				if primaryAmmo == 0 and secondaryAmmo == 0 and clip1 == 0 and clip2 == 0 and IsFirstTimePredicted() then
					self:OnPlayerAmmoDepleted(ent, wep)
				end

				vel = ent:GetAbsVelocity()
			elseif ent:IsNPC() then

				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					vel = phys:GetVelocity()
				end

			end

			local velLen = vel:Length2D()
			velLen = math.Clamp(velLen, 0, 380)

			local spread = data.Spread
			if velLen > 50 then
				spread = spread * (velLen * 0.0035)
			else
				spread = spread * 0.3
			end
			data.Spread = spread

		end

	end

	-- We will add a callback to handle water bullets.
	local prevCallback = data.Callback
	local self = self
	local ent = ent
	local newData = { Dir = data.Dir, Src = data.Src }

	data.Callback = function(attacker, tr, dmginfo)

		local pointContents = util.PointContents(tr.HitPos)

		if bit.band(pointContents, bit.bor(CONTENTS_WATER, CONTENTS_SLIME)) ~= 0 or bit.band(util.PointContents(newData.Src), CONTENTS_WATER) ~= 0 then
			if IsFirstTimePredicted() then
				-- Only call this once clientside, causes weird effects otherwise
				hook.Call("HandleShotImpactingWater", self, ent, attacker, tr, dmginfo, newData)
			end
		end

		if prevCallback ~= nil then
			prevCallback(attacker, tr, dmginfo)
		end

	end

	return true

end
