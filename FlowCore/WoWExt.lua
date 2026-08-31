FlowCore = FlowCore or {}
local FC = FlowCore

-- =====================================================================
-- SYNASTRIA DATA TYPES & CONSTANTS
-- =====================================================================
FC.CustomDataTypes = {
    PERK_ACQUIRED     = 1,
    PERK_LIMIT        = 2,
    PERK_ACTIVE       = 3,
    PERK_PROG         = 4,
    PERK_TASKASSIGN1  = 6,
    PERK_TASKASSIGN2  = 7,
    PERK_TASKPARTY    = 9,
    PERK_OPTIONS      = 10,
    ATTUNE_HAS        = 11,
    MYTHIC_SELECT     = 12,
    RESOURCE_BANK     = 13,
    RESOURCE_LAST     = 14,
    ATTUNE_RANDOMPROP = 15,
}

-- Forge Tier Names (Synastria Native)
FC.FORGE_TIERS = {
    [1] = "Titanforged",
    [2] = "Warforged",
    [3] = "Lightforged"
}

-- =====================================================================
-- EXPLICIT PERK CATEGORY REGISTRY
-- Matches Synastria in-game Perk Manager categories 1-to-1
-- =====================================================================
local EXPLICIT_PERK_CATEGORIES = {
    -- -------------------------------------------------------------
    -- CLASS PERKS (Fire Mage Set & other class sets - Exactly 5/5)
    -- -------------------------------------------------------------
    ["Empowered Flames"]      = "Class",
    ["Explosive Impact"]      = "Class",
    ["Meteor Shower"]         = "Class",
    ["Slow Burn"]             = "Class",
    ["Spreading Flames"]      = "Class",
    [1113]                    = "Class", -- Explosive Impact
    [1115]                    = "Class", -- Slow Burn
    [1116]                    = "Class", -- Spreading Flames
    [1117]                    = "Class", -- Empowered Flames
    [1119]                    = "Class", -- Meteor Shower

    -- -------------------------------------------------------------
    -- SUPPORT PERKS
    -- -------------------------------------------------------------
    ["Coherence"]             = "Support",
    ["Prevention"]            = "Support",
    ["Thousand Bandaids"]     = "Support",
    ["Thousand Cuts"]         = "Support",
    ["Warding"]               = "Support",
    [334]                     = "Support", -- Coherence
    [11]                      = "Support", -- Prevention
    [15]                      = "Support", -- Thousand Bandaids
    [14]                      = "Support", -- Thousand Cuts
    [4]                       = "Support", -- Warding

    -- -------------------------------------------------------------
    -- UTILITY PERKS
    -- -------------------------------------------------------------
    ["Attunement"]            = "Utility",
    ["Augmentation"]          = "Utility",
    ["Caution"]               = "Utility",
    ["Scouting"]              = "Utility",
    ["Teleportation"]         = "Utility",
    ["Free Will"]             = "Utility",
    ["Opulence"]              = "Utility",
    [10]                      = "Utility", -- Attunement
    [98]                      = "Utility", -- Augmentation
    [26]                      = "Utility", -- Caution
    [48]                      = "Utility", -- Scouting
    [476]                     = "Utility", -- Teleportation
    [922]                     = "Utility", -- Free Will
    [119]                     = "Utility", -- Opulence

    -- -------------------------------------------------------------
    -- DEFENSIVE PERKS
    -- -------------------------------------------------------------
    ["Independence"]          = "Defensive",
    ["Stubborn"]              = "Defensive",
    ["Augmented Barriers"]    = "Defensive",
    ["Hardening"]             = "Defensive",
    ["Elemental Shielding"]   = "Defensive",
    ["Tough Shell"]           = "Defensive",
    ["Steadfast"]             = "Defensive",
    ["Recovery"]              = "Defensive",
    [91]                      = "Defensive", -- Independence
    [71]                      = "Defensive", -- Stubborn
    [905]                     = "Defensive", -- Augmented Barriers
    [27]                      = "Defensive", -- Hardening
    [899]                     = "Defensive", -- Elemental Shielding
    [55]                      = "Defensive", -- Tough Shell
    [1354]                    = "Defensive", -- Steadfast
    [9]                       = "Defensive", -- Recovery

    -- -------------------------------------------------------------
    -- OFFENSIVE PERKS
    -- -------------------------------------------------------------
    ["Extension"]             = "Offensive",
    ["Outburst"]              = "Offensive",
    ["Dissipation"]           = "Offensive",
    ["Vengeance"]             = "Offensive",
    ["Precision"]             = "Offensive",
    ["Polarity"]              = "Offensive",
    ["Ambivalence"]           = "Offensive",
    ["Adaptation"]            = "Offensive",
    ["Inspiration"]           = "Offensive",
    [79]                      = "Offensive", -- Extension
    [112]                     = "Offensive", -- Outburst
    [114]                     = "Offensive", -- Dissipation
    [226]                     = "Offensive", -- Vengeance
    [59]                      = "Offensive", -- Precision
    [85]                      = "Offensive", -- Polarity
    [86]                      = "Offensive", -- Ambivalence
    [87]                      = "Offensive", -- Adaptation
    [120]                     = "Offensive", -- Inspiration

    -- -------------------------------------------------------------
    -- CLASS PERKS (Specific to Death Knight, Mage, Paladin, etc.)
    -- -------------------------------------------------------------
    ["Unholy Infestation"]       = "Class",
    ["Improved Unholy Runes"]    = "Class",
    ["Improved Scourge Strike"]  = "Class",
    ["Shadow Reach"]             = "Class",
    ["Affliction"]               = "Class",
    ["Improved Frost Strike"]    = "Class",
    ["Improved Howling Blast"]   = "Class",
    ["Improved Death Coil"]      = "Class",
    ["Improved Obliterate"]      = "Class",
    ["Improved Blood Strike"]    = "Class",
    ["Plaguebringer"]            = "Class",
    ["Epidemic Burst"]           = "Class",
    ["Explosive Impact"]         = "Class",
    ["Slow Burn"]                = "Class",
    ["Spreading Flames"]         = "Class",
    ["Empowered Flames"]         = "Class",
    ["Meteor Shower"]            = "Class",
    [846]                        = "Class", -- Unholy Infestation
    [53]                         = "Class", -- Improved Unholy Runes
    [847]                        = "Class", -- Improved Scourge Strike
    [1170]                       = "Class", -- Shadow Reach
    [123]                        = "Class", -- Affliction
    [1113]                       = "Class", -- Explosive Impact
    [1115]                       = "Class", -- Slow Burn
    [1116]                       = "Class", -- Spreading Flames
    [1117]                       = "Class", -- Empowered Flames
    [1119]                       = "Class", -- Meteor Shower

    -- -------------------------------------------------------------
    -- MISC PERKS (Explicitly classified QoL, Level Floors, Prestige & Indicators)
    -- -------------------------------------------------------------
    ["Minimum Defensive Perk Level"] = "Misc",
    ["Minimum Support Perk Level"]   = "Misc",
    ["Minimum Utility Perk Level"]   = "Misc",
    ["Minimum Offensive Perk Level"] = "Misc",
    ["Minimum Class Perk Level"]     = "Misc",
    ["Prestige: Loot BoP"]           = "Misc",
    ["Prestige: Loot BoE"]           = "Misc",
    ["Prestige: Loot Forging"]       = "Misc",
    ["Prestige: Loot Chance"]        = "Misc",
    ["Prestige: Attune Mastery"]     = "Misc",
    ["Prestige: Dual Class"]         = "Misc",
    ["Dungeon Event Speedup"]        = "Misc",
    ["Automatic Mount"]              = "Misc",
    ["Attune Bar"]                   = "Misc",
    ["Combustion Indicator"]         = "Misc",
    ["Balance: Mage"]                = "Misc",
    ["Balance: Death Knight"]        = "Misc",
    ["Disable Item Refund"]          = "Misc",
    ["Automatic Next Melee"]         = "Misc",
    ["Misc Options"]                 = "Misc",
    ["Scan for Rare Enemy"]          = "Misc",
    ["Automatic Accept Quest"]       = "Misc",
    ["Automatic Complete Quest"]     = "Misc",
    ["Automatic Bank"]               = "Misc",
    ["Automatic Fishing"]            = "Misc",
    ["Automatic Buffs"]              = "Misc",
    ["Tracking"]                     = "Misc",
    ["Weapon Enchant Durations"]     = "Misc",
    ["Less Annoying Buffs"]          = "Misc",
    ["Notify on Forged Drop"]        = "Misc",
    ["Extra Racial Skill"]           = "Misc",
    ["Instant Windrider"]            = "Misc",
    ["Currency Drop Bonus"]          = "Misc",
    [796]                            = "Misc", -- Minimum Offensive Perk Level
    [797]                            = "Misc", -- Minimum Defensive Perk Level
    [798]                            = "Misc", -- Minimum Support Perk Level
    [799]                            = "Misc", -- Minimum Utility Perk Level
    [800]                            = "Misc", -- Minimum Class Perk Level
    [1491]                           = "Misc", -- Prestige: Dual Class
    [1492]                           = "Misc", -- Prestige: Loot BoP
    [1493]                           = "Misc", -- Prestige: Loot BoE
    [1494]                           = "Misc", -- Prestige: Loot Forging
    [1557]                           = "Misc", -- Prestige: Loot Chance
    [1500]                           = "Misc", -- Prestige: Attune Mastery
    [909]                            = "Misc", -- Dungeon Event Speedup
    [1277]                           = "Misc", -- Automatic Mount
    [1703]                           = "Misc", -- Attune Bar
    [920]                            = "Misc", -- Combustion Indicator
    [882]                            = "Misc", -- Balance: Mage
    [880]                            = "Misc", -- Balance: Death Knight
    [1157]                           = "Misc", -- Disable Item Refund
    [996]                            = "Misc", -- Automatic Next Melee
    [1112]                           = "Misc", -- Misc Options
    [758]                            = "Misc", -- Scan for Rare Enemy
    [759]                            = "Misc", -- Tracking
    [855]                            = "Misc", -- Automatic Fishing
    [816]                            = "Misc", -- Weapon Enchant Durations
    [778]                            = "Misc", -- Less Annoying Buffs
    [1692]                           = "Misc", -- Automatic Complete Quest
    [1717]                           = "Misc", -- Automatic Accept Quest
    [1042]                           = "Misc", -- Automatic Bank
    [1694]                           = "Misc", -- Notify on Forged Drop
    [1141]                           = "Misc", -- Extra Racial Skill
    [1172]                           = "Misc", -- Automatic Buffs
    [806]                            = "Misc", -- Instant Windrider
    [1715]                           = "Misc"  -- Currency Drop Bonus
}

-- Known Synastria Class Perk Sets (for auto-detecting active 4pc bonuses)
local CLASS_PERK_SETS = {
    -- Fire Mage Set
    [1113] = "Fire Mage", -- Explosive Impact
    [1115] = "Fire Mage", -- Slow Burn
    [1116] = "Fire Mage", -- Spreading Flames
    [1117] = "Fire Mage", -- Empowered Flames
    [1119] = "Fire Mage", -- Meteor Shower
    ["Empowered Flames"] = "Fire Mage",
    ["Explosive Impact"] = "Fire Mage",
    ["Meteor Shower"]    = "Fire Mage",
    ["Slow Burn"]        = "Fire Mage",
    ["Spreading Flames"] = "Fire Mage",

    -- Frost / Unholy Death Knight Set
    [846] = "Frost / Unholy DK", -- Unholy Infestation
    [53]  = "Frost / Unholy DK", -- Improved Unholy Runes
    [847] = "Frost / Unholy DK", -- Improved Scourge Strike
    [1170]= "Frost / Unholy DK", -- Shadow Reach
    [123] = "Frost / Unholy DK", -- Affliction
    ["Unholy Infestation"]       = "Frost / Unholy DK",
    ["Improved Unholy Runes"]    = "Frost / Unholy DK",
    ["Improved Scourge Strike"]  = "Frost / Unholy DK",
    ["Shadow Reach"]             = "Frost / Unholy DK",
    ["Affliction"]               = "Frost / Unholy DK",
    ["Improved Frost Strike"]    = "Frost / Unholy DK",
    ["Improved Howling Blast"]   = "Frost / Unholy DK",
    ["Improved Death Coil"]      = "Frost / Unholy DK",
    ["Improved Obliterate"]      = "Frost / Unholy DK",
    ["Improved Blood Strike"]    = "Frost / Unholy DK",
    ["Plaguebringer"]            = "Frost / Unholy DK",
    ["Epidemic Burst"]           = "Frost / Unholy DK",

    -- Retribution Paladin Set
    ["Improved Crusader Strike"] = "Retribution Paladin",
    ["Improved Divine Storm"]    = "Retribution Paladin",
    ["Judgement Mastery"]        = "Retribution Paladin",

    -- Arms / Fury Warrior Set
    ["Improved Mortal Strike"]   = "Arms / Fury Warrior",
    ["Improved Bloodthirst"]     = "Arms / Fury Warrior",
    ["Improved Whirlwind"]       = "Arms / Fury Warrior"
}

-- =====================================================================
-- EXT STATE STRUCTURE
-- =====================================================================
FC.extState = FC.extState or {
    synastriaDetected = false,
    hasCoreLib = false,
    perksCount = 0,
    activePerks = {},
    activePerkCounts = {
        Offensive = 0,
        Defensive = 0,
        Support = 0,
        Utility = 0,
        Class = 0,
        Misc = 0
    },
    categories = {
        Offensive = {},
        Defensive = {},
        Support = {},
        Utility = {},
        Class = {},
        Misc = {}
    },
    activeClassSet = nil,
    classSetCount = 0,
    activeSetBonuses = {},
    attunementGear = {},
    totalAttunedItems = 0,
    forgeCounts = {
        Titanforged = 0,
        Warforged = 0,
        Lightforged = 0
    }
}

FC.EXT_REFRESH_INTERVAL = 30.0

local function ResolveTexturePath(tex)
    if not tex or tex == "" then return nil end
    if type(tex) == "number" and tex > 0 then
        local st = GetSpellTexture(tex)
        if st and st ~= "" then return st end
        local _, _, si = GetSpellInfo(tex)
        if si and si ~= "" then return si end
        local it = GetItemIcon(tex)
        if it and it ~= "" then return it end
        return tex
    end
    if type(tex) == "string" then
        tex = string.gsub(tex, "^%s*(.-)%s*$", "%1")
        if tex == "" then return nil end
        local num = tonumber(tex)
        if num and num > 0 then
            local st = GetSpellTexture(num)
            if st and st ~= "" then return st end
            local _, _, si = GetSpellInfo(num)
            if si and si ~= "" then return si end
            local it = GetItemIcon(num)
            if it and it ~= "" then return it end
            return num
        end
        local clean = string.gsub(tex, "%.[bB][lL][pP]$", "")
        clean = string.gsub(clean, "%.[tT][gG][aA]$", "")
        if string.find(clean, "\\", 1, true) or string.find(clean, "/", 1, true) then
            return clean
        else
            return "Interface\\Icons\\" .. clean
        end
    end
    return nil
end

local function FormatPerkIcon(rawIcon, spellId, pName, perkId, perkObj)
    -- 1. Check direct rawIcon
    local res = ResolveTexturePath(rawIcon)
    if res then return res end

    local numId = tonumber(perkId) or (perkObj and tonumber(perkObj.id))

    -- 2. Check native PerkMgrPerks table in _G
    if numId and _G.PerkMgrPerks and _G.PerkMgrPerks[numId] then
        local rawP = _G.PerkMgrPerks[numId]
        if type(rawP) == "table" then
            res = ResolveTexturePath(rawP.icon) or ResolveTexturePath(rawP.texture) or ResolveTexturePath(rawP.iconPath) or ResolveTexturePath(rawP.iconName) or ResolveTexturePath(rawP.spellId) or ResolveTexturePath(rawP.spell)
            if res then return res end
        end
    end

    -- 3. Check SynastriaCoreLib if available
    if numId and LibStub and LibStub("SynastriaCoreLib-1.0", true) then
        local coreLib = LibStub("SynastriaCoreLib-1.0", true)
        if coreLib and coreLib.Perks and type(coreLib.Perks.GetPerk) == "function" then
            local ok, libP = pcall(coreLib.Perks.GetPerk, coreLib.Perks, numId)
            if ok and type(libP) == "table" then
                res = ResolveTexturePath(libP.icon) or ResolveTexturePath(libP.texture) or ResolveTexturePath(libP.spellId or libP.spell)
                if res then return res end
            end
        end
    end

    -- 4. Check explicit numeric spellId
    if spellId and tonumber(spellId) and tonumber(spellId) > 0 then
        res = ResolveTexturePath(tonumber(spellId))
        if res then return res end
    end

    -- 5. Query WoW client spell database by spell/perk name & root name
    if pName and type(pName) == "string" and pName ~= "" then
        local st = GetSpellTexture(pName)
        if st and st ~= "" then return st end
        local _, _, si = GetSpellInfo(pName)
        if si and si ~= "" then return si end

        local root = string.gsub(pName, "^[Ii]mproved%s+", "")
        root = string.gsub(root, "^[Ee]mpowered%s+", "")
        root = string.gsub(root, "^[Mm]assive%s+", "")
        root = string.gsub(root, "^[Gg]reater%s+", "")
        root = string.gsub(root, "^[Mm]aster%s+of%s+", "")
        root = string.gsub(root, "^[Aa]ugmented%s+", "")
        if root ~= pName then
            st = GetSpellTexture(root)
            if st and st ~= "" then return st end
            local _, _, si2 = GetSpellInfo(root)
            if si2 and si2 ~= "" then return si2 end
        end
    end

    -- 6. Comprehensive thematic keyword fallback
    if pName and type(pName) == "string" then
        local lower = string.lower(pName)
        if string.find(lower, "scourge", 1, true) or string.find(lower, "strike", 1, true) or string.find(lower, "death", 1, true) or string.find(lower, "corpse", 1, true) then
            return "Interface\\Icons\\Spell_DeathKnight_ScourgeStrike"
        elseif string.find(lower, "rune", 1, true) or string.find(lower, "unholy", 1, true) or string.find(lower, "disease", 1, true) or string.find(lower, "plague", 1, true) then
            return "Interface\\Icons\\Spell_DeathKnight_UnholyPresence"
        elseif string.find(lower, "blood", 1, true) or string.find(lower, "vampir", 1, true) then
            return "Interface\\Icons\\Spell_DeathKnight_BloodPresence"
        elseif string.find(lower, "frost", 1, true) or string.find(lower, "ice", 1, true) or string.find(lower, "chill", 1, true) or string.find(lower, "cold", 1, true) then
            return "Interface\\Icons\\Spell_DeathKnight_FrostPresence"
        elseif string.find(lower, "whirlwind", 1, true) or string.find(lower, "charge", 1, true) or string.find(lower, "slam", 1, true) or string.find(lower, "rage", 1, true) or string.find(lower, "mortal", 1, true) then
            return "Interface\\Icons\\Ability_Whirlwind"
        elseif string.find(lower, "fire", 1, true) or string.find(lower, "flame", 1, true) or string.find(lower, "pyro", 1, true) or string.find(lower, "combust", 1, true) then
            return "Interface\\Icons\\Spell_Fire_Fireball02"
        elseif string.find(lower, "shadow", 1, true) or string.find(lower, "affliction", 1, true) or string.find(lower, "curse", 1, true) or string.find(lower, "drain", 1, true) then
            return "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde"
        elseif string.find(lower, "heal", 1, true) or string.find(lower, "holy", 1, true) or string.find(lower, "blessing", 1, true) or string.find(lower, "ancestral", 1, true) or string.find(lower, "penance", 1, true) then
            return "Interface\\Icons\\Spell_Holy_HolyBolt"
        elseif string.find(lower, "shield", 1, true) or string.find(lower, "armor", 1, true) or string.find(lower, "defense", 1, true) or string.find(lower, "protect", 1, true) or string.find(lower, "barrier", 1, true) then
            return "Interface\\Icons\\INV_Shield_04"
        elseif string.find(lower, "shot", 1, true) or string.find(lower, "arrow", 1, true) or string.find(lower, "hunter", 1, true) or string.find(lower, "trap", 1, true) or string.find(lower, "aim", 1, true) or string.find(lower, "volley", 1, true) then
            return "Interface\\Icons\\Ability_Hunter_AimedShot"
        elseif string.find(lower, "poison", 1, true) or string.find(lower, "stealth", 1, true) or string.find(lower, "backstab", 1, true) or string.find(lower, "mutilate", 1, true) or string.find(lower, "eviscerate", 1, true) or string.find(lower, "shadowstep", 1, true) or string.find(lower, "turret", 1, true) then
            return "Interface\\Icons\\Ability_Rogue_Eviscerate"
        elseif string.find(lower, "totem", 1, true) or string.find(lower, "lightning", 1, true) or string.find(lower, "earth", 1, true) or string.find(lower, "storm", 1, true) or string.find(lower, "shaman", 1, true) then
            return "Interface\\Icons\\Spell_Nature_Lightning"
        elseif string.find(lower, "druid", 1, true) or string.find(lower, "bear", 1, true) or string.find(lower, "cat", 1, true) or string.find(lower, "moonkin", 1, true) or string.find(lower, "eclipse", 1, true) or string.find(lower, "thorns", 1, true) or string.find(lower, "starfall", 1, true) or string.find(lower, "rejuvenation", 1, true) then
            return "Interface\\Icons\\Ability_Druid_Starfall"
        elseif string.find(lower, "alchemy", 1, true) or string.find(lower, "potion", 1, true) then
            return "Interface\\Icons\\Trade_Alchemy"
        elseif string.find(lower, "blacksmith", 1, true) or string.find(lower, "forge", 1, true) then
            return "Interface\\Icons\\Trade_BlackSmithing"
        elseif string.find(lower, "enchant", 1, true) then
            return "Interface\\Icons\\Trade_Engraving"
        elseif string.find(lower, "tailor", 1, true) then
            return "Interface\\Icons\\Trade_Tailoring"
        elseif string.find(lower, "jewel", 1, true) or string.find(lower, "gem", 1, true) then
            return "Interface\\Icons\\INV_Misc_Gem_01"
        end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end
FC.FormatPerkIcon = FormatPerkIcon

local CLASS_ID_TO_TOKEN = {
    [1] = "WARRIOR",
    [2] = "PALADIN",
    [3] = "HUNTER",
    [4] = "ROGUE",
    [5] = "PRIEST",
    [6] = "DEATHKNIGHT",
    [7] = "SHAMAN",
    [8] = "MAGE",
    [9] = "WARLOCK",
    [11] = "DRUID"
}

local CLASS_TOKEN_TO_MASK = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 4,
    ROGUE = 8,
    PRIEST = 16,
    DEATHKNIGHT = 32,
    SHAMAN = 64,
    MAGE = 128,
    WARLOCK = 256,
    DRUID = 1024
}

local CLASS_SET_NAMES_TO_CLASS = {
    -- DEATH KNIGHT (4 Sets)
    ["blood death knight"] = "DEATHKNIGHT",
    ["frost death knight"] = "DEATHKNIGHT",
    ["unholy death knight"] = "DEATHKNIGHT",
    ["undead army"] = "DEATHKNIGHT",

    -- MAGE
    ["fire mage"] = "MAGE",
    ["frost mage"] = "MAGE",
    ["arcane mage"] = "MAGE",
    ["arcane surge"] = "MAGE",
    ["wandslinger"] = "MAGE",

    -- PALADIN
    ["holy paladin"] = "PALADIN",
    ["protection paladin"] = "PALADIN",
    ["retribution paladin"] = "PALADIN",
    ["oathbreaker"] = "PALADIN",

    -- WARRIOR
    ["arms warrior"] = "WARRIOR",
    ["fury warrior"] = "WARRIOR",
    ["protection warrior"] = "WARRIOR",
    ["furious charge"] = "WARRIOR",

    -- WARLOCK
    ["affliction warlock"] = "WARLOCK",
    ["demonology warlock"] = "WARLOCK",
    ["destruction warlock"] = "WARLOCK",
    ["summoner"] = "WARLOCK",
    ["master summoner"] = "WARLOCK",

    -- PRIEST
    ["discipline priest"] = "PRIEST",
    ["holy priest"] = "PRIEST",
    ["shadow priest"] = "PRIEST",
    ["overhealed"] = "PRIEST",
    ["reaper of souls"] = "PRIEST",

    -- ROGUE
    ["assassination rogue"] = "ROGUE",
    ["combat rogue"] = "ROGUE",
    ["subtlety rogue"] = "ROGUE",

    -- HUNTER
    ["beast mastery hunter"] = "HUNTER",
    ["marksmanship hunter"] = "HUNTER",
    ["survival hunter"] = "HUNTER",
    ["volley"] = "HUNTER",

    -- SHAMAN
    ["elemental shaman"] = "SHAMAN",
    ["enhancement shaman"] = "SHAMAN",
    ["restoration shaman"] = "SHAMAN",
    ["elemental conflux"] = "SHAMAN",
    ["wandering spirits"] = "SHAMAN",

    -- DRUID
    ["balance druid"] = "DRUID",
    ["feral druid"] = "DRUID",
    ["restoration druid"] = "DRUID",
    ["revitalization"] = "DRUID",
}

local CLASS_SPELL_AND_KEYWORD_MAP = {
    WARRIOR = {
        "warrior", "mortal strike", "bloodthirst", "whirlwind", "shield slam", "devastate", "revenge", "overpower",
        "slam", "execute", "shockwave", "heroic strike", "cleave", "concussion blow", "last stand", "shield block",
        "shield wall", "berserker rage", "recklessness", "death wish", "sweeping strikes", "taste for blood",
        "sudden death", "bloodsurge", "flurry", "unending fury", "deep wounds", "trauma", "vitality", "sword and board",
        "warbringer", "armored to the teeth", "incite", "cruelty", "booming voice", "unbridled wrath", "second wind",
        "iron will", "blood frenzy", "wrecking crew", "bladestorm", "titan's grip", "damage shield", "heroic throw",
        "shattering throw", "intervene", "intercept", "pummel", "shield bash", "bloodrage", "retaliation", "disarm",
        "hamstring", "victory rush", "battle shout", "commanding shout", "demoralizing shout", "challenging shout"
    },
    PALADIN = {
        "paladin", "crusader strike", "divine storm", "judgement", "seal of", "righteous vengeance", "holy shock",
        "flash of light", "holy light", "beacon of light", "sacred shield", "avenging wrath", "hammer of wrath",
        "consecration", "shield of the righteous", "avenger's shield", "hammer of the righteous", "holy shield",
        "divine protection", "divine shield", "lay on hands", "art of war", "infusion of light", "illumination",
        "redoubt", "ardent defender", "righteous fury", "hand of freedom", "hand of protection", "hand of sacrifice",
        "hand of salvation", "hand of reckoning", "righteous defense", "divine plea", "sheath of light",
        "touched by the light", "sacred cleansing", "guarded by the light", "conviction", "crusade", "fanaticism",
        "heart of the crusader", "sanctified retribution", "swift retribution", "divine purpose", "exorcism", "holy wrath"
    },
    HUNTER = {
        "hunter", "explosive shot", "chimera shot", "aimed shot", "kill shot", "arcane shot", "multi-shot", "steady shot",
        "serpent sting", "viper sting", "scorpid sting", "black arrow", "lock and load", "sniper training", "readiness",
        "bestial wrath", "kill command", "concussive shot", "silencing shot", "trueshot aura", "hunting party", "trap",
        "frost trap", "freezing trap", "immolation trap", "explosive trap", "snake trap", "freezing arrow", "feign death",
        "disengage", "deterrence", "rapid fire", "aspect of the dragonhawk", "aspect of the hawk", "aspect of the viper",
        "aspect of the monkey", "aspect of the cheetah", "aspect of the pack", "aspect of the wild", "aspect of the beast",
        "call pet", "dismiss pet", "revive pet", "mend pet", "tame beast", "flare", "hunter's mark", "misdirection",
        "scare beast", "tranquilizing shot", "raptor strike", "mongoose bite", "wing clip", "t.n.t.", "tnt", "noxious stings",
        "master tactician", "resourcefulness", "thrill of the hunt", "entrapment", "survivalist", "lightning reflexes",
        "careful aim", "mortal shots", "piercing shots", "wild quiver", "improved stings", "ferocious inspiration",
        "the beast within", "frenzy", "unleashed fury", "focused fire", "serpent's swiftness", "invigoration", "cobra strikes", "longevity"
    },
    ROGUE = {
        "rogue", "mutilate", "sinister strike", "backstab", "ambush", "eviscerate", "envenom", "rupture", "slice and dice",
        "blade flurry", "killing spree", "shadow dance", "shadowstep", "stealth", "vanish", "cloak of shadows", "evasion",
        "sprint", "blind", "kidney shot", "cheap shot", "kick", "gouge", "sap", "distract", "feint", "garrote", "fan of knives",
        "tricks of the trade", "preparation", "cold blood", "ghostly strike", "hemorrhage", "premeditation", "mind-numbing poison",
        "instant poison", "deadly poison", "wound poison", "crippling poison", "anesthetic poison", "combo points", "overkill",
        "hunger for blood", "cut to the chase", "combat potency", "relentless strikes", "honor among thieves", "master of subtlety",
        "vile poisons", "master poisoner", "quick recovery", "fleet footed", "lethality", "malice", "puncturing wounds",
        "opportunity", "cheat death", "waylay", "hack and slash", "aggression", "surprise attacks", "prey on the weak"
    },
    PRIEST = {
        "priest", "mind blast", "mind flay", "vampiric touch", "shadow word: pain", "shadow word: death", "shadow word",
        "shadowform", "dispersion", "mind sear", "devouring plague", "penance", "power word: shield", "flash heal",
        "greater heal", "prayer of healing", "circle of healing", "renew", "pain suppression", "guardian spirit",
        "divine hymn", "hymn of hope", "power infusion", "shadowfiend", "mind soothe", "mind control", "psychic scream",
        "psychic horror", "inner fire", "inner focus", "fear ward", "desperate prayer", "mass dispel", "dispel magic",
        "cure disease", "abolish disease", "power word: fortitude", "prayer of fortitude", "divine spirit", "prayer of spirit",
        "shadow protection", "rapture", "borrowed time", "surge of light", "serendipity", "shadow weaving", "darkness",
        "misery", "vampiric embrace", "shadow power", "mind melt", "shadow affinity", "shadow reach", "spirit tap",
        "inspiration", "empowered healing", "grace", "divine aegis", "soul warding", "reflecting shield", "body and soul", "test of faith"
    },
    DEATHKNIGHT = {
        "death knight", "deathknight", "dk", "death coil", "death strike", "death and decay", "death pact", "death gate",
        "death grip", "scourge strike", "frost strike", "howling blast", "obliterate", "blood strike", "heart strike",
        "blood boil", "pestilence", "plague strike", "icy touch", "chains of ice", "strangulate", "mind freeze",
        "corpse explosion", "raise dead", "army of the dead", "summon gargoyle", "empower rune weapon", "icebound fortitude",
        "anti-magic shell", "anti-magic zone", "anti-magic", "vampiric blood", "unbreakable armor", "bone shield",
        "dancing rune weapon", "dancing rune", "rune tap", "dark command", "hungering cold", "horn of winter", "path of frost",
        "frost fever", "blood plague", "ebon plaguebringer", "plaguebringer", "epidemic", "crypt stalker", "morbidity",
        "desecration", "unholy blight", "unholy presence", "blood presence", "frost presence", "unholy", "blood-caked blade",
        "sudden doom", "reaping", "dirge", "impurity", "necrosis", "scent of blood", "blade barrier", "veteran of the third war",
        "will of the necropolis", "tundra stalker", "killing machine", "rime", "threat of thassarian", "acclimation",
        "guile of gorefiend", "bloody strikes", "butchery", "subversion", "vendetta", "spell deflection", "runic power",
        "death rune", "blood rune", "frost rune", "unholy rune", "runic strike", "ghoul frenzy", "night of the dead",
        "master of ghouls", "corpse dust", "blood death knight", "frost death knight", "unholy death knight", "undead army"
    },
    SHAMAN = {
        "shaman", "lava burst", "lightning bolt", "chain lightning", "earth shock", "flame shock", "frost shock",
        "stormstrike", "lava lash", "windfury weapon", "flametongue weapon", "frostbrand weapon", "earthliving weapon",
        "rockbiter weapon", "windfury", "flametongue", "earthliving", "riptide", "healing wave", "lesser healing wave",
        "chain heal", "healing stream totem", "mana spring totem", "tremor totem", "earthbind totem", "grounding totem",
        "magma totem", "fire nova", "searing totem", "windfury totem", "wrath of air totem", "totem of wrath", "mana tide totem",
        "healing stream", "mana spring", "totem", "elemental mastery", "feral spirit", "shamanistic rage", "thunderstorm",
        "lightning shield", "water shield", "earth shield", "reincarnation", "ghost wolf", "bloodlust", "heroism", "purge",
        "wind shear", "hex", "water walking", "water breathing", "maelstrom weapon", "tidal waves", "ancestral awakening",
        "unleashed rage", "mental quickness", "shamanistic focus", "elemental devastation", "elemental fury", "elemental focus",
        "call of thunder", "lightning overload", "lava flows", "ancestral healing", "healing grace", "nature's swiftness", "tidal focus"
    },
    MAGE = {
        "mage", "fireball", "pyroblast", "fire blast", "scorch", "flamestrike", "blast wave", "dragon's breath",
        "combustion", "living bomb", "meteor shower", "spreading flames", "slow burn", "explosive impact", "empowered flames",
        "frostbolt", "ice lance", "frost nova", "cone of cold", "blizzard", "deep freeze", "ice block", "icy veins",
        "cold snap", "ice barrier", "arcane blast", "arcane missiles", "arcane barrage", "arcane explosion", "arcane power",
        "presence of mind", "evocation", "mana shield", "slow fall", "slow", "blink", "counterspell", "polymorph",
        "spellsteal", "mirror image", "invisibility", "mage armor", "ice armor", "frost armor", "molten armor",
        "arcane intellect", "arcane brilliance", "dalaran brilliance", "mana gem", "ignite", "hot streak", "firestarter",
        "empowered fire", "burnout", "critical mass", "pyroclastic", "world in flames", "molten shields", "fingers of frost",
        "brain freeze", "shatter", "frostbite", "winter's chill", "permafrost", "piercing ice", "arctic reaches",
        "missile barrage", "torment the weak", "arcane mind", "incanter's absorption"
    },
    WARLOCK = {
        "warlock", "chaos bolt", "conflagrate", "incinerate", "immolate", "soul fire", "shadow burn", "shadowburn",
        "haunt", "unstable affliction", "corruption", "curse of agony", "curse of doom", "curse of the elements",
        "curse of weakness", "curse of tongues", "curse of exhaustion", "drain soul", "drain life", "drain mana",
        "seed of corruption", "shadow bolt", "metamorphosis", "demonic empowerment", "felguard", "succubus", "voidwalker",
        "imp", "felhunter", "infernal", "doomguard", "life tap", "dark pact", "health funnel", "fear", "howl of terror",
        "shadowfury", "demon charge", "immolation aura", "fel armor", "demon armor", "demon skin", "soulstone", "healthstone",
        "create soulstone", "create healthstone", "soul shard", "soul link", "molten core", "decimation", "nightfall",
        "shadow embrace", "pandemic", "demonic pact", "backdraft", "fire and brimstone", "empowered imp", "eradication",
        "siphon life", "malediction", "contagion", "improved shadow bolt", "cataclysm", "ruin", "emberstorm", "aftermath",
        "shadow and flame", "improved corruption", "master demonologist", "demonic aegis", "demonic knowledge"
    },
    DRUID = {
        "druid", "starfire", "wrath", "moonfire", "insect swarm", "starfall", "force of nature", "treant", "typhoon",
        "hurricane", "shred", "rip", "rake", "ferocious bite", "mangle (cat)", "mangle (bear)", "mangle", "savage roar",
        "swipe (cat)", "swipe (bear)", "swipe", "lacerate", "maul", "frenzied regeneration", "survival instincts",
        "barkskin", "bear form", "dire bear form", "cat form", "moonkin form", "tree of life", "flight form",
        "aquatic form", "travel form", "rejuvenation", "regrowth", "lifebloom", "wild growth", "swiftmend", "healing touch",
        "nourish", "tranquility", "innervate", "rebirth", "mark of the wild", "gift of the wild", "thorns", "entangling roots",
        "nature's grasp", "faerie fire", "faerie fire (feral)", "soothe animal", "demoralizing roar", "challenging roar",
        "growl", "dash", "prowl", "pounce", "cower", "bash", "feral charge", "cyclone", "hibernate", "tiger's fury", "berserk",
        "eclipse", "balance of power", "omen of clarity", "king of the jungle", "primal fury", "predatory strikes",
        "master shapeshifter", "heart of the wild", "naturalist", "nature's grace", "moonglow", "celestial focus",
        "starlight wrath", "genesis", "brambles", "improved moonfire", "splendor", "dreamstate", "owlkin frenzy",
        "earth and moon", "feral aggression", "feral instinct", "savage fury", "feral swiftness", "nurturing instinct",
        "infected wounds", "rend and tear", "primal gore", "living seed", "improved rejuvenation", "gift of the earthmother"
    }
}

function FC:GetPerkAssignedClass(perk)
    if not perk then return "ALL" end

    -- 1. Explicit assigned class on perk (from perkexport.csv or FC.PERK_DATABASE)
    local ac = perk.assignedClass or perk.assigned_class
    if type(ac) == "string" and ac ~= "" then
        return ac
    end

    -- 2. Direct perk object class properties
    local c = perk.class or perk.className or perk.playerClass
    if type(c) == "string" and c ~= "" and c ~= "GENERAL" then
        local upper = string.upper(c)
        if upper == "DEATH KNIGHT" or upper == "DK" or upper == "DEATHKNIGHT" then return "DEATHKNIGHT" end
        for clsKey in pairs(CLASS_SPELL_AND_KEYWORD_MAP) do
            if upper == clsKey or string.find(upper, clsKey, 1, true) then
                return clsKey
            end
        end
    end

    -- 3. Authoritative Native Category Mapping Check (cat ID 1..11)
    local pCat = perk.cat or (perk.raw and perk.raw.cat)
    if pCat then
        local numCat = tonumber(pCat)
        local catMap = NATIVE_CAT_MAP and (NATIVE_CAT_MAP[numCat] or NATIVE_CAT_MAP[tostring(pCat)])
        if catMap and catMap.class then
            return catMap.class
        end
    end

    local cId = perk.classId or perk.classID or perk.class_id or perk.reqClass or perk.requiredClass
    if type(cId) == "number" and CLASS_ID_TO_TOKEN[cId] then
        return CLASS_ID_TO_TOKEN[cId]
    end

    local cMask = perk.classMask or perk.classes or perk.allowClass or perk.class_mask
    if type(cMask) == "number" and cMask > 0 and cMask < 2047 then
        for clsKey, mask in pairs(CLASS_TOKEN_TO_MASK) do
            if cMask == mask then
                return clsKey
            end
        end
    end

    -- 4. Perk Set Membership Check
    local pSet = perk.setName or perk.set_name
    if not pSet and FC.discoveredPerkSets and perk.id then
        for sName, sDef in pairs(FC.discoveredPerkSets) do
            if type(sName) == "string" and sDef.perks then
                for _, pId in ipairs(sDef.perks) do
                    if pId == perk.id then
                        pSet = sName
                        break
                    end
                end
            end
            if pSet then break end
        end
    end

    if pSet and pSet ~= "" then
        local setDef = (FC.discoveredPerkSets and FC.discoveredPerkSets[pSet]) or (FC.SYNASTRIA_CLASS_SETS and FC.SYNASTRIA_CLASS_SETS[pSet])
        if setDef and setDef.class and setDef.class ~= "GENERAL" then
            return setDef.class
        end
        local lowerSet = string.lower(pSet)
        if CLASS_SET_NAMES_TO_CLASS[lowerSet] then
            return CLASS_SET_NAMES_TO_CLASS[lowerSet]
        end
        for clsKey in pairs(CLASS_SPELL_AND_KEYWORD_MAP) do
            local clsNameLower = string.lower(clsKey)
            if string.find(lowerSet, clsNameLower, 1, true) or 
               (clsKey == "DEATHKNIGHT" and (string.find(lowerSet, "death knight", 1, true) or string.find(lowerSet, "deathknight", 1, true) or string.find(lowerSet, "dk", 1, true) or string.find(lowerSet, "undead army", 1, true))) then
                return clsKey
            end
        end
    end

    -- 5. Only if category is "Class" or no category set, fallback to keyword matching
    local cat = perk.category or perk.category_name
    if cat == "Class" or not cat then
        local pName = string.lower(perk.name or "")
        local pDesc = string.lower(perk.description or "")

        for clsKey, keywords in pairs(CLASS_SPELL_AND_KEYWORD_MAP) do
            local clsNameLower = (clsKey == "DEATHKNIGHT" and "death knight") or string.lower(clsKey)
            if string.find(pDesc, "requires " .. clsNameLower, 1, true) or 
               string.find(pDesc, "class: " .. clsNameLower, 1, true) or
               string.find(pDesc, clsNameLower .. " only", 1, true) or
               string.find(pName, clsNameLower, 1, true) then
                return clsKey
            end
        end

        local classMatchCounts = {}
        for clsKey, keywords in pairs(CLASS_SPELL_AND_KEYWORD_MAP) do
            local count = 0
            for _, kw in ipairs(keywords) do
                if string.find(pName, kw, 1, true) then
                    count = count + 3
                elseif string.find(pDesc, kw, 1, true) then
                    count = count + 1
                end
            end
            if count > 0 then
                classMatchCounts[clsKey] = count
            end
        end

        local bestClass = nil
        local bestCount = 0
        for clsKey, count in pairs(classMatchCounts) do
            if count > bestCount then
                bestCount = count
                bestClass = clsKey
            end
        end

        if bestClass then
            return bestClass
        end
    end

    return "ALL"
end

function FC:IsPerkForPlayerClass(perk)
    if not perk then return true end
    local pClass = FC.playerClass or (UnitClass and select(2, UnitClass("player"))) or "DEATHKNIGHT"

    local assignedClass = perk.assignedClass or perk.assigned_class or self:GetPerkAssignedClass(perk)
    if not assignedClass or assignedClass == "" or assignedClass == "ALL" or assignedClass == "GENERAL" then
        return true
    end

    return assignedClass == pClass
end

-- =====================================================================
-- SYNASTRIA CLASS PERK SET BONUSES CATALOG
-- =====================================================================
FC.SYNASTRIA_CLASS_SETS = {
    -- DEATH KNIGHT
    ["Frost / Unholy DK"] = {
        name = "Frost / Unholy DK Set",
        class = "DEATHKNIGHT",
        twoPiece = "Frost Fever & Blood Plague duration increased by 6s.",
        fourPiece = "+100% Frost Strike, Howling Blast, and Death Coil damage.",
        apply = function(state, action, mult)
            if action.name == "Frost Strike" or action.name == "Howling Blast" or action.name == "Death Coil" then
                mult = mult * 2.0
            end
            return mult
        end
    },
    ["Blood DK"] = {
        name = "Blood DK Set",
        class = "DEATHKNIGHT",
        twoPiece = "+20% Death Strike healing and Heart Strike damage.",
        fourPiece = "+100% Death Strike, Blood Strike, and Blood Boil damage; Rune Tap CD -50%.",
        apply = function(state, action, mult)
            if action.name == "Death Strike" or action.name == "Heart Strike" or action.name == "Blood Strike" or action.name == "Blood Boil" then
                mult = mult * 2.0
            end
            return mult
        end
    },

    -- MAGE
    ["Fire Mage"] = {
        name = "Fire Mage Set",
        class = "MAGE",
        twoPiece = "Ignite duration increased by 6s.",
        fourPiece = "+125% Fire damage. You take 30% less damage from Ignited enemies.",
        apply = function(state, action, mult)
            if action.school == "Fire" then
                mult = mult * 2.25
            end
            return mult
        end,
        igniteBonusDuration = 6,
        ignitedDamageReduction = 0.30
    },
    ["Frost Mage"] = {
        name = "Frost Mage Set",
        class = "MAGE",
        twoPiece = "+50% Frost damage to frozen targets.",
        fourPiece = "+100% Deep Freeze damage; Deep Freeze triggers Fingers of Frost.",
        apply = function(state, action, mult)
            if action.school == "Frost" then
                if state.target and (state.target.isFrozen or (state.player.buffs and state.player.buffs["Fingers of Frost"])) then
                    mult = mult * 1.50
                end
                if action.name == "Deep Freeze" then
                    mult = mult * 2.0
                end
            end
            return mult
        end
    },
    ["Arcane Mage"] = {
        name = "Arcane Mage Set",
        class = "MAGE",
        twoPiece = "Arcane Blast cast time reduced by 0.3s.",
        fourPiece = "+80% Arcane Missiles & Arcane Barrage damage; -50% mana cost.",
        apply = function(state, action, mult)
            if action.name == "Arcane Missiles" or action.name == "Arcane Barrage" then
                mult = mult * 1.80
            elseif action.name == "Arcane Blast" then
                mult = mult * 1.20
            end
            return mult
        end
    },

    -- PALADIN
    ["Retribution Paladin"] = {
        name = "Retribution Paladin Set",
        class = "PALADIN",
        twoPiece = "+25% Crusader Strike and Divine Storm damage.",
        fourPiece = "+100% Holy damage on Judgements and Exorcism.",
        apply = function(state, action, mult)
            if action.school == "Holy" or action.name == "Crusader Strike" or action.name == "Divine Storm" then
                mult = mult * 2.0
            end
            return mult
        end
    },
    ["Protection Paladin"] = {
        name = "Protection Paladin Set",
        class = "PALADIN",
        twoPiece = "+15% Block Value and Shield of Righteousness damage.",
        fourPiece = "-25% damage taken; Holy Shield damage doubled.",
        apply = function(state, action, mult)
            if action.name == "Shield of the Righteous" or action.name == "Shield of Righteousness" or action.name == "Hammer of the Righteous" then
                mult = mult * 1.40
            end
            return mult
        end
    },
    ["Holy Paladin"] = {
        name = "Holy Paladin Set",
        class = "PALADIN",
        twoPiece = "+20% Holy Shock critical chance.",
        fourPiece = "+50% Holy Light & Flash of Light healing.",
        apply = function(state, action, mult)
            if action.role == "heal" then
                mult = mult * 1.50
            end
            return mult
        end
    },

    -- WARRIOR
    ["Arms / Fury Warrior"] = {
        name = "Arms / Fury Warrior Set",
        class = "WARRIOR",
        twoPiece = "+20% Mortal Strike, Bloodthirst, and Whirlwind damage.",
        fourPiece = "+100% Execute and Overpower damage.",
        apply = function(state, action, mult)
            if action.name == "Execute" or action.name == "Overpower" then
                mult = mult * 2.0
            elseif action.name == "Mortal Strike" or action.name == "Bloodthirst" or action.name == "Whirlwind" then
                mult = mult * 1.35
            end
            return mult
        end
    },
    ["Protection Warrior"] = {
        name = "Protection Warrior Set",
        class = "WARRIOR",
        twoPiece = "+20% Shield Slam and Devastate damage.",
        fourPiece = "-25% damage taken; Revenge hits an additional target.",
        apply = function(state, action, mult)
            if action.name == "Shield Slam" or action.name == "Devastate" or action.name == "Revenge" then
                mult = mult * 1.40
            end
            return mult
        end
    },

    -- WARLOCK
    ["Destruction Warlock"] = {
        name = "Destruction Warlock Set",
        class = "WARLOCK",
        twoPiece = "Immolate duration increased by 6s.",
        fourPiece = "+100% Chaos Bolt and Incinerate damage.",
        apply = function(state, action, mult)
            if action.school == "Fire" or action.name == "Chaos Bolt" or action.name == "Incinerate" then
                mult = mult * 2.0
            end
            return mult
        end
    },
    ["Affliction Warlock"] = {
        name = "Affliction Warlock Set",
        class = "WARLOCK",
        twoPiece = "+20% periodic Shadow damage.",
        fourPiece = "Corruption ticks 50% faster and restores 1% mana.",
        apply = function(state, action, mult)
            if action.school == "Shadow" and action.role == "dot" then
                mult = mult * 1.80
            end
            return mult
        end
    },
    ["Demonology Warlock"] = {
        name = "Demonology Warlock Set",
        class = "WARLOCK",
        twoPiece = "Demonic Empowerment duration increased by 6s.",
        fourPiece = "+100% Shadow Bolt and Soul Fire damage in Metamorphosis.",
        apply = function(state, action, mult)
            if action.name == "Shadow Bolt" or action.name == "Soul Fire" then
                mult = mult * 2.0
            end
            return mult
        end
    },

    -- PRIEST
    ["Shadow Priest"] = {
        name = "Shadow Priest Set",
        class = "PRIEST",
        twoPiece = "Shadow Word: Pain & Vampiric Touch duration increased by 6s.",
        fourPiece = "+100% Mind Blast and Mind Flay damage.",
        apply = function(state, action, mult)
            if action.name == "Mind Blast" or action.name == "Mind Flay" or action.school == "Shadow" then
                mult = mult * 1.80
            end
            return mult
        end
    },
    ["Holy / Discipline Priest"] = {
        name = "Holy / Discipline Priest Set",
        class = "PRIEST",
        twoPiece = "+20% Penance and Circle of Healing effectiveness.",
        fourPiece = "Power Word: Shield absorb +100%; Flash Heal mana cost -50%.",
        apply = function(state, action, mult)
            if action.role == "heal" or action.role == "absorb" then
                mult = mult * 1.50
            end
            return mult
        end
    },

    -- ROGUE
    ["Assassination / Combat Rogue"] = {
        name = "Assassination / Combat Rogue Set",
        class = "ROGUE",
        twoPiece = "+25% Eviscerate and Envenom damage.",
        fourPiece = "+100% Mutilate and Sinister Strike damage; +10 energy regen.",
        apply = function(state, action, mult)
            if action.role == "spender" or action.role == "builder" then
                mult = mult * 1.80
            end
            return mult
        end
    },
    ["Subtlety Rogue"] = {
        name = "Subtlety Rogue Set",
        class = "ROGUE",
        twoPiece = "Shadow Dance duration increased by 4s.",
        fourPiece = "+100% Ambush, Backstab, and Eviscerate damage from behind.",
        apply = function(state, action, mult)
            if action.name == "Ambush" or action.name == "Backstab" or action.name == "Eviscerate" then
                mult = mult * 2.0
            end
            return mult
        end
    },

    -- HUNTER
    ["Survival / MM Hunter"] = {
        name = "Survival / MM Hunter Set",
        class = "HUNTER",
        twoPiece = "Serpent Sting duration increased by 6s.",
        fourPiece = "+100% Explosive Shot, Chimera Shot, and Kill Shot damage.",
        apply = function(state, action, mult)
            if action.name == "Explosive Shot" or action.name == "Chimera Shot" or action.name == "Kill Shot" then
                mult = mult * 2.0
            end
            return mult
        end
    },
    ["Beast Mastery Hunter"] = {
        name = "Beast Mastery Hunter Set",
        class = "HUNTER",
        twoPiece = "Bestial Wrath duration increased by 6s.",
        fourPiece = "+100% Kill Command and Pet special ability damage.",
        apply = function(state, action, mult)
            if action.name == "Kill Command" or action.name == "Aimed Shot" or action.name == "Arcane Shot" then
                mult = mult * 1.80
            end
            return mult
        end
    },

    -- SHAMAN
    ["Elemental / Enhancement Shaman"] = {
        name = "Elemental / Enhancement Shaman Set",
        class = "SHAMAN",
        twoPiece = "Flame Shock duration increased by 6s.",
        fourPiece = "+100% Lava Burst, Stormstrike, and Lightning Bolt damage.",
        apply = function(state, action, mult)
            if action.name == "Lava Burst" or action.name == "Stormstrike" or action.name == "Lightning Bolt" then
                mult = mult * 2.0
            end
            return mult
        end
    },
    ["Restoration Shaman"] = {
        name = "Restoration Shaman Set",
        class = "SHAMAN",
        twoPiece = "+20% Riptide periodic healing.",
        fourPiece = "+100% Chain Heal and Healing Wave healing; Earth Shield +4 charges.",
        apply = function(state, action, mult)
            if action.role == "heal" then
                mult = mult * 1.50
            end
            return mult
        end
    },

    -- DRUID
    ["Balance / Feral Druid"] = {
        name = "Balance / Feral Druid Set",
        class = "DRUID",
        twoPiece = "Moonfire & Insect Swarm duration increased by 6s.",
        fourPiece = "+100% Starfire, Wrath, Rip, and Ferocious Bite damage.",
        apply = function(state, action, mult)
            if action.name == "Starfire" or action.name == "Wrath" or action.name == "Rip" or action.name == "Ferocious Bite" then
                mult = mult * 2.0
            end
            return mult
        end
    },
    ["Restoration / Guardian Druid"] = {
        name = "Restoration / Guardian Druid Set",
        class = "DRUID",
        twoPiece = "+20% Rejuvenation and Lifebloom healing.",
        fourPiece = "+100% Wild Growth healing and +50% Frenzied Regeneration healing.",
        apply = function(state, action, mult)
            if action.role == "heal" then
                mult = mult * 1.50
            end
            return mult
        end
    }
}

-- =====================================================================
-- DYNAMIC PERK SETS & LIMITS DISCOVERY (Native Synastria Server Data)
-- =====================================================================

local function FormatBonusDescription(desc, amounts)
    if not desc or desc == "" then return "" end
    local text = tostring(desc)
    if amounts and type(amounts) == "table" then
        -- 1. Plural duration/tick patterns ($1D second$1s -> "6 seconds")
        for i = 0, 9 do
            local val = amounts[i + 1] or amounts[i]
            if val ~= nil then
                local numVal = tonumber(val) or 0
                local sfx = (numVal == 1) and "" or "s"
                text = string.gsub(text, "%$" .. i .. "[dD]%s*second%s*%$" .. i .. "s", tostring(numVal) .. " seconds")
                text = string.gsub(text, "%$" .. i .. "[dD]%s*tick%s*%$" .. i .. "s", tostring(numVal) .. " ticks")
                text = string.gsub(text, "%$" .. i .. "s", sfx)
            end
        end

        -- 2. Percentage patterns ($0d% -> "15%")
        for i = 0, 9 do
            local val = amounts[i + 1] or amounts[i]
            if val ~= nil then
                text = string.gsub(text, "%$" .. i .. "[dD]%%", tostring(val) .. "%%")
                text = string.gsub(text, "%$s" .. (i + 1) .. "%%", tostring(val) .. "%%")
            end
        end

        -- 3. Raw number placeholders ($0d -> "15")
        for i = 0, 9 do
            local val = amounts[i + 1] or amounts[i]
            if val ~= nil then
                text = string.gsub(text, "%$" .. i .. "[dD]", tostring(val))
                text = string.gsub(text, "%$s" .. (i + 1), tostring(val))
            end
        end
    end

    -- 4. Layout syntax markers ($n -> \n, $z -> •, $C/$c -> color tags)
    text = string.gsub(text, "%$n", "\n")
    text = string.gsub(text, "%$z", "• ")
    text = string.gsub(text, "%$C", "")
    text = string.gsub(text, "%$c", "")

    -- 5. Fallback defaults for any remaining un-substituted markers
    text = string.gsub(text, "%$0d%%", "15%%")
    text = string.gsub(text, "%$1d%%", "20%%")
    text = string.gsub(text, "%$2d%%", "25%%")
    text = string.gsub(text, "%$3d%%", "30%%")
    text = string.gsub(text, "%$1D%s*second%$1s", "6 seconds")
    text = string.gsub(text, "%$2D%s*second%$2s", "10 seconds")

    text = string.gsub(text, "\n%s*\n", "\n")
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return text
end

local function ExtractBonusString(val)
    if not val then return nil end
    if type(val) == "string" and val ~= "" then
        return FormatBonusDescription(val, nil)
    elseif type(val) == "number" and val > 0 then
        local name, _, _, _, _, _, _, _, desc = GetSpellInfo(val)
        if desc and desc ~= "" then return desc end
        if name and name ~= "" then return name end
        return "Spell ID " .. tostring(val)
    elseif type(val) == "table" then
        local desc = val.desc or val.description or val.text or val.tooltip
        local amounts = val.amounts or val.amount or val.values
        if desc and type(desc) == "string" and desc ~= "" then
            return FormatBonusDescription(desc, amounts)
        end
        if (val.spellId and tonumber(val.spellId)) or (val.spell and tonumber(val.spell)) then
            local sId = tonumber(val.spellId or val.spell)
            local name, _, _, _, _, _, _, _, sDesc = GetSpellInfo(sId)
            if sDesc and sDesc ~= "" then return sDesc end
            if name and name ~= "" then return name end
            return "Spell ID " .. tostring(sId)
        end
        for k, subVal in pairs(val) do
            if k ~= "count" and k ~= "pieces" and k ~= "threshold" and k ~= "required" and k ~= "id" then
                local res = ExtractBonusString(subVal)
                if res and res ~= "" then return res end
            end
        end
    end
    return nil
end

local function ParseSetBonuses(bonusObj)
    local twoPiece = nil
    local fourPiece = nil

    if type(bonusObj) == "string" then
        fourPiece = FormatBonusDescription(bonusObj, nil)
    elseif type(bonusObj) == "table" then
        for k, v in pairs(bonusObj) do
            if type(v) == "table" then
                local count = tonumber(v.count or v.pieces or v.perks or v.threshold or v.required or k)
                local desc = v.desc or v.description or v.text or v.tooltip
                local amounts = v.amounts or v.amount or v.values
                local txt = nil
                if desc and type(desc) == "string" and desc ~= "" then
                    txt = FormatBonusDescription(desc, amounts)
                elseif v.spellId or v.spell then
                    local sId = tonumber(v.spellId or v.spell)
                    local name, _, _, _, _, _, _, _, sDesc = GetSpellInfo(sId)
                    txt = (sDesc and sDesc ~= "") and sDesc or name
                end

                if txt and txt ~= "" then
                    if count == 2 or (not twoPiece and (count == 1 or count == 2)) then
                        twoPiece = txt
                    elseif count == 4 or (not fourPiece and (count == 3 or count == 4 or count == 5)) then
                        fourPiece = txt
                    end
                end
            elseif type(v) == "string" and v ~= "" then
                local txt = FormatBonusDescription(v, nil)
                if not twoPiece then
                    twoPiece = txt
                elseif not fourPiece then
                    fourPiece = txt
                end
            end
        end

        if not twoPiece and bonusObj[1] then
            twoPiece = ExtractBonusString(bonusObj[1])
        end
        if not fourPiece and bonusObj[2] and bonusObj[2] ~= bonusObj[1] then
            fourPiece = ExtractBonusString(bonusObj[2])
        end
    end

    return twoPiece or "2-Piece Set Bonus Active", fourPiece or "4-Piece Set Bonus Active"
end

local DYNAMIC_CLASS_PERK_SETS = {}
local DYNAMIC_PERK_SET_NAMES = {}
FC.discoveredPerkSets = {}

local function ScanServerPerkSets()
    DYNAMIC_CLASS_PERK_SETS = {}
    DYNAMIC_PERK_SET_NAMES = {}
    FC.discoveredPerkSets = {}

    local rawSets = nil
    if _G.PerkMgrSets and type(_G.PerkMgrSets) == "table" then
        rawSets = _G.PerkMgrSets
    elseif LibStub and LibStub("SynastriaCoreLib-1.0", true) then
        local coreLib = LibStub("SynastriaCoreLib-1.0", true)
        if coreLib and coreLib.Perks and type(coreLib.Perks.GetAllSets) == "function" then
            local ok, libSets = pcall(coreLib.Perks.GetAllSets)
            if ok and type(libSets) == "table" then
                rawSets = libSets
            end
        end
    end

    if rawSets and type(rawSets) == "table" then
        for setId, setObj in pairs(rawSets) do
            if type(setObj) == "table" then
                local sName = setObj.name or setObj.setName or setObj.title or ("Set " .. tostring(setId))
                DYNAMIC_PERK_SET_NAMES[setId] = sName

                -- 1. Extract perks list from setObj.perks
                local perkIdList = {}
                if setObj.perks and type(setObj.perks) == "table" then
                    for _, pId in pairs(setObj.perks) do
                        local numPId = tonumber(pId) or (type(pId) == "table" and tonumber(pId.id or pId.perkId))
                        if numPId then
                            table.insert(perkIdList, numPId)
                            DYNAMIC_CLASS_PERK_SETS[numPId] = sName
                        end
                    end
                end

                -- 2. Extract bonus details from setObj.bonus
                local twoPieceText, fourPieceText = ParseSetBonuses(setObj.bonus)

                -- 3. Determine associated class from set name or perks
                local setClass = nil
                local lowerSetName = string.lower(sName)

                if CLASS_SET_NAMES_TO_CLASS[lowerSetName] then
                    setClass = CLASS_SET_NAMES_TO_CLASS[lowerSetName]
                end

                if not setClass then
                    for clsKey in pairs(CLASS_SPELL_AND_KEYWORD_MAP) do
                        local clsNameLower = string.lower(clsKey)
                        if string.find(lowerSetName, clsNameLower, 1, true) or 
                           (clsKey == "DEATHKNIGHT" and (string.find(lowerSetName, "death knight", 1, true) or string.find(lowerSetName, "deathknight", 1, true) or string.find(lowerSetName, "dk", 1, true))) then
                            setClass = clsKey
                            break
                        end
                    end
                end

                if not setClass and #perkIdList > 0 then
                    for _, pId in ipairs(perkIdList) do
                        local pObj = _G.PerkMgrPerks and _G.PerkMgrPerks[pId]
                        if pObj and pObj.name then
                            local pLower = string.lower(pObj.name)
                            for clsKey, kws in pairs(CLASS_SPELL_AND_KEYWORD_MAP) do
                                for _, kw in ipairs(kws) do
                                    if string.find(pLower, kw, 1, true) then
                                        setClass = clsKey
                                        break
                                    end
                                end
                                if setClass then break end
                            end
                        end
                        if setClass then break end
                    end
                end

                local setRecord = {
                    id = setId,
                    name = sName,
                    class = setClass,
                    perks = perkIdList,
                    twoPiece = twoPieceText,
                    fourPiece = fourPieceText,
                    rawBonus = setObj.bonus
                }

                FC.discoveredPerkSets[sName] = setRecord
                FC.discoveredPerkSets[setId] = setRecord

                if not FC.SYNASTRIA_CLASS_SETS[sName] then
                    FC.SYNASTRIA_CLASS_SETS[sName] = {
                        name = sName,
                        class = setClass or "GENERAL",
                        twoPiece = twoPieceText,
                        fourPiece = fourPieceText
                    }
                else
                    if twoPieceText ~= "2-Piece Set Bonus Active" then FC.SYNASTRIA_CLASS_SETS[sName].twoPiece = twoPieceText end
                    if fourPieceText ~= "4-Piece Set Bonus Active" then FC.SYNASTRIA_CLASS_SETS[sName].fourPiece = fourPieceText end
                end
            elseif type(setObj) == "string" then
                DYNAMIC_PERK_SET_NAMES[setId] = setObj
            end
        end
    end
end

-- =====================================================================
-- PERK CATEGORY RESOLVER (Authoritative Native Server API Mapping)
-- =====================================================================
local NATIVE_CAT_MAP = {
    [1]  = { category = "Class",     class = "WARRIOR" },
    [2]  = { category = "Class",     class = "PALADIN" },
    [3]  = { category = "Class",     class = "HUNTER" },
    [4]  = { category = "Class",     class = "ROGUE" },
    [5]  = { category = "Class",     class = "PRIEST" },
    [6]  = { category = "Class",     class = "DEATHKNIGHT" },
    [7]  = { category = "Class",     class = "SHAMAN" },
    [8]  = { category = "Class",     class = "MAGE" },
    [9]  = { category = "Class",     class = "WARLOCK" },
    [11] = { category = "Class",     class = "DRUID" },
    [15] = { category = "Offensive", class = "ALL" },
    [16] = { category = "Defensive", class = "ALL" },
    [17] = { category = "Support",   class = "ALL" },
    [18] = { category = "Utility",   class = "ALL" },
    [19] = { category = "Misc",      class = "ALL" },
    ["1"]  = { category = "Class",     class = "WARRIOR" },
    ["2"]  = { category = "Class",     class = "PALADIN" },
    ["3"]  = { category = "Class",     class = "HUNTER" },
    ["4"]  = { category = "Class",     class = "ROGUE" },
    ["5"]  = { category = "Class",     class = "PRIEST" },
    ["6"]  = { category = "Class",     class = "DEATHKNIGHT" },
    ["7"]  = { category = "Class",     class = "SHAMAN" },
    ["8"]  = { category = "Class",     class = "MAGE" },
    ["9"]  = { category = "Class",     class = "WARLOCK" },
    ["11"] = { category = "Class",     class = "DRUID" },
    ["15"] = { category = "Offensive", class = "ALL" },
    ["16"] = { category = "Defensive", class = "ALL" },
    ["17"] = { category = "Support",   class = "ALL" },
    ["18"] = { category = "Utility",   class = "ALL" },
    ["19"] = { category = "Misc",      class = "ALL" },
    ["Off"] = { category = "Offensive", class = "ALL" },
    ["Def"] = { category = "Defensive", class = "ALL" },
    ["Sup"] = { category = "Support",   class = "ALL" },
    ["Uti"] = { category = "Utility",   class = "ALL" },
    ["Cla"] = { category = "Class",     class = "ALL" },
    ["Clb"] = { category = "Class",     class = "ALL" },
    ["Mis"] = { category = "Misc",      class = "ALL" },
    ["Offensive"] = { category = "Offensive", class = "ALL" },
    ["Defensive"] = { category = "Defensive", class = "ALL" },
    ["Support"]   = { category = "Support",   class = "ALL" },
    ["Utility"]   = { category = "Utility",   class = "ALL" },
    ["Class"]     = { category = "Class",     class = "ALL" },
    ["Misc"]      = { category = "Misc",      class = "ALL" },
}

local function ResolvePerkCategory(perkId, perkName, perkDesc, perkObj)
    perkId = tonumber(perkId) or 0
    local lowerName = string.lower(perkName or "")
    local lowerDesc = string.lower(perkDesc or "")

    -- 1. Native Server Category field (perkObj.cat) from authoritative table
    if perkObj and type(perkObj) == "table" then
        if perkObj.cat and NATIVE_CAT_MAP[perkObj.cat] then
            return NATIVE_CAT_MAP[perkObj.cat].category
        end
        if perkObj.category and NATIVE_CAT_MAP[perkObj.category] then
            return NATIVE_CAT_MAP[perkObj.category].category
        end
    end

    if perkId > 0 and _G.PerkMgrPerks and _G.PerkMgrPerks[perkId] then
        local rawP = _G.PerkMgrPerks[perkId]
        if rawP and rawP.cat and NATIVE_CAT_MAP[rawP.cat] then
            return NATIVE_CAT_MAP[rawP.cat].category
        end
        if rawP and rawP.category and NATIVE_CAT_MAP[rawP.category] then
            return NATIVE_CAT_MAP[rawP.category].category
        end
    end

    -- 2. Explicit Overrides Table
    if EXPLICIT_PERK_CATEGORIES[perkId] then
        return EXPLICIT_PERK_CATEGORIES[perkId]
    end

    if EXPLICIT_PERK_CATEGORIES[perkName] then
        return EXPLICIT_PERK_CATEGORIES[perkName]
    end

    -- 3. Case-insensitive lookup in explicit categories table
    for name, cat in pairs(EXPLICIT_PERK_CATEGORIES) do
        if type(name) == "string" and string.lower(name) == lowerName then
            return cat
        end
    end

    -- 4. Dynamic Server Set Membership Check (If perk belongs to any Perk Set, it is a Class Perk!)
    if DYNAMIC_CLASS_PERK_SETS[perkId] or (perkObj and type(perkObj) == "table" and (perkObj.setId or perkObj.set or perkObj.perkSet)) then
        return "Class"
    end

    -- 6. Class Perks Heuristic Matcher (Covers all 10 classes and 30 specs)
    -- Any perk modifying specific class abilities, spells, talents, or resources
    if -- Death Knight
       string.find(lowerName, "unholy", 1, true) or string.find(lowerName, "scourge strike", 1, true) or
       string.find(lowerName, "frost strike", 1, true) or string.find(lowerName, "howling blast", 1, true) or
       string.find(lowerName, "death coil", 1, true) or string.find(lowerName, "death strike", 1, true) or
       string.find(lowerName, "obliterate", 1, true) or string.find(lowerName, "blood strike", 1, true) or
       string.find(lowerName, "blood boil", 1, true) or string.find(lowerName, "pestilence", 1, true) or
       string.find(lowerName, "plaguebringer", 1, true) or string.find(lowerName, "epidemic", 1, true) or
       string.find(lowerName, "runic power", 1, true) or string.find(lowerName, "death rune", 1, true) or
       string.find(lowerName, "ghoul", 1, true) or string.find(lowerName, "gargoyle", 1, true) or
       string.find(lowerName, "army of the dead", 1, true) or string.find(lowerName, "rune tap", 1, true) or
       string.find(lowerName, "bone shield", 1, true) or string.find(lowerName, "vampiric blood", 1, true) or
       string.find(lowerName, "anti-magic", 1, true) or string.find(lowerName, "dancing rune", 1, true) or
       string.find(lowerName, "heart strike", 1, true) or string.find(lowerName, "corpse explosion", 1, true) or
       string.find(lowerName, "death and decay", 1, true) or string.find(lowerName, "chains of ice", 1, true) or
       -- Mage
       string.find(lowerName, "fireball", 1, true) or string.find(lowerName, "pyroblast", 1, true) or
       string.find(lowerName, "living bomb", 1, true) or string.find(lowerName, "flamestrike", 1, true) or
       string.find(lowerName, "meteor shower", 1, true) or string.find(lowerName, "spreading flames", 1, true) or
       string.find(lowerName, "slow burn", 1, true) or string.find(lowerName, "explosive impact", 1, true) or
       string.find(lowerName, "empowered flames", 1, true) or string.find(lowerName, "frostbolt", 1, true) or
       string.find(lowerName, "ice lance", 1, true) or string.find(lowerName, "deep freeze", 1, true) or
       string.find(lowerName, "arcane blast", 1, true) or string.find(lowerName, "arcane missiles", 1, true) or
       string.find(lowerName, "arcane barrage", 1, true) or string.find(lowerName, "combustion", 1, true) or
       string.find(lowerName, "icy veins", 1, true) or string.find(lowerName, "arcane power", 1, true) or
       -- Paladin
       string.find(lowerName, "crusader strike", 1, true) or string.find(lowerName, "divine storm", 1, true) or
       string.find(lowerName, "judgement", 1, true) or string.find(lowerName, "holy shock", 1, true) or
       string.find(lowerName, "avenging wrath", 1, true) or string.find(lowerName, "hammer of wrath", 1, true) or
       string.find(lowerName, "consecration", 1, true) or string.find(lowerName, "shield of the righteous", 1, true) or
       string.find(lowerName, "avenger's shield", 1, true) or string.find(lowerName, "hammer of the righteous", 1, true) or
       string.find(lowerName, "sacred shield", 1, true) or string.find(lowerName, "beacon of light", 1, true) or
       -- Warrior
       string.find(lowerName, "mortal strike", 1, true) or string.find(lowerName, "bloodthirst", 1, true) or
       string.find(lowerName, "whirlwind", 1, true) or string.find(lowerName, "shield slam", 1, true) or
       string.find(lowerName, "devastate", 1, true) or string.find(lowerName, "revenge", 1, true) or
       string.find(lowerName, "overpower", 1, true) or string.find(lowerName, "slam", 1, true) or
       string.find(lowerName, "execute", 1, true) or string.find(lowerName, "shockwave", 1, true) or
       string.find(lowerName, "heroic strike", 1, true) or string.find(lowerName, "cleave", 1, true) or
       -- Warlock
       string.find(lowerName, "chaos bolt", 1, true) or string.find(lowerName, "conflagrate", 1, true) or
       string.find(lowerName, "incinerate", 1, true) or string.find(lowerName, "immolate", 1, true) or
       string.find(lowerName, "haunt", 1, true) or string.find(lowerName, "unstable affliction", 1, true) or
       string.find(lowerName, "corruption", 1, true) or string.find(lowerName, "shadow bolt", 1, true) or
       string.find(lowerName, "soul fire", 1, true) or string.find(lowerName, "seed of corruption", 1, true) or
       string.find(lowerName, "metamorphosis", 1, true) or string.find(lowerName, "felguard", 1, true) or
       -- Priest
       string.find(lowerName, "mind blast", 1, true) or string.find(lowerName, "mind flay", 1, true) or
       string.find(lowerName, "vampiric touch", 1, true) or string.find(lowerName, "shadowform", 1, true) or
       string.find(lowerName, "penance", 1, true) or string.find(lowerName, "power word: shield", 1, true) or
       string.find(lowerName, "circle of healing", 1, true) or string.find(lowerName, "prayer of healing", 1, true) or
       string.find(lowerName, "dispersion", 1, true) or string.find(lowerName, "shadow word", 1, true) or
       -- Rogue
       string.find(lowerName, "mutilate", 1, true) or string.find(lowerName, "sinister strike", 1, true) or
       string.find(lowerName, "backstab", 1, true) or string.find(lowerName, "envenom", 1, true) or
       string.find(lowerName, "eviscerate", 1, true) or string.find(lowerName, "killing spree", 1, true) or
       string.find(lowerName, "shadow dance", 1, true) or string.find(lowerName, "blade flurry", 1, true) or
       string.find(lowerName, "slice and dice", 1, true) or string.find(lowerName, "hunger for blood", 1, true) or
       -- Hunter
       string.find(lowerName, "explosive shot", 1, true) or string.find(lowerName, "chimera shot", 1, true) or
       string.find(lowerName, "aimed shot", 1, true) or string.find(lowerName, "kill shot", 1, true) or
       string.find(lowerName, "black arrow", 1, true) or string.find(lowerName, "serpent sting", 1, true) or
       string.find(lowerName, "bestial wrath", 1, true) or string.find(lowerName, "kill command", 1, true) or
       string.find(lowerName, "lock and load", 1, true) or string.find(lowerName, "steady shot", 1, true) or
       -- Shaman
       string.find(lowerName, "lava burst", 1, true) or string.find(lowerName, "stormstrike", 1, true) or
       string.find(lowerName, "lava lash", 1, true) or string.find(lowerName, "chain lightning", 1, true) or
       string.find(lowerName, "lightning bolt", 1, true) or string.find(lowerName, "earth shock", 1, true) or
       string.find(lowerName, "flame shock", 1, true) or string.find(lowerName, "riptide", 1, true) or
       string.find(lowerName, "chain heal", 1, true) or string.find(lowerName, "feral spirit", 1, true) or
       string.find(lowerName, "elemental mastery", 1, true) or string.find(lowerName, "shamanistic rage", 1, true) or
       -- Druid
       string.find(lowerName, "starfire", 1, true) or string.find(lowerName, "wrath", 1, true) or
       string.find(lowerName, "moonfire", 1, true) or string.find(lowerName, "starfall", 1, true) or
       string.find(lowerName, "insect swarm", 1, true) or string.find(lowerName, "eclipse", 1, true) or
       string.find(lowerName, "shred", 1, true) or string.find(lowerName, "rip", 1, true) or
       string.find(lowerName, "ferocious bite", 1, true) or string.find(lowerName, "mangle", 1, true) or
       string.find(lowerName, "savage roar", 1, true) or string.find(lowerName, "swipe", 1, true) or
       string.find(lowerName, "rejuvenation", 1, true) or string.find(lowerName, "wild growth", 1, true) or
       string.find(lowerName, "lifebloom", 1, true) or string.find(lowerName, "swiftmend", 1, true) then
        return "Class"
    end

    -- 7. Semantic Fallback by Description & Name
    if string.find(lowerDesc, "absorb", 1, true) or string.find(lowerDesc, "damage taken", 1, true) or 
       string.find(lowerDesc, "armor", 1, true) or string.find(lowerDesc, "health", 1, true) or 
       string.find(lowerDesc, "resilience", 1, true) or string.find(lowerDesc, "dodge", 1, true) or 
       string.find(lowerDesc, "parry", 1, true) or string.find(lowerDesc, "block", 1, true) or 
       string.find(lowerDesc, "stamina", 1, true) or string.find(lowerName, "hardening", 1, true) or 
       string.find(lowerName, "shielding", 1, true) or string.find(lowerName, "barrier", 1, true) or
       string.find(lowerName, "defense", 1, true) or string.find(lowerName, "defensive", 1, true) then
        return "Defensive"
    elseif string.find(lowerDesc, "damage", 1, true) or string.find(lowerDesc, "critical strike", 1, true) or 
           string.find(lowerDesc, "crit", 1, true) or string.find(lowerDesc, "spell power", 1, true) or 
           string.find(lowerDesc, "attack power", 1, true) or string.find(lowerDesc, "haste", 1, true) or 
           string.find(lowerDesc, "penetration", 1, true) or string.find(lowerName, "vengeance", 1, true) or 
           string.find(lowerName, "precision", 1, true) or string.find(lowerName, "outburst", 1, true) or 
           string.find(lowerName, "offense", 1, true) or string.find(lowerName, "offensive", 1, true) then
        return "Offensive"
    elseif string.find(lowerDesc, "heal", 1, true) or string.find(lowerDesc, "party", 1, true) or 
           string.find(lowerDesc, "raid", 1, true) or string.find(lowerDesc, "mana", 1, true) or 
           string.find(lowerDesc, "allies", 1, true) or string.find(lowerName, "coherence", 1, true) or 
           string.find(lowerName, "prevention", 1, true) or string.find(lowerName, "support", 1, true) then
        return "Support"
    elseif string.find(lowerDesc, "movement", 1, true) or string.find(lowerDesc, "speed", 1, true) or 
           string.find(lowerDesc, "range", 1, true) or string.find(lowerDesc, "cooldown", 1, true) or 
           string.find(lowerName, "attunement", 1, true) or string.find(lowerName, "scouting", 1, true) or 
           string.find(lowerName, "caution", 1, true) or string.find(lowerName, "utility", 1, true) then
        return "Utility"
    end

    return "Misc"
end

-- =====================================================================
-- SYNASTRIA NATIVE CUSTOM ITEM & ATTUNEMENT SCANNER
-- =====================================================================
function FC:GetSynastriaItemData(itemId)
    if not itemId then return nil end
    itemId = tonumber(itemId) or 0

    local data = {
        itemId = itemId,
        isMythic = false,
        hasRandomAffix = false,
        canRollResist = false,
        hasBaseResist = false,
        attuneProgress = 0,
        forgeTier = 0,
        forgeName = "Normal",
        isAttuned = false,
        canAttune = false
    }

    -- 1. Query GetItemTagsCustom(itemId)
    if type(GetItemTagsCustom) == "function" then
        local ok, tag1, tag2 = pcall(GetItemTagsCustom, itemId)
        if ok and tag1 then
            tag1 = tag1 or 0
            tag2 = tag2 or 0
            if bit and bit.band then
                data.isMythic = (bit.band(tag1, 0x80) ~= 0)
                data.hasRandomAffix = (bit.band(tag2, 1) ~= 0)
                data.canRollResist = (bit.band(tag2, 2) ~= 0)
                data.hasBaseResist = (bit.band(tag2, 4) ~= 0)
            end
        end
    end

    -- 2. Query GetItemAttuneProgress(itemId)
    if type(GetItemAttuneProgress) == "function" then
        local ok, prog = pcall(GetItemAttuneProgress, itemId)
        if ok and prog then
            data.attuneProgress = tonumber(prog) or 0
        end
    end

    -- 3. Query GetItemAttuneForge(itemId)
    if type(GetItemAttuneForge) == "function" then
        local ok, forge = pcall(GetItemAttuneForge, itemId)
        if ok and forge then
            data.forgeTier = tonumber(forge) or 0
            data.forgeName = FC.FORGE_TIERS[data.forgeTier] or "Normal"
        end
    end

    -- 4. Query HasAttunedAnyVariantOfItem(itemId)
    if type(HasAttunedAnyVariantOfItem) == "function" then
        local ok, attuned = pcall(HasAttunedAnyVariantOfItem, itemId)
        if ok and attuned then
            data.isAttuned = (attuned == true or attuned == 1)
        end
    end

    -- 5. Query CanAttuneItemHelper(itemId)
    if type(CanAttuneItemHelper) == "function" then
        local ok, can = pcall(CanAttuneItemHelper, itemId)
        if ok and can then
            data.canAttune = (can == 1 or can == true)
        end
    end

    return data
end

-- =====================================================================
-- SCAN EQUIPPED ATTUNEMENTS & FORGE GEAR (Phase 4)
-- =====================================================================
FC._prevAttunedSlots = FC._prevAttunedSlots or {}

function FC:ScanEquippedAttunements()
    local attunedCount = 0
    local forgeCounts = { Titanforged = 0, Warforged = 0, Lightforged = 0 }
    local gearList = {}

    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
            if itemId then
                local data = self:GetSynastriaItemData(itemId)
                if data then
                    data.slot = slot
                    data.link = itemLink
                    table.insert(gearList, data)

                    local isNowAttuned = (data.isAttuned or (data.attuneProgress and data.attuneProgress >= 100))
                    if isNowAttuned then
                        attunedCount = attunedCount + 1
                        self._prevAttunedSlots[slot] = true
                    else
                        self._prevAttunedSlots[slot] = false
                    end

                    if data.forgeName and forgeCounts[data.forgeName] then
                        forgeCounts[data.forgeName] = forgeCounts[data.forgeName] + 1
                    end
                end
            end
        else
            self._prevAttunedSlots[slot] = nil
        end
    end

    self.extState.attunementGear = gearList
    self.extState.totalAttunedItems = attunedCount
    self.extState.forgeCounts = forgeCounts
end



-- =====================================================================
-- NATIVE SERVER API SCANNER & REFRESH
-- =====================================================================
function FC:RefreshExtState()
    ScanServerPerkSets()

    local hasSynastria = false
    local activePerks = {}
    local catCounts = {
        Offensive = 0,
        Defensive = 0,
        Support = 0,
        Utility = 0,
        Class = 0,
        Misc = 0
    }
    local categories = {
        Offensive = {},
        Defensive = {},
        Support = {},
        Utility = {},
        Class = {},
        Misc = {}
    }

    local detectedClassSetCounts = {}

    -- 1. Check Native Synastria Functions
    local hasNativeGetPerkActive = (type(GetPerkActive) == "function")

    -- 2. Fast Path: Load directly from Precompiled Perk Database (PerksData.lua / perkexport.csv)
    if FC.PERK_DATABASE and next(FC.PERK_DATABASE) then
        hasSynastria = true
        for id, perk in pairs(FC.PERK_DATABASE) do
            local numId = tonumber(id) or perk.id or 0
            if numId > 0 then
                local isActive = false
                if hasNativeGetPerkActive then
                    local ok, active = pcall(GetPerkActive, numId)
                    if ok and (active == true or active == 1) then
                        isActive = true
                    end
                elseif perk.active == true or perk.isActive == true then
                    isActive = true
                end

                -- Exact user category from perkexport.csv
                local cat = perk.category or "Misc"
                local classSet = (perk.setName and perk.setName ~= "" and perk.setName) or DYNAMIC_CLASS_PERK_SETS[numId] or CLASS_PERK_SETS[numId] or CLASS_PERK_SETS[perk.name]

                local rawServerIcon = nil
                if _G.PerkMgrPerks and _G.PerkMgrPerks[numId] and type(_G.PerkMgrPerks[numId]) == "table" then
                    rawServerIcon = _G.PerkMgrPerks[numId].icon or _G.PerkMgrPerks[numId].texture
                end

                local entry = {
                    id = numId,
                    name = perk.name,
                    spellId = perk.spellId or perk.spell_id,
                    spell_id = perk.spellId or perk.spell_id,
                    icon = FormatPerkIcon(rawServerIcon or perk.icon, perk.spellId or perk.spell_id, perk.name, numId, perk),
                    category = cat,
                    category_name = cat,
                    description = perk.description or "",
                    active = isActive,
                    setName = classSet,
                    set_name = classSet,
                    cat = perk.cat,
                    assignedClass = perk.assignedClass or perk.assigned_class or "ALL",
                    assigned_class = perk.assignedClass or perk.assigned_class or "ALL"
                }

                categories[cat] = categories[cat] or {}
                table.insert(categories[cat], entry)

                if isActive then
                    activePerks[numId] = entry
                    catCounts[cat] = (catCounts[cat] or 0) + 1

                    if classSet then
                        detectedClassSetCounts[classSet] = (detectedClassSetCounts[classSet] or 0) + 1
                    end
                end
            end
        end
    -- 2b. Fallback: Inspect PerkMgrPerks master table if database not loaded
    elseif _G.PerkMgrPerks and type(_G.PerkMgrPerks) == "table" then
        hasSynastria = true
        for id, perk in pairs(_G.PerkMgrPerks) do
            if type(perk) == "table" and perk.name then
                local numId = tonumber(id) or 0
                local pName = perk.name
                local rawDesc = perk.desc or perk.description or perk.tooltip or perk.text or ""
                local cat = ResolvePerkCategory(numId, pName, rawDesc, perk)

                local isActive = false
                if hasNativeGetPerkActive then
                    local ok, active = pcall(GetPerkActive, numId)
                    if ok and (active == true or active == 1) then
                        isActive = true
                    end
                elseif perk.active == true or perk.isActive == true then
                    isActive = true
                end

                local classSet = DYNAMIC_CLASS_PERK_SETS[numId]
                if not classSet and perk and type(perk) == "table" then
                    local sId = perk.setId or perk.set or perk.perkSet
                    if sId and DYNAMIC_PERK_SET_NAMES[sId] then
                        classSet = DYNAMIC_PERK_SET_NAMES[sId]
                    end
                end
                if not classSet then
                    classSet = CLASS_PERK_SETS[numId] or CLASS_PERK_SETS[pName]
                end

                local realSpellId = nil
                local rawSpell = perk and (perk.spellId or perk.spellID or perk.spell_id or perk.spell)
                if rawSpell and tonumber(rawSpell) and tonumber(rawSpell) > 0 then
                    realSpellId = tonumber(rawSpell)
                end

                local formattedDesc = self:FormatPerkDescription(rawDesc, realSpellId, pName, numId, perk)

                local entry = {
                    id = numId,
                    name = pName,
                    spellId = realSpellId,
                    spell_id = realSpellId,
                    icon = FormatPerkIcon(perk.icon or perk.texture or perk.iconPath or perk.spellIcon, realSpellId, pName, numId, perk),
                    category = cat,
                    category_name = cat,
                    description = formattedDesc,
                    active = isActive,
                    setName = classSet,
                    set_name = classSet,
                    levels = perk.levels,
                    cat = perk.cat
                }
                entry.assignedClass = FC:GetPerkAssignedClass(entry) or "ALL"
                entry.assigned_class = entry.assignedClass

                table.insert(categories[cat], entry)

                if isActive then
                    activePerks[numId] = entry
                    catCounts[cat] = (catCounts[cat] or 0) + 1

                    if classSet then
                        detectedClassSetCounts[classSet] = (detectedClassSetCounts[classSet] or 0) + 1
                    end
                end
            end
        end
    end

    -- 3. Check SynastriaCoreLib via LibStub
    if LibStub and LibStub("SynastriaCoreLib-1.0", true) then
        hasSynastria = true
        self.extState.hasCoreLib = true
        local coreLib = LibStub("SynastriaCoreLib-1.0", true)
        if coreLib and coreLib.Perks and type(coreLib.Perks.GetPerks) == "function" then
            local libPerks = coreLib.Perks:GetPerks() or {}
            for id, perk in pairs(libPerks) do
                local numId = tonumber(id) or (type(perk) == "table" and tonumber(perk.id)) or 0
                if numId > 0 and type(perk) == "table" and perk.name and not activePerks[numId] then
                    local pName = perk.name
                    local rawDesc = perk.desc or perk.description or perk.tooltip or perk.text or ""
                    local cat = ResolvePerkCategory(numId, pName, rawDesc, perk)
                    local isActive = (type(coreLib.Perks.IsPerkActive) == "function" and coreLib.Perks:IsPerkActive(numId)) or (hasNativeGetPerkActive and GetPerkActive(numId)) or perk.active == true

                    local classSet = DYNAMIC_CLASS_PERK_SETS[numId]
                    if not classSet and perk and type(perk) == "table" then
                        local sId = perk.setId or perk.set or perk.perkSet
                        if sId and DYNAMIC_PERK_SET_NAMES[sId] then
                            classSet = DYNAMIC_PERK_SET_NAMES[sId]
                        end
                    end
                    if not classSet then
                        classSet = CLASS_PERK_SETS[numId] or CLASS_PERK_SETS[pName]
                    end

                    local realLibSpellId = nil
                    local rawLibSpell = perk and (perk.spellId or perk.spellID or perk.spell_id or perk.spell)
                    if rawLibSpell and tonumber(rawLibSpell) and tonumber(rawLibSpell) > 0 then
                        realLibSpellId = tonumber(rawLibSpell)
                    end

                    local formattedDesc = self:FormatPerkDescription(rawDesc, realLibSpellId, pName, numId, perk)

                    local entry = {
                        id = numId,
                        name = pName,
                        spellId = realLibSpellId,
                        icon = FormatPerkIcon(perk.icon or perk.texture or perk.iconPath or perk.spellIcon, realLibSpellId, pName, numId, perk),
                        category = cat,
                        description = formattedDesc,
                        active = isActive,
                        setName = classSet,
                        levels = perk.levels,
                        cat = perk.cat
                    }
                    entry.assignedClass = FC:GetPerkAssignedClass(entry)
                    table.insert(categories[cat], entry)
                    if isActive then
                        activePerks[numId] = entry
                        catCounts[cat] = (catCounts[cat] or 0) + 1

                        if classSet then
                            detectedClassSetCounts[classSet] = (detectedClassSetCounts[classSet] or 0) + 1
                        end
                    end
                end
            end
        end
    end

    -- 4. Dynamic Talent & Spell Prerequisites Indexing
    local talentToPerks = {}
    local spellToPerks = {}
    local perkPrerequisites = {}

    for numId, entry in pairs(activePerks) do
        local targets, reqs = self:ExtractPerkPrerequisites(entry)
        entry.targets = targets
        entry.prerequisites = reqs
        perkPrerequisites[numId] = reqs

        for tName in pairs(reqs) do
            talentToPerks[tName] = talentToPerks[tName] or {}
            table.insert(talentToPerks[tName], entry)
        end
        for sName in pairs(targets) do
            spellToPerks[sName] = spellToPerks[sName] or {}
            table.insert(spellToPerks[sName], entry)
        end
    end

    -- 5. Scan Equipped Attunements
    self:ScanEquippedAttunements()

    -- 6. Detect Dominant Active Class Perk Set for Current Character Class
    local pClass = FC.playerClass or (UnitClass and select(2, UnitClass("player"))) or "WARRIOR"
    local dominantSet = nil
    local maxSetCount = 0
    for setName, count in pairs(detectedClassSetCounts) do
        local setDef = FC.SYNASTRIA_CLASS_SETS[setName]
        local isMatchingClass = (setDef and setDef.class == pClass) or (not setDef)
        if isMatchingClass and count > maxSetCount then
            maxSetCount = count
            dominantSet = setName
        end
    end

    if dominantSet and maxSetCount > 0 then
        self.extState.activeClassSet = dominantSet
        self.extState.classSetCount = maxSetCount
        if FC.db then
            FC.db.synastriaClassSet = dominantSet
            FC.db.synastriaClassSetCount = maxSetCount
        end
    else
        local defaultSetForClass = nil
        if pClass == "MAGE" then defaultSetForClass = "Fire Mage"
        elseif pClass == "DEATHKNIGHT" then defaultSetForClass = "Frost / Unholy DK"
        elseif pClass == "PALADIN" then defaultSetForClass = "Retribution Paladin"
        elseif pClass == "WARRIOR" then defaultSetForClass = "Arms / Fury Warrior"
        elseif pClass == "WARLOCK" then defaultSetForClass = "Destruction Warlock"
        elseif pClass == "ROGUE" then defaultSetForClass = "Assassination / Combat Rogue"
        elseif pClass == "HUNTER" then defaultSetForClass = "Survival / MM Hunter"
        elseif pClass == "SHAMAN" then defaultSetForClass = "Elemental / Enhancement Shaman"
        elseif pClass == "DRUID" then defaultSetForClass = "Balance / Feral Druid"
        elseif pClass == "PRIEST" then defaultSetForClass = "Shadow Priest"
        end

        local savedSet = FC.db and FC.db.synastriaClassSet
        if savedSet and FC.SYNASTRIA_CLASS_SETS[savedSet] and FC.SYNASTRIA_CLASS_SETS[savedSet].class == pClass then
            self.extState.activeClassSet = savedSet
            self.extState.classSetCount = (FC.db and FC.db.synastriaClassSetCount) or (catCounts.Class or 0)
        elseif defaultSetForClass then
            self.extState.activeClassSet = defaultSetForClass
            self.extState.classSetCount = catCounts.Class or 0
            if FC.db then
                FC.db.synastriaClassSet = defaultSetForClass
                FC.db.synastriaClassSetCount = catCounts.Class or 0
            end
        else
            self.extState.activeClassSet = nil
            self.extState.classSetCount = 0
        end
    end

    self.extState.synastriaDetected = hasSynastria
    self.extState.activePerks = activePerks
    self.extState.activePerkCounts = catCounts
    self.extState.categories = categories
    self.extState.talentToPerks = talentToPerks
    self.extState.spellToPerks = spellToPerks
    self.extState.perkPrerequisites = perkPrerequisites
end

-- Specific active spell/talent abilities that can be modified by perks
local KNOWN_TALENT_ABILITIES = {
    -- Mage
    ["Living Bomb"] = true,
    ["Blast Wave"] = true,
    ["Dragon's Breath"] = true,
    ["Firestarter"] = true,
    ["Combustion"] = true,
    ["Pyroblast"] = true,
    ["Deep Freeze"] = true,
    ["Icy Veins"] = true,
    ["Cold Snap"] = true,
    ["Arcane Power"] = true,
    ["Presence of Mind"] = true,
    ["Focus Magic"] = true,
    -- Paladin
    ["Holy Shock"] = true,
    ["Divine Storm"] = true,
    ["Crusader Strike"] = true,
    ["Beacon of Light"] = true,
    ["Avenging Wrath"] = true,
    ["Holy Shield"] = true,
    -- Warrior
    ["Mortal Strike"] = true,
    ["Bloodthirst"] = true,
    ["Shield Slam"] = true,
    ["Shockwave"] = true,
    ["Bladestorm"] = true,
    ["Death Wish"] = true,
    -- Warlock
    ["Haunt"] = true,
    ["Chaos Bolt"] = true,
    ["Unstable Affliction"] = true,
    ["Metamorphosis"] = true,
    ["Shadowburn"] = true,
    -- DK
    ["Howling Blast"] = true,
    ["Scourge Strike"] = true,
    ["Heart Strike"] = true,
    ["Dancing Rune Weapon"] = true,
    ["Corpse Explosion"] = true,
    -- Priest
    ["Vampiric Touch"] = true,
    ["Mind Flay"] = true,
    ["Penance"] = true,
    ["Dispersion"] = true,
    ["Shadowform"] = true,
    -- Druid
    ["Starfall"] = true,
    ["Typhoon"] = true,
    ["Wild Growth"] = true,
    ["Mangle"] = true,
    ["Berserk"] = true,
    -- Rogue
    ["Mutilate"] = true,
    ["Killing Spree"] = true,
    ["Shadowstep"] = true,
    ["Adrenaline Rush"] = true,
    ["Hunger for Blood"] = true,
    -- Hunter
    ["Explosive Shot"] = true,
    ["Chimera Shot"] = true,
    ["Black Arrow"] = true,
    ["Silencing Shot"] = true,
    ["Bestial Wrath"] = true,
    -- Shaman
    ["Lava Lash"] = true,
    ["Stormstrike"] = true,
    ["Riptide"] = true,
    ["Thunderstorm"] = true,
    ["Feral Spirit"] = true
}

function FC:ExtractPerkPrerequisites(perk)
    local targets = {}
    local reqs = {}
    if not perk then return targets, reqs end

    local name = perk.name or ""
    local desc = perk.description or perk.tooltip or perk.text or ""
    local lowerDesc = string.lower(desc)

    -- 1. Direct Server Fields (if present)
    if perk.reqSpell and perk.reqSpell ~= "" then reqs[perk.reqSpell] = true; targets[perk.reqSpell] = true end
    if perk.reqTalent and perk.reqTalent ~= "" then reqs[perk.reqTalent] = true; targets[perk.reqTalent] = true end
    if perk.spellName and perk.spellName ~= "" then targets[perk.spellName] = true end

    -- 2. Explicit "Requires [Talent/Spell]" in description
    local reqMatch = string.match(desc, "[Rr]equires%s+([%w%s:']-)[%.,\n]")
    if reqMatch and reqMatch ~= "" then
        reqMatch = string.gsub(reqMatch, "^%s*(.-)%s*$", "%1")
        if reqMatch ~= "" and not string.find(string.lower(reqMatch), "level") and not string.find(string.lower(reqMatch), "perk") then
            reqs[reqMatch] = true
            targets[reqMatch] = true
        end
    end

    -- 3. Explicit Synastria Class Perk Talent Links
    if name == "Explosive Impact" or string.find(lowerDesc, "living bomb", 1, true) then
        targets["Living Bomb"] = true; reqs["Living Bomb"] = true
    end
    if name == "Spreading Flames" then
        targets["Living Bomb"] = true; reqs["Living Bomb"] = true
        targets["Ignite"] = true; reqs["Ignite"] = true
    end
    if name == "Augmented Barriers" or (string.find(lowerDesc, "barrier", 1, true) and string.find(lowerDesc, "absorb", 1, true)) then
        targets["Absorb Shields (Warding, Wards, Shields)"] = true
        -- Augmented Barriers scales any shield or absorb (e.g. Warding perk, Fire Ward, Frost Ward, Mana Shield, Ice Barrier, etc.) and does not require Ice Barrier
    end
    if string.find(lowerDesc, "blast wave", 1, true) then
        targets["Blast Wave"] = true; reqs["Blast Wave"] = true
    end
    if string.find(lowerDesc, "dragon's breath", 1, true) or string.find(lowerDesc, "dragons breath", 1, true) then
        targets["Dragon's Breath"] = true; reqs["Dragon's Breath"] = true
    end
    if string.find(lowerDesc, "firestarter", 1, true) then
        targets["Firestarter"] = true; reqs["Firestarter"] = true
    end

    -- 4. Check for specific known activated ability mentions in the description (NOT matching against perk title)
    for abilityName in pairs(KNOWN_TALENT_ABILITIES) do
        local lowerA = string.lower(abilityName)
        local pattern = "%f[%a]" .. string.gsub(lowerA, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") .. "%f[%A]"
        if string.find(lowerDesc, pattern) then
            if string.find(lowerDesc, "your " .. lowerA, 1, true) or
               string.find(lowerDesc, "when " .. lowerA, 1, true) or
               string.find(lowerDesc, "of " .. lowerA, 1, true) or
               string.find(lowerDesc, lowerA .. " cooldown", 1, true) or
               string.find(lowerDesc, lowerA .. " damage", 1, true) or
               string.find(lowerDesc, lowerA .. " critical", 1, true) or
               string.find(lowerDesc, lowerA .. " now", 1, true) or
               string.find(lowerDesc, lowerA .. " deals", 1, true) or
               string.find(lowerDesc, lowerA .. " absorbs", 1, true) or
               string.find(lowerDesc, "requires " .. lowerA, 1, true) then
                targets[abilityName] = true
                reqs[abilityName] = true
            end
        end
    end

    return targets, reqs
end

-- =====================================================================
-- DYNAMIC PERK DESCRIPTION FORMATTER (Resolves $0d, $n, $z placeholders)
-- =====================================================================
local hiddenTooltip = CreateFrame("GameTooltip", "FlowCorePerkHiddenTooltip", UIParent, "GameTooltipTemplate")
hiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")

function FC:FormatPerkDescription(desc, spellId, perkName, perkId, perkObj)
    if not desc or desc == "" then return "" end

    local text = tostring(desc)

    -- Extract amounts from perk.levels if present
    local amounts = nil
    if perkObj and type(perkObj) == "table" then
        if perkObj.levels and type(perkObj.levels) == "table" then
            local firstLvl = perkObj.levels[1] or perkObj.levels[0] or perkObj.levels
            if type(firstLvl) == "table" then
                amounts = firstLvl.amounts or firstLvl
            end
        end
        if not amounts and perkObj.amounts then
            amounts = perkObj.amounts
        end
    end

    if (not amounts) and perkId and _G.PerkMgrPerks and _G.PerkMgrPerks[perkId] then
        local rawP = _G.PerkMgrPerks[perkId]
        if rawP.levels and type(rawP.levels) == "table" then
            local firstLvl = rawP.levels[1] or rawP.levels[0] or rawP.levels
            if type(firstLvl) == "table" then
                amounts = firstLvl.amounts or firstLvl
            end
        end
        if not amounts and rawP.amounts then
            amounts = rawP.amounts
        end
    end

    -- If amounts are available, substitute them dynamically!
    if amounts and type(amounts) == "table" then
        for i = 0, 9 do
            local val = amounts[i + 1] or amounts[i]
            if val ~= nil then
                local numVal = tonumber(val) or 0
                local sfx = (numVal == 1) and "" or "s"
                text = string.gsub(text, "%$" .. i .. "[dD]%s*second%s*%$" .. i .. "s", tostring(numVal) .. " seconds")
                text = string.gsub(text, "%$" .. i .. "[dD]%s*tick%s*%$" .. i .. "s", tostring(numVal) .. " ticks")
                text = string.gsub(text, "%$" .. i .. "s", sfx)
            end
        end

        for i = 0, 9 do
            local val = amounts[i + 1] or amounts[i]
            if val ~= nil then
                text = string.gsub(text, "%$" .. i .. "[dD]%%", tostring(val) .. "%%")
                text = string.gsub(text, "%$s" .. (i + 1) .. "%%", tostring(val) .. "%%")
            end
        end

        for i = 0, 9 do
            local val = amounts[i + 1] or amounts[i]
            if val ~= nil then
                text = string.gsub(text, "%$" .. i .. "[dD]", tostring(val))
                text = string.gsub(text, "%$s" .. (i + 1), tostring(val))
            end
        end
    end

    -- 1. Format syntax layout markers ($n -> newline, $z -> bullet point, $C/$c -> color tags)
    text = string.gsub(text, "%$n", "\n")
    text = string.gsub(text, "%$z", "• ")
    text = string.gsub(text, "%$C", "")
    text = string.gsub(text, "%$c", "")

    -- 3. Replace dynamic variable placeholders with calculated / clean values
    text = string.gsub(text, "%$0d%%", "15%%")
    text = string.gsub(text, "%$1d%%", "20%%")
    text = string.gsub(text, "%$2d%%", "25%%")
    text = string.gsub(text, "%$3d%%", "30%%")
    text = string.gsub(text, "%$4d%%", "35%%")
    text = string.gsub(text, "%$s1%%", "20%%")
    text = string.gsub(text, "%$s2%%", "30%%")
    text = string.gsub(text, "%$s3%%", "40%%")

    text = string.gsub(text, "%$1D%s*second%$1s", "6 seconds")
    text = string.gsub(text, "%$2D%s*second%$2s", "10 seconds")
    text = string.gsub(text, "%$3D%s*second%$3s", "15 seconds")
    text = string.gsub(text, "%$1d%s*second%$1s", "6 seconds")
    text = string.gsub(text, "%$3d%s*tick%$3s", "2 ticks")

    text = string.gsub(text, "%$0d", "10")
    text = string.gsub(text, "%$1d", "15")
    text = string.gsub(text, "%$2d", "25")
    text = string.gsub(text, "%$3d", "50")
    text = string.gsub(text, "%$4d", "75")
    text = string.gsub(text, "%$s1", "100")
    text = string.gsub(text, "%$s2", "200")
    text = string.gsub(text, "%$s3", "300")

    -- Clean up duplicate newlines
    text = string.gsub(text, "\n%s*\n", "\n")
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")

    return text
end

-- =====================================================
-- DYNAMIC PERK BENEFIT & MODIFIER PARSER
-- =====================================================
function FC:ParsePerkDescription(desc, name)
    local mods = {
        spellDamage = {},
        schoolDamage = {},
        critChance = 0,
        critMultiplier = 0,
        hastePct = 0,
        hitPct = 0,
        spellPowerPct = 0,
        spellPowerFlat = 0,
        attackPowerPct = 0,
        armorPct = 0,
        shieldAbsorbPct = 0,
        damageReductionPct = 0,
        cooldownReduction = {},
        rangeBonus = 0,
        threatReductionPct = 0,
        pushbackReductionPct = 0,
        dotDurationPct = 0,
        aoeDamagePct = 0,
        isSoloOrTanking = false,
        empoweredSpells = {}
    }
    if not desc or desc == "" then
        desc = name or ""
    end

    local cleanDesc = self:FormatPerkDescription(desc, nil, name)
    local lowerDesc = string.lower(cleanDesc)
    local lowerName = string.lower(name or "")

    -- 1. Class Spells Matrix (Comprehensive 3.3.5a Ability Mapping)
    local allKnownSpells = {
        -- Death Knight
        ["Scourge Strike"] = true, ["Death Strike"] = true, ["Heart Strike"] = true, ["Blood Strike"] = true,
        ["Frost Strike"] = true, ["Howling Blast"] = true, ["Death Coil"] = true, ["Blood Boil"] = true,
        ["Pestilence"] = true, ["Death and Decay"] = true, ["Icy Touch"] = true, ["Plague Strike"] = true,
        ["Frost Fever"] = true, ["Blood Plague"] = true, ["Army of the Dead"] = true, ["Summon Gargoyle"] = true,
        ["Corpse Explosion"] = true, ["Rune Tap"] = true, ["Bone Shield"] = true, ["Vampiric Blood"] = true,
        -- Mage
        ["Living Bomb"] = true, ["Flamestrike"] = true, ["Fireball"] = true, ["Pyroblast"] = true,
        ["Blast Wave"] = true, ["Dragon's Breath"] = true, ["Scorch"] = true, ["Fire Blast"] = true,
        ["Frostbolt"] = true, ["Ice Lance"] = true, ["Blizzard"] = true, ["Deep Freeze"] = true,
        ["Arcane Blast"] = true, ["Arcane Missiles"] = true, ["Arcane Barrage"] = true, ["Ice Barrier"] = true,
        -- Paladin
        ["Crusader Strike"] = true, ["Divine Storm"] = true, ["Judgement"] = true, ["Holy Shock"] = true,
        ["Shield of the Righteous"] = true, ["Avenger's Shield"] = true, ["Hammer of the Righteous"] = true,
        ["Consecration"] = true, ["Hammer of Wrath"] = true, ["Holy Light"] = true, ["Flash of Light"] = true,
        -- Warrior
        ["Mortal Strike"] = true, ["Bloodthirst"] = true, ["Shield Slam"] = true, ["Devastate"] = true,
        ["Revenge"] = true, ["Overpower"] = true, ["Slam"] = true, ["Execute"] = true, ["Whirlwind"] = true,
        ["Heroic Strike"] = true, ["Cleave"] = true, ["Shockwave"] = true, ["Thunder Clap"] = true,
        -- Rogue
        ["Mutilate"] = true, ["Sinister Strike"] = true, ["Backstab"] = true, ["Ambush"] = true,
        ["Eviscerate"] = true, ["Envenom"] = true, ["Rupture"] = true, ["Fan of Knives"] = true,
        -- Priest
        ["Mind Blast"] = true, ["Mind Flay"] = true, ["Vampiric Touch"] = true, ["Shadow Word: Pain"] = true,
        ["Shadow Word: Death"] = true, ["Devouring Plague"] = true, ["Penance"] = true, ["Flash Heal"] = true,
        -- Warlock
        ["Chaos Bolt"] = true, ["Conflagrate"] = true, ["Incinerate"] = true, ["Immolate"] = true,
        ["Soul Fire"] = true, ["Shadowburn"] = true, ["Haunt"] = true, ["Unstable Affliction"] = true,
        ["Corruption"] = true, ["Seed of Corruption"] = true, ["Shadow Bolt"] = true,
        -- Shaman
        ["Lava Burst"] = true, ["Lightning Bolt"] = true, ["Chain Lightning"] = true, ["Earth Shock"] = true,
        ["Flame Shock"] = true, ["Frost Shock"] = true, ["Stormstrike"] = true, ["Lava Lash"] = true,
        -- Hunter
        ["Explosive Shot"] = true, ["Chimera Shot"] = true, ["Aimed Shot"] = true, ["Kill Shot"] = true,
        ["Arcane Shot"] = true, ["Multi-Shot"] = true, ["Steady Shot"] = true, ["Serpent Sting"] = true,
        -- Druid
        ["Starfire"] = true, ["Wrath"] = true, ["Moonfire"] = true, ["Insect Swarm"] = true,
        ["Shred"] = true, ["Rip"] = true, ["Rake"] = true, ["Ferocious Bite"] = true, ["Mangle"] = true
    }

    for sName, _ in pairs(allKnownSpells) do
        local lSpell = string.lower(sName)
        if string.find(lowerDesc, lSpell, 1, true) or string.find(lowerName, lSpell, 1, true) then
            local pct = string.match(lowerDesc, lSpell .. ".-by%s+(%d+)%%") or
                        string.match(lowerDesc, "increases%s+.-" .. lSpell .. ".-by%s+(%d+)%%") or
                        string.match(lowerDesc, "damage%s+of%s+.-" .. lSpell .. ".-by%s+(%d+)%%") or
                        string.match(lowerDesc, lSpell .. "%s+deals%s+(%d+)%%")
            local val = tonumber(pct) or 20
            mods.spellDamage[sName] = (mods.spellDamage[sName] or 0) + (val / 100)
            mods.empoweredSpells[sName] = true
        end
    end

    -- 2. School Damage & Universal Damage
    for _, school in ipairs({ "Fire", "Frost", "Arcane", "Shadow", "Holy", "Nature", "Physical" }) do
        local lSchool = string.lower(school)
        if string.find(lowerDesc, lSchool .. " damage", 1, true) or string.find(lowerDesc, lSchool .. " spell", 1, true) then
            local pct = string.match(lowerDesc, lSchool .. ".-by%s+(%d+)%%") or 15
            mods.schoolDamage[school] = (mods.schoolDamage[school] or 0) + (tonumber(pct) / 100)
        end
    end

    -- 3. Core Combat Stats: Crit, Haste, Hit, Attack Power, Spell Power
    local apPct = string.match(lowerDesc, "(%d+)%%%s*ap") or string.match(lowerDesc, "attack power.-by%s*(%d+)%%")
    if apPct then mods.attackPowerPct = mods.attackPowerPct + (tonumber(apPct) / 100) end

    local crit = string.match(lowerDesc, "critical.-by%s*(%d+)%%") or (string.find(lowerName, "crit", 1, true) and 5)
    if crit then mods.critChance = mods.critChance + tonumber(crit) end

    local haste = string.match(lowerDesc, "haste.-by%s*(%d+)%%") or string.match(lowerDesc, "speed.-by%s*(%d+)%%") or (string.find(lowerName, "haste", 1, true) and 5)
    if haste then mods.hastePct = mods.hastePct + tonumber(haste) end

    local hit = string.match(lowerDesc, "hit.-by%s*(%d+)%%") or (string.find(lowerName, "precision", 1, true) and 4)
    if hit then mods.hitPct = mods.hitPct + tonumber(hit) end

    -- 4. Defensive & EHP Stats: Armor, DR, Absorb, Health
    local armor = string.match(lowerDesc, "armor.-by%s*(%d+)%%") or (string.find(lowerName, "armor", 1, true) and 15)
    if armor then mods.armorPct = mods.armorPct + (tonumber(armor) / 100) end

    local dr = string.match(lowerDesc, "damage taken.-reduced by%s*(%d+)%%") or string.match(lowerDesc, "reduces damage taken by%s*(%d+)%%") or (string.find(lowerName, "fortitude", 1, true) and 8)
    if dr then mods.damageReductionPct = mods.damageReductionPct + (tonumber(dr) / 100) end

    local absorb = string.match(lowerDesc, "absorb.-by%s*(%d+)%%") or (string.find(lowerName, "barrier", 1, true) and 25)
    if absorb then mods.shieldAbsorbPct = mods.shieldAbsorbPct + (tonumber(absorb) / 100) end

    -- 5. Mechanics: Runes, Diseases, Dots, AoE
    if string.find(lowerDesc, "rune", 1, true) or string.find(lowerName, "rune", 1, true) then
        mods.hastePct = mods.hastePct + 5
        mods.schoolDamage["Physical"] = (mods.schoolDamage["Physical"] or 0) + 0.08
    end
    if string.find(lowerDesc, "disease", 1, true) or string.find(lowerDesc, "fever", 1, true) or string.find(lowerDesc, "plague", 1, true) then
        mods.schoolDamage["Shadow"] = (mods.schoolDamage["Shadow"] or 0) + 0.12
        mods.dotDurationPct = mods.dotDurationPct + 0.20
    end
    if string.find(lowerDesc, "aoe", 1, true) or string.find(lowerDesc, "nearby", 1, true) or string.find(lowerDesc, "all enemies", 1, true) or string.find(lowerDesc, "death and decay", 1, true) or string.find(lowerDesc, "blood boil", 1, true) then
        mods.aoeDamagePct = mods.aoeDamagePct + 0.20
    end

    -- Base perk value fallback: Ensure every single perk has at least some distinct benefit
    if mods.critChance == 0 and mods.hastePct == 0 and mods.hitPct == 0 and mods.armorPct == 0 and mods.damageReductionPct == 0 and not next(mods.spellDamage) and not next(mods.schoolDamage) then
        local hashVal = (string.len(name or "") * 7 + (tonumber(string.byte(name or "A", 1)) or 50)) % 10
        mods.schoolDamage["All"] = 0.03 + (hashVal * 0.005)
    end

    return mods
end

function FC:GetAggregatedPerkModifiers()
    local agg = {
        spellDamage = {},
        schoolDamage = {},
        critChance = 0,
        critMultiplier = 0,
        hastePct = 0,
        hitPct = 0,
        spellPowerPct = 0,
        armorPct = 0,
        shieldAbsorbPct = 0,
        damageReductionPct = 0,
        cooldownReduction = {},
        rangeBonus = 0,
        threatReductionPct = 0,
        pushbackReductionPct = 0,
        dotDurationPct = 0,
        aoeDamagePct = 0,
        activeCount = 0
    }

    local ext = self.extState or {}
    for _, perk in pairs(ext.activePerks or {}) do
        agg.activeCount = agg.activeCount + 1
        local m = self:ParsePerkDescription(perk.description or perk.tooltip, perk.name)
        for sName, val in pairs(m.spellDamage or {}) do
            agg.spellDamage[sName] = (agg.spellDamage[sName] or 0) + val
        end
        for sc, val in pairs(m.schoolDamage or {}) do
            agg.schoolDamage[sc] = (agg.schoolDamage[sc] or 0) + val
        end
        for sName, cd in pairs(m.cooldownReduction or {}) do
            agg.cooldownReduction[sName] = (agg.cooldownReduction[sName] or 0) + cd
        end
        agg.critChance = agg.critChance + m.critChance
        agg.critMultiplier = agg.critMultiplier + m.critMultiplier
        agg.hastePct = agg.hastePct + m.hastePct
        agg.hitPct = agg.hitPct + m.hitPct
        agg.armorPct = agg.armorPct + m.armorPct
        agg.shieldAbsorbPct = agg.shieldAbsorbPct + m.shieldAbsorbPct
        agg.damageReductionPct = agg.damageReductionPct + m.damageReductionPct
        agg.rangeBonus = agg.rangeBonus + m.rangeBonus
        agg.threatReductionPct = agg.threatReductionPct + m.threatReductionPct
        agg.dotDurationPct = agg.dotDurationPct + m.dotDurationPct
        agg.aoeDamagePct = agg.aoeDamagePct + m.aoeDamagePct
    end

    ext.aggregatedModifiers = agg
    return agg
end

function FC:AddPerkModifiers(baseMods, addM)
    local res = {}
    for k, v in pairs(baseMods or {}) do
        if type(v) == "table" then
            res[k] = {}
            for subK, subV in pairs(v) do res[k][subK] = subV end
        else
            res[k] = v
        end
    end
    res.spellDamage = res.spellDamage or {}
    res.schoolDamage = res.schoolDamage or {}
    for sName, val in pairs(addM.spellDamage or {}) do res.spellDamage[sName] = (res.spellDamage[sName] or 0) + val end
    for sc, val in pairs(addM.schoolDamage or {}) do res.schoolDamage[sc] = (res.schoolDamage[sc] or 0) + val end
    res.critChance = (res.critChance or 0) + (addM.critChance or 0)
    res.critMultiplier = (res.critMultiplier or 0) + (addM.critMultiplier or 0)
    res.hastePct = (res.hastePct or 0) + (addM.hastePct or 0)
    res.hitPct = (res.hitPct or 0) + (addM.hitPct or 0)
    res.armorPct = (res.armorPct or 0) + (addM.armorPct or 0)
    res.shieldAbsorbPct = (res.shieldAbsorbPct or 0) + (addM.shieldAbsorbPct or 0)
    res.damageReductionPct = (res.damageReductionPct or 0) + (addM.damageReductionPct or 0)
    res.rangeBonus = (res.rangeBonus or 0) + (addM.rangeBonus or 0)
    res.threatReductionPct = (res.threatReductionPct or 0) + (addM.threatReductionPct or 0)
    res.dotDurationPct = (res.dotDurationPct or 0) + (addM.dotDurationPct or 0)
    res.aoeDamagePct = (res.aoeDamagePct or 0) + (addM.aoeDamagePct or 0)
    return res
end

function FC:SubtractPerkModifiers(baseMods, subM)
    local res = {}
    for k, v in pairs(baseMods or {}) do
        if type(v) == "table" then
            res[k] = {}
            for subK, subV in pairs(v) do res[k][subK] = subV end
        else
            res[k] = v
        end
    end
    res.spellDamage = res.spellDamage or {}
    res.schoolDamage = res.schoolDamage or {}
    for sName, val in pairs(subM.spellDamage or {}) do res.spellDamage[sName] = math.max(0, (res.spellDamage[sName] or 0) - val) end
    for sc, val in pairs(subM.schoolDamage or {}) do res.schoolDamage[sc] = math.max(0, (res.schoolDamage[sc] or 0) - val) end
    res.critChance = math.max(0, (res.critChance or 0) - (subM.critChance or 0))
    res.critMultiplier = math.max(0, (res.critMultiplier or 0) - (subM.critMultiplier or 0))
    res.hastePct = math.max(0, (res.hastePct or 0) - (subM.hastePct or 0))
    res.hitPct = math.max(0, (res.hitPct or 0) - (subM.hitPct or 0))
    res.armorPct = math.max(0, (res.armorPct or 0) - (subM.armorPct or 0))
    res.shieldAbsorbPct = math.max(0, (res.shieldAbsorbPct or 0) - (subM.shieldAbsorbPct or 0))
    res.damageReductionPct = math.max(0, (res.damageReductionPct or 0) - (subM.damageReductionPct or 0))
    res.rangeBonus = math.max(0, (res.rangeBonus or 0) - (subM.rangeBonus or 0))
    res.threatReductionPct = math.max(0, (res.threatReductionPct or 0) - (subM.threatReductionPct or 0))
    res.dotDurationPct = math.max(0, (res.dotDurationPct or 0) - (subM.dotDurationPct or 0))
    res.aoeDamagePct = math.max(0, (res.aoeDamagePct or 0) - (subM.aoeDamagePct or 0))
    return res
end

function FC:SimulatePerkSwapMetrics()
    local ext = self.extState or {}
    local activePerks = ext.activePerks or {}
    local role = (FC.db and FC.db.playerRole) or "DPS"
    local approach = (FC.db and FC.db.combatApproach) or "Balanced"

    -- 1. Baseline Modifiers & Metrics
    local baseMods = self:GetAggregatedPerkModifiers()
    local baseSim = (self.CalculateSimValues and self:CalculateSimValues(baseMods, role, approach)) or { single = 0, cleave = 0, aoe = 0, ehp = 0, score = 0 }

    -- 2. Group active perks by category and evaluate each active perk's marginal score
    local activeByCat = {
        Offensive = {},
        Defensive = {},
        Support = {},
        Utility = {},
        Class = {},
        Misc = {}
    }

    for pId, pObj in pairs(activePerks) do
        local cat = pObj.category or "Misc"
        if not activeByCat[cat] then activeByCat[cat] = {} end
        table.insert(activeByCat[cat], pObj)
    end

    local lowestActiveInCat = {}
    local minScoreInCat = {}

    for cat, list in pairs(activeByCat) do
        local lowestPerk = nil
        local minScore = 999999999
        for _, pObj in ipairs(list) do
            local m = self:ParsePerkDescription(pObj.description or pObj.tooltip, pObj.name)
            local withoutMods = self:SubtractPerkModifiers(baseMods, m)
            local withoutSim = (self.CalculateSimValues and self:CalculateSimValues(withoutMods, role, approach)) or { single = 0, cleave = 0, aoe = 0, ehp = 0, score = 0 }
            local deltaScore = baseSim.score - withoutSim.score
            pObj._marginalScore = deltaScore
            pObj._sim = baseSim

            if deltaScore < minScore then
                minScore = deltaScore
                lowestPerk = pObj
            end
        end
        lowestActiveInCat[cat] = lowestPerk
        minScoreInCat[cat] = (lowestPerk and minScore) or 0
    end

    local function GetSwapSim(pObj, cat)
        local lowestPerk = lowestActiveInCat[cat]
        local tempMods = baseMods
        if lowestPerk then
            local removeM = self:ParsePerkDescription(lowestPerk.description or lowestPerk.tooltip, lowestPerk.name)
            tempMods = self:SubtractPerkModifiers(tempMods, removeM)
        end
        local addM = self:ParsePerkDescription(pObj.description or pObj.tooltip, pObj.name)
        tempMods = self:AddPerkModifiers(tempMods, addM)
        return (self.CalculateSimValues and self:CalculateSimValues(tempMods, role, approach)) or baseSim
    end

    return baseSim, lowestActiveInCat, minScoreInCat, GetSwapSim
end

-- =====================================================
-- SYNASTRIA DYNAMIC SCORING HOOK (REAL-TIME ROTATION)
-- =====================================================
function FC:ApplyExtStateScore(action, state, score)
    if FC.db and FC.db.enableSynastriaPerks == false then
        return score
    end

    local ext = self.extState or {}
    local pMods = ext.aggregatedModifiers or (self.GetAggregatedPerkModifiers and self:GetAggregatedPerkModifiers()) or {}

    -- 1. Check Class Perk Set Bonuses
    local setName = FC.db and FC.db.synastriaClassSet or ext.activeClassSet
    local setCount = FC.db and FC.db.synastriaClassSetCount or ext.classSetCount or 5

    if setName and setCount >= 4 and FC.SYNASTRIA_CLASS_SETS[setName] then
        local setDef = FC.SYNASTRIA_CLASS_SETS[setName]
        if setDef.apply then
            local ok, newScore = pcall(setDef.apply, state, action, score)
            if ok and newScore then
                score = newScore
            end
        end

        -- Fire Mage: Take 30% less damage from Ignited enemies
        if setName == "Fire Mage" and state.target and state.target.debuffs and state.target.debuffs["Ignite"] then
            if state.dangerLevel then
                state.dangerLevel = math.max(0, state.dangerLevel * 0.70)
            end
        end
    end

    -- 2. Dynamic Spell Modifier Scaling from Parsed Active Perks
    local aName = action.name or (action.spell and action.spell.name) or ""
    if aName ~= "" then
        if pMods.spellDamage and pMods.spellDamage[aName] then
            score = score * (1.0 + pMods.spellDamage[aName])
        end
        local aSchool = action.school or (action.spell and action.spell.school) or ""
        if aSchool ~= "" and pMods.schoolDamage and pMods.schoolDamage[aSchool] then
            score = score * (1.0 + pMods.schoolDamage[aSchool])
        end
        if pMods.schoolDamage and pMods.schoolDamage["All"] then
            score = score * (1.0 + pMods.schoolDamage["All"])
        end

        -- Active Tanking Shield Priority Upkeep
        if (action.isShield or string.find(aName, "Barrier") or string.find(aName, "Ward") or string.find(aName, "Shield")) and pMods.shieldAbsorbPct and pMods.shieldAbsorbPct > 0 then
            score = score * (1.0 + (pMods.shieldAbsorbPct * 0.4))
        end
    end

    -- 3. Custom Perk Ability Score Boost
    if action.isSynastriaPerk then
        score = score * 1.30
    end

    return score
end

-- =====================================================
-- NATIVE TRIGGER FUNCTIONS
-- =====================================================
function FC:OpenSynastriaPerkWindow()
    if OpenPerkMgr and type(OpenPerkMgr) == "function" then
        pcall(OpenPerkMgr)
    elseif CastSpellByID then
        pcall(CastSpellByID, 80100)
    else
        FC:Print("Synastria Perk View Spell (80100) triggered.")
    end
end

function FC:ScanAndCacheAllPerks()
    -- 1. Trigger server sync / perk window if available
    if self.OpenSynastriaPerkWindow then
        pcall(self.OpenSynastriaPerkWindow, self)
    end

    -- 2. Force state refresh with full cache build
    self:RefreshExtState()

    -- 3. Cache all discovered perk metadata into FC.db.perkCache
    if not FC.db then FC.db = {} end
    if not FC.db.perkCache then FC.db.perkCache = {} end
    local ext = self.extState or {}
    local totalPerks = 0
    for catName, pList in pairs(ext.categories or {}) do
        for _, perk in ipairs(pList) do
            totalPerks = totalPerks + 1
            FC.db.perkCache[perk.id] = {
                id = perk.id,
                name = perk.name,
                spellId = perk.spellId,
                icon = perk.icon,
                category = perk.category,
                description = perk.description,
                setName = perk.setName,
                assignedClass = perk.assignedClass
            }
        end
    end

    -- 4. Refresh UI
    if FC.RefreshConfigPerksList then
        FC:RefreshConfigPerksList()
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ccffFlowCore:|r Scanned and cached %d Synastria perks across all categories.", totalPerks))
end

function FC:ShowExportPopup(text, count)
    if not self.exportFrame then
        local f = CreateFrame("Frame", "FlowCoreExportFrame", UIParent)
        f:SetSize(640, 440)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(f)
        bg:SetTexture(0.08, 0.08, 0.12, 0.95)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
        title:SetText("|cffffd700FlowCore - Perk CSV Export|r")
        f.title = title

        local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        subtitle:SetText("Press |cff55ff55Ctrl+C|r to copy all CSV data to clipboard (or find in SavedVariables):")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

        local scroll = CreateFrame("ScrollFrame", "FlowCoreExportScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -55)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 40)

        local eb = CreateFrame("EditBox", "FlowCoreExportEditBox", scroll)
        eb:SetMultiLine(true)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetWidth(570)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)
        f.editBox = eb

        local selAllBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        selAllBtn:SetSize(120, 24)
        selAllBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 10)
        selAllBtn:SetText("Select All")
        selAllBtn:SetScript("OnClick", function()
            eb:SetFocus()
            eb:HighlightText()
        end)

        local closeBottomBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBottomBtn:SetSize(100, 24)
        closeBottomBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
        closeBottomBtn:SetText("Close")
        closeBottomBtn:SetScript("OnClick", function() f:Hide() end)

        self.exportFrame = f
    end

    self.exportFrame.title:SetText(string.format("|cffffd700FlowCore - Perk CSV Export (%d Perks)|r", count or 0))
    self.exportFrame.editBox:SetText(text or "")
    self.exportFrame:Show()
    self.exportFrame.editBox:SetFocus()
    self.exportFrame.editBox:HighlightText()
end

function FC:ExportPerksToCSV()
    if self.RefreshExtState then self:RefreshExtState() end

    local lines = {}
    table.insert(lines, "id,name,cat,category_name,assigned_class,set_name,spell_id,active,description")

    local ext = self.extState or {}
    local allPerks = {}
    local seenIds = {}

    -- 1. Gather all perks from extState categories
    for catName, pList in pairs(ext.categories or {}) do
        for _, p in ipairs(pList) do
            if p.id and not seenIds[p.id] then
                seenIds[p.id] = true
                table.insert(allPerks, p)
            end
        end
    end

    -- 2. Gather any un-categorized perks from _G.PerkMgrPerks
    if _G.PerkMgrPerks and type(_G.PerkMgrPerks) == "table" then
        for id, rawP in pairs(_G.PerkMgrPerks) do
            local numId = tonumber(id) or (type(rawP) == "table" and tonumber(rawP.id)) or 0
            if numId > 0 and not seenIds[numId] and type(rawP) == "table" and rawP.name then
                seenIds[numId] = true
                local cat = ResolvePerkCategory(numId, rawP.name, rawP.desc or rawP.description, rawP)
                local pObj = {
                    id = numId,
                    name = rawP.name,
                    cat = rawP.cat or 0,
                    category = cat,
                    spellId = rawP.spellId or rawP.spellID or rawP.spell,
                    description = self:FormatPerkDescription(rawP.desc or rawP.description, nil, rawP.name, numId, rawP),
                    active = false,
                    setName = DYNAMIC_CLASS_PERK_SETS[numId] or ""
                }
                pObj.assignedClass = self:GetPerkAssignedClass(pObj)
                table.insert(allPerks, pObj)
            end
        end
    end

    table.sort(allPerks, function(a, b)
        if (a.category or "") ~= (b.category or "") then
            return (a.category or "") < (b.category or "")
        end
        return (a.name or "") < (b.name or "")
    end)

    local exportTable = {}

    for _, p in ipairs(allPerks) do
        local id = p.id or 0
        local name = string.gsub(p.name or "", '"', '""')
        local cat = p.cat or 0
        local catName = p.category or "Misc"
        local assignedClass = p.assignedClass or "ALL"
        local setName = string.gsub(p.setName or "", '"', '""')
        local spellId = p.spellId or ""
        local active = p.active and "1" or "0"
        local desc = string.gsub(p.description or "", '"', '""')
        desc = string.gsub(desc, "\r?\n", " ")

        local csvLine = string.format('%d,"%s",%s,"%s","%s","%s","%s",%s,"%s"',
            id, name, tostring(cat), catName, assignedClass, setName, tostring(spellId), active, desc)
        table.insert(lines, csvLine)

        table.insert(exportTable, {
            id = id,
            name = p.name,
            cat = cat,
            category = catName,
            assignedClass = assignedClass,
            setName = p.setName,
            spellId = p.spellId,
            active = p.active,
            description = p.description
        })
    end

    local csvText = table.concat(lines, "\n")

    -- Save to global SavedVariables
    _G.FlowCoreExportDB = {
        exportedAt = date("%Y-%m-%d %H:%M:%S"),
        totalPerks = #allPerks,
        csv = csvText,
        perks = exportTable
    }

    self:Print(string.format("Exported %d perks to SavedVariables (FlowCoreExportDB).", #allPerks))
    self:ShowExportPopup(csvText, #allPerks)
end

function FC:OpenSynastriaAttunementWindow()
    if OpenAttuneSummary and type(OpenAttuneSummary) == "function" then
        pcall(OpenAttuneSummary)
    else
        FC:Print("Attunement Summary window triggered.")
    end
end

function FC:OpenSynastriaResourceWindow()
    if OpenResourceSummary and type(OpenResourceSummary) == "function" then
        pcall(OpenResourceSummary)
    else
        FC:Print("Resource Summary window triggered.")
    end
end

-- =====================================================
-- NATIVE SERVER EVENT HOOKS
-- =====================================================
local _oldOnCustomGameData = OnCustomGameData
OnCustomGameData = function(typeId, id, prev, cur)
    if _oldOnCustomGameData then
        pcall(_oldOnCustomGameData, typeId, id, prev, cur)
    end
    if FC.RefreshExtState and (typeId == 1 or typeId == 3 or typeId == 10 or typeId == 11 or typeId == 15) then
        FC:RefreshExtState()
    end
end

local _oldOnCustomGameDataFinish = OnCustomGameDataFinish
OnCustomGameDataFinish = function(...)
    if _oldOnCustomGameDataFinish then
        pcall(_oldOnCustomGameDataFinish, ...)
    end
    if FC.RefreshExtState then
        FC:RefreshExtState()
    end
end

local _oldOnCustomGameInit = OnCustomGameInit
OnCustomGameInit = function(...)
    if _oldOnCustomGameInit then
        pcall(_oldOnCustomGameInit, ...)
    end
    if FC.RefreshExtState then
        FC:RefreshExtState()
    end
end

-- Background Periodic Poll
local pollFrame = CreateFrame("Frame")
local elapsed = 0

pollFrame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed < FC.EXT_REFRESH_INTERVAL then return end
    elapsed = 0

    if FC.booted and FC.RefreshExtState then
        FC:RefreshExtState()
    end
end)