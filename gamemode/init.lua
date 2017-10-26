AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_postprocess.lua")
AddCSLuaFile("cl_ragdoll_ext.lua")
AddCSLuaFile("cl_scoreboard.lua")

AddCSLuaFile("cl_skin_lambda.lua")
AddCSLuaFile("huds/hud_numeric.lua")
AddCSLuaFile("huds/hud_suit.lua")
AddCSLuaFile("huds/hud_health.lua")
AddCSLuaFile("huds/hud_armor.lua")
AddCSLuaFile("huds/hud_primary_ammo.lua")
AddCSLuaFile("huds/hud_secondary_ammo.lua")
AddCSLuaFile("huds/hud_ammo.lua")
AddCSLuaFile("huds/hud_aux.lua")
AddCSLuaFile("huds/hud_pickup.lua")
AddCSLuaFile("huds/hud_roundinfo.lua")
AddCSLuaFile("huds/hud_settings.lua")
AddCSLuaFile("huds/hud_hint.lua")
AddCSLuaFile("huds/hud_crosshair.lua")

DEFINE_BASECLASS( "gamemode_base" )

include("shared.lua")
include("sv_inputoutput.lua")
include("sv_changelevel.lua")
include("sv_transition.lua")
include("sv_generic_fixes.lua")
include("sv_difficulty.lua")
include("sv_resource.lua")
include("sv_taunts.lua")
include("sv_playerspeech.lua")
include("sv_commands.lua")
include("sv_checkpoints.lua")
include("sv_weapontracking.lua")

local DbgPrint = GetLogging("Server")

function GM:ProcessEnvHudHint(ent)
	DbgPrint(ent, "Enabling env_hudhint for all players")
	ent:AddSpawnFlags(1) -- SF_HUDHINT_ALLPLAYERS
end

function GM:ProcessEnvMessage(ent)
	DbgPrint(ent, "Enabling env_message for all players")
	ent:AddSpawnFlags(2) -- SF_MESSAGE_ALL
end

function GM:ProcessFuncAreaPortal(ent)
	DbgPrint(ent, "Opening func_areaportal")
	-- TODO: This is not ideal at all on larger maps, however can can not get a position for them.
	ent:SetKeyValue("StartOpen", "1")
	ent:Fire("Open")
	ent:SetName("Lambda_" .. ent:GetName())
end

function GM:ProcessFuncAreaPortalWindow(ent)
	DbgPrint(ent, "Extending func_areaportalwindow")
	-- I know this is ugly, but its better than white windows everywhere, this is not 2004 anymore.
	local saveTable = ent:GetSaveTable()
	local fadeStartDist = tonumber(saveTable["FadeStartDist"] or "0") * 3
	local fadeDist = tonumber(saveTable["FadeDist"] or "0") * 3
	ent:SetKeyValue("FadeDist", fadeDist)
	ent:SetKeyValue("FadeStartDist", fadeStartDist)
end

function GM:ProcessTriggerWeaponDissolve(ent)
	-- OnChargingPhyscannon
	-- UGLY HACK! But thats the only way we can tell when to upgrade.
	ent:Fire("AddOutput", "OnChargingPhyscannon lambda_physcannon,Supercharge,,0")
end

local ENTITY_PROCESSORS =
{
	["env_hudhint"] = { PostFrame = true, Fn = GM.ProcessEnvHudHint },
	["env_message"] = { PostFrame = true, Fn = GM.ProcessEnvMessage },
	["func_areaportal"] = { PostFrame = true, Fn = GM.ProcessFuncAreaPortal },
	["func_areaportalwindow"] = { PostFrame = true, Fn = GM.ProcessFuncAreaPortalWindow },
}

function GM:GetNextUniqueEntityId()
	self.UniqueEntityId = self.UniqueEntityId or 0
	self.UniqueEntityId = self.UniqueEntityId + 1
	return self.UniqueEntityId
end

function GM:OnEntityCreated(ent)

	local class = ent:GetClass()
	local entityProcessor = ENTITY_PROCESSORS[class]

	if entityProcessor ~= nil and entityProcessor.PostFrame == false then
		entityProcessor.Fn(self, ent)
	end

	-- Used to track the entity in case we respawn it.
	ent.UniqueEntityId = ent.UniqueEntityId or self:GetNextUniqueEntityId()

	-- Run this next frame so we can safely remove entities and have their actual names assigned.
	util.RunNextFrame(function()

		if not IsValid(ent) then
			return
		end

		-- Required information for respawning some things.
		ent.InitialSpawnData =
		{
			Pos = ent:GetPos(),
			Ang = ent:GetAngles(),
			Mins = ent:OBBMins(),
			Maxs = ent:OBBMaxs(),
		}

		if ent:IsWeapon() == true then
			self:TrackWeapon(ent)
			if ent:CreatedByMap() == true then
				DbgPrint("Level designer created weapon: " .. tostring(ent))
				self:InsertLevelDesignerPlacedObject(ent)
			end
		elseif ent:IsItem() == true then
			if ent:CreatedByMap() == true then
				DbgPrint("Level designer created item: " .. tostring(ent))
				self:InsertLevelDesignerPlacedObject(ent)
			end
		end

		if self.MapScript then
			-- Monitor scripts that we have filtered by class name.
			if self.MapScript.EntityFilterByClass and self.MapScript.EntityFilterByClass[ent:GetClass()] == true then
				DbgPrint("Removing filtered entity by class: " .. tostring(ent))
				ent:Remove()
				return
			end

			-- Monitor scripts that have filtered by name.
			if self.MapScript.EntityFilterByName and self.MapScript.EntityFilterByName[ent:GetName()] == true then
				DbgPrint("Removing filtered entity by name: " .. tostring(ent) .. " (" .. ent:GetName() .. ")")
				ent:Remove()
				return
			end
		end

		if entityProcessor ~= nil and entityProcessor.PostFrame == true then
			entityProcessor.Fn(self, ent)
		end

	end)

	if ent:IsNPC() then
		self:RegisterNPC(ent)
	end

	-- Deal with vehicles at the same frame, sometimes it wouldn't show the gun.
	if ent:IsVehicle() then
		self:HandleVehicleCreation(ent)
	end

end

function GM:InsertLevelDesignerPlacedObject(obj)
	local objects = self.LevelRelevantObjects or {}
	objects[obj] = true
	self.LevelRelevantObjects = objects
end

function GM:IsLevelDesignerPlacedObject(obj)
	local objects = self.LevelRelevantObjects
	if objects == nil then
		return false
	end
	return objects[obj] == true
end

function GM:RemoveLevelDesignerPlacedObject(obj)
	local objects = self.LevelRelevantObjects
	if objects == nil then
		return
	end
	objects[obj] = nil
end

function GM:ClearLevelDesignerPlacedObjects()
	self.LevelRelevantObjects = {}
end

function GM:ApplyCorrectedDamage(dmginfo)

	local attacker = dmginfo:GetAttacker()

	if IsValid(attacker) and (dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_CLUB)) then

		local weaponTable = nil
		local wep = nil

		if attacker:IsPlayer() then
			weaponTable = self.PLAYER_WEAPON_DAMAGE
			wep = attacker:GetActiveWeapon()
		elseif attacker:IsNPC() then
			weaponTable = self.NPC_WEAPON_DAMAGE
			wep = attacker:GetActiveWeapon()
		end

		if weaponTable ~= nil and IsValid(wep) then
			local class = wep:GetClass()
			local dmgCVar = weaponTable[class]
			if dmgCVar ~= nil then
				local dmgAmount = dmgCVar:GetInt()
				DbgPrint("Setting modified weapon damage " .. tostring(dmgAmount) .. " on " .. class)
				dmginfo:SetDamage(dmgAmount)
			end
		end

	end

	return dmginfo

end

function GM:EntityTakeDamage(target, dmginfo)

	local attacker = dmginfo:GetAttacker()
	local inflictor = dmginfo:GetInflictor()
	local targetClass = target:GetClass()

	DbgPrint("EntityTakeDamage -> Target: " .. tostring(target) .. ", Attacker: " .. tostring(attacker) .. ", Inflictor: " .. tostring(inflictor))

	local gameType = self:GetGameType()

	target.IsPhysgunDamage = dmginfo:IsDamageType(DMG_PHYSGUN)
	DbgPrint(target, "PhysgunDamage: " .. tostring(target.IsPhysgunDamage))

	if target:IsNPC() then

		local isFriendly = gameType.ImportantPlayerNPCNames[target:GetName()] or gameType.ImportantPlayerNPCClasses[targetClass]

		-- Check if player is attacking friendlies.
		if ((IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer())) and isFriendly == true then
			DbgPrint("Filtering damage on friendly")
			dmginfo:ScaleDamage(0)
			return true
		end

		if IsValid(attacker) and attacker:IsPlayer() and dmginfo:IsDamageType(DMG_BLAST) == false then
			dmginfo:ScaleDamage(self:GetDifficultyNPCDamageScale(target))

			self:RegisterNPCDamage(target, attacker, dmginfo)
		end

	elseif target:IsPlayer() then

		if target:IsPositionLocked() or target:IsInactive() == true then
			return true
		end

		local gameType = self:GetGameType()
		if target ~= attacker and target ~= inflictor then
			if gameType:PlayerShouldTakeDamage(target, attacker, inflictor) == false then
				return true
			end
		end

		local dmg = dmginfo:GetDamage()
		if dmg > 0 then
			local hitGroup = HITGROUP_GENERIC
			if dmginfo:IsDamageType(DMG_FALL) and dmg > 40 and math.random(1, 2) == 1 then
				hitGroup = HITGROUP_LEFTLEG
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

	elseif target:IsWeapon() == true or target:IsItem() == true then
		if lambda_prevent_item_move:GetBool() == true then
			if (IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer()) then
				dmginfo:SetDamageForce(Vector(0, 0, 0))
			end
		end
	end

	if target.FilterDamage == true then
		DbgPrint("Filtering Damage!")
		dmginfo:ScaleDamage(0)
		return true
	end


end

function GM:CreateEntityRagdoll( owner, ragdoll )

	DbgPrint("Create Ragdoll:", tostring(owner), tostring(ragdoll))
	ragdoll.IsPhysgunDamage = owner.IsPhysgunDamage

end

function GM:LambdaPreChangelevel(data)

end
