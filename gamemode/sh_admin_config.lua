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
        local registeredCvar = GAMEMODE:GetSettingData(cvar)
        if registeredCvar.CVar == nil then
            DbgPrint("Attempted to access unregistered cvar: " .. tostring(cvar) .. ", player: " .. tostring(ply))
            return
        end
        if registeredCvar.Type == "int" or registeredCvar.Type == "bool" or registeredCvar.Type == "float" then
            registeredCvar.CVar:SetInt(val)
            registeredCvar.Value = tonumber(val)
        else
            registeredCvar.CVar:SetString(val)
            registeredCvar.Value = tostring(val)
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
