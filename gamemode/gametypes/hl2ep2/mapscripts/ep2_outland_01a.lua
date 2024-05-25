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
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
}

function MAPSCRIPT:PostInit()
    -- Apply enough force to do more than one player.
    ents.WaitForEntityByName("platform_2_thruster_1", function(ent)
        ent:SetKeyValue("force", "1000")
    end)

    -- This is one ugly hack, we want to keep the velocity of the platform in check due to the force applied.
    -- Without enough force it won't budge and with too much force it sends players flying.
    ents.WaitForEntityByName("platform_2", function(ent)
        hook.Add("Think", "PlatformVelocityControl", function()
            if not IsValid(ent) then
                return
            end
            local physObj = ent:GetPhysicsObject()
            if not IsValid(physObj) then
                return
            end
            local vel = physObj:GetVelocity()
            local len = vel:LengthSqr()
            local maxSpeed = 150
            local maxLen = maxSpeed * maxSpeed
            if len > maxLen then
                physObj:SetVelocity(vel:GetNormalized() * maxSpeed)
            end
        end)
    end)
end

return MAPSCRIPT