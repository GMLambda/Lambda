if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357"},
    Ammo = {
        ["Pistol"] = 18,
        ["SMG1"] = 45,
        ["357"] = 6
    },
    Armor = 0,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_spawner_suit"] = true,
    ["global_newgame_spawner_crowbar"] = true,
    ["global_newgame_spawner_pistol"] = true,
    ["global_newgame_spawner_smg"] = true,
    ["global_newgame_spawner_357"] = true,
}

MAPSCRIPT.Checkpoints = {
    { -- At the lift
        Pos = Vector(4246, 9650, -119),
        Ang = Angle(0, -90, 0),
        Vehicle = {
            Pos = Vector(4270.903320, 9841.201172, -124.578499),
            Ang = Angle(0, -90, 0)
        },
        Trigger = {
            Pos = Vector(5046.067871, 9267.515625, -127.968750),
            Mins = Vector(-1500, -1000, -300),
            Maxs = Vector(100, 600, 180)
        }
    }
}

function MAPSCRIPT:PostInit()
    DbgPrint("MAPSCRIPT:PostInit")

    if SERVER then
        for k, v in pairs(ents.FindByClass("info_player_start")) do
            v:Remove()
        end

        local playerStart = ents.Create("info_player_start")
        playerStart:SetPos(Vector(11876.291016, -12289.263672, -526.052246))
        playerStart:SetAngles(Angle(0, 100, 0))
        playerStart:Spawn()
        playerStart.MasterSpawn = true
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT