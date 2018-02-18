
function GM:InitializeWeaponTracking()
	self.TrackedWeapons = {}
	self.NextWeaponCheck = CurTime() + 0.1
end

function GM:TrackWeapon(wep)
	--self.TrackedWeapons[wep] = true
	table.insert(self.TrackedWeapons, wep)
end

function GM:WeaponTrackingThink()

	local curTime = CurTime()

	if self.NextWeaponCheck == nil or self.NextWeaponCheck < curTime then
		return
	end

	local ownerlessCount = 0

	for k = #self.TrackedWeapons, 1, -1 do
		local wep = self.TrackedWeapons[k]
		if not IsValid(wep) then
			table.remove(self.TrackedWeapons, k)
			continue
		end

		if wep:GetOwner() == nil or wep:GetOwner() == NULL and self:IsLevelDesignerPlacedObject(wep) == false then
			if ownerlessCount >= 200 then
				PrintMessage(HUD_PRINTTALK, "Removing weapon: " .. tostring(wep))
				table.remove(self.TrackedWeapons, k)
				wep:Remove()
				continue
			else
				ownerlessCount = ownerlessCount + 1
			end
		end
	end

	self.NextWeaponCheck = curTime + 0.1

end
