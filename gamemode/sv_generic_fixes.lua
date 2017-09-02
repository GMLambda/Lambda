local Dbgprint = GetLogging("Generic")

local function ReplaceFuncTankVolume(ent, volname)

	--DbgPrint("Replacing control volume: " .. volname)

	local ent = ent
	local newName = "Lambda" .. volname

	ents.WaitForEntityByName(volname, function(vol)

		DbgPrint("Replacing control volume for: " .. tostring(ent))

		local newVol = ents.Create("trigger") -- Yes this actually exists and it has what func_tank needs.
		newVol:SetKeyValue("StartDisabled", "0")
		newVol:SetKeyValue("spawnflags", vol:GetSpawnFlags())
		newVol:SetModel(vol:GetModel())
		newVol:SetMoveType(vol:GetMoveType())
		newVol:SetPos(vol:GetPos())
		newVol:SetAngles(vol:GetAngles())
		newVol:SetName(newName)
		newVol:Spawn()
		newVol:Activate()
		newVol:AddSolidFlags(FSOLID_TRIGGER)
		newVol:SetNotSolid(true)
		newVol:AddEffects(EF_NODRAW)

		-- The previous volume is no longer needed.
		vol:Remove()

	end)

	return newName

end

--- func_tank not controllable because of custom trigger entities
hook.Add("EntityKeyValue", "Lambda_FuncTank", function(ent, key, val)
	if ent:GetClass() == "func_tank" or ent:GetClass() == "func_tankairboatgun" then
		if key == "control_volume" then
			return ReplaceFuncTankVolume(ent, val)
		end
	end
end)
