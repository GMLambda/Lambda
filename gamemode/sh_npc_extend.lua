if SERVER then
	AddCSLuaFile()
end

local DbgPrint = GetLogging("NPCExt")
local META_NPC = FindMetaTable("NPC")

if SERVER then

	-- Sadly theres only GetHull on the Player metatable, so this is a neccesary evil.
	local HULLS =
	{
		[HULL_HUMAN] = { Vector(-13,-13, 0), Vector(13, 13, 72), Vector(-8,-8, 0), Vector( 8, 8, 72) },
		[HULL_SMALL_CENTERED] = { Vector(-20,-20, -20),	Vector(20, 20, 20), Vector(-12,-12,-12), Vector(12, 12, 12) },
		[HULL_WIDE_HUMAN] = { Vector(-15,-15, 0), Vector(15, 15, 72), Vector(-10,-10, 0), Vector(10, 10, 72) },
		[HULL_TINY] = { Vector(-12,-12, 0), Vector(12, 12, 24), Vector(-12,-12, 0), Vector(12, 12, 24) },
		[HULL_WIDE_SHORT] = { Vector(-35,-35, 0), Vector(35, 35, 32), Vector(-20,-20, 0), Vector(20, 20, 32) },
		[HULL_MEDIUM] = { Vector(-16,-16, 0), Vector(16, 16, 64), Vector(-8,-8, 0), Vector(8, 8, 64) },
		[HULL_TINY_CENTERED] = { Vector(-8,	-8, -4), Vector(8, 8,  4), Vector(-8,-8, -4), Vector( 8, 8, 4) },
		[HULL_LARGE] = { Vector(-40,-40, 0), Vector(40, 40, 100), Vector(-40,-40, 0), Vector(40, 40, 100) },
		[HULL_LARGE_CENTERED] = { Vector(-38,-38, -38),	Vector(38, 38, 38), Vector(-30,-30,-30), Vector(30, 30, 30) },
		[HULL_MEDIUM_TALL] = { Vector(-18,-18, 0), Vector(18, 18, 100), Vector(-12,-12, 0), Vector(12, 12, 100) },
	}

	function META_NPC:GetHullMins()

		local hullType = self:GetHullType()
		if hullType == nil then
			return Vector(0, 0, 0)
		end

		local hull = HULLS[hullType]
		if hull == nil then
			return Vector(0, 0, 0)
		end

		return hull[1]

	end

	function META_NPC:GetHullMaxs()

		local hullType = self:GetHullType()
		if hullType == nil then
			return Vector(0, 0, 0)
		end

		local hull = HULLS[hullType]
		if hull == nil then
			return Vector(0, 0, 0)
		end

		return hull[2]

	end

	function META_NPC:GetCurrentSchedule( )

		for s = 0, LAST_SHARED_SCHEDULE-1 do
			if ( self:IsCurrentSchedule( s ) ) then return s end
		end

		return 0

	end

	function META_NPC:CreateServerRagdoll(dmginfo, collisionGroup)

		local ragdoll = ents.Create("prop_ragdoll")
		ragdoll:SetPos(self:GetPos())
		ragdoll:SetOwner(self)
		ragdoll:CopyAnimationDataFrom(self)

		if self:IsEFlagSet(EFL_NO_DISSOLVE) then
			ragdoll:AddEFlags(EFL_NO_DISSOLVE)
		end

		ragdoll:SetSaveValue("m_hKiller", dmginfo:GetInflictor())
		ragdoll:Spawn()

		return ragdoll

	end

	function META_NPC:IsEnemey()
		return not self:IsFriendly()
	end

	function META_NPC:IsFriendly()
		return IsFriendEntityName(self:GetClass())
	end

end
