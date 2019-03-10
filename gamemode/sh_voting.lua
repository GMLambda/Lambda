if SERVER then
    AddCSLuaFile()
end

VOTE_TYPE_INVALID = 0
VOTE_TYPE_KICK_PLAYER = 1
VOTE_TYPE_RESTART_MAP = 2
VOTE_TYPE_SKIP_MAP = 3
VOTE_TYPE_CHANGE_MAP = 4
VOTE_TYPE_NEXT_MAP = 5
VOTE_TYPE_LAST = VOTE_TYPE_NEXT_MAP

local DbgPrint = GetLogging("Voting")
local currentVotes = {}

if SERVER then

    util.AddNetworkString("LambdaUpdateVote")
    util.AddNetworkString("LambdaVoteResults")
    util.AddNetworkString("LambdaFinishVote")
    util.AddNetworkString("LambdaVote")

    local voteid = 0

    local function IsValidVoteType(votetype)
        if not isnumber(votetype) then
            return false
        end
        if votetype <= VOTE_TYPE_INVALID or votetype > VOTE_TYPE_LAST then
            return false
        end
        return true
    end

    function GM:HasActiveVotes()
        return table.Count(currentVotes) > 0
    end

    function GM:StartVote(ply, votetype, time, params, options, excluded, resultFn)

        if not IsValidVoteType(votetype) then
            return false
        end

        -- We only support a single vote right now.
        if self:HasActiveVotes() == true then
            return
        end

        voteid = voteid + 1
        if voteid >= 10000 then
            voteid = 1
        end

        local vote = {}
        vote.id = voteid
        vote.type = votetype
        vote.issuer = ply
        vote.excluded = excluded
        vote.starttime = GetSyncedTimestamp()
        vote.endtime = vote.starttime + (time or 8)
        vote.resultFn = resultFn
        vote.options = options
        vote.params = params
        vote.results = {}

        currentVotes[vote.id] = vote

        self:SendVote(nil, vote)

        if ply ~= nil then
            PrintMessage(HUD_PRINTTALK, "A vote has been started by: " .. ply:Name())
        end

        return vote

    end

    function GM:VoteTimeout(vote)
        DbgPrint("VoteTimeout: " .. tostring(vote.id))

        self:FinishVote(vote, true)
    end

    function GM:VoteCompleted(vote)
        DbgPrint("VoteCompleted: " .. tostring(vote.id))

        self:FinishVote(vote, false)
    end

    function GM:UpdateVotes()

        local t = GetSyncedTimestamp()

        for k,v in pairs(currentVotes) do
            local plys = player.GetAll()
            for _,exc in pairs(v.excluded or {}) do
                table.RemoveByValue(plys, exc)
            end
            local plyCount = #plys
            if t >= v.endtime then
                if table.Count(v.results) >= plyCount then
                    self:VoteCompleted(v)
                else
                    self:VoteTimeout(v)
                end
                currentVotes[k] = nil
                continue
            end

            if table.Count(v.results) >= plyCount then
                --self:VoteCompleted(v)
                --currentVotes[k] = nil 
            end

            for steamid, _ in pairs(v.results) do
                local ply = player.GetBySteamID(steamid)
                if not IsValid(ply) then
                    v.results[steamid] = nil
                    self:SendVote(nil, v)
                end
            end
        end

    end

    function GM:SendVote(ply, vote)
        net.Start("LambdaUpdateVote")
            net.WriteUInt(vote.id, 16)
            net.WriteUInt(vote.type, 8)
            net.WriteEntity(vote.issuer)
            net.WriteFloat(vote.endtime)
            net.WriteFloat(vote.starttime)
            net.WriteTable(vote.params)
            net.WriteTable(vote.excluded)
            net.WriteTable(vote.options)
            net.WriteTable(vote.results)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end

    function GM:FinishVote(vote, timeout)

        local winningOption = 0
        local failed = false
        local randomResult = false

        if vote.params.mustComplete == true then
            timeout = false
        end

        local numVoters = 0
        do
            local choices = {}
            for k,v in pairs(vote.results) do
                choices[v] = (choices[v] or 0) + 1
                numVoters = numVoters + 1
            end
            local maxChoices = 0
            local bestChoice = 0
            for k,v in pairs(choices) do
                if v > maxChoices then
                    bestChoice = k
                    maxChoices = v
                end
            end
            if bestChoice == 0 then
                randomResult = true
                winningOption = math.random(1, #vote.options)
            else
                winningOption = bestChoice
            end
        end

        if timeout == true then
            -- At least 2/3 of the players must vote.
            local p = numVoters / player.GetCount()
            if p < 0.66 then
                failed = true
            end
        end

        local actionDelay = 5

        net.Start("LambdaVoteResults")
        net.WriteUInt(vote.id, 16)
        net.WriteBool(failed)
        if failed == false then
            net.WriteUInt(winningOption, 8)
            net.WriteFloat(GetSyncedTimestamp() + actionDelay)
        end
        net.Broadcast()

        if failed == true then
            PrintMessage(HUD_PRINTTALK,"Vote failed, not enough players voted.")
        end

        timer.Simple(actionDelay, function()
            net.Start("LambdaFinishVote")
            net.WriteUInt(vote.id, 16)
            net.Broadcast()

            vote.resultFn(vote, failed == false, timeout, winningOption)
        end)

    end

    net.Receive("LambdaVote",function(len, ply)

        local id = net.ReadUInt(16)
        local choice = net.ReadUInt(8)

        local vote = currentVotes[id]
        if vote == nil then
            return
        end

        local steamid = ply:SteamID()
        vote.results[steamid] = choice

        GAMEMODE:SendVote(nil, vote)

    end)

    hook.Add("PlayerInitialSpawn", "SendVoteOnSpawn", function(ply)

        for _,v in pairs(currentVotes) do
            GAMEMODE:SendVote(ply, v)
        end

    end)

else -- CLIENT

    local activeVoteId = nil

    function GM:UpdateVote(vote)

        local current = currentVotes[vote.id]

        if current ~= nil then
            -- Update only 
            current.results = vote.results

            DbgPrint("Updating vote: " .. tostring(vote.id))
        else
            -- New vote.
            currentVotes[vote.id] = vote
            current = vote

            -- TODO: Create panel.
            local panel = vgui.Create("HudVote")
            vote.panel = panel

            DbgPrint("Started new vote: " .. tostring(vote.id))
        end

        -- Always use the newest as active vote.
        activeVoteId = nil
        for k,_ in pairs(currentVotes) do
            activeVoteId = k
            break
        end

        vote.canVote = true
        for _,v in pairs(vote.excluded) do
            if v == LocalPlayer() then
                vote.canVote = false
            end
        end

        current.panel:UpdateVote(current)

    end

    function GM:VoteResults(vote, actionTime, failed, winningOption)

        DbgPrint("Vote Results: " .. tostring(vote.id))

        vote.finished = true
        vote.failed = failed
        vote.winningOption = winningOption
        vote.actionTime = actionTime

        local panel = vote.panel
        if IsValid(panel) then
            panel:SetVoteResults(vote)
        end

    end

    function GM:VoteFinish(vote)

        DbgPrint("Vote Finished: " .. tostring(vote.id))

        local panel = vote.panel
        if IsValid(panel) then
            panel:Remove()
        end

        currentVotes[vote.id] = nil
        if activeVoteId == vote.id then
            activeVoteId = nil
        end

    end

    net.Receive("LambdaUpdateVote",function()
        local vote = {}
        vote.id = net.ReadUInt(16)
        vote.type = net.ReadUInt(8)
        vote.issuer = net.ReadEntity()
        vote.endtime = net.ReadFloat()
        vote.starttime = net.ReadFloat()
        vote.params = net.ReadTable()
        vote.excluded = net.ReadTable()
        vote.options = net.ReadTable()
        vote.results = net.ReadTable()
        GAMEMODE:UpdateVote(vote)
    end)

    net.Receive("LambdaVoteResults",function()
        local id = net.ReadUInt(16)
        local failed = net.ReadBool()
        local winningOption = nil
        local actionTime = nil
        if failed == false then
            winningOption = net.ReadUInt(8)
            actionTime = net.ReadFloat()
        end
        local vote = currentVotes[id]
        if vote ~= nil then
            GAMEMODE:VoteResults(vote, actionTime, failed, winningOption)
        end
    end)

    net.Receive("LambdaFinishVote", function()
        local id = net.ReadUInt(16)
        local vote = currentVotes[id]
        if vote ~= nil then
            GAMEMODE:VoteFinish(vote)
        end
    end)

    hook.Add("PlayerBindPress", "LambdaVoteInput", function(ply, bind, pressed)

        if activeVoteId == nil then
            return
        end

        if string.match(bind, "slot%d+") == nil then
            return
        end

        local vote = currentVotes[activeVoteId]
        if vote == nil then
            return
        end
        if vote.finished == true or vote.canVote == false then
            return
        end

        local num = string.gsub(bind, "slot", "")
        num = tonumber(num)

        local choice = vote.options[num]
        if choice == nil then
            DbgPrint("Invalid input choice: " .. tostring(num))
            return
        end

        if vote.choice ~= num then
            vote.choice = num
            net.Start("LambdaVote")
            net.WriteUInt(activeVoteId, 16)
            net.WriteUInt(num, 8)
            net.SendToServer()
        end

        return true

    end)


end