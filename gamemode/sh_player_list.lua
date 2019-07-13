AddCSLuaFile()

local DbgPrint = GetLogging("PlayerList")

function GM:InitializePlayerList()
    DbgPrint("InitializePlayerList")
    self.Players = {}
    self.Connecting = {}
    self.Connected = {}
end

if SERVER then

    function GM:TransferPlayers()

        DbgPrint("TransferPlayers")

        if self.TransitionData ~= nil and self.TransitionData.Players ~= nil then

            -- Changelevel does not signal a new connect, so we take players from the transition data instead.
            for _,data in pairs(self.TransitionData.Players) do

                local userId = tonumber(data["UserID"])
                local playerData = self.Players[userId] or {}

                local timeout = self:GetSetting("connect_timeout")
                playerData.ConnectTime = GetSyncedTimestamp()
                playerData.TimeoutTime = GetSyncedTimestamp() + timeout
                playerData.Nick = data["Nick"]
                playerData.SteamID = data["SteamID"]
                playerData.UserID = userId
                playerData.Connecting = true
                playerData.Bot = false -- Cant be done.

                DbgPrint("Connect timeout for " .. tostring(playerData.Nick) .. ": " .. timeout)

                self.Players[userId] = playerData
                self.Connecting[userId] = playerData

            end

            --PrintTable(self.Connecting)

            for k,_ in pairs(self.Connecting) do
                hook.Call("NotifyPlayerListChanged", GAMEMODE, k)
            end

        end

    end

    local function isValidSteamID(steamId)
        if steamId == "STEAM_ID_PENDING" then
            return false
        elseif steamId == "BOT" or steamId == "NULL" then
            return false
        elseif steamId == "STEAM_0:0:0" then
            return false
        end
        return true
    end
    
    function GM:HandlePlayerConnect(steamid, nick, entIndex, bot, userid)

        DbgPrint("HandlePlayerConnect", steamid, nick, entIndex, userid)

        local getPlayerData = function()
            if isValidSteamID(steamid) then
                for _,v in pairs(self.Players) do
                    if v.SteamID == steamid then
                        return v
                    end
                end
            end
            return self.Players[userid]
        end
        
        local playerData = getPlayerData()
        if playerData ~= nil then
            playerData.Connecting = bot == false
            playerData.Bot = bot
            if playerData.UserID ~= userid then
                -- UserID changed over session, remove old one.
                self.Connecting[playerData.UserID] = nil
                playerData.UserID = userid
            end
        else
            playerData = {}
            playerData.ConnectTime = GetSyncedTimestamp()
            playerData.Nick = nick
            playerData.SteamID = steamid
            playerData.UserID = userid
            playerData.Bot = bot
            playerData.Connecting = bot == false
            DbgPrint("Waiting for new player to fully connect: " .. nick)
        end

        playerData.TimeoutTime = GetSyncedTimestamp() + self:GetSetting("connect_timeout")

        self.Players[userid] = playerData
        if playerData.Connecting == true then
            self.Connecting[userid] = playerData
        end

    end

    function GM:HandlePlayerDisconnect(steamid, nick, reason, bot, userid)

        DbgPrint("HandlePlayerDisconnect", steamid, nick, reason, bot, userid)

        local playerData = self.Players[userid]
        if playerData == nil then
            return
        end

        playerData.Connecting = false -- Just in case of references.

        self.Connecting[userid] = nil
        self.Players[userid] = nil

    end

    function GM:HandlePlayerReadyState(ply)

        DbgPrint("[NET] Player fully connected: " .. tostring(ply))

        local userId = ply:UserID()
        local playerData = self.Connecting[userId]
        if playerData == nil then
            --DbgError("ERROR: User never signaled a connect: " .. userid)
            playerData = {}
            playerData.ConnectTime = GetSyncedTimestamp()
            playerData.Nick = ply:Nick()
            playerData.SteamID = ply:SteamID64()
            playerData.UserID = userId
            playerData.Bot = ply:IsBot()
            playerData.Connecting = false
        end

        playerData.Connecting = false

        self.Connecting[userId] = nil
        self.Connected[userId] = playerData

        hook.Call("NotifyPlayerListChanged", GAMEMODE, userId)

    end

    function GM:CheckPlayerTimeouts()

        local timestamp = GetSyncedTimestamp()

        if self.LastTimeoutCheck ~= nil and timestamp - self.LastTimeoutCheck < 0.2 then
            return
        end

        self.LastTimeoutCheck = timestamp

        for k,v in pairs(self.Connecting) do
            if timestamp >= v.TimeoutTime then
                DbgPrint("Player " .. v.Nick .. " timed out, timeout: " .. v.TimeoutTime)
                v.Connecting = false
                self.Connecting[k] = nil
                continue
            end
        end

    end

    function GM:GetPlayerCount()
        return table.Count(self.Players)
    end

    function GM:GetFullyConnectedCount()
        return table.Count(self.Connected)
    end

    gameevent.Listen("player_connect")
    hook.Add("player_connect", "LambdaPlayerConnect", function(data)
        GAMEMODE:HandlePlayerConnect(data.networkid, data.name, data.index, data.bot == 1, data.userid)
    end)

    gameevent.Listen("player_disconnect")
    hook.Add("player_disconnect", "LambdaPlayerConnect", function(data)
        GAMEMODE:HandlePlayerDisconnect(data.networkid, data.name, data.reason, data.bot == 1, data.userid)
    end)

    util.AddNetworkString("LambdaPlayerReady")

    net.Receive("LambdaPlayerReady",function(len, ply)
        GAMEMODE:HandlePlayerReadyState(ply)
    end)

else -- CLIENT

    -- FIXME: Move this out into sh_lambda_player.lua
    hook.Add("StartCommand", "LambdaPlayerReady", function(ply, cmd)

        -- NOTE: Just making sure its us.
        if ply ~= LocalPlayer() then
            return
        end

        -- Auto-reload
        if ply.SignaledConnection ~= true then

            -- Delay this a little, I noticed that clients aren't fully ready at this point
            -- causing them glitch when put in vehicles.
            timer.Simple(2, function()
                net.Start("LambdaPlayerReady")
                net.SendToServer()
            end)

            ply.SignaledConnection = true
        end

        hook.Remove("StartCommand", "LambdaPlayerReady")

    end)

end

function GM:GetConnectingCount()
    return table.Count(self.Connecting) + 0
end
