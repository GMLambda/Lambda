GM.PickupHistory = {}
GM.PickupHistoryLast = 0
GM.PickupHistoryWide = 300
GM.PickupHistoryCorner = surface.GetTextureID("gui/corner8")
GM.PickupHistoryMax = 6
GM.PickupHistoryTop = 0

GM.SymbolLookupTable = {
    ["Pistol"] = "p",
    ["SMG1"] = "r",
    ["SMG1_Grenade"] = "t",
    ["357"] = "q",
    ["AR2"] = "u",
    ["AR2AltFire"] = "z",
    ["Buckshot"] = "s",
    ["XBowBolt"] = "w",
    ["Grenade"] = "v",
    ["RPG_Round"] = "x",
    ["slam"] = "o",
    ["weapon_smg1"] = "&",
    ["weapon_shotgun"] = "(",
    ["weapon_pistol"] = "%",
    ["weapon_357"] = "$",
    ["weapon_crossbow"] = ")",
    ["weapon_ar2"] = ":",
    ["weapon_frag"] = "_",
    ["weapon_rpg"] = ";",
    ["weapon_crowbar"] = "^",
    ["weapon_physcannon"] = "!",
    ["weapon_physgun"] = "!",
    ["weapon_bugbait"] = "~",
    ["weapon_slam"] = "o",
    ["item_healthkit"] = "+",
    ["item_healthvial"] = "+",
    ["item_battery"] = "*"
}

local function GetTextColor()
    local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")

    return Color(col.x, col.y, col.z, 255)
end

local function GetBGColor()
    local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")

    return Color(col.x, col.y, col.z, 128)
end

surface.CreateFont("LAMBDA_AMMO", {
    font = "halflife2",
    size = 38
})

function GM:UpdatePickupHistory()
    local i = 0

    for _, v in pairs(self.PickupHistory) do
        v.timescale = math.Clamp(table.Count(self.PickupHistory) - i / self.PickupHistoryMax * 10, 1, 10)
        i = i + 1
    end
end

--[[---------------------------------------------------------
   Name: gamemode:HUDWeaponPickedUp( wep )
   Desc: The game wants you to draw on the HUD that a weapon has been picked up
-----------------------------------------------------------]]
function GM:HUDWeaponPickedUp(wep)
    if (not IsValid(LocalPlayer()) or not LocalPlayer():Alive()) then return end
    if (not IsValid(wep)) then return end
    if (not isfunction(wep.GetPrintName)) then return end
    if wep.ShouldHidePickupInfo ~= nil and wep:ShouldHidePickupInfo() == true then return end
    local pickup = {}
    pickup.time = CurTime()
    pickup.elapsed = 0
    pickup.timescale = 1
    pickup.symbol = self.SymbolLookupTable[wep:GetClass()]
    pickup.name = wep:GetPrintName()
    pickup.holdtime = 10
    pickup.fadein = 0.04
    pickup.fadeout = 0.3
    pickup.font = "DermaDefaultBold"
    pickup.color = Color(255, 220, 0, 100)
    surface.SetFont(pickup.font)
    local w, h = surface.GetTextSize(pickup.name)
    pickup.theight = h
    pickup.twidth = w
    pickup.height = 32
    pickup.width = w

    if pickup.symbol then
        surface.SetFont("LAMBDA_AMMO")
        w, h = surface.GetTextSize(pickup.symbol)
        pickup.width = pickup.width + w + 16
        pickup.swidth = math.Clamp(w, 48, 64)
        pickup.sheight = math.Clamp(h, 38, 52)
    end

    if (self.PickupHistoryLast >= pickup.time) then
        pickup.time = self.PickupHistoryLast + 0.05
    end

    table.insert(self.PickupHistory, pickup)
    self.PickupHistoryLast = pickup.time
    self:UpdatePickupHistory()
end

--[[---------------------------------------------------------
   Name: gamemode:HUDItemPickedUp( itemname )
   Desc: An item has been picked up..
-----------------------------------------------------------]]
function GM:HUDItemPickedUp(itemname)
    if (not IsValid(LocalPlayer()) or not LocalPlayer():Alive()) then return end

    -- Try to tack it onto an exisiting ammo pickup
    if (self.PickupHistory) then
        for k, v in pairs(self.PickupHistory) do
            if (v.name == "#" .. itemname) then
                v.amount = v.amount + 1
                local fadeDelay = 1 - v.fadein
                local fadeOut = 1 - v.fadeout
                local elapsed = CurTime() - v.time

                if elapsed > (v.holdtime - fadeDelay - fadeOut) then
                    v.time = CurTime() - v.fadein
                else
                    v.time = CurTime() - fadeDelay
                end

                return
            end
        end
    end

    local pickup = {}
    pickup.time = CurTime()
    pickup.elapsed = 0
    pickup.timescale = 1
    pickup.name = "#" .. itemname
    pickup.holdtime = 10
    pickup.fadein = 0.04
    pickup.fadeout = 0.3
    pickup.font = "DermaDefaultBold"
    pickup.color = Color(180, 255, 180, 255)
    pickup.amount = 1
    pickup.symbol = self.SymbolLookupTable[itemname]
    surface.SetFont(pickup.font)
    local w, h = surface.GetTextSize(pickup.name)
    pickup.theight = h
    pickup.twidth = w
    pickup.height = 32
    pickup.width = w
    w, h = surface.GetTextSize(pickup.amount)
    pickup.xwidth = w
    pickup.width = pickup.width + w + 16

    if pickup.symbol then
        surface.SetFont("LAMBDA_AMMO")
        w, h = surface.GetTextSize(pickup.symbol)
        pickup.width = pickup.width + w + 16
        pickup.swidth = math.Clamp(w, 48, 50)
        pickup.sheight = math.Clamp(h, 32, 52)
    end

    if (self.PickupHistoryLast >= pickup.time) then
        pickup.time = self.PickupHistoryLast + 0.05
    end

    table.insert(self.PickupHistory, pickup)
    self.PickupHistoryLast = pickup.time
    self:UpdatePickupHistory()
end

--[[---------------------------------------------------------
   Name: gamemode:HUDAmmoPickedUp( itemname, amount )
   Desc: Ammo has been picked up..
-----------------------------------------------------------]]
function GM:HUDAmmoPickedUp(itemname, amount)
    if (not IsValid(LocalPlayer()) or not LocalPlayer():Alive()) then return end

    -- Try to tack it onto an exisiting ammo pickup
    if (self.PickupHistory) then
        for k, v in pairs(self.PickupHistory) do
            if (v.name == "#" .. itemname .. "_ammo") then
                v.amount = tostring(tonumber(v.amount) + amount)
                local fadeDelay = 1 - v.fadein
                local fadeOut = 1 - v.fadeout
                local elapsed = CurTime() - v.time

                if elapsed > (v.holdtime - fadeDelay - fadeOut) then
                    v.time = CurTime() - v.fadein
                else
                    v.time = CurTime() - fadeDelay
                end

                return
            end
        end
    end

    --DbgPrint(itemname)
    local pickup = {}
    pickup.time = CurTime()
    pickup.elapsed = 0
    pickup.timescale = 1
    pickup.symbol = self.SymbolLookupTable[itemname]
    pickup.name = "#" .. itemname .. "_ammo"
    pickup.holdtime = 10
    pickup.fadein = 0.04
    pickup.fadeout = 0.3
    pickup.font = "DermaDefaultBold"
    pickup.color = Color(180, 200, 255, 255)
    pickup.amount = tostring(amount)
    surface.SetFont(pickup.font)
    local w, h = surface.GetTextSize(pickup.name)
    pickup.theight = h
    pickup.twidth = w
    pickup.height = 32
    pickup.width = w
    w, h = surface.GetTextSize(pickup.amount)
    pickup.xwidth = w
    pickup.width = pickup.width + w + 16

    if pickup.symbol then
        surface.SetFont("LAMBDA_AMMO")
        w, h = surface.GetTextSize(pickup.symbol)
        pickup.width = pickup.width + w + 16
        pickup.swidth = math.Clamp(w, 48, 64)
        pickup.sheight = math.Clamp(h, 32, 56)
    end

    if (self.PickupHistoryLast >= pickup.time) then
        pickup.time = self.PickupHistoryLast + 0.05
    end

    table.insert(self.PickupHistory, pickup)
    self.PickupHistoryLast = pickup.time
    self:UpdatePickupHistory()
end

local function DrawBlurRect(x, y, w, h, alpha)
    local colBg = GetBGColor()
    draw.NoTexture()
    draw.RoundedBox(3, x, y, w, h, colBg)
end

function GM:HUDDrawPickupHistory()
    if (self.PickupHistory == nil) then return end
    local x, y = ScrW() - self.PickupHistoryWide - 20, ScrH() / 4
    local tall = 0
    local wide = 0

    for k, v in pairs(self.PickupHistory) do
        if (not istable(v)) then
            Msg(tostring(v) .. "\n")
            self.PickupHistory[k] = nil

            return
        end

        v.elapsed = v.elapsed or 0

        if (v.elapsed < v.holdtime) then
            if (v.y == nil) then
                v.y = y
            end

            v.y = y
            v.elapsed = v.elapsed + (FrameTime() * 2 * v.timescale)
            local delta = v.holdtime - v.elapsed
            delta = delta / v.holdtime
            local alpha = 255

            -- Fade in/out
            if (delta > 1 - v.fadein) then
                alpha = math.Clamp((1.0 - delta) * (255 / v.fadein), 0, 255)
            elseif (delta < v.fadeout) then
                alpha = math.Clamp(delta * (255 / v.fadeout), 0, 255)
            end

            v.x = x + self.PickupHistoryWide - (self.PickupHistoryWide * (alpha / 255))
            local rx = math.Round(v.x)
            local ry = math.Round(v.y - (v.height / 2) - 4)
            local rw = math.Round(self.PickupHistoryWide + 19)
            local rh = math.Round(v.height)
            DrawBlurRect(rx, ry, rw, rh, alpha)
            local offsetX = 0
            local col = GetTextColor()
            col.a = alpha

            if v.symbol ~= nil then
                draw.SimpleText(v.symbol, "LAMBDA_AMMO", rx + 60, ry + (v.height / 2) - (v.sheight / 2), col, TEXT_ALIGN_RIGHT)
                offsetX = 40
            end

            draw.SimpleText(v.name, v.font, offsetX + rx + (v.swidth or 55), ry + (v.height / 2) - (v.theight / 2), col)

            if (v.amount) then
                --draw.SimpleText( v.amount, v.font, v.x + self.PickupHistoryWide + 1, v.y - ( v.height / 2 ) + 4, Color( 0, 0, 0, alpha * 0.5 ), TEXT_ALIGN_RIGHT )
                draw.SimpleText(v.amount, v.font, rx + self.PickupHistoryWide, ry + (v.height / 2) - (v.theight / 2), col, TEXT_ALIGN_RIGHT)
            end

            y = y + (v.height + 2)
            tall = tall + v.height + 18
            wide = math.Max(wide, v.width + v.height + 24)

            if (alpha == 0) then
                self.PickupHistory[k] = nil
            end
        end
    end

    self.PickupHistoryTop = (self.PickupHistoryTop * 5 + (ScrH() * 0.75 - tall) / 2) / 6
    self.PickupHistoryWide = (self.PickupHistoryWide * 5 + wide) / 6
end
