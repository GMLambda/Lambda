if SERVER then
    AddCSLuaFile()
end

--local DbgPrint = print
local DbgPrint = GetLogging("EnvZoom")
local CurTime = CurTime
local player = player
local IsValid = IsValid
-- Spawnflags
local ENV_ZOOM_OVERRIDE = 1
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetInputFunction("Zoom", self.Zoom)
    self:SetInputFunction("UnZoom", self.UnZoom)
    self.Rate = 1
    self.FOV = 0
    self.ActivePlayers = {}
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
    self:NextThink(CurTime())
end

function ENT:Think()
end

function ENT:AcceptInput(fn, data, activator, caller)
    DbgPrint(self, fn, data, activator, caller)
    BaseClass.AcceptInput(self, fn, data, activator, caller)
end

function ENT:KeyValue(key, val)
    BaseClass.KeyValue(self, key, val)

    if key:iequals("rate") then
        self.Rate = val
    elseif key:iequals("fov") then
        self.FOV = val
    end
end

function ENT:ZoomPlayer(ply)
    -- If there is a previous one, remove player from it.
    local fovOwner = ply:GetFOVOwner()
    local data

    if IsValid(fovOwner) then
        -- HL2 Zoom.
        if fovOwner == ply then
            ply:StopZooming()
        elseif fovOwner:GetClass() == "env_zoom" then
            data = fovOwner:UnZoomPlayer(ply, nil, true)
            ply:ClearZoomOwner()
        end
    end

    if data == nil then
        data = {}
        data.Player = ply
        data.FOV = ply:GetFOV()
        data.FOVOwner = ply:GetFOVOwner()
        data.LambdaFOVOwner = ply.LambdaFOVOwner
    end

    DbgPrint("Zoom player " .. tostring(ply) .. " fov: " .. tostring(self.FOV) .. " rate: " .. tostring(self.Rate))
    ply:SetFOV(self.FOV, self.Rate)
    ply:SetFOVOwner(self)
    table.insert(self.ActivePlayers, data)
end

function ENT:UnZoomPlayer(ply, data, isExchange)
    if data == nil then
        for k, v in pairs(self.ActivePlayers) do
            if v.Player == ply then
                data = v
                table.remove(self.ActivePlayers, k)
                break
            end
        end

        if data == nil then return end
    end

    DbgPrint(self, "Restoring player " .. tostring(ply), data.FOV, data.FOVOwner)

    if IsValid(ply) then
        if isExchange ~= true then
            ply:ClearZoomOwner()
        end

        ply:SetFOV(0, 0)
        ply:SetFOVOwner(data.FOVOwner)
    end

    return data
end

function ENT:Zoom(data, activator, caller)
    DbgPrint(self, "Zoom", activator, caller)
    -- HACKHACK: d2_coast_03 uses func_door to relay the input.
    activator = self:PropagatePlayerActivator(activator)
    DbgPrint("Propagated Activator", activator)

    if IsValid(activator) and activator:IsPlayer() then
        self:ZoomPlayer(activator)
    else
        -- We can currently only assume this is supposed to zoom everyone.
        for _, v in pairs(player.GetAll()) do
            if v:Alive() == false then continue end
            self:ZoomPlayer(v)
        end
    end

    return true
end

function ENT:UnZoom(data, activator, caller)
    DbgPrint(self, "UnZoom", activator, caller)
    -- HACKHACK: d2_coast_03 uses func_door to relay the input.
    activator = self:PropagatePlayerActivator(activator)
    DbgPrint("Propagated Activator", activator)

    if IsValid(activator) and activator:IsPlayer() then
        self:UnZoomPlayer(activator)
    else
        -- We can currently only assume this is supposed to unzoom everyone.
        for _, v in pairs(self.ActivePlayers) do
            self:UnZoomPlayer(v.Player, v)
        end

        self.ActivePlayers = {}
    end

    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end