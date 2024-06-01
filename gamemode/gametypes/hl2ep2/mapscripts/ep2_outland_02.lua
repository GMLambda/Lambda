if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_physcannon"},
    Ammo = {},
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["spawnitems_template"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(-3189, -9255, -875),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(-2031, -8637, -715),
            Mins = Vector(-150, -150, 0),
            Maxs = Vector(150, 150, 76)
        }
    },
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- The default spawn gets players stuck.
    for _, v in pairs(ents.FindByClass("info_player_start")) do
        if v:HasSpawnFlags(1) then -- Master
            v:SetPos(Vector(-2293.175537, -8260.166016, -497.381989))
            print("Yep")
        end
    end
end

return MAPSCRIPT