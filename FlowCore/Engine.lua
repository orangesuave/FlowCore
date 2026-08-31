FlowCore = FlowCore or {}
local FC = FlowCore

FC._lastDecisionTime = FC._lastDecisionTime or 0
FC._lastAction = FC._lastAction or nil
FC._lastScore = FC._lastScore or nil

function FC:EvaluateActionScore(action, state)
    state = state or FC.state
    local score = action.priority or 0
    local reasons = {}
    local expDmg = 0
    local execTime = action.castTime or 1.5
    local dpct = 0

    -- 1. DPCT & Expected Damage Foundation
    if FC.CalculateDPCT and (action.role == "nuke" or action.role == "dot" or action.role == "aoe" or action.role == "spender" or action.role == "builder" or action.role == "execute") then
        local okDpct, cDpct, cExpDmg, cExecTime = pcall(FC.CalculateDPCT, FC, action, state)
        if okDpct and cDpct then
            dpct = cDpct
            expDmg = cExpDmg or 0
            execTime = cExecTime or execTime
            score = score + (dpct * 0.02)
        end

        local p = state.player or {}
        local t = state.target or {}
        if (p.powerPct or 100) < 30 and (t.ttd or 999) > 12 and FC.CalculateDPM then
            local okDpm, dpm = pcall(FC.CalculateDPM, FC, action, state)
            if okDpm and dpm then
                score = score + math.min(30, dpm * 0.5)
            end
        end
    end

    -- Custom Action Score
    if action.score then
        local success, result = pcall(action.score, state)
        if success and result then
            score = score + result
        end
    end

    -- 2. Active Tanking, Mitigation & Situational Intelligence Boosts
    local danger = state.dangerLevel or 0
    local enemyCount = state.enemyCount or 1
    local pBuffs = (state.player and state.player.buffs) or {}
    local pHp = (state.player and state.player.healthPct) or 100

    if action.role == "interrupt" and state.target and (state.target.isCasting or state.target.isChanneling) and state.target.interruptible then
        score = score + 140
        table.insert(reasons, "|cffff3333Interrupt Active Cast (+140)|r")
    end

    if action.role == "dispel" then
        if state.target and state.target.hasStealableBuff then
            score = score + 65
            table.insert(reasons, "|cff33ffccStealable Buff (+65)|r")
        elseif state.player and (state.player.hasCurse or state.player.hasPoison or state.player.hasDisease) then
            score = score + 50
            table.insert(reasons, "|cff33ffccCleanse Debuff (+50)|r")
        end
    end

    -- Active Tanking Shield Upkeep & Mitigation Priority
    if action.name == "Ice Barrier" or action.name == "Sacred Shield" or action.name == "Power Word: Shield" or action.name == "Bone Shield" or action.name == "Holy Shield" then
        if not pBuffs[action.name] or (pBuffs[action.name].remaining or 0) <= 1.0 then
            score = score + 95
            table.insert(reasons, "|cff55ff55Active Tanking Shield Upkeep (+95)|r")
        end
    end

    -- Active Tanking Armor Maintenance (Mage Armor, Frost Armor, Inner Fire, Demon Armor)
    if action.name == "Mage Armor" or action.name == "Frost Armor" or action.name == "Ice Armor" or action.name == "Molten Armor" or action.name == "Inner Fire" or action.name == "Demon Armor" or action.name == "Fel Armor" then
        local hasArmor = pBuffs["Mage Armor"] or pBuffs["Frost Armor"] or pBuffs["Ice Armor"] or pBuffs["Molten Armor"] or pBuffs["Inner Fire"] or pBuffs["Demon Armor"] or pBuffs["Fel Armor"]
        if not hasArmor then
            score = score + 100
            table.insert(reasons, "|cff55ff55Active Armor Buff Missing (+100)|r")
        end
    end

    -- Emergency Defensive & Self Healing
    if action.role == "defensive" or action.role == "heal" then
        if state.phase == "emergency" or danger >= 75 or pHp <= 35 then
            score = score + 120 + (danger * 1.5)
            table.insert(reasons, "|cffff2222Emergency Defensive (+120)|r")
        elseif danger >= 40 or pHp <= 65 then
            score = score + 45 + (danger * 0.8)
            table.insert(reasons, "|cffffaa00Active Tanking Mitigation (+45)|r")
        end
    end

    -- Evocation Emergency Self-Heal (with Glyph of Evocation)
    if action.name == "Evocation" then
        local hasEvoGlyph = (FC.extState and FC.extState.activeGlyphs and FC.extState.activeGlyphs["Glyph of Evocation"])
        if hasEvoGlyph and pHp <= 45 then
            score = score + 110
            table.insert(reasons, "|cff55ff55Evocation 60% Self-Heal (+110)|r")
        end
    end

    if action.role == "execute" and (state.phase == "execute" or (state.target and (state.target.healthPct or 100) <= 20)) then
        score = score + 60
        table.insert(reasons, "|cffff5522Execute Phase (+60)|r")
    end

    if action.role == "aoe" then
        if enemyCount >= 3 then
            score = score + 40 + (enemyCount * 8)
            table.insert(reasons, string.format("|cffffff33AoE Multi-Target (%d mobs)|r", enemyCount))
        elseif enemyCount == 2 then
            score = score + 20
            table.insert(reasons, "|cffffff33AoE 2 Targets (+20)|r")
        end
    end

    -- 3. Combat Approach & Focus Engine
    local approach = (FC.db and FC.db.combatApproach) or "Balanced"
    if approach == "ST Damage" then
        if action.role == "nuke" or action.role == "builder" or action.role == "spender" or action.role == "execute" then
            score = score * 1.30
        elseif action.role == "aoe" and enemyCount < 4 then
            score = score * 0.40
        end
    elseif approach == "AOE Damage" then
        if action.role == "aoe" or action.isAoE or string.find(action.name or "", "Flamestrike") or string.find(action.name or "", "Blizzard") or string.find(action.name or "", "Whirlwind") or string.find(action.name or "", "Living Bomb") then
            score = score * 1.45 + (enemyCount * 12)
        end
    elseif approach == "Survival/PVP" then
        if action.role == "defensive" or action.role == "heal" or action.isShield or string.find(action.name or "", "Barrier") or string.find(action.name or "", "Ward") or string.find(action.name or "", "Shield") then
            score = score * 1.60 + 35
        end
        if danger >= 25 or pHp <= 75 then
            if action.role == "defensive" or action.isShield then
                score = score + 45
            end
        end
    elseif approach == "Balanced" then
        -- Tri-Pillar: Damage, Speed & Resource Sustain
        local pPower = (state.player and state.player.powerPct) or 100
        if pPower < 35 then
            if action.name == "Evocation" or action.name == "Life Tap" or action.name == "Mana Gem" or action.name == "Innervate" or action.name == "Bloodrage" or action.name == "Tiger's Fury" or action.name == "Aspect of the Viper" then
                score = score + 85
                table.insert(reasons, "|cff00ffccBalanced Resource Sustain (+85)|r")
            end
        end
    end

    if (state.phase == "opener" or state.phase == "ready") and state.target and state.target.exists and state.target.hostile then
        if action.role == "opener" or action.role == "nuke" or action.role == "builder" then
            score = score + 40
        end
    end

    if (action.role == "cooldown" or action.role == "trinket") and state.engaged then
        if state.target and state.target.isBoss then
            score = score + 35
            table.insert(reasons, "|cffffd700Boss Burst Cooldown (+35)|r")
        end
    end

    if action.role == "buff" and state.inCombat then
        local isArmorBuff = (action.name == "Mage Armor" or action.name == "Frost Armor" or action.name == "Ice Armor" or action.name == "Molten Armor" or action.name == "Inner Fire" or action.name == "Demon Armor" or action.name == "Fel Armor")
        if not isArmorBuff then
            score = score - 20
        end
    end

    -- 3. Prediction & Procs Layer
    if FC.ApplyPredictionScore then
        local success, result = pcall(FC.ApplyPredictionScore, FC, action, state, score)
        if success and result then
            score = result
        end
    end

    -- 4. Synastria / WoWExt Scoring Hook
    if FC.ApplyExtStateScore then
        local success, result = pcall(FC.ApplyExtStateScore, FC, action, state, score)
        if success and result then
            score = result
        end
    end

    -- 5. Readiness Check
    if not FC.simulationActive and FC.GetActionReadiness and action.role ~= "fallback" and action.role ~= "idle" then
        local success, readiness = pcall(FC.GetActionReadiness, FC, action)
        if success and readiness then
            score = score + (readiness - 100) * 0.05
        end
    end

    return score, dpct, expDmg, execTime, reasons
end

function FC:GetBestAction(state)
    state = state or FC.state

    local now = GetTime()

    -- Stability lock (avoid recalculating multiple times within 100ms)
    if not FC.simulationActive and FC._lastAction and (now - (FC._lastDecisionTime or 0) < 0.10) then
        return FC._lastAction, FC._lastScore
    end

    local bestAction = nil
    local bestScore = -99999

    for _, action in ipairs(FC.actions or {}) do
        local ok = true
        if action.conditions then
            local success, result = pcall(action.conditions, state)
            ok = success and result
        end

        if ok then
            local score = FC:EvaluateActionScore(action, state)
            if score > bestScore then
                bestScore = score
                bestAction = action
            end
        end
    end

    -- =====================================================
    -- FALLBACK SAFETY
    -- =====================================================
    if not bestAction then
        for _, action in ipairs(FC.actions or {}) do
            if action.role == "fallback" then
                bestAction = action
                bestScore = -10000
                break
            end
        end
    end

    FC._lastAction = bestAction
    FC._lastScore = bestScore
    FC._lastDecisionTime = now

    return bestAction, bestScore
end