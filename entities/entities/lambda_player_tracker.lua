AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
	if CLIENT then
		-- I know this seems insane but otherwise it would clip the purpose.
		self:SetRenderBounds(Vector(-10000, -10000, -10000), Vector(10000, 10000, 10000))

		hook.Add("PostDrawTranslucentRenderables", self, function(ent, bDrawingDepth, bDrawingSkybox)
			if bDrawingDepth == true or bDrawingSkybox == true then
				return
			end
			ent:RenderPlayer()
		end)

		hook.Add("HUDPaint", self, function(ent)
			--ent:RenderPlayerStats()
		end)
	end
	self:DrawShadow(false)
end

function ENT:AttachToPlayer(ply)
	self:SetModel(ply:GetModel())
	self:SetPos(ply:GetPos())
	self:SetAngles(ply:GetAngles())
	self:SetParent(ply)
	self:AddEffects(EF_BONEMERGE)
	self:DrawShadow(false)
	self.Player = ply
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

if CLIENT then

	local pixVis = util.GetPixelVisibleHandle()
	local font = "DermaLarge"
	local pad = 2
	local health_w = 100
	local health_h = 5
	local aux_w = 100
	local aux_h = 5

	local function IsPlayerVisible(ply)

		local localPly = LocalPlayer()
		if localPly:IsLineOfSightClear(ply:EyePos()) then
			return true
		end

		local visibility = util.PixelVisible(ply:EyePos(), 0, pixVis)
		return visibility > 0

	end

	function ENT:RenderPlayer()

		local ply = self:GetParent()
		if not IsValid(ply) or not ply:IsPlayer() then
			return
		end

		local playerVisible = IsPlayerVisible(ply)
		local allowTracking = GAMEMODE:AllowPlayerTracking()

		if allowTracking == false then
			return
		end

		local localPly = LocalPlayer()
		if ply == localPly then
			return
		end

		local dir = (ply:EyePos() - EyePos()):GetNormal()
		local dot = dir:Dot(EyeAngles():Forward())

		if dot < 0 or ply:Alive() == false then
			return
		end

		if playerVisible == false then
			cam.IgnoreZ(true)

			ply:DrawModel()

			for _,v in pairs(ply:GetChildren()) do
				if v == self then continue end
				v:DrawModel()

				if v:GetClass() == "weapon_physcannon" and v.AttachedEnt ~= nil then
					v.AttachedEnt:DrawModel()
				end
			end

			cam.IgnoreZ(false)
		end

	end

	function ENT:RenderPlayerStats()

		local ply = self:GetParent()
		if not IsValid(ply) or not ply:IsPlayer() then
			return
		end

		local playerVisible = IsPlayerVisible(ply)
		local allowTracking = GAMEMODE:AllowPlayerTracking()

		if allowTracking == false and playerVisible == false then
			-- Not visible, hide the name tag.
			return
		end

		surface.SetFont(font)

		local text = ply:Nick()

		local w, h = surface.GetTextSize( text )
		local x = 0
		local y = 0
		local teamColor = GAMEMODE:GetTeamColor( ply )
		local screenPos = Vector()

		local dir = (ply:EyePos() - EyePos()):GetNormal()
		local dot = dir:Dot(EyeAngles():Forward())
		local alphaScale = (dot - 0.8) / 0.2
		if alphaScale < 0 then
			return
		end

		teamColor.a = teamColor.a * alphaScale

		local restoreIgnoreZ = false
		if allowTracking == true and playerVisible == false then
			cam.IgnoreZ(true)
			restoreIgnoreZ = true
		end

		draw.SimpleText( text, font, x - 1 - (w / 2), y + 1, Color( 0, 0, 0, 120 * alphaScale ) )
		draw.SimpleText( text, font, x + 1 - (w / 2), y + 2, Color( 0, 0, 0, 50 * alphaScale ) )
		draw.SimpleText( text, font, x - (w / 2), y, teamColor )

		y = y + h + pad

		do
			local p = ply:Health() / ply:GetMaxHealth()
			local redPower = (1.0 - p) * 10
			local v = CurTime() * redPower
			local flash = (1 + math.sin(v) * math.cos(v)) * 55

			surface.SetDrawColor(0, 0, 0, 100 * alphaScale)
			surface.DrawOutlinedRect(screenPos.x + -1 - (health_w / 2), y, health_w + 2, health_h + 2)

			surface.SetDrawColor(200 - (p * 200) + flash, (p * 255) - (flash / 2), 0, 100 * alphaScale)
			surface.DrawRect(screenPos.x +  -(health_w / 2), y + 1, p * health_w, health_h)

			y = y + health_h + pad
		end

		if ply:GetNWBool("LambdaHEVSuit", false) == true then
			local aux = ply:GetSuitPower()
			local p = aux / 100

			surface.SetDrawColor(0, 0, 0, 100 * alphaScale)
			surface.DrawOutlinedRect(screenPos.x + -1 - (aux_w / 2), y, aux_w + 2, aux_h + 2)

			surface.SetDrawColor(255 - p * 255, p * 200, p * 150, 100 * alphaScale)
			surface.DrawRect(screenPos.x + -(aux_w / 2), y + 1, p * aux_w, aux_h)
		end

		if restoreIgnoreZ == true then
			cam.IgnoreZ(false)
		end

	end

	function ENT:DrawTranslucent()

		local localPly = LocalPlayer()
		if IsValid(localPly) == false then
			return
		end

		local ply = self:GetParent()
		if not IsValid(ply) or ply == LocalPlayer() or ply:Alive() == false then
			return
		end

		local pos
		local boneIdx = ply:LookupBone("ValveBiped.Bip01_Head1")
		if boneIdx ~= nil then
			pos = ply:GetBonePosition(boneIdx) + Vector(0, 0, 14)
		else
			pos = ply:GetPos() + Vector(0, 0, ply:OBBMaxs().z + 4)
		end

		local ang = EyeAngles()

		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), 90 )

		local dist = pos:Distance(localPly:GetPos())
		dist = math.Clamp(dist, 0, 3000)

		local distScale = (2 * (dist / 3000))
		local distZ = distScale * 50
		local scale = 0.12 + distScale

		cam.Start3D2D(pos + Vector(0, 0, 10 + distZ), ang, scale)
		self:RenderPlayerStats()
		cam.End3D2D()

	end

end
