if SERVER then
    AddCSLuaFile()
end

function string.iequals(a, b)
    if string.len(a) ~= string.len(b) then
        return false
    end
    return string.lower(a) == string.lower(b)
end
