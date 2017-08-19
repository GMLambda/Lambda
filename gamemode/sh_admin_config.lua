if SERVER then
	AddCSLuaFile()

	util.AddNetworkString("LambdaAdminSetting")

	function GM:ChangeAdminConfiguration(ply, token, cvar, val)
		if ply:IsAdmin() == false then
			return
		end
		if self:ValidateUserToken(ply, token) == false then
			return
		end
		local registeredCvar = self:GetRegisteredConVar(cvar)
		if registeredCvar == nil then
			print("Attempted to access unregistered cvar: " .. cvar .. ", player: " .. tostring(ply))
			return
		end
		registeredCvar:SetString(val)
	end

	net.Receive("LambdaAdminSetting", function(len, ply)

		print("Received admin setting changes")

		local token = net.ReadString()
		local cvar = net.ReadString()
		local val = net.ReadString()

		GAMEMODE:ChangeAdminConfiguration(ply, token, cvar, val)

	end)

else

	function GM:ChangeAdminConfiguration(cvar, val)
		local ply = LocalPlayer()
		-- Theres no point sending data.
		if ply:IsAdmin() == false then
			return
		end
		net.Start("LambdaAdminSetting")
		net.WriteString(LAMBDA_PLAYER_AUTH_TOKEN)
		net.WriteString(cvar)
		net.WriteString(val)
		net.SendToServer()
	end

end
