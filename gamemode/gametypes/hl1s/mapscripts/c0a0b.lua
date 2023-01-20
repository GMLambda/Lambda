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
MAPSCRIPT.EntityFilterByName = {} --["spawnitems_template"] = true,

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName("goingdown", function(ent)
            ent:Spawn()
        end)

        GAMEMODE:WaitForInput("upper1", "InPass", function(ent)
            local goingdown = ents.FindFirstByName("goingdown")
            local train = ents.FindFirstByName("train")

            util.RunDelayed(function()
                if not IsValid(goingdown) or not IsValid(train) then return end
                goingdown:Input("Trigger", train, train)
                print("Forcing down", train)
            end, CurTime() + 2)
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    -- Failsafe: Make sure players are in the train
    ents.WaitForEntityByName("train", function(ent)
        local pos = ent:LocalToWorld(Vector(50, 40, 8))
        local ang = ent:LocalToWorldAngles(Angle(0, 0, 0))
        ply:TeleportPlayer(pos, ang)
    end)
end

return MAPSCRIPT