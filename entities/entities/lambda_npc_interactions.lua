local CurTime = CurTime
local util = util
local IsValid = IsValid

ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
end

local COND_SEE_PLAYER = 32

function ENT:LinkNPC(npc)
    self:SetPos(npc:GetPos())
    self:SetOwner(npc)
    self:SetParent(npc)
    npc:CallOnRemove("LambdaNPCInteractor", function()
        self:Remove()
    end)
end

function ENT:SearchForInteractTargets()
    local owner = self:GetOwner()
    if not IsValid(owner) then
        return
    end

    local visible = {}
    for _,v in pairs(util.GetAllPlayers()) do
        if v:Alive() == false then
            continue
        end
        if owner:Visible(v) then
            table.insert(visible, v)
        end
    end

    if #visible == 0 then
        owner:ClearCondition(COND_SEE_PLAYER)
        return
    else
        owner:SetCondition(COND_SEE_PLAYER)
    end

    for _,v in pairs(visible) do
        local wep = v:GetActiveWeapon()
        if IsValid(wep) == false or wep:GetClass() ~= "weapon_physcannon" then
            continue
        end
        local heldObject = wep:GetAttachedObject()
        if IsValid(heldObject) then
            owner:SetSaveValue("m_hHackTarget", heldObject)
        end
    end

end

function ENT:Think()
    self:NextThink(CurTime() + 1)
    self:SearchForInteractTargets()
    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_NEVER
end
