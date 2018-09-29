local DbgPrint = GetLogging("Player")

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("LambdaPlayerModels")

    function GM:InitializePlayerModels()
        local mdls = player_manager.AllValidModels()
        self.AvailablePlayerModels = mdls
    end

    function GM:SendPlayerModelList(ply)
        if self.AvailablePlayerModels == nil then
            error("GM:InitializePlayerModels was never called")
        end
        net.Start("LambdaPlayerModels")
        net.WriteTable(self.AvailablePlayerModels)
        net.Send(ply)
        DbgPrint("Sending player model list to: " .. tostring(ply))
    end

else -- CLIENT

    function GM:SetPlayerModelList(mdls)
        self.AvailablePlayerModels = mdls
    end

    net.Receive("LambdaPlayerModels", function(len)
        local mdls = net.ReadTable()
        GAMEMODE:SetPlayerModelList(mdls)
        DbgPrint("Received player model list")
        --PrintTable(mdls)
    end)

end

function GM:GetAvailablePlayerModels()
    if SERVER and self.AvailablePlayerModels == nil then
        error("GM:InitializePlayerModels was never called")
    end
    return self.AvailablePlayerModels
end
