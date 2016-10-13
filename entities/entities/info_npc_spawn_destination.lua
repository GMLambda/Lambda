local DbgPrint = GetLogging("NPC")

if SERVER then

ENT.Base = "base_point"
ENT.ReuseDelay = 0
ENT.RenameNPC = nil
ENT.TimeNextAvailable = 0

DEFINE_BASECLASS( "base_point" )

function ENT:PreInitialize()

	self:SetupOutput("OnSpawnNPC")

end

function ENT:KeyValue(key, val)

	if key:iequals("ReuseDelay") then
		self.ReuseDelay = tonumber(val)
	elseif key:iequals("RenameNPC") then
		self.RenameNPC = val
	end

	return BaseClass.KeyValue(self, key, val)

end

function ENT:Initialize()

	self.TimeNextAvailable = CurTime()

	BaseClass.Initialize(self)

end

function ENT:IsAvailable()

	if self.TimeNextAvailable > CurTime() then
		return false
	end

	return true

end

function ENT:OnSpawnedNPC(ent)

	if self.RenameNPC ~= nil and self.RenameNPC ~= "" then
		ent:SetName(self.RenameNPC)
	end

	self:FireOutputs("OnSpawnNPC", ent, self)
	self.TimeNextAvailable = CurTime() + self.ReuseDelay

end

end
