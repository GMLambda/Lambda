AddCSLuaFile()

local DbgPrint = GetLogging("Ragdoll")

ENT.Base = "base_anim"
ENT.Type = "anim"

function ENT:Initialize()
    self:SetNoDraw(true)
    self:DrawShadow(false)
end

function ENT:AttachToNPC(npc)

    local mdl = npc:GetModel()
    if mdl == nil then
        return
    end

    self.NPC = npc

    local rag = ents.Create("prop_ragdoll")
    rag:SetModel(npc:GetModel() or "")
    rag:SetPos(npc:GetPos())
    --rag:SetParent(npc)
    --rag:AddEffects(EF_BONEMERGE)
    rag:SetMoveType(MOVETYPE_VPHYSICS)
    rag:Spawn()
    rag:AddDebugOverlays(OVERLAY_PROP_DEBUG)
    rag:SetCustomCollisionCheck(true)

    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            phys:SetMaterial("armorflesh")
            phys:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
        end
        phys:EnableMotion(false)
    end

    self.Ragdoll = rag
end

function ENT:Think()
    if SERVER then
        if not IsValid(self.NPC) then
            return
        end
        local npc = self.NPC
        local rag = self.Ragdoll
        for i = 0, npc:GetBoneCount() - 1 do
            local pos, ang = npc:GetBonePosition(i)

            local physNum = rag:TranslateBoneToPhysBone(i)
            local phys2 = rag:GetPhysicsObjectNum(physNum)

            --phys2:Sleep()
            rag:SetRagdollPos(i, pos)
            rag:SetRagdollAng(i, ang)
        end

        rag:RagdollSolve()
    else
        debugoverlay.Box(self:GetPos(), self:OBBMins(), self:OBBMaxs(), FrameTime(), Color(128, 128, 128, 20))
    end
end

function ENT:TestCollision( startpos, delta, isbox, extents )
    if not isbox then
        return
    end
    return
    {
        HitPos          = self:GetPos(),
        Fraction        = 0.0
    }
end

function ENT:OnRemove()
end

if CLIENT then

    function ENT:Draw()
        self:DrawModel()
    end

end
