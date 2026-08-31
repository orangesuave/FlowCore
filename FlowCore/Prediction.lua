FlowCore = FlowCore or {}
local FC = FlowCore

-- Common WotLK Class Procs & Synergies
local PROC_SYNERGIES = {
    -- Mage
    ["Hot Streak"] = { ["Pyroblast"] = 3.2 },
    ["Brain Freeze"] = { ["Fireball"] = 2.8, ["Frostfire Bolt"] = 2.8 },
    ["Fireball!"] = { ["Fireball"] = 2.8, ["Frostfire Bolt"] = 2.8 },
    ["Missile Barrage"] = { ["Arcane Missiles"] = 2.8 },
    ["Clearcasting"] = { ["Arcane Missiles"] = 1.8, ["Blizzard"] = 1.5, ["Arcane Explosion"] = 1.4 },
    ["Combustion"] = { ["Fireball"] = 1.5, ["Pyroblast"] = 1.5, ["Living Bomb"] = 1.4 },

    -- Warlock
    ["Decimation"] = { ["Soul Fire"] = 3.2 },
    ["Molten Core"] = { ["Incinerate"] = 2.2, ["Soul Fire"] = 2.0 },
    ["Backdraft"] = { ["Incinerate"] = 2.0, ["Chaos Bolt"] = 2.0 },
    ["Shadow Trance"] = { ["Shadow Bolt"] = 2.8 },
    ["Nightfall"] = { ["Shadow Bolt"] = 2.8 },
    ["Empowered Imp"] = { ["Soul Fire"] = 1.8, ["Chaos Bolt"] = 1.8 },

    -- Paladin
    ["The Art of War"] = { ["Exorcism"] = 2.8, ["Flash of Light"] = 2.2 },
    ["Infusion of Light"] = { ["Holy Light"] = 2.2, ["Flash of Light"] = 2.0, ["Holy Shock"] = 1.8 },
    ["Judgements of the Pure"] = { ["Judgement of Light"] = 1.2, ["Judgement of Wisdom"] = 1.2 },

    -- Death Knight
    ["Killing Machine"] = { ["Frost Strike"] = 2.5, ["Howling Blast"] = 2.5, ["Obliterate"] = 1.8 },
    ["Rime"] = { ["Howling Blast"] = 2.8, ["Icy Touch"] = 2.2 },
    ["Sudden Doom"] = { ["Death Coil"] = 2.6 },

    -- Warrior
    ["Sudden Death"] = { ["Execute"] = 3.2 },
    ["Taste for Blood"] = { ["Overpower"] = 2.8 },
    ["Bloodsurge"] = { ["Slam"] = 2.8 },
    ["Slam!"] = { ["Slam"] = 2.8 },

    -- Hunter
    ["Lock and Load"] = { ["Explosive Shot"] = 3.5, ["Arcane Shot"] = 2.2 },
    ["Fire!"] = { ["Aimed Shot"] = 2.5 },

    -- Shaman
    ["Lava Surge"] = { ["Lava Burst"] = 2.8 },
    ["Elemental Mastery"] = { ["Lava Burst"] = 2.2, ["Lightning Bolt"] = 2.0 },

    -- Priest
    ["Surge of Light"] = { ["Flash Heal"] = 2.5, ["Smite"] = 2.5 },

    -- Druid
    ["Eclipse (Solar)"] = { ["Wrath"] = 2.4 },
    ["Eclipse (Lunar)"] = { ["Starfire"] = 2.4 },
    ["Omen of Clarity"] = { ["Shred"] = 1.8, ["Starfire"] = 1.8, ["Wrath"] = 1.6, ["Rip"] = 1.6 }
}

-- Major Trinket & Burst Buff Names
local BURST_BUFFS = {
    ["Bloodlust"] = true,
    ["Heroism"] = true,
    ["Time Warp"] = true,
    ["Berserking"] = true,
    ["Blood Fury"] = true,
    ["Speed"] = true,
    ["Hyperspeed Acceleration"] = true,
    ["Greatness"] = true,
    ["Surge of Power"] = true,
    ["Mark of the War Prisoner"] = true,
    ["Abyssal Rune"] = true,
    ["Cultivated Power"] = true,
    ["Sundial of the Exiled"] = true,
    ["Flare of the Heavens"] = true,
    ["Show of Faith"] = true,
    ["Reign of the Dead"] = true,
    ["Reign of the Unliving"] = true,
    ["Dislodged Foreign Object"] = true,
    ["Phylactery of the Nameless Lich"] = true,
    ["Charred Twilight Scale"] = true,
    ["Deathbringer's Will"] = true,
    ["Whispering Fanged Skull"] = true,
    ["Mjolnir Runestone"] = true,
    ["Grim Toll"] = true
}

-- =====================================================================
-- WotLK 3.3.5a SPELL COEFFICIENTS & BASE DAMAGE DATABASE
-- =====================================================================
FC.SPELL_DAMAGE_DATABASE = FC.SPELL_DAMAGE_DATABASE or {
    -- -------------------------------------------------------------
    -- MAGE
    -- -------------------------------------------------------------
    ["Fireball"] = {
        baseMin = 898, baseMax = 1143,
        directCoeff = 1.0,
        dotBase = 116, dotCoeff = 0.08, dotDuration = 8,
        school = "Fire", baseCast = 3.5
    },
    ["Pyroblast"] = {
        baseMin = 1210, baseMax = 1531,
        directCoeff = 1.15,
        dotBase = 452, dotCoeff = 0.20, dotDuration = 12,
        school = "Fire", baseCast = 5.0
    },
    ["Living Bomb"] = {
        baseMin = 0, baseMax = 0,
        directCoeff = 0.0,
        dotBase = 1380, dotCoeff = 0.80, dotDuration = 12,
        explosionMin = 690, explosionMax = 690, explosionCoeff = 0.40,
        school = "Fire", baseCast = 0
    },
    ["Fire Blast"] = {
        baseMin = 664, baseMax = 786,
        directCoeff = 0.4286,
        school = "Fire", baseCast = 0, cooldown = 8
    },
    ["Scorch"] = {
        baseMin = 382, baseMax = 451,
        directCoeff = 0.4286,
        school = "Fire", baseCast = 1.5
    },
    ["Frostfire Bolt"] = {
        baseMin = 722, baseMax = 838,
        directCoeff = 0.8571,
        dotBase = 90, dotCoeff = 0.08, dotDuration = 9,
        school = "Fire", baseCast = 3.0
    },
    ["Frostbolt"] = {
        baseMin = 802, baseMax = 866,
        directCoeff = 0.8143,
        school = "Frost", baseCast = 3.0
    },
    ["Ice Lance"] = {
        baseMin = 223, baseMax = 258,
        directCoeff = 0.1429,
        shatterMult = 3.0,
        school = "Frost", baseCast = 0
    },
    ["Deep Freeze"] = {
        baseMin = 1463, baseMax = 1637,
        directCoeff = 0.7143,
        school = "Frost", baseCast = 0, cooldown = 30
    },
    ["Arcane Blast"] = {
        baseMin = 1185, baseMax = 1377,
        directCoeff = 0.8571,
        school = "Arcane", baseCast = 2.5
    },
    ["Arcane Missiles"] = {
        baseMin = 1810, baseMax = 1810,
        directCoeff = 1.4285,
        isChannel = true,
        school = "Arcane", baseCast = 5.0
    },
    ["Arcane Barrage"] = {
        baseMin = 936, baseMax = 1144,
        directCoeff = 0.7143,
        school = "Arcane", baseCast = 0, cooldown = 3
    },
    ["Flamestrike"] = {
        baseMin = 876, baseMax = 1071,
        directCoeff = 0.2357,
        dotBase = 780, dotCoeff = 0.48, dotDuration = 8,
        isAoE = true,
        school = "Fire", baseCast = 2.0
    },
    ["Flamestrike (Rank 8)"] = {
        baseMin = 675, baseMax = 825,
        directCoeff = 0.2357,
        dotBase = 620, dotCoeff = 0.48, dotDuration = 8,
        isAoE = true,
        school = "Fire", baseCast = 2.0
    },
    ["Flamestrike (Rank 7)"] = {
        baseMin = 480, baseMax = 585,
        directCoeff = 0.2357,
        dotBase = 424, dotCoeff = 0.48, dotDuration = 8,
        isAoE = true,
        school = "Fire", baseCast = 2.0
    },
    ["Blizzard"] = {
        baseMin = 3408, baseMax = 3408,
        directCoeff = 1.144,
        isAoE = true, isChannel = true,
        school = "Frost", baseCast = 8.0
    },
    ["Arcane Explosion"] = {
        baseMin = 538, baseMax = 582,
        directCoeff = 0.2128,
        isAoE = true,
        school = "Arcane", baseCast = 0
    },
    ["Dragon's Breath"] = {
        baseMin = 1101, baseMax = 1279,
        directCoeff = 0.193,
        isAoE = true,
        school = "Fire", baseCast = 0, cooldown = 20
    },
    ["Blast Wave"] = {
        baseMin = 1047, baseMax = 1233,
        directCoeff = 0.193,
        isAoE = true,
        school = "Fire", baseCast = 0, cooldown = 30
    },

    -- -------------------------------------------------------------
    -- WARLOCK
    -- -------------------------------------------------------------
    ["Shadow Bolt"] = { baseMin = 690, baseMax = 770, directCoeff = 0.8571, school = "Shadow", baseCast = 3.0 },
    ["Chaos Bolt"] = { baseMin = 1429, baseMax = 1813, directCoeff = 0.7143, school = "Fire", baseCast = 2.5, cooldown = 12 },
    ["Incinerate"] = { baseMin = 582, baseMax = 676, directCoeff = 0.7143, school = "Fire", baseCast = 2.5 },
    ["Immolate"] = { baseMin = 460, baseMax = 460, directCoeff = 0.20, dotBase = 785, dotCoeff = 0.65, dotDuration = 15, school = "Fire", baseCast = 2.0 },
    ["Corruption"] = { baseMin = 0, baseMax = 0, directCoeff = 0.0, dotBase = 1080, dotCoeff = 1.20, dotDuration = 18, school = "Shadow", baseCast = 0 },
    ["Unstable Affliction"] = { baseMin = 0, baseMax = 0, directCoeff = 0.0, dotBase = 1150, dotCoeff = 1.00, dotDuration = 15, school = "Shadow", baseCast = 1.5 },
    ["Haunt"] = { baseMin = 645, baseMax = 753, directCoeff = 0.4286, school = "Shadow", baseCast = 1.5, cooldown = 8 },
    ["Soul Fire"] = { baseMin = 1323, baseMax = 1657, directCoeff = 1.15, school = "Fire", baseCast = 4.0 },

    -- -------------------------------------------------------------
    -- PALADIN
    -- -------------------------------------------------------------
    ["Judgement of Light"] = { baseMin = 550, baseMax = 650, directCoeff = 0.25, apCoeff = 0.16, school = "Holy", baseCast = 0, cooldown = 8 },
    ["Judgement of Wisdom"] = { baseMin = 550, baseMax = 650, directCoeff = 0.25, apCoeff = 0.16, school = "Holy", baseCast = 0, cooldown = 8 },
    ["Crusader Strike"] = { weaponPct = 0.75, school = "Physical", baseCast = 0, cooldown = 4 },
    ["Divine Storm"] = { weaponPct = 1.10, isAoE = true, school = "Physical", baseCast = 0, cooldown = 10 },
    ["Exorcism"] = { baseMin = 1028, baseMax = 1146, directCoeff = 0.15, apCoeff = 0.15, school = "Holy", baseCast = 1.5, cooldown = 15 },
    ["Hammer of Wrath"] = { baseMin = 1139, baseMax = 1257, directCoeff = 0.15, apCoeff = 0.15, school = "Holy", baseCast = 0, cooldown = 6 },

    -- -------------------------------------------------------------
    -- SHAMAN
    -- -------------------------------------------------------------
    ["Lightning Bolt"] = { baseMin = 715, baseMax = 815, directCoeff = 0.7143, school = "Nature", baseCast = 2.5 },
    ["Chain Lightning"] = { baseMin = 973, baseMax = 1111, directCoeff = 0.5714, isAoE = true, school = "Nature", baseCast = 2.0, cooldown = 3 },
    ["Lava Burst"] = { baseMin = 1192, baseMax = 1518, directCoeff = 0.5714, school = "Fire", baseCast = 2.0, cooldown = 8 },
    ["Flame Shock"] = { baseMin = 500, baseMax = 500, directCoeff = 0.214, dotBase = 840, dotCoeff = 0.60, dotDuration = 18, school = "Fire", baseCast = 0, cooldown = 6 },
    ["Earth Shock"] = { baseMin = 849, baseMax = 895, directCoeff = 0.3858, school = "Nature", baseCast = 0, cooldown = 6 },

    -- -------------------------------------------------------------
    -- PRIEST
    -- -------------------------------------------------------------
    ["Mind Flay"] = { baseMin = 588, baseMax = 588, directCoeff = 0.771, isChannel = true, school = "Shadow", baseCast = 3.0 },
    ["Mind Blast"] = { baseMin = 997, baseMax = 1053, directCoeff = 0.4286, school = "Shadow", baseCast = 1.5, cooldown = 8 },
    ["Shadow Word: Pain"] = { baseMin = 0, baseMax = 0, dotBase = 1380, dotCoeff = 1.10, dotDuration = 18, school = "Shadow", baseCast = 0 },
    ["Vampiric Touch"] = { baseMin = 0, baseMax = 0, dotBase = 850, dotCoeff = 1.00, dotDuration = 15, school = "Shadow", baseCast = 1.5 },
    ["Shadow Word: Death"] = { baseMin = 750, baseMax = 870, directCoeff = 0.4286, school = "Shadow", baseCast = 0, cooldown = 12 },

    -- -------------------------------------------------------------
    -- DRUID
    -- -------------------------------------------------------------
    ["Starfire"] = { baseMin = 1038, baseMax = 1222, directCoeff = 1.0, school = "Arcane", baseCast = 3.5 },
    ["Wrath"] = { baseMin = 557, baseMax = 627, directCoeff = 0.5714, school = "Nature", baseCast = 1.5 },
    ["Moonfire"] = { baseMin = 406, baseMax = 476, directCoeff = 0.15, dotBase = 800, dotCoeff = 0.52, dotDuration = 12, school = "Arcane", baseCast = 0 },
    ["Insect Swarm"] = { baseMin = 0, baseMax = 0, dotBase = 1290, dotCoeff = 0.76, dotDuration = 12, school = "Nature", baseCast = 0 }
}

-- =====================================================================
-- CALCULATE EFFECTIVE CAST / EXECUTION TIME
-- =====================================================================
function FC:CalculateExecutionTime(action, state)
    state = state or FC.state or {}
    local p = state.player or {}
    local buffs = p.buffs or {}
    local stats = p.stats or {}
    local aName = action.spellName or action.name
    local baseGCD = FC.baseGCD or 1.5

    -- 1. Base Cast Time
    local baseCast = action.castTime or 0
    local dbEntry = self.SPELL_DAMAGE_DATABASE[aName]
    if dbEntry and dbEntry.baseCast then
        baseCast = dbEntry.baseCast
    end

    -- Apply Talent Cast Time Reductions (e.g. Improved Fireball, Bane, Starlight Wrath, etc.)
    if FC.GetTalentCastReduction and baseCast > 0 then
        local red = FC:GetTalentCastReduction(aName)
        baseCast = math.max(0, baseCast - red)
    end

    -- Glyph of Fireball (-0.15s cast time)
    if aName == "Fireball" and FC.HasGlyph and FC:HasGlyph("Fireball") then
        baseCast = math.max(0, baseCast - 0.15)
    end

    -- 2. Instant-Cast Procs (Zero Cast Time)
    if buffs["Netherwind Focus"] then
        baseCast = 0
    elseif aName == "Pyroblast" and (buffs["Hot Streak"] or (FC.combat and FC.combat.procs and FC.combat.procs["Hot Streak"] and FC.combat.procs["Hot Streak"].active)) then
        baseCast = 0
    elseif aName == "Fireball" and buffs["Brain Freeze"] then
        baseCast = 0
    elseif aName == "Frostfire Bolt" and buffs["Brain Freeze"] then
        baseCast = 0
    elseif aName == "Soul Fire" and buffs["Decimation"] then
        baseCast = baseCast * 0.40
    elseif aName == "Incinerate" and buffs["Backdraft"] then
        baseCast = baseCast * 0.70
    elseif aName == "Shadow Bolt" and buffs["Shadow Trance"] then
        baseCast = 0
    elseif aName == "Flash of Light" and buffs["The Art of War"] then
        baseCast = 0
    elseif aName == "Exorcism" and buffs["The Art of War"] then
        baseCast = 0
    elseif aName == "Healing Wave" and buffs["Maelstrom Weapon"] and (buffs["Maelstrom Weapon"].count or 0) >= 5 then
        baseCast = 0
    elseif aName == "Lightning Bolt" and buffs["Maelstrom Weapon"] and (buffs["Maelstrom Weapon"].count or 0) >= 5 then
        baseCast = 0
    elseif aName == "Slam" and (buffs["Bloodsurge"] or buffs["Slam!"]) then
        baseCast = 0
    elseif buffs["Presence of Mind"] and baseCast > 0 then
        baseCast = 0
    end

    -- 3. Live Dynamic Haste Multiplier
    local hasteMult = 1.0
    if FC.GetHasteMultiplier then
        local ok, h = pcall(FC.GetHasteMultiplier, FC)
        if ok and h and h > 0 then hasteMult = h end
    else
        local hastePct = stats.spellHaste or 0
        if buffs["Bloodlust"] or buffs["Heroism"] then hastePct = hastePct + 30 end
        if buffs["Hyperspeed Acceleration"] then hastePct = hastePct + 10.3 end
        if buffs["Berserking"] then hastePct = hastePct + 20 end
        hasteMult = 1.0 + (hastePct / 100)
    end

    local effCast = (baseCast > 0) and (baseCast / hasteMult) or 0
    local effGCD = (FC.GetEffectiveGCD and FC:GetEffectiveGCD()) or math.max(0.0, baseGCD / hasteMult)

    local executionTime = math.max(effGCD, effCast)
    return executionTime, effCast
end

-- =====================================================================
-- CALCULATE TRUE EXPECTED SPELL DAMAGE
-- =====================================================================
function FC:CalculateExpectedDamage(action, state)
    state = state or FC.state or {}
    local p = state.player or {}
    local t = state.target or {}
    local buffs = p.buffs or {}
    local tDebuffs = t.debuffs or {}
    local stats = p.stats or {}
    local spTable = stats.spellPower or {}
    local aName = action.spellName or action.name
    local school = action.school or "Physical"
    local enemyCount = state.enemyCount or 1

    local dbEntry = self.SPELL_DAMAGE_DATABASE[aName]
    local sp = spTable[school] or spTable.Max or 1500

    local rawDirect = 0
    local rawDoT = 0
    local dotDuration = 0

    if dbEntry then
        if dbEntry.baseMax and dbEntry.baseMax > 0 then
            local avgBase = (dbEntry.baseMin + dbEntry.baseMax) / 2
            local coeff = dbEntry.directCoeff or 0

            -- Talent: Empowered Fire (+5/10/15% SP coefficient to Fireball/Pyro/FFB)
            if FC.GetTalentRank and (aName == "Fireball" or aName == "Frostfire Bolt" or aName == "Pyroblast") then
                local empFire = FC:GetTalentRank("Empowered Fire")
                if empFire > 0 then
                    coeff = coeff + (empFire * 0.05)
                end
            end

            rawDirect = avgBase + (sp * coeff)
        end

        if dbEntry.apCoeff and stats.attackPower then
            rawDirect = rawDirect + (stats.attackPower * dbEntry.apCoeff)
        end

        if dbEntry.weaponPct then
            local avgWeaponDmg = (stats.weaponAvgDamage and stats.weaponAvgDamage > 0) and stats.weaponAvgDamage or (1200 + (stats.attackPower or 2000) / 14 * 3.3)
            rawDirect = avgWeaponDmg * dbEntry.weaponPct
        end

        if dbEntry.rangedWeaponPct then
            local avgRangedDmg = (stats.rangedAvgDamage and stats.rangedAvgDamage > 0) and stats.rangedAvgDamage or (1000 + (stats.rangedAttackPower or 2000) / 14 * 2.8)
            rawDirect = avgRangedDmg * dbEntry.rangedWeaponPct
        end

        if dbEntry.dotBase and dbEntry.dotBase > 0 then
            rawDoT = dbEntry.dotBase + (sp * (dbEntry.dotCoeff or 0))
            dotDuration = dbEntry.dotDuration or 12
        end

        if dbEntry.explosionMax and dbEntry.explosionMax > 0 then
            local expDmg = dbEntry.explosionMin + (sp * (dbEntry.explosionCoeff or 0))
            if enemyCount > 1 then
                expDmg = expDmg * (1.0 + (enemyCount - 1) * 0.85)
            end
            rawDirect = rawDirect + expDmg
        end

        if dbEntry.isAoE and enemyCount > 1 then
            rawDirect = rawDirect * math.min(10, enemyCount * 0.90)
        end
    else
        local cTime = action.castTime or 1.5
        rawDirect = 500 + (sp * math.max(0.2, cTime / 3.5))
    end

    -- Time-to-Death (TTD) DoT clipping
    if rawDoT > 0 and dotDuration > 0 then
        local ttd = t.ttd or 999
        if ttd < dotDuration then
            local frac = math.max(0.1, ttd / dotDuration)
            rawDoT = rawDoT * frac
        end
    end

    local totalRaw = rawDirect + rawDoT

    -- Multipliers
    local mult = 1.0

    -- 1. Synastria Class Set Bonuses
    if FC.extState and FC.extState.activeClassSet == "Fire Mage" and (FC.extState.classSetCount or 5) >= 4 then
        if school == "Fire" then
            mult = mult * 2.25
        end
    elseif FC.extState and FC.extState.activeClassSet and FC.SYNASTRIA_CLASS_SETS and FC.SYNASTRIA_CLASS_SETS[FC.extState.activeClassSet] then
        local setDef = FC.SYNASTRIA_CLASS_SETS[FC.extState.activeClassSet]
        if setDef.apply then
            local ok, newMult = pcall(setDef.apply, state, action, mult)
            if ok and newMult then mult = newMult end
        end
    end

    -- Synastria Attunements & Forges Multiplier
    if p.forges and p.forges.totalDamageBonus and p.forges.totalDamageBonus > 0 then
        mult = mult * (1.0 + p.forges.totalDamageBonus)
    end

    -- Comprehensive Multi-Expansion Tier Set Modifiers (Classic, TBC, WotLK)
    if p.setBonuses then
        local sb = p.setBonuses
        -- WotLK T10
        if sb.T10 and sb.T10 >= 4 and buffs["Mirror Image"] then
            mult = mult * 1.18
        end
        if sb.T10 and sb.T10 >= 4 and (aName == "Blood Boil" or aName == "Obliterate" or aName == "Scourge Strike") then
            mult = mult * 1.03
        end
        if sb.T10 and sb.T10 >= 4 and (aName == "Slam" or aName == "Execute") then
            mult = mult * 1.10
        end

        -- TBC T6
        if sb.T6 and sb.T6 >= 4 then
            if aName == "Fireball" or aName == "Frostbolt" or aName == "Arcane Missiles" then mult = mult * 1.05
            elseif aName == "Backstab" or aName == "Sinister Strike" or aName == "Mutilate" or aName == "Hemorrhage" then mult = mult * 1.06
            elseif aName == "Lightning Bolt" then mult = mult * 1.05
            elseif aName == "Steady Shot" then mult = mult * 1.10
            elseif aName == "Mortal Strike" or aName == "Bloodthirst" or aName == "Shield Slam" then mult = mult * 1.05
            elseif aName == "Mind Flay" or aName == "Shadow Word: Death" then mult = mult * 1.10
            elseif aName == "Shadow Bolt" or aName == "Incinerate" then mult = mult * 1.06
            elseif aName == "Starfire" or aName == "Mangle (Cat)" or aName == "Mangle (Bear)" then mult = mult * 1.05
            end
        end

        -- TBC T5
        if sb.T5 and sb.T5 >= 2 and aName == "Arcane Blast" then
            mult = mult * 1.20
        end
        if sb.T5 and sb.T5 >= 4 and (aName == "Corruption" or aName == "Immolate") then
            mult = mult * 1.10
        end

        -- Classic T3
        if sb.T3 and sb.T3 >= 4 and aName == "Shield Slam" then
            mult = mult * 1.12
        end
    end

    -- 2. Comprehensive Talent Multipliers
    if FC.GetTalentDamageMultiplier then
        local isSlowed = (t.isSnared or t.isSlowed or tDebuffs["Slow"] or tDebuffs["Cone of Cold"] or tDebuffs["Frostbolt"] or tDebuffs["Chilled"])
        local tMult = FC:GetTalentDamageMultiplier(aName, school, t.healthPct or 100, isSlowed)
        mult = mult * tMult
    end

    -- Glyph Specific Multipliers
    if FC.GetGlyphDamageMultiplier then
        mult = mult * FC:GetGlyphDamageMultiplier(aName)
    end

    -- 3. Target Debuffs (+13% Magic Damage)
    if tDebuffs["Curse of the Elements"] or tDebuffs["Ebon Plague"] or tDebuffs["Earth and Moon"] then
        if school ~= "Physical" then mult = mult * 1.13 end
    end
    if tDebuffs["Blood Frenzy"] or tDebuffs["Savage Combat"] then
        if school == "Physical" then mult = mult * 1.04 end
    end

    -- 4. Active Procs & Shatter
    if aName == "Ice Lance" and (t.isFrozen or buffs["Fingers of Frost"]) then
        local lanceMult = (FC.HasGlyph and FC:HasGlyph("Ice Lance")) and 4.0 or 3.0
        mult = mult * lanceMult
    elseif aName == "Deep Freeze" and (t.isFrozen or buffs["Fingers of Frost"]) then
        mult = mult * 2.0
    end

    local modifiedDmg = totalRaw * mult

    -- Critical Strike Expected Value
    local critChance = (stats.spellCrit or 25) / 100
    if school == "Physical" then critChance = (stats.meleeCrit or 20) / 100 end

    -- Talent & Glyph Crit Bonuses
    if FC.GetTalentCritBonus then
        local tCrit = FC:GetTalentCritBonus(aName, school)
        critChance = critChance + (tCrit / 100)
    end

    -- Tier Set Crit Bonuses
    if p.setBonuses then
        local sb = p.setBonuses
        if sb.T9 and sb.T9 >= 4 and (aName == "Fireball" or aName == "Frostfire Bolt" or aName == "Arcane Blast" or aName == "Shadow Bolt" or aName == "Incinerate" or aName == "Mortal Strike" or aName == "Bloodthirst") then
            critChance = critChance + 0.05
        end
        if sb.T10 and sb.T10 >= 4 and (aName == "Shadow Bolt" or aName == "Incinerate" or aName == "Soul Fire") then
            critChance = critChance + 0.10
        end
        if sb.T3 and sb.T3 >= 4 and (aName == "Corruption" or aName == "Immolate") then
            critChance = critChance + 0.05
        end
    end

    if aName == "Frostfire Bolt" and FC.HasGlyph and FC:HasGlyph("Frostfire") then
        critChance = critChance + 0.02
    elseif aName == "Explosive Shot" and FC.HasGlyph and FC:HasGlyph("Explosive Shot") then
        critChance = critChance + 0.04
    end

    if tDebuffs["Improved Scorch"] or tDebuffs["Shadow and Flame"] or tDebuffs["Winter's Chill"] then
        critChance = critChance + 0.05
    end
    if buffs["Combustion"] and school == "Fire" then critChance = critChance + 0.30 end
    if (t.isFrozen or buffs["Fingers of Frost"]) and (school == "Frost" or aName == "Frostfire Bolt") then
        critChance = critChance + 0.50
    end
    if aName == "Lava Burst" and (tDebuffs["Flame Shock"] or dbEntry and dbEntry.flameShockCrit) then
        critChance = 1.0
    end

    critChance = math.min(1.0, math.max(0.0, critChance))
    local critMultiplier = 2.0
    if FC.GetTalentCritMultiplier then
        critMultiplier = FC:GetTalentCritMultiplier(school)
    end

    if aName == "Arcane Missiles" and FC.HasGlyph and FC:HasGlyph("Arcane Missiles") then
        critMultiplier = critMultiplier + 0.25
    end

    -- Glyph of Living Bomb: Periodic DoT ticks can crit
    if aName == "Living Bomb" and FC.HasGlyph and FC:HasGlyph("Living Bomb") and rawDoT > 0 then
        -- Apply full crit expectation to the entire DoT portion
        expectedDmg = modifiedDmg * (1.0 + critChance * (critMultiplier - 1.0))
    else
        expectedDmg = modifiedDmg * (1.0 + critChance * (critMultiplier - 1.0))
    end

    -- Talent: Ignite (+40% of critical strike damage as extra periodic burn)
    if FC.GetTalentIgniteRate and school == "Fire" and rawDirect > 0 then
        local igniteRate = FC:GetTalentIgniteRate(school)
        if igniteRate > 0 then
            expectedDmg = expectedDmg + (critChance * (rawDirect * mult) * igniteRate)
        end
    end

    -- Target Time-to-Death (TTD) Truncation (Step 2)
    local ttd = (t and t.ttd) or 999
    if t.exists and ttd < 15 and (action.role == "dot" or (dbEntry and dbEntry.dotBase and dbEntry.dotBase > 0)) then
        local dotDur = (dbEntry and dbEntry.dotDuration) or action.dotDuration or 12
        local tickRate = (dbEntry and dbEntry.tickRate) or 3.0
        local maxTicks = math.max(1, math.floor(dotDur / tickRate))
        local usableTicks = math.max(0, math.floor(ttd / tickRate))

        if usableTicks < 1 then
            expectedDmg = expectedDmg * 0.10
        elseif usableTicks < maxTicks then
            expectedDmg = expectedDmg * (usableTicks / maxTicks)
        end
    end

    -- Empirical Combat Log Self-Learning Calibration (Step 1)
    if self.empiricalSamples and self.empiricalSamples[aName] then
        local s = self.empiricalSamples[aName]
        if s.hits >= 3 and (s.avgNonCrit > 0 or s.avgCrit > 0) then
            local liveSampleAvg = 0
            if s.avgNonCrit > 0 and s.avgCrit > 0 then
                local rate = math.min(1.0, math.max(0.0, s.crits / s.hits))
                liveSampleAvg = s.avgNonCrit * (1 - rate) + s.avgCrit * rate
            elseif s.avgNonCrit > 0 then
                liveSampleAvg = s.avgNonCrit * 1.35
            else
                liveSampleAvg = s.avgCrit
            end

            -- Blend 50% empirical live feedback with 50% theoretical scaling
            if liveSampleAvg > 0 then
                expectedDmg = (expectedDmg * 0.50) + (liveSampleAvg * 0.50)
            end
        end
    end

    -- Proc Enabler & Downstream Synergy Bonus Expected Value (EV)
    if self.CalculateProcEnablerValue then
        local okEn, enVal = pcall(self.CalculateProcEnablerValue, self, action, state)
        if okEn and enVal and enVal > 0 then
            expectedDmg = expectedDmg + enVal
        end
    end

    -- Synastria Forged Gear Multiplier (Lightforged/Warforged/Titanforged)
    local synBonus = (p and p.synastriaDamageBonus) or (self.forgedStats and self.forgedStats.totalDamageBonus) or 0
    if synBonus > 0 then
        expectedDmg = expectedDmg * (1.0 + synBonus)
    end

    return expectedDmg, modifiedDmg, critChance
end

-- =====================================================================
-- HELPER SCANNERS FOR SPELLS, TALENTS, AND TRINKETS
-- =====================================================================
function FC:IsAbilityKnown(abilityName)
    if not abilityName then return false end
    if self._registeredSpellNames and self._registeredSpellNames[abilityName] then return true end
    if self.knownSpells and self.knownSpells[abilityName] then return true end
    if self.actions then
        for _, a in ipairs(self.actions) do
            if a.name == abilityName or a.spellName == abilityName then
                return true
            end
        end
    end
    return false
end

function FC:HasTalent(talentName)
    if not talentName then return false end
    if self.GetTalentRank and self:GetTalentRank(talentName) > 0 then return true end
    if self.talents and self.talents.known and self.talents.known[talentName] then return true end
    return false
end

function FC:HasEquippedTrinket(trinketNameOrId)
    if not self.trackedTrinkets then return false end
    for _, t in ipairs(self.trackedTrinkets) do
        if t.name == trinketNameOrId or t.id == trinketNameOrId or (t.buff and t.buff == trinketNameOrId) then
            return true
        end
    end
    return false
end

-- =====================================================================
-- DYNAMIC CROSS-SPELL PREREQUISITE & SYNERGY GRAPH REGISTRY
-- Automatically discovers and activates synergy rules when the player
-- knows the required spells, has learned the talents, or has items equipped.
-- =====================================================================
FC.SYNERGY_RULES = {
    -- 1. MAGE: Fireball/FFB/Scorch -> Hot Streak -> Instant Pyroblast
    {
        id = "mage_hot_streak",
        class = "MAGE",
        enablers = { ["Fireball"] = true, ["Frostfire Bolt"] = true, ["Scorch"] = true },
        requiredFor = "Pyroblast",
        desc = "Fireball/FFB/Scorch crits trigger Hot Streak for instant Pyroblasts",
        isActive = function(self)
            return (self:IsAbilityKnown("Pyroblast") and self:HasTalent("Hot Streak")) or (self.playerClass == "MAGE" and self:IsAbilityKnown("Fireball"))
        end,
        calcEV = function(self, state, action)
            local p = state.player or {}
            local crit = (p.stats and p.stats.spellCrit or 25) / 100
            local buffs = p.buffs or {}
            if buffs["Combustion"] then crit = math.min(1.0, crit + 0.30) end
            local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Fire) or 0
            local pyroBase = 2500 + (sp * 1.15)
            return crit * pyroBase * 0.45
        end
    },

    -- 2. MAGE: Scorch -> Fire Vulnerability (+5% Spell Crit debuff)
    {
        id = "mage_scorch_crit",
        class = "MAGE",
        enablers = { ["Scorch"] = true },
        requiredFor = "Fire Vulnerability",
        desc = "Scorch applies +5% Spell Crit debuff (Improved Scorch) to target",
        isActive = function(self)
            return self.playerClass == "MAGE" and (self:HasTalent("Improved Scorch") or self:IsAbilityKnown("Scorch"))
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Improved Scorch"] and not tDebuffs["Shadow and Flame"] and not tDebuffs["Winter's Chill"] then
                local p = state.player or {}
                local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Fire) or 0
                return 1500 + (sp * 0.50)
            end
            return 0
        end
    },

    -- 3. MAGE: Living Bomb -> Multi-Target Hot Streak & Cleave Explosion
    {
        id = "mage_living_bomb",
        class = "MAGE",
        enablers = { ["Living Bomb"] = true },
        requiredFor = "Hot Streak & AoE Cleave",
        desc = "Living Bomb periodic ticks trigger Hot Streak; explosion cleaves all nearby enemies",
        isActive = function(self)
            return self:IsAbilityKnown("Living Bomb")
        end,
        calcEV = function(self, state, action)
            local p = state.player or {}
            local enemyCount = state.enemyCount or 1
            local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Fire) or 0
            local expBonus = 1800 + (sp * 0.40)
            local ev = expBonus * 0.35
            if enemyCount >= 2 then
                ev = ev + (expBonus * math.min(5, enemyCount) * 0.60)
            end
            return ev
        end
    },

    -- 4. MAGE: Arcane Blast -> Stacking Damage Multiplier (up to +72%)
    {
        id = "mage_arcane_blast_stacks",
        class = "MAGE",
        enablers = { ["Arcane Blast"] = true },
        requiredFor = "Arcane Stacks",
        desc = "Arcane Blast builds up to 4 stacks (+18% damage per stack to Arcane spells)",
        isActive = function(self)
            return self:IsAbilityKnown("Arcane Blast")
        end,
        calcEV = function(self, state, action)
            local buffs = (state.player and state.player.buffs) or {}
            local abAura = buffs["Arcane Blast"]
            local stacks = abAura and (abAura.count or 1) or 0
            if stacks < 4 then
                local p = state.player or {}
                local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Arcane) or 0
                return (1200 + sp * 0.80) * (4 - stacks) * 0.25
            end
            return 0
        end
    },

    -- 5. MAGE: Frostbolt -> Fingers of Frost & Brain Freeze Generator
    {
        id = "mage_frostbolt_procs",
        class = "MAGE",
        enablers = { ["Frostbolt"] = true },
        requiredFor = "Fingers of Frost / Brain Freeze",
        desc = "Frostbolt triggers Fingers of Frost (+50% crit Ice Lance/Deep Freeze) & Brain Freeze",
        isActive = function(self)
            return self:IsAbilityKnown("Frostbolt") and (self:HasTalent("Fingers of Frost") or self:HasTalent("Brain Freeze") or self:IsAbilityKnown("Ice Lance"))
        end,
        calcEV = function(self, state, action)
            local p = state.player or {}
            local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Frost) or 0
            local iceLanceEV = (800 + sp * 0.38) * 3.0
            return iceLanceEV * 0.25
        end
    },

    -- 6. SHAMAN: Flame Shock -> 100% Critical Strike on Lava Burst
    {
        id = "shaman_flame_shock_lavaburst",
        class = "SHAMAN",
        enablers = { ["Flame Shock"] = true },
        requiredFor = "Lava Burst",
        desc = "Flame Shock on target enables 100% Critical Strike on Lava Burst",
        isActive = function(self)
            return self:IsAbilityKnown("Flame Shock") and self:IsAbilityKnown("Lava Burst")
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Flame Shock"] or (tDebuffs["Flame Shock"].remaining or 0) <= 2.0 then
                local p = state.player or {}
                local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Fire) or 0
                return (1500 + sp * 0.57) * 1.50
            end
            return 0
        end
    },

    -- 7. SHAMAN: Stormstrike -> Nature Damage Amplification (+20%)
    {
        id = "shaman_stormstrike_nature",
        class = "SHAMAN",
        enablers = { ["Stormstrike"] = true },
        requiredFor = "Nature Spells",
        desc = "Stormstrike increases Nature damage dealt to target by +20%",
        isActive = function(self)
            return self:IsAbilityKnown("Stormstrike")
        end,
        calcEV = function(self, state, action)
            local p = state.player or {}
            local ap = (p.stats and p.stats.attackPower) or 0
            return ap * 0.50
        end
    },

    -- 8. WARLOCK: Immolate -> Required for Conflagrate & Molten Core
    {
        id = "warlock_immolate_conflag",
        class = "WARLOCK",
        enablers = { ["Immolate"] = true },
        requiredFor = "Conflagrate",
        desc = "Immolate debuff on target enables Conflagrate burst and Molten Core triggers",
        isActive = function(self)
            return self:IsAbilityKnown("Immolate") and (self:IsAbilityKnown("Conflagrate") or self:HasTalent("Molten Core"))
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Immolate"] or (tDebuffs["Immolate"].remaining or 0) <= 2.0 then
                local p = state.player or {}
                local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Fire) or 0
                return (1400 + sp * 0.60) * 1.25
            end
            return 0
        end
    },

    -- 9. WARLOCK: Corruption -> Nightfall (Instant Shadow Bolt)
    {
        id = "warlock_corruption_nightfall",
        class = "WARLOCK",
        enablers = { ["Corruption"] = true },
        requiredFor = "Shadow Bolt",
        desc = "Corruption ticks have a chance to trigger Nightfall (Instant Shadow Bolt)",
        isActive = function(self)
            return self:IsAbilityKnown("Corruption") and (self:HasTalent("Nightfall") or self:IsAbilityKnown("Shadow Bolt"))
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Corruption"] or (tDebuffs["Corruption"].remaining or 0) <= 2.5 then
                local p = state.player or {}
                local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Shadow) or 0
                return (1200 + sp * 0.85) * 0.35
            end
            return 0
        end
    },

    -- 10. WARLOCK: Haunt & Shadow Bolt -> Shadow Embrace (+5% per stack)
    {
        id = "warlock_shadow_embrace",
        class = "WARLOCK",
        enablers = { ["Haunt"] = true, ["Shadow Bolt"] = true },
        requiredFor = "Shadow Damage",
        desc = "Shadow Bolt/Haunt stacks Shadow Embrace (+5% shadow periodic damage per stack)",
        isActive = function(self)
            return self.playerClass == "WARLOCK" and (self:HasTalent("Shadow Embrace") or self:IsAbilityKnown("Haunt"))
        end,
        calcEV = function(self, state, action)
            local p = state.player or {}
            local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Shadow) or 0
            return (1100 + sp * 0.70) * 0.25
        end
    },

    -- 11. DRUID: Wrath & Starfire -> Eclipse State Transitions (Solar/Lunar)
    {
        id = "druid_eclipse_engine",
        class = "DRUID",
        enablers = { ["Wrath"] = true, ["Starfire"] = true },
        requiredFor = "Eclipse",
        desc = "Wrath crits trigger Lunar Eclipse (+40% Starfire crit); Starfire crits trigger Solar Eclipse (+30% Wrath dmg)",
        isActive = function(self)
            return self.playerClass == "DRUID" and (self:HasTalent("Eclipse") or self:IsAbilityKnown("Starfire"))
        end,
        calcEV = function(self, state, action)
            local buffs = (state.player and state.player.buffs) or {}
            if not buffs["Eclipse (Solar)"] and not buffs["Eclipse (Lunar)"] then
                local p = state.player or {}
                local aName = action.spellName or action.name
                if aName == "Wrath" then
                    local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Nature) or 0
                    return (1000 + sp * 0.57) * 0.40
                elseif aName == "Starfire" then
                    local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Arcane) or 0
                    return (1500 + sp * 1.00) * 0.40
                end
            end
            return 0
        end
    },

    -- 12. DRUID / ROGUE / WARRIOR: Mangle / Trauma -> +30% Bleed Amplification
    {
        id = "bleed_mangle_trauma",
        class = "ALL",
        enablers = { ["Mangle (Cat)"] = true, ["Mangle (Bear)"] = true, ["Trauma"] = true },
        requiredFor = "Bleed Spells (Rip, Rake, Rupture, Rend)",
        desc = "Mangle/Trauma increases bleed damage dealt to target by +30%",
        isActive = function(self)
            return self:IsAbilityKnown("Mangle (Cat)") or self:IsAbilityKnown("Mangle (Bear)") or self:HasTalent("Trauma")
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Mangle"] and not tDebuffs["Trauma"] then
                local p = state.player or {}
                local ap = (p.stats and p.stats.attackPower) or 0
                return ap * 0.45
            end
            return 0
        end
    },

    -- 13. PALADIN: Judgement / Crusader Strike -> The Art of War (Instant Exorcism)
    {
        id = "paladin_art_of_war",
        class = "PALADIN",
        enablers = { ["Judgement of Light"] = true, ["Judgement of Wisdom"] = true, ["Judgement of Justice"] = true, ["Crusader Strike"] = true },
        requiredFor = "Exorcism / Flash of Light",
        desc = "Melee crits trigger The Art of War (Instant Exorcism / Flash of Light)",
        isActive = function(self)
            return self.playerClass == "PALADIN" and (self:HasTalent("The Art of War") or self:IsAbilityKnown("Exorcism"))
        end,
        calcEV = function(self, state, action)
            local p = state.player or {}
            local ap = (p.stats and p.stats.attackPower) or 0
            local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Holy) or 0
            return (1100 + sp * 0.30 + ap * 0.15) * 0.45
        end
    },

    -- 14. DEATH KNIGHT: Icy Touch / Plague Strike -> Diseases (+25-50% to Obliterate/Scourge Strike)
    {
        id = "dk_diseases_engine",
        class = "DEATHKNIGHT",
        enablers = { ["Icy Touch"] = true, ["Plague Strike"] = true },
        requiredFor = "Obliterate / Scourge Strike / Death Strike",
        desc = "Frost Fever & Blood Plague amplify Obliterate/Scourge Strike damage by up to +50%",
        isActive = function(self)
            return self.playerClass == "DEATHKNIGHT" and (self:IsAbilityKnown("Obliterate") or self:IsAbilityKnown("Scourge Strike") or self:IsAbilityKnown("Death Strike"))
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            local aName = action.spellName or action.name
            if aName == "Icy Touch" and (not tDebuffs["Frost Fever"] or (tDebuffs["Frost Fever"].remaining or 0) <= 2.5) then
                local p = state.player or {}
                local ap = (p.stats and p.stats.attackPower) or 0
                return ap * 0.55
            elseif aName == "Plague Strike" and (not tDebuffs["Blood Plague"] or (tDebuffs["Blood Plague"].remaining or 0) <= 2.5) then
                local p = state.player or {}
                local ap = (p.stats and p.stats.attackPower) or 0
                return ap * 0.55
            end
            return 0
        end
    },

    -- 15. PRIEST: Mind Flay -> Refreshes Shadow Word: Pain
    {
        id = "priest_mind_flay_swp",
        class = "PRIEST",
        enablers = { ["Mind Flay"] = true },
        requiredFor = "Shadow Word: Pain",
        desc = "Mind Flay damage ticks refresh the duration of Shadow Word: Pain on target (Pain and Suffering)",
        isActive = function(self)
            return self.playerClass == "PRIEST" and (self:HasTalent("Pain and Suffering") or self:IsAbilityKnown("Shadow Word: Pain"))
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if tDebuffs["Shadow Word: Pain"] and (tDebuffs["Shadow Word: Pain"].remaining or 0) <= 4.0 then
                local p = state.player or {}
                local sp = (p.stats and p.stats.spellPower and p.stats.spellPower.Shadow) or 0
                return (1200 + sp * 0.70) * 0.50
            end
            return 0
        end
    },

    -- 16. HUNTER: Serpent Sting -> Chimera Shot Burst
    {
        id = "hunter_serpent_chimera",
        class = "HUNTER",
        enablers = { ["Serpent Sting"] = true },
        requiredFor = "Chimera Shot",
        desc = "Serpent Sting on target enables Chimera Shot 40% instant nature burst",
        isActive = function(self)
            return self:IsAbilityKnown("Serpent Sting") and self:IsAbilityKnown("Chimera Shot")
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Serpent Sting"] or (tDebuffs["Serpent Sting"].remaining or 0) <= 2.0 then
                local p = state.player or {}
                local rap = (p.stats and p.stats.rangedAttackPower) or (p.stats and p.stats.attackPower) or 0
                return (1400 + rap * 0.40) * 1.20
            end
            return 0
        end
    },

    -- 17. WARRIOR: Rend -> Taste for Blood (100% Crit Overpower)
    {
        id = "warrior_rend_overpower",
        class = "WARRIOR",
        enablers = { ["Rend"] = true },
        requiredFor = "Overpower",
        desc = "Rend periodic ticks trigger Taste for Blood (100% Crit Overpower in battle stance)",
        isActive = function(self)
            return self.playerClass == "WARRIOR" and (self:HasTalent("Taste for Blood") or self:IsAbilityKnown("Overpower"))
        end,
        calcEV = function(self, state, action)
            local tDebuffs = (state.target and state.target.debuffs) or {}
            if not tDebuffs["Rend"] or (tDebuffs["Rend"].remaining or 0) <= 2.0 then
                local p = state.player or {}
                local ap = (p.stats and p.stats.attackPower) or 0
                return (1200 + ap * 0.45) * 1.10
            end
            return 0
        end
    },

    -- 18. SYNASTRIA / TRINKET ON-HIT PPM ACCELERATION
    {
        id = "generic_trinket_perk_ppm",
        class = "ALL",
        enablers = {},
        requiredFor = "On-Hit Trinkets & Custom Perks",
        desc = "Multi-hit & fast-ticking abilities accelerate on-hit trinket and perk proc PPM",
        isActive = function(self)
            return (self.trackedTrinkets and #self.trackedTrinkets > 0) or (self.knownPerks and #self.knownPerks > 0)
        end,
        calcEV = function(self, state, action)
            local aName = action.spellName or action.name
            local dbEntry = self.SPELL_DAMAGE_DATABASE and self.SPELL_DAMAGE_DATABASE[aName]
            if dbEntry and dbEntry.dotBase and dbEntry.dotBase > 0 then
                return 200
            end
            return 0
        end
    }
}

-- =====================================================================
-- CALCULATE PROC ENABLER VALUE (DYNAMIC DISCOVERY)
-- =====================================================================
function FC:CalculateProcEnablerValue(action, state)
    state = state or FC.state or {}
    local aName = action.spellName or action.name
    if not aName then return 0 end

    local totalEV = 0
    for _, rule in ipairs(self.SYNERGY_RULES or {}) do
        if rule.class == "ALL" or rule.class == self.playerClass then
            if rule.enablers[aName] or (not next(rule.enablers) and rule.calcEV) then
                if rule.isActive and rule.isActive(self) then
                    local ok, ev = pcall(rule.calcEV, self, state, action)
                    if ok and ev and ev > 0 then
                        totalEV = totalEV + ev
                    end
                end
            end
        end
    end

    return totalEV
end

function FC:GetActiveSynergyReport()
    local activeRules = {}
    for _, rule in ipairs(self.SYNERGY_RULES or {}) do
        if rule.class == "ALL" or rule.class == self.playerClass then
            if rule.isActive and rule.isActive(self) then
                table.insert(activeRules, rule)
            end
        end
    end
    return activeRules
end

-- =====================================================================
-- DAMAGE PER CAST TIME (DPCT) & DAMAGE PER MANA (DPM)
-- =====================================================================
function FC:CalculateDPCT(action, state)
    state = state or FC.state
    local expDmg = self:CalculateExpectedDamage(action, state)
    local execTime = self:CalculateExecutionTime(action, state)
    local dpct = expDmg / math.max(0.05, execTime)
    return dpct, expDmg, execTime
end

function FC:CalculateDPM(action, state)
    state = state or FC.state
    local expDmg = self:CalculateExpectedDamage(action, state)
    local cost = action.powerCost or 0
    if cost <= 0 then return expDmg end
    local dpm = expDmg / cost
    return dpm, expDmg, cost
end

-- =====================================================================
-- APPLY PREDICTION SCORE (ROTATIONAL MULTIPLIERS)
-- =====================================================================
function FC:ApplyPredictionScore(action, state, score)
    local modifier = 1.0
    local talents = self.talents or {}
    local procs = self.combat and self.combat.procs or {}
    local player = state.player or {}
    local playerBuffs = player.buffs or {}
    local target = state.target or {}
    local enemyCount = state.enemyCount or 1
    local aName = action.spellName or action.name
    local stats = player.stats or {}

    -- 1. General Talent Crit/Haste Bonuses
    modifier = modifier + (talents.critBonus or 0)

    -- 2. CLASS PROCS & SYNERGIES
    for procName, synergies in pairs(PROC_SYNERGIES) do
        local procData = procs[procName]
        local isAuraActive = playerBuffs[procName] ~= nil

        if (procData and procData.active) or isAuraActive then
            local bonus = synergies[aName]
            if bonus then
                local mult = bonus
                if procData and procData.expiresAt then
                    local rem = procData.expiresAt - GetTime()
                    if rem > 0 and rem <= 2.0 then
                        mult = mult * 1.25
                    end
                end
                modifier = modifier * mult
            end
        end
    end

    -- 3. Action-Specific Proc Bonus
    if action.procBonus then
        for procName, mult in pairs(action.procBonus) do
            if playerBuffs[procName] or (procs[procName] and procs[procName].active) then
                modifier = modifier * mult
            end
        end
    end

    -- 4. Burst Cooldown Windows
    local isBurstActive = false
    for bBuff, _ in pairs(BURST_BUFFS) do
        if playerBuffs[bBuff] then
            isBurstActive = true
            break
        end
    end

    if isBurstActive then
        if action.role == "nuke" or action.role == "spender" or action.role == "execute" then
            modifier = modifier * 1.30
        elseif action.role == "builder" then
            modifier = modifier * 1.15
        end
    end

    -- 5. Tier Set Bonuses
    local setBonuses = talents.setBonuses or {}
    if setBonuses.T10 and setBonuses.T10 >= 4 then
        if action.role == "cooldown" or isBurstActive then
            modifier = modifier * 1.15
        end
    elseif setBonuses.T10 and setBonuses.T10 >= 2 then
        if action.role == "nuke" or action.role == "spender" then
            modifier = modifier * 1.08
        end
    end

    -- 6. Multi-Target / AoE Intelligence & Smart Multi-Dotting
    if action.role == "dot" and enemyCount >= 2 then
        local activeDotCount, dotList, maxAllowed = 0, {}, 3
        if self.GetMultiTargetDotInfo then
            activeDotCount, dotList, maxAllowed = self:GetMultiTargetDotInfo(aName)
        end
        local currentTargetHasDot = (target.debuffs and target.debuffs[aName] and (target.debuffs[aName].remaining or 0) > 3.0)
        if currentTargetHasDot and activeDotCount < math.min(enemyCount, maxAllowed) then
            modifier = modifier * 1.50
            action.isOffTarget = true
        else
            action.isOffTarget = false
        end
    elseif action.role == "aoe" then
        action.isOffTarget = false
        if enemyCount >= 2 then
            modifier = modifier * (1.0 + (enemyCount - 1) * 0.50)
        else
            if action.castTime and action.castTime >= 4.0 then
                modifier = modifier * 0.40
            end
        end
    elseif (action.role == "nuke" or action.role == "builder") and enemyCount >= 4 then
        action.isOffTarget = false
        modifier = modifier * 0.65
    else
        action.isOffTarget = false
    end

    -- 7. Frozen / Shatter Mechanics
    local isFrozen = target.isFrozen or (playerBuffs["Fingers of Frost"] and playerBuffs["Fingers of Frost"].remaining > 0)
    if isFrozen then
        if aName == "Ice Lance" then
            modifier = modifier * 2.8
        elseif aName == "Deep Freeze" then
            modifier = modifier * 3.2
        elseif aName == "Frostbolt" or aName == "Frostfire Bolt" then
            modifier = modifier * 1.6
        end
    end

    -- 8. Creature Type Synergies
    if target.isUndead or target.isDemon then
        if aName == "Exorcism" then
            modifier = modifier * 1.7
        elseif aName == "Holy Wrath" then
            modifier = modifier * 2.0
        end
    end

    -- 9. Enemy Resistance & Immunity Suppression
    if target.resistances and action.school then
        local res = target.resistances[action.school]
        if res == "IMMUNE" then
            return 0.0
        elseif res == "HIGH_RESIST" or res == "RESIST" then
            modifier = modifier * 0.30
        end
    end

    -- 10. Crowd Control Break Prevention
    if target.isCrowdControlled then
        if action.role == "nuke" or action.role == "aoe" or action.role == "dot" or action.role == "spender" or action.role == "builder" then
            return 0.0
        end
    end

    -- 11. Projectile In-Flight Flight-Time Prediction (Step 3)
    if self.inFlightProjectiles and #self.inFlightProjectiles > 0 then
        local now = GetTime()
        for _, pProj in ipairs(self.inFlightProjectiles) do
            local timeUntilLand = pProj.landsAt - now
            if timeUntilLand > 0 and timeUntilLand <= 1.2 then
                if (pProj.spell == "Fireball" or pProj.spell == "Frostfire Bolt" or pProj.spell == "Pyroblast") and aName == "Pyroblast" then
                    modifier = modifier * 1.35
                elseif (pProj.spell == "Frostbolt" or pProj.spell == "Frostfire Bolt") and (aName == "Ice Lance" or aName == "Deep Freeze") then
                    modifier = modifier * 1.25
                end
            end
        end
    end

    -- 12. Preemptive Mana Starvation & Consumable Engine (Step 6 / Item 5)
    if player.timeToOOM and player.timeToOOM < 15.0 and (player.powerMax and (player.powerMax - player.power) >= 3200) then
        if aName == "Mana Gem" or aName == "Runic Mana Potion" or aName == "Potion of Wild Magic" or aName == "Mana Potion" then
            modifier = modifier * 2.80
        elseif aName == "Evocation" and player.timeToOOM < 8.0 and not isBurstActive then
            modifier = modifier * 3.50
        end
    end

    -- 13. Boss Mechanic & Incoming Lethal Defensive Trigger (Step 5 / Item 6)
    if state.incomingThreat then
        if action.role == "defensive" or aName == "Ice Block" or aName == "Mana Shield" or aName == "Mirror Image" or aName == "Cloak of Shadows" or aName == "Anti-Magic Shell" or aName == "Divine Shield" or aName == "Barkskin" then
            modifier = modifier * 4.50
        end
    end

    -- 14. Movement Awareness & Casting-On-The-Move Priority (Phase 1)
    if player.isMoving then
        local rawCastTime = action.castTime or 0
        local effCastTime = action.effectiveCast or rawCastTime
        local isInstantProc = false

        -- Check instant proc buffs
        if aName == "Pyroblast" and pBuffs["Hot Streak"] then
            isInstantProc = true
        elseif aName == "Flamestrike" and pBuffs["Hot Streak"] then
            isInstantProc = true
        elseif (aName == "Fireball" or aName == "Frostfire Bolt") and pBuffs["Brain Freeze"] then
            isInstantProc = true
        elseif (aName == "Exorcism" or aName == "Flash of Light") and pBuffs["The Art of War"] then
            isInstantProc = true
        elseif aName == "Scorch" and (pBuffs["Firestarter"] or pBuffs["Critical Mass"]) then
            isInstantProc = true
        elseif aName == "Execute" and pBuffs["Sudden Death"] then
            isInstantProc = true
        elseif aName == "Frost Strike" and pBuffs["Killing Machine"] then
            isInstantProc = true
        elseif pBuffs["Presence of Mind"] or pBuffs["Nature's Swiftness"] or pBuffs["Predatory Strikes"] or pBuffs["Predator's Swiftness"] then
            isInstantProc = true
        elseif pBuffs["Maelstrom Weapon"] and (type(pBuffs["Maelstrom Weapon"]) == "table" and (pBuffs["Maelstrom Weapon"].count or 1) >= 5) then
            isInstantProc = true
        end

        if effCastTime > 0.05 and not isInstantProc then
            -- Immobile hard-cast while moving -> suppress
            return 0.0
        elseif isInstantProc or effCastTime <= 0.05 then
            -- Instant-cast ability while moving -> elevate priority
            modifier = modifier * 1.85
        end
    end

    -- 15. Group Threat & Over-Aggro Dump Cooldowns (Phase 2)
    if state.highThreat then
        if aName == "Mirror Image" or aName == "Invisibility" or aName == "Fade" or aName == "Feign Death" or aName == "Hand of Salvation" or aName == "Vanish" or aName == "Soulshatter" or aName == "Cower" then
            modifier = modifier * 5.00
        elseif action.role == "defensive" or aName == "Ice Block" or aName == "Divine Shield" or aName == "Cloak of Shadows" or aName == "Evasion" or aName == "Deterrence" then
            modifier = modifier * 3.50
        end
    end

    -- 16. Target Time-To-Death (TTD) Overkill Protection & Instant Finisher Elevation
    if target and target.exists and target.ttd and target.ttd > 0 and target.ttd < 5.0 then
        local rawCastTime = action.castTime or 0
        local effCastTime = action.effectiveCast or rawCastTime
        if effCastTime > 0.05 and target.ttd < (effCastTime * 0.95) then
            -- Mob will die before hard-cast lands -> suppress overkill
            return 0.0
        elseif effCastTime <= 0.05 and (action.role == "execute" or aName == "Fire Blast" or aName == "Ice Lance" or aName == "Shadow Word: Death" or aName == "Kill Shot" or aName == "Hammer of Wrath" or aName == "Execute" or aName == "Heroic Strike" or aName == "Shadowburn") then
            -- Low-TTD instant execution finisher -> elevate
            modifier = modifier * 2.50
        end
    end

    return score * modifier
end

-- =====================================================================
-- DECISION EXPLANATION & LOGIC DIAGNOSTICS ENGINE
-- =====================================================================
function FC:ExplainDecision()
    if self.UpdateState then self:UpdateState() end
    if self.UpdatePlayerStats then self:UpdatePlayerStats() end
    local state = self.state or {}
    local player = state.player or {}
    local target = state.target or {}
    local pBuffs = player.buffs or {}

    self:Print("=== LIVE RECOMMENDATION DECISION LOGIC ===")

    -- 1. Print Context Summary
    local tName = (target.name and target.name ~= "") and target.name or "None"
    local tHP = string.format("%.1f%%", target.healthPct or 0)
    local tTTD = string.format("%.1fs", target.ttd or 999)
    local isMoving = player.isMoving and "|cffff8800YES (Casting-on-the-Move)|r" or "|cff55ff55NO (Stationary)|r"
    local effGCDVal = (player.stats and player.stats.effectiveGCD) or (self.player and self.player.stats and self.player.stats.effectiveGCD) or self.effectiveHasteGCD or 1.5
    local effGCD = string.format("%.3fs", effGCDVal)
    local threatStr = state.isThreatMonitoringActive and (state.highThreat and "|cffff2222HIGH AGGRO (Defensives Active)|r" or string.format("|cff55ff55%.0f%% (Safe)|r", state.threatPercent or 0)) or "|cffaaaaaaN/A (Solo/Tank)|r"

    self:Print(string.format("  Target: |cffffd700%s|r (%s HP | TTD: %s)", tName, tHP, tTTD))
    self:Print(string.format("  Movement: %s | Effective GCD: |cff00ccff%s|r | Threat: %s", isMoving, effGCD, threatStr))

    -- Active Procs & Bursts
    local activeProcList = {}
    if pBuffs["Hot Streak"] then table.insert(activeProcList, "|cffff8800Hot Streak|r") end
    if pBuffs["Brain Freeze"] then table.insert(activeProcList, "|cff00ccffBrain Freeze|r") end
    if pBuffs["The Art of War"] then table.insert(activeProcList, "|cffffd700Art of War|r") end
    if pBuffs["Killing Machine"] then table.insert(activeProcList, "|cff00ffffKilling Machine|r") end
    if pBuffs["Sudden Death"] then table.insert(activeProcList, "|cffff3333Sudden Death|r") end
    if pBuffs["Maelstrom Weapon"] then table.insert(activeProcList, "|cff33ffccMaelstrom 5|r") end
    if pBuffs["Combustion"] or pBuffs["Arcane Power"] or pBuffs["Icy Veins"] or pBuffs["Heroism"] or pBuffs["Bloodlust"] then
        table.insert(activeProcList, "|cffff00ffBurst Window Active|r")
    end

    if #activeProcList > 0 then
        self:Print("  Active Procs & Bursts: " .. table.concat(activeProcList, ", "))
    end

    -- 2. Evaluate All Candidate Actions (Single Target, DoTs, AoE, Cooldowns)
    local readyCandidates = {}
    local conditionalSpells = {}
    local suppressedSpells = {}

    for _, action in ipairs(self.actions or {}) do
        if action.role ~= "fallback" and action.role ~= "idle" and not action.isSynastriaPerk then
            local aName = action.name or "Unknown"
            local isEnabled = (not FC.db or not FC.db.spellOverrides or not FC.db.spellOverrides[aName] or FC.db.spellOverrides[aName].enabled ~= false)
            
            if isEnabled then
                local finalScore, dpct, expDmg, effCast, customReasons = self:EvaluateActionScore(action, state)
                local reasons = customReasons or {}

                local isConditionMet = true
                local condReason = nil

                if action.cooldown and action.cooldown > 0 and action.cooldownExpiry and action.cooldownExpiry > GetTime() then
                    isConditionMet = false
                    condReason = string.format("On Cooldown (%.1fs remaining)", action.cooldownExpiry - GetTime())
                elseif state.target and state.target.exists and self.IsTargetInImpactRange then
                    local inRange, rangeErr = self:IsTargetInImpactRange(aName, "target", action.impactRadius or action.radius)
                    if not inRange then
                        isConditionMet = false
                        condReason = rangeErr or "Out of impact/spell range"
                    end
                end

                if isConditionMet and action.conditions then
                    local success, result = pcall(action.conditions, state)
                    if not success or not result then
                        isConditionMet = false
                        if aName == "Pyroblast" and not pBuffs["Hot Streak"] then
                            condReason = "Awaiting Hot Streak proc (hard-cast unbuffed)"
                        elseif aName == "Living Bomb" and target.debuffs and target.debuffs["Living Bomb"] and (target.debuffs["Living Bomb"].remaining or 0) > 1.5 then
                            condReason = string.format("Living Bomb active (%.1fs rem) - early clip prevented", target.debuffs["Living Bomb"].remaining)
                        elseif aName == "Deep Freeze" then
                            condReason = "Requires Frozen target or Fingers of Frost"
                        elseif aName == "Combustion" and not state.engaged then
                            condReason = "Reserved for active combat engagement"
                        elseif aName == "Counterspell" then
                            condReason = "Target not actively casting/channeling"
                        else
                            condReason = "Specific situational trigger not met"
                        end
                    end
                end

                if player.isMoving then
                    if effCast > 0.05 and finalScore == 0 then
                        table.insert(reasons, "|cffff2222Hard-cast suppressed while moving|r")
                    elseif effCast <= 0.05 then
                        table.insert(reasons, "|cff55ff55Instant-cast mobility boost (+85%)|r")
                    end
                end

                if aName == "Pyroblast" and pBuffs["Hot Streak"] then
                    table.insert(reasons, "|cffff8800Instant Hot Streak proc (+100% priority)|r")
                elseif (aName == "Fireball" or aName == "Frostfire Bolt") and pBuffs["Brain Freeze"] then
                    table.insert(reasons, "|cff00ccffInstant Brain Freeze proc|r")
                end

                if action.downstreamEV and action.downstreamEV > 0 then
                    table.insert(reasons, string.format("|cffffd700Synergy: +%.0f Downstream EV|r", action.downstreamEV))
                end

                if target.ttd and target.ttd < 15 and action.role == "dot" then
                    table.insert(reasons, string.format("|cffff8800DoT truncated by target TTD (%.1fs)|r", target.ttd))
                end

                if target.ttd and target.ttd > 0 and target.ttd < 5.0 then
                    if effCast > 0.05 and target.ttd < (effCast * 0.95) then
                        table.insert(reasons, string.format("|cffff2222Overkill suppressed: TTD (%.1fs) < Cast (%.2fs)|r", target.ttd, effCast))
                    elseif effCast <= 0.05 and (action.role == "execute" or aName == "Fire Blast" or aName == "Ice Lance" or aName == "Shadow Word: Death" or aName == "Kill Shot" or aName == "Hammer of Wrath" or aName == "Execute" or aName == "Heroic Strike" or aName == "Shadowburn") then
                        table.insert(reasons, string.format("|cff55ff55Instant execution finisher elevated (TTD %.1fs)|r", target.ttd))
                    end
                end

                if action.isOffTarget then
                    table.insert(reasons, "|cff00ccffSmart multi-dotting off-target bonus (+50%)|r")
                end

                if state.highThreat and (aName == "Mirror Image" or aName == "Invisibility" or aName == "Fade" or aName == "Feign Death") then
                    table.insert(reasons, "|cffff2222Over-aggro threat dump boost (+400%)|r")
                end

                local entry = {
                    name = aName,
                    role = action.role or "nuke",
                    finalScore = finalScore,
                    expDmg = expDmg or action.expDmg or finalScore,
                    effCast = effCast or action.effectiveCast or action.castTime or 0,
                    dpct = dpct or (effCast and effCast > 0 and (expDmg / effCast)) or 0,
                    reasons = reasons,
                    condReason = condReason
                }

                if isConditionMet then
                    table.insert(readyCandidates, entry)
                else
                    table.insert(conditionalSpells, entry)
                end
            else
                table.insert(suppressedSpells, { name = aName, reason = "Disabled in settings" })
            end
        end
    end

    table.sort(readyCandidates, function(a, b) return a.finalScore > b.finalScore end)
    table.sort(conditionalSpells, function(a, b) return a.dpct > b.dpct end)

    if #readyCandidates == 0 and #conditionalSpells == 0 then
        self:Print("  No known rotational spells discovered.")
        return
    end

    if #readyCandidates > 0 then
        local topAction = readyCandidates[1]
        self:Print(string.format("  |cff55ff55★ TOP RECOMMENDATION:|r |cffffd700%s|r (Score: |cffff8800%.0f|r)", topAction.name, topAction.finalScore))

        self:Print("=== READY CANDIDATES (RANKED BY LIVE EV) ===")
        for i = 1, math.min(6, #readyCandidates) do
            local cand = readyCandidates[i]
            local rankCol = (i == 1 and "|cff55ff55") or (i == 2 and "|cffffd700") or "|cff00ccff"
            self:Print(string.format("  %s%d. %s|r -> Score: |cffff8800%.0f|r | Expected: %.0f dmg | Cast: %.2fs | DPCT: %.0f",
                rankCol, i, cand.name, cand.finalScore, cand.expDmg, cand.effCast, cand.dpct))

            if #cand.reasons > 0 then
                self:Print("     " .. table.concat(cand.reasons, " | "))
            end

            if i > 1 and i <= 3 then
                local diff = topAction.finalScore - cand.finalScore
                self:Print(string.format("     |cff888888Why lower than #1: %.0f lower score (%s)|r", diff,
                    cand.finalScore == 0 and "Action suppressed by combat state" or (cand.dpct < topAction.dpct and "Lower DPCT efficiency" or "Lower priority weighting")))
            end
        end
    else
        self:Print("  |cffff8800No rotational abilities currently ready to cast.|r")
    end

    if #conditionalSpells > 0 then
        self:Print("=== CONDITIONAL / SITUATIONAL SPELLS ===")
        for i = 1, math.min(6, #conditionalSpells) do
            local cand = conditionalSpells[i]
            self:Print(string.format("  - |cffffd700%s|r (%s): Expected: %.0f dmg | DPCT: %.0f -> |cffff8888%s|r",
                cand.name, cand.role, cand.expDmg, cand.dpct, cand.condReason or "Waiting"))
        end
    end

    if #suppressedSpells > 0 then
        self:Print("=== DISABLED SPELLS ===")
        for i = 1, math.min(3, #suppressedSpells) do
            self:Print(string.format("  - |cff888888%s: %s|r", suppressedSpells[i].name, suppressedSpells[i].reason))
        end
    end

    self:Print("=== END DECISION ANALYSIS ===")
end
