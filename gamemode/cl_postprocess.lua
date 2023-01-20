--local DbgPrint = GetLogging("PostProcess")
local CurTime = CurTime
local Vector = Vector
local math = math
local IsValid = IsValid
GRAIN_RT = GRAIN_RT or GetRenderTarget("LambdaFilmGrain", ScrW(), ScrH(), true)

GRAIN_MAT = GRAIN_MAT or CreateMaterial("LambdaFilmGrain" .. CurTime(), "UnlitGeneric", {
    ["$alpha"] = 1,
    ["$translucent"] = 1,
    ["$basetexture"] = "models/debug/debugwhite",
    Proxies = {
        TextureScroll = {
            texturescrollvar = "$basetexturetransform",
            texturescrollrate = 10,
            texturescrollangle = 40
        }
    }
})

GRAIN_SETUP = GRAIN_SETUP or false

-- FIXME: Use a static texture instead.
local function GenerateFilmGrain()
    if GRAIN_SETUP == true then return end
    GRAIN_SETUP = true
    render.PushRenderTarget(GRAIN_RT)
    render.Clear(0, 0, 0, 1, true, true)
    surface.SetDrawColor(0, 50, 0, 100)
    cam.Start2D()

    for y = 0, ScrH() do
        for x = 0, ScrW() do
            local a = math.random(0, 5)

            if a == 0 then
                surface.DrawLine(x, y, x + 2, y + 2)
            end
        end
    end

    cam.End2D()
    render.BlurRenderTarget(GRAIN_RT, 0.01, 0.01, 1)
    render.PopRenderTarget()
    GRAIN_MAT:SetTexture("$basetexture", GRAIN_RT)
end

local LAST_GEIGER_RANGE = 1000

local RADIATION_COLOR_MOD = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 1.0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

function GM:RenderRadiationEffects(ply)
    GenerateFilmGrain()
    local curGeigerRange = math.Clamp(ply:GetGeigerRange() * 4, 0, 1000)
    local geigerRange = Lerp(FrameTime(), LAST_GEIGER_RANGE, curGeigerRange)
    LAST_GEIGER_RANGE = geigerRange
    local rv = LAST_GEIGER_RANGE / 1000
    local iv = 1 - rv
    GRAIN_MAT:SetFloat("$alpha", iv)
    render.SetMaterial(GRAIN_MAT)
    render.DrawScreenQuad()
    RADIATION_COLOR_MOD["$pp_colour_mulg"] = iv * 3
    DrawColorModify(RADIATION_COLOR_MOD)
end

function GM:RenderSprintEffect(ply)
    self.TargetMotionBlur = self.TargetMotionBlur or 0.0
    local vel = Vector(0, 0, 0)

    if ply:InVehicle() then
        local veh = ply:GetVehicle()

        if IsValid(veh) then
            vel = veh:GetVelocity()
        end
    else
        vel = ply:GetVelocity()
    end

    local len = vel:Length2DSqr()
    local amount = 0

    if len > 1 then
        amount = math.log(len * len)
    end

    self.TargetMotionBlur = math.Approach(self.TargetMotionBlur, 5 + amount, RealFrameTime() * 15)
    DrawToyTown(1, self.TargetMotionBlur * 5)
end

function GM:RenderScreenspaceEffects()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if lambda_postprocess:GetBool() == false then return end
    self:RenderRadiationEffects(ply)
    self:RenderSprintEffect(ply)
end

function GM:PreDrawSkyBox()
end

function GM:PostDrawSkyBox()
end

function GM:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
end

function GM:PostDrawOpaqueRenderables(bDrawingDepth, bDrawingSkybox)
end

function StartMaterialOverlay(mat)
    hook.Add("RenderScreenspaceEffects", "ScreenOverlay", function()
        DrawMaterialOverlay(mat, 0)
    end)
end

function StopMaterialOverlay()
    hook.Remove("RenderScreenspaceEffects", "ScreenOverlay")
end

net.Receive("LambdaPlayerMatOverlay", function()
    local state = net.ReadBool()
    local mat

    if state ~= false then
        mat = net.ReadString()
        StartMaterialOverlay(mat)
    else
        StopMaterialOverlay()
    end
end)