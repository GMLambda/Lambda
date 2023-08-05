if SERVER then
    AddCSLuaFile()
end

local GAMETYPE = {}
GAMETYPE.Name = "Half-Life 2: Episode 1"
GAMETYPE.BaseGameType = "hl2"
GAMETYPE.MapScript = {}
GAMETYPE.MapList = {"ep1_citadel_00", "ep1_citadel_01", "ep1_citadel_02", "ep1_citadel_02b", "ep1_citadel_03", "ep1_citadel_04", "ep1_c17_00", "ep1_c17_00a", "ep1_c17_01", "ep1_c17_02", "ep1_c17_02b", "ep1_c17_02a", "ep1_c17_05", "ep1_c17_06"}

GAMETYPE.CampaignNames = {
    ["UNDUE ALARM"] = {
        s = 1,
        e = 4
    },
    ["DIRECT INTERVENTION"] = {
        s = 5,
        e = 6
    },
    ["LOWLIFE"] = {
        s = 7,
        e = 8
    },
    ["URBAN FLIGHT"] = {
        s = 9,
        e = 13
    },
    ["EXIT 17"] = {
        s = 14,
        e = 15
    }
}

function GAMETYPE:InitSettings()
    self.Base:InitSettings()
end

function GAMETYPE:LoadCurrentMapScript()
    self.Base.LoadMapScript(self, "lambda/gamemode/gametypes/hl2ep1", game.GetMap():lower())
end

function GAMETYPE:GetPlayerLoadout()
    return self.MapScript.DefaultLoadout
end

hook.Add("LambdaLoadGameTypes", "HL2EP1GameType", function(gametypes)
    gametypes:Add("hl2ep1", GAMETYPE)
end)
