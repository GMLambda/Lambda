--local DbgPrint = GetLogging("Ragdoll")

local ImpactSounds =
{
	Soft =
	{
		"physics/body/body_medium_impact_soft1.wav",
		"physics/body/body_medium_impact_soft2.wav",
		"physics/body/body_medium_impact_soft3.wav",
		"physics/body/body_medium_impact_soft4.wav",
		"physics/body/body_medium_impact_soft5.wav",
		"physics/body/body_medium_impact_soft6.wav",
		"physics/body/body_medium_impact_soft7.wav",
	},
	Hard =
	{
		"physics/body/body_medium_impact_hard1.wav",
		"physics/body/body_medium_impact_hard2.wav",
		"physics/body/body_medium_impact_hard3.wav",
		"physics/body/body_medium_impact_hard4.wav",
		"physics/body/body_medium_impact_hard5.wav",
		"physics/body/body_medium_impact_hard6.wav",
	},
	Break =
	{
		"physics/body/body_medium_break2.wav",
		"physics/body/body_medium_break3.wav",
		"physics/body/body_medium_break4.wav",
	},
}

local bloodEmitter = nil

local function HandleRagdollImpact(ent, data)

	ent.LastRagdollImpact = ent.LastRagdollImpact or 0

	if bloodEmitter == nil then
		bloodEmitter = ParticleEmitter(Vector(0, 0, 0), false)
	end

	if CurTime() - ent.LastRagdollImpact > 0.05 then

		ent.LastRagdollImpact = CurTime()

		--PrintTable(data)

		local sndTable = nil
		if data.Speed >= 600 then
			sndTable = ImpactSounds.Break
		elseif data.Speed >= 300 then
			sndTable = ImpactSounds.Hard
		elseif data.Speed >= 100 then
			sndTable = ImpactSounds.Soft
		end

		if sndTable then
			local snd = table.Random(sndTable)
			ent:EmitSound(snd)
		end

		if data.Speed >= 130 then
			local effectdata = EffectData()
			effectdata:SetNormal(data.HitNormal)
			effectdata:SetOrigin(data.HitPos)
			effectdata:SetMagnitude(3)
			effectdata:SetScale(10)
			effectdata:SetFlags(3)
			effectdata:SetColor(0)
			util.Effect("bloodspray", effectdata, true, true)

			effectdata = EffectData()
			effectdata:SetNormal(data.HitNormal)
			effectdata:SetOrigin(data.HitPos)
			effectdata:SetMagnitude(data.Speed / 100)
			effectdata:SetScale(10)
			effectdata:SetFlags(3)
			effectdata:SetColor(0)
			util.Effect("BloodImpact", effectdata, true, true)

			util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
		end

	end

end

function GM:HandleRagdollCreation(ragdoll)

	ragdoll:AddCallback("PhysicsCollide", HandleRagdollImpact)

end
