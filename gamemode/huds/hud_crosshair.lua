function GM:GetCrosshairColor()
    local color = util.StringToType(lambda_crosshair_color:GetString(), "vector")

    if color == nil then
        lambda_crosshair_color:SetString("0 128 0")
        color = Vector(0, 128, 0)
    end

    return color
end

function GM:SetCrosshairColor(color)
    local str = tostring(color.r) .. " " .. tostring(color.g) .. " " .. tostring(color.b)
    lambda_crosshair_color:SetString(str)
end

function GM:ShouldDrawCrosshair()
    local ply = LocalPlayer()
    local viewlock = ply:GetViewLock()
    if viewlock == VIEWLOCK_SETTINGS_ON or viewlock == VIEWLOCK_SETTINGS_RELEASE then return false end
    if ply:GetViewEntity() ~= ply then return false end

    if ply:Alive() == true and ply:InVehicle() == true then
        local veh = ply:GetVehicle()
        if veh:GetClass() == "prop_vehicle_jeep" or veh:GetClass() == "prop_vehicle_airboat" then return false end
    end

    local wep = ply:GetActiveWeapon()
    if wep == nil or wep == NULL then return false end

    return true
end

function GM:GetCrosshairMaterial(w, h, bgcolor)
    local rt = GetRenderTarget("LambdaCrosshairRT", w, h, false)
    local scrW, scrH = ScrW(), ScrH()
    bgcolor = bgcolor or Color(0, 0, 0, 0)
    render.PushRenderTarget(rt)
    render.Clear(bgcolor.r, bgcolor.g, bgcolor.b, bgcolor.a, true, true)
    render.ClearDepth()
    cam.Start2D()
    render.SetViewPort(0, 0, w, h)
    surface.SetDrawColor(255, 255, 255)
    surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
    self:DrawDynamicCrosshair(true)
    cam.End2D()
    render.PopRenderTarget()
    render.SetViewPort(0, 0, scrW, scrH)

    local mat = CreateMaterial("LambdaCrosshairMat", "UnlitGeneric", {
        ["$alpha"] = 1,
        ["$translucent"] = 1,
        ["$basetexture"] = "models/debug/debugwhite"
    })

    mat:SetTexture("$basetexture", rt)

    return mat
end

function GM:DrawDynamicCrosshair(inRT)
    local size = lambda_crosshair_size:GetInt()
    local width = lambda_crosshair_width:GetInt()
    local space = lambda_crosshair_space:GetInt()
    local adaptive = lambda_crosshair_adaptive:GetBool()
    local color = self:GetCrosshairColor()
    local alpha = lambda_crosshair_alpha:GetInt()
    local dynamic = lambda_crosshair_dynamic:GetBool()
    local ply = LocalPlayer()
    local movementRecoil = 0

    if dynamic == true and IsValid(ply) then
        if inRT == true then
            local t = CurTime() * 2
            movementRecoil = 1 + (math.sin(t) * math.cos(t))
        else
            movementRecoil = ply.MovementRecoil or 0
        end

        local gap = 15 * movementRecoil
        space = space + gap
    end

    local scrH = ScrH()
    local scrW = ScrW()
    local centerX = (scrW / 2)
    local centerY = (scrH / 2)
    local sizeH = size / 2

    if lambda_crosshair_outline:GetBool() == true then
        surface.SetDrawColor(0, 0, 0, alpha)
        -- Top to center.
        surface.DrawOutlinedRect(centerX - (width / 2) - 1, centerY - sizeH - space - 1, width + 2, sizeH + 2)
        -- Left to center.
        surface.DrawOutlinedRect(centerX - sizeH - space - 1, centerY - (width / 2) - 1, sizeH + 2, width + 2)
        -- Center to bottom.
        surface.DrawOutlinedRect(centerX - (width / 2) - 1, centerY + space - 1, width + 2, sizeH + 2)
        -- Center to right.
        surface.DrawOutlinedRect(centerX + space - 1, centerY - (width / 2) - 1, sizeH + 2, width + 2)
    end

    render.OverrideAlphaWriteEnable(true, true)

    if inRT == true then
        adaptive = false
    end

    render.OverrideBlendFunc(adaptive, BLEND_ONE_MINUS_DST_COLOR, BLEND_ONE_MINUS_DST_COLOR)
    surface.SetDrawColor(color.x, color.y, color.z, alpha)
    -- Top to center.
    surface.DrawRect(centerX - (width / 2), centerY - sizeH - space, width, sizeH)
    -- Left to center.
    surface.DrawRect(centerX - sizeH - space, centerY - (width / 2), sizeH, width)
    -- Center to bottom.
    surface.DrawRect(centerX - (width / 2), centerY + space, width, sizeH)
    -- Center to right.
    surface.DrawRect(centerX + space, centerY - (width / 2), sizeH, width)
    render.OverrideAlphaWriteEnable(false, false)
    render.OverrideBlendFunc(false)
end