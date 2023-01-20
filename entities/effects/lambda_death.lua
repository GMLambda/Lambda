EFFECT.Mat1 = Material("lambda/death_point.vmt")

surface.CreateFont("LAMBDA_1_PN", {
    font = "Arial",
    size = 24,
    weight = 1000,
    antialias = true,
    additive = false
})

local math_Clamp = math.Clamp
local CurTime = CurTime
local FrameTime = FrameTime
local IsValid = IsValid
local render = render
local cam = cam

function EFFECT:Init(data)
    local size = 64
    local ply = data:GetEntity()

    if not IsValid(ply) then
        self:Remove()
    end

    self:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))
    self:SetAngles(data:GetNormal():Angle() + Angle(0.01, 0.01, 0.01))
    self.Pos = data:GetOrigin()
    self.Normal = data:GetNormal()
    self.Alpha = 1
    self.Player = ply
    self.Direction = data:GetScale()
    self.Size = data:GetRadius()
    self.Axis = data:GetOrigin()
    self.Dist = 0
    self:SetPos(data:GetOrigin())
    self.PlayerName = ply:Nick()
end

function EFFECT:Think()
    local speed = FrameTime()
    if not IsValid(self.Player) then return false end
    if self.Player:Alive() then return false end
    self.Alpha = self.Alpha - speed * 0.08
    self.Dist = math.sin(self:EntIndex() + (CurTime() * 5)) * 5
    if (self.Alpha < 0) then return false end

    return true
end

function EFFECT:Render()
    if (self.Alpha < 0) then return end
    render.SuppressEngineLighting(true)
    local Normal = self.Normal
    local eyePos = EyePos()
    local entPos = self:GetPos()
    local dir = Normal:Angle()
    local ang = eyePos - entPos
    local dist = eyePos:Distance(entPos)
    local signsize = math_Clamp(dist / 20, self.Size / 2, self.Size * 5)
    local offset_z = math_Clamp(dist / 20, 50, 200)
    local textPos = math_Clamp(signsize / 2 + dist / 20, 10, 50)
    cam.IgnoreZ(true)
    cam.Start2D()
    local pos = entPos + (dir:Forward() * (offset_z + self.Dist + textPos))
    local scrPos = pos:ToScreen()
    draw.SimpleTextOutlined(self.PlayerName, "LAMBDA_1_PN", scrPos.x, scrPos.y, Color(100, 20, 20, self.Alpha * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, self.Alpha * 255 - 50))
    cam.End2D()
    self.Mat1:SetFloat("$alpha", ((self.Alpha ^ 1.1) * 255) / 255)
    render.SetMaterial(self.Mat1)
    render.DrawQuadEasy(entPos + (dir:Forward() * (offset_z + self.Dist)), ang, signsize, signsize, Color(255, 255, 255, (self.Alpha ^ 1.1) * 255), 180)
    cam.IgnoreZ(false)
    render.SuppressEngineLighting(false)
end