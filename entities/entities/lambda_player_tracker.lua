if SERVER then
    AddCSLuaFile()
end

local IsValid = IsValid
local Vector = Vector
local util = util
local math_clamp = math.Clamp

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    if CLIENT then
        hook.Add("PostDrawTranslucentRenderables", self, function(ent, bDrawingDepth, bDrawingSkybox)
            if bDrawingDepth == true or bDrawingSkybox == true then
                return
            end
            ent:Render()
        end)
    end

    self:AddEffects(EF_NODRAW)
    self.RenderData = {
        valid = false,
        visible = false,
        hitPlayer = false,
        allowTracking = false,
        headPos = Vector(0, 0, 0),
        crosshairDot = 0.0,
        alphaScale = 0.0,
        teamColor = Color(255, 255, 255, 255),
        nick = "",
        nickWidth = 0,
        nickHeight = 0,
    }
end

function ENT:AttachToPlayer(ply)
    self:SetParent(ply)
    self:AddEffects(EF_NODRAW)
    self.Player = ply
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

if CLIENT then
    local surface = surface
    local LocalPlayer = LocalPlayer
    local EyeAngles = EyeAngles
    local EyePos = EyePos
    local draw = draw
    local cam = cam
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawOutlinedRect = surface.DrawOutlinedRect
    local surface_DrawRect = surface.DrawRect
    local draw_SimpleText = draw.SimpleText
    local pixVis = util.GetPixelVisibleHandle()
    local font = "DermaLarge"
    local pad = 2
    local health_w = 100
    local health_h = 5
    local aux_w = 100
    local aux_h = 5

    local function IsPlayerVisible(ply, localPly)
        local tr = util.TraceLine({
            start = localPly:EyePos(),
            endpos = ply:EyePos(),
            filter = { localPly, ply },
            mask = MASK_SHOT
        })

        if tr.Fraction >= 1.0 then
            return true
        end

        local visibility = util.PixelVisible(ply:EyePos(), 0, pixVis)
        return visibility > 0
    end

    local TICK_DELAY = 1 / 30

    function ENT:Think()
        self:SetNextClientThink(CurTime() + TICK_DELAY)

        local renderData = self.RenderData

        local localPly = LocalPlayer()
        if IsValid(localPly) == false then
            renderData.valid = false
            renderData.hitPlayer = false
            return
        end

        local ply = self:GetParent()
        if not IsValid(ply) or not ply:IsPlayer() or ply:GetNoDraw() == true or ply:Alive() == false then
            renderData.valid = false
            renderData.hitPlayer = false
            return true
        end

        -- Check if if player position is on screen.
        local screen = ply:EyePos():ToScreen()
        if not screen.visible then
            renderData.valid = false
            renderData.visible = false
            renderData.hitPlayer = false
            return
        end

        -- From here on always valid, just compute what needs to be rendered.
        renderData.valid = true
        renderData.allowTracking = GAMEMODE:AllowPlayerTracking()
        renderData.teamColor = GAMEMODE:GetTeamColor(ply)

        if renderData.allowTracking == false then
            -- Never draw through walls.
            renderData.visible = true
        else
            -- Check if player is visible.
            if not IsPlayerVisible(ply, localPly) then
                renderData.visible = false
                renderData.hitPlayer = false
            else
                renderData.visible = true
            end
        end

        -- Compute the rendering data.
        local boneIdx = ply:LookupBone("ValveBiped.Bip01_Head1")
        if boneIdx ~= nil then
            renderData.headPos = ply:GetBonePosition(boneIdx) + Vector(0, 0, 14)
        else
            renderData.headPos = ply:GetPos() + Vector(0, 0, ply:OBBMaxs().z + 4)
        end

        -- Compute how close the crosshair is to the player.
        if renderData.hitPlayer == false then
            local eyePos = localPly:EyePos()
            local eyeAng = localPly:EyeAngles()
            local toTarget = (ply:EyePos() - eyePos):GetNormalized()
            local forward = eyeAng:Forward()
            local dot = forward:Dot(toTarget)
            renderData.crosshairDot = dot
        else
            renderData.crosshairDot = 1.0
        end

        -- Fire a trace to see if we hit the player directly.
        if renderData.crosshairDot > 0.8 then
            local tr = util.TraceLine({
                start = localPly:EyePos(),
                endpos = localPly:EyePos() + (localPly:EyeAngles():Forward() * 4096),
                filter = {localPly},
                mask = MASK_ALL,
            })
            if tr.Entity == ply then
                --print("hit player")
                renderData.hitPlayer = true
            else
                renderData.hitPlayer = false
            end
        else
            renderData.hitPlayer = false
        end

        local alphaScale = (renderData.crosshairDot - 0.985) / 0.2
        renderData.alphaScale = alphaScale
        renderData.teamColor.a = renderData.teamColor.a * alphaScale
        renderData.nick = ply:Nick()

        surface.SetFont(font)
        local w, h = surface.GetTextSize(renderData.nick)
        renderData.nickWidth = w
        renderData.nickHeight = h

        return true
    end

    local function RenderPlayer(renderData, ply, localPly)
        if ply == localPly then
            return
        end
        render.DepthRange(0.2, 0.3)
        do
            ply:DrawModel()
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and not wep:IsEffectActive(EF_NODRAW) then
                wep:DrawModel()
            end
        end
        render.DepthRange(0, 1) -- restore normal depth
    end

    local function RenderPlayerStats(renderData, ply, localPly)
        surface.SetFont(font)
        local text = renderData.nick
        local w, h = renderData.nickWidth, renderData.nickHeight
        local alphaScale = renderData.alphaScale
        local teamColor = renderData.teamColor
        local restoreIgnoreZ = false
        local x = 0
        local y = 0
        local posX = 0

        if renderData.allowTracking == true and renderData.visible == false then
            cam.IgnoreZ(true)
            restoreIgnoreZ = true
        end

        draw_SimpleText(text, font, x - 1 - (w / 2), y + 1, Color(0, 0, 0, 120 * alphaScale))
        draw_SimpleText(text, font, x + 1 - (w / 2), y + 2, Color(0, 0, 0, 50 * alphaScale))
        draw_SimpleText(text, font, x - (w / 2), y, teamColor)
        y = y + h + pad

        do
            local p = ply:Health() / ply:GetMaxHealth()
            local redPower = (1.0 - p) * 10
            local v = CurTime() * redPower
            local flash = (1 + math.sin(v) * math.cos(v)) * 55
            surface_SetDrawColor(0, 0, 0, 100 * alphaScale)
            surface_DrawOutlinedRect(posX + -1 - (health_w / 2), y, health_w + 2, health_h + 2)
            surface_SetDrawColor(200 - (p * 200) + flash, (p * 255) - (flash / 2), 0, 100 * alphaScale)
            surface_DrawRect(posX + -(health_w / 2), y + 1, p * health_w, health_h)
            y = y + health_h + pad
        end

        if ply:GetNWBool("LambdaHEVSuit", false) == true then
            local aux = ply:GetLambdaSuitPower()
            local p = aux / 100
            surface_SetDrawColor(0, 0, 0, 100 * alphaScale)
            surface_DrawOutlinedRect(posX + -1 - (aux_w / 2), y, aux_w + 2, aux_h + 2)
            surface_SetDrawColor(255 - p * 255, p * 200, p * 150, 100 * alphaScale)
            surface_DrawRect(posX + -(aux_w / 2), y + 1, p * aux_w, aux_h)
        end

        if restoreIgnoreZ == true then
            cam.IgnoreZ(false)
        end
    end

    local function RenderOverheadInfo(renderData, ply, localPly)
        local pos = renderData.headPos
        local ang = EyeAngles()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)

        local dist = pos:Distance(EyePos())
        dist = math_clamp(dist, 0, 3000)
        local distScale = (2 * (dist / 3000))
        local distZ = distScale * 50
        local scale = 0.12 + distScale

        cam.Start3D2D(pos + Vector(0, 0, 10 + distZ), ang, scale)
        do
            RenderPlayerStats(renderData, ply, localPly)
        end
        cam.End3D2D()
    end

    function ENT:Render()
        local renderData = self.RenderData
        if renderData.valid ~= true then
            -- Player is out of sight, do nothing.
            return
        end

        local ply = self:GetParent()
        local localPly = LocalPlayer()

        if renderData.visible ~= true then
            -- Player is not visible, render them through walls.
            RenderPlayer(renderData, ply, localPly)
        end

        -- Render the overhead info.
        if renderData.crosshairDot >= 0.98 then
            RenderOverheadInfo(renderData, ply, localPly)
        end
    end
end