if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("LambdaPlayerSettings")
    util.AddNetworkString("LambdaPlayerSettingsChanged")
end

local DbgPrint = GetLogging("Player")
local DbgPrintDmg = GetLogging("Damage")

DEFINE_BASECLASS( "gamemode_base" )

local SUIT_DEVICE_BREATHER = 1
local SUIT_DEVICE_SPRINT = 2
local SUIT_DEVICE_FLASHLIGHT = 3
local sv_infinite_aux_power = GetConVar("sv_infinite_aux_power")

if SERVER then

    function GM:IsPlayerEnemy(ply1, ply2)

        local isEnemy = self:CallGameTypeFunc("IsPlayerEnemy", ply1, ply2)
        return isEnemy

    end

    function GM:ShowHelp(ply)

        local posLocked = ply:IsPositionLocked()
        if posLocked == false then
            self:TogglePlayerSettings(ply, true)
        end

    end

    function GM:TogglePlayerSettings(ply, state)

        if state == true then
            DbgPrint(ply, "Changing to settings")
            ply:LockPosition(true, VIEWLOCK_SETTINGS_ON)
            net.Start("LambdaPlayerSettings")
            net.WriteBool(true)
            net.Send(ply)
        else
            DbgPrint(ply, "Leaveing settings")
            ply:LockPosition(true, VIEWLOCK_SETTINGS_RELEASE)
            net.Start("LambdaPlayerSettings")
            net.WriteBool(false)
            net.Send(ply)
        end

    end

    net.Receive("LambdaPlayerSettings", function(len, ply)
        local state = net.ReadBool()
        if state == true then
            return
        end
        -- Who cares about state, only sent when closed.
        GAMEMODE:TogglePlayerSettings(ply, false)
    end)

    net.Receive("LambdaPlayerSettingsChanged", function(len, ply)

        GAMEMODE:PlayerSetColors(ply)
        GAMEMODE:PlayerSetModel(ply)

    end)

    function GM:CanPlayerSuicide(ply)

        if ply:Alive() == false then
            return false
        end

        if ply:IsPositionLocked() then
            return false
        end

        return true

    end

    function GM:PlayerDisconnected(ply)

        if ply.LambdaPlayerData then
            --PLAYER_ROLES_TAKEN[ply.LambdaPlayerData.Id] = nil
        else
            DbgPrint("Disconnected without LambdaPlayerData assigned, bug?")
        end

        if IsValid(ply.TrackerEntity) then
            ply.TrackerEntity:Remove()
        end

        return BaseClass.PlayerDisconnected(self, ply)

    end

    function GM:SetupPlayerVisibility(ply, viewEnt)

    end

    function GM:PlayerInitialSpawn(ply)

        DbgPrint("GM:PlayerInitialSpawn")

        self:HandlePlayerConnect(ply:SteamID(), ply:Nick(), ply:EntIndex(), ply:IsBot(), ply:UserID())
        self:IncludePlayerInRound(ply)
        self:SendPlayerModelList(ply)

        local model = "models/player/riot.mdl"
        local name = "!player" -- Some stuff will fail if this is not set, not everything is ported.
        ply.LambdaLastModel = model

        local transitionData = self:GetPlayerTransitionData(ply)
        if transitionData ~= nil then
            ply:SetFrags(transitionData.Frags)
            ply:SetDeaths(transitionData.Deaths)
        end

        ply:SetName("!player") -- Some thing are triggered between PlayerInitialSpawn and PlayerSpawn
        if ply:IsBot() == false then
            ply:SetInactive(true)
        end

        self:AssignPlayerAuthToken(ply)

        BaseClass.PlayerInitialSpawn( self, ply )

    end

    function GM:PlayerSelectSpawn(ply)

        DbgPrint("PlayerSelectSpawn")

        local gameType = self:GetGameType()
        if gameType.UsingCheckpoints == true then
            -- Check if players reached a checkpoint.
            if self.CurrentCheckpoint ~= nil and IsValid(self.CurrentCheckpoint) then
                ply.SelectedSpawnpoint = self.CurrentCheckpoint
                return self.CurrentCheckpoint
            end
        end

        local spawnClass = self:GetGameTypeData("PlayerSpawnClass")
        DbgPrint("Spawn class: " .. spawnClass)

        local spawnpoints = ents.FindByClass(spawnClass)
        if #spawnpoints == 0 then
            -- Always use a fallback.
            spawnpoints = ents.FindByClass("info_player_start")
        end

        local spawnpoint = nil

        local possibleSpawns = {}
        for _,v in pairs(spawnpoints) do
            if self:CallGameTypeFunc("CanPlayerSpawn", ply, v) == true then
                table.insert(possibleSpawns, v)
            end
        end

        if spawnpoint == nil and #possibleSpawns > 0 then
            spawnpoint = self:CallGameTypeFunc("PlayerSelectSpawn", possibleSpawns)
        end

        DbgPrint("Select spawnpoint for player: " .. tostring(ply) .. ", spawn: " .. tostring(spawnpoint))

        ply.SelectedSpawnpoint = spawnpoint
        return spawnpoint

    end

    function GM:CanPlayerSpawn(ply)
        local gameType = self:GetGameType()
        if self.WaitingForRoundStart == true then
            return false
        end
        if gameType.UsingCheckpoints == true then
            -- Check if players reached a checkpoint.
            if self.CurrentCheckpoint ~= nil and IsValid(self.CurrentCheckpoint) then
                return true
            end
        end

        local spawnClass = self:GetGameTypeData("PlayerSpawnClass")
        local spawnpoints = ents.FindByClass(spawnClass)
        if #spawnpoints == 0 then
            -- Always use a fallback.
            spawnpoints = ents.FindByClass("info_player_start")
        end

        for _,v in pairs(spawnpoints) do

            -- If set by us then this is the absolute.
            if v.MasterSpawn == true then
                return true
            end

            -- If master flag is set it has priority.
            if v:HasSpawnFlags(1) then
                return true
            end

            if self:CallGameTypeFunc("CanPlayerSpawn", ply, v) == true then
                return true
            end

        end

        return false

    end

    local male_bbox = Vector(22.291288, 20.596443, 72.959808)
    local female_bbox = Vector(21.857199, 20.744711, 71.528900)

    -- Credits to CapsAdmin
    local function EstimateModelGender(ent)

        local mdl = ent:GetModel()
        if not mdl then
            return
        end

        local headcrabAttachment = ent:LookupAttachment("headcrab")
        if headcrabAttachment ~= 0 then
            return "zombie"
        end

        local ziplineAttachment = ent:LookupAttachment("zipline")
        if ziplineAttachment ~= 0 then
            return "combine"
        end

        local seq
        seq = ent:LookupSequence("d3_c17_07_Kidnap")
        if seq ~= nil and seq > 0 then
            return "combine"
        end

        seq = ent:LookupSequence("walk_all")
        if seq ~= nil and seq > 0 then
            local info = ent:GetSequenceInfo(seq)
            if info.bbmax == male_bbox then
                return "male"
            elseif info.bbmax == female_bbox then
                return "female"
            end
        end

        if
            mdl:lower():find("female") or
            ent:LookupBone("ValveBiped.Bip01_R_Pectoral") or
            ent:LookupBone("ValveBiped.Bip01_R_Latt") or
            ent:LookupBone("ValveBiped.Bip01_L_Pectoral") or
            ent:LookupBone("ValveBiped.Bip01_L_Latt")
        then
            return "female"
        end

        return "male"

    end

    function GM:PlayerSetModel(ply)

        DbgPrint("GM:PlayerSetModel")

        local playermdl = ply:GetInfo("lambda_playermdl")
        if playermdl == nil or playermdl == "" then
            playermdl = "male05"
        end

        local mdls = self:GetAvailablePlayerModels()
        local selection = mdls[playermdl]
        if selection == nil then
            print("Player " .. tostring(ply) .. " tried to select unknown model: " .. playermdl)
            selection = mdls["male05"]
        end

        local mdl = selection

        util.PrecacheModel(mdl)
        ply:SetModel(mdl)

        local gender = EstimateModelGender(ply)
        DbgPrint("New Gender: " .. gender)
        ply:SetGender(gender)

        if IsValid(ply.TrackerEntity) then
            ply.TrackerEntity:AttachToPlayer(ply)
        end

        ply:SetupHands()

    end

    function GM:PlayerSetColors(ply)

        --DbgPrint("PlayerSetColors: " .. tostring(ply))

        local plycolor = ply:GetInfo("lambda_player_color") or "0.3 1 1"
        local wepcolor = ply:GetInfo("lambda_weapon_color") or "0.3 1 1"

        ply:SetPlayerColor(util.StringToType(plycolor, "Vector"))
        ply:SetWeaponColor(util.StringToType(wepcolor, "Vector"))

    end

    function GM:PlayerLoadout(ply)

        DbgPrint("PlayerLoadout: " .. tostring(ply))

        local loadout = self:CallGameTypeFunc("GetPlayerLoadout") or {}
        local transitionData = ply.TransitionData
        if transitionData ~= nil and transitionData.Include == true then

            for _,v in pairs(ply.TransitionData.Weapons) do
                ply:Give(v.Class, true)

                ply:SetAmmo(v.Ammo1.Count, v.Ammo1.Id)
                ply:SetAmmo(v.Ammo2.Count, v.Ammo2.Id)

                local wep = ply:GetWeapon(v.Class)
                if IsValid(wep) then
                    wep:SetClip1(v.Clip1)
                    wep:SetClip2(v.Clip2)
                end

                if v.Active == true then
                    ply.ScheduledActiveWeapon = v.Class
                elseif v.Previous == true then
                    ply.ScheduledLastWeapon = v.Class
                end
            end

            ply:SetHealth(ply.TransitionData.Health)
            ply:SetArmor(ply.TransitionData.Armor)

            if ply.TransitionData.Suit then
                ply:EquipSuit()
            else
                ply:RemoveSuit()
            end

        else
            -- Armor
            ply:SetArmor(loadout.Armor or 0)

            -- HEV
            if loadout.HEV == true then
                DbgPrint("EquipSuit(" .. tostring(ply) .. ")")
                ply:EquipSuit()
            else
                DbgPrint("RemoveSuit(" .. tostring(ply) .. ")")
                ply:RemoveSuit()
            end

        end

        -- Give player the default weapons and ammo.
        local ammoTable = loadout.Ammo or {}

        for k,v in pairs(loadout.Weapons or {}) do
            if ply:HasWeapon(v) == true then
                continue
            end

            local weapon = ply:Give(v, true)

            local ammoType1 = weapon:GetPrimaryAmmoType()
            if ammoType1 ~= -1 then
                local ammoName = game.GetAmmoName(ammoType1)
                local ammoNum = ammoTable[ammoName]
                if ammoNum ~= nil then
                    ply:GiveAmmo(ammoNum, ammoName, true)
                end
            end

            local ammoType2 = weapon:GetSecondaryAmmoType()
            if ammoType2 ~= -1 then
                local ammoName = game.GetAmmoName(ammoType2)
                local ammoNum = ammoTable[ammoName]
                if ammoNum ~= nil then
                    ply:GiveAmmo(ammoNum, ammoName, true)
                end
            end

            -- We make sure the weapon is loaded.
            local ammo1 = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
            if ammo1 ~= -1 then
                local maxClip = weapon:GetMaxClip1()
                local newAmmo = maxClip
                if newAmmo > ammo1 then
                    newAmmo = ammo1
                end
                weapon:SetClip1(newAmmo)
                ply:SetAmmo(ammo1 - newAmmo, weapon:GetPrimaryAmmoType())
            end
        end

    end

    function GM:SelectBestWeapon(ply)

        -- Switch to a better weapon.
        local weps = ply:GetWeapons()
        local highestDmg = 0
        local bestWep = nil

        for k,v in pairs(weps) do

            local ammo = ply:GetAmmoCount(v:GetPrimaryAmmoType())
            if bestWep == nil then
                bestWep = v
            end

            if v:GetClass() == "weapon_physcannon" and v:IsMegaPhysCannon() then
                break
            end

            if ammo ~= 0 then
                local dmgCVar = self.PLAYER_WEAPON_DAMAGE[v:GetClass()]
                if dmgCVar ~= nil then
                    local dmg = dmgCVar:GetFloat()
                    if dmg > highestDmg then
                        bestWep = v
                        highestDmg = dmg
                    end
                end
            end
        end

        if bestWep ~= nil then
            DbgPrint(bestWep)
            ply:SelectWeapon(bestWep:GetClass())
        end

    end

    function GM:PlayerSpawn(ply)

        DbgPrint("GM:PlayerSpawn")

        if self.WaitingForRoundStart == true or self:IsRoundRestarting() == true then
            ply:KillSilent()
            return
        end

        ply:EndSpectator()
        ply.SpawnBlocked = false
        ply.LambdaSpawnTime = CurTime()
        ply.IsCurrentlySpawning = true
        ply.DeathAcknowledged = false

        self:PlayerSetModel(ply)
        self:InitializePlayerPickup(ply)
        self:InitializePlayerSpeech(ply)
        self:PlayerSetColors(ply)
        self:NotifyRoundStateChanged(ply, ROUND_INFO_NONE, {})

        -- Update vehicle checkpoints
        self:UpdateQueuedVehicleCheckpoints()

        -- Lets remove whatever the player left on vehicles behind before he got killed.
        self:RemovePlayerVehicles(ply)

        -- Should we really do this?
        ply.WeaponDuplication = {}
        ply:StripAmmo()
        ply:StripWeapons()
        ply:SetupHands()
        ply:SetTeam(LAMBDA_TEAM_ALIVE)
        ply:SetCustomCollisionCheck(true)
        ply:RemoveSuit()

        -- We call this first in order to call PlayerLoadout, once we enter a vehicle we can not
        -- get any weapons.
        BaseClass.PlayerSpawn(self, ply)

        DbgPrint("Base finished")

        if self.MapScript.PrePlayerSpawn ~= nil then
            self.MapScript:PrePlayerSpawn(ply)
        end

        ply:SetSuitPower(100)
        ply:SetSuitEnergy(100)
        ply:SetGeigerRange(1000)
        ply:SetStateSprinting(false)
        ply:SetSprinting(false)
        ply:SetDuckSpeed(0.4)
        ply:SetUnDuckSpeed(0.2)
        if ply:IsBot() == false then
            ply:SetInactive(true)
        end
        ply:DisablePlayerCollide(true)

        -- Bloody fucking hell.
        ply:SetSaveValue("m_bPreventWeaponPickup", false)

        ply:SetRunSpeed(lambda_sprintspeed:GetInt()) -- TODO: Put this in a convar.
        ply:SetWalkSpeed(lambda_normspeed:GetInt())

        if ply:IsBot() then
            local r = 0.3 + (math.sin(ply:EntIndex()) * 0.7)
            local g = 0.3 + (math.sin(ply:EntIndex() * 33) * 0.7)
            local b = 0.3 + (math.sin(ply:EntIndex() * 17) * 0.7)
            ply:SetWeaponColor(Vector(r, g, b))
        end

        local transitionData = ply.TransitionData
        local useSpawnpoint = true

        if transitionData ~= nil and transitionData.Include == true then

            DbgPrint("Player " .. tostring(ply) .. " has transition data.")

            -- We keep those.
            ply:SetFrags(transitionData.Frags)
            ply:SetDeaths(transitionData.Deaths)

            if transitionData.Vehicle ~= nil then

                local vehicle = self:FindEntityByTransitionReference(transitionData.Vehicle)
                if IsValid(vehicle) then
                    DbgPrint("Putting player " .. tostring(ply) .. " back in vehicle: " .. tostring(vehicle))

                    -- Sometimes does crazy things to the view angles, this only helps to a certain amount.
                    local eyeAng = vehicle:WorldToLocalAngles(transitionData.EyeAng)

                    -- NOTE: Workaround as they seem to not get any weapons if we enter the vehicle this frame.
                    -- FIXME: I noticed that delaying it until the next frame won't always work, we use a fixed delay now.
                    util.RunDelayed(function()
                        if IsValid(ply) and IsValid(vehicle) then
                            vehicle:SetVehicleEntryAnim(false)
                            vehicle.ResetVehicleEntryAnim = true
                            ply:EnterVehicle(vehicle)
                            ply:SetEyeAngles(eyeAng) -- We call it again because the vehicle sets it to how you entered.
                        end
                    end, CurTime() + 0.2)
                    useSpawnpoint = false
                else
                    DbgPrint("Unable to find player " .. tostring(ply) .. " vehicle: " .. tostring(transitionData.Vehicle))
                end

            elseif transitionData.Ground ~= nil then

                local groundEnt = self:FindEntityByTransitionReference(transitionData.Ground)
                if IsValid(groundEnt) then
                    local newPos = groundEnt:LocalToWorld(transitionData.GroundPos)
                    DbgPrint("Using func_tracktrain as spawn position reference.", newPos, groundEnt)
                    ply:TeleportPlayer(newPos, transitionData.Ang)
                    useSpawnpoint = false
                else
                    DbgPrint("Ground set but not found")
                end

            else

                DbgPrint("Player " .. tostring(ply) .. " uses normal position")
                ply:TeleportPlayer(transitionData.Pos, transitionData.Ang)
                ply:SetAngles(transitionData.Ang)
                ply:SetEyeAngles(transitionData.EyeAng)
                useSpawnpoint = false

            end

        end

        if useSpawnpoint == true and IsValid(ply.SelectedSpawnpoint) then
            ply:TeleportPlayer(ply.SelectedSpawnpoint:GetPos(), ply.SelectedSpawnpoint:GetAngles())
            ply.SelectedSpawnpoint = nil
        end

        DbgPrint("Selecting best weapon for " .. tostring(ply))
        if ply.ScheduledActiveWeapon ~= nil then
            ply:SelectWeapon(ply.ScheduledActiveWeapon)
            ply.ScheduledActiveWeapon = nil
        else
            self:SelectBestWeapon(ply)
        end

        if ply.ScheduledLastWeapon ~= nil then
            local wep = ply:GetWeapon(ply.ScheduledLastWeapon)
            if IsValid(wep) then
                ply:SetSaveValue("m_hLastWeapon", wep)
            end
        end

        util.RunNextFrame(function()
            if SERVER then
                self:CheckPlayerNotStuck(ply)
            end
            if self.MapScript.PostPlayerSpawn ~= nil then
                self.MapScript:PostPlayerSpawn(ply)
            end
        end)

        ply.TransitionData = nil -- Make sure we erase it because this only happens on a new round.

        -- Adjust difficulty, we want later some dynamic system that adjusts depending on the players.
        self:AdjustDifficulty()

        if not IsValid(ply.TrackerEntity) then
            ply.TrackerEntity = ents.Create("lambda_player_tracker")
            ply.TrackerEntity:AttachToPlayer(ply)
        end

        ply.IsCurrentlySpawning = false

    end

    function GM:CheckPlayerNotStuck(ply)

        -- Thats all there is to it, hopefully.
        if ply:InVehicle() then
            return
        end

        util.PlayerUnstuck(ply)

    end

    local AMMO_TO_ITEM =
    {
        ["RPG_Round"] = "item_rpg_round",
        ["Grenade"] = "weapon_frag",
    }

    function GM:DoPlayerDeath(ply, attacker, dmgInfo)

        DbgPrint("GM:DoPlayerDeath", ply)

        if ply.LastWeaponsDropped ~= nil then
            for _,v in pairs(ply.LastWeaponsDropped) do
                if IsValid(v) and not IsValid(v:GetOwner()) then
                    v:Remove()
                end
            end
        end

        local weps = {}
        for _,v in pairs(ply:GetWeapons()) do
            weps[v] = true
        end

        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) then
            weps[activeWep] = true
        end

        ply.LastWeaponsDropped = {}
        for v,_ in pairs(weps) do

            local ammoType1 = v:GetPrimaryAmmoType()
            local ammoType2 = v:GetSecondaryAmmoType()

            -- Only drop relevant stuff, except the crowbar.
            if ammoType1 == -1 and ammoType2 == -1 and v:GetClass() ~= "weapon_crowbar" then
                continue
            end

            local dropAmmo = false
            local ammo1 = -1
            local ammo2 = -1

            if v:Clip1() == -1 and v:Clip2() == -1 then
                ammo1 = ply:GetAmmoCount(ammoType1)
                if ammo1 > 0 then
                    dropAmmo = true
                end
                ammo2 = ply:GetAmmoCount(ammoType2)
                if ammo2 > 0 then
                    dropAmmo = true
                end
            end

            local drop
            if dropAmmo == true and ammo1 > 0 then
                local ammoDropType1 = game.GetAmmoName(ammoType1)
                local dropClass = AMMO_TO_ITEM[ammoDropType1]
                if dropClass ~= nil then
                    for i = 1, ammo1 do
                        drop = ents.Create(dropClass)
                        drop:SetPos(v:GetPos())
                        drop:Spawn()
                        drop.DroppedByPlayer = ply
                    end
                end
            else
                drop = ents.Create(v:GetClass())
                drop:SetClip1(v:Clip1())
                drop:SetClip2(v:Clip2())
                drop:SetPos(v:GetPos())
                drop:SetAngles(v:GetAngles())
                drop:Spawn()
                drop.DroppedByPlayer = ply
                drop.UniqueEntityId = v.UniqueEntityId

                if drop:GetClass() == "weapon_crowbar" then
                    -- Damage players if it gets thrown their way and they already have a crowbar
                    drop:SetSolidFlags(FSOLID_CUSTOMBOXTEST)
                    drop:SetCollisionGroup(COLLISION_GROUP_PLAYER)
                end

                table.insert(ply.LastWeaponsDropped, drop)
            end

            -- Remove the weapon the player holds.
            v:Remove()

        end

        local dmgForce = dmgInfo:GetDamageForce() * 0.03

        for _,v in ipairs(ply.LastWeaponsDropped) do
            local phys = v:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(dmgForce)
            end
        end

        local gender = ply:GetGender()
        local snd = table.Random(self.HurtSounds[gender][HITGROUP_GENERIC])

        ply:EmitSound(snd)
        ply:SetShouldServerRagdoll(false)

        local damgeDist = dmgInfo:GetDamagePosition():Distance(ply:GetPos())
        local enableGore = true

        -- We always create the ragdoll, client decides what to do with it.
        ply:CreateRagdoll()

        if enableGore == true and dmgInfo:IsDamageType(DMG_BLAST) and damgeDist < 150 then
            -- Exploded
            self:GibPlayer(ply, dmgForce, true)
        elseif enableGore == true and dmgInfo:IsDamageType(DMG_CRUSH) and IsValid(attacker) then
            -- Crushed
            local totalMass = 0
            for i = 0, attacker:GetPhysicsObjectCount() - 1 do
                local physObj = attacker:GetPhysicsObjectNum(i)
                if IsValid(physObj) then
                    totalMass = totalMass + physObj:GetMass()
                end
            end
            local forceLen = dmgForce:Length2D()
            if forceLen <= 0 then
                forceLen = 1
            end
            local forceWithMass = totalMass * forceLen
            if forceWithMass >= 150000 or totalMass >= 10000 then
                self:GibPlayer(ply, dmgForce, false)
            end
        end

        local inflictor = dmgInfo:GetInflictor()
        self:RegisterPlayerDeath(ply, attacker, inflictor, dmgInfo)

    end

    function GM:PlayerDeathSound()
        return true
    end

    function GM:PlayerDeath(ply, attacker, inflictor)

        DbgPrint("GM:PlayerDeath", ply)

        local effectdata = EffectData()
            effectdata:SetOrigin( ply:GetPos() )
            effectdata:SetNormal( Vector(0,0,1) )
            effectdata:SetRadius(50)
            effectdata:SetEntity(ply)
        util.Effect( "lambda_death", effectdata, true )

        self:CallGameTypeFunc("PlayerDeath", ply, attacker, inflictor)

    end

    function GM:RegisterPlayerDeath(ply, attacker, inflictor, dmgInfo)

        DbgPrint("RegisterPlayerDeath", ply, attacker, inflictor)
        self:SendDeathNotice(ply, attacker, inflictor, dmgInfo:GetDamageType())

    end

    function GM:PostPlayerDeath(ply)

        DbgPrint("GM:PostPlayerDeath", ply)

        ply.DeathTime = GetSyncedTimestamp()
        ply:SetTeam(LAMBDA_TEAM_DEAD)
        ply:LockPosition(false, false)

        local respawnTime = self:CallGameTypeFunc("GetPlayerRespawnTime")
        ply.RespawnTime = ply.DeathTime + respawnTime

        if self:IsRoundRestarting() == false and self:CallGameTypeFunc("ShouldRestartRound") == false then
            DbgPrint("Notifying respawn")
            self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN,
            {
                EntIndex = ply:EntIndex(),
                Respawn = true,
                StartTime = ply.DeathTime,
                Timeout = respawnTime,
            })
        end

    end

    function GM:PlayerDeathThink(ply)

        if self.WaitingForRoundStart == true or self:IsRoundRestarting() == true then
          DbgPrint("Can not spawn before players available")
          return false
        end

        local elapsed = GetSyncedTimestamp() - ply.DeathTime

        if elapsed >= 5 and ply:IsSpectator() == false then
            ply:SetSpectator()
        end

        if GetSyncedTimestamp() < ply.RespawnTime then
            return false
        end

        local timeout = self:CallGameTypeFunc("GetPlayerRespawnTime")
        if timeout == -1 then
            return false
        end

        if self:CanPlayerSpawn(ply) == false then
            if ply.SpawnBlocked ~= true then
                DbgPrint("Notifying spawn blocked")
                self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN,
                {
                    EntIndex = ply:EntIndex(),
                    Respawn = true,
                    StartTime = ply.DeathTime,
                    Timeout = 0,
                    SpawnBlocked = true,
                })
                ply.SpawnBlocked = true
            end
            return false
        end

        if ply.SpawnBlocked == true then
            DbgPrint("Notifying spawn free")
            self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN,
            {
                EntIndex = ply:EntIndex(),
                Respawn = true,
                StartTime = ply.DeathTime,
                Timeout = 0,
                SpawnBlocked = false,
            })
        end

        ply.SpawnBlocked = false

        if ply:KeyReleased(IN_JUMP) then
            ply:Spawn()
        end

        return true

    end

    function GM:PlayerSwitchFlashlight(ply, enabled)

        if not ply:IsSuitEquipped() then
            return false
        end

        return true

    end

    function GM:LimitPlayerAmmo(ply)

        if lambda_limit_default_ammo:GetBool() == false then
            return
        end

        local curTime = CurTime()

        ply.LastAmmoCheck = ply.LastAmmoCheck or curTime

        if curTime - ply.LastAmmoCheck < 0.100 then
            return
        end

        ply.LastAmmoCheck = curTime

        for k,v in pairs(self.MAX_AMMO_DEF) do
            local count = ply:GetAmmoCount(k)
            local maxCount = v:GetInt()
            if count > maxCount then
                ply:SetAmmo(maxCount, k)
            end
        end

    end

    function GM:AllowPlayerPickup( ply, ent )

        ply.LastPickupTime = ply.LastPickupTime or 0

        local pickupDelay = lambda_pickup_delay:GetFloat()
        local curTime = CurTime()
        if curTime - ply.LastPickupTime < pickupDelay then
            return false
        end

        ply.LastPickupTime = curTime

        return true

    end

    function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)

        local DbgPrint = DbgPrintDmg 

        DbgPrint("ScalePlayerDamage", ply, hitgroup)

        -- Must be called here not in EntityTakeDamage as that runs after so scaling wouldn't work.
        self:ApplyCorrectedDamage(dmginfo)

        local attacker = dmginfo:GetAttacker()

        if dmginfo:IsDamageType(DMG_BULLET) == true then
            self:MetricsRegisterBulletHit(attacker, ply, hitgroup)
        end
        
        -- First scale hitgroups.
        local scale = self:GetDifficultyPlayerHitgroupDamageScale(hitgroup)
        DbgPrint("Hitgroup Scale", npc, scale)
        dmginfo:ScaleDamage(scale)

        -- Scale by difficulty.
        local scaleType = 0
        if attacker:IsPlayer() == true then
            scaleType = DMG_SCALE_PVP
        elseif attacker:IsNPC() == true then
            scaleType = DMG_SCALE_NVP
        end

        if scaleType ~= 0 then
            scale = self:GetDifficultyDamageScale(scaleType)
            if scale ~= nil then
                DbgPrint("Scaling difficulty damage: " .. tostring(scale))
                dmginfo:ScaleDamage(scale)
            end
        end

        if dmginfo:GetDamage() > 0 then
            --DbgPrint("ScalePlayerDamage: " .. tostring(ply))
            self:EmitPlayerHurt(dmginfo:GetDamage(), ply, hitgroup)
        end

        -- Reset water damage
        if ply.IsDrowning ~= true then
            ply.WaterDamage = 0
        end

        if ply:IsPositionLocked() == true then
            dmginfo:ScaleDamage(0)
        end

    end

    function GM:GetFallDamage( ply, speed )
        speed = speed - 480
        return speed * (100 / (1024-480))
    end

    function GM:EmitPlayerHurt(amount, ply, hitgroup)

        if ply:WaterLevel() == 3 then
            return
        end

        if ply:Health() - amount <= 0 then
            -- Dead people dont say stuff
            return
        end

        if hitgroup == nil or hitgroup == HITGROUP_HEAD or hitgroup == HITGROUP_GEAR then
            hitgroup = HITGROUP_GENERIC
        end

        local gender = ply:GetGender()
        local hurtsounds = self.HurtSounds[gender][hitgroup]

        ply.NextHurtSound = ply.NextHurtSound or 0

        local curTime = CurTime()
        if curTime - ply.NextHurtSound >= 2 then
            local snd = table.Random(hurtsounds)
            ply:EmitSound(snd)
            ply.NextHurtSound = curTime + 2
        end

    end

    function GM:PlayerUse(ply, ent)
        if self.MapScript ~= nil and self.MapScript.PlayerUse ~= nil then
            local res = self.MapScript:PlayerUse(ply, ent)
            if res == false then
                return false
            end
        end
        return true
    end

    function GM:FindUseEntity(ply, engineEnt)
        if engineEnt ~= nil and engineEnt:IsVehicle() then 
            engineEnt = self:FindVehicleSeat(ply, engineEnt)
        end 
        if self.MapScript ~= nil and self.MapScript.FindUseEntity ~= nil then
            local res = self.MapScript:FindUseEntity(ply, engineEnt)
            if res ~= nil then
                return res
            end
        end
        return engineEnt
    end

else -- CLIENT

    function GM:CalcView( ply, pos, angles, fov )

        local view = {}

        view.origin = pos
        view.angles = angles
        view.fov = fov
        view.drawviewer = false

        return view

    end

end

local GEIGER_DELAY = 0.25
local GEIGER_SOUND_DELAY = 0.06

function GM:UpdateGeigerCounter(ply, mv, ucmd)

    local curTime = CurTime()

    if SERVER then

        ply.GeigerDelay = ply.GeigerDelay or curTime

        if curTime < ply.GeigerDelay then
            return
        end

        ply.GeigerDelay = curTime + GEIGER_DELAY

        local range = math.Clamp(math.floor(ply:GetNearestRadiationRange() / 4), 0, 255)

        if ply:InVehicle() then
            range = math.Clamp(range * 4, 0, 1000)
        end

        local randChance = math.random(0, 5)
        if randChance == 0 then
            ply:SetGeigerRange(1000)
            ply:SetNearestRadiationRange(1000, true)
        else
            ply:SetGeigerRange(range)
        end

    else

        if ply:Alive() == false or ply ~= LocalPlayer() then
            return
        end

        ply.GeigerSoundDelay = ply.GeigerSoundDelay or curTime

        if curTime < ply.GeigerSoundDelay then
            return
        end

        ply.GeigerSoundDelay = curTime + GEIGER_SOUND_DELAY

        local range = ply:GetGeigerRange() * 4
        --DbgPrint(range)
        if range == 0 or range >= 1000 then
            return
        end

        local pct = 0
        local vol = 0
        local highSnd = false

        if range > 800 then
            pct = 0
        elseif range > 600 then
            pct = 2
            vol = 0.2
        elseif range > 500 then
            pct = 4
            vol = 0.25
        elseif range > 400 then
            pct = 8
            vol = 0.3
            highSnd = true
        elseif range > 300 then
            pct = 8
            vol = 0.35
            highSnd = true
        elseif range > 200 then
            pct = 28
            vol = 0.39
            highSnd = true
        elseif range > 150 then
            pct = 40
            vol = 0.40
            highSnd = true
        elseif range > 100 then
            pct = 60
            vol = 0.45
            highSnd = true
        elseif range > 75 then
            pct = 80
            vol = 0.45
            highSnd = true
        elseif range > 50 then
            pct = 90
            vol = 0.475
        else
            pct = 95
            vol = 0.5
        end

        vol = (vol * (math.random(0, 127) / 255)) + 0.25

        if math.random(0, 127) < pct then
            local snd
            if highSnd then
                snd = "Geiger.BeepHigh"
            else
                snd = "Geiger.BeepLow"
            end
            --DbgPrint("EMITSOUND")
            ply:EmitSound(snd, 75, 100, vol, CHAN_BODY)

        end

    end

end

local SUIT_SPRINT_DRAIN = 20.0
local SUIT_FLASHLIGHT_DRAIN = 2.222
local SUIT_BREATH_DRAIN = 6.7
local SUIT_CHARGE_RATE = 12.5
local SUIT_CHARGE_DELAY = 1.5
local SUIT_ENERGY_CHARGE_RATE = 12.5

function GM:PlayerAllowSprinting(ply, inSprint)

    inSprint = inSprint or false

    if ply:IsSuitEquipped() == false then
        return false
    end

    if ply:WaterLevel() > 1 then
        return false
    end

    if ply:InVehicle() == true then
        return false
    end

    if ply:KeyDown(IN_DUCK) then
        return false
    end

    if ply:GetSuitPower() <= 0 then
        return false
    end

    return true

end

function GM:PlayerStartSprinting(ply, mv)

    --DbgPrint("PlayerStartSprinting: " .. tostring(ply))

    ply:AddSuitDevice(SUIT_DEVICE_SPRINT)

    local playSprintSnd = false

    if game.MaxPlayers() > 1 then
        if CLIENT and IsFirstTimePredicted() then
            playSprintSnd = true
        end
    else
        playSprintSnd = true
    end

    if playSprintSnd then
        local suitPower = ply:GetSuitPower()
        if suitPower <= 0 then
            ply:EmitSound("HL2Player.SprintNoPower")
            return false
        else
            ply:EmitSound("HL2Player.SprintStart")
        end
    end

    ply:SetRunSpeed(lambda_sprintspeed:GetInt()) -- TODO: Put this in a convar.
    ply:SetWalkSpeed(lambda_normspeed:GetInt())
    ply:SetSprinting(true)

    --DbgPrint("Sprint State: " .. tostring(ply:GetSprinting()))

end

function GM:PlayerEndSprinting(ply, mv)

    --DbgPrint("PlayerEndSprinting: " .. tostring(ply) )

    ply:RemoveSuitDevice(SUIT_DEVICE_SPRINT)
    ply:SetRunSpeed(lambda_normspeed:GetInt()) -- TODO: Put this in a convar.
    ply:SetWalkSpeed(lambda_normspeed:GetInt())
    ply:SetSprinting(false)

end

function GM:StartCommand(ply, cmd)

    self:CalculateMovementAccuracy(ply)

    if ply:IsPositionLocked() == true then
        local vel = ply:GetVelocity()
        vel.x = 0
        vel.y = 0
        vel.z = math.Clamp(vel.z, -2, 0)
        ply:SetVelocity(vel)
        cmd:ClearButtons()
        cmd:ClearMovement()

        local viewlock = ply:GetViewLock()
        if viewlock == VIEWLOCK_SETTINGS_ON or viewlock == VIEWLOCK_SETTINGS_RELEASE then
            cmd:SetMouseX(0)
            cmd:SetMouseY(0)
            cmd:SetViewAngles(ply:GetAngles())
        end

        return
    end

    if CLIENT then
        if self:IsScoreboardOpen() == true then
            cmd:SetButtons( bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)) )
            cmd:SetButtons( bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK2)) )
        end

        if lambda_allow_auto_jump:GetBool() == true and lambda_auto_jump:GetBool() == true then
            if ply:GetMoveType() == MOVETYPE_WALK and not ply:IsOnGround() and ply:WaterLevel() < 2 then
                cmd:SetButtons( bit.band( cmd:GetButtons(), bit.bnot( IN_JUMP ) ) )
            end
        end
    end

    if cmd:KeyDown(IN_SPEED) == true and (ply:IsSuitEquipped() ~= true or ply:WaterLevel() > 1) and ply:InVehicle() == false then
        cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_SPEED)))
    end

    -- HACKHACK: When the player is crouched and releases IN_DUCK but can't stand up it would
    -- offset the player for a short moment when pressing IN_DUCK again. We suppress this.
    if ply:Crouching() == true and ply:KeyDown(IN_DUCK) == false and cmd:KeyDown(IN_DUCK) == true then
        cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_DUCK)))
    end

end

function GM:SetupMove(ply, mv, cmd)

    --if not IsFirstTimePredicted() then return end
    if ply:Alive() == false then
        return
    end

    local isSprinting = false
    if ply.GetSprinting ~= nil then
        isSprinting = ply:GetSprinting()
    end

    if mv:KeyDown(IN_DUCK) and ply:IsOnGround() and isSprinting == true then

        self:PlayerEndSprinting(ply, mv)
        ply:SetStateSprinting(false)

    end

    if mv:KeyDown(IN_SPEED) == true then

        --DbgPrint("Is Sprinting: " .. tostring(isSprinting))

        if self:PlayerAllowSprinting(ply) == true and
            isSprinting == false and
            ply:GetStateSprinting() == false and
            self:PlayerStartSprinting(ply, mv) ~= false
        then
            ply:SetStateSprinting(true)
        end

    else

        if isSprinting == true then
            --DbgPrint("IN_SPEED missing, stopped sprinting " .. tostring(isSprinting))
            self:PlayerEndSprinting(ply, mv, cmd)
        end

        ply:SetStateSprinting(false)

    end

end

function GM:Move(ply, mv)

    -- Whoever stumbles upon this code might ask what this is all about.
    --
    -- Its best shown by going to d1_town_01 to the part where you have to lift up the
    -- vehicles, you have to walk on them and them and jump off which is close to impossible
    -- without the code below, feel free to comment it in order to see the difference.
    local groundEnt = ply:GetGroundEntity()

    if mv:KeyDown(IN_JUMP) and groundEnt ~= NULL and IsValid(groundEnt) then
        local class = groundEnt:GetClass()
        if class == "prop_physics" or class == "func_physbox" then
            local phys = groundEnt:GetPhysicsObject()
            if IsValid(phys) and phys:IsMotionEnabled() == true then
                ply:SetPos(ply:GetPos() + Vector(0, 0, 1))
            end
        end
    end

end

function GM:FinishMove(ply, mv)

    if SERVER then

        -- Network velocity to every client to properly sync animations.
        --ply:SetNetworkAbsVelocity(mv:GetVelocity())

        -- Teleport queue.
        local modifiedPlayer = false

        if ply.TeleportQueue ~= nil and #ply.TeleportQueue > 0 then
            local data = ply.TeleportQueue[1]
            ply:SetPos(data.pos)
            ply:SetAngles(data.ang)
            ply:SetVelocity(data.vel)
            ply:SetEyeAngles(data.ang)
            table.remove(ply.TeleportQueue, 1)
            modifiedPlayer = true
        end

        if (mv:GetButtons() ~= 0 or ply:IsBot()) and ply:GetLifeTime() > 0.1 and ply:IsInactive() == true then
            DbgPrint(ply, "Player now active")
            ply:SetInactive(false)
        end

        local curPos = mv:GetOrigin()
        if ply.LastPlayerPos ~= nil then
            local distance = ply.LastPlayerPos:Distance(curPos)
            if distance >= 100 then
                -- Player probably teleported
                DbgPrint("Teleport detected, disabling player collisions temporarily.")
                ply:DisablePlayerCollide(true)
            end
        end
        ply.LastPlayerPos = curPos

        if modifiedPlayer == true then
            return modifiedPlayer
        end

    end

end

function GM:DrainSuit(ply, amount)

    local current = ply:GetSuitPower()
    local res = true

    if ply:GetMoveType() == MOVETYPE_NOCLIP then
        -- Dont do anything in this case
        return true
    end

    if sv_infinite_aux_power:GetBool() == true then
        amount = 0
    end

    current = current - amount

    if current < 0 then
        current = 0
        res = false
    end

    ply:SetSuitPower(current)

    return res

end

function GM:ChargeSuitPower(ply, amount)

    local current = ply:GetSuitPower() + amount
    if current > 100.0 then
        current = 100.0
    end

    ply:SetSuitPower(current)
    ply:RemoveSuitDevice(SUIT_DEVICE_BREATHER)
    ply:RemoveSuitDevice(SUIT_DEVICE_SPRINT)

end

function GM:ShouldChargeSuitPower(ply)

    local sprinting = ply:GetSprinting()
    local inWater = ply:WaterLevel() >= 3
    local flashlightOn = ply:FlashlightIsOn()
    local powerDrain = sprinting or inWater --[[ or flashlightOn ]]

    if powerDrain == true then
        return false -- Something is draning power.
    end

    local power = ply:GetSuitPower()
    if power >= 100.0 then
        return false -- Full
    end

    local curTime = CurTime()
    ply.NextSuitCharge = ply.NextSuitCharge or curTime

    if curTime < ply.NextSuitCharge then
        return false
    end

    --DbgPrint("Should Charge")
    return true

end

function GM:UpdateSuit(ply, mv, ucmd)

    if ply:IsSuitEquipped() == false then
        return
    end

    local frameTime = FrameTime()

    -- Check if we should recharge.
    if self:ShouldChargeSuitPower(ply) == true then

        local amount = SUIT_CHARGE_RATE * frameTime
        self:ChargeSuitPower(ply, amount)

    else

        local powerLoad = 0

        if ply:GetSprinting() then
            local pos = ply:GetAbsVelocity()
            if math.abs(pos.x) > 0 or math.abs(pos.y) > 0 then
                powerLoad = powerLoad + SUIT_SPRINT_DRAIN
            end
        end

        if ply:WaterLevel() >= 3 then
            powerLoad = powerLoad + SUIT_BREATH_DRAIN
            ply:AddSuitDevice(SUIT_DEVICE_BREATHER)
        else
            ply:RemoveSuitDevice(SUIT_DEVICE_BREATHER)
        end

        --[[
        if ply:FlashlightIsOn() then
            ply:AddSuitDevice(SUIT_DEVICE_FLASHLIGHT)
            powerLoad = powerLoad + SUIT_FLASHLIGHT_DRAIN
        else
            ply:RemoveSuitDevice(SUIT_DEVICE_FLASHLIGHT)
        end
        ]]

        if powerLoad > 0 then
            ply.NextSuitCharge = CurTime() + SUIT_CHARGE_DELAY
            if self:DrainSuit(ply, powerLoad * frameTime) == false then
                ply.NextSuitCharge = CurTime() + SUIT_CHARGE_DELAY
                if ply:GetSprinting() == true then
                    self:PlayerEndSprinting(ply, mv)
                    if SERVER then
                        ply:Flashlight(false)
                    end
                end
            end
        end

    end

    self:UpdateGeigerCounter(ply, mv, ucmd)

end

local CHOKE_TIME = 1
local WATER_HEALTH_RECHARGE_TIME = 3

function GM:PlayerCheckDrowning(ply)

    if not ply:Alive() or not ply:IsSuitEquipped() then
        return
    end

    ply.WaterDamage = ply.WaterDamage or 0

    local curTime = CurTime()

    if ply:WaterLevel() ~= 3 then

        if ply.IsDrowning == true then
            ply.IsDrowning = false
        end

        if ply.WaterDamage > 0 then

            ply.NextWaterHealthTime = ply.NextWaterHealthTime or curTime + WATER_HEALTH_RECHARGE_TIME

            if ply:Health() >= 100 then
                ply.WaterDamage = 0
            else
                if ply.NextWaterHealthTime < curTime then

                    ply.WaterDamage = ply.WaterDamage - 10
                    if ply:Health() + 10 > 100 then
                        ply:SetHealth(100)
                    else
                        ply:SetHealth(ply:Health() + 10)
                    end

                    ply.NextWaterHealthTime = curTime + WATER_HEALTH_RECHARGE_TIME
                end

            end

        end

    else

        ply.NextChokeTime = ply.NextChokeTime or curTime + CHOKE_TIME

        if ply:GetSuitPower() == 0 and curTime > ply.NextChokeTime then

            if ply.IsDrowning ~= true then
                ply.IsDrowning = true
                ply.DrowningStartTime = CurTime()
                ply.WaterDamage = 0
            end

            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage( 10 )
            dmgInfo:SetDamageType( DMG_DROWN )
            dmgInfo:SetInflictor( game.GetWorld() )
            dmgInfo:SetAttacker( game.GetWorld() )

            ply:TakeDamageInfo( dmgInfo )

            ply.WaterDamage = ply.WaterDamage + 10
            ply.NextChokeTime = curTime + CHOKE_TIME

        end

    end

end

function GM:PlayerTick(ply, mv)

    -- Predicted, must be called here.
    local ucmd = ply:GetCurrentCommand()
    self:UpdateSuit(ply, mv, ucmd)

    if SERVER then
        self:LimitPlayerAmmo(ply)
        self:PlayerCheckDrowning(ply)
        if ply:GetNWBool("LambdaHEVSuit", false) ~= ply:IsSuitEquipped() then
            ply:SetNWBool("LambdaHEVSuit", ply:IsSuitEquipped())
        end

        -- Remove those useless "weapons"
        if ply:HasWeapon("weapon_frag") and ply:GetAmmoCount("Grenade") == 0 then
            ply:StripWeapon("weapon_frag")
        end

        if ply:HasWeapon("weapon_slam") and ply:GetAmmoCount("slam") == 0 then
            ply:StripWeapon("weapon_frag")
        end
    end

end

function GM:CalculateMovementAccuracy(ent)

    local movementRecoil = ent.MovementRecoil or 0
    ent.MovementRecoil = ent.MovementRecoil or 0

    local vel = ent:GetVelocity()
    local len = vel:Length()
    local target = len / ent:GetWalkSpeed()
    local scale = 100
    if len > 0 then
        scale = 20
    end
    movementRecoil = Lerp(FrameTime() * scale, movementRecoil, target)
    movementRecoil = math.Clamp(movementRecoil, 0, 2)

    ent.MovementRecoil = movementRecoil

end

function GM:PlayerUpdateSettings(ply)

end

function GM:PlayerThink(ply)

    if SERVER then
        local vel = ply:GetVelocity()
        if ply.LambdaPlayerVelocity ~= vel then
            ply:SetNWVector("LambdaPlayerVelocity", vel)
            ply.LambdaPlayerVelocity = vel
        end
    else
        -- Interpolate velocity on client from server.
        -- Normally the client takes last position and calculates velocity based on distance traveled.
        -- This causes the player to always walk on moving objects.
        local vel = ply:GetNWVector("LambdaPlayerVelocity", ply:GetVelocity())
        ply.LambdaPlayerVelocity = LerpVector(FrameTime() * 30, ply.LambdaPlayerVelocity or Vector(0, 0, 0), vel)
    end

    if SERVER then
        -- Make sure we reset the view lock if we are in release mode.
        local viewlock = ply:GetViewLock()
        if viewlock == VIEWLOCK_SETTINGS_RELEASE then
            local viewlockTime = ply:GetNWFloat("ViewLockTime")
            if viewlockTime + VIEWLOCK_RELEASE_TIME < CurTime() then
                ply:LockPosition(false)
            end
        end

    end

    local disablePlayerCollide = ply:GetNWBool("DisablePlayerCollide", false)

    if SERVER then
        if disablePlayerCollide == true and CurTime() >= ply.NextPlayerCollideTest and ply:IsPositionLocked() == false then

            local hullMin, hullMax = ply:GetHull()

            local tr = util.TraceHull({
                start = ply:GetPos(),
                endpos = ply:GetPos(),
                filter = ply,
                mins = hullMin,
                maxs = hullMax,
                mask = MASK_SHOT_HULL,
            })

            if tr.Hit == false then
                ply:DisablePlayerCollide(false)
                DbgPrint("Reset player collision.")
            --else
                --DbgPrint("Trace Hit: " .. tostring(tr.Entity))
            end

        end
    else
        if ply.LastDisablePlayerCollide ~= disablePlayerCollide then
            ply:CollisionRulesChanged()
            ply.LastDisablePlayerCollide = disablePlayerCollide
        end
    end

end

function GM:GravGunPickupAllowed(ply, ent)

    if ent:IsWeapon() and ent:GetClass() ~= "weapon_crowbar" then
        return false
    end

    do
        return true
    end

    --return BaseClass.GravGunPickupAllowed(ply, ent)
end

function GM:GravGunPunt(ply, ent)

    if ent:IsWeapon()  and ent:GetClass() ~= "weapon_crowbar" then
        return false
    end

    local playerVehicle = ply:GetVehicle()
    if playerVehicle ~= NULL and IsValid(playerVehicle) == true and ent:IsVehicle() == true and ent:GetNWEntity("PassengerSeat") == playerVehicle then
        return false
    end

    if ent:IsVehicle() then
        util.RunNextFrame(function()
            if not IsValid(ent) then
                return
            end
            local phys = ent:GetPhysicsObject()
            if not IsValid(phys) then
                return
            end
            local force = phys:GetVelocity()
            force = force * 0.000001
            phys:SetVelocity(force)
        end)
    end

    if ent:IsNPC() and IsFriendEntityName(ent:GetClass()) then
        return false
    end

    return BaseClass.GravGunPickupAllowed(ply, ent)

end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, filter )

    if ply:KeyDown(IN_WALK) then
        return true
    end

    if SERVER then
        self:NotifyNPCFootsteps(ply, pos, foot, sound, volume )
    end

end

function GM:PlayerSwitchWeapon(ply, old, new)
    DbgPrint("PlayerSwitchWeapon", ply, old, new)
end

function GM:OnPlayerAmmoDepleted(ply, wep)

    DbgPrint("Ammo Depleted: " .. tostring(ply) .. " - " .. tostring(wep) )

    if SERVER then
        util.RunDelayed(function()
            self:SelectBestWeapon(ply)
        end, CurTime() + 1.5)
    end

    if CLIENT then
        ply:EmitSound("hl1/fvox/ammo_depleted.wav", 75, 100, 0.5)
    end

end

function GM:PlayerNoClip(ply, desiredState)

    local sv_cheats = GetConVar("sv_cheats")
    if desiredState == false then
        return true
    elseif sv_cheats:GetBool() == true then
        return true
    end

end

function GM:AllowPlayerTracking()
    return self:CallGameTypeFunc("AllowPlayerTracking")
end
