local DbgPrint = GetLogging("PlayerSpeech")

local SPEECH_GROUPS =
{
    ["teammate_death"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/gordead_ans01.wav",
                "vo/npc/male01/gordead_ans02.wav",
                "vo/npc/male01/gordead_ans03.wav",
                "vo/npc/male01/gordead_ans04.wav",
                "vo/npc/male01/gordead_ans05.wav",
                "vo/npc/male01/gordead_ans06.wav",
                "vo/npc/male01/gordead_ans07.wav",
                "vo/npc/male01/gordead_ans08.wav",
                "vo/npc/male01/gordead_ans09.wav",
                "vo/npc/male01/gordead_ans10.wav",
                "vo/npc/male01/gordead_ans11.wav",
                "vo/npc/male01/gordead_ans12.wav",
                "vo/npc/male01/gordead_ans13.wav",
                "vo/npc/male01/gordead_ans14.wav",
                "vo/npc/male01/gordead_ans15.wav",
                "vo/npc/male01/gordead_ans16.wav",
                "vo/npc/male01/gordead_ans18.wav",
                "vo/npc/male01/gordead_ans19.wav",
                "vo/npc/male01/wetrustedyou01.wav",
                "vo/npc/male01/wetrustedyou02.wav",
            },
            ["female"] = { "vo/npc/female01/gordead_ans01.wav",
                "vo/npc/female01/gordead_ans02.wav",
                "vo/npc/female01/gordead_ans03.wav",
                "vo/npc/female01/gordead_ans04.wav",
                "vo/npc/female01/gordead_ans05.wav",
                "vo/npc/female01/gordead_ans06.wav",
                "vo/npc/female01/gordead_ans07.wav",
                "vo/npc/female01/gordead_ans08.wav",
                "vo/npc/female01/gordead_ans09.wav",
                "vo/npc/female01/gordead_ans10.wav",
                "vo/npc/female01/gordead_ans11.wav",
                "vo/npc/female01/gordead_ans12.wav",
                "vo/npc/female01/gordead_ans13.wav",
                "vo/npc/female01/gordead_ans14.wav",
                "vo/npc/female01/gordead_ans15.wav",
                "vo/npc/female01/gordead_ans16.wav",
                "vo/npc/female01/gordead_ans18.wav",
                "vo/npc/female01/gordead_ans19.wav",
                "vo/npc/female01/wetrustedyou01.wav",
                "vo/npc/female01/wetrustedyou02.wav",
            },
        },
        FallbackTime = 3,
    },
    ["death_imminent"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/uhoh.wav", "vo/npc/male01/whoops01.wav" },
            ["female"] = { "vo/npc/female01/uhoh.wav", "vo/npc/female01/whoops01.wav" },
        },
        FallbackTime = 3,
    },
    ["grenade"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/watchout.wav", "vo/npc/male01/takecover02.wav" },
            ["female"] = { "vo/npc/female01/watchout.wav", "vo/npc/female01/takecover02.wav" },
            ["combine"] = { "npc/metropolice/vo/watchit.wav", "npc/metropolice/vo/grenade.wav", "npc/metropolice/vo/getdown.wav", "npc/metropolice/vo/lookout.wav", "npc/metropolice/vo/shit.wav" },
        },
        FallbackTime = 3,
    },
    ["reload"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/coverwhilereload02.wav", "vo/npc/male01/coverwhilereload01.wav" },
            ["female"] = { "vo/npc/female01/coverwhilereload02.wav", "vo/npc/female01/coverwhilereload01.wav" },
            ["combine"] = { "npc/combine_soldier/vo/coverme.wav"},
        },
        FallbackTime = 3,
    },
    ["encounter_npc_combine_s"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/combine01.wav", "vo/npc/male01/combine02.wav" },
            ["female"] = { "vo/npc/female01/combine01.wav", "vo/npc/female01/combine02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_combine"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/combine01.wav", "vo/npc/male01/combine02.wav" },
            ["female"] = { "vo/npc/female01/combine01.wav", "vo/npc/female01/combine02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_zombie"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/zombies01.wav", "vo/npc/male01/zombies02.wav" },
            ["female"] = { "vo/npc/female01/zombies01.wav", "vo/npc/female01/zombies02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/infected.wav", "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_zombie_fast"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/zombies01.wav", "vo/npc/male01/zombies02.wav" },
            ["female"] = { "vo/npc/female01/zombies01.wav", "vo/npc/female01/zombies02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/infected.wav", "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_manhack"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/herecomehacks01.wav", "vo/npc/male01/herecomehacks02.wav", "vo/npc/male01/hacks01.wav", "vo/npc/male01/hacks02.wav" },
            ["female"] = { "vo/npc/female01/herecomehacks01.wav", "vo/npc/female01/herecomehacks02.wav", "vo/npc/female01/hacks01.wav", "vo/npc/female01/hacks02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_headcrab"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/headcrabs01.wav", "vo/npc/male01/headcrabs02.wav" },
            ["female"] = { "vo/npc/female01/headcrabs01.wav", "vo/npc/female01/headcrabs02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/bugs.wav", "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_headcrab_black"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/headcrabs01.wav", "vo/npc/male01/headcrabs02.wav" },
            ["female"] = { "vo/npc/female01/headcrabs01.wav", "vo/npc/female01/headcrabs02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/bugs.wav", "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_headcrab_fast"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/headcrabs01.wav", "vo/npc/male01/headcrabs02.wav" },
            ["female"] = { "vo/npc/female01/headcrabs01.wav", "vo/npc/female01/headcrabs02.wav" },
            ["combine"] = { "npc/combine_soldier/vo/bugs.wav", "npc/combine_soldier/vo/contact.wav", "npc/combine_soldier/vo/contactconfim.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_strider"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/strider.wav" },
            ["female"] = { "vo/npc/female01/strider.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_cscanner"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/scanners01.wav", "vo/npc/male01/scanners02.wav" },
            ["female"] = { "vo/npc/female01/scanners01.wav", "vo/npc/female01/scanners02.wav" },
        },
        FallbackTime = 3,
    },
    ["encounter_npc_combinegunship"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/gunship02.wav" },
            ["female"] = { "vo/npc/female01/gunship02.wav" },
        },
        FallbackTime = 3,
    },
    ["enemy_kill"] =
    {
        VO =
        {
            ["male"] = { "vo/npc/male01/gotone01.wav", "vo/npc/male01/gotone02.wav" },
            ["female"] = { "vo/npc/female01/gotone01.wav", "vo/npc/female01/gotone02.wav" },
        },
        FallbackTime = 3,
    },
    ["enemy_kill_5"] =
    {
        VO =
        {
            ["male"] = { "vo/coast/odessa/male01/nlo_cheer02.wav" },
            ["female"] = { "vo/coast/odessa/female01/nlo_cheer02.wav", "vo/coast/odessa/female01/nlo_cheer01.wav"  },
        },
        FallbackTime = 3,
    },
    ["enemy_kill_10"] =
    {
        VO =
        {
            ["male"] = { "vo/coast/odessa/male01/nlo_cheer03.wav", "vo/coast/odessa/male01/nlo_cheer04.wav"  },
            ["female"] = { "vo/coast/odessa/female01/nlo_cheer03.wav"  },
            ["combine"] = { "npc/metropolice/vo/chuckle.wav" },
        },
        FallbackTime = 3,
    },
}

local HURT_SOUNDS = {
    ["zombie"] =
    {
        [HITGROUP_GENERIC] = {
            "npc/zombie/zombie_pain1.wav",
            "npc/zombie/zombie_pain2.wav",
            "npc/zombie/zombie_pain3.wav",
            "npc/zombie/zombie_pain4.wav",
            "npc/zombie/zombie_pain5.wav",
        },
    },
    ["combine"] =
    {
        [HITGROUP_GENERIC] = {
            "npc/combine_soldier/pain1.wav",
            "npc/combine_soldier/pain2.wav",
            "npc/combine_soldier/pain3.wav",
        },
    },
    ["monk"] =
    {
        [HITGROUP_GENERIC] = {
            "vo/ravenholm/monk_pain01.wav",
            "vo/ravenholm/monk_pain02.wav",
            "vo/ravenholm/monk_pain03.wav",
            "vo/ravenholm/monk_pain04.wav",
            "vo/ravenholm/monk_pain05.wav",
            "vo/ravenholm/monk_pain06.wav",
            "vo/ravenholm/monk_pain07.wav",
            "vo/ravenholm/monk_pain08.wav",
            "vo/ravenholm/monk_pain09.wav",
            "vo/ravenholm/monk_pain10.wav",
            "vo/ravenholm/monk_pain12.wav",
        },
    },
    ["barney"] =
    {
        [HITGROUP_GENERIC] = {
            "vo/npc/barney/ba_pain01.wav",
            "vo/npc/barney/ba_pain02.wav",
            "vo/npc/barney/ba_pain03.wav",
            "vo/npc/barney/ba_pain04.wav",
            "vo/npc/barney/ba_pain05.wav",
            "vo/npc/barney/ba_pain06.wav",
            "vo/npc/barney/ba_pain07.wav",
            "vo/npc/barney/ba_pain08.wav",
            "vo/npc/barney/ba_pain09.wav",
            "vo/npc/barney/ba_pain10.wav",
        },
    },
    ["alyx"] =
    {
        [HITGROUP_GENERIC] = {
            "vo/npc/alyx/hurt04.wav",
            "vo/npc/alyx/hurt05.wav",
            "vo/npc/alyx/hurt06.wav",
            "vo/npc/alyx/hurt08.wav",
        },
    },
    ["male"] = 
    {
        [HITGROUP_LEFTARM] = {
            "vo/npc/male01/myarm01.wav",
            "vo/npc/male01/myarm02.wav"
        },
        [HITGROUP_RIGHTARM] = {
            "vo/npc/male01/myarm01.wav",
            "vo/npc/male01/myarm02.wav"
        },
        [HITGROUP_LEFTLEG] = {
            "vo/npc/male01/myleg01.wav",
            "vo/npc/male01/myleg02.wav"
        },
        [HITGROUP_RIGHTLEG] = {
            "vo/npc/male01/myleg01.wav",
            "vo/npc/male01/myleg02.wav"
        },
        [HITGROUP_STOMACH] = {
            "vo/npc/male01/hitingut01.wav",
            "vo/npc/male01/hitingut02.wav",
            "vo/npc/male01/mygut02.wav"
        },
        [HITGROUP_GENERIC] = {
            "vo/npc/male01/pain01.wav",
            "vo/npc/male01/pain02.wav",
            "vo/npc/male01/pain03.wav",
            "vo/npc/male01/pain04.wav",
            "vo/npc/male01/pain04.wav",
            "vo/npc/male01/pain05.wav",
            "vo/npc/male01/pain06.wav",
            "vo/npc/male01/pain07.wav",
            "vo/npc/male01/pain08.wav",
            "vo/npc/male01/pain09.wav"
        },
        [HITGROUP_CHEST] = {
            "vo/npc/male01/pain01.wav",
            "vo/npc/male01/pain02.wav",
            "vo/npc/male01/pain03.wav",
            "vo/npc/male01/pain04.wav",
            "vo/npc/male01/pain04.wav",
            "vo/npc/male01/pain05.wav",
            "vo/npc/male01/pain06.wav",
            "vo/npc/male01/pain07.wav",
            "vo/npc/male01/pain08.wav",
            "vo/npc/male01/pain09.wav"
        },
        [HITGROUP_GEAR] = {
            "vo/npc/male01/pain01.wav",
            "vo/npc/male01/pain02.wav",
            "vo/npc/male01/pain03.wav",
            "vo/npc/male01/pain04.wav",
            "vo/npc/male01/pain04.wav",
            "vo/npc/male01/pain05.wav",
            "vo/npc/male01/pain06.wav",
            "vo/npc/male01/pain07.wav",
            "vo/npc/male01/pain08.wav",
            "vo/npc/male01/pain09.wav"
        },

    },
    ["female"] = {
        [HITGROUP_LEFTARM] = {
            "vo/npc/female01/myarm01.wav",
            "vo/npc/female01/myarm02.wav"
        },
        [HITGROUP_RIGHTARM] = {
            "vo/npc/female01/myarm01.wav",
            "vo/npc/female01/myarm02.wav"
        },
        [HITGROUP_LEFTLEG] = {
            "vo/npc/female01/myleg01.wav",
            "vo/npc/female01/myleg02.wav"
        },
        [HITGROUP_RIGHTLEG] = {
            "vo/npc/female01/myleg01.wav",
            "vo/npc/female01/myleg02.wav"
        },
        [HITGROUP_STOMACH] = {
            "vo/npc/female01/hitingut01.wav",
            "vo/npc/female01/hitingut02.wav",
            "vo/npc/female01/mygut02.wav"
        },
        [HITGROUP_GENERIC] = {
            "vo/npc/female01/pain01.wav",
            "vo/npc/female01/pain02.wav",
            "vo/npc/female01/pain03.wav",
            "vo/npc/female01/pain04.wav",
            "vo/npc/female01/pain04.wav",
            "vo/npc/female01/pain05.wav",
            "vo/npc/female01/pain06.wav",
            "vo/npc/female01/pain07.wav",
            "vo/npc/female01/pain08.wav",
            "vo/npc/female01/pain09.wav"
        },
        [HITGROUP_CHEST] = {
            "vo/npc/female01/pain01.wav",
            "vo/npc/female01/pain02.wav",
            "vo/npc/female01/pain03.wav",
            "vo/npc/female01/pain04.wav",
            "vo/npc/female01/pain04.wav",
            "vo/npc/female01/pain05.wav",
            "vo/npc/female01/pain06.wav",
            "vo/npc/female01/pain07.wav",
            "vo/npc/female01/pain08.wav",
            "vo/npc/female01/pain09.wav"
        },
        [HITGROUP_GEAR] = {
            "vo/npc/female01/pain01.wav",
            "vo/npc/female01/pain02.wav",
            "vo/npc/female01/pain03.wav",
            "vo/npc/female01/pain04.wav",
            "vo/npc/female01/pain04.wav",
            "vo/npc/female01/pain05.wav",
            "vo/npc/female01/pain06.wav",
            "vo/npc/female01/pain07.wav",
            "vo/npc/female01/pain08.wav",
            "vo/npc/female01/pain09.wav"
        },
    },
}

local InSpeechUpdate = false
local NextSpeech = nil

local function EmitPlayerSpeech(ply, group, minWait, delay)

    if delay == nil then 
        delay = 0.2
    end

    if InSpeechUpdate == false then
        NextSpeech = { ply, group, minWait, delay }
        return true
    end

    if ply:Alive() == false then
        return false
    end

    local curTime = CurTime()
    if ply.NextSpeechTime > curTime then
        return false -- Busy
    end
    if minWait ~= nil and ply.LastSpeechTime ~= nil and (curTime - ply.LastSpeechTime) < minWait then
        return false -- Busy
    end

    local groupData = SPEECH_GROUPS[group]
    if groupData == nil then
        return false
    end

    local vos = groupData.VO[ply:GetModelCategory()]
    if vos == nil then 
        return false 
    end 
    
    local vo = table.Random(vos)
    local dur = SoundDuration(vo)
    if dur == nil or dur == 0.0 then 
        dur = (groupData.FallbackTime or 5)
    end 

    util.RunDelayed(function()
        if not IsValid(ply) then 
            return 
        end
        ply:EmitSound(vo)
    end, CurTime() + delay)

    ply.NextSpeechTime = curTime + dur + delay
    ply.LastSpeechTime = curTime

    return true

end

function GM:InitializeGlobalSpeechContext()

    self.EnemyClassEncounters = {}

end

function GM:InitializePlayerSpeech(ply)

    ply.LastSpeechUpdate = CurTime()
    ply.NextSpeechTime = CurTime()
    ply.EnemyInSight = false
    ply.EnemyNearby = false
    ply.FriendlyInSight = false
    ply.FriendlyNearby = false
    ply.KillStreakTime = 0
    ply.KillStreak = 0

end

function GM:OnPlayerKilledEnemy(ply, npc)

    if self:GetSetting("player_speech", false) ~= true then
        return
    end

    if ply.KillStreakTime == nil or CurTime() > ply.KillStreakTime then
        ply.KillStreak = 0
    end

    ply.KillStreakTime = CurTime() + 5  -- 1 per second is ok.
    ply.KillStreak = ply.KillStreak + 1

    if ply.FriendlyNearby == false then
        return
    end

    if ply.KillStreak >= 20 then
        ply.KillStreak = 0  -- Reset
    elseif ply.KillStreak == 10 then
        if math.random(0, 2) == 0 then 
            EmitPlayerSpeech(ply, "enemy_kill_10", 5, 0.5)
        end
    elseif ply.KillStreak == 5 then
        if math.random(0, 2) == 0 then 
            EmitPlayerSpeech(ply, "enemy_kill_5", 5, 0.5)
        end
    else
        if math.random(0, 10) == 0 then
            EmitPlayerSpeech(ply, "enemy_kill", 3, 0.5)
        end
    end

end

function GM:HandleNPCContact(viewer, npc, isCriminal)

    if self:GetSetting("player_speech", false) ~= true then
        return
    end

    if viewer.FriendlyInSight == false or isCriminal == false then
        return
    end

    local class = npc:GetClass()
    local curTime = CurTime()

    local encounterData = self.EnemyClassEncounters[class]
    local newEncounter = false

    if encounterData ~= nil then
        if curTime - encounterData.LastSeen > 60 then
            newEncounter = true
        end
    else
        newEncounter = true
    end

    if newEncounter == true and EmitPlayerSpeech(viewer, "encounter_" .. class, 4, 0.2) == true then
        self.EnemyClassEncounters[class] = { LastSeen = curTime }
    elseif newEncounter == false then
        encounterData.LastSeen = curTime
    end

end

function GM:HandlePlayerContact(viewer, ply, isCriminal)

    if self:GetSetting("player_speech", false) ~= true then
        return
    end

    local alive = ply:Alive()
    local acknowledgeDeath = false

    if alive == false and ply.DeathAcknowledged ~= true then
        ply.DeathAcknowledged = true
        acknowledgeDeath = true
    end

    if viewer.FriendlyInSight == false then
        return
    end

    if acknowledgeDeath == true and self:IsPlayerEnemy(viewer, ply) ~= true then
        EmitPlayerSpeech(viewer, "teammate_death", 5, 1)
    end

end

function GM:HandleWeaponContact(viewer, wep, isCriminal)
end

function GM:HandleGrenadeContact(viewer, nate)

    if self:GetSetting("player_speech", false) ~= true then
        return
    end 

    if nate.Acknowledged == true then
        return
    end

    if viewer.FriendlyNearby == false then
        return
    end

    local pos = viewer:GetPos()
    local natePos = nate:GetPos()
    if natePos:Distance(pos) < 400 then
        return
    end

    -- TODO: Approximate the direction.

    if (nate.ExplosionAcknolwedged ~= true and
       nate:GetPos():Distance(pos) <= 150 and
       viewer:Health() <= 60 and
       nate:GetInternalVariable("m_flDetonateTime") <= 0.6)
    then
        if EmitPlayerSpeech(viewer, "death_imminent", 5, 0.2) == true then
            nate.ExplosionAcknolwedged = true
            return
        end
    end

    if EmitPlayerSpeech(viewer, "grenade", 5, 0.2) == true then
        nate.Acknowledged = true
    end

end

function GM:OnPlayerReload(ply, event, data)

    if self:GetSetting("player_speech", false) ~= true then
        return
    end 

    if ply.FriendlyNearby == false then
        return
    end

    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        EmitPlayerSpeech(ply, "reload")
    end 

end

local ENTITY_CLASS_HANDLER =
{
    ["npc_grenade_frag"] = GM.HandleGrenadeContact,
}

function GM:UpdatePlayerSpeech(ply)

    if self:GetSetting("player_speech", false) ~= true then
        return
    end 

    if ply:Alive() == false then
        return
    end

    local curTime = CurTime()
    if curTime - ply.LastSpeechUpdate < 0.5 then
        return
    end
    ply.LastSpeechUpdate = curTime

    local pos = ply:GetPos()

    ply.FriendlyInSight = false
    ply.FriendlyNearby = false
    ply.EnemyInSight = false
    ply.EnemyNearby = false

    local nearbyEnts = ents.FindInBox(pos - Vector(500, 500, 0), pos + Vector(500, 500, 250))
    local actions = {}

    local isCriminal = game.GetGlobalState("gordon_precriminal") ~= GLOBAL_ON
    for k,v in pairs(nearbyEnts) do

        if v == ply then
            continue
        end

        local executeHandler = false
        local isVisible = ply:InsideViewCone(v)
        local class = v:GetClass()

        if isVisible == true then
            isVisible = ply:Visible(v)
        end

        if isVisible == true then
            if v:IsNPC() then
                if IsFriendEntityName(class) == false and isCriminal == true then
                    ply.EnemyInSight = isVisible
                    ply.EnemyNearby = true
                end
            elseif v:IsPlayer() == true and v:Alive() == true and self:IsPlayerEnemy(ply, v) == false then
                ply.FriendlyInSight = isVisible
                ply.FriendlyNearby = true
            end

            executeHandler = true
        else
            if v:IsPlayer() and v:Alive() == true and self:IsPlayerEnemy(ply, v) ~= true then
                local otherPos = v:GetPos()
                local dist = otherPos:Distance(pos)
                if dist <= 50 then
                    ply.FriendlyInSight = false -- Back to back
                    ply.FriendlyNearby = true
                    executeHandler = true
                end
            end
        end

        if executeHandler == true then
            local handler = ENTITY_CLASS_HANDLER[class]
            if handler ~= nil then
                table.insert(actions, function() handler(self, ply, v) end)
            else
                if v:IsNPC() then
                    table.insert(actions, function() self:HandleNPCContact(ply, v, isCriminal) end)
                elseif v:IsPlayer() then
                    table.insert(actions, function() self:HandlePlayerContact(ply, v, isCriminal) end)
                elseif v:IsWeapon() then
                    table.insert(actions, function() self:HandleWeaponContact(ply, v, isCriminal) end)
                end
            end
        end
    end

    for _,v in pairs(actions) do
        v()
    end

    InSpeechUpdate = true

    if NextSpeech ~= nil and IsValid(NextSpeech[1]) then
        EmitPlayerSpeech(NextSpeech[1], NextSpeech[2], NextSpeech[3], NextSpeech[4])
        NextSpeech = nil
    end

    InSpeechUpdate = false

end

function GM:EmitPlayerHurt(amount, ply, hitgroup)

    if self:GetSetting("player_damage_speech", false) ~= true then
        return
    end

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

    local mdlCategory = ply:GetModelCategory()
    local group = HURT_SOUNDS[mdlCategory]
    if group == nil then
        return
    end

    local hurtsounds = group[hitgroup]
    if hurtsounds == nil then
        hurtsounds = group[HITGROUP_GENERIC]
    end
    if hurtsounds == nil then
        DbgPrint("Missing hurt sounds for HITGROUP_GENERIC in group " .. mdlCategory)
        return
    end

    ply.NextHurtSound = ply.NextHurtSound or 0

    local curTime = CurTime()
    if curTime - ply.NextHurtSound >= 2 then
        local snd = table.Random(hurtsounds)
        ply:EmitSound(snd)
        ply.NextHurtSound = curTime + 2
    end

end