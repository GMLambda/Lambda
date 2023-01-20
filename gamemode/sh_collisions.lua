if SERVER then
    AddCSLuaFile()
end

function GM:ShouldCollide(ent1, ent2)
    if (ent1:IsNPC() and ent2:GetClass() == "trigger_changelevel") or (ent2:IsNPC() and ent1:GetClass() == "trigger_changelevel") then return false end

    -- Nothing collides with blocked triggers except players.
    if ent1.IsLambdaTrigger ~= nil and ent1:IsLambdaTrigger() == true then
        if ent2:IsPlayer() == true or ent2:IsVehicle() == true then return ent1:IsBlocked() end

        return false
    elseif ent2.IsLambdaTrigger ~= nil and ent2:IsLambdaTrigger() == true then
        if ent1:IsPlayer() == true or ent1:IsVehicle() == true then return ent2:IsBlocked() end

        return false
    end

    return true
end