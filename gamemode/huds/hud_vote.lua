local PANEL = {}
local padding = 5
local stripeW = 5
local MAT_FAILED = Material("lambda/failed.png")
local MAT_SUCCESS = Material("lambda/success.png")

function PANEL:Init()
    self:SetTitle("")
    self:SetPos(padding, ScrH() * 0.25)
    self:SetDeleteOnClose(false)
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:SetVisible(true)
    self.currentVote = nil
    self.choiceScore = {}
    self.smoothChoiceScore = {}
    self.lastTimeLeft = 99999
    self.totalPlayers = 0
end

function PANEL:UpdateVote(vote)
    if self.currentVote ~= nil then
        -- Only play when being updated.
        surface.PlaySound("buttons/button16.wav")
    end

    self.currentVote = vote
    self.choiceScore = {}
    self.smoothChoiceScore = self.smoothChoiceScore or {}

    for k, v in pairs(vote.options) do
        self.choiceScore[k] = 0
        self.smoothChoiceScore[k] = self.smoothChoiceScore[k] or 0
    end

    for k, v in pairs(vote.results) do
        self.choiceScore[v] = self.choiceScore[v] + 1
    end
end

function PANEL:SetVoteResults(vote)
    if vote.failed == false then
        surface.PlaySound("buttons/button14.wav")
    else
        surface.PlaySound("buttons/button19.wav")
    end
end

function PANEL:Think()
    local vote = self.currentVote
    if vote == nil then return end

    for k, v in pairs(self.choiceScore) do
        self.smoothChoiceScore[k] = Lerp(FrameTime() * 20, self.smoothChoiceScore[k], self.choiceScore[k])
    end

    if vote.finished ~= true then
        local totalTime = vote.endtime - vote.starttime
        local timeLeft = math.Round(vote.endtime - GetSyncedTimestamp())

        if timeLeft < self.lastTimeLeft and timeLeft > 0 and (timeLeft <= (totalTime * 0.5)) then
            self.lastTimeLeft = timeLeft
            surface.PlaySound("buttons/blip1.wav")
        end

        local plys = player.GetAll()

        for _, v in pairs(vote.excluded) do
            table.RemoveByValue(plys, v)
        end

        self.totalPlayers = #plys
    end
end

function PANEL:Paint(w, h)
    local textW, textH = 0, 0
    local paddingChoice = 10
    local x, y = 10, 5
    local maxW = 10
    local vote = self.currentVote
    local ply = vote.issuer
    local params = vote.params
    local text = ""
    surface.SetDrawColor(0, 0, 0, 230)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(255, 147, 30, 230)
    surface.DrawRect(0, 0, 5, h)
    surface.SetFont("lambda_sb_def_sm")

    -- Issuer
    do
        if IsValid(ply) then
            text = "Vote called by " .. ply:Name()
        else
            text = "Vote called by host"
        end

        surface.SetTextColor(255, 255, 255, 230)
        surface.SetTextPos(x, y)
        surface.DrawText(text)
        textW, textH = surface.GetTextSize(text)
        y = y + textH + padding
        maxW = math.max(maxW, textW)
    end

    surface.SetFont("lambda_sb_def")
    local widthDesc = 0

    -- Description.
    do
        if vote.finished ~= true then
            local timeLeft = math.Round(vote.endtime - GetSyncedTimestamp())

            if timeLeft < 0 then
                timeLeft = 0
            end

            text = string.format("%02d - ", timeLeft)
        else
            if vote.failed ~= true then
                local timeLeft = math.Round(vote.actionTime - GetSyncedTimestamp())

                if timeLeft < 0 then
                    timeLeft = 0
                end

                text = string.format("%02d - ", timeLeft)
            else
                text = ""
            end
        end

        if vote.type == VOTE_TYPE_KICK_PLAYER then
            local kickingPlayer = params.Player
            text = text .. "Kick player: " .. kickingPlayer:Name()
        elseif vote.type == VOTE_TYPE_SKIP_MAP then
            text = text .. "Skip to next map: " .. params.NextMap
        elseif vote.type == VOTE_TYPE_RESTART_MAP then
            text = text .. "Restart current map"
        elseif vote.type == VOTE_TYPE_CHANGE_MAP then
            text = text .. "Change to map: " .. params.Map
        elseif vote.type == VOTE_TYPE_NEXT_MAP then
            text = text .. "Choose next map"
        end

        surface.SetTextPos(x, y)
        surface.SetTextColor(255, 147, 30, 230)
        surface.DrawText(text)
        textW, textH = surface.GetTextSize(text)
        y = y + textH + padding
        widthDesc = textW + padding + 100
        maxW = math.max(maxW, widthDesc)
    end

    surface.SetFont("lambda_sb_def_sm")
    local seperatorY = y
    local seperatorX = x

    -- Seperator.
    do
        y = y + 1 + padding
    end

    -- Info.
    if vote.finished ~= true and vote.canVote == true then
        do
            text = "Press the corresponding number to vote."
            surface.SetTextColor(255, 255, 255, 230)
            surface.SetTextPos(x, y)
            surface.DrawText(text)
            textW, textH = surface.GetTextSize(text)
            y = y + textH + paddingChoice
            maxW = math.max(maxW, textW)
        end
    else
        y = y + paddingChoice
    end

    -- Choices
    local choiceMargin = 10
    local maxChoiceW = 0
    local choiceY = y

    for k, v in pairs(vote.options) do
        text = tostring(k) .. "."

        if vote.finished ~= true then
            surface.SetTextColor(255, 147, 30, 230)
        else
            if vote.winningOption == k then
                surface.SetTextColor(255, 147, 30, 230)
            else
                surface.SetTextColor(100, 100, 100, 100)
            end
        end

        surface.SetTextPos(x + choiceMargin, y)
        surface.DrawText(text)
        textW, textH = surface.GetTextSize(text)
        local numberMargin = math.max(textW, 15)
        text = v

        if vote.finished ~= true then
            if vote.choice == k then
                surface.SetTextColor(255, 147, 30, 230)
            else
                surface.SetTextColor(255, 255, 255, 230)
            end
        else
            if vote.winningOption == k then
                surface.SetTextColor(255, 147, 30, 230)
            else
                surface.SetTextColor(100, 100, 100, 100)
            end
        end

        surface.SetTextPos(x + choiceMargin + numberMargin, y)
        surface.DrawText(text)
        textW, textH = surface.GetTextSize(text)
        maxChoiceW = math.max(maxChoiceW, textW + numberMargin)
        y = y + textH + paddingChoice
        maxW = math.max(maxW, textW + choiceMargin)
    end

    maxChoiceW = math.max(maxChoiceW, 100) + 20
    local barWidth = 100

    for k, v in pairs(vote.options) do
        local score = self.choiceScore[k]
        local smoothScore = self.smoothChoiceScore[k]
        text = tostring(score)

        if vote.finished ~= true then
            surface.SetTextColor(255, 255, 255, 230)
        else
            if vote.winningOption == k and vote.failed ~= true then
                surface.SetTextColor(255, 255, 255, 230)
            else
                surface.SetTextColor(100, 100, 100, 100)
            end
        end

        surface.SetTextPos(x + choiceMargin + maxChoiceW + padding, choiceY)
        surface.DrawText(text)
        textW, textH = surface.GetTextSize(text)
        local textSpace = math.max(textW, 15)
        maxW = math.max(maxW, textW + choiceMargin + padding + maxChoiceW + textSpace + barWidth)
        local barSize = (smoothScore / self.totalPlayers) * barWidth

        if vote.finished ~= true then
            surface.SetDrawColor(255, 147, 30, 230)
        else
            if vote.winningOption == k and vote.failed ~= true then
                surface.SetDrawColor(255, 147, 30, 230)
            else
                surface.SetDrawColor(100, 100, 100, 100)
            end
        end

        surface.DrawRect(x + choiceMargin + maxChoiceW + padding + textSpace, choiceY + 6, barSize, 5)
        choiceY = choiceY + textH + paddingChoice
    end

    -- Seperator
    do
        surface.SetDrawColor(255, 255, 255, 155)
        surface.DrawLine(seperatorX, seperatorY, seperatorX + maxW, seperatorY + 1)
    end

    -- Icon 
    if vote.finished == true then
        do
            if vote.failed == true then
                surface.SetMaterial(MAT_FAILED)
            else
                surface.SetMaterial(MAT_SUCCESS)
            end

            surface.DrawTexturedRect(5 + maxW + padding - 32 - 5, 10, 32, 32)
        end
    end

    self:SetSize(stripeW + padding + maxW + padding, y)
end

vgui.Register("HudVote", PANEL, "DFrame")