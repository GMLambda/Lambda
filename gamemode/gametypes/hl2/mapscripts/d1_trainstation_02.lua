AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
	Weapons = {},
	Ammo = {},
	Armor = 30,
	HEV = false,
}

MAPSCRIPT.InputFilters =
{
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

	if SERVER then

		-- Override env_global so combines dont flip shit on everyone
		game.SetGlobalState("gordon_invulnerable", GLOBAL_ON)
		game.SetGlobalState("gordon_precriminal", GLOBAL_ON)

		local cupcop_can = nil
		local cupcop = nil
		local cupcopSpeech =
		{
			"npc/combine_soldier/vo/sectorisnotsecure.wav",
			"npc/combine_soldier/vo/reaper.wav",
			"npc/combine_soldier/vo/stayalert.wav",
			"npc/combine_soldier/vo/ghost.wav",
			"npc/combine_soldier/vo/target.wav",
			"npc/combine_soldier/vo/visualonexogens.wav",
		}

		ents.WaitForEntityByName("cupcop_can", function(ent)
			cupcop_can = ent
		end)

		ents.WaitForEntityByName("cupcop", function(ent)
			cupcop = ent
		end)

		-- swing_seat_1
		-- -4674.464844 -3538.560059 25.073853
		-- models/nova/airboat_seat.mdl
		-- prop_vehicle_prisoner_pod
		local swing_seat_1 = ents.FindFirstByName("swing_seat_1")
		local seat_1 = ents.Create("prop_vehicle_prisoner_pod")
		seat_1:SetPos(Vector(-4674.464844, -3540, 25))
		seat_1:SetModel("models/nova/airboat_seat.mdl")
		seat_1:SetAngles(Angle(0, 180, 0))
		seat_1:SetCollisionGroup(COLLISION_GROUP_NONE)
		seat_1:SetParent(swing_seat_1)
		seat_1:SetNoDraw(true)
		seat_1:Spawn()

		local phys_seat_1 = seat_1:GetPhysicsObject()
		if IsValid(phys_seat_1) then
			phys_seat_1:SetMass(1)
		end

		-- swing_seat_2
		-- -4633.555664 -3542.251465 24.702568
		-- models/nova/airboat_seat.mdl
		-- prop_vehicle_prisoner_pod
		local swing_seat_2 = ents.FindFirstByName("swing_seat_2")
		local seat_2 = ents.Create("prop_vehicle_prisoner_pod")
		seat_2:SetPos(Vector(-4633.555664, -3540, 25))
		seat_2:SetModel("models/nova/airboat_seat.mdl")
		seat_2:SetCollisionGroup(COLLISION_GROUP_NONE)
		seat_2:SetAngles(Angle(0, 180, 0))
		seat_2:SetParent(swing_seat_2)
		seat_2:SetNoDraw(true)
		seat_2:Spawn()

		local phys_seat_2 = seat_2:GetPhysicsObject()
		if IsValid(phys_seat_2) then
			phys_seat_2:SetMass(1)
		end

		-- Why not..
		hook.Add("VehicleMove", "Lambda_SwingSeat", function(ply, vehicle, cmd)

			if vehicle ~= seat_1 and vehicle ~= seat_2 then
				return
			end

			local parent = vehicle:GetParent()
			local phys = parent:GetPhysicsObject()
			if IsValid(phys) then

				if cmd:KeyDown(IN_FORWARD) then
					local fwd = vehicle:GetForward()
					phys:ApplyForceCenter(fwd * 30)
				elseif cmd:KeyDown(IN_BACK) then
					local fwd = vehicle:GetForward()
					phys:ApplyForceCenter(-fwd * 30)
				end

			end

		end)

        GAMEMODE:WaitForInput("cupcop_nag_timer", "Enable", function()
			do
				return
			end
			DbgPrint("Starting to nag the cop")

			util.RunDelayed(function()

				cupcop_can:SetModel("models/gibs/hgibs.mdl")
				cupcop_can:Ignite(999999)

	            hook.Add("Think", "CupCopRevenge", function()

					if not IsValid(cupcop) or not IsValid(cupcop_can) then
						DbgPrint("Not valid, removing hook")
						hook.Remove("Think", "CupCopRevenge")
						return
					end

					local phys = cupcop_can:GetPhysicsObject()
					if not IsValid(phys) then
						DbgPrint("Not valid, removing hook")
						hook.Remove("Think", "CupCopRevenge")
						return
					end

					local cupcopFwd = cupcop:EyeAngles():Forward()
					local cupcopPos = cupcop:EyePos() + (cupcopFwd * 50)

					local dist = cupcop:EyePos():Distance(cupcop_can:GetPos())
					local power = dist * 0.8

					local vecDir = cupcopPos - cupcop_can:GetPos()
					local vecLookDir = cupcop:GetPos() - cupcop_can:GetPos()
					local ang = vecDir:Angle()
					local angLook = vecLookDir:Angle()
					local angFwd = ang:Forward()
					local vel = angFwd * (Vector(1, 1, 1) * power)
					local minDistance = 150

					--DbgPrint("Power: " .. tostring(power))
					cupcop.LastAction = cupcop.LastAction or 0
					if dist < minDistance and CurTime() - cupcop.LastAction >= 5 then

						cupcop.LastAction = CurTime()

						if cupcop:IsCurrentSchedule(SCHED_COWER) == false then

							local cops = {}
							for _,v in pairs(ents.FindByClass("npc_metropolice")) do
								if v ~= cupcop then
									table.insert(cops, v)
								end
							end

							local cupcopRunPos = table.Random(cops):GetPos()

							cupcop:SetLastPosition(cupcopRunPos)
							cupcop:SetSchedule(SCHED_FORCED_GO_RUN)

							cupcop.LastTalk = cupcop.LastTalk or CurTime() - 2.1
							if CurTime() - cupcop.LastTalk >= 2 then
								local speech = table.Random(cupcopSpeech)
								DbgPrint("EmitSound: " .. tostring(speech))
								cupcop:EmitSound(speech)
								cupcop.LastTalk = CurTime()
							end
						end

					end

					phys:SetVelocity(vel)
					phys:SetAngles(angLook)

				end)
			end, CurTime() + 4)

    	end)

    end

end

return MAPSCRIPT
