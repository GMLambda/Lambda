if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Vehicle")
local CurTime = CurTime
local Vector = Vector
local util = util
local math = math
local IsValid = IsValid
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    if CLIENT then
        -- I know this seems insane but otherwise it would clip the purpose.
        self:SetRenderBounds(Vector(-10000, -10000, -10000), Vector(10000, 10000, 10000))
        self:SetRenderMode(RENDERMODE_GLOW)
    end

    self:DrawShadow(false)
    --self:AddEffects(EF_NODRAW)
end

function ENT:AttachToVehicle(vehicle)
    self:SetModel(vehicle:GetModel())
    self:SetPos(vehicle:GetPos())
    self:SetAngles(vehicle:GetAngles())
    self:SetParent(vehicle)
    --self:AddEffects(EF_NODRAW)
    self:DrawShadow(false)
    self.Vehicle = vehicle
    self.Player = vehicle.LambdaPlayer
    self:SetNWEntity("LambdaVehicleOwner", self.Player)
    self:SetNWBool("LambdaVehicleTaken", IsValid(self.Player))
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

if SERVER then
    function ENT:Think()
        local vehicle = self:GetParent()

        if not IsValid(vehicle) then
            self:Remove()

            return
        end

        if self.Player ~= vehicle.LambdaPlayer then
            self.Player = vehicle.LambdaPlayer
            self:SetNWEntity("LambdaVehicleOwner", self.Player)
            self:SetNWBool("LambdaVehicleTaken", IsValid(self.Player))
            DbgPrint("Owner changed")
        end

        self:NextThink(CurTime() + 0.1)

        return true
    end
elseif CLIENT then
    local LocalPlayer = LocalPlayer
    local EyePos = EyePos
    local EyeAngles = EyeAngles
    local render = render

    surface.CreateFont("LAMBDA_1_VEHICLE", {
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

    surface.CreateFont("LAMBDA_2_VEHICLE", {
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

    local function IsVehicleBehind(vehicle)
        local dir = (vehicle:GetPos() - EyePos()):GetNormal()
        local dot = dir:Dot(EyeAngles():Forward())
        if dot < 0 then return true end

        return false
    end

    local VEHICLE_MAT = Material("lambda/vehicle.vmt")

    local function GetTextColor()
        local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")

        return Vector(col.x / 255, col.y / 255, col.z / 255)
    end

    local function GetBGColor()
        local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")

        return Vector(col.x / 255, col.y / 255, col.z / 255)
    end

    function ENT:RenderVehicleStatus(alpha, haveVehicle, isTaken, belongsToUs, owner)
        local vehicle = self:GetParent()
        render.SuppressEngineLighting(true)
        local offset = Vector(0, 0, 100 + (math.sin(self:EntIndex() + (CurTime() * 5)) * 10))
        local pos = vehicle:GetPos() + offset
        local ang = (pos - EyePos()):Angle()
        local signsize = 24
        local colorBg = GetBGColor()
        local textColor = GetTextColor()
        local text = ""

        if belongsToUs == true then
            text = "Your Vehicle"
        elseif isTaken == false then
            if haveVehicle == true then
                text = "Reserved Vehicle"
                alpha = alpha * 0.08
            else
                text = "Available Vehicle"
            end
        elseif isTaken == true then
            local ownerName = "???"

            if IsValid(owner) then
                ownerName = owner:GetName()
            end

            text = "Vehicle belongs to " .. ownerName
            alpha = alpha * 0.08
        end

        ang:Normalize()
        cam.IgnoreZ(true)
        VEHICLE_MAT:SetVector("$tint", textColor)
        VEHICLE_MAT:SetFloat("$alpha", alpha)
        render.SetMaterial(VEHICLE_MAT)
        render.DrawQuadEasy(pos, -ang:Forward(), signsize, signsize, Color(255, 255, 255, 255), 180)
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        colorBg = Color(colorBg.x * 255, colorBg.y * 255, colorBg.z * 255, alpha * 255)
        textColor = Color(textColor.x * 255, textColor.y * 255, textColor.z * 255, alpha * 255)
        cam.Start3D2D(pos - Vector(0, 0, 13), ang, 0.1)
        draw.DrawText(text, "LAMBDA_1_VEHICLE", 0, 0, colorBg, TEXT_ALIGN_CENTER)
        draw.DrawText(text, "LAMBDA_2_VEHICLE", 0, 0, textColor, TEXT_ALIGN_CENTER)
        cam.End3D2D()
        cam.IgnoreZ(false)
        render.SuppressEngineLighting(false)
    end

    function ENT:Draw()
        local vehicle = self:GetParent()
        if not IsValid(vehicle) then return end
        local pos = self:GetPos() + self:OBBCenter() + Vector(0, 0, 50)
        local localPly = LocalPlayer()
        local plyVeh = localPly:GetVehicle()
        if IsValid(plyVeh) then return end
        local plyPos = localPly:GetPos()
        local alphaDist = 1.0 - (plyPos:Distance(pos) / 1500)
        if alphaDist <= 0.0 then return end
        if IsVehicleBehind(vehicle) then return end -- Dont bother
        local ownedVehicle = localPly:GetNWEntity("LambdaOwnedVehicle")
        local isVehicleTaken = self:GetNWBool("LambdaVehicleTaken")
        local vehicleOwner = self:GetNWEntity("LambdaVehicleOwner")
        local belongsToUs = false

        if IsValid(ownedVehicle) and IsValid(vehicleOwner) then
            if ownedVehicle == vehicle then
                -- Owned by us.
                belongsToUs = true
            else
                -- Owned by another player.
                belongsToUs = false
            end
        end

        if IsValid(vehicleOwner) and vehicleOwner:GetVehicle() == vehicle then return end -- If the owner is inside the vehicle don't render anything.
        self:RenderVehicleStatus(alphaDist, IsValid(ownedVehicle), isVehicleTaken, belongsToUs, vehicleOwner)
    end

    function ENT:DrawTranslucent()
        self:Draw()
    end
end