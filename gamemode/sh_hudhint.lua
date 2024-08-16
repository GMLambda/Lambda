if SERVER then
    AddCSLuaFile()
end

local util = util
local player = player
local IsValid = IsValid
local table = table

if SERVER then
    util.AddNetworkString("LambdaHudHint")

    function GM:AddHint(text, time, ply)
        ply = ply or player.GetAll()
        net.Start("LambdaHudHint")
        net.WriteString(text)
        net.WriteFloat(time)
        net.Send(ply)
    end
else -- CLIENT
    function GM:AddHint(text, time)
        local hint = vgui.Create("lambda_hud_hint")
        hint:SetText(text)
        hint:SetTime(time)
        hint:SetAlpha(0)
        hint:AlphaTo(255, 0.7, 0.1)
        hint:SetPos(ScrW(), ScrH() * 0.8)
        hint.unique = table.insert(HINTS, hint)
        local y = ScrH() * 0.8

        for i = 0, #HINTS do
            local pnl = HINTS[#HINTS - i]

            if IsValid(pnl) then
                pnl:MoveTo(ScrW() - hint:GetWide() - 20, y, 0.3, 0, 0.9)
                y = y - (pnl:GetTall() + 8)
            end
        end
    end

    local function LocalizeWithInput(text, default)
        local msg = language.GetPhrase(text, default)
        -- Process key bindings.
        local i = 1
        while i ~= nil do
            local pos = string.find(msg, "%", i, true)
            if pos == nil then break end
            local endPos = string.find(msg, "%", pos + 1, true)
            if endPos == nil then break end
            local leftPart = string.sub(msg, 1, pos - 1)
            local rightPart = string.sub(msg, endPos + 1)
            local key = string.sub(msg, pos + 1, endPos - 1)
            local binding = input.LookupBinding(key, true)

            if binding ~= nil then
                binding = string.upper(binding)
                msg = leftPart .. "<" .. binding .. ">" .. rightPart
                i = pos + 1
            else
                i = endPos + 1
            end
        end

        return msg
    end

    net.Receive("LambdaHudHint", function(len)
        local text = net.ReadString()
        local time = net.ReadFloat()
        text = LocalizeWithInput(text, text)
        GAMEMODE:AddHint(text, time)
    end)
end