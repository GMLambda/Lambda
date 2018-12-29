if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("LambdaMetrics")
end

local DEFAULT_HITS =
{
    [HITGROUP_GENERIC] = 0,
    [HITGROUP_HEAD] = 0,
    [HITGROUP_CHEST] = 0,
    [HITGROUP_STOMACH] = 0,
    [HITGROUP_LEFTARM] = 0,
    [HITGROUP_RIGHTARM] = 0,
    [HITGROUP_LEFTLEG] = 0,
    [HITGROUP_RIGHTLEG] = 0,
}

local DEFAULT_BULLET_DATA =
{
    ["NPC"] = { Fired = 0, Hits = {} },
    ["Player"] = { Fired = 0, Hits = {} },
}

function GM:ResetMetrics()

    BULLET_DATA = table.Copy(DEFAULT_BULLET_DATA)
    BULLET_DATA["NPC"].Hits = table.Copy(DEFAULT_HITS)
    BULLET_DATA["Player"].Hits = table.Copy(DEFAULT_HITS)

end

GM:ResetMetrics()

local function GetGroup(ent)
    if not IsValid(ent) then
        return nil
    end
    if ent:IsNPC() then
        return "NPC"
    elseif ent:IsPlayer() then
        return "Player"
    end
    return nil
end

local NEXT_NETWORK_UPDATE = CurTime()

local function NetworkUpdate()

    if GAMEMODE:GetSetting("difficulty_metrics") == false then
        return
    end
    
    if CurTime() < NEXT_NETWORK_UPDATE then
        return
    end

    if player.GetCount() > 0 then
        net.Start("LambdaMetrics")
        net.WriteTable(BULLET_DATA)
        net.Broadcast()
    end

    NEXT_NETWORK_UPDATE = CurTime() + 1

end

function GM:MetricsRegisterBullet(ent, amount)

    local group = GetGroup(ent)
    if group == nil then return end

    local data = BULLET_DATA[group]
    data.Fired = data.Fired + amount

    NetworkUpdate()

end

function GM:MetricsRegisterBulletHit(attacker, target, hitgroup)

    if not IsValid(attacker) then
        return
    end

    local group = GetGroup(attacker)
    if group == nil then return end

    local data = BULLET_DATA[group]
    data.Hits[hitgroup] = data.Hits[hitgroup] + 1

    NetworkUpdate()

end

if CLIENT then
    net.Receive("LambdaMetrics", function(len)

        BULLET_DATA = net.ReadTable()

    end)

    surface.CreateFont( "LAMBDA_METRICS",
    {
        font = "Consolas",
        size = 13,
        weight = 300,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    } )
end

local HITGROUP_NAME =
{
    [HITGROUP_GENERIC] = "Generic",
    [HITGROUP_HEAD] = "Head",
    [HITGROUP_CHEST] = "Chest",
    [HITGROUP_STOMACH] = "Stomach",
    [HITGROUP_LEFTARM] = "Left Arm",
    [HITGROUP_RIGHTARM] = "Right Arm",
    [HITGROUP_LEFTLEG] = "Left Leg",
    [HITGROUP_RIGHTLEG] = "Right Leg",
}

-- Difficulty setting, 1 = Very Easy, 2 = Easy, 3 = Normal, 4 = Hard, 5 = Extreme

local function GetAccuracy(v, max)
    if max == 0 then
        return 0
    end
    return (v / max) * 100.0
end

function GM:DrawMetrics()

    if self:GetSetting("difficulty_metrics") == false then
        return
    end

    local y = 10

    -- Draw Difficulty
    do
        local difficulty = self:GetDifficultyText()
        draw.DrawText("Difficulty: " .. difficulty, "LAMBDA_METRICS", 10, y, Color(255, 255, 255, 255))
        y = y + 15
    end

    -- Proficiency
    do
        local proficiency = self:GetDifficultyWeaponProficiencyText()
        draw.DrawText("Proficiency: " .. proficiency, "LAMBDA_METRICS", 10, y, Color(255, 255, 255, 255))
        y = y + 15
    end

    do
        local data = BULLET_DATA["NPC"]
        local total = 0
        local headY = y
        y = y + 15
        for k,v in pairs(data.Hits) do
            local hitGroup = HITGROUP_NAME[k]
            local accuracy = GetAccuracy(v, data.Fired)
            total = total + v
            local text = hitGroup .. ": " .. string.format("%.02f", accuracy) .. "%"
            draw.DrawText(text, "LAMBDA_METRICS", 25, y, Color(255, 255, 255, 255))
            y = y + 15
        end
        local accuracy = GetAccuracy(total, data.Fired)
        local text = "NPC Accuracy: " .. string.format("%.02f", accuracy) .. "%"
        draw.DrawText(text, "LAMBDA_METRICS", 10, headY, Color(255, 255, 255, 255))
    end

    do
        local data = BULLET_DATA["Player"]
        local total = 0
        local headY = y
        y = y + 15
        for k,v in pairs(data.Hits) do
            local hitGroup = HITGROUP_NAME[k]
            local accuracy = GetAccuracy(v, data.Fired)
            if data.Fired == 0 then
                accuracy = 0
            end
            total = total + v
            local text = hitGroup .. ": " .. string.format("%.02f", accuracy) .. "%"
            draw.DrawText(text, "LAMBDA_METRICS", 25, y, Color(255, 255, 255, 255))
            y = y + 15
        end
        local accuracy = GetAccuracy(total, data.Fired)
        local text = "Player Accuracy: " .. string.format("%.02f", accuracy) .. "%"
        draw.DrawText(text, "LAMBDA_METRICS", 10, headY, Color(255, 255, 255, 255))
    end


end 