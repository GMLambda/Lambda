if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_shotgun",
        "weapon_smg1",
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_357",
    },
    Ammo = {
        ["XBowBolt"] = 5,
        ["AR2"] = 30,
        ["SMG1_Grenade"] = 3,
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["Buckshot"] = 6,
        ["357"] = 6,
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["magnusson_courtyard_exitdoor"] = {"Close"},
    ["magnusson_courtyard_exitdoor_brush"] = {"Enable"},
}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true,
    ["global_newgame_template_base_items"] = true,
    ["door_silo_lab_3_counter_playertrigger"] = true, -- Prevent closing the 2nd silo door
    ["magnusson_ragdoll_door_playerout_trigger"] = true, -- Prevent closing the door after they go out
}
MAPSCRIPT.GlobalStates = {}
MAPSCRIPT.Checkpoints = {}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- Close the first door after everyone is in
    -- Would leave it open but NPCs go in and out during scene
    ents.WaitForEntityByName("trigger_player_closedoor_1", function(ent)
        ent:SetKeyValue("teamwait", "1")
        ent:SetKeyValue("showwait", "0")
    end)

    -- Remove both triggers that close the first door
    for k, v in pairs(ents.FindByName("trigger_close_tvdoor_transition_1")) do
        v:Remove()
    end

    -- Close the first door after everyone is out
    local leaveTVroom = ents.Create("trigger_multiple")
    leaveTVroom:SetupTrigger(Vector(432, -8611, -254), Angle(0, 0, 0), Vector(-224, -269, -62), Vector(224, 269, 62))
    leaveTVroom:Fire("AddOutput", "OnEndTouchAll door_silo_lab_1,Close,,0.0,-1")

end

return MAPSCRIPT