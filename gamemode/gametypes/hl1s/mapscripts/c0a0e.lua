if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {},
    Ammo = {},
    Armor = 0,
    HEV = false
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {} --["env_global"] = true,

MAPSCRIPT.EntityFilterByName = {
    ["changetoc1a0mm"] = true
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()
    if SERVER then
        -- Block.
        local blockade = ents.Create("func_brush")
        blockade:SetPos(Vector(-2120, -594.165466, -200))
        blockade:SetModel("*15")
        blockade:SetKeyValue("spawnflags", "2")
        blockade:SetKeyValue("Solidity", "0")
        blockade:SetKeyValue("solidbsp", "0")
        blockade:SetKeyValue("StartDisabled", "1")
        blockade:Spawn()
        blockade:SetName("lambda_pclip1")
        local doorTrigger = ents.Create("trigger_once")
        doorTrigger:Fire("AddOutput", "OnTrigger lambda_pclip1,Enable,,0,-1")
        doorTrigger:Fire("AddOutput", "OnTrigger doors,Toggle,,0,-1")
        doorTrigger:SetKeyValue("teamwait", "1")
        doorTrigger:SetupTrigger(Vector(-2405.352295, -588.131409, -252.968750), Angle(0, 0, 0), Vector(-180, -80, 0), Vector(200, 80, 120))
        -- Lazy valve, make sure he exists.
        local barney = ents.FindFirstByName("barney1")

        if not IsValid(barney) then
            barney = ents.Create("monster_barney")
            barney:SetName("barney1")
            barney:SetPos(Vector(-2008.000000, -472.000000, -252.968750))
            barney:SetAngles(Angle(0, 320, 0))
            barney:SetModel("models/hl1bar.mdl")
            barney:Spawn()
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT