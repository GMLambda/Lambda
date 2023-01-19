AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons = {},
    Ammo = {},
    Armor = 30,
    HEV = false,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
}

MAPSCRIPT.EntityFilterByName =
{
    ["lab_entry_script_trigger"] = true,
}

MAPSCRIPT.ImportantPlayerNPCNames =
{
    ["lamarr_jumper"] = true,   -- In any case this should restart.
}

function MAPSCRIPT:PostInit()

    if SERVER then

        self.DefaultLoadout.HEV = false

        ents.WaitForEntityByName("player_in_teleport", function(ent)
            ent:SetKeyValue("teamwait", "1")
            ent.OnTrigger = function(e)
                ents.WaitForEntityByName("kleiner_teleport_lift_1", function(ent)
                    local cpLift = GAMEMODE:CreateCheckpoint(Vector(-7185.238770, -1185.304810, 6.031250), Angle(0, -90, 0))
                    cpLift:SetParent(ent)
                    GAMEMODE:SetPlayerCheckpoint(cpLift)
                end)
            end
        end)

        ents.WaitForEntityByName("start_first_teleport_01", function(ent)
            ent:SetKeyValue("teamwait", "1")
        end)

        ents.WaitForEntityByName("kleiner_console_lift_1", function(ent)
            ent:SetKeyValue("spawnflags", "256")
            --ent:SetKeyValue("dmg", "0") -- Don`t hurt the player
        end)

        -- Enable HEV as soon someone gets it.
        GAMEMODE:WaitForInput("suiton", "Enable", function(ent)
            local loadout = GAMEMODE:GetMapScript().DefaultLoadout
            loadout.HEV = true
        end)

        local allowPlayerClip = false
        GAMEMODE:WaitForInput("brush_soda_clip_player_2", "Enable", function(ent)
            if allowPlayerClip == false then
                return true -- Suppress
            end
        end)

        -- Close the door once everyone is inside.
        -- -6754.733398 -1360.082764 0.031250
        local doorTrigger = ents.Create("trigger_once")
        doorTrigger:SetKeyValue("TeamWait", "1")
        doorTrigger:SetupTrigger(
            Vector(-6754.733398, -1360.082764, 0.031250),
            Angle(0, 0, 0),
            Vector(-350, -300, 0),
            Vector(400, 200, 180)
        )
        doorTrigger:SetName("door_trigger")
        doorTrigger.OnTrigger = function()
            allowPlayerClip = true
            TriggerOutputs({
                {"brush_soda_clip_player", "Enable", 0.0, ""},
                {"BarneyEnter_song", "PlaySound", 0.0, ""},
                {"speaker_alyxsoda_nags", "Kill", 0.0, ""},
                {"lab01_lcs", "Start", 0.1, ""},
                {"kleiner_prepose_idle_1", "BeginSequence", 0.3, ""},
            })
        end

        -- -6569.488281 -1150.120850 0.031250
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-6569.488281, -1150.120850, 0.031250), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-6482.711914, -1095.658813, 0.031250),
            Angle(0, 0, 0),
            Vector(-50, -50, 0),
            Vector(50, 50, 180)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        ents.WaitForEntityByName("gman_fixtie_1", function(ent)
            ent:SetKeyValue("m_iszPlay", "citizen4_valve")
        end)

        -- Create a trigger that requires all players to have the suit
        local suitTrigger = ents.Create("trigger_once")
        suitTrigger:SetName("lambda_suit_trigger")
        suitTrigger:SetKeyValue("StartDisabled", "1")
        suitTrigger:SetupTrigger(
            Vector(-6716.156250, -1396.862793, 0), 
            Angle(0,0,0),
            Vector(-350, -300, 0),
            Vector(350, 310, 250),
            true,
            SF_TRIGGER_ONLY_PLAYER_WITH_HEV
        )
        suitTrigger:SetKeyValue("teamwait", "1")
        suitTrigger:SetKeyValue("messagepos", "231 -221 154")
        suitTrigger:SetKeyValue("timeoutteleport", "0")
        suitTrigger:Fire("AddOutput", "OnTrigger suitnag_loopall01_lcs,Kill,,0,-1")
        suitTrigger:Fire("AddOutput", "OnTrigger hev_light_suit_1,TurnOff,,0,-1")
        suitTrigger:Fire("AddOutput", "OnTrigger get_suit_math_1,Add,1,0,-1")
        suitTrigger:Fire("AddOutput", "OnTrigger hevnag_speaker,Kill,,0,-1")
        suitTrigger:Fire("AddOutput", "OnTrigger phys_knocked_nag_rl,Kill,,0,-1")
        suitTrigger.OnWaitTimeout = function(s)
            for _,v in pairs(player.GetAll()) do
                v:EquipSuit()
            end
        end

        -- Make the song suit per client.
        ents.WaitForEntityByName("song_suit", function(ent)
            local song_suit = ents.Create("lambda_client_sound")
            song_suit:SetName("song_suit")
            song_suit:SetKeyValue("sound", "song_trainstation_05_suit")
            song_suit:Spawn()

            -- Remove old.
            ent:Remove()
        end)

        -- Remove the original suit and replace with custom
        local suits = ents.FindByClass("item_suit")
        local itemSuit = suits[1]
        if IsValid(itemSuit) then
            local newSuit = ents.Create("item_suit")
            newSuit:SetPos(itemSuit:GetPos())
            newSuit:SetAngles(itemSuit:GetAngles())
            newSuit:Spawn()
            newSuit:Fire("AddOutput", "OnPlayerTouch song_suit,PlaySound,,0,-1")
            newSuit:Fire("AddOutput", "OnPlayerTouch lambda_suit_trigger,Enable,,0,-1")
            newSuit:EnableRespawn(true)
            -- HACK: Calling Fire or SetKeyValue doesn't trigger hooks, we have to manually store them.
            newSuit.EntityOutputs = {
                ["OnPlayerTouch"] = {
                    "song_suit,PlaySound,,0,-1",
                    "lambda_suit_trigger,Enable,,0,-1",
                }
            }
            -- Remove old.
            itemSuit:Remove()
        end

        GAMEMODE:WaitForInput("lab_door", "Close", function()
            local cp = GAMEMODE:CreateCheckpoint(Vector(-7154, -1508.3, 1), Angle(0, 90, 0))
            GAMEMODE:SetPlayerCheckpoint(cp, nil)
        end)

        -- Outdoor
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-10368, -4714, 320), Angle(0, 180, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-10368, -4714, 320),
            Angle(0, 0, 0),
            Vector(-50, -50, 0),
            Vector(50, 50, 180)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end
        
        -- Reposition alyx intro position a bit
        ents.WaitForEntityByName("mark_alyx_intro", function(ent)
            ent:SetPos(Vector(-6491.843262, -876.207031, 64.031250))
        end)

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
