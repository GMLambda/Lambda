AddCSLuaFile()

local DbgPrint = GetLogging("Physcannon")

local physcannon_minforce = GetConVar("physcannon_minforce")
local physcannon_maxforce = GetConVar("physcannon_maxforce")

local physcannon_maxmass = GetConVar("physcannon_maxmass") -- ( "physcannon_maxmass", "250" );
local physcannon_tracelength = GetConVar("physcannon_tracelength") --( "physcannon_tracelength", "250" );

local physcannon_mega_tracelength = GetConVar("physcannon_mega_tracelength") -- ( "physcannon_mega_tracelength", "850" );
local physcannon_mega_pullforce = GetConVar("physcannon_mega_pullforce") --( "physcannon_mega_pullforce", "8000" );

local physcannon_cone = GetConVar("physcannon_cone") -- "physcannon_cone" = "0.97"
local physcannon_mega_enabled  = GetConVar("physcannon_mega_enabled")

DEFINE_BASECLASS( "gamemode_base" )

util.PrecacheModel("sprites/lgtning_noz.vmt")

function GM:IsMegaCannonEnabled()
	if physcannon_mega_enabled:GetBool() == true then
		return true
	end
	if self:IsGlobalStateOn("super_phys_gun") == true then
		return true
	end
	return false
end

if SERVER then

	function GM:PhyscannonTick()

		if self:IsMegaCannonEnabled() then
			if physcannon_maxmass:GetInt() ~= 8000 then
				RunConsoleCommand("physcannon_maxmass", "8000")
			end
			if physcannon_tracelength:GetInt() ~= 850 then
				RunConsoleCommand("physcannon_tracelength", "850")
			end
			if physcannon_cone:GetFloat() ~= 0.98 then
				RunConsoleCommand("physcannon_cone", "0.98")
			end
			if physcannon_maxforce:GetFloat() ~= 3500 then
				RunConsoleCommand("physcannon_maxforce", "3500")
			end
		else
			if physcannon_maxmass:GetInt() ~= 250 then
				RunConsoleCommand("physcannon_maxmass", "250")
			end
			if physcannon_tracelength:GetInt() ~= 250 then
				RunConsoleCommand("physcannon_tracelength", "250")
			end
			if physcannon_cone:GetFloat() ~= 0.97 then
				RunConsoleCommand("physcannon_cone", "0.97")
			end
			if physcannon_maxforce:GetFloat() ~= 1500 then
				RunConsoleCommand("physcannon_maxforce", "1500")
			end
		end

	end

	function GM:PhyscannonThink(ply, wep)

		wep:SetNW2Bool("Megacannon", self:IsMegaCannonEnabled())

		if wep.Debounce == true then
			wep:SetNextSecondaryFire(CurTime())
		end

	end

end

function GM:GravGunOnPickedUp(ply, ent)

	DbgPrint("Picked Up: " .. tostring(ent))

	local wep = ply:GetActiveWeapon()
	if wep:GetClass() ~= "weapon_physcannon" then
		return
	end

	wep.Debounce = false

	if wep:GetNW2Bool("Megacannon") == true and ent:IsNPC() and ent.PhysgunPickupKill == true then

		local dmgInfo = DamageInfo()
		dmgInfo:SetInflictor(ply)
		dmgInfo:SetAttacker(ply)
		dmgInfo:SetDamage(10000)
		dmgInfo:SetDamageType(bit.bor(DMG_PHYSGUN))
		dmgInfo:SetDamageForce(Vector(0, 0, 0))

		ent.PhyscannonPulled = true
		ent:SetShouldServerRagdoll(true)
		ent:TakeDamageInfo(dmgInfo)

		wep:SetNextSecondaryFire(CurTime())
		wep:SetSaveValue("m_flNextSecondaryAttack", -3)
		wep.Debounce = true
		wep:SetOwner(NULL)

		local hookPly = ply
		local hookName = tostring(wep) .. tostring(ply)

		-- Because it spawns a ragdoll we have to have to release the key target the ragdoll instead.
		hook.Add("StartCommand", hookName, function(ply, cmd)
			-- Debounce IN_ATTACK2
			if hookPly ~= ply then
				--DbgError("Invalid ply")
				return
			end
			cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK2)))
			wep:SetNextSecondaryFire(CurTime())
			wep:SetOwner(ply)

			hook.Add("StartCommand", hookName, function()
				wep:SetNextSecondaryFire(CurTime())
				cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK2))
				--wep.Debounce = false
				hook.Remove("StartCommand", hookName)
			end)
		end)


	end

end

function GM:GravGunPickupAllowed(ply, ent)

	--DbgPrint("GravGunPickupAllowed", ent)

    if ent:IsWeapon() and ent:GetClass() ~= "weapon_crowbar" then
		return false
	end

	local wep = ply:GetActiveWeapon()
	if wep:GetClass() == "weapon_physcannon" then

		if wep:GetNW2Bool("Megacannon") == true and ent:IsNPC() and ent:GetMoveType() == MOVETYPE_STEP then
			--DbgPrint("Assigning move type")
			ent:SetMoveType(MOVETYPE_VPHYSICS)
			ent.PhysgunPickupKill = true
		end

	end

	return true

end

function GM:GravGunPunt(ply, ent)

	--DbgPrint("PUNT: " .. tostring(ent))

	if ent:IsWeapon() and ent:GetClass() ~= "weapon_crowbar" then
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

	if SERVER then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_physcannon" then
			if wep:GetNW2Bool("Megacannon") == true then

				if ent:IsNPC() then

					local phys = ent:GetPhysicsObject()
					if not IsValid(phys) then
						return
					end
					local mass = phys:GetMass()

					-- Just kill them
					local dmgInfo = DamageInfo()
					dmgInfo:SetInflictor(ply)
					dmgInfo:SetAttacker(ply)
					dmgInfo:SetDamage(10000)
					dmgInfo:SetDamageType(bit.bor(DMG_PHYSGUN))
					dmgInfo:SetDamageForce(ply:GetAimVector() * mass * physcannon_maxforce:GetFloat())

					ent.PhyscannonPulled = true
					ent:SetShouldServerRagdoll(true)
					ent:TakeDamageInfo(dmgInfo)

				elseif ent:IsRagdoll() then
					ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
					util.RunNextFrame(function()
						if not IsValid(ent) then
							return
						end

						local phys = ent:GetPhysicsObject()
						local mass = 80
						if IsValid(phys) then
							mass = phys:GetMass()
						end

						local fwd = ply:GetAimVector()

						-- Distribute all the velocity over the entire ragdoll not just the part held.
						local count = ent:GetPhysicsObjectCount()
						for i = 0, count - 1 do
							local phys = ent:GetPhysicsObjectNum(i)
							if not IsValid(phys) then
								continue
							end
							phys:SetVelocity(fwd * (mass / count) * physcannon_maxforce:GetFloat())
						end

					end)

				end

			end
		end
	end

	return BaseClass.GravGunPunt(ply, ent)

end

function GM:PlayerSelectedGravityGun(ply, wep)

	DbgPrint("Ply " .. tostring(ply) .. " selected weapon: " .. tostring(wep))

	wep:SetNW2Bool("Megacannon", self:IsMegaCannonEnabled())

end

function GM:PhyscannonDrawViewModel(vm, ply, wep)

	if wep:GetNW2Bool("Megacannon") == true then

		local curMdl = wep:GetWeaponViewModel()
		if curMdl ~= "models/weapons/c_superphyscannon.mdl" then
			vm:SetWeaponModel("models/weapons/c_superphyscannon.mdl", wep)
		end

	else

		local curMdl = wep:GetWeaponViewModel()
		if curMdl ~= "models/weapons/c_physcannon.mdl" then
			vm:SetWeaponModel("models/weapons/c_physcannon.mdl", wep)
		end

	end

end
