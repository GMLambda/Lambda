local DbgPrint = GetLogging("Admin")

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("LambdaAdminSetting")

    function GM:ChangeAdminConfiguration(ply, token, cvar, val)
        if ply:IsAdmin() == false then
            DbgPrint("Player " .. tostring(ply) .. " attempted to change settings without the correct permissions.")
            return
        end
        if self:ValidateUserToken(ply, token) == false then
            DbgPrint("Player " .. tostring(ply) .. " attempted to change settings with invalid auth token.")
            return
        end
        local registeredCvar = self:GetGameTypeData("Settings")[cvar]
        if registeredCvar.getCvar == nil then
            DbgPrint("Attempted to access unregistered cvar: " .. tostring(cvar) .. ", player: " .. tostring(ply))
            return
        end
        if registeredCvar.value_type == "int" or registeredCvar.value_type == "bool" or registeredCvar.value_type == "float" then
            registeredCvar.getCvar:SetInt(val)
            registeredCvar.value = tonumber(val)
        else
            registeredCvar.getCvar:SetString(val)
            registeredCvar.value = tostring(val)
        end
    end


    net.Receive("LambdaAdminSetting", function(len, ply)

        local token = net.ReadString()
        local cvar = net.ReadString()
        local val = net.ReadString()

        GAMEMODE:ChangeAdminConfiguration(ply, token, cvar, val)

    end)

else -- CLIENT

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
