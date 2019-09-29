if SERVER then
    AddCSLuaFile()
end

sound.Add({
    name = "Flesh.BulletImpact",
    channel = CHAN_WEAPON,
    volume = 0.7,
    level = SNDLVL_NORM,
    pitch = 100,
    sound = { 
        "lambda/physics/flesh/flesh_impact_bullet1.wav",
        "lambda/physics/flesh/flesh_impact_bullet2.wav",
        "lambda/physics/flesh/flesh_impact_bullet3.wav",
        "lambda/physics/flesh/flesh_impact_bullet4.wav",
        "lambda/physics/flesh/flesh_impact_bullet5.wav",
    },
})

function GM:SetSoundSuppressed(suppress)
    self.SuppressSound = suppress
end

local host_timescale = GetConVar("host_timescale")

function GM:EntityEmitSound(data)

    local modifyPitch = true
    local modified

    if data.SoundName == "lambda/roundover.mp3" then
        modifyPitch = false
    end

    if modifyPitch == true then
        local p = data.Pitch

        if game.GetTimeScale() ~= 1 then
            p = p * (game.GetTimeScale() * 1.5)
            modified = true
        elseif host_timescale:GetFloat() ~= 1 then
            p = p * (host_timescale:GetFloat() * 1.5)
            modified = true
        end

        p = math.Clamp(p, 0, 255)
        data.Pitch = p

    end

    local ent = data.Entity

    if IsValid(ent) and ent:IsNPC() and string.sub(data.SoundName, 1, 16):iequals("player/footsteps") and self:NPCFootstep(ent, data) == false then
        return false
    end

    return modified

end
