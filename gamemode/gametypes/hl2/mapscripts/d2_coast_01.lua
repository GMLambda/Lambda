if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_shotgun", "weapon_ar2"},
    --"weapon_frag",
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        --["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["push_car_superjump_01"] = {"Disable"}
}

MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["logic_jeepflipped"] = true -- Annoying
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    if SERVER then
        ents.WaitForEntityByName("push_car_superjump_01", function(ent)
            ent:Fire("Enable")
            ent:SetName("Lambda_" .. ent:GetName()) -- Prevent anyone disabling it.
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT