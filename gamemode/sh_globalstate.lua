if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("GlobalStates")

if SERVER then
    -- Predefined list to capture the state on map start in order to properly reset on new rounds.
    local GLOBAL_STATES = {"gordon_precriminal", "antlion_allied", "suit_no_sprint", "super_phys_gun", "friendly_encounter", "gordon_invulnerable", "no_seagulls_on_jeep", "ep2_alyx_injured", "ep_alyx_darknessmode", "hunters_to_run_over"}
    -- GLOBAL_OFF = 0
    -- GLOBAL_ON = 1
    -- GLOBAL_DEAD = 2
    GM.GlobalStatesSnapshot = {}

    function GM:InitializeGlobalStates()
        DbgPrint("GM:InitializeGlobalStates")
        local data = {}

        for _, v in pairs(GLOBAL_STATES) do
            local state = game.GetGlobalState(v)
            data[v] = state
        end

        self.GlobalStatesSnapshot = data
        --PrintTable(data)
    end

    function GM:ResetGlobalStates(data)
        DbgPrint("GM:ResetGlobalStates")

        for k, v in pairs(self.GlobalStatesSnapshot or {}) do
            if v == GLOBAL_DEAD then continue end -- Don't set dead ones, no need.
            game.SetGlobalState(k, v)
        end
    end
end