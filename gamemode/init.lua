AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_postprocess.lua")
AddCSLuaFile("cl_ragdoll_ext.lua")
AddCSLuaFile("cl_scoreboard.lua")

AddCSLuaFile("huds/hud_numeric.lua")
AddCSLuaFile("huds/hud_suit.lua")
AddCSLuaFile("huds/hud_health.lua")
AddCSLuaFile("huds/hud_armor.lua")
AddCSLuaFile("huds/hud_primary_ammo.lua")
AddCSLuaFile("huds/hud_secondary_ammo.lua")
AddCSLuaFile("huds/hud_ammo.lua")
AddCSLuaFile("huds/hud_aux.lua")
AddCSLuaFile("huds/hud_pickup.lua")
AddCSLuaFile("huds/hud_respawn.lua")

DEFINE_BASECLASS( "gamemode_base" )

include("shared.lua")
include("sv_inputoutput.lua")
include("sv_changelevel.lua")
include("sv_transition.lua")
include("sv_generic_fixes.lua")
include("sv_difficulty.lua")
include("sv_resource.lua")
include("sv_taunts.lua")
include("sv_commands.lua")

local DbgPrint = GetLogging("Server")

function GM:OnEntityCreated(ent)

	local self = self
	local ent = ent
	local class = ent:GetClass()

	-- Run this next frame so we can safely remove entities and have their actual names assigned.
	util.RunNextFrame(function()

		if not IsValid(ent) then
			return
		end

		if self.MapScript then
			-- Monitor scripts that we have filtered by class name.
			if self.MapScript.EntityFilterByClass and self.MapScript.EntityFilterByClass[ent:GetClass()] == true then
				DbgPrint("Removing filtered entity by class: " .. tostring(ent))
				ent:Remove()
			end

			-- Monitor scripts that have filtered by name.
			if self.MapScript.EntityFilterByName and self.MapScript.EntityFilterByName[ent:GetName()] == true then
				DbgPrint("Removing filtered entity by name: " .. tostring(ent) .. " (" .. ent:GetName() .. ")")
				ent:Remove()
			end

			if class == "env_hudhint" then
				DbgPrint("Enabling env_hudhint for all players")
				ent:AddSpawnFlags(1) -- SF_HUDHINT_ALLPLAYERS
			elseif class == "env_message" then
				ent:AddSpawnFlags(2) -- SF_MESSAGE_ALL
			elseif class == "func_areaportal" then
				-- TODO: This is not ideal at all on larger maps, however can can not get a position for them.
				ent:SetKeyValue("StartOpen", "1")
				ent:Fire("Open")
				ent:SetName("Lambda_" .. ent:GetName())
			elseif class == "func_areaportalwindow" then
				-- I know this is ugly, but its better than white windows everywhere, this is not 2004 anymore.
				local saveTable = ent:GetSaveTable()
				local fadeStartDist = tonumber(saveTable["FadeStartDist"] or "0") * 3
				local fadeDist = tonumber(saveTable["FadeDist"] or "0") * 3
				ent:SetKeyValue("FadeDist", fadeDist)
				ent:SetKeyValue("FadeStartDist", fadeStartDist)
			end

		end

		if ent:IsNPC() then
			self:RegisterNPC(ent)
		end
	end)

	-- Deal with vehicles at the same frame, sometimes it wouldn't show the gun.
	if ent:IsVehicle() then
		self:HandleVehicleCreation(ent)
	end

end

function GM:EntityTakeDamage(target, dmginfo)

	local attacker = dmginfo:GetAttacker()
	local inflictor = dmginfo:GetInflictor()
	local class = target:GetClass()

	DbgPrint("EntityTakeDamage -> Target: " .. tostring(target) .. ", Attacker: " .. tostring(attacker) .. ", Inflictor: " .. tostring(inflictor))

	local gameType = self:GetGameType()

	if target:IsNPC() then

		local isFriendly = gameType.ImportantPlayerNPCNames[target:GetName()] or gameType.ImportantPlayerNPCClasses[target:GetClass()]

		-- Check if player is attacking friendlies.
		if (IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer()) then
			if isFriendly == true then
				DbgPrint("Filtering damage on friendly")
				dmginfo:ScaleDamage(0)
				return true
			end
		end

		if IsValid(attacker) and attacker:IsPlayer() and dmginfo:IsDamageType(DMG_BLAST) == false then
			dmginfo:ScaleDamage(self:GetDifficultyNPCDamageScale(target))

			self:RegisterNPCDamage(target, attacker, dmginfo)
		end

	elseif target:IsPlayer() then

		if target:IsPositionLocked() or target:IsInactive() == true then
			return true
		end

		if (IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer()) then
			if not dmginfo:IsExplosionDamage() then
				return true
			end
		end

		local dmg = dmginfo:GetDamage()
		if dmg > 0 then
			local hitGroup = HITGROUP_GENERIC
			if dmginfo:IsDamageType(DMG_FALL) then
				if dmg > 40 and math.random(1, 2) == 1 then
					hitGroup = HITGROUP_LEFTLEG
				end
			end
			self:EmitPlayerHurt(dmginfo:GetDamage(), target, hitGroup)
		end

		if IsValid(attacker) and attacker:IsNPC() and dmginfo:IsDamageType(DMG_BLAST) == false then
			--dmginfo:ScaleDamage(self:GetDifficultyPlayerDamageScale(attacker))

			self:RegisterPlayerDamage(target, attacker, dmginfo)
		end

		if target:InVehicle() then
			dmginfo:ScaleDamage(0.6)
		end

		-- NOTE: Blocking too early would not register any damage.
		if lambda_player_god:GetBool() == true then
			return true
		end


	elseif target:IsVehicle() then


	end

	if target.FilterDamage == true then
		DbgPrint("Filtering Damage!")
		dmginfo:ScaleDamage(0)
		return true
	end


end
