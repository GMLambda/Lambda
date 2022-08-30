if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Settings")

function GM:InitSettings()
    DbgPrint("GM:InitSettings")

    self.Settings = {}

    local gameType = self:GetGameType()
    gameType:InitSettings()
end

function GM:GetSettingsTable()
    return self.Settings
end

-- NOTE: For performance reason we don't capture upvalues
local function GetValueIntClampMinMax(s)
    return math.Clamp(s.CVar:GetInt(), s.Clamp.Min, s.Clamp.Max)
end
local function GetValueIntClampMin(s)
    return math.max(s.CVar:GetInt(), s.Clamp.Min)
end
local function GetValueIntClampMax(s)
    return math.min(s.CVar:GetInt(), s.Clamp.Max)
end
local function GetValueInt(s)
    return s.CVar:GetInt()
end
local function GetValueFloatClampMinMax(s)
    return math.Clamp(s.CVar:GetFloat(), s.Clamp.Min, s.Clamp.Max)
end
local function GetValueFloatClampMin(s)
    return math.max(s.CVar:GetFloat(), s.Clamp.Min)
end
local function GetValueFloatClampMax(s)
    return math.min(s.CVar:GetFloat(), s.Clamp.Max)
end
local function GetValueFloat(s)
    return s.CVar:GetFloat()
end
local function GetValueBool(s)
    return s.CVar:GetBool()
end
local function GetValueString(s)
    return s.CVar:GetString()
end

function GM:AddSetting(id, option, fn)

    DbgPrint("GM:AddSetting(", id, option, fn, ")")

    local function GetCVarValue(cvar)
        if ConVarExists(cvar) then
            if option.Type == "int" then
                return GetConVar(cvar):GetInt()
            elseif option.Type == "bool" then
                return GetConVar(cvar):GetBool()
            elseif option.Type == "float" then
                return GetConVar(cvar):GetFloat()
            else
                return GetConVar(cvar):GetString()
            end
        end
    end

    local flags = option.Flags

    -- Remove certain flags on client to avoid bad replication.
    if CLIENT and bit.band(flags, FCVAR_REPLICATED) ~= 0 and bit.band(flags, FCVAR_ARCHIVE) ~= 0 then
        DbgPrint("Removing FCVAR_ARCHIVE from " .. id)
        flags = bit.band(flags, bit.bnot(FCVAR_ARCHIVE))
    end

    local defaultValue = option.Default
    local prefix = "lambda_"
    local actualName = prefix .. id
    local storedVal = GetCVarValue(actualName)

    if storedVal ~= nil then
        defaultValue = storedVal
    end
    DbgPrint("Default value for " .. id .. ": " .. tostring(defaultValue))

    if option.Type == "int" or option.Type == "float" then
        defaultValue = tonumber(defaultValue)
    elseif option.Type == "bool" then
        defaultValue = defaultValue and "1" or "0"
    elseif option.Type == "string" then
        defaultValue = tostring(defaultValue)
    end

    local setting = {}
    setting.Category = option.Category
    setting.Name = id
    setting.NiceName = option.NiceName
    setting.Description = option.Description
    setting.HelpText = option.HelpText
    setting.Type = option.Type
    setting.Flags = option.flags
    setting.CVar = GetConVar(actualName)
    if setting.CVar == nil then
        setting.CVar = CreateConVar(actualName, tostring(defaultValue), flags, option.info)
    end
    if option.Extra ~= nil then
        setting.Extra = table.Copy(option.Extra)
    end
    if option.Clamp ~= nil then
        setting.Clamp = table.Copy(option.Clamp)
    end
    if fn ~= nil and isfunction(fn) then
        setting.fn = fn
    end

    if setting.Type == "int" then
        if option.Clamp ~= nil and option.Clamp.Min ~= nil and option.Clamp.Max ~= nil then
            setting.GetValue = GetValueIntClampMinMax
        elseif option.Clamp ~= nil and option.Clamp.Min ~= nil then
            setting.GetValue = GetValueIntClampMin
        elseif option.Clamp ~= nil and option.Clamp.Max ~= nil then
            setting.GetValue = GetValueIntClampMax
        else
            setting.GetValue = GetValueInt
        end
    elseif setting.Type == "float" then
        if option.Clamp ~= nil and option.Clamp.Min ~= nil and option.Clamp.Max ~= nil then
            setting.GetValue = GetValueFloatClampMinMax
        elseif option.Clamp ~= nil and option.Clamp.Min ~= nil then
            setting.GetValue = GetValueFloatClampMin
        elseif option.Clamp ~= nil and option.Clamp.Max ~= nil then
            setting.GetValue = GetValueFloatClampMax
        else
            setting.GetValue = GetValueFloat
        end
    elseif setting.Type == "bool" then
        setting.GetValue = GetValueBool
    else
        setting.GetValue = GetValueString
    end

    self.Settings[id] = setting

    return convar
end

function GM:GetSetting(setting, default)
    local res = self.Settings[setting]
    if res == nil then return default end
    return res:GetValue()
end

function GM:GetSettingData(setting)
    local res = self.Settings[setting]
    return res
end