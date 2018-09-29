AddCSLuaFile()

local DbgPrint = GetLogging("PlayerExt")
local PLAYER_META = FindMetaTable("Player")

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

    function PLAYER_META:LockPosition(poslock, viewlock, viewdata)

        if not self:Alive() then return end
        
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

        e:SetLocalPos(self:GetLocalPos())

        local SF_NORESPAWN = 0x40000000
        e:AddSpawnFlags(SF_NORESPAWN)

        e:Spawn()
        e.CreatedForPlayer = self

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

        return e
    end

end -- SERVER

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

function PLAYER_META:GetGender()
    return self:GetNWString("Gender", "male")
end

function PLAYER_META:SetGender(gender)
    if gender:iequals("male") == false and
       gender:iequals("female") == false and
         gender:iequals("zombie") == false and 
         gender:iequals("combine") == false
    then
        gender = "male"
    end
    self:SetNWString("Gender", gender)
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
end

function PLAYER_META:SetSuitPower(val)
    self:SetNW2Float("SuitPower", val)
end
function PLAYER_META:GetSuitPower()
    return self:GetNW2Float("SuitPower", 0.0)
end

function PLAYER_META:SetSuitEnergy(val)
    self:SetNW2Float("SuitEnergy", val)
end
function PLAYER_META:GetSuitEnergy()
    return self:GetNW2Float("SuitEnergy", 0.0)
end

function PLAYER_META:SetSprinting(val)
    self:SetNW2Bool("Sprinting", val)
end
function PLAYER_META:GetSprinting()
    return self:GetNW2Bool("Sprinting", false)
end

function PLAYER_META:SetStateSprinting(val)
    self:SetNW2Bool("StateSprinting", val)
end

function PLAYER_META:GetStateSprinting()
    return self:GetNW2Bool("StateSprinting", false)
end

function PLAYER_META:IsSprinting()
    return self:GetSprinting()
end

-- Override the non-functional one.
function PLAYER_META:StopSprinting()
    self:SetSprinting(false)
end

function PLAYER_META:InsideViewCone(other, tolerance)

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

    local dir = (otherPos - self:EyePos()):GetNormal()
    local dot = dir:Dot(self:GetAimVector())
    return dot >= (tolerance or 0.6)

end 