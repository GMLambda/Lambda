if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("PlayerList")
local util = util
local table = table

LAMBDA_PLAYER_LIST = LAMBDA_PLAYER_LIST or {
    Players = {},
    Connecting = {},
    Connected = {}
}

function GM:InitializePlayerList()
    DbgPrint("InitializePlayerList")

    LAMBDA_PLAYER_LIST = {
        Players = {},
        Connecting = {},
        Connected = {}
    }
end

if SERVER then
    function GM:TransferPlayers()
        DbgPrint("TransferPlayers")

        if self.TransitionData ~= nil and self.TransitionData.Players ~= nil then
            -- Changelevel does not signal a new connect, so we take players from the transition data instead.
            for _, data in pairs(self.TransitionData.Players) do
                local userId = tonumber(data["UserID"])
                local playerData = LAMBDA_PLAYER_LIST.Players[userId] or {}
                local timeout = self:GetSetting("connect_timeout")
                playerData.ConnectTime = GetSyncedTimestamp()
                playerData.TimeoutTime = GetSyncedTimestamp() + timeout
                playerData.Nick = data["Nick"]
                playerData.SteamID = data["SteamID"]
                playerData.UserID = userId
                playerData.Connecting = true
                playerData.Bot = false -- Cant be done.
                DbgPrint("Connect timeout for " .. tostring(playerData.Nick) .. ": " .. timeout)
                LAMBDA_PLAYER_LIST.Players[userId] = playerData
                LAMBDA_PLAYER_LIST.Connecting[userId] = playerData
            end

            --PrintTable(self.Connecting)
            for k, _ in pairs(LAMBDA_PLAYER_LIST.Connecting) do
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
                for _, v in pairs(LAMBDA_PLAYER_LIST.Players) do
                    if v.SteamID == steamid then return v end
                end
            end

            return LAMBDA_PLAYER_LIST.Players[userid]
        end

        local playerData = getPlayerData()

        if playerData ~= nil then
            playerData.Connecting = bot == false
            playerData.Bot = bot

            if playerData.UserID ~= userid then
                -- UserID changed over session, remove old one.
                LAMBDA_PLAYER_LIST.Connecting[playerData.UserID] = nil
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
        LAMBDA_PLAYER_LIST.Players[userid] = playerData

        if playerData.Connecting == true then
            LAMBDA_PLAYER_LIST.Connecting[userid] = playerData
        end
    end

    function GM:HandlePlayerDisconnect(steamid, nick, reason, bot, userid)
        DbgPrint("HandlePlayerDisconnect", steamid, nick, reason, bot, userid)
        local playerData = LAMBDA_PLAYER_LIST.Players[userid]
        if playerData == nil then return end
        playerData.Connecting = false -- Just in case of references.
        LAMBDA_PLAYER_LIST.Connecting[userid] = nil
        LAMBDA_PLAYER_LIST.Players[userid] = nil
    end

    function GM:HandlePlayerReadyState(ply)
        DbgPrint("[NET] Player fully connected: " .. tostring(ply))
        local userId = ply:UserID()
        local playerData = LAMBDA_PLAYER_LIST.Connecting[userId]

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
        LAMBDA_PLAYER_LIST.Connecting[userId] = nil
        LAMBDA_PLAYER_LIST.Connected[userId] = playerData
        hook.Call("NotifyPlayerListChanged", GAMEMODE, userId)
    end

    function GM:CheckPlayerTimeouts()
        local timestamp = GetSyncedTimestamp()
        if self.LastTimeoutCheck ~= nil and timestamp - self.LastTimeoutCheck < 0.2 then return end
        self.LastTimeoutCheck = timestamp

        for k, v in pairs(LAMBDA_PLAYER_LIST.Connecting) do
            if timestamp >= v.TimeoutTime then
                DbgPrint("Player " .. v.Nick .. " timed out, timeout: " .. v.TimeoutTime)
                v.Connecting = false
                LAMBDA_PLAYER_LIST.Connecting[k] = nil
                continue
            end
        end
    end

    function GM:GetPlayerCount()
        return table.Count(LAMBDA_PLAYER_LIST.Players)
    end

    function GM:GetFullyConnectedCount()
        return table.Count(LAMBDA_PLAYER_LIST.Connected)
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

    net.Receive("LambdaPlayerReady", function(len, ply)
        GAMEMODE:HandlePlayerReadyState(ply)
    end)
else -- CLIENT
    -- FIXME: Move this out into sh_lambda_player.lua
    hook.Add("StartCommand", "LambdaPlayerReady", function(ply, cmd)
        -- NOTE: Just making sure its us.
        if ply ~= LocalPlayer() then return end

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
    return table.Count(LAMBDA_PLAYER_LIST.Connecting) + 0
end