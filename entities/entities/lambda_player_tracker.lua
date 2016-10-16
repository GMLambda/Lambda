AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

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
			ent:RenderPlayerStats()
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

	local function IsPlayerBehind(ply)

		local dir = (ply:EyePos() - EyePos()):GetNormal()
		local dot = dir:Dot(EyeAngles():Forward())
		if dot < 0 then
			return true
		end
		return false

	end

	function ENT:RenderPlayer()

		local ply = self:GetParent()
		if not IsValid(ply) or not ply:IsPlayer() then
			return
		end

		local localPly = LocalPlayer()
		if ply == localPly then
			return
		end

		if IsPlayerBehind(ply) == true or ply:Alive() == false then
			return
		end

		local lastFrame = self.LastFrameNumber
		if lastFrame == nil or lastFrame == FrameNumber() then
			--return
		end
		self.LastFrameNumber = FrameNumber()

		if IsPlayerVisible(ply) == false then
			cam.IgnoreZ(true)
			ply:DrawModel()
			cam.IgnoreZ(false)
		end

	end

	function ENT:RenderPlayerStats()

		local ply = self:GetParent()
		if not IsValid(ply) or not ply:IsPlayer() or ply == LocalPlayer() then
			return
		end

		local text = ply:Nick()
		local pos = ply:EyePos() + Vector(0, 0, 12)

		local boneIdx = ply:LookupBone("ValveBiped.Bip01_Head1")
		if boneIdx ~= nil then
			pos = ply:GetBonePosition(boneIdx) + Vector(0, 0, 14)
		end

		local dist = EyePos():Distance(ply:EyePos())
		if dist < 100 then
			dist = 100
		elseif dist > 6000 then
			dist = 6000
		end
		local scaleFactor = math.log(dist) * 6

		local scale = 0.12 * (dist * 0.01)
		if scale < 0.12 then
			scale = 0.12
		end

		local zOffset = 1 * (scale * scaleFactor)

		local screenPos = (pos + Vector(0, 0, zOffset)):ToScreen()

		surface.SetFont(font)

		local w, h = surface.GetTextSize( text )
		local x = -(w / 2) + screenPos.x
		local y = 0 + screenPos.y

		draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
		draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ) )
		draw.SimpleText( text, font, x, y, GAMEMODE:GetTeamColor( ply ) )

		y = y + h + pad

		do
			local p = ply:Health() / ply:GetMaxHealth()
			local redPower = (1.0 - p) * 10
			local v = CurTime() * redPower
			local flash = (1 + math.sin(v) * math.cos(v)) * 55

			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawOutlinedRect(screenPos.x + -1 - (health_w / 2), y, health_w + 2, health_h + 2)

			surface.SetDrawColor(200 - (p * 200) + flash, (p * 255) - (flash / 2), 0, 100)
			surface.DrawRect(screenPos.x +  -(health_w / 2), y + 1, p * health_w, health_h)

			y = y + health_h + pad

		end

		do
			local aux = ply:GetSuitPower()
			local p = aux / 100

			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawOutlinedRect(screenPos.x + -1 - (aux_w / 2), y, aux_w + 2, aux_h + 2)

			surface.SetDrawColor(255 - p * 255, p * 200, p * 150, 100)
			surface.DrawRect(screenPos.x + -(aux_w / 2), y + 1, p * aux_w, aux_h)

		end

	end

	function ENT:Draw()
	end

	function ENT:DrawTranslucent()
	end

end
