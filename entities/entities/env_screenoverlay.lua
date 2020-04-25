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

    self:PopulateTable()
end

function ENT:PopulateTable()
    for num_ov = 1,10 do 
        local tbl = {["OverlayName" .. tostring(num_ov)] = "", ["OverlayTime" .. tostring(num_ov)] = 0}
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

    if self.OverlayTable["OverlayTime1"] ~= OVERLAY_LOOP then
        self.NextSwitch = CurTime() + tonumber(self.OverlayTable["OverlayTime1"])
    else
        self.NextSwitch = 0
    end

    local ply = self:PropagatePlayerActivator(activator)
    if IsValid(ply) and ply:IsPlayer() then
        DbgPrint("Propagated Activator:", ply)
        self.Activator = ply
        GAMEMODE:StartScreenOverlay(self.OverlayTable["OverlayName1"], ply)
        ply:SetScreenOverlayOwner(self)
    elseif ply ~= activator then
        GAMEMODE:StartScreenOverlay(self.OverlayTable["OverlayName1"])
    end

    return true
end

function ENT:SwitchOverlay()
    DbgPrint(self, "SwitchOverlay", self.Activator, self.ActiveNum)

    if self.Activator then
        GAMEMODE:StopScreenOverlay(self.Activator)
    else
        GAMEMODE:StopScreenOverlay()
    end

    if self.Activator then
        GAMEMODE:StartScreenOverlay(self.OverlayTable["OverlayName" .. self.ActiveNum], self.Activator)
    else
        GAMEMODE:StartScreenOverlay(self.OverlayTable["OverlayName" .. self.ActiveNum])
    end

    if self.OverlayTable["OverlayTime" .. self.ActiveNum] == OVERLAY_LOOP then
        self.NextSwitch = false
    else
        self.NextSwitch = CurTime() + tonumber(self.OverlayTable["OverlayTime" .. self.ActiveNum])
    end

end

function ENT:StopOverlays(data, activator, caller)
    DbgPrint(self, "StopOverlays", activator, caller)

    if not self.Active then return end

    local ply = self:PropagatePlayerActivator(activator)
    if IsValid(ply) and ply:IsPlayer() and ply:GetScreenOverlayOwner()  and self.Activator == ply then
        DbgPrint("Propagated Activator:", ply)
        GAMEMODE:StopScreenOverlay(ply)
        ply:CleanScreenOverlayOwner()
        self.Activator = nil
        self.Active = false
        self.ActiveNum = 1
    elseif not ply:GetScreenOverlayOwner() and not self.Activator == activator then
        GAMEMODE:StopScreenOverlay()
        self.Active = false
        self.ActiveNum = 1
    end

    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

