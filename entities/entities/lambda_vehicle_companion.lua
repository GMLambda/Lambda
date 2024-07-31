local DbgPrint = GetLogging("Vehicle")

ENT.Base = "lambda_entity"
ENT.Type = "point"
DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetInputFunction("OnPlayerVehicleEnter", self.InputOnPlayerVehicleEnter)
    self:SetInputFunction("OnPlayerVehicleExit", self.InputOnPlayerVehicleExit)
    self:SetupNWVar(
        "CompanionName",
        "string",
        {
            Default = "",
            KeyValue = "CompanionName"
        }
    )
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
end

local function IsEntityInVehicle(ent)
    if not IsValid(ent) then
        return false
    end

    if ent:IsPlayer() then
        return ent:InVehicle()
    end

    if ent:IsNPC() then
        -- This is a bit akward.
        local parent = ent:GetParent()
        if IsValid(parent) and parent:IsVehicle() then
            return true
        end
    end

    return false
end

local function IsEntityBusy(ent)
    if not IsValid(ent) then
        return false
    end

    if ent:IsNPC() then
        local npcState = ent:GetNPCState()
        if npcState == NPC_STATE_SCRIPT or npcState == NPC_STATE_DEAD or npcState == NPC_STATE_PLAYDEAD then
            return true
        end
    end

    return false
end

function ENT:InputOnPlayerVehicleEnter(data, activator, caller)
    DbgPrint(self, "InputOnPlayerVehicleEnter", tostring(data), tostring(activator), tostring(caller))

    local passenger = GAMEMODE:VehicleGetPassenger(caller)
    if IsValid(passenger) then
        -- Already holds a passenger.
        DbgPrint("Vehicle already has a passenger")
        return
    end

    local companionName = self:GetNWVar("CompanionName")
    local closest = nil
    local closestDist = 999999
    for _, v in pairs(ents.FindByName(companionName)) do
        local dist = v:GetPos():Distance(caller:GetPos())
        if dist < closestDist then
            closest = v
            closestDist = dist
        end
    end

    if not IsValid(closest) then
        DbgPrint("Unable to find companion '" .. companionName .. "'")
        return
    end

    if IsEntityInVehicle(closest) then
        DbgPrint("Companion is already in a vehicle")
        return
    end

    if IsEntityBusy(closest) then
        DbgPrint("Companion is busy")
        return
    end

    local oldName = activator:GetName()
    local newName = "lambda_vehicle_companion_" .. tostring(activator:EntIndex())
    caller:SetName(newName)
    DbgPrint("Requesting '" .. companionName .. "' to enter vehicle")
    closest:Input("EnterVehicle", activator, self, newName)
    caller:SetName(oldName)
end

function ENT:InputOnPlayerVehicleExit(data, activator, caller)
    DbgPrint(self, "InputOnPlayerVehicleExit", tostring(data), tostring(activator), tostring(caller))
    if not IsValid(caller) or not IsValid(activator) then
        return
    end

    -- Check if the vehicle has a NPC companion.
    local passenger = GAMEMODE:VehicleGetPassenger(caller)
    if not IsValid(passenger) then
        return
    end

    DbgPrint("Requesting companion to leave vehicle.")
    passenger:Input("ExitVehicle", activator, self)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_NEVER
end

function ENT:OnRemove()
    DbgPrint(self, "OnRemove")
end