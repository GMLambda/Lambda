local voteinfo = {}
voteinfo.voting = false
voteinfo.rtv = false
voteinfo.map = false
voteinfo.ply = false
voteinfo.time = 20

function GM:StartSkipMapVote(issuer)
    local function OnSkipToNextMapResult(vote, success, timeout, option)
        -- Yes
        if success == true and option == 1 then
            GAMEMODE:ChangeToNextLevel()
        end
    end

    local nextMap = self:GetNextMap()

    self:StartVote(issuer, VOTE_TYPE_SKIP_MAP, 15, {
        NextMap = nextMap
    }, {"Yes", "No"}, {}, OnSkipToNextMapResult)
end

function GM:StartRestartMapVote(issuer)
    local function OnRestartMapVoteResult(vote, success, timeout, option)
        -- Yes
        if success == true and option == 1 then
            GAMEMODE:CleanUpMap()
        end
    end

    self:StartVote(issuer, VOTE_TYPE_RESTART_MAP, 15, {}, {"Yes", "No"}, {}, OnRestartMapVoteResult)
end

function GM:StartMapVote(issuer, map)
    local function OnChangeLevelVoteResult(vote, success, timeout, option)
        -- Yes
        if success == true and option == 1 then
            GAMEMODE:RequestChangeLevel(map, nil, {})
        end
    end

    if string.lower(map) == string.lower(game.GetMap()) then return end

    self:StartVote(issuer, VOTE_TYPE_CHANGE_MAP, 15, {
        Map = map
    }, {"Yes", "No"}, {}, OnChangeLevelVoteResult)
end

function GM:StartKickVote(issuer, id)
    local ply = Player(id)
    if not IsValid(ply) then return end

    local function OnKickPlayerVoteResult(vote, success, timeout, option)
        -- Yes
        if success == true and option == 1 then
            game.KickID(id, "You have been vote kicked.")
        end
    end

    self:StartVote(issuer, VOTE_TYPE_KICK_PLAYER, 15, {
        Player = ply
    }, {"Yes", "No"}, {ply}, OnKickPlayerVoteResult)
end