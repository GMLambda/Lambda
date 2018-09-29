local DbgPrint = GetLogging("Transition")

local ENT_TYPE_NPC = 0
local ENT_TYPE_VEHICLE = 1
local ENT_TYPE_DOOR = 2
local ENT_TYPE_GENERIC = 3

local SERIALIZE_VECTOR = function(ent, val) return ent:WorldToLocal(val) end
local SERIALIZE_ANGLES = function(ent, val) return ent:WorldToLocalAngles(val) end

local FIELD_SERIALIZE =
{
    ["Pos"] = SERIALIZE_VECTOR,
    ["Pos1"] = SERIALIZE_VECTOR,
    ["Pos2"] = SERIALIZE_VECTOR,
    ["Vec"] = SERIALIZE_VECTOR,
    ["Ang"] = SERIALIZE_ANGLES,
    ["EyeAng"] = SERIALIZE_ANGLES,
}

local DESERIALIZE_VECTOR = function(ent, val) return ent:LocalToWorld(val) end
local DESERIALIZE_ANGLES = function(ent, val) return ent:LocalToWorldAngles(val) end

local FIELD_DESERIALIZE =
{
    ["Pos"] = DESERIALIZE_VECTOR,
    ["Pos1"] = DESERIALIZE_VECTOR,
    ["Pos2"] = DESERIALIZE_VECTOR,
    ["Vec"] = DESERIALIZE_VECTOR,
    ["Ang"] = DESERIALIZE_ANGLES,
    ["EyeAng"] = DESERIALIZE_ANGLES,
}

local DEFAULT_TRANSITION_DATA = util.TableToJSON({ Objects = {}, Players = {}, GlobalStates = {} })

function GM:InitializeTransitionData()

    -- I know this is not ideal but lets be honest, I have so much more important work left :3

    if self.IsChangeLevel == true then
        local transitionData = util.GetPData("Lambda" .. lambda_instance_id:GetString(), "TransitionData", DEFAULT_TRANSITION_DATA)
        self.TransitionData = util.JSONToTable(transitionData)

    else
        self.TransitionData = util.JSONToTable(DEFAULT_TRANSITION_DATA)
    end

    DbgPrint("TransitionData containts " .. tostring(table.Count(self.TransitionData)) .. " objects")

    --PrintTable(self.TransitionData)
    util.RemovePData("Lambda" .. lambda_instance_id:GetString(), "TransitionData")

end

function GM:TransitionToLevel(map, landmark, playersInTrigger)

    -- 1. Lets collect all entities with the landmark name we have to seperate them by landmark and trigger
    local transitionTriggers = {}
    local landmarkEnt = nil

    if landmark ~= nil and landmark ~= "" then
        for _,v in pairs(ents.FindByName(landmark)) do

            if v:GetClass() == "info_landmark" then
                if landmarkEnt ~= nil then
                    DbgPrint("Something is wrong, we already have found the landmark")
                end
                landmarkEnt = v
                DbgPrint("Found landmark entity: " .. tostring(landmarkEnt))
            elseif v:GetClass() == "trigger_transition" then
                table.insert(transitionTriggers, v)
                DbgPrint("Found transition trigger: " .. tostring(v))
            end

        end
    end

    -- 2. We now create a list of objects to transfer.
    local objectTable = {}
    local playerTable = {}

    if not IsValid(landmarkEnt) then
        DbgPrint("Unable to find landmark! - " .. tostring(landmark))
    else
        self:TransitionNearbyObjects(landmarkEnt, transitionTriggers, objectTable, playerTable, playersInTrigger)

        -- In case players didnt make it, we erase their position from the data.
        for k,v in pairs(playerTable) do

            local ply = Entity(v.RefId)
            if not IsValid(ply) then
                DbgError("Invalid player detected, this should not happen")
            end

            if table.HasValue(playersInTrigger, ply) == false then
                DbgPrint("Removing player: " .. tostring(ply) .. " from transitioning, not in changelevel trigger")
                --playerTable[k] = nil
                playerTable[k].Include = false -- NOTE: Changed this to carry stats and other information.
            end

        end
    end

    DbgPrint("Transitioning #" .. tostring(table.Count(objectTable)) .. " objects")
    --PrintTable(objectTable)

    DbgPrint("Transitioning #" .. tostring(table.Count(playerTable)) .. " players")
    --PrintTable(playerTable)

    local transitionData = {
        Objects = objectTable,
        Players = playerTable,
    }

    hook.Run("SaveTransitionData", transitionData)

    -- We have to mimic the input on transition.
    local transitionMap = {}
    for _,v in pairs(objectTable) do
        transitionMap[Entity(v.RefId)] = true
    end

    for _,v in pairs(ents.GetAll()) do
        local caps = v:ObjectCaps()

        if bit.band(caps, FCAP_NOTIFY_ON_TRANSITION) ~= 0 then
            if transitionMap[v] == true then
                v:Fire("OutsideTransition")
            else
                v:Fire("InsideTransition")
            end
        end
    end

    util.SetPData("Lambda" .. lambda_instance_id:GetString(), "TransitionData", util.TableToJSON(transitionData))

end

function GM:SaveTransitionData(data)

    self:SaveTransitionDifficulty(data)
    --self:SaveGlobalStates(data)

end

local TRANSITION_BLACKLIST =
{
    --["env_sprite"] = true, -- Crashes in combination with TestPVS
    --["trigger_once"] = true,
    --["trigger_multiple"] = true,
    --["info_landmark"] = true,
    ["keyframe_rope"] = true,
    ["info_landmark"] = true,
    ["env_sprite"] = true,
    ["env_lightglow"] = true,
    ["env_soundscape"] = true,
    ["lambda_checkpoint"] = true,
    --["path_track"] = true,
    --["point_camera"] = true,
    ["move_rope"] = true,
    ["trigger_transition"] = true,
    ["game_ragdoll_manager"] = true,
    --["aiscripted_schedule"] = true,
    ["env_fog_controller"] = true,
}

local TRANSITION_ENFORCED_NPC =
{
    ["npc_zombie"] = true,
    ["npc_headcrab"] = true,
    ["npc_fastzombie"] = true,
}

function GM:ShouldTransitionObject(obj, playersInTrigger)

    if obj:IsWorld() then
        return false
    end

    local transition = false
    local caps = obj:ObjectCaps()

    local class = obj:GetClass()
    if TRANSITION_BLACKLIST[class] == true then
        return false
    end

    if bit.band(caps, FCAP_DONT_SAVE) ~= 0 then
        --if g_debug_transitions:GetBool() == true then
            DbgPrint("Ignoring object for transition (FCAP_DONT_SAVE): " .. tostring(obj))
        --end
        if obj:IsVehicle() == false then
            return false
        end
    end

    if bit.band(caps, FCAP_ACROSS_TRANSITION) ~= 0 then
        transition = true
    end

    if bit.band(caps, FCAP_FORCE_TRANSITION) ~= 0 then
        transition = true
        obj.ForceTransition = true
    end

    local globalName = obj:GetNWString("GlobalName", obj:GetInternalVariable("globalname") or "")
    if globalName ~= "" and obj:IsDormant() == false then
        transition = true
        obj.ForceTransition = true
    end

    if obj:IsNPC() and TRANSITION_ENFORCED_NPC[obj:GetClass()] == true then
        transition = true
        obj.ForceTransition = true
    end

    if obj:IsVehicle() and transition == false then

        local driver = obj:GetDriver()

        if IsValid(driver) and driver:IsPlayer() then
            if table.HasValue(playersInTrigger, driver) == true then
                DbgPrint("Enforcing vehicle to transition because player is driving: " .. tostring(obj))
                transition = true
            else
                -- TODO: Create a estimate distance and give it a tolerance of lets say 1024 units?
                DbgPrint("Player is not in changelevel trigger")
                transition = false
            end
        else
            --if obj.CoopPlayer ~= nil then
                --transition = false -- Player is not inside so give him a new one.
            --end
        end

    end

    if transition == false then
        DbgPrint("Object " .. tostring(obj) .. " failed transition pass, caps: " .. tostring(caps))
    end

    local parent = obj:GetParent()
    if IsValid(parent) and (parent:IsPlayer() or parent:IsNPC() or parent:IsWeapon()) then
        transition = false
    end

    local owner = obj:GetOwner()
    if IsValid(owner) and (owner:IsPlayer() or owner:IsNPC()) then
        transition = false
    end

    if obj:IsWeapon() and IsValid(owner) and owner:IsNPC() then
        -- We deal with that specifically.
        transition = false
    end

    -- Overpass owner/parent test, it might be not strictly attached.
    if obj:IsPlayerHolding() then
        transition = true
        obj.ForceTransition = true
    end

    return transition

end

function GM:SerializePlayerData(landmarkEnt, ply, playersInTrigger)

    -- Construct a weapon table that contains also info about the ammo.
    local weapons = {}

    local playerSaveTable = ply:GetSaveTable()
    local prevWeapon = nil
    if playerSaveTable ~= nil and IsValid(playerSaveTable.m_hLastWeapon) then
        prevWeapon = playerSaveTable.m_hLastWeapon
    end

    for _, weapon in pairs(ply:GetWeapons()) do
        local isActive = ply:GetActiveWeapon() == weapon
        local isPrevious = prevWeapon == weapon
        local weaponData =
        {
            Class = weapon:GetClass(),
            Ammo1 =
            {
                Id = weapon:GetPrimaryAmmoType(),
                Count = ply:GetAmmoCount(weapon:GetPrimaryAmmoType()),
            },
            Ammo2 =
            {
                Id = weapon:GetSecondaryAmmoType(),
                Count = ply:GetAmmoCount(weapon:GetSecondaryAmmoType()),
            },
            Clip1 = weapon:Clip1(),
            Clip2 = weapon:Clip2(),
            Active = isActive,
            Previous = isPrevious,
        }
        table.insert(weapons, weaponData)
    end

    local groundEnt = ply:GetGroundEntity()
    local groundId = nil
    local groundPos = nil
    if IsValid(groundEnt) and groundEnt:GetClass() == "func_tracktrain" then
        groundId = groundEnt:EntIndex()
        groundPos = groundEnt:WorldToLocal(ply:GetPos())
    end

    local data =
    {
        RefId = ply:EntIndex(),
        SteamID64 = ply:SteamID64(), -- Important for later.
        SteamID = ply:SteamID(),
        UserID = ply:UserID(), -- For those who wonder, as long you dont disconnect it stays the same: https://developer.valvesoftware.com/wiki/Userid
        Nick = ply:Nick(),
        Pos = ply:GetPos(),
        Ang = ply:GetAngles(),
        EyeAng = ply:EyeAngles(),
        Vel = ply:GetVelocity(),
        Mdl = ply:GetModel(),
        Health = ply:Health(),
        Frags = ply:Frags(),
        Deaths = ply:Deaths(),
        Armor = ply:Armor(),
        Suit = ply:IsSuitEquipped(),
        Weapons = weapons,
        Ground = groundId,
        GroundPos = groundPos,
    }

    if table.HasValue(playersInTrigger, ply) == true and ply:Alive() == true then
        if ply:InVehicle() then
            data.Vehicle = ply:GetVehicle():EntIndex()
        end
        data.Include = true
    else
        data.Include = false
        data.Weapons = {} -- Ditch the table, no need.
    end

    -- Serialize vectors, angles to local ones by landmark.
    for k, v in pairs(data) do

        local serializeFn = FIELD_SERIALIZE[k]
        if serializeFn then
            data[k] = serializeFn(landmarkEnt, v)
        end

    end

    return data

end

local SAVETABLE_BLACKLIST =
{
    ["m_vecCommandGoal"] = true,
    ["basevelocity"] = true,
    ["m_vecLean"] = true,
    ["avelocity"] = true,
    ["velocity"] = true,
    ["m_vecOrigin"] = true,
    ["m_angRotation"] = true,
    ["m_angAbsRotation"] = true,
    ["m_vecAbsOrigin"] = true,
    ["m_vSavePosition"] = true,
    ["m_hMoveEntity"] = true,
    ["model"] = true,
    ["modelindex"] = true,
    ["m_iszModelName"] = true,
    ["effects"] = true,
    ["spawnflags"] = true,
    ["m_MoveType"] = true,
    ["hammerid"] = true,
    ["m_hMovePeer"] = true,
    ["m_hMoveChild"] = true, -- dead locks.
    ["m_hMoveParent"] = true, -- dead locks.
    ["m_pParent"] = true, -- dead locks.
    ["m_MoveCollide"] = true,
    ["globalname"] = true,
    ["additionalequipment"] = true,
    ["m_bConditionsGathered"] = true,
    ["m_flReadinessLockedUntil"] = true,
    ["waterlevel"] = true,
    ["m_CollisionGroup"] = true,
    ["m_nExactWaterLevel"] = true,
    ["m_nWaterType"] = true,
    ["m_rgflCoordinateFrame"] = true, -- Fucks up the airboat.
    ["m_bSequenceFinished"] = true,
    ["classname"] = true,
    ["health"] = true,
    ["sequence"] = true,
    ["m_bClientSideAnimation"] = true,
    ["renderfx"] = true,
    ["rendermode"] = true,
    ["m_iEFlags"] = true,
    ["m_flNextAttack"] = true,
    ["m_SleepFlags"] = true,
    ["m_nWakeTick"] = true,
    ["LightingOriginHack"] = true,
    ["m_NPCState"] = true,
    ["LightingOrigin"] = true,
    ["rendercolor"] = true,
}

function GM:SerializeEntityData(landmarkEnt, ent, playersInTrigger)

    DbgPrint("GM:SerializeEntityData(" .. tostring(landmarkEnt) .. ", " .. tostring(ent) .. ")")

    local currentMap = self:GetCurrentMap()

    local data =
    {
        Class = ent:GetClass(),
        RefId = ent:EntIndex(),
        InitialRefId = ent.InitialRefId or ent:EntIndex(),
        Pos = ent:GetPos(),
        Ang = ent:GetAngles(),
        Vel = ent:GetVelocity(),
        EyeAng = ent:EyeAngles(),
        Mdl = ent:GetModel(),
        Skin = ent:GetSkin(),
        Name = ent:GetName(),
        Mat = ent:GetMaterial(),
        Health = ent:Health(),
        Flags = ent:GetFlags(),
        EFlags = ent:GetEFlags(),
        Effects = ent:GetEffects(),
        SolidFlags = ent:GetSolidFlags(),
        Solid = ent:GetSolid(),
        SpawnFlags = ent:GetSpawnFlags(),
        CollisionGroup = ent:GetCollisionGroup(),
        Sequence = ent:GetSequence(),
        MoveCollide = ent:GetMoveCollide(),
        MoveType = ent:GetMoveType(),
        KeyValues = ent.KeyValueTable or ent:GetKeyValues(),
        SaveTable = ent:GetSaveTable(),
        Table = ent:GetTable(),
        Phys = {},
        SourceMap = ent.SourceMap or currentMap,
        GlobalName = ent:GetNWString("GlobalName", ent:SafeGetInternalVariable("globalname")),
    }

    if ent.LambdaKeyValues ~= nil then
        table.Merge(data.KeyValues, ent.LambdaKeyValues)
    end

    if ent.GetNWVars ~= nil then
        data.NWVars = ent:GetNWVars()
    end

    if ent.GetOutputsTable ~= nil then
        data.Outputs = ent:GetOutputsTable()
    end

    if ent.EntityOutputs ~= nil then
        data.EntityOutputs = table.Copy(ent.EntityOutputs)
    end

    if ent:IsNPC() then
        data.Type = ENT_TYPE_NPC
        data.MovementActivity = ent:GetMovementActivity()
        --data.MovementSequence = ent:GetMovementSequence()
        data.Expression = ent:GetExpression()
        data.Activity = ent:GetActivity()
        data.NPCState = ent:GetNPCState()
        local activeWeapon = ent:GetActiveWeapon()
        if IsValid(activeWeapon) then
            data.ActiveWeapon = activeWeapon:GetClass()
        end
    elseif ent:IsVehicle() then
        data.Type = ENT_TYPE_VEHICLE
        if ent:IsGunEnabled() then
            data.EnableGun = true
        else
            data.EnableGun = false
        end
        data.VehicleScript = ent:GetInternalVariable("VehicleScript")
        if ent:GetNWBool("IsPassengerSeat", false) == true then
            data.IsPassengerSeat = true
        end

    elseif ent:IsDoor() then
        data.Type = ENT_TYPE_DOOR
        if ent:IsDoorOpen() or ent:IsDoorOpening() then
            data.SpawnFlags = bit.bor(data.SpawnFlags, 1) -- Starts Open
        end
        if ent:IsDoorLocked() then
            data.SpawnFlags = bit.bor(data.SpawnFlags, 2048) -- Starts Locked
        end
        data.Pos1 = ent:SafeGetInternalVariable("m_vecPosition1")
        data.Pos2 = ent:SafeGetInternalVariable("m_vecPosition2")
    else
        data.Type = ENT_TYPE_GENERIC
    end

    for i = 0, ent:GetPhysicsObjectCount() - 1 do
        local physObj = ent:GetPhysicsObjectNum(i)
        if IsValid(physObj) then
            local physPos = physObj:GetPos()
            local physAng = physObj:GetAngles()
            physPos = ent:WorldToLocal(physPos)
            physAng = ent:WorldToLocalAngles(physAng)
            data.Phys[i] = { physPos, physAng }
        end
    end

    for k,v in pairs(data.SaveTable) do

        if SAVETABLE_BLACKLIST[k] == true then
            data.SaveTable[k] = nil
            continue
        end

        if IsEntity(v) and IsValid(v) then
            data.SaveTable[k] = "CoopRef_" .. tostring(v:EntIndex())
        else
            data.SaveTable[k] = v
        end

    end

    local parent = ent:GetParent()
    if IsValid(parent) and not parent:IsPlayer() then
        data.Parent = parent:EntIndex()
    end

    local owner = ent:GetOwner()
    if IsValid(owner) and not owner:IsPlayer() then
        data.Owner = parent:EntIndex()
    end

    -- Serialize vectors, angles to local ones by landmark.
    for k, v in pairs(data) do

        local serializeFn = FIELD_SERIALIZE[k]
        if serializeFn then
            data[k] = serializeFn(landmarkEnt, v)
        end

    end

    return data

end

function GM:TransitionObjects(landmarkEnt, objects, objectTable, playerTable, playersInTrigger)

    DbgPrint("GM:TransitionObjects")

    local processed = {}
    local transitionTable = {}
    local debugTransition = false -- FIXME: Make this part of the debug logging.
    local processedPlayers = {}

    for _, touchingEnt in pairs(objects) do

        if not IsValid(touchingEnt) then
            continue
        end

        -- Prevent duplicates
        if processed[touchingEnt] == true then
            continue
        end

        processed[touchingEnt] = true

        if touchingEnt:IsPlayer() and not touchingEnt:IsBot() then

            local ply = touchingEnt

            local data = self:SerializePlayerData(landmarkEnt, ply, playersInTrigger)
            table.insert(playerTable, data)

            processedPlayers[ply] = true

            if debugTransition == true then
                table.insert(transitionTable, ply)
            end

        else

            local ent = touchingEnt

            local data = self:SerializeEntityData(landmarkEnt, ent, playersInTrigger)
            table.insert(objectTable, data)

            if debugTransition == true then
                table.insert(transitionTable, ent)
                ent:AddDebugOverlays(bit.bor(OVERLAY_PIVOT_BIT, OVERLAY_BBOX_BIT, OVERLAY_NAME_BIT))
            end
        end

    end

    -- Matt: Special case, we include them all because of some refactored code that relys on this.
    for _,ply in pairs(player.GetAll()) do
        if processedPlayers[ply] == nil and ply:IsBot() == false then
            local data = self:SerializePlayerData(landmarkEnt, ply, playersInTrigger)
            data.Include = false
            table.insert(playerTable, data)
        end
    end

    if debugTransition == true then
        PrintTable(transitionTable)
    end

end

function GM:InTransitionVolume(volumes, obj)

    local caps = obj:ObjectCaps()

    if bit.band(caps, FCAP_FORCE_TRANSITION) ~= 0 or obj.ForceTransition == true then
        return true
    end

    for _,volume in pairs(volumes) do

        local pos = obj:GetPos()
        local volPos = volume:GetPos()
        local volMins = volPos + volume:OBBMins()
        local volMaxs = volPos + volume:OBBMaxs()

        -- FIXME: This is currently inaccurate, but theres no way to do it properly.
        if pos:WithinAABox(volMins, volMaxs) == false then
            return false
        else
            -- We have no collision test that would apply to the model.
        end

    end

    return true

end

function GM:TransitionNearbyObjects(landmarkEnt, transitionTriggers, objectTable, playerTable, playersInTrigger)

    DbgPrint("GM:TransitionNearbyObjects")

    local objects = {}

    DbgPrint("Collecting players")

    for _,v in pairs(player.GetAll()) do
        if v:Alive() == false then
            continue
        end
        table.insert(objects, v)
        if v:InVehicle() and table.HasValue(playersInTrigger, v) == true then
            table.insert(objects, v:GetVehicle())
        end
    end

    local checkVolumes = table.Count(transitionTriggers) > 0

    --local inPVS = ents.FindInPVS(landmarkEnt) -- Currently crashing, we use landmark:TestPVS instead.
    local allEnts = ents.GetAll()
    for _,v in pairs(allEnts) do

        if self:ShouldTransitionObject(v, playersInTrigger) == false then
            continue
        end

        if v.ForceTransition ~= true then
            DbgPrint("Testing PVS on: " .. tostring(v))
            if landmarkEnt:TestPVS(v) == false then
                continue
            end
        else
            DbgPrint("Enforcing transition: " .. tostring(v))
        end

        if checkVolumes == true and v.ForceTransition ~= true and self:InTransitionVolume(transitionTriggers, v) == false then
            --if g_debug_transitions:GetBool() == true then
                DbgPrint("Object " .. tostring(v) .. " not in transition volumes")
            --end
            continue
        end

        table.insert(objects, v)
    end

    self:TransitionObjects(landmarkEnt, objects, objectTable, playerTable, playersInTrigger)

end

function GM:TransitionObjectsByVolumes(landmarkEnt, transitionTriggers, objectTable, playerTable)

    for _,trigger in pairs(transitionTriggers) do

        if trigger.GetTouching == nil then
            DbgPrint("Flawed trigger, does not have a member called GetTouchingObjects")
            continue
        end

        local objects = trigger:GetTouching()

        -- Ensure we have always all players in the table.
        for _,v in pairs(player.GetAll()) do
            table.insert(objects, v)
            if v:InVehicle() then
                table.insert(objects, v:GetVehicle())
            end
        end

        self:TransitionObjects(landmarkEnt, objects, objectTable, playerTable)

    end

end

function GM:TransitionObjectsByLandmark(landmarkEnt, objectTable, playerTable)

    DbgPrint("GM:TransitionObjectsByLandmark")

    local objects = {}

    for _,v in pairs(player.GetAll()) do
        table.insert(objects, v)
        if v:InVehicle() then
            table.insert(objects, v:GetVehicle())
        end
    end

    local inPVS = ents.FindInPVS(landmarkEnt) -- Thanks again Willox :3
    for _,v in pairs(inPVS) do
        table.insert(objects, v)
    end

    self:TransitionObjects(landmarkEnt, objects, objectTable, playerTable)

end

function GM:FindEntityByTransitionReference(id)

    self.CreatedTransitionObjects = self.CreatedTransitionObjects or {}
    return self.CreatedTransitionObjects[id]

end

function GM:PostLoadTransitionData()

    DbgPrint("GM:PostLoadTransitionData")

    hook.Run("LoadTransitionData", self.TransitionData)

    -- In case there is a entry landmark we are going to resolve the relative positioning,
    -- this avoids us doing it over and over again at places where its used.
    local entryLandmark = self:GetEntryLandmark()
    if entryLandmark == nil then
        return
    end

    local landmarkEnt = nil

    for _,v in pairs(ents.FindByName(entryLandmark)) do
        if v:GetClass() == "info_landmark" then
            if landmarkEnt ~= nil then
                DbgPrint("Something is wrong, we already have found the landmark")
            end
            landmarkEnt = v
            DbgPrint("Found entry landmark entity: " .. tostring(landmarkEnt) .. "( " .. entryLandmark .. ")")
            break
        end
    end

    if IsValid(landmarkEnt) == false then
        if table.Count(self.TransitionData.Players) > 0 or table.Count(self.TransitionData.Objects) > 0 then
            DbgError("No landmark found to resolve transition data")
        end
        return
    end

    DbgPrint("Resolving absolute position on transition players.")

    for objId, obj in pairs(self.TransitionData.Players) do
        for k,v in pairs(obj) do
            local deserializeFn = FIELD_DESERIALIZE[k]
            if deserializeFn then
                self.TransitionData.Players[objId][k] = deserializeFn(landmarkEnt, v)
            end
        end
    end

    DbgPrint("Resolving absolute position on transition Objects.")

    for objId, data in pairs(self.TransitionData.Objects) do
        for k,v in pairs(data) do
            if objId == nil then
                continue
            end
            local deserializeFn = FIELD_DESERIALIZE[k]
            if deserializeFn then
                self.TransitionData.Objects[objId][k] = deserializeFn(landmarkEnt, v)
            end
        end
    end

end

function GM:LoadTransitionData(data)

    self:LoadTransitionDifficulty(data)
    --self:LoadGlobalStates(data)

end

local sv_lan = GetConVar("sv_lan")

function GM:GetPlayerTransitionData(ply)

    if self.TransitionData == nil then
        Error("No transition data table, something is flawed")
    end

    -- Lan support, because duplicates of STEAM_0:0:0
    local key = "SteamID64"
    local val = ply:SteamID64()
    if sv_lan:GetBool() == true then
        key = "UserID"
        val = ply:UserID()
    end

    for _,v in pairs(self.TransitionData.Players) do
        if v[key] == val then
            DbgPrint("Found transition data!")
            return v
        end
    end

    return nil

end

GM.CreatedTransitionObjects = GM.CreatedTransitionObjects or {}

-- Ive noticed strange issues when just applying every KeyValue that is in the table
-- therefor we go by a whitelist.
local DOOR_KEYVALUES =
{
    "opendir",
    "ajarangles",
    "forceclosed",
    "spawnpos",
    "dmg",
    "hardware",
    "speed",
    "health",
    "returndelay",
    "movedir",
}

local VEHICLE_KEYVALUES =
{
}

local KEYVALUE_BLACKLIST =
{
    ["hammerid"] = true,
    ["globalname"] = true,
    ["model"] = true,
    ["modelindex"] = true,
    ["origin"] = true,
    ["spawnflags"] = true,
    ["additionalequipment"] = true,
}

function GM:CreateTransitionObjects()

    self.CreatedTransitionObjects = {}

    self.TransitionData = self.TransitionData or {}

    -- First iteration: We create the things.
    local objects = self.TransitionData.Objects or {}
    local objCount = table.Count(objects)
    local curMap = self:GetCurrentMap()

    for _,data in pairs(objects) do
        if data.GlobalName ~= nil and isstring(data.GlobalName) then
            local e = ents.FindByGlobalName(data.GlobalName)
            if IsValid(e) then
                local oldMdl = data.Mdl
                data.Mdl = e:GetModel() or oldMdl
            else
                local mapData = game.FindEntityByGlobalNameInMapData(data.GlobalName)
                if mapData ~= nil and mapData["model"] ~= nil then
                    local oldMdl = data.Mdl
                    data.Mdl = mapData["model"]
                    DbgPrint("Old Model: " .. oldMdl .. ", new: " .. data.Mdl)
                end
            end
        end
    end

    -- R
    local entryLandmark = self:GetEntryLandmark()
    local landmarkEntities = {}
    if entryLandmark ~= nil then
        DbgPrint("Entry Landmark: " .. entryLandmark)
        for _,v in pairs(ents.FindByName(entryLandmark)) do
            if v:GetClass() ~= "trigger_transition" then
                continue
            end
            DbgPrint("Landmark Entity:", v)
            local touchingObjects = v:GetTouching()
            for _, obj in pairs(touchingObjects) do
                if v:IsWorld() then
                    continue
                end
                if self:ShouldTransitionObject(obj) or obj.ForceTransition == true then
                    landmarkEntities[obj:EntIndex()] = obj
                    DbgPrint("Entry landmark entity", obj, obj:GetName())
                end
            end
        end
    end

    local function findByGlobalName(name)
        for k,v in pairs(ents.GetAll()) do
            local globalName = v:GetNWString("GlobalName", v:SafeGetInternalVariable("globalname"))
            if globalName == name then
                DbgPrint("Found global!")
                return k,v
            end
        end
        return nil, nil
    end

    local function findByName(name)
        for k,v in pairs(landmarkEntities) do
            if v:GetName() == name then
                return k, v
            end
        end
        return nil, nil
    end

    -- Global entities carry the state.
    for _,data in pairs(objects) do
        if data.GlobalName ~= nil and isstring(data.GlobalName) and data.GlobalName ~= "" then
            local k, obj = findByGlobalName(data.GlobalName)
            if k ~= nil then
                DbgPrint("Removing duplicate global entity: " .. tostring(obj))
                obj:Remove()
            end
        end
    end

    -- Remove objects carried forth and back.
    for _,data in pairs(objects) do
        if data.SourceMap ~= curMap then
            continue
        end
        local k
        local obj
        local isGlobal = false
        if data.GlobalName ~= nil and isstring(data.GlobalName) and data.GlobalName ~= "" then
            k, obj = findByGlobalName(data.GlobalName)
            if k ~= nil then
                isGlobal = true
            end
        end
        if k == nil and data.Name ~= nil and data.Name ~= "" then
            k = findByName(data.Name)
        end
        if k ~= nil then
            obj = landmarkEntities[k]
            if isGlobal ~= true then
                DbgPrint("Removing duplicate entity", obj, data.Name or data.GlobalName or "")
                obj:Remove()
            else
                data.GlobalEnt = obj
            end
            landmarkEntities[k] = nil
        else
            -- We don't spawn things that already exist in this world and can't be referenced.
            data.Ignored = true
        end
    end

    DbgPrint("Creating " .. tostring(objCount) .. " transition Objects...")

    local entityTransitionData = {}

    ignoreKeyIndex = -1 -- ignoreKeyIndex + 1

    DbgPrint("IgnoreKeyIndex: " .. ignoreKeyIndex)

    for _,data in pairs(objects) do

        if data.Ignored == true then
            continue
        end

        -- NOTE/FIXME: Observed different results on linux
        if util.IsInWorld(data.Pos) == false then
            DbgPrint("Ignoring creation of " .. data.Class .. ", position out of world: " .. tostring(data.Pos))
            continue
        end

        DbgPrint("Creating: " .. data.Class, data.Name, data.GlobalName)

        local ent
        local dispatchSpawn = true
        if IsValid(data.GlobalEnt) then
            ent = data.GlobalEnt
            dispatchSpawn = false
            DbgPrint("Using global entity!")
        else
            ent = ents.Create(data.Class)
        end

        if not IsValid(ent) then
            DbgPrint("Attempted to create bogus entity: " .. data.Class)
            continue
        end

        ent.SourceMap = data.SourceMap
        ent.ShouldDispatchSpawn = dispatchSpawn

        -- Do key values first because we might override a few things with setters.
        local keyIndex = 0
        for k, v in pairs(data.KeyValues) do
            if KEYVALUE_BLACKLIST[k] == true then
                continue
            end
            v = tostring(v)
            -- Deal with specifics.
            if data.Type == ENT_TYPE_DOOR and table.HasValue(DOOR_KEYVALUES, k) then
                ent:SetKeyValue(k, v)
                GAMEMODE:EntityKeyValue(ent, k, v)
            elseif data.Type == ENT_TYPE_VEHICLE and table.HasValue(VEHICLE_KEYVALUES, k) then
                ent:SetKeyValue(k, v)
                GAMEMODE:EntityKeyValue(ent, k, v)
            else
                if keyIndex == ignoreKeyIndex then
                    DbgPrint("IGNORED KEY: " .. k)
                else
                    ent:SetKeyValue(k, v)
                    GAMEMODE:EntityKeyValue(ent, k, v)
                end
            end
            keyIndex = keyIndex + 1
        end

        for k,v in pairs(data.EntityOutputs or {}) do
            if istable(v) then
                for _,output in pairs(v) do
                    ent:SetKeyValue(k, output)
                    GAMEMODE:EntityKeyValue(ent, k, output)
                end
            else
                ent:SetKeyValue(k, v)
                GAMEMODE:EntityKeyValue(ent, k, v)
            end
        end

        ent:SetPos(data.Pos)
        ent:SetAngles(data.Ang)
        ent:SetVelocity(data.Vel)
        if data.Mdl ~= nil then
            ent:SetModel(data.Mdl)
            DbgPrint(data.Mdl)
        end
        ent:SetName(data.Name)
        ent:SetSkin(data.Skin)
        ent:SetMaterial(data.Mat)
        ent:SetHealth(data.Health)
        ent:AddEFlags(data.EFlags)
        ent:AddEffects(data.Effects)
        ent:SetSolid(data.Solid)
        ent:AddSpawnFlags(data.SpawnFlags)
        ent:SetCollisionGroup(data.CollisionGroup)
        ent:SetMoveCollide(data.MoveCollide)
        ent:SetMoveType(data.MoveType)
        ent:SetSequence(data.Sequence)

        if data.IsPassengerSeat == true then
            ent:SetNWBool("IsPassengerSeat", true)
        end

        if data.Type == ENT_TYPE_NPC then
            ent:SetMovementActivity(data.MovementActivity)
            --ent:SetMovementSequence(data.MovementSequence)
            ent:SetExpression(data.Expression)
            ent:SetNPCState(data.NPCState)
            if data.ActiveWeapon ~= nil then
                ent:SetKeyValue("additionalequipment", data.ActiveWeapon)
                GAMEMODE:EntityKeyValue(ent, "additionalequipment", data.ActiveWeapon)
            end
            if data.KeyValues ~= nil and data.KeyValues["spawnflags"] ~= nil then
                --ent:SetKeyValue("spawnflags", data.KeyValues["spawnflags"])
                --GAMEMODE:EntityKeyValue(ent, "spawnflags", data.KeyValues["spawnflags"])
            end
        elseif data.Type == ENT_TYPE_VEHICLE then
            if data.EnableGun == true then
                ent:SetKeyValue("EnableGun", "1")
            else
                ent:SetKeyValue("EnableGun", "0")
            end
            if data.VehicleScript ~= nil then
                ent:SetKeyValue("VehicleScript", data.VehicleScript)
            end
        end

        if data.Outputs ~= nil then
            ent:SetOutputsTable(table.Copy(data.Outputs)) -- Dont mess with the references on cleanups.
        end

        if ent.SetNWVars ~= nil and data.NWVars ~= nil then
            ent:SetNWVars(data.NWVars)
        end

        if data.Type == ENT_TYPE_DOOR then
            ent:SetSaveValue("m_vecPosition1", data.Pos1)
            ent:SetSaveValue("m_vecPosition2", data.Pos2)
        end

        --ent.TransitionData = data
        entityTransitionData[ent] = data

        self.CreatedTransitionObjects[data.RefId] = ent

        DbgPrint("Created " .. tostring(ent))

    end

    -- Second iteration: We resolve dependencies.
    DbgPrint("Fixing object referencs...")
    for _,ent in pairs(self.CreatedTransitionObjects) do

        local data = entityTransitionData[ent]
        if data == nil then
            continue
        end

        if data.Parent then
            local parent = self.CreatedTransitionObjects[data.Parent]
            if IsValid(parent) then
                ent:SetParent(parent)
                -- FIX: Make sure we assign the seat to the vehicle.
                if ent:GetNWBool("IsPassengerSeat", false) == true then
                    parent:SetNWEntity("PassengerSeat", ent)
                end
            end
        end

        if data.Owner then
            local owner = self.CreatedTransitionObjects[data.Owner]
            if IsValid(owner) then
                ent:SetOwner(owner)
            end
        end

        for k,v in pairs(data.SaveTable) do

            if SAVETABLE_BLACKLIST[k] == true then
                continue
            end

            if isstring(v) and v:sub(1, 8) == "CoopRef_" then
                local refId = tonumber(v:sub(9))
                local refEnt = self.CreatedTransitionObjects[refId]
                if IsValid(refEnt) and refEnt ~= ent and ent:IsNPC() == false then
                    DbgPrint("Resolved reference: " .. k .. " -> " .. tostring(refEnt))
                    ent:SetSaveValue(k, refEnt)
                end
            elseif isvector(v) then
                --local newVec = ent:LocalToWorld(v)
                --ent:SetSaveValue(k, newVec)
            elseif isangle(v) then
                --local newAng = ent:LocalToWorldAngles(v)
                --ent:SetSaveValue(k, newAng)
            elseif istable(v) then 
                ent:SetSaveValue(k, v)
            else
                --ent:SetSaveValue(k,v)
            end
        end

        ent.TransitionData = nil

    end

    -- Third iteration: We spawn and activate.
    DbgPrint("Spawning objects...")
    for _,ent in pairs(self.CreatedTransitionObjects) do
        DbgPrint("Spawning: " .. tostring(ent))
        if ent.ShouldDispatchSpawn ~= true then
            continue
        end
        ent:Spawn()
        if ent:IsNPC() or ent:IsVehicle() then
            ent:Activate()
        end
        local data = entityTransitionData[ent]
        if data == nil then
            continue
        end
        if data.GlobalName ~= nil and data.GlobalName ~= "" then
            ent:SetNWString("GlobalName", data.GlobalName)
            --ent:SetKeyValue("globalname", data.GlobalName)
        end

        -- Correct phys positions.
        for k,v in pairs(data.Phys) do
            local physObj = ent:GetPhysicsObjectNum(k)
            if IsValid(physObj) then
                local physPos = ent:LocalToWorld(v[1])
                local physAng = ent:LocalToWorldAngles(v[2])
                physObj:SetPos(physPos)
                physObj:SetAngles(physAng)
            end
        end
    end

    if ignoreKeyIndex ~= -1 then
        ignoreKeyIndex = ignoreKeyIndex + 1
    end

end
