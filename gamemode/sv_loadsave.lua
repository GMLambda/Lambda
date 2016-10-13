-- NOTE: This is currently not working properly to reset map states at a specific time.

function GM:ShouldSaveEntity(ent)

	local caps = ent:ObjectCaps()
	if bit.band(caps, FCAP_DONT_SAVE) ~= 0 then
		--return false
	end

	return true

end

function GM:GetEntitySaveData(ent, queue)

	local data = {}
	local class = ent:GetKeyValues()["classname"] or ent:GetClass()

	data.RefId = ent:EntIndex()
	data.Class = class
	data.SaveTable = ent:GetSaveTable()
	data.Outputs = ent.EntityOutputs or {}
	data.KeyValues = ent.KeyValueTable or ent:GetKeyValues()
	data.Pos = ent:GetPos()
	data.Ang = ent:GetAngles()
	data.Model = ent:GetModel()
	data.Effects = ent:GetEffects()
	data.Name = ent:GetName()
	data.Skin = ent:GetSkin()
	data.Mat = ent:GetMaterial()
	data.CollisionGroup = ent:GetCollisionGroup()
	data.SolidFlags = ent:GetSolidFlags()
	data.Table = table.Copy(ent:GetTable())
	data.MoveType = ent:GetMoveType()
	data.MoveCollide = ent:GetMoveCollide()
	data.Flags = ent:GetFlags()
	data.EFlags = ent:GetEFlags()
	data.IsPlayer = ent:IsPlayer()
	data.IsNPC = ent:IsNPC()
	data.IsWeapon = ent:IsWeapon()
	data.IsWorld = ent:IsWorld()

	--data.LuaData
	if ent.GetCoopKeyValueTable then
		table.Merge(data.KeyValues, ent:GetCoopKeyValueTable())
	end

	for k,v in pairs(data.SaveTable) do

		if isentity(v) and IsValid(v) and not v:IsWorld() and self:ShouldSaveEntity(v) then
			data.SaveTable[k] = "CoopRef_" .. v:EntIndex()
			table.insert(queue, v)
		end

	end

	for k,v in pairs(data.KeyValues) do
		if k == "angle" then
			local y = tonumber(v)
			if y >= 0 then
				local localAng = ent:GetLocalAngles()
				local ang = string.format("%f %f %f", localAng.x, y, localAng.z)
				data.KeyValues["angles"] = ang
			elseif y == -1 then
				data.KeyValues["angles"] = "-90 0 0"
			else
				data.KeyValues["angles"] = "90 0 0"
			end

			data.KeyValues[k] = nil
		elseif k == "hammerid" then
			data.KeyValues[k] = nil
		end
	end

	return data

end

function GM:GetPlayerSaveData(ply)

end

SAVEDATA = SAVEDATA or { Ents = {}, Players = {} }

function GM:SaveGameState()

	do

		SAVEDATA = gmsave.SaveMap(game.SinglePlayer() and Entity( 1 ) or player.GetAll()[1])

		return true

	end

	SAVEDATA = { Ents = {}, Players = {} }

	local queue = table.Copy(ents.GetAll())
	local processed = {}

	local uniqueIdStart = CurTime() + SysTime()
	local i = 0

	while table.Count(queue) > 0 do

		local v = queue[1]
		table.remove(queue, 1)

		if processed[v] == true then
			continue
		end

		processed[v] = true

		if self:ShouldSaveEntity(v) == false then
			continue
		end

		v.UniqueSaveId = uniqueIdStart + i
		i = i + 1

		local data = self:GetEntitySaveData(v, queue)
		table.insert(SAVEDATA.Ents, data)

		data.UniqueSaveId = v.UniqueSaveId

	end

	DbgPrint("Saved " .. #SAVEDATA.Ents .. " objects")
	--PrintTable(SAVEDATA)

end

local SAVETABLE_BLACKLIST =
{
	--["m_iActiveSound"] = true,
	--["m_iFreeSound"] = true,
	--[[
	["m_vecCommandGoal"] = true,
	["basevelocity"] = true,
	["m_vecLean"] = true,
	["avelocity"] = true,
	["velocity"] = true,
	["m_vecOrigin"] = true,
	["m_angRotation"] = true,
	["m_angAbsRotation"] = true,
	["m_vecAbsOrigin"] = true,
	["m_vSavePosition"] = true,
	["m_hMoveEntity"] = true,
	["model"] = true,
	["modelindex"] = true,
	["m_iszModelName"] = true,
	["effects"] = true,
	["spawnflags"] = true,
	["m_MoveType"] = true,
	["hammerid"] = true,
	["globalname"] = true,
	["m_pnext"] = true,
	["m_pprevious"] = true,
	]]
}

function GM:CreateSavedEntities()

	-- Create everything.
	local createdEnts = {}
	local entData = {}
	local referencedEnts = {}
	local spawned = {}
	local dispatchSpawn = {}
	--PrintTable(SAVEDATA)

	for k,data in pairs(SAVEDATA.Ents) do

		DbgPrint("Creating: " .. data.Class .. " RefId: " .. data.RefId)

		local ent = Entity(data.RefId)
		if IsValid(ent) then
			if ent.UniqueSaveId ~= data.UniqueSaveId then
				DbgPrint("Overriding entity: " .. tostring(ent) .. ", non-matching save id")
				ent = nil
			end
		end

		if not IsValid(ent) and data.IsPlayer == false and data.IsWorld == false then
			ent = ents.Create(data.Class)
			dispatchSpawn[ent] = true
		else
			dispatchSpawn[ent] = false
		end

		if not IsValid(ent) then
			DbgPrint("Failed to create entity: " .. data.Class)
			continue
		end

		for k,v in pairs(data.KeyValues) do
			DbgPrint("KeyValue: " .. k .. " -> " .. v)
			--ent:SetKeyValue(k, v)
			GAMEMODE:EntityKeyValue(ent, k, v)
		end

		ent:SetTable(data.Table)

		createdEnts[data.RefId] = ent
		data.RefId = ent:EntIndex()

		entData[ent] = data
		SAVEDATA.Ents[k] = data

	end

	-- Fix references, save values
	for _, ent in pairs(createdEnts) do

		local data = entData[ent]

		ent:SetTable(data.Table)

		for k,v in pairs(data.SaveTable) do
			if SAVETABLE_BLACKLIST[k] == true then
				continue
			end

			if isstring(v) and v:sub(1, 8) == "CoopRef_" then
				local refId = tonumber(v:sub(9))
				local refEnt = createdEnts[refId]
				if refEnt ~= nil and IsValid(refEnt) then
					if refEnt == ent then
						DbgPrint(ent, "Cyclic reference!", refEnt)
					else
						DbgPrint(tostring(ent), "SaveValue: " .. k .. " -> " .. tostring(refEnt))
						ent:SetSaveValue(k, refEnt)
						table.insert(referencedEnts, refEnt)
						DbgPrint(tostring(ent), "Resolved reference (" .. k .. "): " .. tostring(refEnt))
					end
				else
					DbgPrint("Unable to solve reference (" .. k .. "): " .. tostring(refId))
				end
			else
				--DbgPrint("SaveValue: " .. k .. " -> " .. tostring(v))
				if v ~= NULL then
					ent:SetSaveValue(k, v)
				end
			end
		end

		for output, tab in pairs(data.Outputs or {}) do
			for _,v in pairs(tab) do
				ent:SetKeyValue(output, v)
				GAMEMODE:EntityKeyValue(ent, output, v)
			end
		end

		ent:SetPos(data.Pos)
		ent:SetAngles(data.Ang)
		if data.Model ~= nil then
			ent:SetModel(data.Model)
		end
		ent:SetName(data.Name)
		ent:AddEffects(data.Effects)
		ent:SetSkin(data.Skin)
		ent:SetMaterial(data.Mat)
		ent:SetCollisionGroup(data.CollisionGroup)
		ent:SetSolidFlags(data.SolidFlags)
		ent:SetMoveType(data.MoveType)
		ent:SetMoveCollide(data.MoveCollide)
		ent:AddFlags(data.Flags)
		ent:AddEFlags(data.EFlags)
	end

	-- Spawn
	for _, ent in pairs(referencedEnts) do

		if spawned[ent] == true then
			continue
		end
		spawned[ent] = true

		local data = entData[ent]

		local caps = ent:ObjectCaps()
		if bit.band(caps, FCAP_MUST_SPAWN) and dispatchSpawn[ent] == true then
			--DbgPrint("Spawn: " .. tostring(ent))
			ent:Spawn()
		end

		local class = ent:GetClass()
		if ent:IsNPC() or ent:IsVehicle() and dispatchSpawn[ent] == true then
			ent:Activate()
		end

		if IsValid(ent) then
			DbgPrint("Created: " .. tostring(ent))
		else
			DbgPrint("Unable to create entity: " .. data.Class)
		end

	end

	-- Spawn
	for _, ent in pairs(createdEnts) do

		if spawned[ent] == true then
			continue
		end
		spawned[ent] = true

		local data = entData[ent]

		local caps = ent:ObjectCaps()
		if bit.band(caps, FCAP_MUST_SPAWN) and dispatchSpawn[ent] == true then
			--DbgPrint("Spawn: " .. tostring(ent))
			ent:Spawn()
		end

		local class = ent:GetClass()
		if ent:IsNPC() or ent:IsVehicle() and dispatchSpawn[ent] == true  then
			ent:Activate()
		end

		ent.UniqueSaveId = data.UniqueSaveId

		if IsValid(ent) then
			DbgPrint("Created: " .. tostring(ent))
		else
			DbgPrint("Unable to create entity: " .. data.Class)
		end

	end

end

function GM:LoadGameState()

	do

		if SAVEDATA ~= nil then

			gmsave.LoadMap(SAVEDATA, game.SinglePlayer() and Entity( 1 ) or player.GetAll()[1])
			return true

		end

	end
	--game.CleanUpMap()

	if SAVEDATA == nil or table.Count(SAVEDATA.Ents) == 0 then
		DbgPrint("Empty SaveData!")
		return
	end

	-- Remove everything.
	for k,data in pairs(SAVEDATA.Ents) do
		local ent = Entity(data.RefId)
		if IsValid(ent) and ent:GetKeyValues()["classname"] == data.Class then
			--ent:Remove()
		else
			--DbgPrint("Invalid reference: " .. data.RefId)
		end
	end

	local self = self
	timer.Simple(1, function()
		self:CreateSavedEntities()
	end)

end
