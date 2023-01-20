if SERVER then
    AddCSLuaFile()
end

local math = math
local CurTime = CurTime
INTERP_LINEAR = 1
INTERP_SPLINE = 2
local MT_InterpValue = {}
MT_InterpValue.__index = MT_InterpValue

local function interpLinear(var, t)
    t = t or CurTime()
    if t >= var.EndTime then return var.EndVal end
    if t <= var.StartTime then return var.StartVal end

    return math.Remap(t, var.StartTime, var.EndTime, var.StartVal, var.EndVal)
end

local function simpleSpline(val)
    local sqr = val * val

    return 3 * sqr - 2 * sqr * val
end

local function simpleSplineRemapVal(val, A, B, C, D)
    if A == B then
        if val >= B then
            return D
        else
            return C
        end
    end

    local cVal = (val - A) / (B - A)

    return C + (D - C) * simpleSpline(cVal)
end

local function interpSpline(var, t)
    t = t or CurTime()
    if t >= var.EndTime then return var.EndVal end
    if t <= var.StartTime then return var.StartVal end

    return simpleSplineRemapVal(t, var.StartTime, var.EndTime, var.StartVal, var.EndVal)
end

function MT_InterpValue:Init(startVal, endVal, dt, interpType)
    interpType = interpType or INTERP_LINEAR
    self:SetType(interpType)

    if dt <= 0.0 then
        self:SetTime(CurTime(), CurTime())

        return self:SetAbsolute(endVal)
    end

    self:SetTime(CurTime(), CurTime() + dt)
    self:SetRange(startVal, endVal)
end

function MT_InterpValue:InitFromCurrent(endVal, dt, interpType)
    return self:Init(self:Interp(CurTime()), endVal, dt, interpType)
end

function MT_InterpValue:SetAbsolute(val)
    self.StartVal = val
    self.EndVal = val
    self.InterpType = INTERP_LINEAR
end

function MT_InterpValue:SetTime(curT, endT)
    self.StartTime = curT
    self.EndTime = endT
end

function MT_InterpValue:SetRange(startVal, endVal)
    self.StartVal = startVal
    self.EndVal = endVal
end

function MT_InterpValue:SetType(interpType)
    self.InterpType = interpType

    if interpType == INTERP_LINEAR then
        self.Interp = interpLinear
    elseif interpType == INTERP_SPLINE then
        self.Interp = interpSpline
    else
        error("Invalid interpolation type supplied")
    end
end

function MT_InterpValue:Interp(dt)
    error("Invalid type set")
end

function InterpValue(startVal, endVal, dt, interpType)
    startVal = startVal or 0
    endVal = endVal or 0
    dt = dt or 0
    interpType = interpType or INTERP_LINEAR
    local var = setmetatable({}, MT_InterpValue)
    var:Init(startVal, endVal, dt, interpType)

    return var
end