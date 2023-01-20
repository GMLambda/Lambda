if SERVER then
    AddCSLuaFile()
end

local CurTime = CurTime
local Vector = Vector
local util = util
local math = math
ENT.Base = "lambda_entity"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
DEFINE_BASECLASS("lambda_entity")

function ENT:PreInitialize()
    DbgPrint(self, "ENT:PreInitialize")
    BaseClass.PreInitialize(self)
end

function ENT:Initialize()
    BaseClass.Initialize(self)

    if CLIENT then
        self:SetRenderBounds(Vector(-150, -150, -150), Vector(150, 150, 150))
        self:SetRenderMode(RENDERMODE_GLOW)
    end

    self:DrawShadow(false)
    self:Reset()
end

function ENT:Reset()
    self:RemoveEffects(EF_NODRAW)
    self:RemoveEFlags(EFL_DORMANT)
    self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT + EFL_NOTIFY)
    self.Alpha = 1
    self.Dist = 0
    self.Inactive = true
    self.ActivationTime = 0
    self.Rotation = 0
    self.Delta = 0
    self.LastUpdate = CurTime()
    self:SetNWBool("Activated", false)
    self:Activate()
end

local MAT = Material("lambda/checkpoint.vmt")
local OFFSET_Z = Vector(0, 0, 60)

function ENT:DoSpinEffects()
    if not SERVER then return end
    if math.random() < 0.1 then return end
    local pos = self:GetEffectPos()
    local ef = EffectData()
    ef:SetOrigin(pos)
    ef:SetEntity(self)
    ef:SetStart(pos)
    ef:SetMagnitude(0.2)
    ef:SetScale(1)
    ef:SetRadius(20)
    util.Effect("Sparks", ef)
end

function ENT:DoFinishEffects()
    if not SERVER then return end
    local pos = self:GetEffectPos()
    local ef = EffectData()
    ef:SetOrigin(pos)
    ef:SetEntity(self)
    ef:SetStart(pos)
    util.Effect("cball_explode", ef)
    ef = EffectData()
    ef:SetOrigin(pos)
    ef:SetEntity(self)
    ef:SetStart(pos)
    ef:SetMagnitude(5)
    ef:SetScale(1)
    ef:SetRadius(50)
    util.Effect("Sparks", ef)
    ef = EffectData()
    ef:SetOrigin(pos)
    ef:SetEntity(self)
    ef:SetStart(pos)
    ef:SetMagnitude(100)
    ef:SetScale(20)
    ef:SetRadius(100)
    util.Effect("ThumperDust", ef)
    self:EmitSound("ambient/machines/thumper_dust.wav")
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Think()
    if self:GetDynamicCheckpoint() == true then return end
    local curTime = CurTime()
    local dt = curTime - self.LastUpdate
    self.LastUpdate = curTime

    if self:IsEffectActive(EF_NODRAW) == false then
        if self.Inactive == true and self:GetActivated() == true then
            self.Inactive = false
            self.ActivationTime = CurTime()
            self.FadeScale = 0
            self.Delta = 0.5
        elseif self.Inactive == false and self:GetActivated() == true then
            self.Delta = self.Delta + (3 * dt)
            self.Rotation = self.Rotation + self.Delta
            self:DoSpinEffects()

            if self.Delta >= 6 then
                self:DoFinishEffects()

                if SERVER then
                    self:AddEffects(EF_NODRAW)
                end

                return
            end
        elseif self.Inactive == false and self:GetActivated() == false then
            self:Reset()
        else
            self.Dist = math.sin(CurTime() * 5) * 5
            self.Rotation = math.sin(CurTime() * 1.4) * 30
        end
    end

    if CLIENT and self:IsEffectActive(EF_NODRAW) == false then
        self:SetRenderBoundsWS(self:GetVisiblePos(), self:GetVisiblePos(), Vector(300, 300, 300))
    end

    if SERVER then
        self:NextThink(CurTime())
    else
        self:SetNextClientThink(CurTime())
    end
end

function ENT:SetVisiblePos(pos)
    self:SetNWVector("VisiblePos", pos)
end

function ENT:GetVisiblePos()
    return self:GetNWVector("VisiblePos", self:GetPos())
end

function ENT:SetDynamicCheckpoint(dynamic)
    self:SetNWBool("DynamicCheckpoint", dynamic)
end

function ENT:GetDynamicCheckpoint()
    return self:GetNWBool("DynamicCheckpoint", true)
end

function ENT:SetActivated()
    self:SetNWBool("Activated", true)
end

function ENT:GetActivated()
    return self:GetNWBool("Activated", false)
end

function ENT:GetEffectPos()
    local pos = self:GetVisiblePos() + OFFSET_Z + (Vector(0, 0, self.Dist))

    return pos
end

local function GetTextColor()
    local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")

    return Vector(col.x / 255, col.y / 255, col.z / 255)
end

local function GetBGColor()
    local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")

    return Vector(col.x / 255, col.y / 255, col.z / 255)
end

if CLIENT then
    surface.CreateFont("LAMBDA_1_CP", {
        font = "Arial",
        size = 66,
        weight = 600,
        blursize = 10,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = true,
        additive = false,
        outline = true
    })

    surface.CreateFont("LAMBDA_2_CP", {
        font = "Arial",
        size = 66,
        weight = 600,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false
    })
end

function ENT:Draw(flags)
    if self:GetDynamicCheckpoint() == true then return end

    if self:GetActivated() == false and self.Inactive == false then
        -- HACKHACK: For some reason Think is not called after a while.
        self:SetNextClientThink(CurTime())
    end

    local pos = self:GetEffectPos()
    local ang = (pos - EyePos()):Angle() + Angle(0, self.Rotation, 0)
    local signsize = 24
    ang:Normalize()
    --cam.IgnoreZ(true)
    MAT:SetVector("$tint", GetTextColor())
    render.SetMaterial(MAT)
    render.DrawQuadEasy(pos, -ang:Forward(), signsize, signsize, Color(255, 255, 255, 255), 180)
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    local colorBg = GetBGColor()
    local textColor = GetTextColor()
    colorBg = Color(colorBg.x * 255, colorBg.y * 255, colorBg.z * 255)
    textColor = Color(textColor.x * 255, textColor.y * 255, textColor.z * 255)
    cam.Start3D2D(pos - Vector(0, 0, 13), ang, 0.1)
    local text = "CHECKPOINT"
    draw.DrawText(text, "LAMBDA_1_CP", 0, 0, colorBg, TEXT_ALIGN_CENTER)
    draw.DrawText(text, "LAMBDA_2_CP", 0, 0, textColor, TEXT_ALIGN_CENTER)
    cam.End3D2D()
    --cam.IgnoreZ(false)
end

function ENT:DrawTranslucent(flags)
    self:Draw()
end