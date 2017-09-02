AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons =
	{
		"weapon_physcannon",
	},
	Ammo =
	{
	},
	Armor = 60,
	HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
	--["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["global_newgame_template_base_items"] = true,
	["global_newgame_template_local_items"] = true,
	["global_newgame_template_ammo"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- FIX: Running towards the players before they get to do anything
		for k,v in pairs(ents.FindByName("citadel_npc_sold_starthall1_*")) do
			if v:IsNPC() then
				v:SetKeyValue("sleepstate", "3")
			end
		end

		-- 7724.114746 -1358.596924 2112.031250
		local weaponTrigger = ents.Create("trigger_multiple")
		weaponTrigger:SetupTrigger(
			Vector(7724.114746, -1358.596924, 2112.031250),
			Angle(0, 0, 0),
			Vector(-160, -260, 0),
			Vector(160, 260, 100)
		)
		weaponTrigger.OnTrigger = function(ent)
			local plys = ent:GetTouchingObjects()
			table.sort(plys, function(a, b)
				return a:EntIndex() < b:EntIndex()
			end)
			local firstPly = false
			for k,v in pairs(plys) do
				if firstPly == false then
					firstPly = true
					continue
				end
				if v:HasWeapon("weapon_physcannon") then
					DbgPrint("Stripping on player: " .. tostring(v))
					v:StripWeapon("weapon_physcannon")
				end
			end
		end

		GAMEMODE:WaitForInput("logic_weapon_strip_physcannon_start", "Trigger", function(ent)

			weaponTrigger:Remove()

			for k,v in pairs(ents.FindByClass("weapon_physcannon")) do
				v:Supercharge()
			end

			-- Reset sleep state
			for k,v in pairs(ents.FindByName("citadel_npc_sold_starthall1_*")) do
				if v:IsNPC() then
					v:SetKeyValue("sleepstate", "0")
				end
			end
		end)

		GAMEMODE:WaitForInput("weapon_strip", "Disable", function(ent)
			-- I don't understand how this works in HL2, simply Disabling it wont call StopTouch and reset the value.
			for k,v in pairs(player.GetAll()) do
				v:SetSaveValue("m_bPreventWeaponPickup", false)
			end
		end)

		ents.WaitForEntityByName("citadel_movelinear_elevphysball1_1", function(ent)
			ent:SetKeyValue("blockdamage", "0")
		end)
	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

end

function MAPSCRIPT:OnRegisterNPC(npc)

	-- Don't drop weapons, seems that NPCs in gmod don't have this flag set.
	util.RunNextFrame(function()
		if not IsValid(npc) then return end
		npc:AddSpawnFlags(8192 + 131072 + 262144)
	end)

	DbgPrint("Registered NPC: " .. tostring(npc))

end

return MAPSCRIPT
