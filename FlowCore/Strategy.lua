FlowCore = FlowCore or {}
local FC = FlowCore

-- =====================================================================
-- FLOWCORE COMBAT STRATEGY, BUILD ADVISOR & GEAR OPTIMIZER ENGINE
-- Comprehensive Multi-Expansion System (Classic, TBC, WotLK 3.3.5a / Synastria)
-- =====================================================================

FC.cachedBank = FC.cachedBank or {}
FC.cachedMail = FC.cachedMail or {}
FC.lastCombatReport = FC.lastCombatReport or nil

-- Hidden scanner tooltip for item parsing
local stratScannerTooltip = CreateFrame("GameTooltip", "FlowCoreStratScanTooltip", UIParent, "GameTooltipTemplate")
stratScannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- =====================================================================
-- 1. STAT CAPS CONSTANTS & DYNAMIC MULTI-DIFFICULTY ENGINE
-- =====================================================================
FC.STAT_CAPS_CONSTANTS = {
    BASELINE = {
        SpellHit = { soft = 14.0, hard = 17.0, ratingPerPct = 26.232, desc = "17% total (14% with 3/3 talents, 13% with Spriest/Boomkin debuff)" },
        MeleeHit = { soft = 8.0, hard = 27.0, ratingPerPct = 32.79, desc = "8% for yellow specials (263 rating), 27% for dual-wield white hits" },
        RangedHit = { soft = 8.0, hard = 8.0, ratingPerPct = 32.79, desc = "8% for ranged shots (263 rating, 164 rating with 3/3 Focused Aim)" },
        Expertise = { soft = 26, hard = 56, ratingPerExp = 8.1975, desc = "26 (6.5%) eliminates boss dodges from behind; 56 (14%) eliminates parries from front" },
        SpellCrit = { soft = 100.0, hard = 100.0, ratingPerPct = 45.91, desc = "100% caps spell critical strikes" },
        MeleeCrit = { soft = 76.0, hard = 100.0, ratingPerPct = 45.91, desc = "Crit cap ~76-80% due to 24% boss glance table; 100% for yellow specials" },
        HasteSoft = { soft = 50.0, hard = 100.0, ratingPerPct = 32.79, desc = "50% haste brings 1.5s GCD to 1.0s floor; 100% doubles cast throughput" },
        ArmorPen = { soft = 100.0, hard = 100.0, ratingPerPct = 13.996, desc = "100% ArP (1400 rating) hard cap for 100% physical boss armor bypass" },
        Defense = { soft = 535, hard = 540, ratingPerPoint = 4.92, desc = "535 for Heroics, 540 for Level 83 Raid Boss critical strike immunity (-5.6% crit)" },
        Resilience = { soft = 1000, hard = 1414, ratingPerPoint = 81.975, desc = "1414 rating cap (-33% player crit damage taken / -15% crit chance)" },
        SpellPenetration = { soft = 75, hard = 130, desc = "130 spell penetration overcomes Mark of the Wild & Shadow Protection" },
        Armor = { soft = 49905, hard = 49905, desc = "49,905 armor (75% maximum physical damage reduction against level 83 boss)" }
    },
    MYTHIC = {
        SpellHit = { soft = 25.0, hard = 35.0, ratingPerPct = 26.232, desc = "Mythic bosses have elevated magic resistance & miss chance (+10-18%)" },
        MeleeHit = { soft = 18.0, hard = 45.0, ratingPerPct = 32.79, desc = "Mythic bosses have increased dodge and miss penalties (+10%)" },
        RangedHit = { soft = 18.0, hard = 18.0, ratingPerPct = 32.79, desc = "Mythic boss elevated miss penalty" },
        Expertise = { soft = 45, hard = 85, ratingPerExp = 8.1975, desc = "Mythic bosses have enhanced dodge/parry avoidance tables" },
        SpellCrit = { soft = 400.0, hard = 700.0, ratingPerPct = 45.91, desc = "Mythic suppression requires up to 700% character sheet crit for guaranteed crits!" },
        MeleeCrit = { soft = 400.0, hard = 700.0, ratingPerPct = 45.91, desc = "Mythic suppression requires up to 700% character sheet crit for guaranteed crits!" },
        HasteSoft = { soft = 100.0, hard = 250.0, ratingPerPct = 32.79, desc = "Sub-second animation thresholds and extreme haste scaling in Mythic" },
        ArmorPen = { soft = 100.0, hard = 200.0, ratingPerPct = 13.996, desc = "Extended Mythic boss armor pools require deep ArP saturation" },
        Defense = { soft = 650, hard = 850, ratingPerPoint = 4.92, desc = "Mythic bosses have increased critical strike chance & crushing blows" },
        Resilience = { soft = 1414, hard = 2000, ratingPerPoint = 81.975, desc = "Mitigates extreme Mythic boss spike hits" },
        SpellPenetration = { soft = 130, hard = 250, desc = "Overcomes high Mythic magic resistances" },
        Armor = { soft = 60000, hard = 75000, desc = "Extended Mythic armor reduction curve" }
    }
}

local DEFAULT_STAT_WEIGHTS = {
    ["Fire"] = { SP = 1.25, Hit = 2.30, Crit = 0.90, Haste = 1.05, Spirit = 0.55, Int = 0.40, Sta = 0.60, Armor = 0.35 },
    ["Arcane"] = { SP = 1.25, Hit = 2.30, Haste = 1.15, Crit = 0.70, Int = 0.65, Spirit = 0.30, Sta = 0.60, Armor = 0.35 },
    ["Frost"] = { SP = 1.25, Hit = 2.30, Haste = 1.05, Crit = 0.80, Int = 0.45, Spirit = 0.30, Sta = 0.65, Armor = 0.40 },
    ["Affliction"] = { SP = 1.20, Hit = 2.40, Haste = 1.15, Crit = 0.75, Spirit = 0.50, Int = 0.35, Sta = 0.60, Armor = 0.35 },
    ["Destruction"] = { SP = 1.20, Hit = 2.40, Haste = 1.05, Crit = 0.90, Spirit = 0.40, Int = 0.35, Sta = 0.60, Armor = 0.35 },
    ["Demonology"] = { SP = 1.20, Hit = 2.40, Haste = 1.00, Crit = 0.85, Spirit = 0.45, Int = 0.40, Sta = 0.70, Armor = 0.40 },
    ["Shadow"] = { SP = 1.20, Hit = 2.35, Haste = 1.10, Crit = 0.80, Spirit = 0.50, Int = 0.35, Sta = 0.60, Armor = 0.35 },
    ["Holy"] = { SP = 1.15, Crit = 0.85, Haste = 0.95, Int = 0.70, Spirit = 0.65, Sta = 0.60, Armor = 0.35 },
    ["Discipline"] = { SP = 1.20, Crit = 0.90, Haste = 0.85, Int = 0.70, Spirit = 0.55, Sta = 0.65, Armor = 0.35 },
    ["Retribution"] = { AP = 1.00, Str = 2.30, Hit = 2.50, Exp = 2.20, Crit = 1.10, Haste = 0.95, ArP = 0.65, Sta = 0.75, Armor = 0.50 },
    ["Protection"] = { Armor = 1.20, Sta = 2.20, Defense = 1.60, Dodge = 1.30, Parry = 1.30, Block = 1.00, Str = 1.50, Hit = 1.80 },
    ["Frost_DK"] = { AP = 1.00, Str = 2.50, Hit = 2.40, Exp = 2.20, ArP = 1.40, Crit = 1.10, Haste = 0.90, Sta = 0.75, Armor = 0.45 },
    ["Unholy_DK"] = { AP = 1.00, Str = 2.60, Hit = 2.40, Exp = 2.00, ArP = 1.10, Crit = 1.05, Haste = 0.95, Sta = 0.75, Armor = 0.45 },
    ["Blood_DK"] = { Armor = 1.20, Sta = 2.40, Defense = 1.50, Dodge = 1.30, Parry = 1.30, Hit = 1.80, Str = 1.80 },
    ["Arms"] = { AP = 1.00, Str = 2.10, Hit = 2.30, Exp = 2.10, ArP = 1.85, Crit = 1.20, Haste = 0.65, Sta = 0.70, Armor = 0.45 },
    ["Fury"] = { AP = 1.00, Str = 2.20, Hit = 2.40, Exp = 2.20, ArP = 1.95, Crit = 1.25, Haste = 0.80, Sta = 0.70, Armor = 0.45 },
    ["Assassination"] = { AP = 1.00, Agi = 1.80, Hit = 2.20, Exp = 2.00, Haste = 1.20, Crit = 1.05, ArP = 0.50, Sta = 0.60 },
    ["Combat"] = { AP = 1.00, Agi = 1.70, Hit = 2.30, Exp = 2.10, ArP = 1.90, Haste = 1.30, Crit = 1.10, Sta = 0.60 },
    ["Subtlety"] = { AP = 1.00, Agi = 1.90, Hit = 2.20, Exp = 2.00, ArP = 1.40, Crit = 1.15, Haste = 0.75, Sta = 0.60 },
    ["Balance"] = { SP = 1.20, Hit = 2.30, Haste = 1.10, Crit = 0.85, Spirit = 0.35, Int = 0.30, Sta = 0.65, Armor = 0.40 },
    ["Feral"] = { AP = 1.00, Agi = 2.10, Str = 2.00, Hit = 2.30, Exp = 2.10, ArP = 1.90, Crit = 1.20, Sta = 0.80, Armor = 0.60 },
    ["Survival"] = { AP = 1.00, Agi = 2.20, Hit = 2.40, Crit = 1.15, Haste = 0.75, ArP = 0.85, Sta = 0.60 },
    ["Marksmanship"] = { AP = 1.00, Agi = 2.10, Hit = 2.40, ArP = 1.80, Crit = 1.20, Haste = 0.80, Sta = 0.60 },
    ["Elemental"] = { SP = 1.20, Hit = 2.30, Haste = 1.15, Crit = 0.80, Int = 0.35, Sta = 0.65, Armor = 0.45 },
    ["Enhancement"] = { AP = 1.00, Agi = 1.70, Hit = 2.50, Exp = 2.20, Haste = 1.25, Crit = 1.10, SP = 0.85, Sta = 0.70, Armor = 0.45 }
}

function FC:GetStatWeights(specName)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"

    local base = DEFAULT_STAT_WEIGHTS[specName]
    if not base then
        if pClass == "DEATHKNIGHT" then base = DEFAULT_STAT_WEIGHTS["Frost_DK"]
        elseif pClass == "WARRIOR" then base = DEFAULT_STAT_WEIGHTS["Fury"]
        elseif pClass == "ROGUE" then base = DEFAULT_STAT_WEIGHTS["Combat"]
        elseif pClass == "PALADIN" then base = DEFAULT_STAT_WEIGHTS["Retribution"]
        elseif pClass == "HUNTER" then base = DEFAULT_STAT_WEIGHTS["Survival"]
        elseif pClass == "PRIEST" then base = DEFAULT_STAT_WEIGHTS["Shadow"]
        elseif pClass == "WARLOCK" then base = DEFAULT_STAT_WEIGHTS["Affliction"]
        elseif pClass == "SHAMAN" then base = DEFAULT_STAT_WEIGHTS["Elemental"]
        elseif pClass == "DRUID" then base = DEFAULT_STAT_WEIGHTS["Balance"]
        else base = DEFAULT_STAT_WEIGHTS["Fire"]
        end
    end

    local weights = {}
    for k, v in pairs(base) do
        weights[k] = v
    end

    local approach = (FC.db and FC.db.combatApproach) or "Balanced"
    if approach == "ST Damage" then
        if weights.Crit then weights.Crit = weights.Crit * 1.15 end
        if weights.Haste then weights.Haste = weights.Haste * 1.10 end
        if weights.ArP then weights.ArP = weights.ArP * 1.20 end
        if weights.Hit then weights.Hit = weights.Hit * 1.25 end
        if weights.SP then weights.SP = weights.SP * 1.10 end
        if weights.AP then weights.AP = weights.AP * 1.10 end
    elseif approach == "AOE Damage" then
        if weights.Haste then weights.Haste = weights.Haste * 1.25 end
        if weights.Crit then weights.Crit = weights.Crit * 1.20 end
        if weights.SP then weights.SP = weights.SP * 1.15 end
        if weights.AP then weights.AP = weights.AP * 1.15 end
    elseif approach == "Survival/PVP" then
        if weights.Sta then weights.Sta = weights.Sta * 2.0 end
        if weights.Armor then weights.Armor = weights.Armor * 1.8 end
        weights.Resilience = 2.2
        weights.Defense = 1.8
        weights.Dodge = 1.5
        weights.Parry = 1.5
        weights.Block = 1.2
    end

    return weights
end

function FC:AnalyzeStatCaps(mode)
    if self.UpdatePlayerStats then self:UpdatePlayerStats() end
    local p = self.state.player or {}
    local s = p.stats or {}
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"
    local specName = (self.GetActiveSpecName and self:GetActiveSpecName()) or "Unknown"

    local isMythic = (mode == "mythic" or mode == "m" or (self.extState and self.extState.isMythicDungeon))
    local caps = isMythic and FC.STAT_CAPS_CONSTANTS.MYTHIC or FC.STAT_CAPS_CONSTANTS.BASELINE

    local isCaster = (pClass == "MAGE" or pClass == "WARLOCK" or pClass == "PRIEST" or (pClass == "DRUID" and specName == "Balance") or (pClass == "SHAMAN" and specName == "Elemental"))
    local isTank = (s.defense and s.defense >= 500) or (pClass == "WARRIOR" and specName == "Protection") or (pClass == "PALADIN" and specName == "Protection") or (pClass == "DEATHKNIGHT" and specName == "Blood")

    local reports = {}

    -- 1. Hit Cap Analysis
    if isCaster then
        local baseHitNeeded = caps.SpellHit.hard
        local talentHit = 0
        if self.GetTalentRank then
            if pClass == "MAGE" then talentHit = self:GetTalentRank("Precision") * 1.0
            elseif pClass == "WARLOCK" then talentHit = self:GetTalentRank("Suppression") * 1.0
            elseif pClass == "PRIEST" then talentHit = self:GetTalentRank("Shadow Focus") * 1.0
            elseif pClass == "DRUID" then talentHit = self:GetTalentRank("Balance of Power") * 2.0
            elseif pClass == "SHAMAN" then talentHit = self:GetTalentRank("Elemental Precision") * 1.0
            end
        end
        local raidHitDebuff = isMythic and 0 or 3.0 -- Misery / Improved Faerie Fire
        local gearHit = s.spellHit or 0
        local totalHit = gearHit + talentHit + raidHitDebuff
        local hitRating = GetCombatRating and GetCombatRating(8) or 0
        local hitCapRating = math.max(0, math.ceil((baseHitNeeded - talentHit - raidHitDebuff) * caps.SpellHit.ratingPerPct))

        local status = "|cff55ff55[CAPPED]|r"
        local diffStr = ""
        if totalHit < baseHitNeeded then
            local missingPct = baseHitNeeded - totalHit
            local missingRating = math.ceil(missingPct * caps.SpellHit.ratingPerPct)
            status = "|cffff2222[UNDER CAP]|r"
            diffStr = string.format(" (Need +%.2f%% / +%d Rating)", missingPct, missingRating)
        else
            local excessPct = totalHit - baseHitNeeded
            if excessPct > 1.0 then
                status = "|cffffd700[OVER CAPPED]|r"
                diffStr = string.format(" (+%.2f%% excess rating can be reforged/gemmed)", excessPct)
            end
        end

        table.insert(reports, {
            name = "Spell Hit Rating",
            current = string.format("%.2f%% (%d Rating)", gearHit + talentHit, hitRating),
            target = string.format("%.1f%% (Target: %d Rating%s)", baseHitNeeded, hitCapRating, isMythic and " Mythic" or " Raid"),
            status = status,
            detail = diffStr
        })
    else
        -- Melee / Physical Hit
        local baseHitNeeded = caps.MeleeHit.soft -- Yellow special attack cap
        local gearHit = s.meleeHit or s.rangedHit or 0
        local hitRating = GetCombatRating and (GetCombatRating(6) or GetCombatRating(7)) or 0
        local status = "|cff55ff55[CAPPED]|r"
        local diffStr = ""
        if gearHit < baseHitNeeded then
            local missingPct = baseHitNeeded - gearHit
            local missingRating = math.ceil(missingPct * caps.MeleeHit.ratingPerPct)
            status = "|cffff2222[UNDER CAP]|r"
            diffStr = string.format(" (Need +%.2f%% / +%d Rating for Specials)", missingPct, missingRating)
        elseif gearHit > baseHitNeeded + 1.0 then
            status = "|cffffd700[OVER CAPPED]|r"
            diffStr = string.format(" (+%.2f%% excess for specials, benefits dual-wield white hits)", gearHit - baseHitNeeded)
        end

        table.insert(reports, {
            name = "Physical Hit Rating",
            current = string.format("%.2f%% (%d Rating)", gearHit, hitRating),
            target = string.format("%.1f%% (%d Rating for Specials)", baseHitNeeded, math.ceil(baseHitNeeded * caps.MeleeHit.ratingPerPct)),
            status = status,
            detail = diffStr
        })
    end

    -- 2. Expertise Cap Analysis (Melee & Tanks)
    if not isCaster then
        local exp = s.expertise or 0
        local expPct = s.expertisePct or 0
        local expCap = caps.Expertise.soft
        local status = (exp >= expCap) and "|cff55ff55[CAPPED]|r" or "|cffff2222[UNDER CAP]|r"
        local diffStr = (exp < expCap) and string.format(" (Need +%d Expertise to eliminate boss dodges)", expCap - exp) or " (Boss dodges eliminated)"
        table.insert(reports, {
            name = "Expertise",
            current = string.format("%d (%.2f%% Dodge Reduction)", exp, expPct),
            target = string.format("%d Expertise / %.2f%%", expCap, expCap * 0.25),
            status = status,
            detail = diffStr
        })
    end

    -- 3. Critical Strike & Mythic Suppression Cap
    local critVal = isCaster and (s.spellCrit or 0) or (s.meleeCrit or 0)
    local critTarget = caps.SpellCrit.hard
    local critStatus = (critVal >= critTarget) and "|cff55ff55[100% CRIT CAPPED]|r" or "|cff00ccff[Scaling Efficiently]|r"
    local critDetail = isMythic and string.format(" (Mythic suppression requires up to 700%% for guaranteed crits)") or ""
    table.insert(reports, {
        name = isCaster and "Spell Critical Strike" or "Physical Critical Strike",
        current = string.format("%.2f%%", critVal),
        target = string.format("%.0f%% %s", critTarget, isMythic and "Mythic Target" or "Sheet Cap"),
        status = critStatus,
        detail = critDetail
    })

    -- 4. Haste Soft-Cap Analysis (1.00s GCD Cap)
    local baseGCD = (pClass == "ROGUE" or pClass == "CAT") and 1.0 or 1.5
    local currentHaste = s.spellHaste or s.meleeHaste or 0
    local hasteMult = 1.0 + (currentHaste / 100)
    local effGCD = math.max(0.0, baseGCD / hasteMult)
    local hasteStatus = (effGCD <= 1.005) and "|cff55ff55[SOFT CAP REACHED (1.0s GCD)]|r" or "|cff00ccff[Scaling Efficiently]|r"
    local hasteDetail = string.format("Effective GCD: %.3fs (Base: %.2fs)", effGCD, baseGCD)
    table.insert(reports, {
        name = "Haste Soft-Cap",
        current = string.format("%.2f%% (%.3fx Speed)", currentHaste, hasteMult),
        target = "1.000s Floor (50% Haste)",
        status = hasteStatus,
        detail = hasteDetail
    })

    -- 5. Armor Penetration (Physical DPS)
    if not isCaster and (s.armorPen and s.armorPen > 0 or pClass == "WARRIOR" or pClass == "ROGUE" or pClass == "DEATHKNIGHT" or pClass == "HUNTER" or (pClass == "DRUID" and specName == "Feral")) then
        local arp = s.armorPen or 0
        local arpPct = math.min(100, (arp / 1400) * 100)
        local arpStatus = (arp >= 1400) and "|cff55ff55[HARD CAPPED (100%)]|r" or "|cff00ccff[Scaling Efficiently]|r"
        local arpDetail = (arp < 1400) and string.format(" (Need +%d Rating for 100%% Hard Cap)", 1400 - arp) or " (Maximum 100% Armor Bypass)"
        table.insert(reports, {
            name = "Armor Penetration",
            current = string.format("%.1f%% (%d Rating)", arpPct, arp),
            target = "1400 Rating (100.0% Hard Cap)",
            status = arpStatus,
            detail = arpDetail
        })
    end

    -- 6. Defense Cap (Tanks)
    if isTank or (s.defense and s.defense > 400) then
        local def = s.defense or 0
        local defCap = caps.Defense.hard
        local status = (def >= defCap) and "|cff55ff55[CRIT IMMUNE (540+)]|r" or "|cffff2222[VULNERABLE TO CRITS]|r"
        local detail = (def < defCap) and string.format(" (Need +%d Defense Rating for Raid Bosses)", defCap - def) or " (Immune to Level 83 Boss Critical Strikes)"
        table.insert(reports, {
            name = "Defense Rating",
            current = string.format("%d Defense", def),
            target = string.format("%d Defense", defCap),
            status = status,
            detail = detail
        })
    end

    -- 7. Spell Penetration (Casters in PvP / High Resist Mobs)
    if isCaster and s.spellPenetration and s.spellPenetration > 0 then
        table.insert(reports, {
            name = "Spell Penetration",
            current = string.format("%d Spell Pen", s.spellPenetration),
            target = "130 Cap (Overcomes Resistance Auras)",
            status = (s.spellPenetration >= 130) and "|cff55ff55[CAPPED]|r" or "|cff00ccff[Active]|r",
            detail = ""
        })
    end

    return reports
end

-- =====================================================================
-- 2. GEAR, MULTI-PROFESSION ENCHANT & TRINKET PROC OPTIMIZER
-- =====================================================================
local ENCHANTABLE_SLOTS = {
    [1] = "Head",
    [3] = "Shoulders",
    [15] = "Back",
    [5] = "Chest",
    [9] = "Wrist",
    [10] = "Hands",
    [6] = "Waist (Belt Buckle)",
    [7] = "Legs",
    [8] = "Feet",
    [16] = "Main Hand",
    [17] = "Off Hand (Shield/Weapon)",
    [18] = "Ranged (Bow/Gun/Crossbow)"
}

-- Comprehensive Trinket Empirical Benchmark Database
FC.TRINKET_DATABASE = {
    -- Top Tier WotLK Raid Trinkets (Heroic & Normal)
    ["Charred Twilight Scale"] = 920,
    ["Dislodged Foreign Object"] = 900,
    ["Phylactery of the Nameless Lich"] = 890,
    ["Reign of the Unliving"] = 820,
    ["Reign of the Dead"] = 820,
    ["Flare of the Heavens"] = 750,
    ["Muradin's Spyglass"] = 740,
    ["Talisman of Resurgence"] = 560,
    ["Abyssal Rune"] = 540,
    ["Sundial of the Exiled"] = 490,
    ["Eye of the Broodmother"] = 510,
    ["Scale of Fates"] = 620,
    ["Illustration of the Dragon Soul"] = 600,
    ["Darkmoon Card: Greatness"] = 720,
    ["Deathbringer's Will"] = 930,
    ["Sharpened Twilight Scale"] = 940,
    ["Whispering Fanged Skull"] = 770,
    ["Death's Choice"] = 840,
    ["Death's Verdict"] = 840,
    ["Comet's Trail"] = 750,
    ["Mjolnir Runestone"] = 720,
    ["Dark Matter"] = 690,
    ["Grim Toll"] = 530,
    ["Mirror of Truth"] = 490,
    ["Banner of Victory"] = 430,
    ["Mercurial Alchemist Stone"] = 360 -- Craftable Level 200 Alchemist Stone
}

-- Comprehensive Enchant / Item Enhancement Matching (Multi-Profession Aware)
local PROFESSION_ENCHANT_KEYWORDS = {
    -- Inscription
    "Master's Inscription of the Storm", "Master's Inscription of the Axe", "Master's Inscription of the Crag", "Master's Inscription of the Pinnacle",
    -- Tailoring
    "Lightweave Embroidery", "Darkglow Embroidery", "Swordguard Embroidery",
    -- Leatherworking
    "Fur Lining - Spell Power", "Fur Lining - Attack Power", "Fur Lining - Stamina", "Fur Lining - Fire Resist", "Fur Lining - Frost Resist",
    -- Engineering
    "Hyperspeed Accelerators", "Nitro Boosts", "Springy Arachnoweave", "Hand-Mounted Pyro Rocket", "Flexweave Underlay", "Frag Belt", "Mind Amplification Dish", "Personal Electromagnetic Damper",
    -- Blacksmithing / Buckles / Sockets
    "Socket", "Prismatic Socket", "Eternal Belt Buckle",
    -- Standard Enchanting
    "Enchanted: ", "Berserking", "Mongoose", "Black Magic", "Blood Draining", "Blade Ward", "Executioner",
    "Greater Inscription", "Arcanum of", "Greater Spellpower", "Mighty Spellpower", "Superior Potency",
    "Heavy Borean Armor Kit", "Jormungar Leg Reinforcements", "Earthen Leg Armor", "Icescale Leg Armor", "Sanctified Spellthread", "Brilliant Spellthread",
    "Heartseeker Scope", "Sun Scope", "Titanium Weapon Chain"
}

function FC:IsItemEnchanted(itemLink, slotId)
    if not itemLink then return false end

    -- Method 1: Direct Item Link Parameter Parsing (|Hitem:itemId:enchantId:...)
    local enchantId = string.match(itemLink, "item:%d+:(%d+)")
    if enchantId and tonumber(enchantId) and tonumber(enchantId) > 0 then
        return true
    end

    -- Method 2: Tooltip Green Text & Profession Keywords Scan
    stratScannerTooltip:ClearLines()
    stratScannerTooltip:SetHyperlink(itemLink)

    for lineIdx = 1, stratScannerTooltip:NumLines() do
        local line = _G["FlowCoreStratScanTooltipTextLeft" .. lineIdx]
        if line then
            local txt = line:GetText() or ""
            local r, g, b = line:GetTextColor()

            -- Green text line check (enchantments in 3.3.5a are rendered in green font)
            if g and r and b and g > 0.70 and r < 0.35 and b < 0.35 then
                if not string.find(txt, "Set:", 1, true) and not string.find(txt, "Equip:", 1, true) and not string.find(txt, "Use:", 1, true) and not string.find(txt, "Requires", 1, true) then
                    return true
                end
            end

            -- Profession enhancement keywords
            for _, kw in ipairs(PROFESSION_ENCHANT_KEYWORDS) do
                if string.find(txt, kw, 1, true) then
                    return true
                end
            end
        end
    end

    return false
end

function FC:ExtractStatsFromItem(itemLink)
    if not itemLink then return {} end
    local stats = {
        name = GetItemInfo(itemLink) or "Item",
        iLevel = 0,
        sp = 0, ap = 0, rap = 0, str = 0, agi = 0, sta = 0, int = 0, spi = 0,
        crit = 0, haste = 0, hit = 0, arp = 0, exp = 0,
        armor = 0, defense = 0, dodge = 0, parry = 0, block = 0,
        sockets = 0, emptySockets = 0, hasEnchant = false,
        onUseStat = nil, onUseVal = 0, onUseDur = 0, onUseCD = 120,
        procStat = nil, procVal = 0, procDur = 0, procICD = 45, procChance = 0.15,
        procDamage = 0, procDamageSchool = "Physical",
        isTitanforged = false, isWarforged = false, isLightforged = false
    }

    local _, _, _, itemLevel, _, _, _, _, equipSlot = GetItemInfo(itemLink)
    stats.iLevel = itemLevel or 0
    stats.equipSlot = equipSlot

    stratScannerTooltip:ClearLines()
    stratScannerTooltip:SetHyperlink(itemLink)

    for lineIdx = 1, stratScannerTooltip:NumLines() do
        local line = _G["FlowCoreStratScanTooltipTextLeft" .. lineIdx]
        if line then
            local txt = line:GetText() or ""

            -- Attributes
            local val = tonumber(string.match(txt, "%+(%d+) Strength")) or tonumber(string.match(txt, "%+(%d+) Str"))
            if val then stats.str = stats.str + val end

            val = tonumber(string.match(txt, "%+(%d+) Agility")) or tonumber(string.match(txt, "%+(%d+) Agi"))
            if val then stats.agi = stats.agi + val end

            val = tonumber(string.match(txt, "%+(%d+) Stamina")) or tonumber(string.match(txt, "%+(%d+) Sta"))
            if val then stats.sta = stats.sta + val end

            val = tonumber(string.match(txt, "%+(%d+) Intellect")) or tonumber(string.match(txt, "%+(%d+) Int"))
            if val then stats.int = stats.int + val end

            val = tonumber(string.match(txt, "%+(%d+) Spirit")) or tonumber(string.match(txt, "%+(%d+) Spi"))
            if val then stats.spi = stats.spi + val end

            -- Secondary Stats
            val = tonumber(string.match(txt, "Increases spell power by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Spell Power"))
            if val then stats.sp = stats.sp + val end

            val = tonumber(string.match(txt, "Increases attack power by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Attack Power"))
            if val then stats.ap = stats.ap + val end

            val = tonumber(string.match(txt, "Increases ranged attack power by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Ranged Attack Power"))
            if val then stats.rap = stats.rap + val end

            val = tonumber(string.match(txt, "Increases critical strike rating by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Critical Strike")) or tonumber(string.match(txt, "%+(%d+) Crit"))
            if val then stats.crit = stats.crit + val end

            val = tonumber(string.match(txt, "Increases haste rating by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Haste"))
            if val then stats.haste = stats.haste + val end

            val = tonumber(string.match(txt, "Increases hit rating by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Hit"))
            if val then stats.hit = stats.hit + val end

            val = tonumber(string.match(txt, "Increases your armor penetration by (%d+)")) or tonumber(string.match(txt, "Increases armor penetration rating by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Armor Penetration"))
            if val then stats.arp = stats.arp + val end

            val = tonumber(string.match(txt, "Increases expertise rating by (%d+)")) or tonumber(string.match(txt, "%+(%d+) Expertise"))
            if val then stats.exp = stats.exp + val end

            -- TRINKET / SPECIAL ON-USE AFFIXES
            if string.find(txt, "Use:", 1, true) then
                local uVal, uDur, uCD = string.match(txt, "Increases spell power by (%d+) for (%d+) sec.*%((%d+) Min Cooldown%)")
                if uVal then
                    stats.onUseStat = "SP"
                    stats.onUseVal = tonumber(uVal) or 0
                    stats.onUseDur = tonumber(uDur) or 20
                    stats.onUseCD = (tonumber(uCD) or 2) * 60
                end

                uVal, uDur, uCD = string.match(txt, "Increases haste rating by (%d+) for (%d+) sec.*%((%d+) Min Cooldown%)")
                if uVal then
                    stats.onUseStat = "Haste"
                    stats.onUseVal = tonumber(uVal) or 0
                    stats.onUseDur = tonumber(uDur) or 20
                    stats.onUseCD = (tonumber(uCD) or 2) * 60
                end

                uVal, uDur, uCD = string.match(txt, "Increases attack power by (%d+) for (%d+) sec.*%((%d+) Min Cooldown%)")
                if uVal then
                    stats.onUseStat = "AP"
                    stats.onUseVal = tonumber(uVal) or 0
                    stats.onUseDur = tonumber(uDur) or 20
                    stats.onUseCD = (tonumber(uCD) or 2) * 60
                end
            end

            -- TRINKET / SPECIAL CHANCE-ON-HIT PROC AFFIXES
            if string.find(txt, "chance to grant", 1, true) or string.find(txt, "chance to increase", 1, true) then
                local pVal, pDur = string.match(txt, "grant (%d+) spell power for (%d+) sec")
                if pVal then
                    stats.procStat = "SP"
                    stats.procVal = tonumber(pVal) or 0
                    stats.procDur = tonumber(pDur) or 10
                end

                pVal, pDur = string.match(txt, "grant (%d+) haste rating for (%d+) sec")
                if pVal then
                    stats.procStat = "Haste"
                    stats.procVal = tonumber(pVal) or 0
                    stats.procDur = tonumber(pDur) or 10
                end

                pVal, pDur = string.match(txt, "grant (%d+) attack power for (%d+) sec")
                if pVal then
                    stats.procStat = "AP"
                    stats.procVal = tonumber(pVal) or 0
                    stats.procDur = tonumber(pDur) or 10
                end
            end

            -- TRINKET DIRECT DAMAGE PROCS (e.g. Reign of the Dead / Unliving)
            local dMin, dMax, dSchool = string.match(txt, "deal (%d+) to (%d+) (%a+) damage")
            if dMin and dMax then
                stats.procDamage = (tonumber(dMin) + tonumber(dMax)) / 2
                stats.procDamageSchool = dSchool or "Fire"
            end

            -- Sockets
            if string.find(txt, "Socket", 1, true) then
                stats.sockets = stats.sockets + 1
                if string.find(txt, "Empty", 1, true) then
                    stats.emptySockets = stats.emptySockets + 1
                end
            end

            -- Forges
            if string.find(txt, "Titanforged", 1, true) then stats.isTitanforged = true
            elseif string.find(txt, "Warforged", 1, true) then stats.isWarforged = true
            elseif string.find(txt, "Lightforged", 1, true) then stats.isLightforged = true
            end
        end
    end

    -- Native Synastria Item Tags Custom Check (bitmask analysis)
    local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
    if itemId and itemId > 0 and type(_G.GetItemTagsCustom) == "function" then
        local ok, tag1, tag2 = pcall(_G.GetItemTagsCustom, itemId)
        if ok and (tag1 or tag2) then
            tag1 = tag1 or 0
            tag2 = tag2 or 0
            if bit and bit.band then
                if bit.band(tag1, 0x80) ~= 0 then stats.isMythic = true end
                if bit.band(tag2, 0x01) ~= 0 then stats.hasRandomAffix = true end
                if bit.band(tag2, 0x04) ~= 0 then stats.hasBaseResistWhenAttuned = true end
            end
        end
    end

    stats.hasEnchant = FC:IsItemEnchanted(itemLink, 0)
    return stats
end

function FC:CalculateItemScore(itemLink, specName)
    local s = self:ExtractStatsFromItem(itemLink)
    local w = self:GetStatWeights(specName)
    local itemName = s.name or ""

    -- Direct Database Lookup for Known Raid Trinkets
    local baseScore = nil
    for dbName, dbScore in pairs(FC.TRINKET_DATABASE) do
        if string.find(itemName, dbName, 1, true) then
            baseScore = dbScore
            if string.find(itemName, "Heroic", 1, true) or (s.iLevel and s.iLevel >= 271) then
                baseScore = baseScore + 60
            end
            break
        end
    end

    local score = baseScore or ((s.iLevel or 1) * 0.5)
    if not baseScore then
        score = score + (s.sp * (w.SP or 1.0))
        score = score + (s.ap * (w.AP or 0.5))
        score = score + (s.rap * (w.AP or 0.5))
        score = score + (s.str * (w.Str or 0.5))
        score = score + (s.agi * (w.Agi or 0.5))
        score = score + (s.sta * (w.Sta or 0.3))
        score = score + (s.int * (w.Int or 0.4))
        score = score + (s.spi * (w.Spirit or 0.3))
        score = score + (s.crit * (w.Crit or 0.8))
        score = score + (s.haste * (w.Haste or 0.9))
        score = score + (s.hit * (w.Hit or 1.5))
        score = score + (s.arp * (w.ArP or 0.5))
        score = score + (s.exp * (w.Exp or 1.0))

        -- ON-USE STAT EQUIVALENT VALUE
        if s.onUseStat and s.onUseVal > 0 and s.onUseCD > 0 then
            local uptime = math.min(0.35, (s.onUseDur or 20) / (s.onUseCD or 120))
            local effVal = s.onUseVal * uptime
            local statWeight = w[s.onUseStat] or 1.0
            score = score + (effVal * statWeight)
        end

        -- CHANCE-ON-HIT PROC EQUIVALENT VALUE (ICD ~45-50s)
        if s.procStat and s.procVal > 0 then
            local avgCycle = 50.0
            local uptime = math.min(0.30, (s.procDur or 10) / avgCycle)
            local effVal = s.procVal * uptime
            local statWeight = w[s.procStat] or 1.0
            score = score + (effVal * statWeight)
        end

        -- DIRECT DAMAGE PROC EQUIVALENT VALUE
        if s.procDamage and s.procDamage > 0 then
            local dpsGain = s.procDamage / 15.0
            score = score + (dpsGain * (w.SP or 1.0) * 0.80)
        end
    end

    -- FORGES & MYTHIC MULTIPLIERS
    if s.isMythic then score = score * 1.65
    elseif s.isTitanforged then score = score * 1.50
    elseif s.isWarforged then score = score * 1.25
    elseif s.isLightforged then score = score * 1.15
    end

    return score, s
end

function FC:AuditEquippedGear()
    local results = {
        score = 0,
        totalEmptySockets = 0,
        missingEnchants = {},
        slots = {}
    }

    local specName = (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"

    for slot = 1, 18 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local itemScore, sData = self:CalculateItemScore(link, specName)
            local isEnchanted = self:IsItemEnchanted(link, slot)
            results.score = results.score + itemScore

            -- Determine if slot is actually enchantable for the equipped item type
            local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
            local isEnchantable = ENCHANTABLE_SLOTS[slot] ~= nil

            -- Slot 17: Held in offhand cannot be enchanted; Shields/Weapons can
            if slot == 17 and (equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_RELIC") then
                isEnchantable = false
            end

            -- Slot 18: Wands, Thrown, Relics cannot be enchanted/scoped; Bows/Guns/Crossbows can
            if slot == 18 and (equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN" or equipLoc == "INVTYPE_RELIC") then
                isEnchantable = false
            end

            -- Enchant Check
            if isEnchantable and not isEnchanted then
                table.insert(results.missingEnchants, { slot = slot, slotName = ENCHANTABLE_SLOTS[slot], itemName = sData.name })
            end

            -- Gem Socket Check
            if sData.emptySockets and sData.emptySockets > 0 then
                results.totalEmptySockets = results.totalEmptySockets + sData.emptySockets
            end

            results.slots[slot] = {
                link = link,
                name = sData.name,
                score = itemScore,
                emptySockets = sData.emptySockets,
                hasEnchant = isEnchanted,
                isEnchantable = isEnchantable
            }
        end
    end

    return results
end

-- =====================================================================
-- SCAN BAGS, BANK & MAIL INBOX FOR EQUIPPABLE UPGRADE CANDIDATES
-- Integrated DataStore Support, Already-Equipped Item Exclusion & 2H/1H Combos
-- =====================================================================
function FC:ScanBagsBankMailForUpgrades(specName)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    local upgrades = {}
    local equippedAudit = self:AuditEquippedGear()

    -- 1. Index Currently Equipped Items (to exclude already-equipped gear)
    local equippedItemIDs = {}
    local equippedItemNames = {}
    local equippedItemLinks = {}
    for slot = 1, 18 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local name = GetItemInfo(link)
            local id = string.match(link, "item:(%d+)")
            if name then equippedItemNames[name] = true end
            if id then equippedItemIDs[tonumber(id)] = true end
            equippedItemLinks[link] = true
        end
    end

    -- Clean up cached bank/mail entries that are now equipped
    if FC.cachedBank then
        for cLink, _ in pairs(FC.cachedBank) do
            local cName = GetItemInfo(cLink)
            local cId = string.match(cLink, "item:(%d+)")
            if equippedItemLinks[cLink] or (cName and equippedItemNames[cName]) or (cId and equippedItemIDs[tonumber(cId)]) then
                FC.cachedBank[cLink] = nil
            end
        end
    end
    if FC.cachedMail then
        for mLink, _ in pairs(FC.cachedMail) do
            local mName = GetItemInfo(mLink)
            local mId = string.match(mLink, "item:(%d+)")
            if equippedItemLinks[mLink] or (mName and equippedItemNames[mName]) or (mId and equippedItemIDs[tonumber(mId)]) then
                FC.cachedMail[mLink] = nil
            end
        end
    end

    -- 2. Gather all candidate items from Bags, Bank, Mail, and DataStore
    local allCandidates = {}
    local seenLinks = {}

    local function Collect(link, src)
        if not link or seenLinks[link] then return end
        local name, _, rarity, iLvl, _, iType, subType, _, equipLoc = GetItemInfo(link)
        if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then return end

        local id = string.match(link, "item:(%d+)")
        -- Strictly exclude items that are ALREADY EQUIPPED on the player!
        if (id and equippedItemIDs[tonumber(id)]) or (name and equippedItemNames[name]) or equippedItemLinks[link] then
            return
        end

        seenLinks[link] = true
        local score, sData = FC:CalculateItemScore(link, specName)
        table.insert(allCandidates, {
            link = link,
            name = name or "Item",
            equipLoc = equipLoc,
            source = src,
            score = score,
            sData = sData
        })
    end

    -- Scan Bags (0 to 4)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then Collect(link, "Bags") end
        end
    end

    -- Scan Live Bank (-1 and 5 to 11)
    for bag = -1, 11 do
        if bag == -1 or bag >= 5 then
            local numSlots = GetContainerNumSlots(bag) or 0
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    FC.cachedBank[link] = true
                    Collect(link, "Bank")
                end
            end
        end
    end

    -- DataStore Integration (DataStore_Containers & DataStore_Mails)
    if _G["DataStore"] and type(_G["DataStore"].GetCharacter) == "function" then
        local charKey = _G["DataStore"]:GetCharacter()
        if charKey and _G["DataStore"].GetContainers then
            local containers = _G["DataStore"]:GetContainers(charKey)
            if containers then
                for containerID, container in pairs(containers) do
                    -- Bank containers: -1 and 5 to 11
                    if containerID == -1 or (containerID >= 5 and containerID <= 11) then
                        local numSlots = (type(container) == "table" and container.size) or 36
                        for slotID = 1, numSlots do
                            local item = _G["DataStore"]:GetContainerItem(charKey, containerID, slotID)
                            local link = nil
                            if type(item) == "string" and string.find(item, "item:") then
                                link = item
                            elseif type(item) == "number" then
                                local _, itemLink = GetItemInfo(item)
                                link = itemLink
                            end
                            if link then
                                Collect(link, "DataStore (Bank)")
                            end
                        end
                    end
                end
            end
        end
    end

    -- Fallback Cached Bank
    if FC.cachedBank then
        for cLink, _ in pairs(FC.cachedBank) do Collect(cLink, "Bank (Cached)") end
    end

    -- Scan Mailbox Inbox (if opened)
    if GetInboxNumItems and GetInboxItemLink then
        local numMail = GetInboxNumItems() or 0
        for m = 1, numMail do
            for a = 1, 12 do
                local link = GetInboxItemLink(m, a)
                if link then
                    FC.cachedMail[link] = true
                    Collect(link, "Mailbox")
                end
            end
        end
    end
    if FC.cachedMail then
        for mLink, _ in pairs(FC.cachedMail) do Collect(mLink, "Mailbox (Cached)") end
    end

    -- 3. Analyze Equipped Weapon State (Slot 16 Main Hand & Slot 17 Off-Hand)
    local curMH = equippedAudit.slots[16]
    local curOH = equippedAudit.slots[17]
    local curMHScore = curMH and curMH.score or 0
    local curOHScore = curOH and curOH.score or 0
    local curWeaponComboScore = curMHScore + curOHScore

    local isEquipped2H = false
    if curMH and curMH.link then
        local _, _, _, _, _, _, _, _, eqLoc = GetItemInfo(curMH.link)
        if eqLoc == "INVTYPE_2HWEAPON" then isEquipped2H = true end
    end

    -- Find Best Available Off-Hand in inventory/bank/mail (for 1H combos when 2H is equipped)
    local bestAvailOH = nil
    for _, cand in ipairs(allCandidates) do
        if cand.equipLoc == "INVTYPE_WEAPONOFFHAND" or cand.equipLoc == "INVTYPE_SHIELD" or cand.equipLoc == "INVTYPE_HOLDABLE" then
            if not bestAvailOH or cand.score > bestAvailOH.score then
                bestAvailOH = cand
            end
        end
    end
    local offHandScoreToUse = (curOH and curOH.score and curOH.score > 0 and curOH.score) or (bestAvailOH and bestAvailOH.score) or 0

    -- Find Best Available 1H Weapon in inventory/bank/mail (for Off-Hand combos when 2H is equipped)
    local bestAvail1H = nil
    for _, cand in ipairs(allCandidates) do
        if cand.equipLoc == "INVTYPE_WEAPON" or cand.equipLoc == "INVTYPE_WEAPONMAINHAND" then
            if not bestAvail1H or cand.score > bestAvail1H.score then
                bestAvail1H = cand
            end
        end
    end

    -- 4. Evaluate Upgrades for each Candidate
    local seenUpgrades = {}

    for _, cand in ipairs(allCandidates) do
        local equipLoc = cand.equipLoc
        local itemLink = cand.link
        local itemName = cand.name
        local candScore = cand.score

        if not seenUpgrades[itemLink] then
            -- A. Two-Handed Weapon Candidate
            if equipLoc == "INVTYPE_2HWEAPON" then
                if candScore > (curWeaponComboScore * 1.03) then
                    seenUpgrades[itemLink] = true
                    local diff = candScore - curWeaponComboScore
                    local pct = curWeaponComboScore > 0 and ((diff / curWeaponComboScore) * 100) or 100
                    local compName = isEquipped2H and "Equipped 2H" or "Equipped 1H+OffHand Combo"
                    table.insert(upgrades, {
                        name = itemName,
                        link = itemLink,
                        slot = 16,
                        slotName = string.format("Two-Hand (vs %s)", compName),
                        source = cand.source,
                        candScore = candScore,
                        curScore = curWeaponComboScore,
                        gain = diff,
                        gainPct = pct
                    })
                end

            -- B. One-Handed Weapon Candidate
            elseif equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" then
                if isEquipped2H then
                    local comboScore = candScore + offHandScoreToUse
                    if comboScore > (curWeaponComboScore * 1.03) then
                        seenUpgrades[itemLink] = true
                        local diff = comboScore - curWeaponComboScore
                        local pct = curWeaponComboScore > 0 and ((diff / curWeaponComboScore) * 100) or 100
                        local ohLabel = (curOH and curOH.name) or (bestAvailOH and bestAvailOH.name) or "Off-Hand"
                        table.insert(upgrades, {
                            name = itemName .. " + " .. ohLabel,
                            link = itemLink,
                            slot = 16,
                            slotName = "Main Hand (1H + Off-Hand Combo vs 2H)",
                            source = cand.source,
                            candScore = comboScore,
                            curScore = curWeaponComboScore,
                            gain = diff,
                            gainPct = pct
                        })
                    end
                else
                    if candScore > (curMHScore * 1.03) then
                        seenUpgrades[itemLink] = true
                        local diff = candScore - curMHScore
                        local pct = curMHScore > 0 and ((diff / curMHScore) * 100) or 100
                        table.insert(upgrades, {
                            name = itemName,
                            link = itemLink,
                            slot = 16,
                            slotName = "Main Hand",
                            source = cand.source,
                            candScore = candScore,
                            curScore = curMHScore,
                            gain = diff,
                            gainPct = pct
                        })
                    end
                end

            -- C. Off-Hand / Shield / Holdable Candidate
            elseif equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then
                if isEquipped2H then
                    if bestAvail1H then
                        local comboScore = bestAvail1H.score + candScore
                        if comboScore > (curWeaponComboScore * 1.03) then
                            seenUpgrades[itemLink] = true
                            local diff = comboScore - curWeaponComboScore
                            local pct = curWeaponComboScore > 0 and ((diff / curWeaponComboScore) * 100) or 100
                            table.insert(upgrades, {
                                name = bestAvail1H.name .. " + " .. itemName,
                                link = itemLink,
                                slot = 17,
                                slotName = "Off-Hand (1H + Off-Hand Combo vs 2H)",
                                source = cand.source,
                                candScore = comboScore,
                                curScore = curWeaponComboScore,
                                gain = diff,
                                gainPct = pct
                            })
                        end
                    end
                else
                    if candScore > (curOHScore * 1.03) then
                        seenUpgrades[itemLink] = true
                        local diff = candScore - curOHScore
                        local pct = curOHScore > 0 and ((diff / curOHScore) * 100) or 100
                        table.insert(upgrades, {
                            name = itemName,
                            link = itemLink,
                            slot = 17,
                            slotName = "Off-Hand",
                            source = cand.source,
                            candScore = candScore,
                            curScore = curOHScore,
                            gain = diff,
                            gainPct = pct
                        })
                    end
                end

            -- D. Rings (Slot 11 & Slot 12: compare against the lowest-scored equipped ring)
            elseif equipLoc == "INVTYPE_FINGER" then
                local r1 = equippedAudit.slots[11]
                local r2 = equippedAudit.slots[12]
                local r1Score = r1 and r1.score or 0
                local r2Score = r2 and r2.score or 0
                local targetSlot = (r1Score <= r2Score) and 11 or 12
                local lowestScore = math.min(r1Score, r2Score)

                if candScore > (lowestScore * 1.03) then
                    seenUpgrades[itemLink] = true
                    local diff = candScore - lowestScore
                    local pct = lowestScore > 0 and ((diff / lowestScore) * 100) or 100
                    table.insert(upgrades, {
                        name = itemName,
                        link = itemLink,
                        slot = targetSlot,
                        slotName = string.format("Finger (Slot %d)", targetSlot),
                        source = cand.source,
                        candScore = candScore,
                        curScore = lowestScore,
                        gain = diff,
                        gainPct = pct
                    })
                end

            -- E. Trinkets (Slot 13 & Slot 14: compare against the lowest-scored equipped trinket)
            elseif equipLoc == "INVTYPE_TRINKET" then
                local t1 = equippedAudit.slots[13]
                local t2 = equippedAudit.slots[14]
                local t1Score = t1 and t1.score or 0
                local t2Score = t2 and t2.score or 0
                local targetSlot = (t1Score <= t2Score) and 13 or 14
                local lowestScore = math.min(t1Score, t2Score)

                if candScore > (lowestScore * 1.03) then
                    seenUpgrades[itemLink] = true
                    local diff = candScore - lowestScore
                    local pct = lowestScore > 0 and ((diff / lowestScore) * 100) or 100
                    table.insert(upgrades, {
                        name = itemName,
                        link = itemLink,
                        slot = targetSlot,
                        slotName = string.format("Trinket (Slot %d)", targetSlot),
                        source = cand.source,
                        candScore = candScore,
                        curScore = lowestScore,
                        gain = diff,
                        gainPct = pct
                    })
                end

            -- F. All other single armor/accessory slots
            else
                local targetSlots = {}
                if equipLoc == "INVTYPE_HEAD" then targetSlots = { 1 }
                elseif equipLoc == "INVTYPE_NECK" then targetSlots = { 2 }
                elseif equipLoc == "INVTYPE_SHOULDER" then targetSlots = { 3 }
                elseif equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE" then targetSlots = { 5 }
                elseif equipLoc == "INVTYPE_WAIST" then targetSlots = { 6 }
                elseif equipLoc == "INVTYPE_LEGS" then targetSlots = { 7 }
                elseif equipLoc == "INVTYPE_FEET" then targetSlots = { 8 }
                elseif equipLoc == "INVTYPE_WRIST" then targetSlots = { 9 }
                elseif equipLoc == "INVTYPE_HAND" then targetSlots = { 10 }
                elseif equipLoc == "INVTYPE_CLOAK" then targetSlots = { 15 }
                elseif equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN" or equipLoc == "INVTYPE_RELIC" then targetSlots = { 18 }
                end

                for _, slot in ipairs(targetSlots) do
                    local curEquipped = equippedAudit.slots[slot]
                    local curScore = curEquipped and curEquipped.score or 0

                    if candScore > (curScore * 1.03) then
                        seenUpgrades[itemLink] = true
                        local scoreDiff = candScore - curScore
                        local pctGain = curScore > 0 and ((scoreDiff / curScore) * 100) or 100
                        table.insert(upgrades, {
                            name = itemName,
                            link = itemLink,
                            slot = slot,
                            slotName = ENCHANTABLE_SLOTS[slot] or ("Slot " .. slot),
                            source = cand.source,
                            candScore = candScore,
                            curScore = curScore,
                            gain = scoreDiff,
                            gainPct = pctGain
                        })
                        break
                    end
                end
            end
        end
    end

    table.sort(upgrades, function(a, b) return a.gain > b.gain end)
    return upgrades
end

-- =====================================================================
-- 3. DYNAMIC TALENT EVALUATION & SIMULATION-DRIVEN OPTIMIZER
-- (Zero hardcoded spec tables: dynamically evaluates simulation profiles,
-- spell mechanics, Synastria perks, glyphs, and prerequisite tiers)
-- =====================================================================

local TALENT_MECHANICS_REGISTRY = {
    -- Critical Strike Multipliers & Keystone Amplifiers
    ["Ignite"] = { role = "crit_multiplier", weight = 120, aoeScale = 1.25, perkCategory = "Class" },
    ["Burnout"] = { role = "crit_multiplier", weight = 115, aoeScale = 1.20, perkCategory = "Class" },
    ["Ruin"] = { role = "crit_multiplier", weight = 115, aoeScale = 1.20 },
    ["Spell Power"] = { role = "crit_multiplier", weight = 115, aoeScale = 1.15 },
    ["Righteous Vengeance"] = { role = "crit_multiplier", weight = 110, aoeScale = 1.20 },
    ["Impale"] = { role = "crit_multiplier", weight = 110, aoeScale = 1.20 },
    ["Mortal Shots"] = { role = "crit_multiplier", weight = 110, aoeScale = 1.15 },
    ["Lethality"] = { role = "crit_multiplier", weight = 105, aoeScale = 1.15 },
    ["Vengeance"] = { role = "crit_multiplier", weight = 105, aoeScale = 1.15 },
    ["Elemental Fury"] = { role = "crit_multiplier", weight = 115, aoeScale = 1.25 },
    ["Surprise Attacks"] = { role = "crit_multiplier", weight = 100 },
    ["Shadow Power"] = { role = "crit_multiplier", weight = 105 },

    -- Signature Procs & Rotational Keystones
    ["Hot Streak"] = { role = "signature_proc", weight = 120, aoeScale = 1.30, perkCategory = "Class" },
    ["Living Bomb"] = { role = "signature_spell", weight = 115, aoeScale = 1.45, isAoE = true, perkCategory = "Class" },
    ["Firestarter"] = { role = "signature_proc", weight = 110, aoeScale = 1.50, isAoE = true, perkCategory = "Class" },
    ["Blast Wave"] = { role = "signature_spell", weight = 95, aoeScale = 1.40, isAoE = true, perkCategory = "Offensive" },
    ["Dragon's Breath"] = { role = "signature_spell", weight = 95, aoeScale = 1.40, isAoE = true, perkCategory = "Offensive" },
    ["Combustion"] = { role = "cooldown", weight = 100, aoeScale = 1.20 },
    ["Pyroblast"] = { role = "signature_spell", weight = 95, aoeScale = 1.10 },
    ["Missile Barrage"] = { role = "signature_proc", weight = 115 },
    ["Arcane Power"] = { role = "cooldown", weight = 110 },
    ["Presence of Mind"] = { role = "cooldown", weight = 95 },
    ["Deep Freeze"] = { role = "signature_spell", weight = 110 },
    ["Icy Veins"] = { role = "cooldown", weight = 110 },
    ["Fingers of Frost"] = { role = "signature_proc", weight = 115 },
    ["Brain Freeze"] = { role = "signature_proc", weight = 110 },
    ["Water Elemental"] = { role = "pet", weight = 105 },
    ["Cold Snap"] = { role = "cooldown", weight = 90 },

    -- Physical / Hybrid Keystones
    ["Bloodthirst"] = { role = "signature_spell", weight = 120 },
    ["Death Wish"] = { role = "cooldown", weight = 115 },
    ["Titan's Grip"] = { role = "keystone", weight = 130 },
    ["Improved Whirlwind"] = { role = "aoe_mult", weight = 100, aoeScale = 1.45, isAoE = true },
    ["Bloodsurge"] = { role = "signature_proc", weight = 110 },
    ["Blade Flurry"] = { role = "aoe_mult", weight = 115, aoeScale = 1.50, isAoE = true },
    ["Adrenaline Rush"] = { role = "cooldown", weight = 115 },
    ["Killing Spree"] = { role = "cooldown", weight = 115, aoeScale = 1.30, isAoE = true },
    ["Divine Storm"] = { role = "signature_spell", weight = 120, aoeScale = 1.40, isAoE = true },
    ["Crusader Strike"] = { role = "signature_spell", weight = 115 },
    ["The Art of War"] = { role = "signature_proc", weight = 110 },
    ["Shadowform"] = { role = "keystone", weight = 125 },
    ["Vampiric Touch"] = { role = "signature_spell", weight = 115 },
    ["Mind Flay"] = { role = "signature_spell", weight = 115 },
    ["Haunt"] = { role = "signature_spell", weight = 120 },
    ["Unstable Affliction"] = { role = "signature_spell", weight = 115 },
    ["Chaos Bolt"] = { role = "signature_spell", weight = 120 },
    ["Howling Blast"] = { role = "signature_spell", weight = 120, aoeScale = 1.50, isAoE = true },
    ["Deathchill"] = { role = "cooldown", weight = 95 },
    ["Explosive Shot"] = { role = "signature_spell", weight = 125, aoeScale = 1.25 },
    ["Lock and Load"] = { role = "signature_proc", weight = 120 },
    ["Black Arrow"] = { role = "signature_spell", weight = 115 },
    ["Starfall"] = { role = "cooldown", weight = 120, aoeScale = 1.50, isAoE = true },
    ["Eclipse"] = { role = "signature_proc", weight = 120 },
    ["Typhoon"] = { role = "signature_spell", weight = 95, aoeScale = 1.40, isAoE = true },
    ["Thunderstorm"] = { role = "signature_spell", weight = 100, aoeScale = 1.35, isAoE = true },
    ["Elemental Mastery"] = { role = "cooldown", weight = 110 },
    ["Lava Flows"] = { role = "signature_proc", weight = 110 },

    -- Hit Rating & Accuracy (Essential until capped)
    ["Arcane Focus"] = { role = "hit", weight = 90, stat = "SpellHit" },
    ["Precision"] = { role = "hit", weight = 90, stat = "SpellHit" },
    ["Suppression"] = { role = "hit", weight = 90, stat = "SpellHit" },
    ["Shadow Focus"] = { role = "hit", weight = 90, stat = "SpellHit" },
    ["Balance of Power"] = { role = "hit", weight = 90, stat = "SpellHit" },
    ["Elemental Precision"] = { role = "hit", weight = 90, stat = "SpellHit" },
    ["Focused Aim"] = { role = "hit", weight = 90, stat = "PhysicalHit" },
    ["Nerves of Cold Steel"] = { role = "hit", weight = 90, stat = "PhysicalHit" },

    -- Percentage Damage Multipliers & Modifiers
    ["Torment the Weak"] = { role = "damage_multiplier", weight = 95, aoeScale = 1.15 },
    ["Fire Power"] = { role = "damage_multiplier", weight = 90, aoeScale = 1.20 },
    ["Playing with Fire"] = { role = "damage_multiplier", weight = 88, aoeScale = 1.15 },
    ["Molten Fury"] = { role = "execute_multiplier", weight = 90 },
    ["World in Flames"] = { role = "crit_chance", weight = 85, aoeScale = 1.35, isAoE = true },
    ["Critical Mass"] = { role = "crit_chance", weight = 85, aoeScale = 1.15 },
    ["Pyromaniac"] = { role = "crit_chance", weight = 80, aoeScale = 1.15 },
    ["Darkness"] = { role = "damage_multiplier", weight = 90 },
    ["Shadow Mastery"] = { role = "damage_multiplier", weight = 90 },
    ["Two-Handed Weapon Specialization"] = { role = "damage_multiplier", weight = 90 },
    ["Dual Wield Specialization"] = { role = "damage_multiplier", weight = 90 },
    ["Aggression"] = { role = "damage_multiplier", weight = 88 },
    ["Crusade"] = { role = "damage_multiplier", weight = 90 },
    ["Sanctified Retribution"] = { role = "damage_multiplier", weight = 90 },
    ["Earth and Moon"] = { role = "damage_multiplier", weight = 92 },
    ["Wrath of Cenarius"] = { role = "damage_multiplier", weight = 90 },
    ["Piercing Ice"] = { role = "damage_multiplier", weight = 88 },
    ["Arctic Gale"] = { role = "damage_multiplier", weight = 85 },
    ["Arcane Instability"] = { role = "damage_multiplier", weight = 88 },
    ["Arcane Empowerment"] = { role = "damage_multiplier", weight = 90 },
    ["Tundra Stalker"] = { role = "damage_multiplier", weight = 90 },
    ["Master Tactician"] = { role = "crit_chance", weight = 85 },
    ["Sniper Training"] = { role = "damage_multiplier", weight = 92 },
    ["Concussion"] = { role = "damage_multiplier", weight = 85 },
    ["Call of Flame"] = { role = "damage_multiplier", weight = 88 },

    -- Coefficient & Stat Scaling
    ["Empowered Fire"] = { role = "stat_coeff", weight = 88, aoeScale = 1.10 },
    ["Empowered Corruption"] = { role = "stat_coeff", weight = 88 },
    ["Sheath of Light"] = { role = "stat_coeff", weight = 90 },
    ["Twisted Faith"] = { role = "stat_coeff", weight = 90 },
    ["Mind Mastery"] = { role = "stat_coeff", weight = 85 },
    ["Armored to the Teeth"] = { role = "stat_coeff", weight = 88 },
    ["Demonic Knowledge"] = { role = "stat_coeff", weight = 88 },
    ["Hunter vs. Wild"] = { role = "stat_coeff", weight = 85 },
    ["Student of the Mind"] = { role = "stat_coeff", weight = 75 },
    ["Arcane Mind"] = { role = "stat_coeff", weight = 80 },
    ["Divine Strength"] = { role = "stat_coeff", weight = 82 },
    ["Mental Agility"] = { role = "stat_coeff", weight = 78 },

    -- Cast Time Reduction & Haste
    ["Improved Fireball"] = { role = "cast_time", weight = 85 },
    ["Bane"] = { role = "cast_time", weight = 85 },
    ["Starlight Wrath"] = { role = "cast_time", weight = 85 },
    ["Lightning Mastery"] = { role = "cast_time", weight = 85 },
    ["Icy Talons"] = { role = "haste", weight = 88 },
    ["Flurry"] = { role = "haste", weight = 88 },
    ["Netherwind Presence"] = { role = "haste", weight = 85 },
    ["Swift Retribution"] = { role = "haste", weight = 85 },
    ["Celestial Focus"] = { role = "haste", weight = 80 },

    -- Clearcasting & Resource Engine / Utilities
    ["Arcane Concentration"] = { role = "clearcasting", weight = 80 },
    ["Master of Elements"] = { role = "resource", weight = 75 },
    ["Burning Soul"] = { role = "utility", weight = 70 },
    ["Flame Throwing"] = { role = "utility", weight = 72 },
    ["Focus Magic"] = { role = "buff", weight = 82 },
    ["Meditation"] = { role = "resource", weight = 70 },
    ["Judgements of the Wise"] = { role = "resource", weight = 80 },
    ["Combat Potency"] = { role = "resource", weight = 82 },
    ["Thrill of the Hunt"] = { role = "resource", weight = 75 },
    ["Omen of Clarity"] = { role = "clearcasting", weight = 82 },
    ["Elemental Focus"] = { role = "clearcasting", weight = 80 },
    ["Nightfall"] = { role = "clearcasting", weight = 82 }
}

local function CalculateTalentDynamicWeight(name, tab, tier, maxRank, specName, pClass, sims, perks, glyphs)
    local reg = TALENT_MECHANICS_REGISTRY[name]
    local damageWeight = 50
    local speedWeight = 0
    local survivabilityWeight = 0

    if reg then
        damageWeight = reg.weight or 50

        -- 1. Multi-Target Simulation Scaling (Cleave & AoE)
        if reg.isAoE or (reg.aoeScale and reg.aoeScale > 1.0) then
            local cleaveMult = 1.0 + ((reg.aoeScale or 1.25) - 1.0) * 0.50
            local aoeMult = 1.0 + ((reg.aoeScale or 1.25) - 1.0) * 0.80
            local blendedMultiplier = (0.50 * 1.0) + (0.25 * cleaveMult) + (0.25 * aoeMult)
            damageWeight = damageWeight * blendedMultiplier
        end

        -- 2. Speed & Movement Uptime Contributions
        if reg.role == "cast_time" or reg.role == "haste" then
            speedWeight = 35
        elseif name == "Flame Throwing" or name == "Shadow Reach" or name == "Hawk Eye" or name == "Elemental Reach" then
            speedWeight = 30 -- Range increases effective movement uptime during boss mechanics
        elseif name == "Firestarter" or name == "Presence of Mind" or name == "The Art of War" or name == "Brain Freeze" then
            speedWeight = 25 -- Instant cast mobility without clipping
        end

        -- 3. Survivability, Threat Suppression & Resource Endurance Contributions
        if name == "Burning Soul" then
            survivabilityWeight = 45 -- -20% Threat + 70% Pushback protection is critical for raid survival & unbroken DPS
        elseif name == "Incanter's Absorption" or name == "Ice Barrier" or name == "Mana Shield" or name == "Molten Shields" or name == "Fiery Payback" then
            survivabilityWeight = 35 -- Mitigation & absorption shields
        elseif name == "Master of Elements" or name == "Arcane Concentration" or name == "Meditation" or name == "Judgements of the Wise" or name == "Combat Potency" then
            survivabilityWeight = 25 -- Mana/resource endurance over long enrage fights
        elseif reg.role == "utility" or reg.role == "resource" or reg.role == "clearcasting" then
            survivabilityWeight = 20
        end

        -- 4. Synastria Category Perks Scaling
        if reg.perkCategory and perks and perks[reg.perkCategory] and perks[reg.perkCategory] > 0 then
            damageWeight = damageWeight * (1.0 + 0.05 * math.min(perks[reg.perkCategory], 5))
        end
    else
        -- Heuristic semantic parsing
        local lowerName = string.lower(name)
        if string.find(lowerName, "power") or string.find(lowerName, "damage") or string.find(lowerName, "fury") or string.find(lowerName, "strike") then
            damageWeight = 75
        elseif string.find(lowerName, "crit") or string.find(lowerName, "impact") or string.find(lowerName, "precision") or string.find(lowerName, "focus") then
            damageWeight = 80
        elseif string.find(lowerName, "improved") or string.find(lowerName, "empowered") then
            damageWeight = 70
        elseif string.find(lowerName, "mastery") or string.find(lowerName, "specialization") then
            damageWeight = 85
        end
        if string.find(lowerName, "ward") or string.find(lowerName, "shield") or string.find(lowerName, "soul") or string.find(lowerName, "absorb") or string.find(lowerName, "armor") then
            survivabilityWeight = 30
        end
    end

    -- 5. Dynamic Synastria Perk Prerequisite & Direct Spell/Talent Synergies
    local activePerksForTalent = (FC.extState and FC.extState.talentToPerks and FC.extState.talentToPerks[name])
    local activePerksForSpell = (FC.extState and FC.extState.spellToPerks and FC.extState.spellToPerks[name])

    if activePerksForTalent or activePerksForSpell then
        local count = (activePerksForTalent and #activePerksForTalent or 0) + (activePerksForSpell and #activePerksForSpell or 0)
        damageWeight = damageWeight + (80 * math.min(count, 3))
        speedWeight = speedWeight + 25
        survivabilityWeight = survivabilityWeight + 25
    end

    -- 6. Approach-Driven Dynamic Pillar Weights
    local approach = (FC.db and FC.db.combatApproach) or "Balanced"
    local totalScore = 0

    if approach == "ST Damage" then
        -- 70% ST Damage Focus + 15% Speed & Cast Uptime + 15% Survivability
        totalScore = (damageWeight * 0.70) + (speedWeight * 0.15) + (survivabilityWeight * 0.15) + (tier or 1) * 2.5
    elseif approach == "AOE Damage" then
        -- Emphasize AoE talents heavily
        local aoeFactor = (reg and reg.isAoE and 1.5) or 1.0
        totalScore = (damageWeight * aoeFactor * 0.65) + (speedWeight * 0.20) + (survivabilityWeight * 0.15) + (tier or 1) * 2.5
    elseif approach == "Survival/PVP" then
        -- 55% Survivability & EHP + 25% Damage + 20% Speed/Mobility
        totalScore = (survivabilityWeight * 0.55) + (damageWeight * 0.25) + (speedWeight * 0.20) + (tier or 1) * 2.5
    else
        -- Balanced Tri-Pillar: 50% Damage Output + 25% Speed & Resource Sustain + 25% Survivability & Threat Headroom
        totalScore = (damageWeight * 0.50) + (speedWeight * 0.25) + (survivabilityWeight * 0.25) + (tier or 1) * 2.5
    end

    return totalScore
end

function FC:CalculateDynamicTalentBuild(specName)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"
    local sims = (self.RunSimulationBenchmarks and self:RunSimulationBenchmarks(specName)) or { boss = 35000, cleave = 44000, aoe = 65000 }
    local perks = (self.extState and self.extState.activePerkCounts) or {}
    local glyphs = (self.extState and self.extState.activeGlyphs) or {}

    local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3
    local primaryTab = 1
    local tabNames = {}

    -- Identify Primary Tab matching specName
    for tab = 1, numTabs do
        local tabName = (GetTalentTabInfo and GetTalentTabInfo(tab)) or ""
        tabNames[tab] = tabName
        if string.lower(tabName) == string.lower(specName) then
            primaryTab = tab
        end
    end

    -- Fallback primary tab mapping if tab names didn't match directly
    if primaryTab == 1 and string.lower(tabNames[1] or "") ~= string.lower(specName) then
        if pClass == "MAGE" then
            primaryTab = (specName == "Fire" and 2) or (specName == "Frost" and 3) or 1
        elseif pClass == "WARRIOR" then
            primaryTab = (specName == "Fury" and 2) or (specName == "Protection" and 3) or 1
        elseif pClass == "PALADIN" then
            primaryTab = (specName == "Protection" and 2) or (specName == "Retribution" and 3) or 1
        elseif pClass == "PRIEST" then
            primaryTab = (specName == "Holy" and 2) or (specName == "Shadow" and 3) or 1
        elseif pClass == "WARLOCK" then
            primaryTab = (specName == "Demonology" and 2) or (specName == "Destruction" and 3) or 1
        elseif pClass == "ROGUE" then
            primaryTab = (specName == "Combat" and 2) or (specName == "Subtlety" and 3) or 1
        elseif pClass == "DEATHKNIGHT" then
            primaryTab = (specName == "Frost" and 2) or (specName == "Unholy" and 3) or 1
        elseif pClass == "HUNTER" then
            primaryTab = (specName == "Marksmanship" and 2) or (specName == "Survival" and 3) or 1
        elseif pClass == "DRUID" then
            primaryTab = (specName == "Feral Combat" and 2) or (specName == "Restoration" and 3) or 1
        elseif pClass == "SHAMAN" then
            primaryTab = (specName == "Enhancement" and 2) or (specName == "Restoration" and 3) or 1
        end
    end

    -- Scan all talents across all tabs
    local treeTalents = {}
    for tab = 1, numTabs do
        treeTalents[tab] = {}
        local numTalents = (GetNumTalents and GetNumTalents(tab)) or 0
        for i = 1, numTalents do
            local name, iconTexture, tier, column, currentRank, maxRank = GetTalentInfo(tab, i)
            if name and maxRank and maxRank > 0 then
                local dynamicWeight = CalculateTalentDynamicWeight(name, tab, tier, maxRank, specName, pClass, sims, perks, glyphs)
                table.insert(treeTalents[tab], {
                    index = i,
                    name = name,
                    tab = tab,
                    tier = tier or 1,
                    column = column or 1,
                    maxRank = maxRank,
                    currentRank = currentRank or 0,
                    weight = dynamicWeight,
                    allocated = 0
                })
            end
        end
    end

    -- Total talent points to allocate (Standard 71 at lvl 80, or player max points)
    local totalPoints = (UnitLevel and math.max(0, UnitLevel("player") - 9)) or 71
    if totalPoints < 71 then totalPoints = 71 end

    local recTalents = {}
    local tabPoints = { [1] = 0, [2] = 0, [3] = 0 }

    -- 1. PRIMARY TREE OPTIMIZATION PASS (Target: 51-54 points into primary tree to reach tier 9-11 keystones)
    local primaryTargetPoints = math.min(54, totalPoints)
    local pointsSpentInPrimary = 0

    while pointsSpentInPrimary < primaryTargetPoints do
        local bestNode = nil
        local bestScore = -1

        for _, t in ipairs(treeTalents[primaryTab] or {}) do
            if t.allocated < t.maxRank then
                local reqPoints = (t.tier - 1) * 5
                if tabPoints[primaryTab] >= reqPoints then
                    if t.weight > bestScore then
                        bestScore = t.weight
                        bestNode = t
                    end
                end
            end
        end

        if bestNode then
            bestNode.allocated = bestNode.allocated + 1
            tabPoints[primaryTab] = tabPoints[primaryTab] + 1
            pointsSpentInPrimary = pointsSpentInPrimary + 1
            recTalents[bestNode.name] = bestNode.allocated
        else
            local fillerNode = nil
            local fillerScore = -1
            for _, t in ipairs(treeTalents[primaryTab] or {}) do
                if t.allocated < t.maxRank and tabPoints[primaryTab] >= (t.tier - 1) * 5 then
                    if t.weight > fillerScore then
                        fillerScore = t.weight
                        fillerNode = t
                    end
                end
            end
            if fillerNode then
                fillerNode.allocated = fillerNode.allocated + 1
                tabPoints[primaryTab] = tabPoints[primaryTab] + 1
                pointsSpentInPrimary = pointsSpentInPrimary + 1
                recTalents[fillerNode.name] = fillerNode.allocated
            else
                break
            end
        end
    end

    -- 2. SECONDARY / SPLASH TREES OPTIMIZATION PASS (Allocate remaining points: 17-20 pts)
    local remainingPoints = totalPoints - tabPoints[primaryTab]
    while remainingPoints > 0 do
        local bestNode = nil
        local bestScore = -1
        local bestTab = nil

        for tab = 1, numTabs do
            if tab ~= primaryTab then
                for _, t in ipairs(treeTalents[tab] or {}) do
                    if t.allocated < t.maxRank then
                        local reqPoints = (t.tier - 1) * 5
                        if tabPoints[tab] >= reqPoints then
                            if t.weight > bestScore then
                                bestScore = t.weight
                                bestNode = t
                                bestTab = tab
                            end
                        end
                    end
                end
            end
        end

        if bestNode and bestTab then
            bestNode.allocated = bestNode.allocated + 1
            tabPoints[bestTab] = tabPoints[bestTab] + 1
            remainingPoints = remainingPoints - 1
            recTalents[bestNode.name] = bestNode.allocated
        else
            local fillerNode = nil
            local fillerScore = -1
            local fillerTab = nil
            for tab = 1, numTabs do
                if tab ~= primaryTab then
                    for _, t in ipairs(treeTalents[tab] or {}) do
                        if t.allocated < t.maxRank and tabPoints[tab] >= (t.tier - 1) * 5 then
                            if t.weight > fillerScore then
                                fillerScore = t.weight
                                fillerNode = t
                                fillerTab = tab
                            end
                        end
                    end
                end
            end
            if fillerNode and fillerTab then
                fillerNode.allocated = fillerNode.allocated + 1
                tabPoints[fillerTab] = tabPoints[fillerTab] + 1
                remainingPoints = remainingPoints - 1
                recTalents[fillerNode.name] = fillerNode.allocated
            else
                break
            end
        end
    end

    return recTalents, primaryTab, tabPoints
end

function FC:GetRecommendedTalents(specName)
    return self:CalculateDynamicTalentBuild(specName)
end

-- =====================================================================
-- FLOWCORE TALENT & PERK SIDE-PANEL UI & RECURSIVE OVERLAY ENGINE
-- =====================================================================
local function CreateOrGetSidePanel(parentFrame, specName)
    if not FC.sidePanel then
        local p = CreateFrame("Frame", "FlowCoreTalentSidePanel", UIParent)
        p:SetFrameStrata("HIGH")
        p:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        p:SetBackdropColor(0.04, 0.04, 0.07, 0.96)
        p:SetBackdropBorderColor(0.0, 0.75, 1.0, 0.85)

        -- Title
        local title = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -12)
        title:SetText("|cff00ccffFlowCore Build Advisor|r")
        p.title = title

        local subtitle = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        p.subtitle = subtitle

        -- Close Button
        local closeBtn = CreateFrame("Button", nil, p, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", p, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() p:Hide() end)

        -- Scroll Container
        local scrollFrame = CreateFrame("ScrollFrame", "FlowCoreTalentSidePanelScroll", p, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -8)
        scrollFrame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -28, 10)

        local content = CreateFrame("Frame", "FlowCoreTalentSidePanelContent", scrollFrame)
        content:SetSize(240, 600)
        scrollFrame:SetScrollChild(content)

        local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        text:SetWidth(230)
        text:SetJustifyH("LEFT")
        text:SetSpacing(3)
        p.bodyText = text

        FC.sidePanel = p
    end

    local p = FC.sidePanel
    if parentFrame and parentFrame:IsVisible() then
        p:ClearAllPoints()
        p:SetPoint("TOPRIGHT", parentFrame, "TOPLEFT", -6, 0)
        p:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMLEFT", -6, 0)
        p:SetWidth(275)
        p:Show()
    end

    return p
end

function FC:UpdateTalentSidePanel(specName, activeFrame)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    local panel = CreateOrGetSidePanel(activeFrame, specName)
    if not panel or not panel:IsVisible() then return end

    panel.subtitle:SetText(string.format("Active Spec: |cffffd700[%s]|r", specName))

    local syn = (self.AnalyzeBuildSynergies and self:AnalyzeBuildSynergies(specName)) or {}
    local sims = (self.RunSimulationBenchmarks and self:RunSimulationBenchmarks(specName)) or { single = 0, cleave = 0, aoe = 0 }

    local lines = {}
    table.insert(lines, "|cff00ccff=== 1. Synastria Perks by Category ===|r")
    for _, p in ipairs(syn.perks or {}) do
        if p.category == "Misc" then
            table.insert(lines, string.format("%s |cffffd700%s (%d Active):|r\n  |cff888888%d Automation & QoL Perks active|r",
                p.status, p.category, p.count, p.count))
        else
            table.insert(lines, string.format("%s |cffffd700%s (%d/%d):|r\n  |cffdddddd%s|r%s",
                p.status, p.category, p.count, p.max, p.perksStr,
                (p.recommendationStr and p.recommendationStr ~= "") and ("\n  " .. p.recommendationStr) or ""))
        end
    end

    table.insert(lines, "\n|cff00ccff=== 2. Perk Prerequisites & Talents Met ===|r")
    if syn.perkPrerequisites and #syn.perkPrerequisites > 0 then
        for _, req in ipairs(syn.perkPrerequisites) do
            table.insert(lines, string.format("%s |cffffd700%s|r\n  %s", req.status, req.name, req.desc))
        end
    else
        table.insert(lines, "  |cff55ff55[PREREQS MET]|r |cffffd700Active Perks Synchronized|r\n  |cff888888All active perk prerequisites & talent synergies satisfied.|r")
    end

    table.insert(lines, "\n|cff00ccff=== 3. Equipped & Optimal Glyphs ===|r")
    for _, g in ipairs(syn.glyphs or {}) do
        table.insert(lines, string.format("%s |cffffd700%s|r\n  |cff888888%s|r", g.status, g.name, g.desc))
    end

    table.insert(lines, "\n|cff00ccff=== 4. Simulation Benchmarks (Optimal Cooldowns & Uptime) ===|r")
    table.insert(lines, string.format("• |cffffd70025H Boss|r (Lich King):\n  |cff55ff55~%d DPS|r (Optimal CD Cycle + Molten Fury)", sims.single or 0))
    table.insert(lines, string.format("• |cffffd700Cleave|r (L82 Elite x3):\n  |cff55ff55~%d DPS|r (3x LB Multi-Dot + HS Weaving)", sims.cleave or 0))
    table.insert(lines, string.format("• |cffffd700Mass AOE|r (6+ Targets):\n  |cff55ff55~%d DPS|r (Dual Flamestrike + Firestarter)", sims.aoe or 0))
    table.insert(lines, string.format("• |cffffd700Speed & Cast Uptime|r:\n  |cff00ffcc%s|r", sims.speedRating or "Optimal 1.00s GCD Floor (41yd Range)"))
    table.insert(lines, string.format("• |cffffd700Survivability & Threat|r:\n  |cff00ffcc%s|r", sims.survivabilityRating or "High (92% Pushback Immunity, -20% Threat)"))

    table.insert(lines, "\n|cff00ccff=== 5. Talent Overlay Color Key ===|r")
    table.insert(lines, "• |cff55ff55● Green|r: Recommended (0 spent)")
    table.insert(lines, "• |cff888888● Gray|r: Optimal (Matches build)")
    table.insert(lines, "• |cffff2222● Red|r: Under-spent / Missing")
    table.insert(lines, "• |cffffaa00● Orange|r: Over-allocated")

    panel.bodyText:SetText(table.concat(lines, "\n"))
end

local function ApplyOverlayBadge(btn, name, currentRank, recRank)
    if not btn then return end

    if not btn.fcOverlay then
        local overlay = CreateFrame("Frame", nil, btn)
        overlay:SetAllPoints(btn)
        overlay:SetFrameStrata("TOOLTIP")
        overlay:SetFrameLevel(btn:GetFrameLevel() + 60)

        local bg = overlay:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, 2)
        bg:SetWidth(18)
        bg:SetHeight(18)
        bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bg:SetVertexColor(0, 0, 0, 0.92)

        local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        text:SetPoint("CENTER", bg, "CENTER", 0, 0)
        text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

        overlay.bg = bg
        overlay.text = text
        btn.fcOverlay = overlay
    end

    currentRank = tonumber(currentRank) or 0
    recRank = tonumber(recRank) or 0

    -- 1. OVER-ALLOCATED (Orange: Points allocated exceed recommendation, including non-zero on 0-point talents)
    if currentRank > recRank then
        btn.fcOverlay.text:SetText(tostring(recRank))
        btn.fcOverlay.text:SetTextColor(1.0, 0.65, 0.0, 1.0) -- Vibrant Orange
        btn.fcOverlay.bg:SetVertexColor(0.40, 0.22, 0.0, 0.92)
        btn.fcOverlay:Show()

    -- 2. OPTIMAL (Gray: Allocated points exactly match recommended points)
    elseif recRank > 0 and currentRank == recRank then
        btn.fcOverlay.text:SetText(tostring(recRank))
        btn.fcOverlay.text:SetTextColor(0.70, 0.70, 0.70, 1.0) -- Optimal Gray
        btn.fcOverlay.bg:SetVertexColor(0.15, 0.15, 0.15, 0.90)
        btn.fcOverlay:Show()

    -- 3. UNDER-SPENT / PARTIALLY ASSIGNED (Red: Player allocated fewer points than recommended, but > 0)
    elseif recRank > currentRank and currentRank > 0 then
        btn.fcOverlay.text:SetText(tostring(recRank))
        btn.fcOverlay.text:SetTextColor(1.0, 0.2, 0.2, 1.0) -- Missing Red
        btn.fcOverlay.bg:SetVertexColor(0.45, 0.05, 0.05, 0.92)
        btn.fcOverlay:Show()

    -- 4. RECOMMENDED BUT UNSPENT (Green: 0 points allocated into a recommended talent)
    elseif recRank > 0 and currentRank == 0 then
        btn.fcOverlay.text:SetText(tostring(recRank))
        btn.fcOverlay.text:SetTextColor(0.2, 1.0, 0.2, 1.0) -- Recommended Green
        btn.fcOverlay.bg:SetVertexColor(0.05, 0.40, 0.05, 0.92)
        btn.fcOverlay:Show()

    -- 5. NOT IN BUILD & UNSPENT (recRank == 0 and currentRank == 0)
    else
        if btn.fcOverlay then
            btn.fcOverlay:Hide()
        end
    end
end

local function BuildTalentMetadataTables()
    local texMap = {}
    local tabIdMap = {}

    for tab = 1, 3 do
        local num = GetNumTalents(tab) or 0
        for i = 1, num do
            local name, iconTexture, tier, column, currentRank, maxRank = GetTalentInfo(tab, i)
            if name then
                local data = {
                    name = name,
                    tab = tab,
                    id = i,
                    currentRank = currentRank or 0,
                    maxRank = maxRank or 5,
                    iconTexture = iconTexture
                }
                tabIdMap[tab .. "_" .. i] = data
                if iconTexture then
                    local norm = string.lower(string.gsub(iconTexture, "\\", "/"))
                    texMap[norm] = data
                    local base = string.match(norm, "[^/]+$")
                    if base then
                        texMap[base] = data
                    end
                end
            end
        end
    end

    return texMap, tabIdMap
end

local function RecursivelyScanAndOverlay(parentFrame, recTalents, texMap, tabIdMap)
    if not parentFrame or not parentFrame.GetChildren then return end

    local function InspectWidget(w)
        if not w then return end

        local matched = nil

        -- 1. Check tab & id
        local wTab = w.tab or (w.tree and (w.tree.tab or w.tree.id)) or (w:GetParent() and w:GetParent().tab)
        local wId = w.id or w.talent_id or w.talentIndex or w.index
        if wTab and wId and tabIdMap[wTab .. "_" .. wId] then
            matched = tabIdMap[wTab .. "_" .. wId]
        end

        -- 2. Check w.talent table (spell info or name)
        if not matched and w.talent and type(w.talent) == "table" then
            if w.talent.name then
                matched = { name = w.talent.name, currentRank = (w.rank and tonumber(w.rank:GetText())) or w.req or 0 }
            elseif w.talent[1] and type(w.talent[1]) == "number" then
                local sName = GetSpellInfo(w.talent[1])
                if sName then
                    matched = { name = sName, currentRank = (w.rank and tonumber(w.rank:GetText())) or w.req or 0 }
                end
            end
        end

        -- 3. Check direct texture on widget
        if not matched then
            local texObj = w.texture or w.icon or (w.GetNormalTexture and w:GetNormalTexture())
            if texObj and texObj.GetTexture then
                local tex = texObj:GetTexture()
                if tex and type(tex) == "string" then
                    local norm = string.lower(string.gsub(tex, "\\", "/"))
                    local base = string.match(norm, "[^/]+$")
                    matched = texMap[norm] or (base and texMap[base])
                end
            end
        end

        -- 4. Check all texture regions on widget
        if not matched and w.GetRegions then
            local regions = { w:GetRegions() }
            for _, reg in ipairs(regions) do
                if reg and reg.IsObjectType and reg:IsObjectType("Texture") then
                    local tex = reg:GetTexture()
                    if tex and type(tex) == "string" then
                        local norm = string.lower(string.gsub(tex, "\\", "/"))
                        local base = string.match(norm, "[^/]+$")
                        if texMap[norm] or (base and texMap[base]) then
                            matched = texMap[norm] or texMap[base]
                            break
                        end
                    end
                end
            end
        end

        -- 5. Check button name pattern (e.g. PlayerTalentFrameTalent1)
        if not matched and w.GetName and w:GetName() then
            local bName = w:GetName()
            local tIdx = string.match(bName, "PlayerTalentFrameTalent(%d+)")
            if tIdx and tonumber(tIdx) then
                local selTab = (PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(PlayerTalentFrame)) or 1
                matched = tabIdMap[selTab .. "_" .. tIdx]
            end
        end

        -- If matched, apply overlay badge
        if matched and matched.name then
            local curRank = matched.currentRank
            if w.rank and w.rank.GetText then
                curRank = tonumber(w.rank:GetText()) or curRank
            elseif w.req then
                curRank = tonumber(w.req) or curRank
            end
            local recRank = recTalents[matched.name] or 0
            ApplyOverlayBadge(w, matched.name, curRank, recRank)
        end

        -- Recurse into children
        if w.GetChildren then
            local children = { w:GetChildren() }
            for _, child in ipairs(children) do
                InspectWidget(child)
            end
        end
    end

    InspectWidget(parentFrame)
end

function FC:UpdateTalentTreeOverlay()
    local specName = (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    local recTalents, primaryTab = self:GetRecommendedTalents(specName)
    local texMap, tabIdMap = BuildTalentMetadataTables()

    local activeTalentFrame = nil

    -- 1. Direct Talented UI Element & Tree Scan
    if _G["Talented"] then
        local tObj = _G["Talented"]
        local view = (tObj.base and tObj.base.view) or tObj.view
        local baseFrame = tObj.base or _G["TalentedFrame"]
        if baseFrame and baseFrame:IsVisible() then
            activeTalentFrame = baseFrame
            if view then
                for tab = 1, 3 do
                    local numTalents = GetNumTalents(tab) or 0
                    for i = 1, numTalents do
                        local btn = (view.GetUIElement and view:GetUIElement(tab, i)) or (view.elements and view.elements[tab .. "-" .. i])
                        if btn then
                            local name, iconTexture, tier, column, currentRank, maxRank = GetTalentInfo(tab, i)
                            local recRank = (name and recTalents[name]) or 0
                            if name then
                                ApplyOverlayBadge(btn, name, currentRank or 0, recRank)
                            end
                        end
                    end
                end
            end
            RecursivelyScanAndOverlay(baseFrame, recTalents, texMap, tabIdMap)
        end
    end

    -- 2. Scan Blizzard PlayerTalentFrame
    if PlayerTalentFrame and PlayerTalentFrame:IsVisible() then
        if not activeTalentFrame then activeTalentFrame = PlayerTalentFrame end
        RecursivelyScanAndOverlay(PlayerTalentFrame, recTalents, texMap, tabIdMap)
    end

    -- 3. Update Side Panel
    if activeTalentFrame then
        self:UpdateTalentSidePanel(specName, activeTalentFrame)
    elseif self.sidePanel and self.sidePanel:IsVisible() then
        self.sidePanel:Hide()
    end
end

-- =====================================================================
-- 4. SIMULATION PROFILES & ENEMY NPC COMBAT STATS ENGINE
-- (Detailed NPC stats: Health, Mana, Armor, Melee/Ranged Damage, Abilities)
-- =====================================================================
FC.SIMULATION_PROFILES = {
    BOSS = {
        name = "The Lich King",
        title = "The Lich King (25H Heroic Raid Boss)",
        level = 83,
        classification = "worldboss",
        creatureType = "Undead",
        health = 103200000, -- 103.2M HP in 25-Man Heroic
        mana = 3500000,
        armor = 10643, -- 61.4% Base Physical DR -> 48.2% with Sunder Armor 5/5 + Faerie Fire
        meleeDmgMin = 38500,
        meleeDmgMax = 48200,
        meleeSpeed = 1.80, -- ~24,083 DPS base tank damage before active mitigation
        rangedDmgMin = 0,
        rangedDmgMax = 0,
        magicResist = 0,
        spellHitCap = 17.0, -- 14% with 3/3 Precision + 3% Spriest/Boomkin debuff
        meleeHitCap = 8.0,
        expertiseCap = 26,
        enrageSeconds = 900,
        cleaveTargets = 1,
        abilities = {
            -- Phase 1 (100% - 70% HP)
            { phase = "P1", name = "Infest", school = "Shadow", damage = 7500, interval = 22, type = "Raid Pulse", desc = "Deals 7,500 Shadow damage to raid; pulses every 1s until target is healed above 90% HP." },
            { phase = "P1", name = "Shadow Trap (25H)", school = "Shadow", damage = 0, interval = 15, type = "Knockoff Trap", desc = "Spawns shadow trap; triggers massive AoE knockoff to instant death if stepped on." },
            { phase = "P1", name = "Necrotic Plague", school = "Shadow", damage = 50000, interval = 30, type = "Dispel Bounce", desc = "Deadly disease jumping to closest add or player on dispel, stacking +damage on jump." },
            { phase = "P1", name = "Shambling Horror", school = "Physical", damage = 18000, interval = 60, type = "Enrage Add", desc = "2.8M HP add casting Shockwave and Enrage (+200% physical damage)." },

            -- Intermissions (70% & 40% HP - 60s)
            { phase = "Int", name = "Remorseless Winter", school = "Frost", damage = 7000, interval = 60, type = "Aura Frost", desc = "Constant 7,000 Frost damage/sec pushing entire raid to the edge." },
            { phase = "Int", name = "Raging Spirits", school = "Shadow", damage = 22000, interval = 20, type = "Frontal Cone", desc = "2.4M HP add casting Soul Shriek (22,000 Shadow cone silence)." },
            { phase = "Int", name = "Ice Spheres", school = "Frost", damage = 9000, interval = 7, type = "Ranged Switch", desc = "Floating spheres pulsing towards raid; detonates for lethal knockback on contact." },

            -- Phase 2 (70% - 40% HP)
            { phase = "P2", name = "Defile", school = "Shadow", damage = 5000, interval = 32, type = "Ground Void Zone", desc = "Expanding void zone dealing 5,000 Shadow damage/sec; grows whenever it deals damage. Requires instant repositioning." },
            { phase = "P2", name = "Val'kyr Shadowguard", school = "Shadow", damage = 0, interval = 45, type = "3x Grab Cleave", desc = "3x Val'kyrs (1.8M HP each) grab 3 players and carry them to cliff edge. Requires heavy slows, stuns, and cleave burst." },
            { phase = "P2", name = "Soul Reaper", school = "Shadow/Physical", damage = 50000, interval = 30, type = "Tank Buster", desc = "Strikes tank for weapon damage + 50,000 Shadow damage after 5s; increases boss haste by 100%." },

            -- Phase 3 (40% - 10% HP)
            { phase = "P3", name = "Vile Spirits", school = "Shadow", damage = 18000, interval = 30, type = "AoE Detonation", desc = "Summons 10 hovering Vile Spirits that descend after 15s, detonating for 18,000 Shadow AoE each." },
            { phase = "P3", name = "Harvest Souls (25H)", school = "Shadow", damage = 7500, interval = 60, type = "Frostmourne Chamber", desc = "Transports ENTIRE RAID inside Frostmourne chamber; raid must dodge falling Wicked Spirits while assisting King Terenas." }
        },
        desc = "Multi-phase encounter: Phase 1 (Infest/Shadow Trap/Plague), Intermissions (Remorseless Winter/Raging Spirits/Ice Spheres), Phase 2 (Val'kyr 3x Cleave/Defile/Soul Reaper), Phase 3 (Vile Spirits/Frostmourne Chamber/Molten Fury Execute)"
    },
    CLEAVE = {
        name = "Raging Spirit & Val'kyr Shadowguard",
        title = "Level 82 Elite Cleave (3 Targets)",
        level = 82,
        classification = "elite",
        creatureType = "Undead",
        health = 2400000, -- 2.4M HP each (7.2M combined pool)
        mana = 120000,
        armor = 9729, -- 59.2% Base Physical DR
        meleeDmgMin = 14200,
        meleeDmgMax = 18500,
        meleeSpeed = 2.00, -- ~8,175 DPS physical
        rangedDmgMin = 0,
        rangedDmgMax = 0,
        magicResist = 0,
        spellHitCap = 6.0,
        meleeHitCap = 5.5,
        expertiseCap = 24,
        cleaveTargets = 3,
        abilities = {
            { name = "Soul Shriek", school = "Shadow", damage = 22000, interval = 15, type = "Frontal Cone", desc = "Frontal cone dealing 22,000 Shadow damage and silencing for 5s." },
            { name = "Life Siphon", school = "Shadow", damage = 8000, interval = 10, type = "Channel Drain", desc = "Drains 8,000 life per tick restoring health to the add." }
        },
        desc = "Simulates Raging Spirits, Val'kyr Shadowguards, and Shambling Horrors (Living Bomb multi-dotting & instant finisher elevation)"
    },
    AOE = {
        name = "Infested Ghouls & Scourge Trash",
        title = "AOE Trash Pack (6+ Targets)",
        level = 81,
        classification = "elite",
        creatureType = "Undead",
        health = 450000, -- 450k HP each (2.7M combined pool)
        mana = 0,
        armor = 9000, -- 57.1% Base Physical DR
        meleeDmgMin = 6500,
        meleeDmgMax = 8800,
        meleeSpeed = 2.00,
        rangedDmgMin = 0,
        rangedDmgMax = 0,
        magicResist = 0,
        spellHitCap = 5.0,
        cleaveTargets = 6,
        abilities = {
            { name = "Infected Bite", school = "Nature", damage = 4200, interval = 10, type = "Melee Disease", desc = "Physical strike with stacking disease dealing 4,200 periodic Nature damage." }
        },
        desc = "Mass pack AoE (Infested Ghouls, Icecrown trash packs) utilizing Dual Flamestrike stacking, Dragon's Breath, and Blast Wave"
    }
}

function FC:InspectTargetNPC()
    local unit = "target"
    if not UnitExists(unit) then
        return nil, "No active target selected. Target an enemy or boss to inspect stats."
    end

    local name = UnitName(unit) or "Unknown NPC"
    local level = UnitLevel(unit)
    if level == -1 or level == 0 then level = 83 end -- Boss level
    local classification = UnitClassification(unit) or "normal"
    local creatureType = UnitCreatureType(unit) or "Unknown"
    local isPlayer = UnitIsPlayer(unit)
    local curHp = UnitHealth(unit) or 0
    local maxHp = UnitHealthMax(unit) or 1
    local hpPct = (curHp / maxHp) * 100
    local curPower = UnitPower(unit) or 0
    local maxPower = UnitPowerMax(unit) or 0

    -- Estimate Armor & Physical Damage Reduction
    local baseArmor = (level >= 83 and 10643) or (level == 82 and 9729) or (level == 81 and 9000) or (400 + 85 * level)
    if classification == "worldboss" then baseArmor = 10643 end

    -- Scan Armor Shred and Magic Vulnerability Debuffs
    local sunderCount = 0
    local hasMajorArmorShred = false
    local hasMinorArmorShred = false
    local hasMagicVulnerability = false
    local hasSpellHitDebuff = false
    local hasCritDebuff = false
    local activeDebuffList = {}

    for i = 1, 40 do
        local dName, _, _, dCount = UnitDebuff(unit, i)
        if not dName then break end
        local lowerD = string.lower(dName)
        table.insert(activeDebuffList, dName)

        if string.find(lowerD, "sunder armor") then
            sunderCount = math.max(sunderCount, dCount or 1)
            hasMajorArmorShred = true
        elseif string.find(lowerD, "expose armor") or string.find(lowerD, "acid spit") then
            hasMajorArmorShred = true
        elseif string.find(lowerD, "faerie fire") or string.find(lowerD, "sting") or string.find(lowerD, "curse of weakness") then
            hasMinorArmorShred = true
        elseif string.find(lowerD, "curse of the elements") or string.find(lowerD, "ebon plague") or string.find(lowerD, "earth and moon") then
            hasMagicVulnerability = true
        elseif string.find(lowerD, "misery") or string.find(lowerD, "improved faerie fire") then
            hasSpellHitDebuff = true
        elseif string.find(lowerD, "heart of the crusader") or string.find(lowerD, "master poisoner") or string.find(lowerD, "totem of wrath") then
            hasCritDebuff = true
        end
    end

    local armorShredPct = 0
    if sunderCount > 0 then
        armorShredPct = armorShredPct + (sunderCount * 0.04) -- 4% per stack up to 20%
    elseif hasMajorArmorShred then
        armorShredPct = armorShredPct + 0.20
    end
    if hasMinorArmorShred then
        armorShredPct = armorShredPct + 0.05
    end

    local effectiveArmor = baseArmor * (1.0 - armorShredPct)
    local playerLvl = UnitLevel("player") or 80
    local drPct = (effectiveArmor / (effectiveArmor + 400 + (85 * playerLvl))) * 100

    -- Check if target matches known boss profile
    local knownProfile = nil
    for _, prof in pairs(FC.SIMULATION_PROFILES) do
        if string.find(string.lower(name), string.lower(prof.name)) or string.find(string.lower(prof.name), string.lower(name)) then
            knownProfile = prof
            break
        end
    end

    return {
        name = name,
        level = level,
        classification = classification,
        creatureType = creatureType,
        isPlayer = isPlayer,
        curHp = curHp,
        maxHp = maxHp,
        hpPct = hpPct,
        curPower = curPower,
        maxPower = maxPower,
        baseArmor = baseArmor,
        effectiveArmor = math.floor(effectiveArmor),
        armorShredPct = armorShredPct * 100,
        drPct = drPct,
        hasMagicVulnerability = hasMagicVulnerability,
        hasSpellHitDebuff = hasSpellHitDebuff,
        hasCritDebuff = hasCritDebuff,
        activeDebuffs = activeDebuffList,
        knownProfile = knownProfile
    }
end

function FC:RunSimulationBenchmarks(specName)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    if self.UpdatePlayerStats then self:UpdatePlayerStats() end
    local p = self.state.player or {}
    local s = p.stats or {}
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"

    local ext = self.extState or {}
    local pMods = ext.aggregatedModifiers or (self.GetAggregatedPerkModifiers and self:GetAggregatedPerkModifiers()) or {}

    local baseSp = s.spellDamage or s.attackPower or 2000
    local sp = baseSp * (1.0 + (pMods.spellPowerPct or 0)) + (pMods.spellPowerFlat or 0)
    local critPct = (s.spellCrit or s.meleeCrit or 35.0) + (pMods.critChance or 0)
    local hastePct = (s.spellHaste or s.meleeHaste or 25.0) + (pMods.hastePct or 0)
    local hasteMult = 1.0 + (hastePct / 100)
    local critMult = (1.5 + (critPct / 100) * 1.04) * (1.0 + (pMods.critMultiplier or 0))

    local fireMod = 1.0 + ((pMods.schoolDamage and pMods.schoolDamage["Fire"]) or 0) + ((pMods.schoolDamage and pMods.schoolDamage["All"]) or 0)
    local lbMod = fireMod * (1.0 + ((pMods.spellDamage and pMods.spellDamage["Living Bomb"]) or 0))
    local fbMod = fireMod * (1.0 + ((pMods.spellDamage and pMods.spellDamage["Fireball"]) or 0))
    local pyroMod = fireMod * (1.0 + ((pMods.spellDamage and pMods.spellDamage["Pyroblast"]) or 0))
    local fsMod = fireMod * (1.0 + ((pMods.spellDamage and pMods.spellDamage["Flamestrike"]) or 0))

    local singleDps = 0
    local cleaveDps = 0
    local aoeDps = 0
    local speedRating = "1.00s GCD Floor | 41yd Range (98.5% Uptime)"
    local survivabilityRating = "High (-20% Threat, 92% Pushback Immunity, Incanter Shield)"

    if pClass == "MAGE" and (specName == "Fire" or specName == "Active Spec") then
        -- 1. Single Target Boss Sim (The Lich King 25H - 180s Simulation Window)
        -- Living Bomb (DoT 80% SP coeff + Explosion 40% SP coeff every 12s, 100% optimal uptime, scales with parsed perks)
        local lbDps = ((1380 + sp * 0.80) + (690 + sp * 0.40)) / 12.0 * critMult * 1.10 * lbMod
        -- Fireball (Base ~1020 + 1.15 SP coeff per 2.3s cast with Imp Fireball, scaled by parsed perks)
        local fbCast = math.max(1.0, 3.0 / hasteMult)
        local fbDmg = (1020 + sp * 1.15) * critMult * 1.10 * 1.12 * fbMod -- 1.12 TTW snared multiplier
        local fbDps = fbDmg / fbCast
        -- Hot Streak Instant Pyroblast (Proc ~every 4.5s with high crit, 100% immediate consumption, scaled by parsed perks)
        local pyroDmg = (1370 + sp * 1.15) * critMult * 1.10 * 1.12 * pyroMod
        local pyroDps = pyroDmg / 4.5
        
        -- Cooldown & Execute Cycle Modeling:
        -- Combustion (2x in 180s: +50% Crit multiplier burst) + Mirror Image (30s duration) + On-Use Trinket
        local cooldownBurstDps = (pyroDps * 0.45 + fbDps * 0.30) * (30.0 / 180.0)
        local mirrorImageDps = 1850 * (30.0 / 180.0) * fireMod
        -- Molten Fury Execute Phase (+12% damage over final 35% boss HP)
        local executeMultiplier = 1.0 + (0.12 * 0.35)

        singleDps = (lbDps + fbDps + pyroDps + cooldownBurstDps + mirrorImageDps) * executeMultiplier

        -- 2. Cleave Sim (Level 82 Elite Mobs - 3 Targets - 45s Window)
        -- 3x Living Bombs ticking simultaneously + 3x end explosions + Hot Streak acceleration
        local cleaveLbDps = lbDps * 3.0
        local cleavePyroDps = pyroDps * 1.65
        local cleaveCooldowns = (cooldownBurstDps + mirrorImageDps) * 1.35
        cleaveDps = cleaveLbDps + fbDps + cleavePyroDps + cleaveCooldowns

        -- 3. AOE Sim (6+ Targets - 25s Trash Pack Window)
        -- Dual Flamestrike Rank 9 + Rank 8 ground ticks + Dragon's Breath + Blast Wave + Firestarter instant weaves
        local fsDps = ((973 + sp * 0.2357) + (780 + sp * 0.48)) / 2.0 * 6.0 * (critMult * 0.9) * fsMod
        local dbDps = (1190 + sp * 0.193) / 10.0 * 6.0 * critMult * fireMod
        local bwDps = (1140 + sp * 0.193) / 15.0 * 6.0 * critMult * fireMod
        local firestarterInstantDps = fsDps * 0.35
        aoeDps = (fsDps + dbDps + bwDps + firestarterInstantDps + (lbDps * 2.5)) * (1.0 + (pMods.aoeDamagePct or 0))

        -- Active Tanking Shield & Armor Maintenance:
        -- Modeled Ice Barrier + Warding + Mage Armor + Incanter's Absorption (+5% absorbed damage as SP)
        local tankingShieldAbsorption = (3300 + (sp * 0.80)) * (1.0 + (pMods.shieldAbsorbPct or 0))
        local armorVal = (s.armor or 8500) * (1.0 + (pMods.armorPct or 0))
        local armorDr = armorVal / (armorVal + 15232.5)
        local totalDr = math.min(0.85, (1.0 - (1.0 - armorDr) * (1.0 - (pMods.damageReductionPct or 0))))
        local tankingEHP = math.floor((s.health or 25000) / math.max(0.1, 1.0 - totalDr))

        local totalRange = 35 + 6 + (pMods.rangeBonus or 0)
        local threatPct = math.floor((0.20 + (pMods.threatReductionPct or 0)) * 100)
        speedRating = string.format("%.2fs GCD Floor | %dyd Range (98.8%% Tanking Uptime)", math.max(1.0, 1.5 / hasteMult), totalRange)
        survivabilityRating = string.format("Active Tanking: %d EHP | %d Absorb Shield | -%d%% Threat", tankingEHP, math.floor(tankingShieldAbsorption), threatPct)
    else
        -- Generalized Multi-Class Sim Model with Active Tanking & Parsed Perk Factors
        local allMod = 1.0 + ((pMods.schoolDamage and pMods.schoolDamage["All"]) or 0)
        singleDps = sp * 2.5 * hasteMult * (1 + critPct / 100) * 1.15 * allMod
        cleaveDps = singleDps * 2.6
        aoeDps = singleDps * 4.8 * (1.0 + (pMods.aoeDamagePct or 0))
        local totalRange = 30 + (pMods.rangeBonus or 0)
        local threatPct = math.floor((0.15 + (pMods.threatReductionPct or 0)) * 100)
        local tankingEHP = math.floor((s.health or 25000) / math.max(0.1, 1.0 - (0.45 + (pMods.damageReductionPct or 0))))
        speedRating = string.format("%.2fs GCD Floor | %dyd Range (95%% Tanking Uptime)", math.max(1.0, 1.5 / hasteMult), totalRange)
        survivabilityRating = string.format("Active Tanking: %d EHP | -%d%% Threat", tankingEHP, threatPct)
    end

    return {
        single = math.floor(singleDps),
        cleave = math.floor(cleaveDps),
        aoe = math.floor(aoeDps),
        speedRating = speedRating,
        survivabilityRating = survivabilityRating
    }
end

function FC:OpenTalentWindow()
    -- 1. Check Talented / Talented Synastria Addon
    if _G["Talented"] then
        if type(_G["Talented"].Open) == "function" then
            _G["Talented"]:Open()
            return true
        elseif type(_G["Talented"].Toggle) == "function" then
            if not (_G["TalentedFrame"] and _G["TalentedFrame"]:IsVisible()) then
                _G["Talented"]:Toggle()
            end
            return true
        end
    end
    if _G["TalentedFrame"] and _G["TalentedFrame"].Show then
        _G["TalentedFrame"]:Show()
        return true
    end

    -- 2. Check Standard WoW / Synastria ToggleTalentFrame hook
    if ToggleTalentFrame and type(ToggleTalentFrame) == "function" then
        ToggleTalentFrame()
        return true
    end

    -- 3. Fallback to Blizzard PlayerTalentFrame
    if not PlayerTalentFrame then
        if not IsAddOnLoaded("Blizzard_TalentUI") then
            LoadAddOn("Blizzard_TalentUI")
        end
    end
    if PlayerTalentFrame then
        ShowUIPanel(PlayerTalentFrame)
        return true
    end

    return false
end

function FC:OpenTalentBuildAdvisor(specName)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"

    -- Open the Talent Screen (Prioritizing Talented Synastria)
    self:OpenTalentWindow()

    -- Install Hooks and Apply Overlays
    if not self.talentHooksInstalled then
        self.talentHooksInstalled = true

        -- Hook Talented Synastria if loaded
        if _G["Talented"] then
            local tObj = _G["Talented"]
            if tObj.TalentView and tObj.TalentView.Update then
                hooksecurefunc(tObj.TalentView, "Update", function()
                    FC:UpdateTalentTreeOverlay()
                end)
            end
            if tObj.UpdateView then
                hooksecurefunc(tObj, "UpdateView", function()
                    FC:UpdateTalentTreeOverlay()
                end)
            end
            if tObj.SetTemplate then
                hooksecurefunc(tObj, "SetTemplate", function()
                    FC:UpdateTalentTreeOverlay()
                end)
            end
            if tObj.Open then
                hooksecurefunc(tObj, "Open", function()
                    FC:UpdateTalentTreeOverlay()
                end)
            end
        end

        local tf = _G["TalentedFrame"] or (_G["Talented"] and _G["Talented"].base)
        if tf and tf.HookScript then
            pcall(function()
                tf:HookScript("OnShow", function()
                    FC:UpdateTalentTreeOverlay()
                end)
                tf:HookScript("OnHide", function()
                    if FC.sidePanel then FC.sidePanel:Hide() end
                end)
                local tfElapsed = 0
                tf:HookScript("OnUpdate", function(self, elapsed)
                    tfElapsed = tfElapsed + (elapsed or 0.1)
                    if tfElapsed >= 0.25 then
                        tfElapsed = 0
                        FC:UpdateTalentTreeOverlay()
                    end
                end)
            end)
        end

        -- Hook Blizzard PlayerTalentFrame if used
        if PlayerTalentFrame then
            if PlayerTalentFrame.HookScript then
                pcall(function()
                    PlayerTalentFrame:HookScript("OnShow", function()
                        FC:UpdateTalentTreeOverlay()
                    end)
                    PlayerTalentFrame:HookScript("OnHide", function()
                        if FC.sidePanel then FC.sidePanel:Hide() end
                    end)
                end)
            end
        end
        if PlayerTalentFrame_Update then
            hooksecurefunc("PlayerTalentFrame_Update", function()
                FC:UpdateTalentTreeOverlay()
            end)
        end
        for t = 1, 3 do
            local tab = _G["PlayerTalentFrameTab" .. t]
            if tab then
                tab:HookScript("OnClick", function()
                    FC:UpdateTalentTreeOverlay()
                end)
            end
        end
    end

    self:UpdateTalentTreeOverlay()
    return self:AnalyzeBuildSynergies(specName)
end

local RECOMMENDED_PERKS_CATALOG = {
    ["Fire"] = {
        Class = { "Explosive Impact", "Slow Burn", "Spreading Flames", "Meteor Shower", "Empowered Flames" },
        Offensive = { "Outburst", "Dissipation", "Vengeance", "Precision", "Extension" },
        Defensive = { "Independence", "Augmented Barriers", "Hardening", "Elemental Shielding", "Stubborn" },
        Support = { "Prevention", "Coherence", "Thousand Cuts", "Thousand Bandaids", "Warding" },
        Utility = { "Attunement", "Teleportation", "Scouting", "Augmentation", "Caution" }
    },
    ["Arcane"] = {
        Class = { "Arcane Power Acceleration", "Mind Mastery", "Barrage Surge", "Arcane Infusion", "Temporal Compression" },
        Offensive = { "Outburst", "Dissipation", "Precision", "Extension", "Vengeance" },
        Defensive = { "Independence", "Augmented Barriers", "Hardening", "Elemental Shielding", "Stubborn" },
        Support = { "Coherence", "Prevention", "Warding", "Thousand Cuts", "Thousand Bandaids" },
        Utility = { "Attunement", "Teleportation", "Scouting", "Augmentation", "Caution" }
    },
    ["General"] = {
        Offensive = { "Outburst", "Dissipation", "Vengeance", "Precision", "Extension" },
        Defensive = { "Independence", "Augmented Barriers", "Hardening", "Elemental Shielding", "Stubborn" },
        Support = { "Prevention", "Coherence", "Thousand Cuts", "Thousand Bandaids", "Warding" },
        Utility = { "Attunement", "Teleportation", "Scouting", "Augmentation", "Caution" }
    }
}

function FC:ScoreCandidatePerkForSpec(perk, specName)
    local score = 0
    if not perk then return 0 end

    local name = perk.name or ""
    local desc = perk.description or perk.tooltip or ""
    local mods = (self.ParsePerkDescription and self:ParsePerkDescription(desc, name)) or {}
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"

    -- 1. Spell Damage & Synergy Matches
    for sName, pct in pairs(mods.spellDamage or {}) do
        local isKnown = (self._registeredSpellNames and self._registeredSpellNames[sName]) or (self.GetTalentRank and self:GetTalentRank(sName) > 0)
        if isKnown then
            score = score + (pct * 250)
        end
    end

    -- 2. School Damage Matches
    if pClass == "MAGE" then
        if specName == "Fire" and mods.schoolDamage and mods.schoolDamage["Fire"] then
            score = score + (mods.schoolDamage["Fire"] * 220)
        elseif specName == "Arcane" and mods.schoolDamage and mods.schoolDamage["Arcane"] then
            score = score + (mods.schoolDamage["Arcane"] * 220)
        elseif specName == "Frost" and mods.schoolDamage and mods.schoolDamage["Frost"] then
            score = score + (mods.schoolDamage["Frost"] * 220)
        end
    end
    if mods.schoolDamage and mods.schoolDamage["All"] then
        score = score + (mods.schoolDamage["All"] * 200)
    end

    -- 3. Core Stats & Modifiers
    score = score + ((mods.critChance or 0) * 8.0)
    score = score + ((mods.critMultiplier or 0) * 150)
    score = score + ((mods.hastePct or 0) * 9.0)
    score = score + ((mods.hitPct or 0) * 12.0)
    score = score + ((mods.dotDurationPct or 0) * 100)
    score = score + ((mods.aoeDamagePct or 0) * 120)

    -- 4. Survivability, Shields & Active Tanking
    score = score + ((mods.damageReductionPct or 0) * 180)
    score = score + ((mods.shieldAbsorbPct or 0) * 140)
    score = score + ((mods.rangeBonus or 0) * 15)
    score = score + ((mods.threatReductionPct or 0) * 50)

    -- 5. Approach-Driven Multipliers
    local approach = (FC.db and FC.db.combatApproach) or "Balanced"
    if approach == "Survival/PVP" then
        score = score + ((mods.damageReductionPct or 0) * 350)
        score = score + ((mods.shieldAbsorbPct or 0) * 300)
        score = score + ((mods.armorPct or 0) * 250)
        if name == "Independence" or name == "Augmented Barriers" or name == "Hardening" or name == "Elemental Shielding" or name == "Warding" then
            score = score + 120
        end
    elseif approach == "AOE Damage" then
        score = score + ((mods.aoeDamagePct or 0) * 300)
        if name == "Spreading Flames" or name == "Explosive Impact" or name == "Meteor Shower" or name == "Firestarter" or name == "Thousand Cuts" then
            score = score + 120
        end
    elseif approach == "ST Damage" then
        score = score + ((mods.critMultiplier or 0) * 250)
        score = score + ((mods.critChance or 0) * 15.0)
        if name == "Outburst" or name == "Dissipation" or name == "Vengeance" or name == "Precision" then
            score = score + 100
        end
    end

    -- 6. Baseline Fallback Priority for Known Signature Perks
    local priorityMap = {
        ["Explosive Impact"] = 280, ["Slow Burn"] = 260, ["Spreading Flames"] = 270,
        ["Meteor Shower"] = 250, ["Empowered Flames"] = 260,
        ["Outburst"] = 240, ["Dissipation"] = 220, ["Vengeance"] = 230, ["Precision"] = 220, ["Extension"] = 210,
        ["Independence"] = 260, ["Augmented Barriers"] = 250, ["Hardening"] = 230, ["Elemental Shielding"] = 220, ["Stubborn"] = 210,
        ["Prevention"] = 230, ["Coherence"] = 220, ["Thousand Cuts"] = 210, ["Thousand Bandaids"] = 200, ["Warding"] = 240,
        ["Attunement"] = 220, ["Teleportation"] = 200, ["Scouting"] = 190, ["Augmentation"] = 210, ["Caution"] = 230
    }
    if priorityMap[name] then
        score = score + priorityMap[name]
    end

    return score
end

function FC:GetDynamicRecommendedPerksForCategory(cat, specName)
    local ext = self.extState or {}
    local catPerks = (ext.categories and ext.categories[cat]) or {}
    local scored = {}
    local seen = {}

    -- 1. Score all perks discovered in this category
    for _, p in ipairs(catPerks) do
        local pName = p.name or ""
        if pName ~= "" and not seen[pName] then
            seen[pName] = true
            local sc = self:ScoreCandidatePerkForSpec(p, specName)
            table.insert(scored, { name = pName, score = sc, perk = p })
        end
    end

    -- 2. Include fallback catalog items if not present
    local catalogList = (RECOMMENDED_PERKS_CATALOG[specName] and RECOMMENDED_PERKS_CATALOG[specName][cat]) or
                        (RECOMMENDED_PERKS_CATALOG["General"] and RECOMMENDED_PERKS_CATALOG["General"][cat]) or {}
    for _, cName in ipairs(catalogList) do
        if not seen[cName] then
            seen[cName] = true
            local sc = self:ScoreCandidatePerkForSpec({ name = cName, description = "" }, specName)
            table.insert(scored, { name = cName, score = sc })
        end
    end

    -- 3. Sort by dynamic score descending
    table.sort(scored, function(a, b) return a.score > b.score end)

    local recList = {}
    for i = 1, math.min(5, #scored) do
        table.insert(recList, scored[i].name)
    end
    return recList
end

function FC:AnalyzeBuildSynergies(specName)
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"
    local report = {
        specName = specName,
        tabPoints = (self.talents and self.talents.tabPoints) or { [1] = 0, [2] = 0, [3] = 0 },
        talents = {},
        perks = {},
        glyphs = {}
    }

    local function Has(tName) return (FC.GetTalentRank and FC:GetTalentRank(tName) > 0) end
    local function Rank(tName) return (FC.GetTalentRank and FC:GetTalentRank(tName)) or 0 end

    -- 1. TALENT TREES BENCHMARK COMPARISON
    if pClass == "MAGE" then
        if specName == "Fire" or Has("Fireball") then
            local ignite = Rank("Ignite")
            local hotStreak = Rank("Hot Streak")
            local burnout = Rank("Burnout")
            local empFire = Rank("Empowered Fire")
            local firePower = Rank("Fire Power")

            if hotStreak == 3 and ignite == 5 and burnout == 5 then
                table.insert(report.talents, { status = "|cff55ff55[OPTIMAL]|r", name = "Hot Streak Engine", desc = "5/5 Ignite + 3/3 Hot Streak + 5/5 Burnout (Full 2.54x crit scaling active)" })
            else
                table.insert(report.talents, { status = "|cffff8800[SUBOPTIMAL]|r", name = "Hot Streak Engine", desc = string.format("Missing keystone talents (Ignite %d/5, Hot Streak %d/3, Burnout %d/5)", ignite, hotStreak, burnout) })
            end

            if empFire == 3 and firePower == 5 then
                table.insert(report.talents, { status = "|cff55ff55[OPTIMAL]|r", name = "Fire Power & Empowered Fire", desc = "5/5 Fire Power (+10%) & 3/3 Empowered Fire (+15% SP coefficient)" })
            else
                table.insert(report.talents, { status = "|cffff8800[IMPROVEMENT]|r", name = "Empowered Fire / Fire Power", desc = string.format("Currently %d/3 Empowered & %d/5 Fire Power", empFire, firePower) })
            end

            local blastWave = Rank("Blast Wave")
            local dragonsBreath = Rank("Dragon's Breath")
            local firestarter = Rank("Firestarter")
            if blastWave >= 1 and dragonsBreath >= 1 and firestarter >= 2 then
                table.insert(report.talents, { status = "|cff55ff55[OPTIMAL]|r", name = "Firestarter AOE Engine", desc = "Blast Wave + Dragon's Breath + 2/2 Firestarter (100% Instant Flamestrike weave active)" })
            else
                table.insert(report.talents, { status = "|cffff8800[IMPROVEMENT]|r", name = "Firestarter AOE Engine", desc = string.format("Missing AOE burst weave (Blast Wave %d/1, Dragon's Breath %d/1, Firestarter %d/2)", blastWave, dragonsBreath, firestarter) })
            end
        elseif specName == "Arcane" then
            local mBarrage = Rank("Missile Barrage")
            local arcPower = Rank("Arcane Power")
            if mBarrage == 5 and arcPower == 1 then
                table.insert(report.talents, { status = "|cff55ff55[OPTIMAL]|r", name = "Missile Barrage & Arcane Power", desc = "5/5 Missile Barrage (40% instant proc) & Arcane Power (+20% burst)" })
            else
                table.insert(report.talents, { status = "|cffff2222[CRITICAL]|r", name = "Missile Barrage Proc Engine", desc = "Missing Missile Barrage or Arcane Power - core Arcane keystones!" })
            end
        end
    end

    if #report.talents == 0 then
        table.insert(report.talents, { status = "|cff55ff55[BALANCED]|r", name = "Standard Talent Distribution", desc = "Core talent tree keystones actively allocated." })
    end

    -- 2. ACTIVE PERKS IN VARIOUS CATEGORIES & DYNAMICALLY SCORED RECOMMENDATIONS
    local ext = self.extState or {}
    local catCounts = ext.activePerkCounts or {}
    local categoriesOrder = { "Class", "Offensive", "Defensive", "Support", "Utility", "Misc" }

    for _, cat in ipairs(categoriesOrder) do
        local count = catCounts[cat] or 0
        local catPerks = {}
        local activeSet = {}
        for id, perk in pairs(ext.activePerks or {}) do
            if perk.category == cat then
                local pName = perk.name or ("Perk #" .. tostring(id))
                table.insert(catPerks, pName)
                activeSet[pName] = true
            end
        end

        local perkListStr = (#catPerks > 0) and table.concat(catPerks, ", ") or "None active"

        -- Dynamically Determine Best-in-Slot Recommended Perks via Description Scoring
        local recList = (self.GetDynamicRecommendedPerksForCategory and self:GetDynamicRecommendedPerksForCategory(cat, specName)) or {}
        local missingRecs = {}
        for _, rName in ipairs(recList) do
            if not activeSet[rName] then
                table.insert(missingRecs, rName)
            end
        end

        local recStr = ""
        if count < 5 and #missingRecs > 0 then
            recStr = " -> |cffffd700Recommended Pick(s):|r " .. table.concat(missingRecs, ", ")
        elseif #missingRecs == 0 and count == 5 then
            recStr = " -> |cff55ff55[100% Best-in-Slot Perks Active]|r"
        end

        table.insert(report.perks, {
            category = cat,
            count = count,
            max = 5,
            perksStr = perkListStr,
            recommendationStr = recStr,
            status = (count == 5) and "|cff55ff55[FULL 5/5]|r" or (count > 0 and string.format("|cff00ccff[%d/5]|r", count) or "|cff888888[0/5 Empty]|r")
        })
    end

    -- 3. EQUIPPED GLYPHS COMPARISON & RECOMMENDATIONS
    local gList = self.glyphList or {}
    local recMajor = { "Glyph of Fireball", "Glyph of Living Bomb", "Glyph of Scorch" }
    local recMinor = { "Glyph of Arcane Intellect", "Glyph of Frost Ward", "Glyph of Fire Ward" }

    if #gList == 0 then
        table.insert(report.glyphs, { status = "|cffff2222[EMPTY]|r", name = "No Glyphs Equipped", desc = "Recommended: Fireball, Living Bomb, Scorch | Arcane Intellect, Frost Ward, Fire Ward" })
    else
        for _, g in ipairs(gList) do
            table.insert(report.glyphs, { status = "|cff55ff55[ACTIVE]|r", name = string.format("[%s] %s", g.type or "Major", g.name or "Glyph"), desc = "Equipped & active in combat calculations." })
        end
    end

    -- 4. ACTIVE PERK PREREQUISITES & TALENT DEPENDENCY REPORT
    report.perkPrerequisites = {}
    for numId, perk in pairs(ext.activePerks or {}) do
        local reqs = (ext.perkPrerequisites and ext.perkPrerequisites[numId]) or {}
        local missingReqs = {}
        local satisfiedReqs = {}
        for reqName in pairs(reqs) do
            local isTalentKnown = (FC.GetTalentRank and FC:GetTalentRank(reqName) > 0)
            local isSpellKnown = (FC._registeredSpellNames and FC._registeredSpellNames[reqName])
            if isTalentKnown or isSpellKnown then
                table.insert(satisfiedReqs, reqName)
            else
                table.insert(missingReqs, reqName)
            end
        end

        if #missingReqs > 0 or #satisfiedReqs > 0 then
            local status = (#missingReqs == 0) and "|cff55ff55[PREREQS MET]|r" or "|cffff2222[PREREQ MISSING]|r"
            local desc = ""
            if #missingReqs > 0 then
                desc = "|cffff3333Requires talent/spell:|r " .. table.concat(missingReqs, ", ")
            else
                desc = "|cff55ff55Prerequisites active:|r " .. table.concat(satisfiedReqs, ", ")
            end
            table.insert(report.perkPrerequisites, {
                status = status,
                name = perk.name or ("Perk #" .. tostring(numId)),
                desc = desc,
                hasMissing = (#missingReqs > 0)
            })
        end
    end

    return report
end

-- =====================================================================
-- 4. POST-FIGHT COMBAT PERFORMANCE & ROTATION GRADING
-- =====================================================================
FC.combatStats = {
    active = false,
    startTime = 0,
    endTime = 0,
    startDmg = 0,
    castsRecommended = 0,
    castsMatched = 0,
    procsGained = 0,
    procsUsed = 0,
    dotsClipped = 0,
    dotsRefreshed = 0
}

function FC:StartCombatSession()
    self.combatStats.active = true
    self.combatStats.startTime = GetTime()
    self.combatStats.castsRecommended = 0
    self.combatStats.castsMatched = 0
    self.combatStats.procsGained = 0
    self.combatStats.procsUsed = 0
    self.combatStats.dotsClipped = 0
    self.combatStats.dotsRefreshed = 0
end

function FC:EndCombatSession()
    if not self.combatStats.active then return end
    self.combatStats.active = false
    self.combatStats.endTime = GetTime()
    local dur = math.max(1.0, self.combatStats.endTime - self.combatStats.startTime)

    local totalCasts = math.max(1, self.combatStats.castsRecommended)
    local matchedCasts = self.combatStats.castsMatched
    local execPct = math.min(100, (matchedCasts / totalCasts) * 100)

    local grade = "A"
    local gradeCol = "|cff55ff55"
    if execPct >= 95 then grade = "S+"; gradeCol = "|cffffd700"
    elseif execPct >= 90 then grade = "S"; gradeCol = "|cff00ffcc"
    elseif execPct >= 80 then grade = "A"; gradeCol = "|cff55ff55"
    elseif execPct >= 70 then grade = "B"; gradeCol = "|cff00ccff"
    elseif execPct >= 60 then grade = "C"; gradeCol = "|cffff8800"
    else grade = "D"; gradeCol = "|cffff2222"
    end

    self.lastCombatReport = {
        duration = dur,
        grade = grade,
        gradeCol = gradeCol,
        execPct = execPct,
        totalCasts = totalCasts,
        matchedCasts = matchedCasts,
        dotsClipped = self.combatStats.dotsClipped,
        procsUsed = self.combatStats.procsUsed,
        procsGained = self.combatStats.procsGained
    }
end

-- =====================================================================
-- 5. PRE-COMBAT READINESS & RAID BUFF CHECKLIST
-- =====================================================================
function FC:CheckPreCombatReadiness()
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"
    local pBuffs = (self.state and self.state.player and self.state.player.buffs) or {}
    local warnings = {}
    local ready = true

    -- 1. Self Class Buffs
    if pClass == "MAGE" then
        if not pBuffs["Molten Armor"] and not pBuffs["Mage Armor"] and not pBuffs["Ice Armor"] then
            table.insert(warnings, "|cffff2222Missing Mage Armor (Molten Armor recommended for DPS)|r")
            ready = false
        end
        if not pBuffs["Arcane Intellect"] and not pBuffs["Arcane Brilliance"] and not pBuffs["Dalaran Brilliance"] then
            table.insert(warnings, "|cffff8800Missing Arcane Intellect / Brilliance|r")
        end
    elseif pClass == "PRIEST" then
        if not pBuffs["Inner Fire"] then
            table.insert(warnings, "|cffff2222Missing Inner Fire (+Spell Power / Armor)|r")
            ready = false
        end
        if not pBuffs["Power Word: Fortitude"] and not pBuffs["Prayer of Fortitude"] then
            table.insert(warnings, "|cffff8800Missing Power Word: Fortitude|r")
        end
    elseif pClass == "WARLOCK" then
        if not pBuffs["Fel Armor"] and not pBuffs["Demon Armor"] then
            table.insert(warnings, "|cffff2222Missing Fel Armor (+Spell Power / Spirit conversion)|r")
            ready = false
        end
    elseif pClass == "PALADIN" then
        if not pBuffs["Righteous Fury"] and (self.state and self.state.playerRole == "Tank") then
            table.insert(warnings, "|cffff2222Missing Righteous Fury (Tank threat active)|r")
            ready = false
        end
        local hasSeal = false
        for bName, _ in pairs(pBuffs) do
            if string.find(bName, "Seal of", 1, true) then hasSeal = true; break end
        end
        if not hasSeal then
            table.insert(warnings, "|cffff2222Missing Active Paladin Seal!|r")
            ready = false
        end
    elseif pClass == "WARRIOR" then
        if not pBuffs["Battle Shout"] and not pBuffs["Commanding Shout"] then
            table.insert(warnings, "|cffff8800Missing Battle Shout / Commanding Shout|r")
        end
    elseif pClass == "DEATHKNIGHT" then
        if not pBuffs["Horn of Winter"] then
            table.insert(warnings, "|cffff8800Missing Horn of Winter (+Str/Agi)|r")
        end
    end

    -- 2. Consumables (Flask / Elixir & Food)
    local hasFlask = false
    local hasFood = false
    for bName, _ in pairs(pBuffs) do
        if string.find(bName, "Flask", 1, true) or string.find(bName, "Elixir", 1, true) then hasFlask = true end
        if string.find(bName, "Well Fed", 1, true) or string.find(bName, "Food", 1, true) then hasFood = true end
    end
    if not hasFlask then
        table.insert(warnings, "|cff888888Flask / Battle Elixir not active (Optional for raid DPS)|r")
    end
    if not hasFood then
        table.insert(warnings, "|cff888888Well Fed Food Buff not active|r")
    end

    return ready, warnings
end
