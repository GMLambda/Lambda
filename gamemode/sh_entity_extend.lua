AddCSLuaFile()

local DbgPrint = GetLogging("EntityExt")
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

DOOR_STATE_CLOSED = 0
DOOR_STATE_OPENING = 1
DOOR_STATE_OPEN = 2
DOOR_STATE_CLOSING = 3
DOOR_STATE_AJAR = 4

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

function ENTITY_META:GetDoorBlocker()
	return self:GetSaveTable().m_hBlocker
end

function ENTITY_META:IsDoorLocked()
	return self:GetSaveTable().m_bLocked
end

function ENTITY_META:GetDoorOpenDir()

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

		self:CallOnRemove("LambdaRespawn", function(self)
			local class = self:GetClass()
			local pos = self:GetPos()
			local ang = self:GetAngles()
			local mdl = self:GetModel()

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

-- FIXME: I'm not sure if we can use the material path alone, no way to get surface data atm.
function ENTITY_META:IsVPhysicsFlesh()

	--[[
	IPhysicsObject *pList[VPHYSICS_MAX_OBJECT_LIST_COUNT];
	int count = VPhysicsGetObjectList( pList, ARRAYSIZE(pList) );
	for ( int i = 0; i < count; i++ )
	{
		int material = pList[i]->GetMaterialIndex();
		const surfacedata_t *pSurfaceData = physprops->GetSurfaceData( material );
		// Is flesh ?, don't allow pickup
		if ( pSurfaceData->game.material == CHAR_TEX_ANTLION || pSurfaceData->game.material == CHAR_TEX_FLESH || pSurfaceData->game.material == CHAR_TEX_BLOODYFLESH || pSurfaceData->game.material == CHAR_TEX_ALIENFLESH )
			return true;
	}
	return false;
	]]

	for i = 0, self:GetPhysicsObjectCount() - 1 do

		local phys = self:GetPhysicsObjectNum( i )
		local mat = phys:GetMaterial()
		DbgPrint("IsVPhysicsFlesh: " .. mat)
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
