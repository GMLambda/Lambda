if SERVER then
    AddCSLuaFile()
end

--local DbgPrint = print
local DbgPrint = GetLogging("ViewControl")
-- Spawnflags
local SF_CAMERA_PLAYER_POSITION = 1
--local SF_CAMERA_PLAYER_TARGET = 2
local SF_CAMERA_PLAYER_TAKECONTROL = 4
local SF_CAMERA_PLAYER_INFINITE_WAIT = 8
local SF_CAMERA_PLAYER_SNAP_TO = 16
local SF_CAMERA_PLAYER_NOT_SOLID = 32
local SF_CAMERA_PLAYER_INTERRUPT = 64
local SF_CAMERA_PLAYER_MULTIPLAYER_ALL = 128
local SF_CAMERA_PLAYER_NODRAW = 256
ENT.Base = "lambda_entity"
ENT.Type = "anim"
DEFINE_BASECLASS("lambda_entity")
local vec3_origin = Vector(0, 0, 0)

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")
    self:SetupOutput("OnEndFollow")
    self:SetInputFunction("Enable", self.Enable)
    self:SetInputFunction("Disable", self.Disable)

    self:SetupNWVar("Disabled", "bool", {
        Default = true,
        KeyValue = "StartDisabled"
    })

    self.ActivePlayers = self.ActivePlayers or {}
    self.GlobalState = self.GlobalState or ""
    self.Acceleration = self.Acceleration or 0
    self.Deceleration = self.Deceleration or 0
    self.Wait = self.Wait or 0
    self.Speed = self.Speed or 0
    self.MoveTo = self.MoveTo or ""
    self.TargetName = self.TargetName or ""
    self.TargetAttachment = ""
    self.InitialSpeed = 0
    self.TargetActive = false
    self.MoveDir = Vector()
    self.MoveDistance = 0
    self.StopTime = 0
end

function ENT:KeyValue(key, val)
    BaseClass.KeyValue(self, key, val)
    DbgPrint(self, "KeyValue", key, val)

    if key:iequals("globalstate") then
        self.GlobalState = val
    elseif key:iequals("acceleration") then
        self.Acceleration = tonumber(val)
    elseif key:iequals("deceleration") then
        self.Deceleration = tonumber(val)
    elseif key:iequals("wait") then
        self.Wait = tonumber(val)
    elseif key:iequals("speed") then
        self.InitialSpeed = tonumber(val)
    elseif key:iequals("moveto") then
        self.MoveTo = val
    elseif key:iequals("target") then
        self.TargetName = val
    elseif key:iequals("targetattachment") then
        self.TargetAttachment = val
    end
end

function ENT:AcceptInput(name, activator, caller, data)
    DbgPrint(self, name, activator, caller, data)

    return BaseClass.AcceptInput(self, name, activator, caller, data)
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
    self:NextThink(CurTime())
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(SOLID_NONE)
    self:SetRenderMode(RENDERMODE_TRANSTEXTURE)
    self:SetColor(Color(0, 0, 0, 0))
    self.InitialPos = self:GetPos()
    self.InitialAng = self:GetAngles()

    if self.Acceleration == 0 then
        self.Acceleration = 500
    end

    if self.Deceleration == 0 then
        self.Deceleration = 500
    end
end

function ENT:OnRemove()
    if SERVER then
        self:Disable()
    end
end

function ENT:Think()
    if CLIENT then return end -- FIXME: Add client interpolation, requires to network the target entity handle.
    if self:GetNWVar("Disabled", false) == true then return end
    if self:MaintainPlayers() == false then return end

    if self.TargetActive == true then
        self:FollowTarget()
    end

    self:NextThink(CurTime())

    return true
end

function ENT:MaintainPlayers()
    for k, data in pairs(self.ActivePlayers) do
        local ply = data.Player

        -- Remove invalid players.
        if not IsValid(ply) then
            table.remove(self.ActivePlayers, k)
            continue
        end

        if self:HasSpawnFlags(SF_CAMERA_PLAYER_INTERRUPT) == true then
            -- If players press buttons throw them out.
            local curButtons = ply:GetButtons()
            local changed = bit.bxor(curButtons, data.Buttons)

            if changed ~= 0 and curButtons ~= 0 then
                self:RestorePlayer(ply, data)
                table.remove(self.ActivePlayers, k)
            end

            data.Buttons = curButtons
        end
    end

    return true
end

function ENT:FollowTarget()
    local target = self.TargetEntity
    local isTargetValid = IsValid(target)

    -- If the flag is set it has to be disabled explicitly.
    if self:HasSpawnFlags(SF_CAMERA_PLAYER_INFINITE_WAIT) == false then
        if CurTime() > self.ReturnTime then
            DbgPrint(self, "Reached return time, disabling")
            self:Disable()

            return
        elseif isTargetValid == false then
            DbgPrint(self, "Target not valid, disabling")
            self:Disable()
        end
    end

    if isTargetValid == false then
        -- If infinite hold time is set we simply return.
        self.TargetActive = false

        return
    end

    local diffAng = self:GetAngles()

    if self.AttachmentIndex ~= nil and self.AttachmentIndex ~= 0 then
        local attachment = target:GetAttachment(self.AttachmentIndex)

        if attachment ~= nil then
            local diff = attachment.Pos - self:GetPos()
            diffAng = diff:Angle()
        end
    else
        if IsValid(target) then
            local diff = target:GetPos() - self:GetPos()
            diffAng = diff:Angle()
        end
    end

    if self.SnapToTarget == true then
        self:SetAngles(diffAng)
        self.SnapToTarget = false
    else
        local localAng = self:GetLocalAngles()

        if diffAng.y > 360 then
            diffAng.y = diffAng.y - 360
        end

        if diffAng.y < 0 then
            diffAng.y = diffAng.y + 360
        end

        self:SetLocalAngles(localAng)
        localAng = self:GetLocalAngles()
        local dx = diffAng.x - localAng.x
        local dy = diffAng.y - localAng.y

        if dx < -180 then
            dx = dx + 360
        end

        if dx > 180 then
            dx = dx - 360
        end

        if dy < -180 then
            dy = dy + 360
        end

        if dy > 180 then
            dy = dy - 360
        end

        local lookSpeed = 20
        local angVel = Angle()
        angVel.x = dx * (lookSpeed * FrameTime())
        angVel.y = dy * (lookSpeed * FrameTime())
        angVel.z = self:GetLocalAngularVelocity().z
        self:SetLocalAngularVelocity(angVel)
    end

    if self:HasSpawnFlags(SF_CAMERA_PLAYER_TAKECONTROL) == false then
        self:SetAbsVelocity(self:GetAbsVelocity() * 0.8)
        local vel = self:GetAbsVelocity()

        if vel:Length() < 10.0 then
            self:SetAbsVelocity(vec3_origin)
        end
    end

    self:Move()
end

local function GetNextTarget(ent)
    local target = ent:GetInternalVariable("target")
    if target ~= nil then return ents.FindFirstByName(target) end

    return nil
end

function ENT:Move()
    if not IsValid(self.TargetPath) then return end
    local currentPos = self:GetPos()

    --[[ SF_PATHCORNER_TELEPORT ]]
    if self.TargetPath:HasSpawnFlags(2) == true then
        self:SetPos(self.TargetPath:GetPos())
        self.MoveDistance = -1
    else
        self.MoveDistance = self.MoveDistance - currentPos:Distance(self.LastPos)
    end

    if self.MoveDistance <= 0 then
        self.TargetPath:Input("InPass", self, self)
        DbgPrint(self, "Reached pass", self.TargetPath)
        local nextPath = GetNextTarget(self.TargetPath)

        if not IsValid(nextPath) then
            self:SetAbsVelocity(vec3_origin)
            self.TargetPath = nil
        else
            local pathSpeed = (nextPath:GetInternalVariable("speed") or 0)

            if pathSpeed > 0 then
                self.TargetSpeed = pathSpeed
            end

            local targetPathPos = nextPath:GetLocalPos()
            local localPos = self:GetLocalPos()
            self.MoveDir = targetPathPos - localPos
            self.MoveDir:Normalize()
            self.MoveDistance = targetPathPos:Distance(localPos)
            self.StopTime = CurTime() + (nextPath:GetInternalVariable("wait") or 0)
            self.TargetPath = nextPath
        end
    end

    if self.StopTime > CurTime() then
        self.Speed = math.Approach(0, self.Speed, self.Deceleration * FrameTime())
    else
        self.Speed = math.Approach(self.TargetSpeed, self.Speed, self.Acceleration * FrameTime())
    end

    local frac = 2.0 * FrameTime()
    local velocity = ((self.MoveDir * self.Speed) * frac) + (self:GetAbsVelocity() * (1.0 - frac))
    self:SetAbsVelocity(velocity)
    self.LastPos = self:GetPos()
end

function ENT:GetPlayerRestoreData(ply)
    for _, data in pairs(self.ActivePlayers) do
        if data.Player == ply then return data end
    end

    return nil
end

function ENT:AddPlayerToControl(ply)
    DbgPrint(self, "Adding player: " .. tostring(ply))
    local activeWeapon = ply:GetActiveWeapon()
    local viewEntity = ply:GetViewEntity()
    local restoreData = {}
    restoreData.Player = ply
    restoreData.Buttons = ply:GetButtons()

    if IsValid(viewEntity) and viewEntity:GetClass() == "point_viewcontrol" then
        -- Remove the player from the previous one, transition data over.
        DbgPrint(self, "Removing player from previous viewcontrol")
        restoreData = viewEntity:GetPlayerRestoreData(ply)
        viewEntity:RemovePlayerFromControl(ply, true)
    else
        -- Initial entry.
        restoreData.SolidFlags = ply:GetSolidFlags()
        restoreData.ActiveWeapon = activeWeapon
        restoreData.ViewEntity = viewEntity
        restoreData.Frozen = ply:IsFrozen()
        restoreData.NoDraw = ply:GetNoDraw()
    end

    if self:HasSpawnFlags(SF_CAMERA_PLAYER_NOT_SOLID) == true then
        ply:AddSolidFlags(FSOLID_NOT_SOLID)
    end

    if self:HasSpawnFlags(SF_CAMERA_PLAYER_TAKECONTROL) == true then
        DbgPrint("Freezing player: " .. tostring(ply))
        ply:Freeze(true)
    end

    if self:HasSpawnFlags(SF_CAMERA_PLAYER_NODRAW) == true then
        ply:SetNoDraw(true)
    end

    if IsValid(activeWeapon) then
        activeWeapon:AddEffects(EF_NODRAW)
    end

    ply:SetViewEntity(self)
    table.insert(self.ActivePlayers, restoreData)
end

function ENT:RestorePlayer(ply, restoreData)
    if not IsValid(ply) then return end
    DbgPrint(self, "Restoring player " .. tostring(ply))
    ply:SetViewEntity(restoreData.ViewEntity)
    ply:SetSolidFlags(restoreData.SolidFlags)

    if restoreData.Frozen == false and ply:IsFrozen() == true then
        DbgPrint("Restoring freeze player: " .. tostring(ply))
        ply:Freeze(restoreData.Frozen)
    end

    ply:SetNoDraw(restoreData.NoDraw)

    if IsValid(restoreData.ActiveWeapon) then
        restoreData.ActiveWeapon:RemoveEffects(EF_NODRAW)
    end
end

function ENT:RemovePlayerFromControl(ply, switching)
    for k, restoreData in pairs(self.ActivePlayers) do
        if restoreData.Player ~= ply then continue end

        if switching ~= true then
            self:RestorePlayer(ply, restoreData)
        end

        self.ActivePlayers[k] = nil

        if table.Count(self.ActivePlayers) == 0 then
            DbgPrint(self, "All players removed, disabling")
            self:Disable()
        end

        return true
    end

    DbgPrint(self, "Failed to restore player " .. tostring(ply))

    return false
end

function ENT:EnableControl(ply)
    local plys = {}

    if self:HasSpawnFlags(SF_CAMERA_PLAYER_MULTIPLAYER_ALL) == true then
        plys = player.GetAll()
    elseif IsValid(ply) then
        plys = {ply}
    end

    -- What do we do in this case?
    if #plys == 0 then return end
    -- HACHACK: Because point_viewcontrol is not affected by game.CleanUpMap we have to always restore it.
    --self:SetPos(self.InitialPos)
    --self:SetAngles(self.InitialAng)
    self.ReturnTime = CurTime() + self.Wait
    self.Speed = self.InitialSpeed
    self.TargetSpeed = self.InitialSpeed
    local targetEntityName = self.TargetName
    self.TargetEntity = ents.FindFirstByName(targetEntityName)

    if not IsValid(self.TargetEntity) then
        DbgPrint(self, self:GetName(), "Failed to find target entity: \"" .. tostring(targetEntityName) .. "\"")
    else
        self.TargetActive = true
    end

    self.AttachmentIndex = 0
    self.TargetSpeed = 1
    self.Speed = self.InitialSpeed
    -- NOTE: Check out why we have to set snap to target to 1 to get the right effects.
    self.SnapToTarget = self:HasSpawnFlags(SF_CAMERA_PLAYER_SNAP_TO)

    if IsValid(self.TargetEntity) then
        if self.TargetAttachment ~= "" then
            self.AttachmentIndex = self.TargetEntity:LookupAttachment(self.TargetAttachment)
            DbgPrint(self, "Attachment Name", self.TargetAttachment, self.AttachmentIndex)
        end
    end

    local pathName = self.MoveTo

    if pathName ~= "" then
        self.TargetPath = ents.FindFirstByName(pathName)

        if not IsValid(self.TargetPath) then
            DbgPrint(self, "Unable to find path", pathName)
        end
    end

    self.StopTime = CurTime()

    if IsValid(self.TargetPath) then
        local targetPath = self.TargetPath
        local pathSpeed = (targetPath:GetInternalVariable("speed") or 0)

        if pathSpeed > 0 then
            self.TargetSpeed = pathSpeed
        end

        local targetPathPos = targetPath:GetLocalPos()
        local localPos = self:GetLocalPos()
        self.MoveDir = targetPathPos - localPos
        self.MoveDir:Normalize()
        self.MoveDistance = targetPathPos:Distance(localPos)
        self.StopTime = CurTime() + (targetPath:GetInternalVariable("wait") or 0)
    end

    for _, v in pairs(plys) do
        self:AddPlayerToControl(v)
    end

    if self:HasSpawnFlags(SF_CAMERA_PLAYER_POSITION) == true and #self.ActivePlayers == 1 then
        -- Can only do this if a single player is using this.
        local firstPlayer = self.ActivePlayers[1].Player
        self:SetPos(firstPlayer:EyePos())
        self:SetAbsVelocity(firstPlayer:GetAbsVelocity())
        local ang = firstPlayer:GetLocalAngles()
        ang.z = 0
        self:SetLocalAngles(ang)
    else
        self:SetAbsVelocity(vec3_origin)
    end

    self.LastPos = self:GetPos()
    self.MoveDistance = 0
    self:Move()
end

function ENT:DisableControl()
    for k, restoreData in pairs(self.ActivePlayers) do
        self:RestorePlayer(restoreData.Player, restoreData)
    end

    self.ActivePlayers = {}
    self.ReturnTime = CurTime()
    self.TargetActive = false
    self:FireOutputs("OnEndFollow", self, self)
    self:SetAbsVelocity(Vector(0, 0, 0))
end

function ENT:Enable(data, activator, caller)
    DbgPrint(self, "Enable", data, activator, caller)

    -- Avoid doing this.
    if self:GetNWVar("Disabled") == false then
        DbgPrint(self, "Not disabled trying to re-enable?")

        return
    end

    local ply = nil

    -- HACKHACK: d2_coast_03 uses func_door to relay the input.
    if IsValid(activator) then
        ply = self:PropagatePlayerActivator(activator)
    end

    if not IsValid(ply) and IsValid(activator) and activator:IsPlayer() then
        ply = activator
    end

    if not IsValid(ply) and IsValid(caller) and caller:IsPlayer() then
        ply = caller
    end

    -- If we have no valid player at this point and it has not the multiplayer flag
    -- should we just ignore it?
    self:SetNWVar("Disabled", false)
    self:EnableControl(ply)

    return true
end

function ENT:Disable()
    DbgPrint(self, "Disable")
    -- Avoid doing this.
    if self:GetNWVar("Disabled") == true then return end
    self:DisableControl()
    self:SetNWVar("Disabled", true)

    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end