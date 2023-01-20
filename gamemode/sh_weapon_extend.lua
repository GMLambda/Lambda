if SERVER then
    AddCSLuaFile()
end

local WEAPON_META = FindMetaTable("Weapon")

-- Stub function
function WEAPON_META:CanHolster()
    return true
end