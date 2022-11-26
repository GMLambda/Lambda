AddCSLuaFile()

local Taunts = {}
local Categories = {}

local function InsertCategory(category)
    local id = #Categories + 1
    Categories[id] = { Id = id, Name = category }
    return id
end

local function GetCategoryIndex(category)
    for k,v in pairs(Categories) do
        if v.Name == category then
            return v.Id
        end
    end
    return nil
end

local function InsertTaunt(categoryId, mdlCategory, name, files)
    if Categories[categoryId] == nil then
        error("Invalid category id.")
        return
    end
    Taunts[categoryId] = Taunts[categoryId] or {}
    Taunts[categoryId][mdlCategory] = Taunts[categoryId][mdlCategory] or {}
    local data = {
        Name = name,
        Sounds = files,
    }
    table.insert(Taunts[categoryId][mdlCategory], data)
end

local CAT_TAUNTS = InsertCategory("Taunts")
local ZOMBIE_MOANS = {
    "npc/zombie/zombie_voice_idle1.wav",
    "npc/zombie/zombie_voice_idle2.wav",
    "npc/zombie/zombie_voice_idle3.wav",
    "npc/zombie/zombie_voice_idle4.wav",
    "npc/zombie/zombie_voice_idle5.wav",
    "npc/zombie/zombie_voice_idle6.wav",
    "npc/zombie/zombie_voice_idle7.wav",
    "npc/zombie/zombie_voice_idle8.wav",
    "npc/zombie/zombie_voice_idle9.wav",
    "npc/zombie/zombie_voice_idle10.wav",
    "npc/zombie/zombie_voice_idle11.wav",
    "npc/zombie/zombie_voice_idle12.wav",
    "npc/zombie/zombie_voice_idle13.wav",
    "npc/zombie/zombie_voice_idle14.wav",
}

InsertTaunt(CAT_TAUNTS, "zombie", "Over there", {"npc/zombie/zombie_alert1.wav"})
InsertTaunt(CAT_TAUNTS, "zombie", "Over here", {"npc/zombie/zombie_alert2.wav"})
InsertTaunt(CAT_TAUNTS, "zombie", "Take cover", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "I'm Ready", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Hi", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Yeah", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Okay", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "No", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Nice", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Help", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Sorry", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Leave it alone", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "I'm with you", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Ready when you are", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Whatever you say", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Let's go", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Excuse me", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Get down", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Heads up", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Fantastic", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Finally", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Good God", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Run for your life", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Run", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Behind you", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "You got it", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Whoops", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Watch out", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Waiting for somebody?", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Like that", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "We trusted you", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "How about that", ZOMBIE_MOANS)
InsertTaunt(CAT_TAUNTS, "zombie", "Wanna bet", ZOMBIE_MOANS)

InsertTaunt(CAT_TAUNTS, "combine", "Over there", { "npc/metropolice/vo/move.wav", "npc/metropolice/vo/moveit.wav", "npc/metropolice/vo/moveit2.wav", "npc/metropolice/vo/examine.wav" })
InsertTaunt(CAT_TAUNTS, "combine", "Over here", { "npc/metropolice/vo/holdthisposition.wav", "npc/metropolice/vo/holditrightthere.wav" })
InsertTaunt(CAT_TAUNTS, "combine", "Take cover", {"npc/metropolice/vo/takecover.wav"})
InsertTaunt(CAT_TAUNTS, "combine", "I'm Ready", {"npc/metropolice/vo/readytojudge.wav", "npc/metropolice/vo/readytoprosecute.wav", "npc/metropolice/vo/readytoamputate.wav"})
InsertTaunt(CAT_TAUNTS, "combine", "Affirmative", {"npc/combine_soldier/vo/affirmative.wav", "npc/combine_soldier/vo/affirmative2.wav"})
InsertTaunt(CAT_TAUNTS, "combine", "Nice", {"npc/metropolice/vo/chuckle.wav"})
InsertTaunt(CAT_TAUNTS, "combine", "Help", {"npc/metropolice/vo/help.wav"})

InsertTaunt(CAT_TAUNTS, "alyx", "Over there", {"vo/k_lab/al_there.wav", "vo/novaprospekt/al_there.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Over here", {"vo/trainyard/al_overhere.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Take cover", {"vo/npc/female01/takecover02.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Follow me", {"vo/novaprospekt/al_followme01.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Let's get going", {"vo/novaprospekt/al_letsgetgoing.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Cover me", {"vo/npc/alyx/coverme01.wav", "vo/npc/alyx/coverme02.wav", "vo/npc/alyx/coverme03.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Let's go", {"vo/streetwar/alyx_gate/al_letsgo.wav", "vo/streetwar/alyx_gate/al_letsgo01.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Excuse me", {"vo/npc/alyx/al_excuse03.wav"})
InsertTaunt(CAT_TAUNTS, "alyx", "Watch out", {"vo/npc/alyx/watchout01.wav", "vo/npc/alyx/watchout02.wav"})

InsertTaunt(CAT_TAUNTS, "monk", "Over there", {"vo/ravenholm/exit_goquickly.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Over here", {"vo/ravenholm/shotgun_overhere.wav", "vo/ravenholm/monk_overhere.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Take cover", {"vo/ravenholm/bucket_guardwell.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Follow me", {"vo/ravenholm/monk_followme.wav", "vo/ravenholm/grave_stayclose.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Cover me", {"vo/ravenholm/monk_coverme01.wav", "vo/ravenholm/monk_coverme02.wav", "vo/ravenholm/monk_coverme03.wav", "vo/ravenholm/monk_coverme04.wav", "vo/ravenholm/monk_coverme05.wav", "vo/ravenholm/monk_coverme07.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Let's go", {"vo/ravenholm/exit_goquickly.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Watch out", {"vo/ravenholm/monk_danger03.wav", "vo/ravenholm/monk_danger02.wav", "vo/ravenholm/monk_danger01.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Behind you", {"vo/ravenholm/firetrap_lookout.wav"})
InsertTaunt(CAT_TAUNTS, "monk", "Help", {"vo/ravenholm/monk_helpme01.wav", "vo/ravenholm/monk_helpme02.wav", "vo/ravenholm/monk_helpme04.wav", "vo/ravenholm/monk_helpme05.wav"})

InsertTaunt(CAT_TAUNTS, "barney", "Over there", {"vo/streetwar/sniper/ba_letsgetgoing.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Over here", {"vo/streetwar/sniper/ba_overhere.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Take cover", {"vo/ravenholm/bucket_guardwell.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Follow me", {"vo/npc/barney/ba_followme02.wav", "vo/npc/barney/ba_followme05.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Let's go", {"vo/npc/barney/ba_letsgo.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Watch out", {"vo/npc/barney/ba_lookout.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Help", {"vo/streetwar/rubble/ba_helpmeout.wav"})
InsertTaunt(CAT_TAUNTS, "barney", "Done", {"vo/streetwar/nexus/ba_done.wav"})

InsertTaunt(CAT_TAUNTS, "male", "Over there", {"vo/npc/male01/overthere01.wav", "vo/npc/male01/overthere02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Over here", {"vo/npc/male01/overhere01.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Take cover", {"vo/npc/male01/takecover02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "I'm Ready", {"vo/npc/male01/okimready01.wav", "vo/npc/male01/okimready02.wav", "vo/npc/male01/okimready03.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Hi", {"vo/npc/male01/hi01.wav", "vo/npc/male01/hi02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Yeah", {"vo/npc/male01/yeah02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Okay", {"vo/npc/male01/ok01.wav", "vo/npc/male01/ok02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "No", {"vo/npc/male01/no01.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Nice", {"vo/npc/male01/nice.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Help", {"vo/npc/male01/help01.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Sorry", {"vo/npc/male01/sorry01.wav", "vo/npc/male01/sorry02.wav", "vo/npc/male01/sorry03.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Leave it alone", {"vo/npc/male01/answer38.wav"})
InsertTaunt(CAT_TAUNTS, "male", "I'm with you", {"vo/npc/male01/answer13.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Ready when you are", {"vo/npc/male01/readywhenyouare01.wav", "vo/npc/male01/readywhenyouare02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Whatever you say", {"vo/npc/male01/squad_affirm03.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Let's go", {"vo/npc/male01/letsgo01.wav", "vo/npc/male01/letsgo02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Excuse me", {"vo/npc/male01/excuseme01.wav", "vo/npc/male01/excuseme02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Get down", {"vo/npc/male01/getdown02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Heads up", {"vo/npc/male01/headsup01.wav", "vo/npc/male01/headsup02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Fantastic", {"vo/npc/male01/fantastic01.wav", "vo/npc/male01/fantastic02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Finally", {"vo/npc/male01/finally.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Good God", {"vo/npc/male01/goodgod.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Run for your life", {"vo/npc/male01/runforyourlife01.wav", "vo/npc/male01/runforyourlife02.wav", "vo/npc/male01/runforyourlife03.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Run", {"vo/npc/male01/strider_run.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Behind you", {"vo/npc/male01/behindyou01.wav", "vo/npc/male01/behindyou02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "You got it", {"vo/npc/male01/yougotit02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Whoops", {"vo/npc/male01/whoops01.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Watch out", {"vo/npc/male01/watchout.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Waiting for somebody?", {"vo/npc/male01/waitingsomebody.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Like that", {"vo/npc/male01/likethat.wav"})
InsertTaunt(CAT_TAUNTS, "male", "We trusted you", {"vo/npc/male01/wetrustedyou01.wav", "vo/npc/male01/wetrustedyou02.wav"})
InsertTaunt(CAT_TAUNTS, "male", "How about that", {"vo/npc/male01/answer25.wav"})
InsertTaunt(CAT_TAUNTS, "male", "Wanna bet", {"vo/npc/male01/answer27.wav"})

InsertTaunt(CAT_TAUNTS, "female", "Over there", {"vo/npc/female01/overthere01.wav", "vo/npc/female01/overthere02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Over here", {"vo/npc/female01/overhere01.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Take cover", {"vo/npc/female01/takecover02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "I'm Ready", {"vo/npc/female01/okimready01.wav", "vo/npc/female01/okimready02.wav", "vo/npc/female01/okimready03.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Hi", {"vo/npc/female01/hi01.wav", "vo/npc/female01/hi02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Yeah", {"vo/npc/female01/yeah02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Okay", {"vo/npc/female01/ok01.wav", "vo/npc/female01/ok02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "No", {"vo/npc/female01/no01.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Nice", {"vo/npc/female01/nice01.wav", "vo/npc/female01/nice02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Help", {"vo/npc/female01/help01.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Sorry", {"vo/npc/female01/sorry01.wav", "vo/npc/female01/sorry02.wav", "vo/npc/female01/sorry03.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Leave it alone", {"vo/npc/female01/answer38.wav"})
InsertTaunt(CAT_TAUNTS, "female", "I'm with you", {"vo/npc/female01/answer13.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Ready when you are", {"vo/npc/female01/readywhenyouare01.wav", "vo/npc/female01/readywhenyouare02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Whatever you say", {"vo/npc/female01/squad_affirm03.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Let's go", {"vo/npc/female01/letsgo01.wav", "vo/npc/female01/letsgo02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Excuse me", {"vo/npc/female01/excuseme01.wav", "vo/npc/female01/excuseme02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Get down", {"vo/npc/female01/getdown02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Heads up", {"vo/npc/female01/headsup01.wav", "vo/npc/female01/headsup02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Fantastic", {"vo/npc/female01/fantastic01.wav", "vo/npc/female01/fantastic02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Finally", {"vo/npc/female01/finally.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Good God", {"vo/npc/female01/goodgod.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Run for your life", {"vo/npc/female01/runforyourlife01.wav", "vo/npc/female01/runforyourlife02.wav", "vo/npc/female01/runforyourlife03.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Run", {"vo/npc/female01/strider_run.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Behind you", {"vo/npc/female01/behindyou01.wav", "vo/npc/female01/behindyou02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "You got it", {"vo/npc/female01/yougotit02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Whoops", {"vo/npc/female01/whoops01.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Watch out", {"vo/npc/female01/watchout.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Waiting for somebody?", {"vo/npc/female01/waitingsomebody.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Like that", {"vo/npc/female01/likethat.wav"})
InsertTaunt(CAT_TAUNTS, "female", "We trusted you", {"vo/npc/female01/wetrustedyou01.wav", "vo/npc/female01/wetrustedyou02.wav"})
InsertTaunt(CAT_TAUNTS, "female", "How about that", {"vo/npc/female01/answer25.wav"})
InsertTaunt(CAT_TAUNTS, "female", "Wanna bet", {"vo/npc/female01/answer27.wav"})

function GM:GetTauntCategories()
    return Categories
end

function GM:GetTauntCategoryId(category)
    return GetCategoryIndex(category)
end

function GM:GetTaunts(categoryId, mdlCategory)
    return Taunts[categoryId][mdlCategory]
end

function GM:GetPlayerTaunts(ply, categoryId)
    local mdlCategory = ply:GetModelCategory()
    return self:GetTaunts(categoryId, mdlCategory)
end
