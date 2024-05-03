include("lang/english.lua")
local DbgPrint = GetLogging("Language")

local ext = ".lua"
local filepath = "lambda/gamemode/lang/"

local current_lang = lambda_language:GetString()
include("lang/" .. current_lang .. ext)

-- Find all available languages
GM.Languages = {}
for k, v in pairs(file.Find(filepath .. "*", "LUA")) do
    v = string.StripExtension(v)
    DbgPrint("Found language: " .. v)
    GM.Languages[v] = true
end

function GM:ChangeLanguage(new)
    if file.Exists(filepath .. new .. ext, "LUA") then
        DbgPrint("Including new language: " .. new)
        include(filepath .. new .. ext)
    end
end

cvars.AddChangeCallback("lambda_language", function(cvar, old, new)
    if GAMEMODE.Languages[new] then
        DbgPrint("Language found")
        GAMEMODE:ChangeLanguage(new)
    else
        DbgPrint("Language not found!!! Reverting convar!")
        lambda_language:SetString(old)
    end
end)