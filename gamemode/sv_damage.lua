DEFINE_BASECLASS("gamemode_base")
local DbgPrint = GetLogging("Damage")
local IsValid = IsValid

local DMG_TYPES = {
    [DMG_GENERIC] = "Generic",
    [DMG_CRUSH] = "Crush",
    [DMG_BULLET] = "Bullet",
    [DMG_SLASH] = "Slash",
    [DMG_BURN] = "Burn",
    [DMG_VEHICLE] = "Vehicle",
    [DMG_FALL] = "Fall",
    [DMG_BLAST] = "Blast",
    [DMG_CLUB] = "Club",
    [DMG_SHOCK] = "Shock",
    [DMG_SONIC] = "Sonic",
    [DMG_ENERGYBEAM] = "Energybeam",
    [DMG_PREVENT_PHYSICS_FORCE] = "PhysForce",
    [DMG_NEVERGIB] = "NeverGib",
    [DMG_ALWAYSGIB] = "AlwaysGib",
    [DMG_DROWN] = "Drown",
    [DMG_PARALYZE] = "Paralyze",
    [DMG_NERVEGAS] = "NerveGas",
    [DMG_POISON] = "Poison",
    [DMG_RADIATION] = "Radiation",
    [DMG_DROWNRECOVER] = "DrownRecover",
    [DMG_ACID] = "Acid",
    [DMG_SLOWBURN] = "SlowBurn",
    [DMG_REMOVENORAGDOLL] = "RemoveNoRagdoll",
    [DMG_PHYSGUN] = "Physgun",
    [DMG_PLASMA] = "Plasma",
    [DMG_AIRBOAT] = "Airboat",
    [DMG_DISSOLVE] = "Dissolve",
    [DMG_BLAST_SURFACE] = "BlastSurface",
    [DMG_DIRECT] = "Direct",
    [DMG_BUCKSHOT] = "Buckshot",
    [DMG_SNIPER] = "Sniper",
    [DMG_MISSILEDEFENSE] = "MissileDefense"
}

local function GetDamageTypeText(dmginfo)
    local text = ""

    local append = function(t)
        if text ~= "" then
            text = text .. ", " .. t
        else
            text = t
        end
    end

    for k, v in pairs(DMG_TYPES) do
        if dmginfo:IsDamageType(k) == true then
            append(v)
        end
    end

    return text .. " : " .. dmginfo:GetDamageType()
end

function GM:EntityTakeDamage(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    local dmgText = GetDamageTypeText(dmginfo)
    local attackerIsPlayer = false

    if (IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer()) then
        attackerIsPlayer = true
    end

    DbgPrint("EntityTakeDamage -> Target: " .. tostring(target) .. ", Attacker: " .. tostring(attacker) .. ", Inflictor: " .. tostring(inflictor) .. ", Type: " .. dmgText)
    local dmgType = dmginfo:GetDamageType()
    target:SetLastDamageType(dmgType)
    target.IsPhysgunDamage = dmginfo:IsDamageType(DMG_PHYSGUN)
    DbgPrint(target, "PhysgunDamage: " .. tostring(target.IsPhysgunDamage))

    if target:IsNPC() then
        if dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH) then
            -- BUG: https://github.com/Facepunch/garrysmod-issues/issues/3704
            -- Only trace attacks will call scale.
            self:ScaleNPCDamage(target, HITGROUP_GENERIC, dmginfo)
        end

        if attackerIsPlayer == true and self:IsNPCMissionCritical(target) and self:GetSetting("allow_npcdmg") == false then
            DbgPrint("Filtering damage on restricted NPC")
            dmginfo:SetDamage(0)

            return true
        end
    elseif target:IsPlayer() then
        if target:IsPositionLocked() or target:IsInactive() == true then return true end

        if target ~= attacker and target ~= inflictor then
            if self:CallGameTypeFunc("PlayerShouldTakeDamage", target, attacker, inflictor) == false then return true end
        end

        if dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH) then
            -- BUG: https://github.com/Facepunch/garrysmod-issues/issues/3704
            -- Only trace attacks will call scale.
            self:ScalePlayerDamage(target, HITGROUP_GENERIC, dmginfo)
        end

        local dmg = dmginfo:GetDamage()

        if dmg > 0 then
            local hitGroup = HITGROUP_GENERIC

            if dmginfo:IsDamageType(DMG_FALL) and dmg > 40 and math.random(1, 2) == 1 then
                hitGroup = HITGROUP_LEFTLEG
            end

            self:EmitPlayerHurt(dmg, target, hitGroup)
        end

        if target:InVehicle() then
            dmginfo:ScaleDamage(0.6)
        end

        -- NOTE: Blocking too early would not register any damage.
        if self:GetSetting("player_god") == true then return true end
    elseif target:IsWeapon() == true or target:IsItem() == true then
        if self:GetSetting("prevent_item_move") == true then
            if (IsValid(attacker) and attacker:IsPlayer()) or (IsValid(inflictor) and inflictor:IsPlayer()) then
                dmginfo:SetDamageForce(Vector(0, 0, 0))
            end
        end
    else
        -- For any other entity, this is called in ScalePlayerDamage and ScaleNPCDamage otherwise.
        self:ApplyCorrectedDamage(dmginfo)
    end

    if target.FilterDamage == true then
        DbgPrint("Filtering Damage!")
        dmginfo:ScaleDamage(0)

        return true
    end
end