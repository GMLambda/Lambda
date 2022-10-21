--local DbgPrint = function() end

local showtriggers = GetConVar("showtriggers")
local DbgPrint = GetLogging("Trigger")
local DbgPrint2 = GetLogging("TriggerTouch")

local TRIGGER_MSG_PLAYER_COUNT = 0
local TRIGGER_MSG_SHOWWAIT = 1
local TRIGGER_MSG_SETBLOCKED = 2
local TRIGGER_MSG_REMOVED = 3

ENT.Base = "lambda_entity"
ENT.Type = "brush"

if SERVER then

    AddCSLuaFile()

    util.AddNetworkString("LambdaTriggerUpdate")

    DEFINE_BASECLASS("lambda_entity")

    SF_TRIGGER_ALLOW_CLIENTS                = 0x01      -- Players can fire this trigger
    SF_TRIGGER_ALLOW_NPCS                   = 0x02      -- NPCS can fire this trigger
    SF_TRIGGER_ALLOW_PUSHABLES              = 0x04      -- Pushables can fire this trigger
    SF_TRIGGER_ALLOW_PHYSICS                = 0x08      -- Physics objects can fire this trigger
    SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS        = 0x10      -- *if* NPCs can fire this trigger, this flag means only player allies do so
    SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES     = 0x20      -- *if* Players can fire this trigger, this flag means only players inside vehicles can
    SF_TRIGGER_ALLOW_ALL                    = 0x40      -- Everything can fire this trigger EXCEPT DEBRIS!
    SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES = 0x200     -- *if* Players can fire this trigger, this flag means only players outside vehicles can
    SF_TRIG_PUSH_ONCE                       = 0x80      -- trigger_push removes itself after firing once
    SF_TRIG_PUSH_AFFECT_PLAYER_ON_LADDER    = 0x100     -- if pushed object is player on a ladder, then this disengages them from the ladder (HL2only)
    SF_TRIG_TOUCH_DEBRIS                    = 0x400     -- Will touch physics debris objects
    SF_TRIGGER_ONLY_NPCS_IN_VEHICLES        = 0x800     -- *if* NPCs can fire this trigger, only NPCs in vehicles do so (respects player ally flag too)
    SF_TRIGGER_DISALLOW_BOTS                = 0x1000    -- Bots are not allowed to fire this trigger
    SF_TRIGGER_ONLY_PLAYER_WITH_HEV         = 0x8000    -- Triggers only on players with the hev suit.

    function ENT:IsLambdaTrigger()
        return true
    end

    function ENT:PreInitialize()

        DbgPrint(self, "PreInitialize")

        BaseClass.PreInitialize(self)

        self:SetupOutput("OnTrigger")
        self:SetupOutput("OnStartTouch")
        self:SetupOutput("OnStartTouchAll")
        self:SetupOutput("OnEndTouch")
        self:SetupOutput("OnEndTouchAll")

        self:SetInputFunction("Enable", self.Enable)
        self:SetInputFunction("Disable", self.Disable)
        self:SetInputFunction("Toggle", self.Toggle)

        self:SetupNWVar("Disabled", "bool", { Default = false, KeyValue = "StartDisabled", OnChange = self.HandleDisableChange })
        self:SetupNWVar("WaitTime", "float", { Default = 0.2, KeyValue = "wait"} )
        self:SetupNWVar("FilterName", "string", { Default = "", KeyValue = "filtername"} )
        self:SetupNWVar("WaitForTeam", "bool", { Default = false, KeyValue = "teamwait"} )
        self:SetupNWVar("LockPlayers", "bool", { Default = false, KeyValue = "lockplayers"} )
        self:SetupNWVar("Blocked", "bool", { Default = false, KeyValue = "blocked", OnChange = self.HandleBlockingUpdate } )
        -- If WaitForTeam is enabled this specifies the timeout to when to force trigger.
        self:SetupNWVar("Timeout", "float", { Default = 0, KeyValue = "timeout" } )
        -- Teleport all players on timeout.
        self:SetupNWVar("TimeoutTeleport", "bool", { Default = true, KeyValue = "timeoutteleport"})
        self:SetupNWVar("DisableEndTouch", "bool", { Default = false, KeyValue = "disableendtouch" })
        self:SetupNWVar("ShowWait", "bool", { Default = true, KeyValue = "showwait" })
        self:SetupNWVar("MessagePos", "vector", { Default = Vector(0, 0, 0), KeyValue = "messagepos" })

        -- Internal variables
        self.TeamInside = false
        self.IsWaiting = false
        self.NextTimeout = 0
        self.DisabledTouchingObjects = {}
        self.TouchingObjects = {}
        self.LastTouch = CurTime()

        self:AddDebugOverlays(bit.bor(OVERLAY_PIVOT_BIT, OVERLAY_BBOX_BIT, OVERLAY_NAME_BIT))

    end

    function ENT:Initialize()

        BaseClass.Initialize(self)

        DbgPrint(self, "Initialize")

        self:SetNotSolid(true)
        self:SetTrigger(true)

        if IsValid(self:GetParent()) then
            self:SetSolid(SOLID_VPHYSICS)
        else
            self:SetSolid(SOLID_BSP)
        end

        self:AddSolidFlags( FSOLID_NOT_SOLID )
        self:AddSolidFlags( FSOLID_TRIGGER )

        self:SetMoveType( MOVETYPE_NONE )

        if self:HasSpawnFlags(SF_TRIG_TOUCH_DEBRIS) then
            self:AddSolidFlags( FSOLID_TRIGGER_TOUCH_DEBRIS )
        end

        if  self:HasSpawnFlags( SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS ) or
            self:HasSpawnFlags( SF_TRIGGER_ONLY_NPCS_IN_VEHICLES ) then
            self:AddSpawnFlags( SF_TRIGGER_ALLOW_NPCS );
        end

        if self:HasSpawnFlags( SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES )  then
            self:AddSpawnFlags( SF_TRIGGER_ALLOW_CLIENTS );
        end

        if self:HasSpawnFlags( SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES )  then
            self:AddSpawnFlags( SF_TRIGGER_ALLOW_CLIENTS );
        end

        if self:HasSpawnFlags(SF_TRIGGER_ONLY_PLAYER_WITH_HEV) then
            self:AddSpawnFlags( SF_TRIGGER_ALLOW_CLIENTS );
        end

        --DbgPrint(self, "OnTriggerEvents: " .. #self.OnTriggerEvents)
        --DbgPrint(self, "OnStartTouchEvents: " .. #self.OnStartTouchEvents)

        if showtriggers:GetBool() == false then
            self:AddEffects(EF_NODRAW)
            self:AddDebugOverlays(OVERLAY_BBOX_BIT)
        else
            self:RemoveEffects(EF_NODRAW)
            self:RemoveDebugOverlays(OVERLAY_BBOX_BIT)
        end

        if self:GetNWVar("Blocked") == true then
            self:HandleBlockingUpdate(nil, false, true)
        end

        hook.Add("PlayerInitialSpawn", self, function(gm, ply)
            gm:FullPlayerUpdate(ply)
        end)

    end

    function ENT:KeyValue(key, val)

        BaseClass.KeyValue(self, key, val)

    end

    function ENT:HandleDisableChange(key, wasDisabled, isDisabled)

        if wasDisabled == false and isDisabled == true then

            if self.IsWaiting == true then
                DbgPrint("Reset state because it got disabled")
                self:CmdShowTeamWaiting(nil, false, 0)
            end

        end

    end

    function ENT:HandleBlockingUpdate(key, wasBlocked, wantsBlocking)

        DbgPrint(self, "HandleBlockingUpdate", wasBlocked, wantsBlocking)

        if wasBlocked == true and wantsBlocking == false then
            self:SetCustomCollisionCheck(false)
            if IsValid(self:GetPhysicsObject()) then
                self:PhysicsDestroy()
            end
            if self.PrevModel ~= nil then
                self:SetModel(self.PrevModel)
            end
            self:SetTrigger(true)
            self:CollisionRulesChanged()
        elseif wasBlocked == false and wantsBlocking == true then
            self:PhysicsInit(SOLID_BSP)
            self:SetSolid(SOLID_BSP)
            self:SetMoveType(MOVETYPE_NONE)
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end
            self:SetCustomCollisionCheck(true)
            self:CollisionRulesChanged()
            self.PrevModel = self:GetModel()
        end

        self:CmdSetBlocked(nil)

    end

    function ENT:SetupTrigger(pos, ang, mins, maxs, spawn, spawnflags)

        --DbgPrint("Creating Trigger at " .. tostring(pos) .. "\n\tMins: "..tostring(mins) .. "\n\tMaxs: " .. tostring(maxs))
        if spawnflags == nil then
            spawnflags = SF_TRIGGER_ALLOW_CLIENTS
        end
        self:SetPos(pos)
        self:SetAngles(ang)
        self:AddSpawnFlags(spawnflags)
        self:SetTrigger(true)
        self:SetMoveType(0)
        self:SetNoDraw(true)

        if spawn == nil or spawn == true then
            self:Spawn()
        end

        self:SetTrigger(true)
        self:SetCollisionBounds(mins, maxs)
        self:UseTriggerBounds(true)

    end

    function ENT:ResizeTriggerBox(mins, maxs)

        self:SetTrigger(true)
        self:SetCollisionBounds(mins, maxs)
        self:UseTriggerBounds(true)

    end

    function ENT:Enable()
        DbgPrint(self, "ENT:Enable")

        -- This is a lame workaround but sadly theres no binding to invalidate touch links.
        -- To explain this scenario:
        --  NPC walks in into a trigger, its currently Disabled.
        --  The npc will stop calling Touch once it stops moving unlike players.
        --  NPC now presses a button that enables the trigger but it wont fire StartTouch/Touch as the NPC is not moving after.
        --  So we have to do this:
        -- 8/6/2016: FIX -- Delay by a frame it can cause recursion, happens if two triggers disable/enable each other constantly.
        -- apparanetly its also done in Source SDK.
        util.RunNextFrame(function()
            if not IsValid(self) then
                return
            end

            self:SetNWVar("Disabled", false)

            if not self:IsEFlagSet(EFL_CHECK_UNTOUCH) then
                self:AddEFlags(EFL_CHECK_UNTOUCH)
            end

            for k,v in pairs(self.DisabledTouchingObjects) do
                local ent = Entity(k)
                if IsValid(ent) then
                    self:StartTouch(ent)
                end
            end

            for k,v in pairs(self.DisabledTouchingObjects) do
                local ent = Entity(k)
                if IsValid(ent) then
                    self:Touch(ent)
                end
            end

            self.DisabledTouchingObjects = {}
        end)
    end

    function ENT:Disable()
        DbgPrint(self, "ENT:Disable")
        --self:RemoveSolidFlags(FSOLID_TRIGGER)
        self:SetNWVar("Disabled", true)
        self:RemoveEFlags(EFL_CHECK_UNTOUCH)

        self.DisabledTouchingObjects = self.TouchingObjects or {}
    end

    function ENT:IsDisabled()
        return self:GetNWVar("Disabled", false)
    end
    
    function ENT:Toggle()
        DbgPrint(self, "ENT:Toggle")
        if self:GetNWVar("Disabled") == false then
            self:Disable()
        else
            self:Enable()
        end
    end

    function ENT:GetTimeout()
        local timeout = self:GetNWVar("Timeout", 0)
        if timeout ~= 0 then
            return timeout
        end
        local setting = GAMEMODE:GetSetting("checkpoint_timeout")
        return setting
    end

    function ENT:OnRemove()
        -- Only send the info if really needed.
        self.TeamInside = false
        self.IsWaiting = false
        self.NextTimeout = 0
        self.DisabledTouchingObjects = {}
        self.TouchingObjects = {}

        self:FullPlayerUpdate()
    end

    function ENT:SetWaitTime(waitTime)
        --self.WaitTime = tonumber(waitTime or -1)
        self:KeyValue("wait", tostring(waitTime))
    end

    function ENT:SetBlocked(blocked)
        if blocked == true then
            self:SetKeyValue("blocked", "1")
        else
            self:SetKeyValue("blocked", "0")
        end
    end

    function ENT:IsBlocked()

        return self:GetNWVar("Blocked", false)

    end

    function ENT:Think()

        local playersInside = 0

        for id, v in pairs(self.DisabledTouchingObjects) do
            local ent = Entity(id)
            if not IsValid(ent) then
                self.DisabledTouchingObjects[id] = nil
            end
        end

        for id,v in pairs(self.TouchingObjects) do

            local ent = Entity(id)
            if not IsValid(ent) then
                self.TouchingObjects[id] = nil
                continue
            end

            if ent:IsPlayer() then
                if ent:Alive() == true then
                    playersInside = playersInside + 1
                else
                    self.TouchingObjects[id] = nil
                    continue
                end
            end

            --
            -- HACKHACK: Sometimes the player slips thru the trigger so it stops calling Touch.
            if CurTime() - v >= 0.2 and ent:IsPlayer() == true then
                DbgPrint(self, "Enforcing Touch")
                self:Touch(ent)
            end

        end

        if self:GetNWVar("WaitForTeam") == true then

            local playersAlive = 0
            for _,v in pairs(player.GetAll()) do
                if v:Alive() then
                    playersAlive = playersAlive + 1
                end
            end

            if playersInside >= playersAlive then
                self.TeamInside = true
            elseif playersInside < playersAlive then
                self.TeamInside = false
            end

            if playersInside > 0 then
                if self:GetNWVar("Disabled") == false then
                    if self.IsWaiting == false and playersInside > 0 then
                        local timeout = self:GetTimeout()
                        if timeout > 0 then
                            DbgPrint("Setting next timeout")
                            self.NextTimeout = GetSyncedTimestamp() + timeout
                        else
                            DbgPrint("No timeout set")
                        end
                        self.IsWaiting = true
                        self:CmdShowTeamWaiting(nil, true, self.NextTimeout)
                        self:CmdPlayerCount(nil)
                    elseif self.IsWaiting == true and playersInside == 0 then
                        self.IsWaiting = false
                        self:CmdShowTeamWaiting(nil, false, 0)
                        self.NextTimeout = 0
                    end
                else
                    --DbgPrint(self, "Logic disabled!")
                end
            else
                if self.IsWaiting == true then
                    self.IsWaiting = false
                    self:CmdShowTeamWaiting(nil, false, 0)
                    self.NextTimeout = 0
                end
            end
        end

    end

    -- This is basically OnTriggerEvents
    function ENT:Touch(ent)

        --DbgPrint(self, "Touch")
        self.LastTouch = CurTime()

        local waitTime = self:GetNWVar("WaitTime")

        local waitForTeam = self:GetNWVar("WaitForTeam")
        if waitForTeam == true and ent:IsPlayer() then
            ent:DisablePlayerCollide(true)
        end

        if self:GetNWVar("Disabled") == true or self:GetNWVar("Blocked") == true then
            --DbgPrint("Disabled")
            return
        end

        if self.NextWait ~= nil and self.NextWait ~= 0 then
            if CurTime() < self.NextWait then
                return
            end
            self.NextWait = nil
        end

        if self.PassesTriggerFilters and self:PassesTriggerFilters(ent) == false then
            --DbgPrint(self, "Object " .. tostring(ent) .. " did not pass trigger filter")
            return
        end

        local entIndex = ent:EntIndex()
        self.TouchingObjects[entIndex] = CurTime()

        DbgPrint2(self, "Touch(" .. tostring(ent) .. ") -> flags: " .. tostring(self:GetSpawnFlags()) .. ", wait: " .. waitTime)

        --DbgPrint(self, "Touch(" .. tostring(ent) .. ") -> flags: " .. tostring(self:GetSpawnFlags()) .. ", wait: " .. tostring(self.WaitTime))
        --DbgPrint(self, "OnTriggerEvents: " .. #self.OnTriggerEvents)
        local timeoutEvent = false
        if self:GetNWVar("WaitForTeam") == true  then
            --DbgPrint("Waiting")
            if self.TeamInside == false then
                local timeout = self:GetTimeout()
                if self.NextTimeout == 0 then
                    -- Wait for all players without timeout.
                    return
                else
                    if GetSyncedTimestamp() < self.NextTimeout then
                        return
                    else
                        -- Timeout event
                        timeoutEvent = true
                        self.NextTimeout = 0
                    end
                end
            else
                self.IsWaiting = false
            end
        end

        if timeoutEvent == true then
            self:FireOnTimeout()
        end

        if self.OnTrigger ~= nil and isfunction(self.OnTrigger) then
            self.OnTrigger(self, ent)
        end
        
        self:FireOutputs("OnTrigger", nil, ent)

        if waitTime < 0 then
            self:Disable()
            self:Remove()
        else
            self.NextWait = CurTime() + waitTime
        end

    end

    function ENT:TeleportAllToTrigger()

        local missingEnts = {}
        for _,v in pairs(ents.GetAll()) do
            if not self:IsEntityTouching(v) and self:PassesTriggerFilters(v) then
                local isAlive = true
                if v:IsPlayer() then
                    isAlive = v:Alive()
                end
                if isAlive then
                    table.insert(missingEnts, v)
                end
            end
        end

        -- Teleport missing objects into the box
        local centerPos = Vector(0, 0, 0)
        local numEntries = 0
        for k,_ in pairs(self.TouchingObjects) do
            local ent = Entity(k)
            if IsValid(ent) then
                local pos  = ent:GetPos()
                centerPos:Add(pos)
                numEntries = numEntries + 1
            end
        end

        if numEntries > 0 then
            centerPos = centerPos / numEntries
        else
            -- This should in theory never happen but in case it does
            -- lets have the location not at 0,0,0
            centerPos = self:OBBCenter()
        end

        for _,v in pairs(missingEnts) do
            if v:IsPlayer() then
                v:TeleportPlayer(centerPos)
            else
                v:SetPos(centerPos)
            end
            -- Add to touching objects
            self.TouchingObjects[v:EntIndex()] = CurTime()
        end

    end

    function ENT:FireOnTimeout()

        -- Teleport all entities that passes the filter rules
        if self:GetNWVar("TimeoutTeleport", false) == true then
            self:TeleportAllToTrigger()
        end

        -- Fire custom output
        self:FireOutputs("OnWaitTimeout", nil, nil)

        if self.OnWaitTimeout ~= nil and isfunction(self.OnWaitTimeout) then
            self:OnWaitTimeout()
        end

    end

    function ENT:StartTouch(ent)

        --DbgPrint(self, "StartTouch(" .. tostring(ent) .. ")")
        local entIndex = ent:EntIndex()

        if self:GetNWVar("Disabled") == true then
            if self.DisabledTouchingObjects[entIndex] == nil then
                self.DisabledTouchingObjects[entIndex] = CurTime()
            end
            return
        end

        if self:PassesTriggerFilters(ent) == false then
            --DbgPrint("Object " .. tostring(ent) .. " did not pass trigger filter")
            return
        end

        if self:GetNWVar("Blocked") == true and ent:IsPlayer() then

            local dir = self:OBBCenter() - ent:GetPos()
            local ang = dir:Angle()
            local force = 1400
            if ent:IsOnGround() == false then
                force = 200
            end
            local vel = -ang:Forward() * force
            vel.z = 0
            ent:SetVelocity(vel)

            return
        end

        if self.OnStartTouch ~= nil and isfunction(self.OnStartTouch) then
            self:OnStartTouch(ent)
        end

        self.TouchingObjects = self.TouchingObjects or {} -- This is called before Initialize?
        if self.TouchingObjects[entIndex] == nil then

            self.TouchingObjects[entIndex] = CurTime()

            if ent:IsPlayer() and self:GetNWVar("LockPlayers") == true --[[ self.LockPlayers ]] then
                DbgPrint(self, "StartTouch: Locking player " .. tostring(ent))
                ent:LockPosition(true)
            end

            local waitForTeam = self:GetNWVar("WaitForTeam")
            --local disabled = self:GetNWVar("Disabled")
            --DbgPrint("WaitForTeam: " .. tostring(waitForTeam), "Disabled: " .. tostring(disabled))

            if waitForTeam == false or (waitForTeam == true and self.TeamInside == true) then
                DbgPrint(self, CurTime() .. ", OnStartTouch")
                self:FireOutputs("OnStartTouch", nil, ent)
            end

            if table.Count(self.TouchingObjects) == 1 then
                DbgPrint(self, CurTime() .. ", OnStartTouchAll")
                self:FireOutputs("OnStartTouchAll", nil, ent)
            end

        end

        if self.IsWaiting == true then
            self:CmdPlayerCount(nil)
        end

    end

    function ENT:EndTouch(ent)

        local entIndex = ent:EntIndex()

        if self.DisabledTouchingObjects[entIndex] ~= nil then
            self.DisabledTouchingObjects[entIndex] = nil
        end

        if self:GetNWVar("DisableEndTouch") ~= true then

            self.TouchingObjects = self.TouchingObjects or {} -- Seems this is called before Initialize in some cases.
            if self.TouchingObjects[entIndex] ~= nil then

                self.TouchingObjects[entIndex] = nil

                local waitForTeam = self:GetNWVar("WaitForTeam")
                if waitForTeam == false or (waitForTeam and self.TeamInside == true) then
                    self:FireOutputs("OnEndTouch", nil, ent)
                    if self.OnEndTouch ~= nil then
                        self:OnEndTouch(ent)
                    end
                end

                if table.Count(self.TouchingObjects) == 0 then
                    if self.OnEndTouchAll then
                        self:OnEndTouchAll()
                    end

                    self:FireOutputs("OnEndTouchAll", nil, ent)
                end
            end

            if self.IsWaiting == true then
                self:CmdPlayerCount(nil)
            end
        end

    end

    function ENT:IsEntityTouching(ent)
        local id = ent:EntIndex()
        return self.TouchingObjects[id] ~= nil
    end

    function ENT:IsPlayerTouching(ply)
        return self:IsEntityTouching(ply)
    end

    function ENT:GetTouchingObjects()

        -- Instead of our internal data we return it a list of entities.
        local touching = {}

        for entId,_ in pairs(self.TouchingObjects) do
            local ent = Entity(entId)
            if IsValid(ent) then
                table.insert(touching, ent)
            else
                -- Lets clean it up
                self.TouchingObjects[entId] = nil
            end
        end

        return touching

    end

    local ENTITY_META = FindMetaTable("Entity")
    local ENT_PassesFilter = ENTITY_META.PassesFilter

    function ENT:PassesTriggerFilters(ent)

        if self:HasSpawnFlags(SF_TRIGGER_ALLOW_ALL) or
            (self:HasSpawnFlags(SF_TRIGGER_ALLOW_CLIENTS) and ent:IsPlayer()) or
            (self:HasSpawnFlags(SF_TRIGGER_ALLOW_NPCS) and ent:IsNPC()) or
            (self:HasSpawnFlags(SF_TRIGGER_ALLOW_PUSHABLES) and ent:GetClass() == "func_pushable") or
            (self:HasSpawnFlags(SF_TRIGGER_ALLOW_PHYSICS) and ent:GetMoveType() == MOVETYPE_VPHYSICS)
        then

            if ent:IsNPC() then

                if self:HasSpawnFlags(SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS) and IsFriendEntityName(ent:GetClass()) == false then
                    return false
                end

                if self:HasSpawnFlags(SF_TRIGGER_ONLY_NPCS_IN_VEHICLES) then

                    -- TODO: There is no way to tell if a NPC is inside a vehicle, figure out if we can obtain it via savetable.

                end

            end

            if self:HasSpawnFlags(SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES) and ent:IsPlayer() then
                if ent:InVehicle() == false then
                    --DbgPrint("Client must be in vehicle")
                    return false
                end

            end

            if self:HasSpawnFlags(SF_TRIGGER_ONLY_PLAYER_WITH_HEV) and ent:IsPlayer() then
                if ent:IsSuitEquipped() == false then
                    return false
                end
            end

            if self:HasSpawnFlags(SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES) and ent:IsPlayer() then

                if ent:InVehicle() == true then
                    --DbgPrint("Client must be not in vehicle")
                    return false
                end

            end

            local filterName = self:GetNWVar("FilterName")
            if filterName ~= nil and filterName ~= "" then

                local filter = ents.FindFirstByName(filterName)
                if IsValid(filter) and filter.PassesFilter then
                    --DbgPrint("Using filter: " .. self.Filter .. " ( " .. tostring(filter) .. ") -> " .. tostring(ent))
                    --local res = filter:PassesFilter(self, ent)
                    local res = ENT_PassesFilter(filter, self, ent)
                    --DbgPrint("Result: " .. tostring(res))
                    return res
                end

            end

            return true

        end

        return false

    end

    function ENT:CmdPlayerCount(ply)

        if self:GetNWVar("ShowWait") == false then
            return
        end

        if ply == nil then
            ply = player.GetHumans()
            if #ply == 0 then
                return
            end
        end

        local playerCount = 0
        local players = {}

        for entId, _ in pairs(self.TouchingObjects) do
            local ent = Entity(entId)
            if IsValid(ent) and ent:IsPlayer() then
                playerCount = playerCount + 1
                table.insert(players, entId)
            end
        end

        net.Start("LambdaTriggerUpdate")
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteUInt(TRIGGER_MSG_PLAYER_COUNT, 4)
        net.WriteUInt(playerCount, 8)
        for _,v in pairs(players) do
            if v >= 255 then
                ErrorNoHalt("CRITICAL ERROR: Player entIndex > 255")
            end
            net.WriteUInt(v, 8)
        end

        net.Send(ply)

    end

    function ENT:CmdShowTeamWaiting(ply, state, timeout)

        if self:GetNWVar("ShowWait") == false then
            return
        end
        
        DbgPrint(self, "Sending trigger update: ", state, timeout)

        if ply == nil then
            ply = player.GetHumans()
            if #ply == 0 then
                return
            end
        end

        net.Start("LambdaTriggerUpdate")
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteUInt(TRIGGER_MSG_SHOWWAIT, 4)
        net.WriteBool(state)
        if state == true then
            net.WriteFloat(timeout)
            net.WriteVector(self:GetPos())
            net.WriteVector(self:OBBCenter())
            net.WriteVector(self:OBBMins())
            net.WriteVector(self:OBBMaxs())
            local msgPos = self:GetNWVar("MessagePos", Vector(0, 0, 0))
            net.WriteVector(msgPos)
        end
        net.Send(ply)

    end

    function ENT:CmdSetBlocked(ply)

        local blocked = self:GetNWVar("Blocked")

        DbgPrint(self, "Sending trigger blocked: ", blocked)

        if ply == nil then
            ply = player.GetHumans()
            if #ply == 0 then
                return
            end
        end

        net.Start("LambdaTriggerUpdate")
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteUInt(TRIGGER_MSG_SETBLOCKED, 4)
        net.WriteBool(blocked)

        if blocked == true then
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                local meshData = phys:GetMesh()
                net.WriteTable(meshData)
            else
                DbgError(self, "No valid phys object while blocking!")
                net.WriteTable({})
            end
            net.WriteVector(self:GetPos())
            net.WriteVector(self:OBBCenter())
            net.WriteVector(self:OBBMins())
            net.WriteVector(self:OBBMaxs())
            local msgPos = self:GetNWVar("MessagePos", Vector(0, 0, 0))
            net.WriteVector(msgPos)
        end

        net.Send(ply)

    end

    function ENT:CmdTriggerRemoved()

        if player.GetCount() == 0 then
            return
        end

        -- Wipe it from the table on the client, he doesnt need to do anything anymore.
        net.Start("LambdaTriggerUpdate")
        net.WriteUInt(self:EntIndex(), 13)
        net.WriteUInt(TRIGGER_MSG_REMOVED, 4)
        net.Broadcast()

    end

    function ENT:FullPlayerUpdate(ply)

        DbgPrint("Sending full update for trigger")

        self:CmdShowTeamWaiting(ply, self.IsWaiting, self.NextTimeout)
        self:CmdPlayerCount(ply)
        self:CmdSetBlocked(ply)

    end


else -- CLIENT

    LAMBDA_TRIGGERS = LAMBDA_TRIGGERS or {}

    local function CmdShowTeamWaiting(entIndex)

        LAMBDA_TRIGGERS[entIndex] = LAMBDA_TRIGGERS[entIndex] or {}

        local state = net.ReadBool()
        if state == true then

            local timeout = net.ReadFloat()
            local pos = net.ReadVector()
            local center = net.ReadVector()
            local obbMins = net.ReadVector()
            local obbMaxs = net.ReadVector()
            local messagePos = net.ReadVector()

            DbgPrint(self, "Trigger(" .. entIndex .. ") waiting for team, timeout: " .. timeout)

            LAMBDA_TRIGGERS[entIndex].Timeout = timeout
            LAMBDA_TRIGGERS[entIndex].Pos = pos
            LAMBDA_TRIGGERS[entIndex].Center = center
            LAMBDA_TRIGGERS[entIndex].Mins = obbMins
            LAMBDA_TRIGGERS[entIndex].Maxs = obbMaxs
            LAMBDA_TRIGGERS[entIndex].MessagePos = messagePos
            LAMBDA_TRIGGERS[entIndex].PlayerCount = 0
            LAMBDA_TRIGGERS[entIndex].ActivePlayers = {}
            LAMBDA_TRIGGERS[entIndex].Waiting = true

        else

            --DbgPrint("Trigger(" .. entIndex .. ") no longer waiting for team")
            LAMBDA_TRIGGERS[entIndex].Waiting = false

        end

    end

    local function CmdPlayerCount(entIndex)

        local count = net.ReadUInt(8)

        DbgPrint("Trigger(" .. entIndex .. ") new player count: " .. count)

        if LAMBDA_TRIGGERS[entIndex] == nil then
            DbgError("Unknown trigger, we can not update information: " .. entIndex)
            return
        end

        LAMBDA_TRIGGERS[entIndex].PlayerCount = count
        LAMBDA_TRIGGERS[entIndex].ActivePlayers = {}

        for i = 1, count do
            local plyIndex = net.ReadUInt(8)
            table.insert(LAMBDA_TRIGGERS[entIndex].ActivePlayers, plyIndex)
        end

    end

    local function CmdSetBlocked(entIndex)

        DbgPrint("Received trigger block update")

        LAMBDA_TRIGGERS[entIndex] = LAMBDA_TRIGGERS[entIndex] or {}

        local state = net.ReadBool()
        if state == true then
            local meshData = net.ReadTable()
            local pos = net.ReadVector()
            local center = net.ReadVector()
            local maxs = net.ReadVector()
            local mins = net.ReadVector()
            local msgPos = net.ReadVector()
            LAMBDA_TRIGGERS[entIndex].MeshData = meshData
            LAMBDA_TRIGGERS[entIndex].Pos = pos
            LAMBDA_TRIGGERS[entIndex].Center = center
            LAMBDA_TRIGGERS[entIndex].Maxs = maxs
            LAMBDA_TRIGGERS[entIndex].Mins = mins
            LAMBDA_TRIGGERS[entIndex].MessagePos = msgPos
            DbgPrint("Trigger(" .. entIndex .. ") now blocked")
        else
            -- What shall we do about this?
            DbgPrint("Trigger(" .. entIndex .. ") now unblocked")
        end

        LAMBDA_TRIGGERS[entIndex].Blocked = state

    end

    net.Receive("LambdaTriggerUpdate", function(len)

        local entIndex = net.ReadUInt(13)
        local msg = net.ReadUInt(4)

        if msg == TRIGGER_MSG_SHOWWAIT then
            CmdShowTeamWaiting(entIndex)
        elseif msg == TRIGGER_MSG_PLAYER_COUNT then
            CmdPlayerCount(entIndex)
        elseif msg == TRIGGER_MSG_SETBLOCKED then
            CmdSetBlocked(entIndex)
        elseif msg == TRIGGER_MSG_REMOVED then
            LAMBDA_TRIGGERS[entIndex] = nil
        end

    end)

    local MAT_POINTER = Material( "lambda/run_point.vmt" )

    surface.CreateFont( "LAMBDA_1",
    {
        font = "Arial",
        size = 33,
        weight = 600,
        blursize = 10,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = true,
        additive = false,
        outline = true,
    } )

    surface.CreateFont( "LAMBDA_2",
    {
        font = "Arial",
        size = 33,
        weight = 600,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    } )

    local function GetTextColor()
        local col = util.StringToType(lambda_hud_text_color:GetString(), "vector")
        return col
    end

    local function GetBGColor()
        local col = util.StringToType(lambda_hud_bg_color:GetString(), "vector")
        return col
    end

    local Vec3Zero = Vector(0, 0, 0)
    local function DrawTriggerWaiting(data)

        local activePlayers = data.ActivePlayers
        local scheduledTime = data.Timeout
        local pos = data.Pos + data.Center
        local ang = Angle(0, 0, 0)
        local realPos = data.Pos 
        local obbMins = data.Mins
        local obbMaxs = data.Maxs
        
        local allowLocalView = true
        -- If the trigger has specified the message position use that.
        if data.MessagePos ~= Vec3Zero then
            pos = data.Pos + data.MessagePos
            allowLocalView = false
        end

        local playerCount = 0
        local activePlayerCount = #activePlayers

        for _,v in pairs(player.GetAll()) do
            if v:Alive() then
                playerCount = playerCount + 1
            end
        end

        local ply = LocalPlayer()
        local eyePos = ply:EyePos()
        local eyeAngles = EyeAngles()

        local distance = eyePos:Distance(pos)
        local localView = false
        local textColor = GetTextColor()
        local colorBg = GetBGColor()

        local showRunner = true
        if distance < 50 then
            localView = true
        end

        if allowLocalView and table.HasValue(activePlayers, ply:EntIndex()) then
            local plyPos = ply:GetPos()
            if plyPos:WithinAABox(realPos + (obbMins * 5), realPos + (obbMaxs * 5)) == true then
                localView = true
            end
        end

        if localView == true then
            local tr = ply:GetEyeTrace()
            local hitDistance = eyePos:Distance(tr.HitPos)
            local fwdDistance = 50
            if hitDistance < fwdDistance then
                fwdDistance = hitDistance
            end
            if ply:InVehicle() then
                if fwdDistance < 200 then
                    fwdDistance = 200
                end
            else
                if fwdDistance < 30 then
                    fwdDistance = 30
                end
            end
            pos = eyePos + (eyeAngles:Forward() * fwdDistance)
            showRunner = false
        end

        local w, h = 0,0
        local text = ""

        local remaining = scheduledTime - GetSyncedTimestamp()
        if remaining < 0 then
            remaining = 0
        end

        local bounce = math.sin(SysTime() * 5) + math.cos(SysTime() * 5)
        pos = pos + (Vector(0, 0, 1) * bounce)

        local screenPos = pos:ToScreen()

        local x = screenPos.x
        local y = screenPos.y

        pcall(function()
            surface.SetFont("LAMBDA_2")

            local textY = 0
            local spacing = 10

            text = "Waiting for players: " .. tostring(activePlayerCount) .. " / " .. tostring(playerCount)
            draw.DrawText( text, "LAMBDA_1", x, y + textY, colorBg, TEXT_ALIGN_CENTER )
            draw.DrawText( text, "LAMBDA_2", x, y + textY, textColor, TEXT_ALIGN_CENTER )
            w,h = surface.GetTextSize( text )
            textY = textY + h + spacing

            text = "Game will continue once all players are here"
            draw.DrawText( text, "LAMBDA_1", x, y + textY, colorBg, TEXT_ALIGN_CENTER )
            draw.DrawText( text, "LAMBDA_2", x, y + textY, textColor, TEXT_ALIGN_CENTER )
            textY = textY + h + spacing

            if scheduledTime > 0 then

                text = "Timeout in " .. string.format("%.02f", remaining) .. " seconds"

                draw.DrawText( text, "LAMBDA_1", x, y + textY, colorBg, TEXT_ALIGN_CENTER )
                draw.DrawText( text, "LAMBDA_2", x, y + textY, textColor, TEXT_ALIGN_CENTER )
                textY = textY + h + spacing

            end

            if showRunner == true then
                textColor = Vector(textColor.r / 255, textColor.g / 255, textColor.b / 255)
                MAT_POINTER:SetVector("$tint", textColor)

                surface.SetDrawColor( textColor.r, textColor.g, textColor.b, 200 )
                surface.SetMaterial( MAT_POINTER )
                surface.DrawTexturedRect( x + -40, y + textY + 40 + (-bounce * 10), 80, 80 )
            end

        end)

    end

    local MAT_BLOCKED = Material("lambda/blocked.vmt")

    local function DrawTriggerBlockade(data)

        local cachedMesh = data.Mesh

        if cachedMesh == nil then
            cachedMesh = Mesh(MAT_BLOCKED)

            local bounds = data.Maxs - data.Mins
            local meshData = table.Copy(data.MeshData)

            local texture_w = 48
            for i = 1, #meshData do
                local v1 = meshData[i]
                v1.normal = Vector(0,0,0)
            end

            for i = 1, #meshData do
                local v1 = meshData[i]
                local v2 = meshData[i + 1]
                local v3 = meshData[i + 2]
                if v1 == nil or v2 == nil or v3 == nil then
                    continue
                end
                local e1 = v1.pos - v2.pos
                local e2 = v3.pos - v2.pos
                local no = e1:Cross(e2)
                v1.normal = v1.normal + no
                v2.normal = v2.normal + no
                v3.normal = v3.normal + no
            end

            for i = 1, #meshData do
                local v1 = meshData[i]
                v1.normal:Normalize()
                local rel = v1.pos
                meshData[i].v = (rel.y % texture_w) / texture_w
                meshData[i].u = (rel.x % texture_w) / texture_w
            end

            cachedMesh:BuildFromTriangles(meshData)
            data.Mesh = cachedMesh
        end

        render.SetMaterial(MAT_BLOCKED)
        cachedMesh:Draw()

    end

    hook.Add("PostDrawTranslucentRenderables", "LambdaTrigger", function(bDrawingDepth, bDrawingSkybox)

        if bDrawingSkybox == true then
            return
        end

        for k, data in pairs(LAMBDA_TRIGGERS) do

            if data.Blocked == true then
                DrawTriggerBlockade(data)
            end

        end

    end)

    hook.Add("HUDPaint", "LambdaTrigger", function()

        for k, data in pairs(LAMBDA_TRIGGERS) do

            if data.Waiting == true then
                DrawTriggerWaiting(data)
            end

        end

    end)

end
