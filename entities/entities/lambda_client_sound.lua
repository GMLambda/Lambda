if SERVER then
    AddCSLuaFile()
end

ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")
local MSG_PLAY_SOUND = 1
local MSG_STOP_SOUND = 2

if SERVER then
    util.AddNetworkString("lambda_client_sound_msg")
end

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    self:SetInputFunction("PlaySound", self.InputPlaySound)
    self:SetInputFunction("StopSound", self.InputStopSound)

    self:SetupNWVar("Sound", "string", {
        Default = "",
        KeyValue = "sound"
    })

    self:SetupNWVar("Pitch", "float", {
        Default = 100,
        KeyValue = "pitch"
    })
end

function ENT:Initialize()
    BaseClass.Initialize(self)
end

function ENT:KeyValue(key, val)
    BaseClass.KeyValue(self, key, val)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:InputPlaySound(data, activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        net.Start("lambda_client_sound_msg")
        net.WriteInt(MSG_PLAY_SOUND, 3)
        net.WriteEntity(self)
        net.WriteEntity(activator)
        net.Send(activator)
    end
end

function ENT:InputStopSound(data, activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        net.Start("lambda_client_sound_msg")
        net.WriteInt(MSG_STOP_SOUND, 3)
        net.WriteEntity(self)
        net.WriteEntity(activator)
        net.Send(activator)
    end
end

if CLIENT then
    function ENT:PlaySoundClient(activator)
        if not IsValid(activator) then return end
        local soundFile = self:GetNWVar("Sound", "")
        if soundFile == "" then return end
        local sndProps = sound.GetProperties(soundFile)
        if sndProps == nil then return end
        activator:EmitSound(soundFile, sndProps.level, sndProps.pitch, sndProps.volume, sndProps.channel)
    end

    function ENT:StopSoundClient(activator)
        if not IsValid(activator) then return end
        local soundFile = self:GetNWVar("Sound", "")
        if soundFile == "" then return end
        activator:StopSound(soundFile)
    end

    net.Receive("lambda_client_sound_msg", function()
        local msgType = net.ReadInt(3)
        local ent = net.ReadEntity()
        local activator = net.ReadEntity()

        if IsValid(ent) then
            if msgType == MSG_PLAY_SOUND then
                ent:PlaySoundClient(activator)
            elseif msgType == MSG_STOP_SOUND then
                ent:StopSoundClient(activator)
            end
        end
    end)
end