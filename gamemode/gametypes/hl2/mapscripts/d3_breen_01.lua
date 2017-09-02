AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons =
	{
		--"weapon_physcannon",
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
	["logic_auto"] = true,
	["env_fade"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
	["soldier_takegun"] = true,
	["soldier_actor"] = true,
	["timer_guards_bang"] = true,
	["logic_fade_view"] = true,
	["teleport_breen_blast_1"] = true,
	["sprite_breen_blast_1"] = true, -- Visible thru walls.
	["lcs_BreenOffice01"] = true,
	["lcs_BreenOffice02"] = true,
	["lcs_BreenOffice03"] = true,
	["lcs_BreenOffice03b"] = true,
	["citadel_brush_combinewall_start1"] = true,
	["citadel_brush_combinewall_start2"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

		self.AllowPhyscannon = false

		-- Remove default spawns.
		for k,v in pairs(ents.FindByClass("info_player_start")) do
			v:Remove()
		end

		local newStart = ents.Create("info_player_start")
		newStart:SetPos(Vector(-2458.020752, -1047.822632, 576.031250))
		newStart:SetAngles(Angle(0, 90, 0))
		newStart:SetKeyValue("spawnflags", "1") -- master
		newStart:Spawn()

		ents.WaitForEntityByName("Breen_blast_door_1", function(ent)
			ent:SetKeyValue("speed", "64")
			ent:Fire("Close")
		end)

		ents.WaitForEntityByName("Mossman", function(ent)
			ent:SetPos(Vector(-2173.508301, 749.625549, 576.031250))
		end)

		ents.WaitForEntityByName("lcs_BreenOffice01", function(ent)
			ent:SetKeyValue("busyactor", "0")
		end)
		ents.WaitForEntityByName("lcs_BreenOffice04", function(ent)
			ent:SetKeyValue("busyactor", "0")
		end)

		ents.WaitForEntityByName("logic_breenblast_2", function(ent)
			ent:Fire("AddOutput", "OnTrigger Breen_blast_door_1,Open,,4")
		end)

		-- -1836.434814 -1.664792 1344.031250

		local checkpoint1 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1836.434814, -1.664792, 1344.031250), Ang = Angle(0, 0, 0) })
		ents.WaitForEntityByName("trigger_player_Breenelevator", function(ent)
			ent:SetKeyValue("teamwait", "1")
			ent.OnTrigger = function()
				GAMEMODE:SetPlayerCheckpoint(checkpoint1)
			end
		end)

		local checkpoint2 = ents.CreateSimple("lambda_checkpoint", { Pos = Vector(-1056.175659, 490.913574, 1271.527832), Ang = Angle(0, -90, 0) })
		ents.WaitForEntityByName("Train_lift_TP", function(ent)
			checkpoint2:SetParent(ent)
		end)

		ents.WaitForEntityByName("Trigger_lift_control", function(ent)
			local trigger = ents.Create("trigger_once")
			trigger:SetKeyValue("teamwait", "1")
			trigger:SetupTrigger(
				Vector(-1056.175659, 490.913574, 1271.527832),
				Angle(0, 0, 0),
				Vector(-80, -80, 0),
				Vector(80, 50, 200)
			)
			trigger:Disable()
			trigger:CloneOutputs(ent)
			trigger:SetName("Trigger_lift_control")
			trigger.OnTrigger = function()
				GAMEMODE:SetPlayerCheckpoint(checkpoint2)
				self.AllowPhyscannon = true
			end
			ent:Remove()
		end)

		ents.RemoveByClass("npc_combine_s", Vector(-2298.000000, 334.000000, 576.031250))
	end

end

function MAPSCRIPT:OnNewGame()

	if SERVER then

		TriggerOutputs({
			{"EMPtool_Alyx", "SetParentAttachment", 0.0, "anim_attachment_RH"},
			{"steam_alyxSpit", "SetParentAttachment", 0.0, "mouth"},
			{"logic_pods_init", "Trigger", 0.0, ""},
			{"Eli", "StartScripting", 0.5, ""},
			{"Mossman", "StartScripting", 0.5, ""},
			{"Breen", "StartScripting", 0.5, ""},
			{"alyx", "StartScripting", 0.5, ""},
			{"lcs_BreenOffice04", "Start", 1.0, ""},
			--{"strip_start", "Trigger", 1.0, ""},
		})

	end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

	if self.AllowPhyscannon == true then
		ply:Give("weapon_physcannon")
	end

end

return MAPSCRIPT
