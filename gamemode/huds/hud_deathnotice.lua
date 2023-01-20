local Color_Icon = Color(230, 230, 230, 130)
local NPC_Color = Color(250, 50, 50, 255)
local times_color = Color(255, 255, 255, 255)
local font = "LambdaKillFont"

local function CreateFonts()
    surface.CreateFont(font, {
        font = "Tahoma",
        size = util.ScreenScaleH(7),
        weight = 800,
        antialias = true,
        additive = false
    })

    surface.CreateFont("LambdaKillico", {
        font = "HL2MP",
        size = util.ScreenScaleH(22),
        weight = 100,
        antialias = true,
        additive = false
    })

    killicon.AddFont("weapon_smg1", "LambdaKillico", "/", Color_Icon)
    killicon.AddFont("weapon_smg1", "LambdaKillico", "/", Color_Icon)
    killicon.AddFont("weapon_357", "LambdaKillico", ".", Color_Icon)
    killicon.AddFont("weapon_ar2", "LambdaKillico", "2", Color_Icon)
    killicon.AddFont("crossbow_bolt", "LambdaKillico", "1", Color_Icon)
    killicon.AddFont("weapon_shotgun", "LambdaKillico", "0", Color_Icon)
    killicon.AddFont("rpg_missile", "LambdaKillico", "3", Color_Icon)
    killicon.AddFont("npc_grenade_frag", "LambdaKillico", "4", Color_Icon)
    killicon.AddFont("weapon_pistol", "LambdaKillico", "-", Color_Icon)
    killicon.AddFont("prop_combine_ball", "LambdaKillico", "8", Color_Icon)
    killicon.AddFont("grenade_ar2", "LambdaKillico", "7", Color_Icon)
    killicon.AddFont("weapon_stunstick", "LambdaKillico", "!", Color_Icon)
    killicon.AddFont("npc_satchel", "LambdaKillico", "*", Color_Icon)
    killicon.AddFont("npc_tripmine", "LambdaKillico", "*", Color_Icon)
    killicon.AddFont("weapon_crowbar", "LambdaKillico", "6", Color_Icon)
    killicon.AddFont("weapon_physcannon", "LambdaKillico", ",", Color_Icon)
    killicon.Add("prop_physics", "killicons/func_physbox_killicon", Color_Icon)
    killicon.Add("func_physbox", "killicons/func_physbox_killicon", Color_Icon)
    killicon.Add("func_physbox_multiplayer", "killicons/func_physbox_killicon", Color_Icon)
    killicon.Add("env_fire", "killicons/env_fire_killicon", Color_Icon)
    killicon.Add("entityflame", "killicons/env_fire_killicon", Color_Icon)
    killicon.Add("env_explosion", "killicons/env_explosion_killicon", Color_Icon)
    killicon.Add("env_physexplosion", "killicons/env_explosion_killicon", Color_Icon)
    killicon.Add("point_hurt", "killicons/point_hurt_killicon", Color_Icon)
    killicon.Add("trigger_hurt", "killicons/point_hurt_killicon", Color_Icon)
    killicon.Add("radiation", "killicons/radiation_killicon", Color_Icon)
    killicon.Add("func_door", "killicons/func_door_killicon", Color_Icon)
    killicon.Add("func_door_rotating", "killicons/func_door_killicon", Color_Icon)
    killicon.Add("prop_door_rotating", "killicons/func_door_killicon", Color_Icon)
    killicon.Add("npc_barnacle", "killicons/npc_barnacle_killicon", Color_Icon)
    killicon.Add("npc_manhack", "killicons/npc_manhack_killicon", Color_Icon)
    killicon.Add("fall", "killicons/worldspawn_killicon", Color_Icon)
    killicon.Add("combine_mine", "killicons/combine_mine_killicon", Color_Icon)
end

local DeathsData = {
    Bounds = nil,
    Entries = {}
}

local function RecieveDeathEvent()
    local data = net.ReadTable()
    GAMEMODE:AddDeathNotice(data)
end

net.Receive("LambdaDeathEvent", RecieveDeathEvent)

local WEAPON_TYPES = {
    ["grenade_ar2"] = true,
    ["combine_mine"] = true,
    ["rpg_missile"] = true,
    ["npc_grenade_frag"] = true,
    ["grenade_frag"] = true
}

function GM:AddDeathNotice(data)
    local death = {}
    death.time = CurTime()
    death.times = 1
    local dmgType = data.dmgType
    local inflictor = data.inflictor

    if inflictor ~= nil then
        death.icon = inflictor.class

        if bit.band(dmgType, DMG_BLAST) ~= 0 and WEAPON_TYPES[inflictor.class] ~= true then
            death.icon = "env_explosion"
        end
    end

    local attacker = data.attacker

    if attacker ~= nil then
        if attacker.isPlayer then
            death.left = Entity(attacker.entIndex):Name()
        else
            death.left = "#" .. attacker.class
        end

        if attacker.class == "trigger_hurt" then
            death.left = nil
        elseif attacker.class == "combine_mine" then
            death.icon = "combine_mine"
        end
    end

    local victim = data.victim

    if victim ~= nil then
        if victim.isPlayer then
            death.right = Entity(victim.entIndex):Name()
        else
            death.right = "#" .. victim.class
        end
    end

    if death.left == death.right and data.selfInflicted == true then
        death.left = nil
    end

    if death.left == nil then
        if bit.band(dmgType, DMG_BLAST) ~= 0 then
            death.left = "EXPLOSION"
        elseif bit.band(dmgType, DMG_CRUSH) ~= 0 then
            death.left = "CRUSHED"
        elseif bit.band(dmgType, DMG_POISON) ~= 0 then
            death.left = "POISON"
        elseif bit.band(dmgType, DMG_RADIATION) ~= 0 then
            death.left = "RADIATION"
            death.icon = "radiation"
        elseif bit.band(dmgType, DMG_DROWN) ~= 0 then
            death.left = "DROWNED"
        elseif bit.band(dmgType, DMG_FALL) ~= 0 then
            death.left = "FELL"
            death.icon = "fall"
        elseif bit.band(dmgType, DMG_SHOCK) ~= 0 then
            death.left = "SHOCK"
        elseif bit.band(dmgType, DMG_ENERGYBEAM) ~= 0 then
            death.left = "BEAM"
        end
    end

    if death.icon == nil then
        death.icon = "default"
    end

    for k, v in pairs(DeathsData.Entries) do
        if v.left == death.left and v.icon == death.icon and v.right == death.right then
            death.times = v.times + 1
            death.lerpY = v.lerpY
            table.remove(DeathsData.Entries, k)
            break
        end
    end

    if attacker == nil or attacker.team == nil then
        death.color1 = table.Copy(NPC_Color)
    else
        death.color1 = table.Copy(team.GetColor(attacker.team))
    end

    if victim == nil or victim.team == nil then
        death.color2 = table.Copy(NPC_Color)
    else
        death.color2 = table.Copy(team.GetColor(victim.team))
    end

    DeathsData.Bounds = nil
    table.insert(DeathsData.Entries, death)
end

local function ComputeDeathNoticeSize(death, bounds)
    local txtW
    local txtH
    local totalW = 0

    if death.left ~= nil then
        surface.SetFont(font)
        txtW, txtH = surface.GetTextSize(death.left)
        death.leftW = txtW
        death.leftH = txtH
        totalW = totalW + txtW
        bounds.left = math.max(bounds.left, txtW)
        bounds.height = math.max(bounds.height, txtH)
    end

    if death.right ~= nil then
        surface.SetFont(font)
        txtW, txtH = surface.GetTextSize(death.right)
        death.rightW = txtW
        death.rightH = txtH
        totalW = totalW + txtW
        bounds.right = math.max(bounds.right, txtW)
        bounds.height = math.max(bounds.height, txtH)
    end

    local killiconW, killiconH = killicon.GetSize(death.icon)

    if killiconW ~= nil and killiconH ~= nil then
        death.killiconW = killiconW
        death.killiconH = killiconH
        bounds.killiconW = math.max(bounds.killiconW, killiconW)
        bounds.killiconH = math.max(bounds.killiconH, killiconH)
        bounds.height = math.max(bounds.height, killiconH / 2)
    end

    if death.times > 1 then
        local txt = "x" .. tostring(death.times)
        surface.SetFont(font)
        txtW, txtH = surface.GetTextSize(txt)
        death.counterW = txtW
        death.counterH = txtH
        bounds.counterW = math.max(bounds.counterW, txtW)
        bounds.counterH = math.max(bounds.counterH, txtH)
    end
end

local function DrawDeathEntry(bounds, y, data, margin, remaining)
    local alpha = math.Clamp(remaining * 255, 0, 255)
    data.color1.a = alpha
    data.color2.a = alpha
    times_color.a = alpha
    local x = ScrW()
    x = x - margin
    -- Draw count.
    x = x - bounds.counterW

    if data.times > 1 then
        local txt = "x" .. data.times
        draw.SimpleText(txt, font, x, y, times_color, TEXT_ALIGN_LEFT)
    end

    x = x - margin
    -- Draw victim.
    x = x - bounds.right

    if data.right ~= nil then
        draw.SimpleText(data.right, font, x, y, data.color2, TEXT_ALIGN_LEFT)
    end

    x = x - margin
    -- Draw kill icon, its always drawn at center.
    local killiconHalf = (data.killiconW / 2)
    local alignKilliconHalf = bounds.killiconW / 2
    local killiconOffset = 0

    if alignKilliconHalf > killiconHalf then
        killiconOffset = alignKilliconHalf - killiconHalf
    end

    x = x - killiconHalf - killiconOffset
    killicon.Draw(x, y, data.icon, alpha)
    x = x - killiconHalf - killiconOffset
    x = x - margin

    -- Draw attacker.
    if data.left ~= nil then
        x = x - data.leftW
        draw.SimpleText(data.left, font, x, y, data.color1, TEXT_ALIGN_LEFT)
    end
end

function GM:DrawDeathNotice()
    local deathnotice_time = lambda_deathnotice_time:GetFloat()
    local fadeTime = deathnotice_time * 0.8 -- Fade out at 80%
    local visibleTime = deathnotice_time - fadeTime
    local curTime = CurTime()
    local margin = util.ScreenScaleH(8)
    -- Compute size if we have new/modified entries.
    local bounds = DeathsData.Bounds

    if bounds == nil then
        bounds = {
            left = 0,
            right = 0,
            killiconW = 0,
            killiconH = 0,
            counterW = 0,
            counterH = 0,
            height = 0
        }

        for _, v in pairs(DeathsData.Entries) do
            ComputeDeathNoticeSize(v, bounds)
        end

        DeathsData.Bounds = bounds
    end

    -- Draw
    local y = util.ScreenScaleH(15)

    for k, data in pairs(DeathsData.Entries) do
        local elapsed = curTime - data.time
        local remaining = 1.0

        if elapsed > visibleTime then
            remaining = math.Clamp(1.0 - ((elapsed - visibleTime) / fadeTime), 0.0, 1.0)
        end

        if remaining > 0.0 then
            data.lerpY = Lerp(FrameTime() * 5, data.lerpY or y, y)
            DrawDeathEntry(bounds, data.lerpY, data, margin, remaining)
            y = y + bounds.height + margin
        else
            -- Invalidate bounds.
            DeathsData.Bounds = nil
            -- Remove expired entry.
            table.remove(DeathsData.Entries, k)
        end
    end
end

-- Since we manually draw everything we still need a init for resolution changes.
function GM:DeathNoticeHUDInit()
    CreateFonts()
end