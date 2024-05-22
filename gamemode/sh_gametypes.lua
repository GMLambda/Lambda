if SERVER then AddCSLuaFile() end
local DbgPrint = GetLogging("GameType")
local table = table
include("gametypes/gametype_base.lua")
include("gametypes/hl2.lua")
include("gametypes/hl2ep1.lua")
include("gametypes/hl2ep2.lua")
include("gametypes/hl2dm.lua")
include("gametypes/hl1s.lua")
local DEFAULT_MAPSCRIPT = {}
DEFAULT_MAPSCRIPT.InputFilters = {}
DEFAULT_MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow", "weapon_bugbait"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
        ["XBowBolt"] = 4
    },
    Armor = 60,
    HEV = true
}

DEFAULT_MAPSCRIPT.EntityCleanupFilter = {}
-- Default functions.
DEFAULT_MAPSCRIPT.Init = function(self) end
DEFAULT_MAPSCRIPT.PostInit = function(self) end
DEFAULT_MAPSCRIPT.PrePlayerSpawn = function(self, ply) end
DEFAULT_MAPSCRIPT.PostPlayerSpawn = function(self, ply) end
DEFAULT_MAPSCRIPT.OnNewGame = function(self) end
GameTypes = GameTypes or {}
GameTypes.Registered = {}
function GameTypes:Add(name, tbl)
    local mappedName = name:lower()
    if self.Registered[mappedName] ~= nil then error("GameType name is already taken: " .. name) end
    -- Don't reference the table.
    local data = table.Copy(tbl)
    data.GameType = mappedName
    local meta = {}
    meta.__index = function(i, k)
        local base = i
        while base ~= nil do
            local v = rawget(base, k)
            if v ~= nil then return v end
            base = rawget(base, "Base")
        end
    end

    setmetatable(data, meta)
    self.Registered[mappedName] = data
end

function GameTypes:Get(name)
    if name == nil then return nil end
    local mappedName = name:lower()
    return self.Registered[mappedName]
end

function GameTypes:GetByMap(mapName)
    for gameTypeName, v in pairs(self.Registered) do
        for _, map in pairs(v.MapList or {}) do
            if string.iequals(map, mapName) then return gameTypeName end
        end
    end
    return nil
end

function GM:LoadGameTypes()
    hook.Run("LambdaLoadGameTypes", GameTypes)
    if SERVER then
        print("-- Loaded GameTypes --")
        for k, v in pairs(GameTypes.Registered) do
            print(" > " .. k)
        end
    end

    for k, v in pairs(GameTypes.Registered) do
        if v.BaseGameType ~= nil then
            local base = GameTypes.Registered[v.BaseGameType]
            if base == nil then
                print("GameType '" .. k .. "' references missing base: '" .. tostring(v.BaseGameType) .. "'")
                continue
            end

            v.Base = base
        end
    end
end

function GM:CallGameTypeFunc(name, ...)
    local base = self:GetGameType()
    while base ~= nil do
        if base[name] ~= nil and isfunction(base[name]) then return base[name](base, ...) end
        base = base.Base
    end
    return nil
end

function GM:GetGameTypeData(name)
    local base = self:GetGameType()
    while base ~= nil do
        if base[name] ~= nil and not isfunction(base[name]) then return base[name] end
        base = base.Base
    end
    return nil
end

function GM:SetGameType(gametype, isFallback)
    DbgPrint("SetGameType: " .. tostring(gametype))

    local currentMap = game.GetMap():lower()
    local idealGametype = GameTypes:GetByMap(currentMap)

    if gametype == nil or gametype == "" then
        if SERVER then
            ErrorNoHalt("Warning: 'lambda_gametype' is empty, using 'auto'.\n")
        else
            print("Warning: 'lambda_gametype' is empty, using 'auto'.")
        end
        gametype = "auto"
    end

    DbgPrint("Current Gametype: " .. gametype)
    DbgPrint("Ideal Gametype: " .. (idealGametype or "unknown"))

    if gametype == "auto" then
        DbgPrint("Game type is set to auto, trying to detect gametype by map.")
        if gametype ~= nil then
            DbgPrint("Detected game type '" .. gametype .. "' for map " .. currentMap)
        else
            DbgPrint("No game type registered that contains the map " .. currentMap)
        end
        gametype = idealGametype
    else
        if idealGametype ~= nil and idealGametype ~= gametype then
            local msg = ""
            msg = msg .. "Warning: Server ConVar 'lambda_gametype' is set to '" .. gametype .. "', but the map is associated with '" .. idealGametype .. "'.\n"
            msg = msg .. " - Set 'lambda_gametype' to '" .. idealGametype .. "' or 'auto' to use the correct gametype.\n"
            if SERVER then
                ErrorNoHalt(msg)
            else
                print(msg)
            end
        end
    end

    local gametypeData = GameTypes:Get(gametype)
    if gametypeData == nil then
        print("Unable to find gametype: " .. (gametype or "unknown"))
        if isFallback ~= true then
            DbgPrint("Fallback: hl2")
            return self:SetGameType("hl2", true)
        end
    end

    self.GameType = gametypeData
    self:InitializeMapList()
    if gametypeData.LoadCurrentMapScript ~= nil then gametypeData:LoadCurrentMapScript() end
    if CLIENT then self:LoadLocalisation() end
    self:ResetMapScript()
end

function GM:ReloadGameType()
    if self.GameType ~= nil then
        self:InitializeMapList()
        self:ResetMapScript()
    end
end

function GM:ResetMapScript()
    local gametype = self.GameType
    if gametype.LoadCurrentMapScript ~= nil then gametype:LoadCurrentMapScript() end
    self.MapScript = gametype.MapScript or table.Copy(DEFAULT_MAPSCRIPT)
end

function GM:GetGameType()
    return self.GameType
end

function GM:GetMapScript()
    return self.MapScript or table.Copy(DEFAULT_MAPSCRIPT)
end