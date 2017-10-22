AddCSLuaFile()

--local DbgPrint = GetLogging("EntityExt")
local ENTITY_META = FindMetaTable("Entity")

function ENTITY_META:AddSpawnFlags(flags)

	local newFlags = bit.bor(self:GetSpawnFlags(), flags)
	self:SetKeyValue("spawnflags", newFlags)

end

function ENTITY_META:RemoveSpawnFlags(flags)

	local newFlags = bit.band(self:GetSpawnFlags(), bit.bnot(flags))
	self:SetKeyValue("spawnflags", newFlags)

end

function ENTITY_META:IsDoor()
	local class = self:GetClass()
	return class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating"
end

function ENTITY_META:GetModelInfo()

	local mdl = self:GetModel()
	if self.CachedModelDataInfo ~= nil and self.CachedModelDataFile == mdl then
		return self.CachedModelDataInfo
	end

	local mdlInfo = util.GetModelInfo(mdl)
	if mdlInfo ~= nil and mdlInfo.KeyValues ~= nil then
		self.CachedModelDataInfo = util.KeyValuesToTable(mdlInfo.KeyValues)
		self.CachedModelDataFile = mdl
	end

	return self.CachedModelDataInfo

end

local ITEM_CLASSES =
{
	["item_ammo_357"] = true,
	["item_ammo_357_large"] = true,
	["item_ammo_ar2"] = true,
	["item_ammo_ar2_altfire"] = true,
	["item_ammo_ar2_large"] = true,
	["item_ammo_crate"] = true,
	["item_ammo_crossbow"] = true,
	["item_ammo_pistol"] = true,
	["item_ammo_pistol_large"] = true,
	["item_ammo_smg1"] = true,
	["item_ammo_smg1_grenade"] = true,
	["item_ammo_smg1_large"] = true,
	["item_battery"] = true,
	["item_box_buckshot"] = true,
	["item_dynamic resupply"] = true,
	["item_healthcharger"] = true,
	["item_healthkit"] = true,
	["item_healthvial"] = true,
	["item_item_crate"] = true,
	["item_rpg_round"] = true,
	["item_suit"] = true,
	["item_suitcharger"] = true,
	["weapon_frag"] = true,
	["weapon_slam"] = true,
}

function ENTITY_META:IsItem()
	local class = self:GetClass()
	return ITEM_CLASSES[class] == true
end

function ENTITY_META:PhysicsImpactSound(chan, vol, speed)

	local mdlInfo = self:GetModelInfo()
	if mdlInfo == nil then
		return
	end

	local solid = mdlInfo["solid"];

	if solid == nil then
		return
	end

	local surfaceprop = solid["surfaceprop"]
	if surfaceprop == nil then
		return
	end

	local data = surfacedata.GetByName(surfaceprop)
	if data == nil then
		return
	end

	local snd = data["impactsoft"]
	if snd ~= nil then
		self:EmitSound(snd)
	end

end

DOOR_STATE_CLOSED = 0
DOOR_STATE_OPENING = 1
DOOR_STATE_OPEN = 2
DOOR_STATE_CLOSING = 3

function ENTITY_META:GetDoorState()
	return self:GetSaveTable().m_eDoorState
end

function ENTITY_META:IsDoorClosing()
	return self:GetDoorState() == DOOR_STATE_CLOSING
end

function ENTITY_META:IsDoorClosed()
	return self:GetDoorState() == DOOR_STATE_CLOSED
end

function ENTITY_META:IsDoorOpening()
	return self:GetDoorState() == DOOR_STATE_OPENING
end

function ENTITY_META:IsDoorOpen()
	return self:GetDoorState() == DOOR_STATE_OPEN
end

function ENTITY_META:IsDoorLocked()
	return self:GetSaveTable().m_bLocked
end

OVERLAY_TEXT_BIT			=	0x00000001		-- show text debug overlay for this entity
OVERLAY_NAME_BIT			=	0x00000002		-- show name debug overlay for this entity
OVERLAY_BBOX_BIT			=	0x00000004		-- show bounding box overlay for this entity
OVERLAY_PIVOT_BIT			=	0x00000008		-- show pivot for this entity
OVERLAY_MESSAGE_BIT			=	0x00000010		-- show messages for this entity
OVERLAY_ABSBOX_BIT			=	0x00000020		-- show abs bounding box overlay
OVERLAY_RBOX_BIT			=   0x00000040     -- show the rbox overlay
OVERLAY_SHOW_BLOCKSLOS		=	0x00000080		-- show entities that block NPC LOS
OVERLAY_ATTACHMENTS_BIT		=	0x00000100		-- show attachment points
OVERLAY_AUTOAIM_BIT			=	0x00000200		-- Display autoaim radius
OVERLAY_NPC_SELECTED_BIT	=	0x00001000		-- the npc is current selected
OVERLAY_NPC_NEAREST_BIT		=	0x00002000		-- show the nearest node of this npc
OVERLAY_NPC_ROUTE_BIT		=	0x00004000		-- draw the route for this npc
OVERLAY_NPC_TRIANGULATE_BIT =	0x00008000		-- draw the triangulation for this npc
OVERLAY_NPC_ZAP_BIT			=	0x00010000		-- destroy the NPC
OVERLAY_NPC_ENEMIES_BIT		=	0x00020000		-- show npc's enemies
OVERLAY_NPC_CONDITIONS_BIT	=	0x00040000		-- show NPC's current conditions
OVERLAY_NPC_SQUAD_BIT		=	0x00080000		-- show npc squads
OVERLAY_NPC_TASK_BIT		=	0x00100000		-- show npc task details
OVERLAY_NPC_FOCUS_BIT		=	0x00200000		-- show line to npc's enemy and target
OVERLAY_NPC_VIEWCONE_BIT	=	0x00400000		-- show npc's viewcone
OVERLAY_NPC_KILL_BIT		=	0x00800000		-- kill the NPC running all appropriate AI.
OVERLAY_WC_CHANGE_ENTITY	=	0x01000000		-- object changed during WC edit
OVERLAY_BUDDHA_MODE			=	0x02000000		-- take damage but don't die
OVERLAY_NPC_STEERING_REGULATIONS	=	0x04000000	-- Show the steering regulations associated with the NPC
OVERLAY_TASK_TEXT_BIT		=	0x08000000		-- show task and schedule names when they start
OVERLAY_PROP_DEBUG			=	0x10000000
OVERLAY_NPC_RELATION_BIT	=	0x20000000		-- show relationships between target and all children
OVERLAY_VIEWOFFSET			=	0x40000000		-- show view offset

function ENTITY_META:AddDebugOverlays(f)
	local flags = self:GetDebugOverlays()
	flags = bit.bor(flags, tonumber(f or 0))
	self:SetSaveValue("m_debugOverlays", flags)
end

function ENTITY_META:RemoveDebugOverlays(f)
	local flags = self:GetDebugOverlays()
	flags = bit.band(flags, bit.bnot(f))
	self:SetSaveValue("m_debugOverlays", flags)
end

function ENTITY_META:GetDebugOverlays()
	local tbl = self:GetSaveTable()
	return tonumber(tbl["m_debugOverlays"] or 0)
end

-- Vehicles
function ENTITY_META:IsGunEnabled()
	return self:GetSaveTable().EnableGun == true
end

-- caps
FCAP_MUST_SPAWN				= 0x00000001		-- Spawn after restore
FCAP_ACROSS_TRANSITION		= 0x00000002		-- should transfer between transitions
-- UNDONE: This will ignore transition volumes (trigger_transition), but not the PVS!!!
FCAP_FORCE_TRANSITION		= 0x00000004		-- ALWAYS goes across transitions
FCAP_NOTIFY_ON_TRANSITION	= 0x00000008		-- Entity will receive Inside/Outside transition inputs when a transition occurs

FCAP_IMPULSE_USE			= 0x00000010		-- can be used by the player
FCAP_CONTINUOUS_USE			= 0x00000020		-- can be used by the player
FCAP_ONOFF_USE				= 0x00000040		-- can be used by the player
FCAP_DIRECTIONAL_USE		= 0x00000080		-- Player sends +/- 1 when using (currently only tracktrains)

-- NOTE: Normally +USE only works in direct line of sight.  Add these caps for additional searches
FCAP_USE_ONGROUND			= 0x00000100
FCAP_USE_IN_RADIUS			= 0x00000200
FCAP_SAVE_NON_NETWORKABLE	= 0x00000400

FCAP_MASTER					= 0x10000000		-- Can be used to "master" other entities (like multisource)
FCAP_WCEDIT_POSITION		= 0x40000000		-- Can change position and update Hammer in edit mode
FCAP_DONT_SAVE				= 0x80000000		-- Don't save this

function ENTITY_META:HasObjectCaps(caps)
	return bit.band(self:ObjectCaps(), caps) ~= 0
end

function ENTITY_META:GetObjectCaps()
	return self:ObjectCaps()
end

function ENTITY_META:EnableRespawn(state, time)
	-- On shutdown this actually errors thats why this check exists.
	if not IsValid(self) then
		return
	end

	if state == true then
		time = time or 1

		self:CallOnRemove("LambdaRespawn", function(ent)
			local class = ent:GetClass()
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			local mdl = ent:GetModel()

			timer.Simple(time, function()
				local new = ents.Create(class)
				new:SetPos(pos)
				new:SetAngles(ang)
				new:SetModel(mdl)
				new:Spawn()
				new:EnableRespawn(true)
			end)

		end)

	else
		self:RemoveCallOnRemove("LambdaRespawn")
	end

end

function ENTITY_META:GetKeyValueTable()
	return table.Copy(self.LambdaKeyValues or {})
end

CHAR_TEX_ANTLION		= 'A'
CHAR_TEX_BLOODYFLESH	= 'B'
CHAR_TEX_CONCRETE		= 'C'
CHAR_TEX_DIRT			= 'D'
CHAR_TEX_EGGSHELL		= 'E' -- the egg sacs in the tunnels in ep2.
CHAR_TEX_FLESH			= 'F'
CHAR_TEX_GRATE			= 'G'
CHAR_TEX_ALIENFLESH		= 'H'
CHAR_TEX_CLIP			= 'I'
CHAR_TEX_SNOW			= 'J'

function ENTITY_META:IsVPhysicsFlesh()

	if CLIENT then
		-- Since they dont have physics this is our best bet.
		local class = self:GetClass()
		if class == "prop_ragdoll" then
			return true
		end
	end

	for i = 0, self:GetPhysicsObjectCount() - 1 do

		local phys = self:GetPhysicsObjectNum( i )
		local mat = phys:GetMaterial()
		--DbgPrint("MAT:" .. tostring(mat))
		local surfdata = surfacedata.GetByName(mat)
		if surfdata ~= nil then
			local matType = surfdata["gamematerial"]
			if matType == CHAR_TEX_ANTLION or matType == CHAR_TEX_FLESH or matType == CHAR_TEX_BLOODYFLESH or matType == CHAR_TEX_ALIENFLESH then
				return true
			end
		end
	end

	return false

end

function ENTITY_META:GetRootMoveParent()
	local ent = self
	local parent = ent:GetMoveParent()
	while IsValid(parent) do
		ent = parent
		parent = ent:GetMoveParent()
	end
	return ent
end

function ENTITY_META:GetPhysMass()
	local mass = 0.0
	for i = 0, self:GetPhysicsObjectCount() - 1 do
		local phys = self:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			mass = mass + phys:GetMass()
		end
	end
	return mass
end

function ENTITY_META:CanBecomeRagdoll()
	local seq = self:SelectWeightedSequence(ACT_DIERAGDOLL)
	if seq == ACT_INVALID then
		return false
	end
	if self:IsFlagSet(FL_TRANSRAGDOLL) then
		return false
	end
	return true
end

function ENTITY_META:CopyAnimationDataFrom(other)

	self:SetModel(other:GetModel())
	self:SetCycle(other:GetCycle())
	self:RemoveEffects(self:GetEffects()) -- Clear, no set available.
	self:AddEffects(other:GetEffects())
	self:SetSequence(other:GetSequence())

	local saveTable = other:GetSaveTable()
	self:SetSaveValue("m_flAnimTime", saveTable["m_flAnimTime"])
	self:SetSkin(other:GetSkin())


end
