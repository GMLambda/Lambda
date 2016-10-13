if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("LambdaPlayerEnableRespawn")
end

local DbgPrint = GetLogging("Player")

DEFINE_BASECLASS( "gamemode_base" )

local SUIT_DEVICE_BREATHER = 1
local SUIT_DEVICE_SPRINT = 2
local SUIT_DEVICE_FLASHLIGHT = 3

local sv_infinite_aux_power = GetConVar("sv_infinite_aux_power")

if SERVER then

	function GM:CanPlayerSuicide(ply)

		if ply:Alive() == false then
			return false
		end

		if ply:IsPositionLocked() then
			return false
		end

		return true

	end

	function GM:PlayerDisconnected(ply)

		if ply.LambdaPlayerData then
			--PLAYER_ROLES_TAKEN[ply.LambdaPlayerData.Id] = nil
		else
			DbgPrint("Disconnected without LambdaPlayerData assigned, bug?")
		end

		if IsValid(ply.TrackerEntity) then
			ply.TrackerEntity:Remove()
		end

	    return BaseClass.PlayerDisconnected(self, ply)

	end

	function GM:SetPlayerCheckpoint(checkpoint)
		DbgPrint("Assigned new checkpoint to: " .. tostring(checkpoint))
		self.CurrentCheckpoint = checkpoint
	end

	function GM:SetupPlayerVisibility(ply, viewEnt)

	end

	function GM:PlayerInitialSpawn(ply)

	    DbgPrint("GM:PlayerInitialSpawn")

		self:HandlePlayerConnect(ply:SteamID(), ply:Nick(), ply:EntIndex(), ply:IsBot(), ply:UserID())
	    self:IncludePlayerInRound(ply)

		local model = "models/player/riot.mdl"
		local name = "!player" -- Some stuff will fail if this is not set, not everything is ported.
		local gender = "male"

		local hash = tonumber(util.CRC(ply:SteamID64() or "LOCALPLAYER"))
		math.randomseed(hash * 4) -- * 4 because im special! :v

		-- We pick something random.
		local genders = { "male", "female" }
		gender = genders[math.random(1, #genders)]

		local index = "0" .. tostring(math.random(1, 5))

		model = gender .. "_" .. index .. ".mdl"
		name = "!player"

		ply.LambdaPlayerData =
		{
			Gender = gender,
			Name = name,
			Model = model,
		}

		local transitionData = self:GetPlayerTransitionData(ply)
		if transitionData ~= nil then
			ply:SetFrags(transitionData.Frags)
			ply:SetDeaths(transitionData.Deaths)
		end

		DbgPrint("Gender: " .. gender)
		DbgPrint("Model: " .. model)
		DbgPrint("Unique: " .. tostring(unique))

		ply:SetNWString("Gender", gender)
		ply:SetName(name) -- Some thing are triggered between PlayerInitialSpawn and PlayerSpawn
		ply:SetInactive(true)

		BaseClass.PlayerInitialSpawn( self, ply )

	end

	function GM:PlayerSelectSpawn(ply)

		DbgPrint("PlayerSelectSpawn")

		-- Check if players reached a checkpoint.
		if self.CurrentCheckpoint ~= nil and IsValid(self.CurrentCheckpoint) then
			return self.CurrentCheckpoint
		end

		local spawnpoints = ents.FindByClass("info_player_start")
		local spawnpoint = nil

		for _,v in pairs(spawnpoints) do

			-- Initial spawnpoint if none set.
			spawnpoint = spawnpoint or v

			-- If set by us then this is the absolute.
			if v.MasterSpawn == true then
				DbgPrint("Spawn using MasterSpawn variable: " .. tostring(v))
				spawnpoint = v
				break
			end

			-- If master flag is set it has priority.
			if v:HasSpawnFlags(1) then
				spawnpoint = v
			end

		end

		DbgPrint("Select spawnpoint for player: " .. tostring(ply) .. ", spawn: " .. tostring(spawnpoint))

		return spawnpoint

	end

	function GM:PlayerSetModel(ply)

		DbgPrint("GM:PlayerSetModel")

		local mdl = "models/player"
		if ply:IsSuitEquipped() then
			mdl = mdl .. "/group03/" .. ply.LambdaPlayerData.Model
		else
		    mdl = mdl .. "/group01/" .. ply.LambdaPlayerData.Model
		end

		ply:SetModel(mdl)

	end

	function GM:PlayerLoadout(ply)

		DbgPrint("PlayerLoadout: " .. tostring(ply))

		ply.LambdaDisablePickupDuplication = true

		local transitionData = ply.TransitionData
		if transitionData ~= nil and transitionData.Include == true then

			for _,v in pairs(ply.TransitionData.Weapons) do
				ply:Give(v.Class)
				ply:SetAmmo(v.Ammo1.Count, v.Ammo1.Id)
				ply:SetAmmo(v.Ammo2.Count, v.Ammo2.Id)
				if v.Active then
					ply.ScheduledActiveWeapon = v.Class
				end
			end

			ply:SetHealth(ply.TransitionData.Health)
			ply:SetArmor(ply.TransitionData.Armor)

			if ply.TransitionData.Suit then
				ply:EquipSuit()
			else
				ply:RemoveSuit()
			end

		else
			-- Weapons
			for k,v in pairs(self.MapScript.DefaultLoadout.Weapons) do
				ply:Give(v)
			end

			-- Ammo
			for k,v in pairs(self.MapScript.DefaultLoadout.Ammo) do
				ply:GiveAmmo(v, k, true)
			end

			-- Armor
			ply:SetArmor(self.MapScript.DefaultLoadout.Armor)

			-- HEV
			if self.MapScript.DefaultLoadout.HEV then
				ply:EquipSuit()
			else
				ply:RemoveSuit()
			end

		end

		ply.LambdaDisablePickupDuplication = false

	end

	function GM:PlayerSpawn(ply)

		DbgPrint("GM:PlayerSpawn")

	    if self.WaitingForRoundStart == true or self:IsRoundRestarting() == true then
	        ply:KillSilent()
	        return
	    end

		ply:EndSpectator()

		net.Start("LambdaPlayerEnableRespawn")
		net.WriteUInt(ply:EntIndex(), 8)
		net.WriteBool(false)
		net.Send(ply)

		-- Ensure we keep it.
		local ply = ply

		if not IsValid(ply.TrackerEntity) then
			ply.TrackerEntity = ents.Create("lambda_player_tracker")
		end

		-- Lets remove whatever the player left on vehicles behind before he got killed.
		self:RemovePlayerVehicles(ply)

		-- We call this first in order to call PlayerLoadout, once we enter a vehicle we can not
		-- get any weapons.
		BaseClass.PlayerSpawn(self, ply)

		if self.MapScript.PrePlayerSpawn ~= nil then
			self.MapScript:PrePlayerSpawn(ply)
		end

		ply.LambdaSpawnTime = CurTime()

		-- Should we really do this?
		ply:SetName(ply.LambdaPlayerData.Name)
		ply:SetupHands()
		ply:SetTeam(LAMBDA_TEAM_ALIVE)
		ply:SetShouldServerRagdoll(false)
		ply:SetCustomCollisionCheck(true)

		ply:SetSuitPower(100)
		ply:SetSuitEnergy(100)
		ply:SetGeigerRange(1000)
		ply:SetStateSprinting(false)
		ply:SetSprinting(false)
		ply:SetDuckSpeed(0.4)
		ply:SetUnDuckSpeed(0.2)
		ply:SetInactive(true)

		ply:SetRunSpeed(lambda_sprintspeed:GetInt()) -- TODO: Put this in a convar.
		ply:SetWalkSpeed(lambda_normspeed:GetInt())

		local transitionData = ply.TransitionData

		if transitionData ~= nil then

			-- We keep those.
			ply:SetFrags(transitionData.Frags)
			ply:SetDeaths(transitionData.Deaths)

			if transitionData.Include == true then
				DbgPrint("Player " .. tostring(ply) .. " uses transition data!")
				ply:SetPos(transitionData.Pos)
				ply:SetAngles(transitionData.Ang)
				ply:SetEyeAngles(transitionData.EyeAng)
			end

			if transitionData.Vehicle ~= nil and transitionData.Include == true then

				local vehicle = self:FindEntityByTransitionReference(transitionData.Vehicle)
				if IsValid(vehicle) then
					DbgPrint("Putting player " .. tostring(ply) .. " back in vehicle: " .. tostring(vehicle))

					-- Sometimes does crazy things to the view angles, this only helps to a certain amount.
					vehicle:SetVehicleEntryAnim(false)
					vehicle.ResetVehicleEntryAnim = true

					local eyeAng = vehicle:WorldToLocalAngles(transitionData.EyeAng)

					-- NOTE: Workaround as they seem to not get any weapons if we enter the vehicle this frame.
					util.RunNextFrame(function()
						if IsValid(ply) and IsValid(vehicle) then
							ply:SetPos(vehicle:GetPos())
							ply:EnterVehicle(vehicle)
							ply:SetEyeAngles(eyeAng) -- We call it again because the vehicle sets it to how you entered.
						end
					end)

				else
					DbgPrint("Unable to find player " .. tostring(ply) .. " vehicle: " .. tostring(transitionData.Vehicle))
				end
			end

		end

		if SERVER then
			if ply.ScheduledActiveWeapon ~= nil then
				ply:SelectWeapon(ply.ScheduledActiveWeapon)
				ply.ScheduledActiveWeapon = nil
			else
				self:SelectBestWeapon(ply)
			end
		end

		util.RunNextFrame(function()
			if SERVER then
				self:CheckPlayerNotStuck(ply)
			end
			if self.MapScript.PostPlayerSpawn ~= nil then
				self.MapScript:PostPlayerSpawn(ply)
			end
		end)

		ply.TransitionData = nil -- Make sure we erase it because this only happens on a new round.

		-- Adjust difficulty, we want later some dynamic system that adjusts depending on the players.
		self:AdjustDifficulty()

		ply.TrackerEntity:AttachToPlayer(ply)

	end

	function GM:CheckPlayerNotStuck(ply)

		-- Thats all there is to it, hopefully.
		if ply:InVehicle() then
			return
		end

		util.PlayerUnstuck(ply)

	end

	function GM:DoPlayerDeath(ply, attacker, dmg)

		if ply.LastWeaponsDropped ~= nil then
			for _,v in pairs(ply.LastWeaponsDropped) do
				if IsValid(v) and v:GetOwner() ~= ply then
					v:Remove()
				end
			end
		end

		local weps = ply:GetWeapons()
		local activeWep = ply:GetActiveWeapon()
		if IsValid(activeWep) then
			table.insert(weps, activeWep)
		end

		ply.LastWeaponsDropped = {}
		for _,v in pairs(weps) do

			local ammoType1 = v:GetPrimaryAmmoType()
			local ammoType2 = v:GetSecondaryAmmoType()

			-- Only drop relevant stuff, except the crowbar.
			if ply:GetAmmoCount(ammoType1) == 0 and ply:GetAmmoCount(ammoType2) == 0 and v:GetClass() ~= "weapon_crowbar" then
				continue
			end

			ply:DropWeapon(v)

			v.PreventDuplication = true

			if v:GetClass() == "weapon_crowbar" then
				-- Damage players if it gets thrown their way
				v:SetSolidFlags(FSOLID_CUSTOMBOXTEST)
				v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
			end

			table.insert(ply.LastWeaponsDropped, v)
		end

		local createRagdoll = true

		-- Because the weapons are attached to the player at the time the explosion happened they did
		-- not receive the force, we gonna apply it so things go flying.
		if dmg:IsExplosionDamage() then

			local dmgPos = dmg:GetDamagePosition()

			local force = dmg:GetDamageForce() * 0.05

			for _,v in ipairs(ply.LastWeaponsDropped) do
				local phys = v:GetPhysicsObject()
				if IsValid(phys) then
					phys:AddVelocity(force * Vector(math.random(-10, 10), math.random(-10, 10), 1))
				end
			end

			--[[
			-- Removed for now, actually working on getting the gibs models.
			if ply:GetPos():Distance(dmgPos) < 128 and dmg:GetDamageForce():Length() > 256 then
				createRagdoll = false
				self:CreatePlayerGibs(ply, force)
			end
			]]

		end

		if createRagdoll == true then
			ply:CreateRagdoll()
		end

		ply:AddDeaths( 1 )

		if attacker:IsValid() and attacker:IsPlayer() then

			if attacker == ply then
				attacker:AddFrags( -1 )
			else
				attacker:AddFrags( 1 )
			end

		end

	end

	function GM:PlayerDeath(victim, attacker, inflictor)

		local effectdata = EffectData()
			effectdata:SetOrigin( victim:GetPos() )
			effectdata:SetNormal( Vector(0,0,1) )
			effectdata:SetRadius(50)
			effectdata:SetEntity(victim)
		util.Effect( "lambda_death", effectdata, true )

		self:RegisterPlayerDeath(victim, attacker, inflictor)

		BaseClass.PlayerDeath(self, victim, attacker, inflictor)

	end

	function GM:PostPlayerDeath(ply)

	    DbgPrint("GM:PostPlayerDeath")

	    ply.DeathTime = GetSyncedTimestamp()
		ply:SetTeam(LAMBDA_TEAM_DEAD)
		ply:LockPosition(false, false)

		local timeout = math.Clamp(lambda_max_respawn_timeout:GetInt(), 1, 255)
		local alive = #team.GetPlayers(LAMBDA_TEAM_ALIVE)
		local total = #player.GetAll()
		local timeoutAmount = math.Round(alive / total * timeout)

		ply.RespawnTime = ply.DeathTime + timeoutAmount

		if self:IsRoundRestarting() == false and alive > 0 then
			net.Start("LambdaPlayerEnableRespawn")
			net.WriteUInt(ply:EntIndex(), 8)
			net.WriteBool(true)
			net.WriteFloat(ply.DeathTime)
			net.WriteUInt(timeoutAmount, 8)
			net.Send(ply)
		end

	end

	function GM:PlayerDeathThink(ply)

	    --DbgPrint("GM:PlayerDeathThink")

		if self:IsRoundRestarting() then
	        --DbgPrint("Round is restarting")
			return false
		end

	    if self.WaitingForRoundStart == true or self:IsRoundRestarting() == true then
	        --DbgPrint("Can not spawn before players available")
	        return false
	    end

		local elapsed = GetSyncedTimestamp() - ply.DeathTime

		if elapsed >= 5 and ply:IsSpectator() == false then
			ply:SetSpectator()
		end

	    if GetSyncedTimestamp() < ply.RespawnTime then
	        return false
	    end

	    if ply:KeyReleased(IN_JUMP) then
	        ply:Spawn()
	    end

		return true

	end

	function GM:PlayerSwitchFlashlight(ply, enabled)

		if not ply:IsSuitEquipped() then
			return false
		end

		return true

	end

	function GM:Move(ply, mv)

		-- Whoever stumbles upon this code might ask what this is all about.
		--
		-- Its best shown by going to d1_town_01 to the part where you have to lift up the
		-- vehicles, you have to walk on them and them and jump off which is close to impossible
		-- without the code below, feel free to comment it in order to see the difference.
		local groundEnt = ply:GetGroundEntity()

		if mv:KeyDown(IN_JUMP) and groundEnt ~= NULL and IsValid(groundEnt) then
			local class = groundEnt:GetClass()
			if class == "prop_physics" or class == "func_physbox" then
				local phys = groundEnt:GetPhysicsObject()
				if IsValid(phys) and phys:IsMotionEnabled() == true then
					local currentVel = phys:GetVelocity()
					phys:EnableMotion(false)
					-- Enable it back next frame
					util.RunNextFrame(function()
						if IsValid(groundEnt) then
							local phys = groundEnt:GetPhysicsObject()
							if IsValid(phys) then
								phys:EnableMotion(true)
								phys:SetVelocity(currentVel)
							end
						end
					end)
				end
			end
		end

	end

	function GM:LimitPlayerAmmo(ply)

		local curTime = CurTime()

		ply.LastAmmoCheck = ply.LastAmmoCheck or curTime

		if curTime - ply.LastAmmoCheck < 0.100 then
			return
		end

		ply.LastAmmoCheck = curTime

		for k,v in pairs(self.MAX_AMMO_DEF) do
			local count = ply:GetAmmoCount(k)
			local maxCount = v:GetInt()
			if count > maxCount then
				ply:SetAmmo(maxCount, k)
			end
		end

	end

	function GM:AllowPlayerPickup( ply, ent )

		ply.LastPickupTime = ply.LastPickupTime or 0

		local pickupDelay = lambda_pickup_delay:GetFloat()
		local curTime = CurTime()
		if curTime - ply.LastPickupTime < pickupDelay then
			return false
		end

		ply.LastPickupTime = curTime

		return true

	end

	function GM:PlayerCanPickupItem(ply, item)

		if ply.LambdaDisablePickupDuplication == true then
			return true
		end

		-- Maps have the annoying template spawner for all weapons so give it a slight chance to pick it up
		-- those items arent usually cleaned up so let the player have it, for now..
		if CurTime() - ply.LambdaSpawnTime <= 1 then
			return true
		end

		local class = item:GetClass()
		local res = true

		-- Dont pickup stuff if we dont need it.
	    if class == "item_health" or class == "item_healthvial" or class == "item_healthkit" then
			if ply:Health() >= ply:GetMaxHealth() then
				return false
			end
		elseif class == "item_battery" then
			if ply:Armor() >= 100 then
				return false
			end
		elseif class == "item_suit" then
			if ply:IsSuitEquipped() == true then
				return false
			else
				return true
			end
		end

		-- Limit the ammo to pickup based on the sk convars.
		local skill = tostring(game.GetSkillLevel())

		local ammo = self.ITEM_DEF[class]
		if ammo then
			local cur = ply:GetAmmoCount(ammo.Type)
			local amount = ammo[skill]
			local max = ammo.Max:GetInt()
			if cur + amount > max then
				--DbgPrint("Limited ammo pickup: " .. tostring(item))
				res = false
			end
		end

		return res

	end

	function GM:WeaponEquip(wep)

		local wep = wep

	    util.RunNextFrame(function()
			if not IsValid(wep) then
				return
			end

			local ply = wep:GetOwner()
			if IsValid(ply) then

				if wep.CreatedForPlayer == ply then
					ply.WeaponDuplication[wep.OriginalWeapon] = nil
				end
				if ply.LastDuplicatedWeapon == wep then
					ply:SelectWeapon(wep:GetClass())
				end

				for k,v in pairs(wep.EntityOutputs or {}) do
					util.SimpleTriggerOutputs(v, ply, ply, wep )
				end

				ply:EmitSound("Player.PickupWeapon")
			end
		end)

	end

	function GM:PlayerCanPickupWeapon(ply, wep)

		--DbgPrint("PlayerCanPickupWeapon", ply, wep)

		if ply.LambdaDisablePickupDuplication == true then
			return true
		end

		local class = wep:GetClass()

		if class == "weapon_frag" then
			if ply:GetAmmoCount("grenade") < sk_max_grenade:GetInt() then
				return true
			end
		elseif class == "weapon_annabelle" then
			return false -- Not supposed to have this.
		end

		-- Maps have the annoying template spawner for all weapons so give it a slight chance to pick it up
		-- those items arent usually cleaned up so let the player have it, for now..
		if CurTime() - ply.LambdaSpawnTime <= 2 then
			return true
		end

		if ply:HasWeapon(wep:GetClass()) then

			local clip1 = wep:Clip1()
			if clip1 > 5 then
				local rest = clip1 - 5
				ply:GiveAmmo(rest, wep:GetPrimaryAmmoType(), false)
				wep:SetClip1(5)
			end

			return false

		end

		if wep.PreventDuplication == true then
			return true
		end

		ply.WeaponDuplication = ply.WeaponDuplication or {}

		if ply.WeaponDuplication[wep] == true then
			--DbgPrint("Already duplicating this weapon")
			return false
		end

		if wep.CreatedForPlayer ~= nil then
			if wep.CreatedForPlayer == ply then
				-- This was specifically created for the player, allow it.
				--DbgPrint("Allowing to pickup")
				return true
			else
				-- Lets not duplicate a duplicate
				return false
			end
		end

		DbgPrint("Duplicating new player weapon")

		ply.WeaponDuplication[wep] = true

		local copy = ents.Create(class)
		copy:SetPos(wep:GetPos())
		copy:SetAngles(wep:GetAngles())
		copy:SetClip1(wep:Clip1())
		copy:SetClip2(wep:Clip2())
		copy:SetName(wep:GetName())
		copy.CreatedForPlayer = ply
		copy.OriginalWeapon = wep
		-- Copy the outputs, some of the maps use them to trigger events.
		copy.EntityOutputs = table.Copy(wep.EntityOutputs or {})
		copy:Spawn()

		-- Only ever select the last duplicated weapon.
		ply.LastDuplicatedWeapon = copy

		return false

	end

	local sk_player_head = GetConVar("sk_player_head")
	local sk_player_chest = GetConVar("sk_player_chest")
	local sk_player_stomach = GetConVar("sk_player_stomach")
	local sk_player_arm = GetConVar("sk_player_arm")
	local sk_player_leg = GetConVar("sk_player_leg")

	local HITGROUP_SCALE =
	{
		[HITGROUP_GENERIC] = function() return 1.0 end,
		[HITGROUP_HEAD] = function() return sk_player_head:GetFloat() end,
		[HITGROUP_CHEST] = function() return sk_player_chest:GetFloat() end,
		[HITGROUP_STOMACH] = function() return sk_player_stomach:GetFloat() end,
		[HITGROUP_LEFTARM] = function() return sk_player_arm:GetFloat() end,
		[HITGROUP_RIGHTARM] = function() return sk_player_arm:GetFloat() end,
		[HITGROUP_LEFTLEG] = function() return sk_player_leg:GetFloat() end,
		[HITGROUP_RIGHTLEG] = function() return sk_player_leg:GetFloat() end,
	}

	function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)

		DbgPrint("ScalePlayerDamage", ply, hitgroup)

		self:ApplyCorrectedDamage(dmginfo)

		local hitgroupScale = HITGROUP_SCALE[hitgroup] or function() return 1.0 end

		if hitgroup == HITGROUP_GEAR then
			dmginfo:SetDamage(0.1)
			return
		else
			local scale = hitgroupScale()
			--DbgPrint("Scaling damage with: " .. scale)
			dmginfo:ScaleDamage( scale )
		end

		if dmginfo:IsDamageType(DMG_BLAST) then
			dmginfo:ScaleDamage( 2 )
		end

		if dmginfo:GetDamage() > 0 then
			--DbgPrint("ScalePlayerDamage: " .. tostring(ply))
			self:EmitPlayerHurt(dmginfo:GetDamage(), ply, hitgroup)
		end

		-- Reset water damage
		if ply.IsDrowning ~= true then
			ply.WaterDamage = 0
		end

		if ply:IsPositionLocked() == true then
			dmginfo:ScaleDamage(0)
		end

	end

	function GM:GetFallDamage( ply, speed )
		speed = speed - 480
		return speed * (100 / (1024-480))
	end

	function GM:EmitPlayerHurt(amount, ply, hitgroup)

		if ply:WaterLevel() == 3 then
			return
		end

		if ply:Health() - amount <= 0 then
			-- Dead people dont say stuff
			return
		end

		if hitgroup == nil or hitgroup == HITGROUP_HEAD or hitgroup == HITGROUP_GEAR then
			hitgroup = HITGROUP_GENERIC
		end

		local gender = ply.LambdaPlayerData.Gender
		local hurtsounds = self.HurtSounds[gender][hitgroup]

		ply.NextHurtSound = ply.NextHurtSound or 0

		local curTime = CurTime()
		if curTime - ply.NextHurtSound >= 2 then
			local snd = table.Random(hurtsounds)
			ply:EmitSound(snd)
			ply.NextHurtSound = curTime + 2
		end

	end


else -- CLIENT

	function GM:CalcView( ply, pos, angles, fov )

		local view = {}

		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		return view

	end

	function GM:NotifyPlayerRespawn(state, entIndex, deathTime, timeout)

		local localPly = LocalPlayer()
		if Entity(entIndex) == localPly then
			GAMEMODE:EnableRespawnHUD(state, deathTime, timeout)
		end

	end

	net.Receive("LambdaPlayerEnableRespawn", function(len)

		local entIndex = net.ReadUInt(8)
		local state = net.ReadBool()
		local deathTime = 0
		local timeout = 0

		if state == true then
			deathTime = net.ReadFloat()
			timeout = net.ReadUInt(8)
		end

		GAMEMODE:NotifyPlayerRespawn(state, entIndex, deathTime, timeout)

	end)

end

local GEIGER_DELAY = 0.25
local GEIGER_SOUND_DELAY = 0.06

function GM:UpdateGeigerCounter(ply)

	local curTime = CurTime()

	if SERVER then

		ply.GeigerDelay = ply.GeigerDelay or curTime

		if curTime < ply.GeigerDelay then
			return
		end

		ply.GeigerDelay = curTime + GEIGER_DELAY

		local range = math.Clamp(math.floor(ply:GetNearestRadiationRange() / 4), 0, 255)

		if ply:InVehicle() then
			range = math.Clamp(range * 4, 0, 1000)
		end

		if math.random(0, 5) == 0 then
			ply:SetGeigerRange(1000)
			ply:SetNearestRadiationRange(1000, true)
		else
			ply:SetGeigerRange(range)
		end

	else

		if ply:Alive() == false or ply ~= LocalPlayer() then
			return
		end

		ply.GeigerSoundDelay = ply.GeigerSoundDelay or curTime

		if curTime < ply.GeigerSoundDelay then
			return
		end

		ply.GeigerSoundDelay = curTime + GEIGER_SOUND_DELAY

		local range = ply:GetGeigerRange() * 4
		--DbgPrint(range)
		if range == 0 or range >= 1000 then
			return
		end

		local pct = 0
		local vol = 0
		local highSnd = false

		if range > 800 then
			pct = 0
		elseif range > 600 then
			pct = 2
			vol = 0.2
		elseif range > 500 then
			pct = 4
			vol = 0.25
		elseif range > 400 then
			pct = 8
			vol = 0.3
			highSnd = true
		elseif range > 300 then
			pct = 8
			vol = 0.35
			highSnd = true
		elseif range > 200 then
			pct = 28
			vol = 0.39
			highSnd = true
		elseif range > 150 then
			pct = 40
			vol = 0.40
			highSnd = true
		elseif range > 100 then
			pct = 60
			vol = 0.45
			highSnd = true
		elseif range > 75 then
			pct = 80
			vol = 0.45
			highSnd = true
		elseif range > 50 then
			pct = 90
			vol = 0.475
		else
			pct = 95
			vol = 0.5
		end

		vol = (vol * (math.random(0, 127) / 255)) + 0.25

		if math.random(0, 127) < pct then
			local snd
			if highSnd then
				snd = "Geiger.BeepHigh"
			else
				snd = "Geiger.BeepLow"
			end
			--DbgPrint("EMITSOUND")
			ply:EmitSound(snd, 75, 100, vol, CHAN_BODY)

		end

	end

end

local SUIT_SPRINT_DRAIN = 20.0
local SUIT_FLASHLIGHT_DRAIN = 2.222
local SUIT_BREATH_DRAIN = 6.7
local SUIT_CHARGE_RATE = 12.5
local SUIT_CHARGE_DELAY = 1.5
local SUIT_ENERGY_CHARGE_RATE = 12.5

function GM:PlayerAllowSprinting(ply, inSprint)

	inSprint = inSprint or false

	if ply:IsSuitEquipped() == false then
		return false
	end

	if ply:WaterLevel() > 1 then
		return false
	end

	if ply:InVehicle() == true then
		return false
	end

	if ply:KeyDown(IN_DUCK) then
		return false
	end

	if ply:GetSuitPower() <= 0 then
		return false
	end

	return true

end

function GM:PlayerStartSprinting(ply, mv)

	--DbgPrint("PlayerStartSprinting: " .. tostring(ply))

	ply:AddSuitDevice(SUIT_DEVICE_SPRINT)

	if CLIENT and IsFirstTimePredicted() then
		local suitPower = ply:GetSuitPower()
		if suitPower <= 0 then
			ply:EmitSound("HL2Player.SprintNoPower")
			return false
		else
			ply:EmitSound("HL2Player.SprintStart")
		end
	end

	ply:SetRunSpeed(lambda_sprintspeed:GetInt()) -- TODO: Put this in a convar.
	ply:SetWalkSpeed(lambda_normspeed:GetInt())
	ply:SetSprinting(true)

	--DbgPrint("Sprint State: " .. tostring(ply:GetSprinting()))

end

function GM:PlayerEndSprinting(ply, mv)

	--DbgPrint("PlayerEndSprinting: " .. tostring(ply) )

	ply:RemoveSuitDevice(SUIT_DEVICE_SPRINT)
	ply:SetRunSpeed(lambda_normspeed:GetInt()) -- TODO: Put this in a convar.
	ply:SetWalkSpeed(lambda_normspeed:GetInt())
	ply:SetSprinting(false)

end

function GM:StartCommand(ply, cmd)

	--DbgPrint("StartCommand", ply)

	if ply:IsPositionLocked() == true then
		local vel = ply:GetVelocity()
		vel.x = 0
		vel.y = 0
		vel.z = math.Clamp(vel.z, -2, 0)
		ply:SetVelocity(vel)
		cmd:ClearButtons()
		cmd:ClearMovement()
		return
	end

	if cmd:KeyDown(IN_SPEED) == true and (ply:IsSuitEquipped() ~= true or ply:WaterLevel() >= 1) and ply:InVehicle() == false then
		cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_SPEED)))
	end

	if cmd:KeyDown(IN_DUCK) then
		ply:SetNW2Bool("InDuck", true)
	else
		ply:SetNW2Bool("InDuck", false)
	end

end

function GM:SetupMove(ply, mv, cmd)

	--if not IsFirstTimePredicted() then return end
	if ply:Alive() == false then
		return
	end

	local isSprinting = false
	if ply.GetSprinting ~= nil then
		isSprinting = ply:GetSprinting()
	end

	if mv:KeyDown(IN_DUCK) and ply:IsOnGround() and isSprinting == true then

		self:PlayerEndSprinting(ply, mv)
		ply:SetStateSprinting(false)

	end

	if mv:KeyDown(IN_SPEED) == true then

		--DbgPrint("Is Sprinting: " .. tostring(isSprinting))

		if self:PlayerAllowSprinting(ply) == true and
			isSprinting == false and
			ply:GetStateSprinting() == false and
			self:PlayerStartSprinting(ply, mv) ~= false
		then
			ply:SetStateSprinting(true)
		end

	else

		if isSprinting == true then
			--DbgPrint("IN_SPEED missing, stopped sprinting " .. tostring(isSprinting))
			self:PlayerEndSprinting(ply, mv, cmd)
		end

		ply:SetStateSprinting(false)

	end

end

function GM:FinishMove(ply, mv)

	if (mv:GetButtons() ~= 0 or ply:IsBot()) and ply:GetLifeTime() > 0.1 and ply:IsInactive() == true then
		DbgPrint(ply, "Player now active")
		ply:SetInactive(false)
	end

end

function GM:DrainSuit(ply, amount)

	local current = ply:GetSuitPower()
	local res = true

	if ply:GetMoveType() == MOVETYPE_NOCLIP then
		-- Dont do anything in this case
		return true
	end

	if sv_infinite_aux_power:GetBool() == true then
		amount = 0
	end

	current = current - amount

	if current < 0 then
		current = 0
		res = false
	end

	ply:SetSuitPower(current)

	return res

end

function GM:ChargeSuitPower(ply, amount)

	local current = ply:GetSuitPower()

	current = current + amount
	if current > 100.0 then
		current = 100.0
	end

	ply:SetSuitPower(current)
	ply:RemoveSuitDevice(SUIT_DEVICE_BREATHER)
	ply:RemoveSuitDevice(SUIT_DEVICE_SPRINT)

end

function GM:ShouldChargeSuitPower(ply)

	--local flashlight = ply:FlashlightIsOn() -- Its just annoying.
	local sprinting = ply:GetSprinting()
	local inWater = ply:WaterLevel() >= 3
	local powerDrain = sprinting or inWater

	if powerDrain == true then
		return false -- Something is draning power.
	end

	local power = ply:GetSuitPower()
	if power >= 100.0 then
		return false -- Full
	end

	local curTime = CurTime()
	ply.NextSuitCharge = ply.NextSuitCharge or curTime

	if curTime < ply.NextSuitCharge then
		return false
	end

	--DbgPrint("Should Charge")
	return true

end

function GM:UpdateSuit(ply, mv)

	if ply:IsSuitEquipped() == false then
		return
	end

	local frameTime = FrameTime()
	local currentEnergy = ply:GetSuitEnergy()

	if ply:FlashlightIsOn() then
		--powerLoad = powerLoad + SUIT_FLASHLIGHT_DRAIN
		ply:AddSuitDevice(SUIT_DEVICE_FLASHLIGHT)
		currentEnergy = currentEnergy - (SUIT_FLASHLIGHT_DRAIN * frameTime)
		if currentEnergy <= 0 then
			if SERVER then
				ply:Flashlight(false)
			end
			ply:RemoveSuitDevice(SUIT_DEVICE_FLASHLIGHT)
		end
	else
		currentEnergy = currentEnergy + (SUIT_ENERGY_CHARGE_RATE * frameTime)
		ply:RemoveSuitDevice(SUIT_DEVICE_FLASHLIGHT)
	end

	ply:SetSuitEnergy(currentEnergy)

	-- Check if we should recharge.
	if self:ShouldChargeSuitPower(ply) == true then

		local amount = SUIT_CHARGE_RATE * frameTime
		self:ChargeSuitPower(ply, amount)

	else

		local powerLoad = 0

		if ply:GetSprinting() then
			local pos = ply:GetAbsVelocity()
			if math.abs(pos.x) > 0 or math.abs(pos.y) > 0 then
				powerLoad = powerLoad + SUIT_SPRINT_DRAIN
			end
		end

		if ply:WaterLevel() >= 3 then
			powerLoad = powerLoad + SUIT_BREATH_DRAIN
			ply:AddSuitDevice(SUIT_DEVICE_BREATHER)
		else
			ply:RemoveSuitDevice(SUIT_DEVICE_BREATHER)
		end

		if powerLoad > 0 and self:DrainSuit(ply, powerLoad * frameTime) == false then
			ply.NextSuitCharge = CurTime() + SUIT_CHARGE_DELAY
			if ply:GetSprinting() == true then
				self:PlayerEndSprinting(ply, mv)
			end
		end

	end

end

local CHOKE_TIME = 1
local WATER_HEALTH_RECHARGE_TIME = 3

function GM:PlayerCheckDrowning(ply)

	if not ply:Alive() or not ply:IsSuitEquipped() then
		return
	end

	ply.WaterDamage = ply.WaterDamage or 0

	local curTime = CurTime()

	if ply:WaterLevel() ~= 3 then

		if ply.IsDrowning == true then
			ply.IsDrowning = false
		end

		if ply.WaterDamage > 0 then

			ply.NextWaterHealthTime = ply.NextWaterHealthTime or curTime + WATER_HEALTH_RECHARGE_TIME

			if ply:Health() >= 100 then
				ply.WaterDamage = 0
			else
				if ply.NextWaterHealthTime < curTime then

					ply.WaterDamage = ply.WaterDamage - 10
					if ply:Health() + 10 > 100 then
						ply:SetHealth(100)
					else
						ply:SetHealth(ply:Health() + 10)
					end

					ply.NextWaterHealthTime = curTime + WATER_HEALTH_RECHARGE_TIME
				end

			end

		end

	else

		ply.NextChokeTime = ply.NextChokeTime or curTime + CHOKE_TIME

		if ply:GetSuitPower() == 0 and curTime > ply.NextChokeTime then

			if ply.IsDrowning ~= true then
				ply.IsDrowning = true
				ply.DrowningStartTime = CurTime()
				ply.WaterDamage = 0
			end

			local dmgInfo = DamageInfo()
			dmgInfo:SetDamage( 10 )
			dmgInfo:SetDamageType( DMG_DROWN )
			dmgInfo:SetInflictor( game.GetWorld() )
			dmgInfo:SetAttacker( game.GetWorld() )

			ply:TakeDamageInfo( dmgInfo )

			ply.WaterDamage = ply.WaterDamage + 10
			ply.NextChokeTime = curTime + CHOKE_TIME

		end

	end

end

function GM:PlayerTick(ply, mv)

	-- Predicted, must be called here.
	self:UpdateSuit(ply, mv)

	if SERVER then
		self:LimitPlayerAmmo(ply)
		self:PlayerCheckDrowning(ply)
	end

end

function GM:PlayerThink(ply)

	if SERVER then
		-- I don't really like this, however there is no way to tell if we just equipped the suit
		local prevSuitEquipped = ply.LambdaSuitEquipped or false
		local suitEquipped = ply:IsSuitEquipped()
		if suitEquipped == true and prevSuitEquipped == false then
			self:PlayerSetModel(ply)
		end
		ply.LambdaSuitEquipped = suitEquipped
	end

	--DbgPrint(CurTime())
	self:UpdateGeigerCounter(ply)

end

function GM:GravGunPickupAllowed(ply, ent)

    if ent:IsWeapon() and ent:GetClass() ~= "weapon_crowbar" then
		return false
	end

	do
		return true
	end

	--return BaseClass.GravGunPickupAllowed(ply, ent)
end

function GM:GravGunPunt(ply, ent)

	if ent:IsWeapon()  and ent:GetClass() ~= "weapon_crowbar" then
		return false
	end

	local playerVehicle = ply:GetVehicle()
	if playerVehicle and IsValid(playerVehicle) then
		if ent:IsVehicle() then
			if ent.PassengerSeat == playerVehicle then
				return false
			end
		end
	end

	if ent:IsVehicle() then
		util.RunNextFrame(function()
			if not IsValid(ent) then
				return
			end
			local phys = ent:GetPhysicsObject()
			if not IsValid(phys) then
				return
			end
			local force = phys:GetVelocity()
			force = force * 0.000001
			phys:SetVelocity(force)
		end)
	end

	if ent:IsNPC() and IsFriendEntityName(ent:GetClass()) then
		return false
	end

	return BaseClass.GravGunPickupAllowed(ply, ent)

end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, filter )

	if ply:KeyDown(IN_WALK) then
		return true
	end

	if SERVER then
		self:NotifyNPCFootsteps(ply, pos, foot, sound, volume )
	end

end

if SERVER then

	function GM:SelectBestWeapon(ply)

		-- Switch to a better weapon.
		local weps = ply:GetWeapons()
		local highestDmg = 0
		local bestWep = nil

		for k,v in pairs(weps) do
			local ammo = ply:GetAmmoCount(v:GetPrimaryAmmoType())
			if bestWep == nil then
				bestWep = v
			end
			if ammo ~= 0 then
				local dmgCVar = self.PLAYER_WEAPON_DAMAGE[v:GetClass()]
				if dmgCVar ~= nil then
					local dmg = dmgCVar:GetFloat()
					if dmg > highestDmg then
						bestWep = v
						highestDmg = dmg
					end
				end
			end
		end

		if bestWep ~= nil then
			DbgPrint(bestWep)
			ply:SelectWeapon(bestWep:GetClass())
		end

	end

end

function GM:OnPlayerAmmoDepleted(ply, wep)

	DbgPrint("Ammo Depleted: " .. tostring(ply) .. " - " .. tostring(wep) )

	if SERVER then
		self:SelectBestWeapon(ply)
	end

	if CLIENT then
		ply:EmitSound("hl1/fvox/ammo_depleted.wav", 75, 100, 0.5)
	end

end

function GM:PlayerNoClip(ply, desiredState)

	local sv_cheats = GetConVar("sv_cheats")
	if desiredState == false then
		return true
	elseif sv_cheats:GetBool() == true then
		return true
	end

end
