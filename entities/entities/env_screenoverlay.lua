if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("EnvScreenOverlay")
ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")
local OVERLAY_LOOP = "-1"

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetInputFunction("StartOverlays", self.StartOverlays)
    self:SetInputFunction("StopOverlays", self.StopOverlays)
    self:SetInputFunction("SwitchOverlay", self.SwitchOverlay)
    self.Active = false
    self.ActiveNum = 1
    self.OverlayTable = {}
    self.Activator = nil
    self.NextSwitch = 0
    self.ShouldStop = false
    self:PopulateTable()
end

function ENT:PopulateTable()
    for num_ov = 1, 10 do
        local tbl = {
            ["OverlayName" .. tostring(num_ov)] = "",
            ["OverlayTime" .. tostring(num_ov)] = 0
        }

        table.Merge(self.OverlayTable, tbl)
    end
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
    self:NextThink(CurTime())
end

function ENT:Think()
    if self.OverlayTable["OverlayTime" .. self.ActiveNum] == OVERLAY_LOOP then return end

    if self.Active and self.NextSwitch ~= false and CurTime() > self.NextSwitch then
        self.ActiveNum = self.ActiveNum + 1
        self:SwitchOverlay()
    end
end

function ENT:AcceptInput(fn, data, activator, caller)
    DbgPrint(self, "AcceptInput", fn, data, activator, caller)

    return BaseClass.AcceptInput(self, fn, data, activator, caller)
end

function ENT:KeyValue(key, val)
    BaseClass.KeyValue(self, key, val)

    if self.OverlayTable[tostring(key)] then
        self.OverlayTable[key] = val
    end
end

function ENT:StartOverlays(data, activator, caller)
    DbgPrint(self, "StartOverlays", activator, caller)
    self.Active = true

    local OverlayName = self.OverlayTable["OverlayName1"]
    local OverlayTime = self.OverlayTable["OverlayTime1"]

    if OverlayTime ~= OVERLAY_LOOP then
        self.NextSwitch = CurTime() + tonumber(OverlayTime)
    else
        self.NextSwitch = 0
    end

    local ply = self:PropagatePlayerActivator(activator)

    if IsValid(ply) and ply:IsPlayer() then
        DbgPrint("Propagated Activator:", ply)
        self.Activator = ply
        GAMEMODE:StartScreenOverlay(OverlayName, ply)
        ply:SetScreenOverlayOwner(self)
    elseif ply ~= activator then
        GAMEMODE:StartScreenOverlay(OverlayName)
    end

    return true
end

function ENT:SwitchOverlay()
    DbgPrint(self, "SwitchOverlay", self.Activator, self.ActiveNum)

    if self.ShouldStop then
        -- Timed out, we'll help player disable the overlay.
        self:StopOverlays(nil, self.Activator, self)
        return
    end

    if self.ActiveNum <= 10 then
        local OverlayName = self.OverlayTable["OverlayName" .. self.ActiveNum]
        local OverlayTime = self.OverlayTable["OverlayTime" .. self.ActiveNum]

        if OverlayName ~= "" then
            if self.Activator then
                GAMEMODE:StopScreenOverlay(self.Activator)
            else
                GAMEMODE:StopScreenOverlay()
            end

            if self.Activator then
                GAMEMODE:StartScreenOverlay(OverlayName, self.Activator)
            else
                GAMEMODE:StartScreenOverlay(OverlayName)
            end

            if OverlayTime == OVERLAY_LOOP then
                self.NextSwitch = false
            else
                self.NextSwitch = CurTime() + tonumber(OverlayTime)
            end
        else
            -- Keep showing the overlay just like original behavior, but with 20 sec timeout.
            self.ShouldStop = true
            self.NextSwitch = CurTime() + 20
        end
    else
        self.ShouldStop = true
        self.NextSwitch = CurTime() + 20
    end
end

function ENT:StopOverlays(data, activator, caller)
    DbgPrint(self, "StopOverlays", activator, caller)
    if not self.Active then return end
    local ply = self:PropagatePlayerActivator(activator)

    if IsValid(ply) and ply:IsPlayer() and ply:GetScreenOverlayOwner() and self.Activator == ply then
        DbgPrint("Propagated Activator:", ply)
        GAMEMODE:StopScreenOverlay(ply)
        ply:CleanScreenOverlayOwner()
        self.Activator = nil
        self.Active = false
        self.ActiveNum = 1
        self.ShouldStop = false
    elseif self.Activator ~= activator or self.Activator == nil then
        GAMEMODE:StopScreenOverlay()
        self.Active = false
        self.ActiveNum = 1
        self.ShouldStop = false
    end

    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end
