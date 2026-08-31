FlowCore = FlowCore or {}
local FC = FlowCore

FC.combat = FC.combat or {}
FC.combat.lastEvents = FC.combat.lastEvents or {}
FC.combat.procs = FC.combat.procs or {}
FC.combat.damageTakenHistory = FC.combat.damageTakenHistory or {}
FC.combat.damageDoneHistory = FC.combat.damageDoneHistory or {}
FC.combat.activeHostileGUIDs = FC.combat.activeHostileGUIDs or {}
FC.combat.resistances = FC.combat.resistances or {}
FC.combatSession = FC.combatSession or {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

local lastTrigger = 0
local ENGINE_THROTTLE = 0.05

local function TriggerEngine()
    if not FC.MarkEngineDirty then return end
    local now = GetTime()
    if (now - lastTrigger) < ENGINE_THROTTLE then return end
    lastTrigger = now
    FC:MarkEngineDirty()
end

-- Spell School Map (WotLK Standard School Bitmasks / Names)
local SCHOOL_NAMES = {
    [1]  = "Physical",
    [2]  = "Holy",
    [4]  = "Fire",
    [8]  = "Nature",
    [16] = "Frost",
    [32] = "Shadow",
    [64] = "Arcane"
}

-- Bitmask constants for WotLK Combat Log Filters
local REACTION_HOSTILE = 0x00000040
local REACTION_FRIENDLY = 0x00000010
local AFFILIATION_MINE = 0x00000001
local AFFILIATION_PARTY = 0x00000002
local AFFILIATION_RAID = 0x00000004
local TYPE_NPC = 0x00000800
local TYPE_PET = 0x00001000

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat session
        FC.combatSession = {
            inCombat = true,
            startTime = GetTime(),
            actionsCast = 0,
            optimalActions = 0,
            earlyClips = 0
        }
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Dropped combat session: generate performance summary (Phase 6)
        FC.combat.activeHostileGUIDs = {}
        if FC.combatSession and FC.combatSession.inCombat then
            local dur = GetTime() - (FC.combatSession.startTime or GetTime())
            FC.combatSession.inCombat = false
            FC.combatSession.duration = dur

            if dur >= 6.0 and (FC.combatSession.actionsCast or 0) >= 3 then
                local total = FC.combatSession.actionsCast or 1
                local opt = FC.combatSession.optimalActions or 0
                local score = (opt / total) * 100

                local report = {
                    duration = dur,
                    total = total,
                    optimal = opt,
                    score = score,
                    earlyClips = FC.combatSession.earlyClips or 0
                }
                FC.combatSession.lastReport = report

                if FC.db and FC.db.showCombatReport ~= false then
                    FC:Print(string.format("=== COMBAT PERFORMANCE: |cffffd700%.1f%% Optimal|r (%.0fs fight) ===", score, dur))
                    FC:Print(string.format("  Actions: |cff55ff55%d/%d|r Recommended | Early DoT Clips: |cffff8800%d|r", opt, total, report.earlyClips))
                end
            end
        end
        TriggerEngine()
        return
    end

    local timestamp, eventType,
          sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags = ...

    if not eventType then return end

    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    local targetGUID = UnitGUID("target")
    local now = GetTime()

    -- 3.3.5a CLEU Extended Parameters (Starts at argument 11 in WotLK)
    local spellId, spellName, spellSchool,
          amount, overkill, school, resisted,
          blocked, absorbed, critical =
          select(11, ...)

    -- Event History Ring Buffer
    table.insert(FC.combat.lastEvents, {
        time = now,
        event = eventType,
        spell = spellName or "unknown",
        id = spellId or 0,
        source = sourceGUID,
        target = destGUID,
        amount = amount or 0
    })
    if #FC.combat.lastEvents > 30 then
        table.remove(FC.combat.lastEvents, 1)
    end

    -- =====================================================
    -- COMPREHENSIVE ACTIVE HOSTILE ENEMY TRACKING
    -- =====================================================
    local sFlags = tonumber(sourceFlags) or 0
    local dFlags = tonumber(destFlags) or 0

    local isSourceHostile = (bit.band(sFlags, REACTION_HOSTILE) > 0)
    local isDestHostile = (bit.band(dFlags, REACTION_HOSTILE) > 0)
    local isSourceMine = (sourceGUID == playerGUID or (petGUID and sourceGUID == petGUID) or bit.band(sFlags, AFFILIATION_MINE + AFFILIATION_PARTY + AFFILIATION_RAID) > 0)
    local isDestMine = (destGUID == playerGUID or (petGUID and destGUID == petGUID) or bit.band(dFlags, AFFILIATION_MINE + AFFILIATION_PARTY + AFFILIATION_RAID) > 0)

    -- 1. Enemy attacks player, pet, or party/raid
    if isDestMine and sourceGUID and sourceGUID ~= playerGUID and sourceGUID ~= petGUID then
        if isSourceHostile or bit.band(sFlags, TYPE_NPC) > 0 then
            FC.combat.activeHostileGUIDs[sourceGUID] = now
        end
    end

    -- 2. Player, pet, or party/raid attacks enemy
    if isSourceMine and destGUID and destGUID ~= playerGUID and destGUID ~= petGUID then
        if isDestHostile or bit.band(dFlags, TYPE_NPC) > 0 then
            FC.combat.activeHostileGUIDs[destGUID] = now
        end
    end

    -- 3. Hostile unit casts a spell, buffs, or performs an action in combat
    if isSourceHostile and sourceGUID and sourceGUID ~= playerGUID and sourceGUID ~= petGUID then
        if eventType == "SPELL_CAST_START" or eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED" or eventType == "SWING_DAMAGE" or eventType == "SWING_MISSED" then
            FC.combat.activeHostileGUIDs[sourceGUID] = now
        end
    end

    -- 4. Unit Death Cleanup
    if eventType == "UNIT_DIED" or eventType == "UNIT_DESTROYED" then
        if destGUID and FC.combat.activeHostileGUIDs[destGUID] then
            FC.combat.activeHostileGUIDs[destGUID] = nil
        end
        TriggerEngine()
        return
    end

    -- =====================================================
    -- INCOMING & OUTGOING DAMAGE TRACKING
    -- =====================================================
    local isDamageEvent = (eventType == "SWING_DAMAGE" or
                          eventType == "SPELL_DAMAGE" or
                          eventType == "SPELL_PERIODIC_DAMAGE" or
                          eventType == "RANGE_DAMAGE" or
                          eventType == "ENVIRONMENTAL_DAMAGE")

    if isDamageEvent then
        local dmg = tonumber(amount) or 0

        -- 1. Incoming Damage to Player (for DTPS & Survivability)
        if destGUID == playerGUID and dmg > 0 then
            table.insert(FC.combat.damageTakenHistory, {
                time = now,
                amount = dmg
            })
        end

        -- 2. Outgoing Damage from Player (for DPS & Target TTD)
        if sourceGUID == playerGUID and dmg > 0 then
            table.insert(FC.combat.damageDoneHistory, {
                time = now,
                amount = dmg
            })
        end
    end

    -- =====================================================
    -- RESISTANCE & IMMUNITY TRACKING (CLEU MISSED & DAMAGE)
    -- =====================================================
    if sourceGUID == playerGUID and destGUID then
        local targetRes = FC.combat.resistances[destGUID] or {}
        local schoolKey = spellSchool and SCHOOL_NAMES[spellSchool] or nil

        if eventType == "SPELL_MISSED" then
            local missType = amount -- In SPELL_MISSED, arg 15 (amount) is missType (e.g. "IMMUNE", "RESIST")
            if missType == "IMMUNE" and schoolKey then
                targetRes[schoolKey] = "IMMUNE"
                FC:Verbose("Target " .. tostring(destName) .. " is IMMUNE to " .. schoolKey)
            elseif missType == "RESIST" and schoolKey then
                targetRes[schoolKey] = "RESIST"
            end
        end

        if eventType == "SPELL_DAMAGE" and resisted and tonumber(resisted) and tonumber(resisted) > 0 and schoolKey then
            local dmg = tonumber(amount) or 1
            local res = tonumber(resisted)
            if res >= dmg then
                targetRes[schoolKey] = "HIGH_RESIST"
            end
        end

        FC.combat.resistances[destGUID] = targetRes
        if destGUID == targetGUID then
            FC.state.target.resistances = targetRes
        end
    end

    -- =====================================================
    -- MELEE SWING DAMAGE
    -- =====================================================
    if eventType == "SWING_DAMAGE" then
        local dmg = tonumber(amount) or 0
        local abs = tonumber(absorbed) or 0
        local crit = (critical == 1)
        local final = math.max(dmg - abs, 0)

        if FC.EmitSwingSignal then
            FC:EmitSwingSignal({
                final = final,
                crit = crit,
                source = sourceGUID,
                target = destGUID,
                absorbed = abs
            })
        end
        TriggerEngine()
    end

    -- =====================================================
    -- SPELL DAMAGE & EMPIRICAL SELF-LEARNING CALIBRATION
    -- =====================================================
    if eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" or eventType == "RANGE_DAMAGE" then
        local finalAmount = tonumber(amount) or 0

        -- 1. Empirical Self-Learning Combat Log Feedback Loop (Step 1)
        if sourceGUID == playerGUID and spellName and finalAmount > 0 then
            FC.empiricalSamples = FC.empiricalSamples or {}
            local s = FC.empiricalSamples[spellName]
            if not s then
                s = { hits = 0, crits = 0, sumNonCrit = 0, sumCrit = 0, avgNonCrit = 0, avgCrit = 0, minHit = 999999, maxHit = 0, lastSeen = 0, isPeriodic = (eventType == "SPELL_PERIODIC_DAMAGE") }
                FC.empiricalSamples[spellName] = s
            end
            s.hits = s.hits + 1
            s.lastSeen = now
            local isCrit = (critical == 1 or critical == true)
            if isCrit then
                s.crits = s.crits + 1
                s.sumCrit = s.sumCrit + finalAmount
                s.avgCrit = s.sumCrit / s.crits
            else
                s.sumNonCrit = s.sumNonCrit + finalAmount
                local nonCritCount = math.max(1, s.hits - s.crits)
                s.avgNonCrit = s.sumNonCrit / nonCritCount
            end
            if finalAmount < s.minHit then s.minHit = finalAmount end
            if finalAmount > s.maxHit then s.maxHit = finalAmount end
        end

        if FC.EmitSpellSignal then
            FC:EmitSpellSignal({
                spell = spellName,
                amount = finalAmount,
                final = finalAmount,
                source = sourceGUID,
                target = destGUID
            })
        end
        TriggerEngine()
    end

    -- =====================================================
    -- SPELL CAST SUCCESS (Player GCD, Cooldown Clock & Projectiles)
    -- =====================================================
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == playerGUID then
            FC._gcdStart = now

            -- Track Session Actions for Performance Score (Phase 6)
            if FC.combatSession and FC.combatSession.inCombat and spellName then
                FC.combatSession.actionsCast = (FC.combatSession.actionsCast or 0) + 1
                local hero = FC.timeline and FC.timeline.queue and FC.timeline.queue[1]
                if hero and (hero.name == spellName or hero.spellName == spellName or string.find(hero.name or "", spellName, 1, true)) then
                    FC.combatSession.optimalActions = (FC.combatSession.optimalActions or 0) + 1
                end
            end

            -- Projectile Flight Time Tracker (Step 3)
            local PROJECTILE_SPELLS = {
                ["Fireball"] = true, ["Frostfire Bolt"] = true, ["Pyroblast"] = true,
                ["Frostbolt"] = true, ["Arcane Missiles"] = true, ["Arcane Barrage"] = true,
                ["Lava Burst"] = true, ["Lightning Bolt"] = true, ["Shadow Bolt"] = true,
                ["Chaos Bolt"] = true, ["Soul Fire"] = true, ["Shoot"] = true
            }
            if PROJECTILE_SPELLS[spellName] then
                FC.inFlightProjectiles = FC.inFlightProjectiles or {}
                -- Default flight distance 25 yards / 24 yd/s flight speed = ~1.04s
                local flightTime = 1.05
                table.insert(FC.inFlightProjectiles, {
                    spell = spellName,
                    firedAt = now,
                    landsAt = now + flightTime,
                    crit = (FC.state and FC.state.player and FC.state.player.stats and FC.state.player.stats.spellCrit) or 25
                })
                -- Prune old in-flight projectiles
                while #FC.inFlightProjectiles > 6 do
                    table.remove(FC.inFlightProjectiles, 1)
                end
            end

            if spellName == "Flamestrike" then
                if spellId == 42925 then
                    FC.state.flamestrike_r8_expiry = now + 8.0
                elseif spellId == 27086 then
                    FC.state.flamestrike_r7_expiry = now + 8.0
                else
                    FC.state.flamestrike_r9_expiry = now + 8.0
                end
            end
            if FC.TrackSpellCast and spellName then
                FC:TrackSpellCast(spellName)
            end
        end
        TriggerEngine()
    end

    -- =====================================================
    -- PROCS & AURA TRACKING
    -- =====================================================
    if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") and destGUID == playerGUID then
        local sName = spellName or "unknown"
        FC.combat.procs[sName] = {
            active = true,
            time = now,
            spellId = spellId
        }

        -- Track Trinket / Equipment Proc ICD (Phase 3)
        if FC.TRINKET_ICDS and FC.TRINKET_ICDS[sName] then
            local tDef = FC.TRINKET_ICDS[sName]
            FC.combat.procICDs[sName] = {
                triggeredAt = now,
                expiresAt = now + (tDef.duration or 15),
                readyAt = now + (tDef.icd or 45)
            }
        end

        if FC.EmitProcSignal then
            FC:EmitProcSignal(sName)
        end
        TriggerEngine()
    end

    if eventType == "SPELL_AURA_REMOVED" and destGUID == playerGUID then
        local sName = spellName or "unknown"
        if FC.combat.procs[sName] then
            FC.combat.procs[sName].active = false
        end
        TriggerEngine()
    end

    -- =====================================================
    -- MULTI-TARGET OUTGOING DOT TRACKER (Phase 2)
    -- =====================================================
    FC.combat.multiTargetDots = FC.combat.multiTargetDots or {}
    local DOT_DURATIONS = {
        ["Living Bomb"] = 12,
        ["Shadow Word: Pain"] = 18,
        ["Vampiric Touch"] = 15,
        ["Devouring Plague"] = 24,
        ["Corruption"] = 18,
        ["Unstable Affliction"] = 15,
        ["Curse of Agony"] = 24,
        ["Curse of Doom"] = 60,
        ["Immolate"] = 15,
        ["Moonfire"] = 12,
        ["Insect Swarm"] = 12,
        ["Flame Shock"] = 18,
        ["Rake"] = 9,
        ["Rip"] = 12,
        ["Rupture"] = 16,
        ["Lacerate"] = 15,
        ["Rend"] = 15,
        ["Serpent Sting"] = 15,
        ["Frost Fever"] = 15,
        ["Blood Plague"] = 15
    }

    if sourceGUID == playerGUID and spellName and DOT_DURATIONS[spellName] and destGUID then
        local dotDur = DOT_DURATIONS[spellName] or 12
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            FC.combat.multiTargetDots[spellName] = FC.combat.multiTargetDots[spellName] or {}
            FC.combat.multiTargetDots[spellName][destGUID] = {
                destGUID = destGUID,
                destName = destName or "Unknown Enemy",
                appliedAt = now,
                expiresAt = now + dotDur,
                duration = dotDur
            }
            TriggerEngine()
        elseif eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_BROKEN" then
            if FC.combat.multiTargetDots[spellName] then
                FC.combat.multiTargetDots[spellName][destGUID] = nil
            end
            TriggerEngine()
        end
    end

    -- Cleanup Dead Targets from Multi-Target DoT Tracker
    if (eventType == "UNIT_DIED" or eventType == "PARTY_KILL" or eventType == "SPELL_INSTAKILL") and destGUID then
        if FC.combat.multiTargetDots then
            for dotName, targets in pairs(FC.combat.multiTargetDots) do
                targets[destGUID] = nil
            end
        end
        TriggerEngine()
    end
end)
