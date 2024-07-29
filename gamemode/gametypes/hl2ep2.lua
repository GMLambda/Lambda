if SERVER then
    AddCSLuaFile()
end

local GAMETYPE = {}
GAMETYPE.Name = "Half-Life 2: Episode 2"
GAMETYPE.InternalName = "ep2"
GAMETYPE.BaseGameType = "hl2"
GAMETYPE.MapScript = {}
GAMETYPE.MapList = {
    "ep2_outland_01",
    "ep2_outland_01a",
    "ep2_outland_02",
    "ep2_outland_03",
    "ep2_outland_04",
    "ep2_outland_02",
    "ep2_outland_05",
    "ep2_outland_06",
    "ep2_outland_06a",
    "ep2_outland_07",
    "ep2_outland_08",
    "ep2_outland_09",
    "ep2_outland_10",
    "ep2_outland_10a",
    "ep2_outland_11",
    "ep2_outland_11a",
    "ep2_outland_11b",
    "ep2_outland_12",
    "ep2_outland_12a",
}

GAMETYPE.CampaignNames = {
    ["To the White Forest"] = {
        s = 1,
        e = 2
    },
    ["This Vortal Coil"] = {
        s = 3,
        e = 5
    },
    ["Freeman Pontifex"] = {
        s = 6,
        e = 7
    },
    ["Riding Shotgun"] = {
        s = 8,
        e = 10
    },
    ["Under the Radar"] = {
        s = 11,
        e = 13
    },
    ["Our Mutual Fiend"] = {
        s = 14,
        e = 17
    },
    ["T-Minus One"] = {
        s = 18,
        e = 18
    }
}
GAMETYPE.Localisation = include("hl2ep2/cl_localisation.lua")
GAMETYPE.ModelRemapping = {
    ["models/advisor.mdl"] = "models/advisor_ep2.mdl"
}

function GAMETYPE:InitSettings()
    self.Base:InitSettings()
end

function GAMETYPE:LoadCurrentMapScript()
    self.Base.LoadMapScript(self, "lambda/gamemode/gametypes/hl2ep2", game.GetMap():lower())
end

function GAMETYPE:GetPlayerLoadout()
    return self.MapScript.DefaultLoadout
end

hook.Add("LambdaLoadGameTypes", "HL2EP2GameType", function(gametypes)
    gametypes:Add("hl2ep2", GAMETYPE)
end)

if CLIENT then
    surface.CreateFont("ClientTitleFont", {
        font = "HL2EP2",
        size = util.ScreenScaleH(34),
        weight = 0,
        antialias = true,
        additive = true,
        custom = true
    })
end