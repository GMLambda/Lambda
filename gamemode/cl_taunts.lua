include("sh_taunts.lua")

--local DbgPrint = GetLogging("Taunts")
local TauntIndex = CreateClientConVar("_lambda_taunt_idx", "1", true)
local CategoryIndex = CreateClientConVar("_lambda_taunt_cat_idx", "1", true)

local TauntMaxDisplay = 3 -- Each direction
local TauntSelection = false

surface.CreateFont("TauntFont",
{
    font = "Arial",
    size = 30,
    weight = 500,
    blursize = 1,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = true
})

surface.CreateFont("TauntFont2",
{
    font = "Arial",
    size = 30,
    weight = 100,
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
    outline = false
})

local function DrawTauntElement(text, xpos, size, alpha, offset)

    local w, h = ScrW(), ScrH()
    local x = 100
    local y = (h / 2) + xpos
    offset = offset or 0
    --mat:Translate( Vector( w/2, h/2 ) )
    --mat:Rotate( Angle( 0,0,0 ) )

    local mat1 = Matrix()
    mat1:Scale( Vector(1, 1, 1) * size )
    mat1:SetTranslation( Vector( x, y, 0 ) )
    --mat:Translate( -Vector( w/2, h/2 ) )

    render.PushFilterMag( TEXFILTER.ANISOTROPIC )
    render.PushFilterMin( TEXFILTER.ANISOTROPIC )

    cam.PushModelMatrix(mat1)
        surface.SetTextPos(offset, 0)
        surface.SetFont("TauntFont")
        surface.SetTextColor(0, 0, 0, alpha * 0.5)
        surface.DrawText(text)
    cam.PopModelMatrix()

    local mat2 = Matrix()
    mat2:Scale( Vector(1, 1, 1) * size )
    mat2:SetTranslation( Vector( x, y, 0 ) )

    cam.PushModelMatrix(mat2)
            surface.SetTextPos(offset, 0)
            surface.SetFont("TauntFont2")
            surface.SetTextColor(255, 255, 255, alpha)
            surface.DrawText(text)
    cam.PopModelMatrix()

    render.PopFilterMag()
    render.PopFilterMin()

    return w, h

end

function GM:DrawTauntsMenu()

    if TauntSelection == false then
        return
    end

    local ply = LocalPlayer()
    local categoryId = CategoryIndex:GetInt()
    local taunts = self:GetPlayerTaunts(ply, categoryId)
    local count = 0
    if taunts ~= nil then
        count = #taunts
    end

    local tauntIndex = TauntIndex:GetInt()
    if tauntIndex > count then
        tauntIndex = count
    end
    if tauntIndex < 1 then
        tauntIndex = 1
    end

    local x
    local xpos = (3 * 20) + math.pow(3, 1.5)

    -- Back
    local back_max = tauntIndex - TauntMaxDisplay
    if back_max < 1 then
        back_max = 1
    end

    x = 1
    for i = (tauntIndex - 1), back_max, -1 do
        local taunt = taunts[i]
        if not taunt then
            break
        end
        local alpha = (1 - (x / 4)) * 50
        DrawTauntElement(taunt.Name, xpos, 1.2 - (x / 3), alpha)
        x = x + 1
        xpos = xpos - 35 - math.pow(x + 1, 1.1)
    end

    xpos = (3 * 20) + math.pow(3, 1.2) + 40

    -- Current
    local taunt = taunts[tauntIndex]
    if not taunt then
        return
    end

    --text, xpos, size, alpha
    local scaleTime = CurTime() * 4
    local offset = 10 + (math.sin(scaleTime) * math.cos(scaleTime)) * 10
    DrawTauntElement(taunt.Name, xpos, 1.3, 255, offset)
    xpos = xpos + 50

    -- Front
    local front_max = tauntIndex + TauntMaxDisplay
    if front_max > count then
        front_max = count
    end

    x = 1
    for i = (tauntIndex + 1), front_max do
        taunt = taunts[i]
        if not taunt then
            break
        end
        local alpha = (1 - (x / 4)) * 50
        DrawTauntElement(taunt.Name, xpos, 1.2 - (x / 3), alpha)
        x = x + 1
        xpos = xpos + 35 + math.pow(x + 1, 1.1)
    end

end

function GM:SendSelectedTaunt()

    local ply = LocalPlayer()
    ply.LastTaunt = ply.LastTaunt or (RealTime() - 5)

    if RealTime() - ply.LastTaunt < 2 then
        return false
    end

    ply.LastTaunt = RealTime()

    local categoryId = CategoryIndex:GetInt()
    local taunts = self:GetPlayerTaunts(ply, categoryId)
    local count = #taunts

    local tauntIndex = TauntIndex:GetInt()
    if tauntIndex < 1 or tauntIndex > count then
        return false
    end

    local taunt = taunts[tauntIndex]
    if not taunt then
        return false
    end

    net.Start("PlayerStartTaunt")
    net.WriteInt(categoryId, 16)
    net.WriteInt(tauntIndex, 16)
    net.SendToServer()
end

function GM:ShowTauntSelection(state)
    if TauntSelection == true and state == false then
        self:SendSelectedTaunt()
    end
    TauntSelection = state
end

function GM:IsTauntSelectionOpen()
    return TauntSelection
end

function GM:TauntSelectionInput(ply, bind, pressed)
    local tauntIndex = TauntIndex:GetInt()
    local update
    if TauntSelection then
        if bind == "invnext" and pressed then
            tauntIndex = tauntIndex + 1
            update = true
        elseif bind == "invprev" and pressed then
            tauntIndex = tauntIndex - 1
            update = true
        end
    end
    if update == true then
        local categoryId = CategoryIndex:GetInt()
        local taunts = self:GetPlayerTaunts(ply, categoryId)
        tauntIndex = math.Clamp(tauntIndex, 1, #taunts)
        TauntIndex:SetInt(tauntIndex)
    end
    return update
end
