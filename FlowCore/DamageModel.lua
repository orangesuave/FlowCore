FlowCore = FlowCore or {}
local FC = FlowCore

-- =====================================================================
-- WotLK 3.3.5a SPELL COEFFICIENTS & BASE DAMAGE DATABASE
-- =====================================================================
local SPELL_DAMAGE_DATABASE = {
    -- -------------------------------------------------------------
    -- MAGE
    -- -------------------------------------------------------------
    ["Fireball"] = {
        baseMin = 898, baseMax = 1143,
        directCoeff = 1.0, -- (3.5 / 3.5)
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
        directCoeff = 0.4286, -- (1.5 / 3.5)
        school = "Fire", baseCast = 0, cooldown = 8
    },
    ["Scorch"] = {
        baseMin = 382, baseMax = 451,
        directCoeff = 0.4286, -- (1.5 / 3.5)
        school = "Fire", baseCast = 1.5
    },
    ["Frostfire Bolt"] = {
        baseMin = 722, baseMax = 838,
        directCoeff = 0.8571, -- (3.0 / 3.5)
        dotBase = 90, dotCoeff = 0.08, dotDuration = 9,
        school = "Fire", baseCast = 3.0
    },
    ["Frostbolt"] = {
        baseMin = 802, baseMax = 866,
        directCoeff = 0.8143, -- (3.0 / 3.5 * 0.95 slow penalty)
        school = "Frost", baseCast = 3.0
    },
    ["Ice Lance"] = {
        baseMin = 223, baseMax = 258,
        directCoeff = 0.1429,
        shatterMult = 3.0, -- 3x on frozen
        school = "Frost", baseCast = 0
    },
    ["Deep Freeze"] = {
        baseMin = 1463, baseMax = 1637,
        directCoeff = 0.7143,
        school = "Frost", baseCast = 0, cooldown = 30
    },
    ["Arcane Blast"] = {
        baseMin = 1185, baseMax = 1377,
        directCoeff = 0.8571, -- (2.5 / 3.5 + 0.1429)
        school = "Arcane", baseCast = 2.5
    },
    ["Arcane Missiles"] = {
        baseMin = 1810, baseMax = 1810, -- 5 waves of 362
        directCoeff = 1.4285, -- 5 * 0.2857
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
    ["Blizzard"] = {
        baseMin = 3408, baseMax = 3408, -- 8 waves of 426
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
    ["Shadow Bolt"] = {
        baseMin = 690, baseMax = 770,
        directCoeff = 0.8571,
        school = "Shadow", baseCast = 3.0
    },
    ["Chaos Bolt"] = {
        baseMin = 1429, baseMax = 1813,
        directCoeff = 0.7143,
        school = "Fire", baseCast = 2.5, cooldown = 12
    },
    ["Incinerate"] = {
        baseMin = 582, baseMax = 676,
        directCoeff = 0.7143,
        immolateBonus = 0.25,
        school = "Fire", baseCast = 2.5
    },
    ["Immolate"] = {
        baseMin = 460, baseMax = 460,
        directCoeff = 0.20,
        dotBase = 785, dotCoeff = 0.65, dotDuration = 15,
        school = "Fire", baseCast = 2.0
    },
    ["Corruption"] = {
        baseMin = 0, baseMax = 0,
        directCoeff = 0.0,
        dotBase = 1080, dotCoeff = 1.20, dotDuration = 18,
        school = "Shadow", baseCast = 0
    },
    ["Unstable Affliction"] = {
        baseMin = 0, baseMax = 0,
        directCoeff = 0.0,
        dotBase = 1150, dotCoeff = 1.00, dotDuration = 15,
        school = "Shadow", baseCast = 1.5
    },
    ["Haunt"] = {
        baseMin = 645, baseMax = 753,
        directCoeff = 0.4286,
        school = "Shadow", baseCast = 1.5, cooldown = 8
    },
    ["Soul Fire"] = {
        baseMin = 1323, baseMax = 1657,
        directCoeff = 1.15,
        school = "Fire", baseCast = 4.0
    },

    -- -------------------------------------------------------------
    -- PALADIN
    -- -------------------------------------------------------------
    ["Judgement of Light"] = {
        baseMin = 550, baseMax = 650,
        directCoeff = 0.25, apCoeff = 0.16,
        school = "Holy", baseCast = 0, cooldown = 8
    },
    ["Judgement of Wisdom"] = {
        baseMin = 550, baseMax = 650,
        directCoeff = 0.25, apCoeff = 0.16,
        school = "Holy", baseCast = 0, cooldown = 8
    },
    ["Crusader Strike"] = {
        weaponPct = 0.75,
        school = "Physical", baseCast = 0, cooldown = 4
    },
    ["Divine Storm"] = {
        weaponPct = 1.10, isAoE = true,
        school = "Physical", baseCast = 0, cooldown = 10
    },
    ["Exorcism"] = {
        baseMin = 1028, baseMax = 1146,
        directCoeff = 0.15, apCoeff = 0.15,
        school = "Holy", baseCast = 1.5, cooldown = 15
    },
    ["Hammer of Wrath"] = {
        baseMin = 1139, baseMax = 1257,
        directCoeff = 0.15, apCoeff = 0.15,
        school = "Holy", baseCast = 0, cooldown = 6
    },

    -- -------------------------------------------------------------
    -- SHAMAN
    -- -------------------------------------------------------------
    ["Lightning Bolt"] = {
        baseMin = 715, baseMax = 815,
        directCoeff = 0.7143,
        school = "Nature", baseCast = 2.5
    },
    ["Chain Lightning"] = {
        baseMin = 973, baseMax = 1111,
        directCoeff = 0.5714, isAoE = true,
        school = "Nature", baseCast = 2.0, cooldown = 3
    },
    ["Lava Burst"] = {
        baseMin = 1192, baseMax = 1518,
        directCoeff = 0.5714,
        flameShockCrit = true, -- Always crits if Flame Shock is on target
        school = "Fire", baseCast = 2.0, cooldown = 8
    },
    ["Flame Shock"] = {
        baseMin = 500, baseMax = 500,
        directCoeff = 0.214,
        dotBase = 840, dotCoeff = 0.60, dotDuration = 18,
        school = "Fire", baseCast = 0, cooldown = 6
    },
    ["Earth Shock"] = {
        baseMin = 849, baseMax = 895,
        directCoeff = 0.3858,
        school = "Nature", baseCast = 0, cooldown = 6
    },

    -- -------------------------------------------------------------
    -- PRIEST
    -- -------------------------------------------------------------
    ["Mind Flay"] = {
        baseMin = 588, baseMax = 588,
        directCoeff = 0.771,
        isChannel = true,
        school = "Shadow", baseCast = 3.0
    },
    ["Mind Blast"] = {
        baseMin = 997, baseMax = 1053,
        directCoeff = 0.4286,
        school = "Shadow", baseCast = 1.5, cooldown = 8
    },
    ["Shadow Word: Pain"] = {
        baseMin = 0, baseMax = 0,
        dotBase = 1380, dotCoeff = 1.10, dotDuration = 18,
        school = "Shadow", baseCast = 0
    },
    ["Vampiric Touch"] = {
        baseMin = 0, baseMax = 0,
        dotBase = 850, dotCoeff = 1.00, dotDuration = 15,
        school = "Shadow", baseCast = 1.5
    },
    ["Shadow Word: Death"] = {
        baseMin = 750, baseMax = 870,
        directCoeff = 0.4286,
        school = "Shadow", baseCast = 0, cooldown = 12
    },

    -- -------------------------------------------------------------
    -- DRUID
    -- -------------------------------------------------------------
    ["Starfire"] = {
        baseMin = 1038, baseMax = 1222,
        directCoeff = 1.0,
        school = "Arcane", baseCast = 3.5
    },
    ["Wrath"] = {
        baseMin = 557, baseMax = 627,
        directCoeff = 0.5714,
        school = "Nature", baseCast = 1.5
    },
    ["Moonfire"] = {
        baseMin = 406, baseMax = 476,
        directCoeff = 0.15,
        dotBase = 800, dotCoeff = 0.52, dotDuration = 12,
        school = "Arcane", baseCast = 0
    },
    ["Insect Swarm"] = {
        baseMin = 0, baseMax = 0,
        dotBase = 1290, dotCoeff = 0.76, dotDuration = 12,
        school = "Nature", baseCast = 0
    }
}

-- =====================================================================
-- CALCULATE EFFECTIVE CAST / EXECUTION TIME
-- =====================================================================
function FC:CalculateExecutionTime(action, state)
    state = state or FC.state
    local p = state.player or {}
    local buffs = p.buffs or {}
    local stats = p.stats or {}
    local aName = action.spellName or action.name
    local baseGCD = FC.baseGCD or 1.5

    -- 1. Base Cast Time
    local baseCast = action.castTime or 0
    local dbEntry = SPELL_DAMAGE_DATABASE[aName]
    if dbEntry and dbEntry.baseCast then
        baseCast = dbEntry.baseCast
    end

    -- 2. Instant-Cast Procs (Zero Cast Time)
    if aName == "Pyroblast" and (buffs["Hot Streak"] or (FC.combat and FC.combat.procs and FC.combat.procs["Hot Streak"] and FC.combat.procs["Hot Streak"].active)) then
        baseCast = 0
    elseif aName == "Fireball" and buffs["Brain Freeze"] then
        baseCast = 0
    elseif aName == "Soul Fire" and buffs["Decimation"] then
        baseCast = baseCast * 0.40 -- -60% cast time
    elseif aName == "Incinerate" and buffs["Backdraft"] then
        baseCast = baseCast * 0.70 -- -30% cast time
    elseif aName == "Flash of Light" and buffs["The Art of War"] then
        baseCast = 0
    elseif aName == "Exorcism" and buffs["The Art of War"] then
        baseCast = 0
    elseif aName == "Healing Wave" and buffs["Maelstrom Weapon"] and (buffs["Maelstrom Weapon"].count or 0) >= 5 then
        baseCast = 0
    elseif aName == "Lightning Bolt" and buffs["Maelstrom Weapon"] and (buffs["Maelstrom Weapon"].count or 0) >= 5 then
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

    -- Execution time is at least 1 effective GCD
    local executionTime = math.max(effGCD, effCast)
    return executionTime, effCast
end

-- =====================================================================
-- CALCULATE TRUE EXPECTED SPELL DAMAGE
-- =====================================================================
function FC:CalculateExpectedDamage(action, state)
    state = state or FC.state
    local p = state.player or {}
    local t = state.target or {}
    local buffs = p.buffs or {}
    local tDebuffs = t.debuffs or {}
    local stats = p.stats or {}
    local spTable = stats.spellPower or {}
    local aName = action.spellName or action.name
    local school = action.school or "Physical"
    local enemyCount = state.enemyCount or 1

    local dbEntry = SPELL_DAMAGE_DATABASE[aName]
    local sp = spTable[school] or spTable.Max or 1500

    local rawDirect = 0
    local rawDoT = 0
    local dotDuration = 0

    if dbEntry then
        -- 1. Direct Damage Component
        if dbEntry.baseMax and dbEntry.baseMax > 0 then
            local avgBase = (dbEntry.baseMin + dbEntry.baseMax) / 2
            local coeff = dbEntry.directCoeff or 0
            rawDirect = avgBase + (sp * coeff)
        end

        -- 2. Attack Power scaling for hybrid/melee spells
        if dbEntry.apCoeff and stats.attackPower then
            rawDirect = rawDirect + (stats.attackPower * dbEntry.apCoeff)
        end

        -- 3. Weapon Damage scaling
        if dbEntry.weaponPct then
            local avgWeaponDmg = 1200 + (stats.attackPower or 2000) / 14 * 3.3
            rawDirect = avgWeaponDmg * dbEntry.weaponPct
        end

        -- 4. Periodic (DoT) Component
        if dbEntry.dotBase and dbEntry.dotBase > 0 then
            rawDoT = dbEntry.dotBase + (sp * (dbEntry.dotCoeff or 0))
            dotDuration = dbEntry.dotDuration or 12
        end

        -- 5. Living Bomb Explosion
        if dbEntry.explosionMax and dbEntry.explosionMax > 0 then
            local expDmg = dbEntry.explosionMin + (sp * (dbEntry.explosionCoeff or 0))
            -- Explosion hits target + other nearby enemies
            if enemyCount > 1 then
                expDmg = expDmg * (1.0 + (enemyCount - 1) * 0.85)
            end
            rawDirect = rawDirect + expDmg
        end

        -- 6. AoE Multi-Target Multiplier
        if dbEntry.isAoE and enemyCount > 1 then
            rawDirect = rawDirect * math.min(10, enemyCount * 0.90)
        end
    else
        -- Generic fallback formula: Base ~500 + CastTime/3.5 * SP
        local cTime = action.castTime or 1.5
        rawDirect = 500 + (sp * math.max(0.2, cTime / 3.5))
    end

    -- =================================================================
    -- TIME-TO-DEATH (TTD) DOT CLIPPING
    -- =================================================================
    if rawDoT > 0 and dotDuration > 0 then
        local ttd = t.ttd or 999
        if ttd < dotDuration then
            local frac = math.max(0.1, ttd / dotDuration)
            rawDoT = rawDoT * frac -- Scale down DoT if enemy will die before duration ends
        end
    end

    -- Total Base Raw Damage
    local totalRaw = rawDirect + rawDoT

    -- =================================================================
    -- MULTIPLIERS (Perks, Talents, Debuffs)
    -- =================================================================
    local mult = 1.0

    -- 1. Synastria Class Set Bonuses
    if FC.extState and FC.extState.activeClassSet == "Fire Mage" and (FC.extState.classSetCount or 5) >= 4 then
        if school == "Fire" then
            mult = mult * 2.25 -- +125% Fire Damage
        end
    elseif FC.extState and FC.extState.activeClassSet and FC.SYNASTRIA_CLASS_SETS[FC.extState.activeClassSet] then
        local setDef = FC.SYNASTRIA_CLASS_SETS[FC.extState.activeClassSet]
        if setDef.apply then
            local ok, newMult = pcall(setDef.apply, state, action, mult)
            if ok and newMult then mult = newMult end
        end
    end

    -- 2. Talents
    if FC.talents and FC.talents.known then
        if school == "Fire" and FC.talents.known["Fire Power"] then
            mult = mult * (1.0 + FC.talents.known["Fire Power"] * 0.02)
        end
        if FC.talents.known["Playing with Fire"] then
            mult = mult * (1.0 + FC.talents.known["Playing with Fire"] * 0.01)
        end
        if (t.healthPct or 100) < 35 and FC.talents.known["Molten Fury"] then
            mult = mult * (1.0 + FC.talents.known["Molten Fury"] * 0.06)
        end
        if FC.talents.known["Torment the Weak"] and (t.isSnared or t.isSlowed or tDebuffs["Slow"] or tDebuffs["Cone of Cold"]) then
            mult = mult * 1.12
        end
    end

    -- 3. Target Debuffs (+13% Magic Damage from CoE/Ebon Plague/Earth and Moon)
    if tDebuffs["Curse of the Elements"] or tDebuffs["Ebon Plague"] or tDebuffs["Earth and Moon"] then
        if school ~= "Physical" then mult = mult * 1.13 end
    end
    if tDebuffs["Blood Frenzy"] or tDebuffs["Savage Combat"] then
        if school == "Physical" then mult = mult * 1.04 end
    end

    -- 4. Active Procs & Shatter
    if aName == "Ice Lance" and (t.isFrozen or buffs["Fingers of Frost"]) then
        mult = mult * 3.0
    elseif aName == "Deep Freeze" and (t.isFrozen or buffs["Fingers of Frost"]) then
        mult = mult * 2.0
    end

    local modifiedDmg = totalRaw * mult

    -- =================================================================
    -- CRITICAL STRIKE EXPECTED VALUE
    -- Expected Dmg = Dmg * (1 + CritChance * (CritMult - 1))
    -- =================================================================
    local critChance = (stats.spellCrit or 25) / 100
    if school == "Physical" then critChance = (stats.meleeCrit or 20) / 100 end

    -- +5% crit from Scorch / Shadow and Flame / Winter's Chill
    if tDebuffs["Improved Scorch"] or tDebuffs["Shadow and Flame"] or tDebuffs["Winter's Chill"] then
        critChance = critChance + 0.05
    end
    -- Combustion / Arcane Potency / Shatter bonus crit
    if buffs["Combustion"] and school == "Fire" then critChance = critChance + 0.30 end
    if (t.isFrozen or buffs["Fingers of Frost"]) and (school == "Frost" or aName == "Frostfire Bolt") then
        critChance = critChance + 0.50 -- Shatter talent (+50% crit on frozen)
    end
    if aName == "Lava Burst" and (tDebuffs["Flame Shock"] or dbEntry and dbEntry.flameShockCrit) then
        critChance = 1.0 -- 100% crit
    end

    critChance = math.min(1.0, math.max(0.0, critChance))
    local critMultiplier = 2.0 -- 200% crit damage for casters with damage talents (Spell Power / Ruin / Ice Shards)
    if school == "Physical" then critMultiplier = 2.0 end

    local expectedDmg = modifiedDmg * (1.0 + critChance * (critMultiplier - 1.0))

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
    if cost <= 0 then return expDmg end -- Free spells have infinite/max DPM
    local dpm = expDmg / cost
    return dpm, expDmg, cost
end
