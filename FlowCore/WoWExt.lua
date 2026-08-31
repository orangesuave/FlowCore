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
    -- SUPPORT PERKS (5/5)
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
    -- UTILITY PERKS (5/5)
    -- -------------------------------------------------------------
    ["Attunement"]            = "Utility",
    ["Augmentation"]          = "Utility",
    ["Caution"]               = "Utility",
    ["Scouting"]              = "Utility",
    ["Teleportation"]         = "Utility",
    [10]                      = "Utility", -- Attunement
    [98]                      = "Utility", -- Augmentation
    [26]                      = "Utility", -- Caution
    [48]                      = "Utility", -- Scouting
    [476]                     = "Utility", -- Teleportation

    -- -------------------------------------------------------------
    -- DEFENSIVE PERKS (5/5)
    -- -------------------------------------------------------------
    ["Independence"]          = "Defensive",
    ["Stubborn"]              = "Defensive",
    ["Augmented Barriers"]    = "Defensive",
    ["Hardening"]             = "Defensive",
    ["Elemental Shielding"]   = "Defensive",
    [91]                      = "Defensive", -- Independence
    [71]                      = "Defensive", -- Stubborn
    [905]                     = "Defensive", -- Augmented Barriers
    [27]                      = "Defensive", -- Hardening
    [899]                     = "Defensive", -- Elemental Shielding

    -- -------------------------------------------------------------
    -- OFFENSIVE PERKS (5/5)
    -- -------------------------------------------------------------
    ["Extension"]             = "Offensive",
    ["Outburst"]              = "Offensive",
    ["Dissipation"]           = "Offensive",
    ["Vengeance"]             = "Offensive",
    ["Precision"]             = "Offensive",
    [79]                      = "Offensive", -- Extension
    [112]                     = "Offensive", -- Outburst
    [114]                     = "Offensive", -- Dissipation
    [226]                     = "Offensive", -- Vengeance
    [59]                      = "Offensive", -- Precision

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
    ["Dungeon Event Speedup"]        = "Misc",
    ["Automatic Mount"]              = "Misc",
    ["Attune Bar"]                   = "Misc",
    ["Combustion Indicator"]         = "Misc",
    ["Balance: Mage"]                = "Misc",
    [796]                            = "Misc", -- Minimum Offensive Perk Level
    [797]                            = "Misc", -- Minimum Defensive Perk Level
    [798]                            = "Misc", -- Minimum Support Perk Level
    [799]                            = "Misc", -- Minimum Utility Perk Level
    [1492]                           = "Misc", -- Prestige: Loot BoP
    [1493]                           = "Misc", -- Prestige: Loot BoE
    [1494]                           = "Misc", -- Prestige: Loot Forging
    [1557]                           = "Misc", -- Prestige: Loot Chance
    [1500]                           = "Misc", -- Prestige: Attune Mastery
    [909]                            = "Misc", -- Dungeon Event Speedup
    [1277]                           = "Misc", -- Automatic Mount
    [1703]                           = "Misc", -- Attune Bar
    [920]                            = "Misc", -- Combustion Indicator
    [882]                            = "Misc"  -- Balance: Mage
}

-- Known Synastria Class Perk Sets (for auto-detecting active 4pc bonuses)
local CLASS_PERK_SETS = {
    -- Fire Mage Set (The 5 Core Class Perks)
    [1113] = "Fire Mage", -- Explosive Impact
    [1115] = "Fire Mage", -- Slow Burn
    [1116] = "Fire Mage", -- Spreading Flames
    [1117] = "Fire Mage", -- Empowered Flames
    [1119] = "Fire Mage", -- Meteor Shower
    ["Empowered Flames"] = "Fire Mage",
    ["Explosive Impact"] = "Fire Mage",
    ["Meteor Shower"]    = "Fire Mage",
    ["Slow Burn"]        = "Fire Mage",
    ["Spreading Flames"] = "Fire Mage"
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

FC.EXT_REFRESH_INTERVAL = 2.0

-- =====================================================================
-- SYNASTRIA CLASS PERK SET BONUSES CATALOG
-- =====================================================================
FC.SYNASTRIA_CLASS_SETS = {
    ["Fire Mage"] = {
        name = "Fire Mage Set",
        class = "MAGE",
        twoPiece = "Ignite duration increased by 6s.",
        fourPiece = "+125% Fire damage. You take 30% less damage from Ignited enemies.",
        apply = function(state, action, mult)
            -- 4-Piece: +125% Fire Damage
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
            if action.name == "Shield of Righteousness" or action.name == "Hammer of the Righteous" then
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
    ["Destruction Warlock"] = {
        name = "Destruction Warlock Set",
        class = "WARLOCK",
        twoPiece = "Immolate duration increased by 6s.",
        fourPiece = "+100% Chaos Bolt and Incinerate damage.",
        apply = function(state, action, mult)
            if action.school == "Fire" or action.name == "Chaos Bolt" then
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
    }
}

-- =====================================================================
-- PERK CATEGORY RESOLVER
-- =====================================================================
local function ResolvePerkCategory(perkId, perkName, perkDesc)
    perkId = tonumber(perkId) or 0
    perkName = perkName or ""
    perkDesc = perkDesc or ""

    -- 1. Direct ID / Exact Name Lookup
    if EXPLICIT_PERK_CATEGORIES[perkId] then
        return EXPLICIT_PERK_CATEGORIES[perkId]
    end

    if EXPLICIT_PERK_CATEGORIES[perkName] then
        return EXPLICIT_PERK_CATEGORIES[perkName]
    end

    local lowerName = string.lower(perkName)

    -- 2. Misc Pre-Filters (Catch all level floors, prestige, QoL, automation, and UI indicators)
    if string.find(lowerName, "minimum", 1, true) or 
       string.find(lowerName, "perk level", 1, true) or 
       string.find(lowerName, "prestige", 1, true) or 
       string.find(lowerName, "speedup", 1, true) or 
       string.find(lowerName, "indicator", 1, true) or 
       string.find(lowerName, "attune bar", 1, true) or 
       string.find(lowerName, "mount", 1, true) or 
       string.find(lowerName, "balance:", 1, true) or
       string.find(lowerName, "loot", 1, true) then
        return "Misc"
    end

    -- 3. Case-insensitive lookup in explicit categories table
    for name, cat in pairs(EXPLICIT_PERK_CATEGORIES) do
        if type(name) == "string" and string.lower(name) == lowerName then
            return cat
        end
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

    -- 2. Inspect PerkMgrPerks master table
    if _G.PerkMgrPerks and type(_G.PerkMgrPerks) == "table" then
        hasSynastria = true
        for id, perk in pairs(_G.PerkMgrPerks) do
            if type(perk) == "table" and perk.name then
                local numId = tonumber(id) or 0
                local pName = perk.name
                local pDesc = perk.description or perk.tooltip or perk.text or ""
                local cat = ResolvePerkCategory(numId, pName, pDesc)

                local isActive = false
                if hasNativeGetPerkActive then
                    local ok, active = pcall(GetPerkActive, numId)
                    if ok and (active == true or active == 1) then
                        isActive = true
                    end
                elseif perk.active == true or perk.isActive == true then
                    isActive = true
                end

                local entry = {
                    id = numId,
                    name = pName,
                    spellId = perk.spellId or numId,
                    icon = perk.icon or "Interface\\Icons\\Spell_Holy_MagicalSentry",
                    category = cat,
                    description = pDesc,
                    active = isActive
                }

                table.insert(categories[cat], entry)

                if isActive then
                    activePerks[numId] = entry
                    catCounts[cat] = (catCounts[cat] or 0) + 1

                    -- Track active class perks towards set bonuses
                    local classSet = CLASS_PERK_SETS[numId] or CLASS_PERK_SETS[pName]
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
                    local pDesc = perk.description or perk.tooltip or perk.text or ""
                    local cat = ResolvePerkCategory(numId, pName, pDesc)
                    local isActive = (type(coreLib.Perks.IsPerkActive) == "function" and coreLib.Perks:IsPerkActive(numId)) or (hasNativeGetPerkActive and GetPerkActive(numId)) or perk.active == true
                    local entry = {
                        id = numId,
                        name = pName,
                        spellId = perk.spellId or numId,
                        icon = perk.icon or "Interface\\Icons\\Spell_Holy_MagicalSentry",
                        category = cat,
                        description = pDesc,
                        active = isActive
                    }
                    if isActive then
                        activePerks[numId] = entry
                        catCounts[cat] = (catCounts[cat] or 0) + 1
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

    -- 6. Detect Dominant Active Class Perk Set
    local dominantSet = nil
    local maxSetCount = 0
    for setName, count in pairs(detectedClassSetCounts) do
        if count > maxSetCount then
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
        if not FC.db.synastriaClassSet then
            if FC.playerClass == "MAGE" then
                FC.db.synastriaClassSet = "Fire Mage"
                FC.db.synastriaClassSetCount = 5
            else
                FC.db.synastriaClassSet = "Retribution Paladin"
                FC.db.synastriaClassSetCount = 5
            end
        end
        self.extState.activeClassSet = FC.db.synastriaClassSet
        self.extState.classSetCount = FC.db.synastriaClassSetCount or 5
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

-- =====================================================
-- DYNAMIC PERK DESCRIPTION & BENEFIT PARSER
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
    if not desc or desc == "" then return mods end

    local lowerDesc = string.lower(desc)
    local lowerName = string.lower(name or "")

    -- 1. Spell Damage Modifiers
    local spellList = FC._registeredSpellNames or {
        ["Living Bomb"] = true, ["Flamestrike"] = true, ["Fireball"] = true,
        ["Pyroblast"] = true, ["Blast Wave"] = true, ["Dragon's Breath"] = true,
        ["Scorch"] = true, ["Fire Blast"] = true, ["Frostbolt"] = true,
        ["Arcane Blast"] = true, ["Arcane Missiles"] = true, ["Ice Barrier"] = true
    }
    for sName, _ in pairs(spellList) do
        local lSpell = string.lower(sName)
        local pct = string.match(lowerDesc, "increases%s+the%s+damage%s+of%s+your%s+" .. lSpell .. "%s+by%s+(%d+)%%") or
                    string.match(lowerDesc, "increases%s+" .. lSpell .. "%s+damage%s+by%s+(%d+)%%") or
                    string.match(lowerDesc, lSpell .. "%s+deals%s+(%d+)%%s+additional%s+damage") or
                    string.match(lowerDesc, lSpell .. "%s+deals%s+(%d+)%%s+more%s+damage")
        if pct then
            mods.spellDamage[sName] = (mods.spellDamage[sName] or 0) + (tonumber(pct) / 100)
            mods.empoweredSpells[sName] = true
        end

        local cdSec = string.match(lowerDesc, "reduces%s+the%s+cooldown%s+of%s+" .. lSpell .. "%s+by%s+(%d+)")
        if cdSec then
            mods.cooldownReduction[sName] = (mods.cooldownReduction[sName] or 0) + tonumber(cdSec)
            mods.empoweredSpells[sName] = true
        end

        local critPct = string.match(lowerDesc, "increases%s+the%s+critical%s+strike%s+damage%s+of%s+" .. lSpell .. "%s+by%s+(%d+)%%") or
                        string.match(lowerDesc, "increases%s+" .. lSpell .. "%s+critical%s+strike%s+damage%s+by%s+(%d+)%%")
        if critPct then
            mods.critMultiplier = mods.critMultiplier + (tonumber(critPct) / 100)
            mods.empoweredSpells[sName] = true
        end
    end

    -- 2. School Damage Modifiers
    for _, school in ipairs({ "Fire", "Frost", "Arcane", "Shadow", "Holy", "Nature", "Physical" }) do
        local lSchool = string.lower(school)
        local pct = string.match(lowerDesc, "increases%s+" .. lSchool .. "%s+damage%s+by%s+(%d+)%%") or
                    string.match(lowerDesc, "increases%s+" .. lSchool .. "%s+spell%s+damage%s+by%s+(%d+)%%") or
                    string.match(lowerDesc, lSchool .. "%s+damage%s+increased%s+by%s+(%d+)%%")
        if pct then
            mods.schoolDamage[school] = (mods.schoolDamage[school] or 0) + (tonumber(pct) / 100)
        end
    end

    local genDmg = string.match(lowerDesc, "increases%s+damage%s+dealt%s+by%s+(%d+)%%") or
                   string.match(lowerDesc, "deal%s+(%d+)%%s+more%s+damage") or
                   string.match(lowerDesc, "all%s+damage%s+increased%s+by%s+(%d+)%%")
    if genDmg then
        mods.schoolDamage["All"] = (mods.schoolDamage["All"] or 0) + (tonumber(genDmg) / 100)
    end

    -- 3. Critical Strike Modifiers
    local crit = string.match(lowerDesc, "increases%s+critical%s+strike%s+chance%s+by%s+(%d+)%%") or
                 string.match(lowerDesc, "increases%s+your%s+spell%s+critical%s+strike%s+chance%s+by%s+(%d+)%%") or
                 string.match(lowerDesc, "critical%s+strike%s+chance%s+increased%s+by%s+(%d+)%%")
    if crit then
        mods.critChance = mods.critChance + tonumber(crit)
    elseif string.find(lowerName, "outburst", 1, true) then
        mods.critChance = mods.critChance + 5
    end

    local critMult = string.match(lowerDesc, "increases%s+critical%s+strike%s+damage%s+bonus%s+by%s+(%d+)%%") or
                     string.match(lowerDesc, "critical%s+strikes%s+deal%s+(%d+)%%s+additional%s+damage")
    if critMult then
        mods.critMultiplier = mods.critMultiplier + (tonumber(critMult) / 100)
    end

    -- 4. Haste & Cast Speed
    local haste = string.match(lowerDesc, "increases%s+spell%s+casting%s+speed%s+by%s+(%d+)%%") or
                  string.match(lowerDesc, "increases%s+haste%s+rating%s+by%s+(%d+)%%") or
                  string.match(lowerDesc, "casting%s+speed%s+increased%s+by%s+(%d+)%%") or
                  string.match(lowerDesc, "haste%s+increased%s+by%s+(%d+)%%")
    if haste then
        mods.hastePct = mods.hastePct + tonumber(haste)
    end

    -- 5. Hit Rating
    local hit = string.match(lowerDesc, "increases%s+hit%s+rating%s+by%s+(%d+)%%") or
                string.match(lowerDesc, "increases%s+your%s+chance%s+to%s+hit%s+by%s+(%d+)%%")
    if hit then
        mods.hitPct = mods.hitPct + tonumber(hit)
    elseif string.find(lowerName, "precision", 1, true) then
        mods.hitPct = mods.hitPct + 4
    end

    -- 6. Shield & Absorb Modifiers
    local absorb = string.match(lowerDesc, "increases%s+damage%s+absorbed%s+by%s+(%d+)%%") or
                   string.match(lowerDesc, "absorbed%s+by%s+(%d+)%%") or
                   string.match(lowerDesc, "barrier%s+absorption%s+increased%s+by%s+(%d+)%%") or
                   string.match(lowerDesc, "shield%s+absorption%s+increased%s+by%s+(%d+)%%")
    if absorb then
        mods.shieldAbsorbPct = mods.shieldAbsorbPct + (tonumber(absorb) / 100)
    elseif string.find(lowerName, "augmented barriers", 1, true) or string.find(lowerName, "warding", 1, true) then
        mods.shieldAbsorbPct = mods.shieldAbsorbPct + 0.35
    end

    -- 7. Damage Reduction & Defenses
    local dr = string.match(lowerDesc, "reduces%s+damage%s+taken%s+by%s+(%d+)%%") or
               string.match(lowerDesc, "damage%s+taken%s+reduced%s+by%s+(%d+)%%") or
               string.match(lowerDesc, "take%s+(%d+)%%s+less%s+damage")
    if dr then
        mods.damageReductionPct = mods.damageReductionPct + (tonumber(dr) / 100)
    elseif string.find(lowerName, "independence", 1, true) then
        mods.damageReductionPct = mods.damageReductionPct + 0.15
        mods.isSoloOrTanking = true
    elseif string.find(lowerName, "hardening", 1, true) then
        mods.armorPct = mods.armorPct + 0.25
        mods.damageReductionPct = mods.damageReductionPct + 0.08
    elseif string.find(lowerName, "stubborn", 1, true) then
        mods.damageReductionPct = mods.damageReductionPct + 0.05
    end

    -- 8. Range / Radius
    local range = string.match(lowerDesc, "increases%s+the%s+range%s+of%s+.-by%s+(%d+)%s*yd") or
                  string.match(lowerDesc, "range%s+increased%s+by%s+(%d+)%s*yd") or
                  string.match(lowerDesc, "range%s+by%s+(%d+)%s*yd")
    if range then
        mods.rangeBonus = mods.rangeBonus + tonumber(range)
    elseif string.find(lowerName, "extension", 1, true) then
        mods.rangeBonus = mods.rangeBonus + 6
    end

    -- 9. Periodic / DoTs
    local dot = string.match(lowerDesc, "increases%s+the%s+duration%s+of%s+.-by%s+(%d+)%%") or
                string.match(lowerDesc, "periodic%s+damage%s+increased%s+by%s+(%d+)%%")
    if dot then
        mods.dotDurationPct = mods.dotDurationPct + (tonumber(dot) / 100)
    elseif string.find(lowerName, "slow burn", 1, true) then
        mods.dotDurationPct = mods.dotDurationPct + 0.30
    end

    -- 10. Threat & Pushback
    if string.find(lowerDesc, "threat", 1, true) then
        local threat = string.match(lowerDesc, "reduces%s+threat%s+.-by%s+(%d+)%%")
        mods.threatReductionPct = mods.threatReductionPct + (tonumber(threat or 20) / 100)
    elseif string.find(lowerName, "caution", 1, true) then
        mods.threatReductionPct = mods.threatReductionPct + 0.20
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