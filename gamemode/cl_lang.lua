local DbgPrint = GetLogging("Language")

local SUPPORTED_LANGUAGES = {
    ["en"] = "english",
}

local function GetCurrentLanguage()
    local gmod_language = GetConVar("gmod_language")
    local lang = gmod_language:GetString()
    local realLang = SUPPORTED_LANGUAGES[lang]
    if realLang == nil then
        DbgPrint("Language '" .. lang .. "' is not supported, falling back to 'en'")
        realLang = "english"
    end
    return realLang
end

function GM:LoadLocalisation()
    local langName = GetCurrentLanguage()
    local gameType = self:GetGameType()
    if gameType == nil then return end
    while gameType ~= nil do
        local langData = gameType.Localisation
        if langData ~= nil then
            local langEntries = langData[langName]
            if langEntries ~= nil then
                for k, v in pairs(langEntries) do
                    DbgPrint("Adding localisation: " .. k .. " = " .. v)
                    language.Add(k, v)
                end
            end
        end
        gameType = gameType.Base
    end
end

cvars.AddChangeCallback("gmod_language", function(cvar, old, new)
    GAMEMODE:LoadLocalisation()
end)