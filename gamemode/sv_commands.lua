GM.Commands = {}

local DbgPrint = GetLogging("Commands")
local restrictedStr = "Unauthorized access for command: "

-- Check for user rights if ran by player or it is ran by console
local function isAuthority(ply)

    if IsValid(ply) and ply:IsAdmin() or not IsValid(ply) then return true end 
    return false 

end

-- RegisterCommand("command", fn, helptext, flags, restricted)
function GM:RegisterCommand(name, fn, helptext, flags, restricted)

    local cmdData = {}
    local prefix = "lambda_"

    cmdData.name = name
    cmdData.fullname = prefix .. name
    cmdData.helptext = helptext
    cmdData.flags = flags
    cmdData.restricted = restricted 

    if restricted == true then
        local _fn = fn
        fn = function(ply, cmd, args) 
            if isAuthority(ply) then 
                _fn(ply, cmd, args) 
            else 
                ply:ChatPrint(restrictedStr .. name, 10, ply)
                DbgPrint(restrictedStr, name) 
            end 
        end
    end

    cmdData.fn = fn

    concommand.Add(prefix .. name, fn, nil, nil, flags)
    DbgPrint("Registering command:", prefix .. name, fn, flags, restricted)

    self.Commands[name] = cmdData

end

function GM:GetRegisteredCommand(name)
    return self.Commands[name]
end


-- Game/Map Commands (Restricted)
GM:RegisterCommand("notarget",
    function(ply, cmd, args) 
        local flags = ply:GetFlags()
            if bit.band(flags, FL_NOTARGET) ~= 0 then
                DbgPrint("Player: " .. tostring(ply) .. " target")
                ply:SetNoTarget(false)
            else
                DbgPrint("Player: " .. tostring(ply) .. " notarget")
                ply:SetNoTarget(true)
            end 
    end,
    "Enable notarget",
    bit.bor(FCVAR_CHEAT, FCVAR_CLIENTCMD_CAN_EXECUTE),
    true)

GM:RegisterCommand("reset",
    function() GAMEMODE:CleanUpMap() end,
    "Restart current level",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    true)

GM:RegisterCommand("reload",
    function() game.ConsoleCommand("changelevel " .. game.GetMap()  .. "\n") end,
    "Re-load current level",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    true)

GM:RegisterCommand("nextmap",
    function() game.ConsoleCommand("changelevel " .. GAMEMODE:GetNextMap() .. "\n") end,
    "Change map to the next one",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    true)

GM:RegisterCommand("prevmap",
    function() game.ConsoleCommand("changelevel " .. GAMEMODE:GetPreviousMap() .. "\n") end,
    "Change map to the previous one",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    true)


-- Voting commands
GM:RegisterCommand("voteskip",
    function(ply) GAMEMODE:StartSkipMapVote(ply) end,
    "Start a skip map vote",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    false)

GM:RegisterCommand("voterestart",
    function(ply) GAMEMODE:StartRestartMapVote(ply) end,
    "Start a restart map vote",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    false)

GM:RegisterCommand("votemap",
    function(ply,cmd, args) GAMEMODE:StartMapVote(ply, args[1]) end,
    "Start a map vote",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    false)

GM:RegisterCommand("votekick",
    function(ply,cmd, args) GAMEMODE:StartKickVote(ply, args[1]) end,
    "Start a kick vote",
    bit.bor(FCVAR_CLIENTCMD_CAN_EXECUTE,  FCVAR_SERVER_CAN_EXECUTE),
    false)