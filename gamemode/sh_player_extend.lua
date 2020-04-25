AddCSLuaFile()

local DbgPrint = GetLogging("PlayerExt")
local PLAYER_META = FindMetaTable("Player")

-- Ensure autoreload will not screw this up.
_PLAYER_META_GIVE = _PLAYER_META_GIVE or PLAYER_META.Give

VIEWLOCK_NONE = 0
VIEWLOCK_ANGLE = 1
VIEWLOCK_NPC = 2
VIEWLOCK_PLAYER = 3
VIEWLOCK_SETTINGS_ON = 4
VIEWLOCK_SETTINGS_RELEASE = 5

VIEWLOCK_RELEASE_TIME = 1.0 -- Seconds

if SERVER then

    function PLAYER_META:TeleportPlayer(pos, ang, vel)
        local data = {}
        data.vel = vel or self:GetVelocity()
        data.ang = ang or self:GetAngles()
        data.pos = pos or Vector(0, 0, 0)
        self.TeleportQueue = self.TeleportQueue or {}
        table.insert(self.TeleportQueue, data)
        -- Make sure players won't get stuck in each other.
        self:DisablePlayerCollide(true)
    end

    function PLAYER_META:DisablePlayerCollide(state, temporarily)
        if state == true then
            self.NextPlayerCollideTest = CurTime() + 2
        end
        if temporarily == nil then
            temporarily = true
        end
        self:SetNWBool("DisablePlayerCollide", state)
        self.DisablePlayerCollisionTemporarily = temporarily
        self:CollisionRulesChanged()
        DbgPrint(self, "DisablePlayerCollide", tostring(state))
    end

    function PLAYER_META:GetFOVOwner()
        return self:GetInternalVariable("m_hZoomOwner")
    end

    function PLAYER_META:SetFOVOwner(ent)
        self:SetSaveValue("m_hZoomOwner", ent)
    end

    function PLAYER_META:ClearZoomOwner()
        self:SetFOVOwner(NULL)
    end
        
    function PLAYER_META:LockPosition(poslock, viewlock, viewdata)

        if not self:Alive() then
            return
        end

        poslock = poslock or false
        viewlock = viewlock or VIEWLOCK_NONE

        self.PositionLocked = self.PositionLocked or false
        self.ViewLocked = self.ViewLocked or false

        if poslock == true then
            DbgPrint("Locking player position: " .. tostring(self))
        else
            DbgPrint("Unlocking player position: " .. tostring(self))
            viewlock = VIEWLOCK_NONE
        end

        local prevPositionLock = self.PositionLocked
        local prevViewLocked = self.ViewLocked

        self.PositionLocked = poslock
        self.ViewLock = viewlock
        self.LockedViewAngles = viewdata
        self:SetNoTarget(poslock)
        self:SetNWBool("PositionLocked", poslock)
        self:SetNWInt("ViewLock", viewlock)
        self:SetNWFloat("ViewLockTime", CurTime())
        self:DisablePlayerCollide(poslock)

        if viewlock == VIEWLOCK_ANGLE then
            self:SetNWAngle("LockedViewAngles", viewdata)
        elseif viewlock == VIEWLOCK_NPC then
            self:SetNWEntity("LockedViewEntity", viewdata)
        elseif viewlock == VIEWLOCK_SETTINGS_RELEASE then
            -- Dealt within sh_lambda_player:PlayerThink
        end

        if self.PositionLocked ~= prevPositionLock or self.ViewLock ~= prevViewLocked then
            hook.Call("Lambda_PlayerLockChanged", GAMEMODE, poslock, viewlock, viewdata)
        end

    end

    function PLAYER_META:Give(class, noAmmo)
        if self:Alive() == false then
            return nil
        end

        local e = ents.Create(class)
        if not IsValid(e) then
            return nil
        end

        -- Slightly offset the pos, in some cases using EyePos() doesn't work if players stand in each other.
        e:SetPos(self:EyePos() + Vector(0, 0, 20))

        local SF_NORESPAWN = 0x40000000
        e:AddSpawnFlags(SF_NORESPAWN)
        e.CreatedForPlayer = self
        e:Spawn()

        local resetAmmo = false
        local primaryAmmo = -1
        local secondaryAmmo = -1
        local primaryType = -1
        local secondaryType = -1
        if noAmmo == true and e:IsWeapon() == true then
            e:SetClip1(0)
            e:SetClip2(0)
            primaryType = e:GetPrimaryAmmoType()
            if primaryType ~= -1 then
                primaryAmmo = self:GetAmmoCount(primaryType)
            end
            secondaryType = e:GetSecondaryAmmoType()
            if secondaryType ~= -1 then
                secondaryAmmo = self:GetAmmoCount(secondaryType)
            end
            resetAmmo = true
        end

        -- Forces a touch.
        e:Use(self, self, USE_ON, 1)

        if noAmmo == true and resetAmmo == true then
            if primaryType ~= -1 then
                self:SetAmmo(primaryAmmo, primaryType)
            end
            if secondaryType ~= -1 then
                self:SetAmmo(secondaryAmmo, secondaryType)
            end
        end

        if self:HasWeapon(e:GetClass()) == false then
            -- FALLBACK: In some rare cases this isnt working, use the original give.
            e:Remove()

            self.InsideGive = true
            e = _PLAYER_META_GIVE(self, class, noAmmo)
            e.CreatedForPlayer = self
            self.InsideGive = nil

            if self:HasWeapon(class) == false then
                error("Unable to give weapon " .. tostring(e) .. " (Owner: " .. tostring(e:GetOwner()) .. ") to player " .. tostring(self))
            end
        end

        return e
    end

    function PLAYER_META:SetSpawningBlocked(blocked)
        self:SetNWBool("LambdaSpawnBlocked", blocked)
    end

    function PLAYER_META:SetRagdollManager(rag)
        self:SetNWEntity("LambdaRagdollManager", rag)
    end

    function PLAYER_META:Revive(pos, ang, health)
        GAMEMODE:RevivePlayer(self, pos, ang, health)
    end

    function PLAYER_META:SetScreenOverlayOwner(ent)
        self:SetNWEntity("scrOverlay", ent)
    end

    function PLAYER_META:GetScreenOverlayOwner()
        return self:GetNWEntity("scrOverlay")
    end

    function PLAYER_META:CleanScreenOverlayOwner()
        self:SetScreenOverlayOwner(NULL)
    end

end -- SERVER

function PLAYER_META:GetRagdollManager()
    return self:GetNWEntity("LambdaRagdollManager")
end

function PLAYER_META:IsSpawningBlocked()
    return self:GetNWBool("LambdaSpawnBlocked", false)
end

function PLAYER_META:IsPositionLocked()

    if SERVER then
        self.PositionLocked = self.PositionLocked or false
        return self.PositionLocked
    end

    return self:GetNWBool("PositionLocked", false)

end

function PLAYER_META:GetViewLockTime()
    return self:GetNWFloat("ViewLockTime", CurTime())
end

function PLAYER_META:GetViewLock()

    if SERVER then
        self.ViewLock = self.ViewLock or VIEWLOCK_NONE
        return self.ViewLock
    end

    return self:GetNWInt("ViewLock", VIEWLOCK_NONE)

end

function PLAYER_META:GetNearestRadiationRange()
    return self:GetNWInt("LambdaRadiationRange", 1000)
end

function PLAYER_META:SetNearestRadiationRange(range, override)

    local current = self:GetNearestRadiationRange()

    if override == true then
        current = range
    else
        if current >= range then
            current = range
        end
    end

    self:SetNWInt("LambdaRadiationRange", current)

end

function PLAYER_META:SetGeigerRange(range)
    self:SetNWInt("LambdaGeigerRange", range)
end

function PLAYER_META:GetGeigerRange()
    return self:GetNWInt("LambdaGeigerRange", 1000)
end

function PLAYER_META:AddSuitDevice(device)
    self.SuitDevices = self.SuitDevices or {}
    self.SuitDevices[device] = true
end

function PLAYER_META:RemoveSuitDevice(device)
    self.SuitDevices = self.SuitDevices or {}
    self.SuitDevices[device] = false
end

function PLAYER_META:GetSuitDevices()
    self.SuitDevices = self.SuitDevices or {}
    return table.Copy(self.SuitDevices)
end

function PLAYER_META:UsingSuitDevice(device)
    self.SuitDevices = self.SuitDevices or {}
    return self.SuitDevices[device] or false
end

function PLAYER_META:GetFlexIndexByName(name)

    self.LastModelName = self.LastModelName or ""
    self.FlexIndexCache = self.FlexIndexCache or {}
    local mdl = self:GetModel()

    if mdl ~= self.LastModelName then
        self.LastModelName = mdl
        self.FlexIndexCache = {}
        local count = self:GetFlexNum() - 1
        if count <= 0 then return end

        for i = 0, count do
            local flexName = self:GetFlexName(i)
            self.FlexIndexCache[flexName] = i
        end
    end

    return self.FlexIndexCache[name]

end

function PLAYER_META:GetSpawnTime()
    return self.LambdaSpawnTime or CurTime()
end

function PLAYER_META:GetLifeTime()
    return CurTime() - self:GetSpawnTime()
end

function PLAYER_META:IsInactive()
    return self:GetNWBool("Inactive", true)
end

function PLAYER_META:SetInactive(state)
    self:SetNWBool("Inactive", state)
    if state == true then
        self:AddFlags(FL_NOTARGET)
    else
        self:RemoveFlags(FL_NOTARGET)
    end
end

function PLAYER_META:SetLambdaSuitPower(val)
    self:SetNW2Float("LambdaSuitPower", val)
end

function PLAYER_META:GetLambdaSuitPower()
    return self:GetNW2Float("LambdaSuitPower", 0.0)
end

function PLAYER_META:SetLambdaSprinting(val)
    self:SetNW2Bool("LambdaSprinting", val)
end

function PLAYER_META:GetLambdaSprinting()
    return self:GetNW2Bool("LambdaSprinting", false)
end

function PLAYER_META:SetLambdaStateSprinting(val)
    self:SetNW2Bool("LambdaStateSprinting", val)
end

function PLAYER_META:GetLambdaStateSprinting()
    return self:GetNW2Bool("LambdaStateSprinting", false)
end

function PLAYER_META:IsSprinting()
    return self:GetLambdaSprinting()
end

-- Override the non-functional one.
function PLAYER_META:StopSprinting()
    self:SetLambdaSprinting(false)
end

function PLAYER_META:BodyDirection2D()
    local ang = self:EyeAngles()
    local vec = ang:Forward()
    vec.z = 0

    local len2d = vec:Length2D()
    if len2d ~= 0.0 then
        vec.x = vec.x / len2d
        vec.y = vec.y / len2d
    else
        vec.x = 0
        vec.y = 0
    end
    return vec
end

function PLAYER_META:InsideViewCone(other, tolerance)

    if tolerance == nil then
        tolerance = self:GetInternalVariable("m_flFieldOfView")
    end

    local otherPos
    if IsEntity(other) then
        if other:IsPlayer() then
            otherPos = other:EyePos()
        else
            otherPos = other:GetPos()
        end
    elseif isvector(other) then
        otherPos = other
    else
        error("Invalid argument passed")
    end

    local los = otherPos - self:EyePos()
    los.z = 0
    los:Normalize()

    local facingDir = self:BodyDirection2D()
    local dot = los:Dot(facingDir)

    return dot > tolerance

end

function PLAYER_META:GetButtons()
    if self.LastUserCmdButtons ~= nil then
        return self.LastUserCmdButtons
    end
    return 0
end

function PLAYER_META:GetIsJumping()
    return self:GetNW2Bool("LambdaIsJumping", false)
end

function PLAYER_META:SetIsJumping(val)
    self:SetNW2Bool("LambdaIsJumping", val)
end