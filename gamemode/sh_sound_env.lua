if SERVER then
	AddCSLuaFile()
end

function GM:SetSoundSuppressed(suppress)
	self.SuppressSound = suppress
end

local host_timescale = GetConVar("host_timescale")

function GM:EntityEmitSound(data)

	local p = data.Pitch

	if game.GetTimeScale() ~= 1 then
		p = p * (game.GetTimeScale() * 1.5)
	elseif host_timescale:GetFloat() ~= 1 then
		p = p * (host_timescale:GetFloat() * 1.5)
	end

	p = math.Clamp(p, 0, 255)
	data.Pitch = p

	local ent = data.Entity

	if IsValid(ent) and ent:IsNPC() and string.sub(data.SoundName, 1, 16):iequals("player/footsteps") then
		if self:NPCFootstep(ent, data) == false then
			return false
		end
	end

	return true

end
