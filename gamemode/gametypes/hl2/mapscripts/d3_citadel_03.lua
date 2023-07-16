if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_physcannon"},
    Ammo = {},
    Armor = 60,
    HEV = true
}

MAPSCRIPT.InputFilters = {}
MAPSCRIPT.EntityFilterByClass = {}

MAPSCRIPT.EntityFilterByName = {
    ["global_newgame_template_base_items"] = true,
    ["global_newgame_template_local_items"] = true,
    ["global_newgame_template_ammo"] = true
}

function MAPSCRIPT:PostInit()
    if SERVER then
        -- FIX: Running towards the players before they get to do anything
        for k, v in pairs(ents.FindByName("citadel_npc_sold_starthall1_*")) do
            if v:IsNPC() then
                v:SetKeyValue("sleepstate", "3")
            end
        end

        GAMEMODE:WaitForInput("logic_weapon_strip_strip", "Trigger", function(ent)
            timer.Simple(3.8, function()
                local ply = nil
                for _, v in ipairs(player.GetAll()) do
                    if v:Alive() then
                        if not IsValid(ply) and v:HasWeapon("weapon_physcannon") then
                            ply = v
                        else
                            v:StripWeapons()
                        end
                    end
                end

                -- Softlock? Too sad.
                if not IsValid(ply) then
                    local physcannon = ents.Create("weapon_physcannon")
                    physcannon:SetPos(Vector(7680, -995, 2125))
                    physcannon:Spawn()

                    util.RunNextFrame(function()
                        ents.WaitForEntityByName("logic_weapon_strip_physcannon_start", function(ent)
                            ent:Fire("Trigger")
                        end)
                    end)
                end
            end)
        end)

        -- 7724.114746 -1358.596924 2112.031250
        local weaponTrigger = ents.Create("trigger_multiple")
        weaponTrigger:SetupTrigger(Vector(7724.114746, -1358.596924, 2112.031250), Angle(0, 0, 0), Vector(-160, -260, 0), Vector(160, 260, 100), true, SF_TRIGGER_ALLOW_PHYSICS)

        weaponTrigger.OnTrigger = function(ent)
            local props = ent:GetTouchingObjects()
            local cannon = nil

            for _, v in pairs(props) do
                if v:GetClass() == "weapon_physcannon" then
                    if not IsValid(cannon) then
                        cannon = v
                    else
                        v:Remove()
                    end
                end
            end
        end

        GAMEMODE:WaitForInput("logic_weapon_strip_physcannon_start", "Trigger", function(ent)
            weaponTrigger:Remove()

            for k, v in pairs(ents.FindByClass("weapon_physcannon")) do
                v:Supercharge()
            end

            -- Reset sleep state
            for k, v in pairs(ents.FindByName("citadel_npc_sold_starthall1_*")) do
                if v:IsNPC() then
                    v:SetKeyValue("sleepstate", "0")
                end
            end
        end)

        GAMEMODE:WaitForInput("weapon_strip", "Disable", function(ent)
            -- I don't understand how this works in HL2, simply Disabling it wont call StopTouch and reset the value.
            for k, v in pairs(player.GetAll()) do
                v:SetSaveValue("m_bPreventWeaponPickup", false)
            end
        end)

        ents.WaitForEntityByName("citadel_movelinear_elevphysball1_1", function(ent)
            ent:SetKeyValue("blockdamage", "0")
        end)
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
end

function MAPSCRIPT:OnRegisterNPC(npc)
    -- Don't drop weapons, seems that NPCs in gmod don't have this flag set.
    util.RunNextFrame(function()
        if not IsValid(npc) then return end
        npc:AddSpawnFlags(8192 + 131072 + 262144)
    end)

    DbgPrint("Registered NPC: " .. tostring(npc))
end

return MAPSCRIPT
