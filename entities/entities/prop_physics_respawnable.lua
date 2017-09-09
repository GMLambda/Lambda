ENT.Base = "lambda_entity"
ENT.Type = "point"

DEFINE_BASECLASS("lambda_entity")

local DEFAULT_RESPAWN_TIME = 60.0

function ENT:PreInitialize()
	BaseClass.PreInitialize(self)
	self:SetupNWVar("RespawnTime", "string", { Default = "", KeyValue = "RespawnTime"} )
end

function ENT:SpawnProp()

	local ent = ents.Create("prop_physics")
	for _,v in pairs(self.StoredKeyValues) do
		ent:SetKeyValue(v.Key, v.Val)
	end
	ent:Spawn()
	ent:CallOnRemove(self, function()
		if IsValid(self) then
			self:PropDestroyed(ent)
		end
	end)

	self.OriginalSpawnPos = ent:GetPos()
	self.OriginalSpawnAng = ent:GetAngles()

	self.OriginalOBBMins = ent:OBBMins()
	self.OriginalOBBMaxs = ent:OBBMaxs()

	self.ActiveProp = ent
	self.NextRespawnTime = 0
	self.Think = self.IdleThink

end

function ENT:PropDestroyed(ent)
	local respawnTime = self:GetNWVar("RespawnTime", DEFAULT_RESPAWN_TIME)
	self.NextRespawnTime = CurTime() + respawnTime
	self.Think = self.RespawnThink
end

function ENT:Initialize()

    BaseClass.Initialize(self)

	self:SpawnProp()

end

function ENT:OnRemove()
end

function ENT:IdleThink()
end

function ENT:RespawnThink()
	if self.NextRespawnTime == 0 or CurTime() < self.NextRespawnTime then
		return
	end

	local tr = util.TraceHull(
	{
		start = self.OriginalSpawnPos,
		endpos = self.OriginalSpawnPos,
		mins = self.OriginalOBBMins,
		maxs = self.OriginalOBBMaxs,
		filter = self,
		mask = MASK_SOLID,
	})

	if tr.StartSolid == true or tr.AllSolid == true then
		-- Try again in a second.
		self.NextRespawnTime = CurTime() + 1.0
		return
	end

	self:SpawnProp()
end

function ENT:KeyValue(key, val)
	BaseClass.KeyValue(self, key, val)

	self.StoredKeyValues = self.StoredKeyValues or {}
	-- NOTE: This causes the overwrite the class of the entity, remove it.
	if key:iequals("classname") == false then
		table.insert(self.StoredKeyValues, { Key = key, Val = val })
	end
end
