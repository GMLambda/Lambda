if SERVER then
    AddCSLuaFile()
end

--local DbgPrint = print
local DbgPrint = GetLogging("EnvZoom")

-- Spawnflags
local ENV_ZOOM_OVERRIDE = 1

ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS("lambda_entity")

local vec3_origin = Vector(0, 0, 0)

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")

    self:SetInputFunction("Zoom", self.Zoom)
    self:SetInputFunction("UnZoom", self.UnZoom)

    self:SetupNWVar("Rate", "float", { Default = 1.0, KeyValue = "Rate" })
    self:SetupNWVar("FOV", "int", { Default = 75, KeyValue = "FOV" })
    self:SetupNWVar("AllPlayers", "bool", { Default = true, KeyValue = "AllPlayers" })

    self.ActivePlayers = {}
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")

    self:NextThink(CurTime())

end

function ENT:OnRemove()
    self:UnZoom()
end

function ENT:Think()

    if CLIENT then
        return
    end

    if self:MaintainPlayers() == false then
        return
    end

    self:NextThink(CurTime())
    return true

end

function ENT:MaintainPlayers()

    for k, data in pairs(self.ActivePlayers) do
        local ply = data.Player

         -- Remove invalid players.
        if not IsValid(ply) then
            table.remove(self.ActivePlayers, k)
            continue
        end

        if self:HasSpawnFlags(ENV_ZOOM_OVERRIDE) == true then
            local curButtons = ply:GetButtons()
            local changed = bit.bxor(curButtons, data.Buttons)

            if changed ~= 0 and curButtons == IN_ZOOM then
                self:RestorePlayer(ply, data)
                table.remove(self.ActivePlayers, k)
            end

            data.Buttons = curButtons
        end
    end

    if #self.ActivePlayers == 0 then
        self:UnZoom()
        return false
    end

    return true

end

function ENT:GetPlayerRestoreData(ply)
    for _,data in pairs(self.ActivePlayers) do
        if data.Player == ply then
            return data
        end
    end
    return nil
end

function ENT:RestorePlayer(ply)

    if not IsValid(ply) then
        return
    end

    DbgPrint(self, "Restoring player FOV " .. tostring(ply))

    ply:SetFOV(90, restoreData.Rate)

end

function ENT:RemovePlayerFromControl(ply)

    for k,restoreData in pairs(self.ActivePlayers) do
        if restoreData.Player ~= ply then
            continue
        end

        self:RestorePlayer(ply)

        table.remove(self.ActivePlayers, k)
        return true

    end

    DbgPrint(self, "Failed to restore player " .. tostring(ply))
    return false

end

function ENT:BeginZoom(ply)

    local plys = {}

    if ply == nil and self.AllPlayers == true then
        plys = player.GetAll()
    elseif IsValid(ply) then
        plys = { ply }
    end

    if #plys == 0 then
        return
    end

    self.Rate = self:GetNWVar("Rate")
    self.FOV = self:GetNWVar("FOV")

    for _, v in pairs(plys) do
        v:SetFOV(self.FOV, self.Rate)
    end
    
end

function ENT:Zoom(data, activator, caller)
    DbgPrint(self, "Zoom", data, activator, caller)

    local ply = nil

    -- This should apply to the env_zoom as well most likely, copy pasta
    -- HACKHACK: d2_coast_03 uses func_door to relay the input.
    if IsValid(activator) and activator:GetClass() == "func_door" then
        ply = activator:GetInternalVariable("m_hActivator")
    end

    if not IsValid(ply) and IsValid(activator) and activator:IsPlayer() then
        ply = activator
    end

    if not IsValid(ply) and IsValid(caller) and caller:IsPlayer() then
        ply = caller
    end

	self.AllPlayers = self:GetNWVar("AllPlayers")
    self:BeginZoom(ply)

    return true
end

function ENT:UnZoom()
    DbgPrint(self, "UnZoom")
    
    for k, restoreData in pairs(self.ActivePlayers) do
        self:RestorePlayer(restoreData.Player)
    end
    self.ActivePlayers = {}

    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end
