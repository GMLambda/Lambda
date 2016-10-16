--local DbgPrint = print
-- REFACTOR ME: lambad_entity as base
local DbgPrint = GetLogging("Trigger")

ENT.Base = "base_point"
ENT.Type = "point"

-- HACK: SetPos does not ensure that the position wont be modified again by the gamemovement.
-- There is currently no ENTITY:Teleport binding.
TELEPORT_QUEUE = {}

hook.Add("FinishMove", "LambdaTeleport", function(ply, mv)
	local tpData = TELEPORT_QUEUE[ply]
	if tpData ~= nil then
		ply:SetPos(tpData.Pos)
		ply:SetAngles(tpData.Angles)
		TELEPORT_QUEUE[ply] = nil
		return true
	end
end)

local function TeleportPlayer(ent, pos, ang, vel)

	-- Mimic IncrementInterpolationFrame, we just make sure we call the things at the right time.
	local data = {}
	data.Pos = pos
	data.Angles = ang
	data.Velocity = vel
	data.Ent = ent
	TELEPORT_QUEUE[ent] = data

end

function ENT:Initialize()
	DbgPrint("point_teleport:Initialize")
	self.Target = self.Target or ""
	self.StackMode = self.StackMode or false
	self.StackDir = self.StackDir or self:GetAngles():Forward()
	self.StackLength = self.StackLength or 100
end

function ENT:AcceptInput(inputName, activator, called, data)

	DbgPrint("point_teleport:AcceptInput(" .. tostring(inputName) .. ", " .. tostring(activator) .. ", " .. tostring(called) .. ", " .. tostring(data) .. ")")

	if inputName == "Teleport" then

		-- We gonna teleport all players, kinda nasty work-around to replicate this entity type.
		if self.Target == "!player" or self.Target == "!players" then
			local pos = self:GetPos()
			local ang = self:GetAngles()

			for _,v in pairs(player.GetAll()) do
				DbgPrint("[" .. self:GetName() .. "] Teleporting player " .. tostring(v) .. "to  pos: " .. tostring(pos) .. ", ang: " .. tostring(ang))
				TeleportPlayer(v, pos, ang, v:GetVelocity())
			end

			return true
		else
			-- We have to find them.
			local entryPos = self:GetPos()
			local teleportPos = entryPos

			for _,v in pairs(ents.FindByName(self.Target)) do

				DbgPrint("Teleporting target: " .. self.Target .. " to: " .. tostring(teleportPos))

				v:SetPos(teleportPos)
				v:SetAngles(self:GetAngles())

				if self.StackMode == true then
					DbgPrint("Using stack mode teleportation")
					teleportPos = teleportPos + (self.StackDir * self.StackLength)
				end
			end

			return true
		end
	else
		DbgPrint("Unhandled input: " .. tostring(inputName))
	end

	--return false
end

function ENT:KeyValue( key, value )
	DbgPrint("point_teleport:KeyValue(" .. key .. ", " .. value .. ")")

	if key == "target" then
		self.Target = value
	elseif key == "stackmode" then
		self.StackMode = tobool(value)
	elseif key == "stackdir" then
		self.StackDir = util.StringToType(value, "Vector")
	elseif key == "stacklength" then
		self.StackLength = tonumber(value)
	end

end

function ENT:Think()
end

function ENT:OnRemove()
end
