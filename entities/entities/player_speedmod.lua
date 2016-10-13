--https://developer.valvesoftware.com/wiki/Player_speedmod
local DbgPrint = GetLogging("Trigger")

ENT.Base = "base_point"
ENT.Type = "point"

function ENT:Initialize()
	DbgPrint("player_speedmod:Initialize")
end

function ENT:AcceptInput(inputName, activator, called, data)

	DbgPrint("player_speedmod:AcceptInput(" .. tostring(inputName) .. ", " .. tostring(activator) .. ", " .. tostring(called) .. ", " .. tostring(data) .. ")")

	if inputName == "ModifySpeed" then
		local speed = tonumber(data)
		for _,v in pairs(player.GetAll()) do
			v:Flashlight(false)
			v:SetLaggedMovementValue(speed)
		end
		return true
	else
		DbgPrint("Unhandled input: " .. tostring(inputName))
	end

	return false
end
