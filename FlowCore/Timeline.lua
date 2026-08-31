FlowCore = FlowCore or {}
local FC = FlowCore

FC.timeline = FC.timeline or { queue = {}, builtAt = 0 }

-- =========================================================
-- READINESS SCORE (Real-time at t = 0)
-- =========================================================
function FC:GetActionReadiness(action)
    if not action or not action.name then return 100 end

    local score = 100

    if action.actionType == "spell" and action.spellName then
        if not self:IsNativeSpellReady(action.spellName) then
            local t = self:GetNativeTimeUntilReady(action.spellName)
            score = score - (t * 35)
        end
    elseif action.actionType == "item" then
        local cd = 0
        if action.slotId then
            cd = self:GetInventorySlotCooldownRemaining(action.slotId)
        elseif action.itemId then
            cd = self:GetItemCooldownRemaining(action.itemId)
        end
        if cd > 0 then
            score = score - (cd * 35)
        end
    end

    -- GCD penalty
    if not self:IsGCDReady() then
        score = score * 0.25
    end

    return score
end

-- =====================================================================
-- BUILD PREDICTIVE 10-SECOND TIMELINE
-- Guarantees strictly ordered, non-overlapping future timeline slots
-- Integrates:
--  1. Historical context & active DoT debuff tracking
--  2. Debuff uptime maintenance & reapplication (Pandemic refresh window)
--  3. Survivability & imminent death prevention
--  4. Target Time-To-Die (TTD) & DPS loss prevention
--  5. Dynamic resource & power regeneration (Mana, Energy, Rage, Focus)
-- =====================================================================
function FC:BuildTimeline(duration)
    duration = duration or (self.db and self.db.timelineDuration) or 10

    local state = FC.state or {}
    local queue = {}
    local baseGCD = (FC.GetEffectiveGCD and FC:GetEffectiveGCD()) or 1.5
    local now = GetTime()

    -- 1. Snapshot Initial Readiness for Cooldowns & Spells
    local readyAt = {}
    for _, action in ipairs(FC.actions or {}) do
        if action.role ~= "fallback" and action.role ~= "idle" then
            local remaining = 0
            if action.actionType == "spell" and action.spellName then
                if not FC.simulationActive then
                    remaining = self:GetNativeTimeUntilReady(action.spellName)
                end
            elseif action.actionType == "item" then
                if not FC.simulationActive then
                    if action.slotId then
                        remaining = self:GetInventorySlotCooldownRemaining(action.slotId)
                    elseif action.itemId then
                        remaining = self:GetItemCooldownRemaining(action.itemId)
                    end
                end
            end
            readyAt[action.name] = remaining
        end
    end

    -- 2. Snapshot Initial Target Debuffs (DoTs & Vulnerabilities)
    local simDebuffs = {}
    if state.target and state.target.debuffs then
        for name, debuff in pairs(state.target.debuffs) do
            if debuff.mine or debuff.remaining then
                simDebuffs[name] = debuff.remaining or 0
            end
        end
    end

    -- 3. Snapshot Initial Player Buffs
    local simBuffs = {}
    if state.player and state.player.buffs then
        for name, buff in pairs(state.player.buffs) do
            simBuffs[name] = buff.remaining or 0
        end
    end

    -- 4. Snapshot Initial Ground Auras (Flamestrike R9, R8, etc.)
    local simGroundAuras = {
        Flamestrike_R9 = math.max(0, ((state.flamestrike_r9_expiry or 0) - now)),
        Flamestrike_R8 = math.max(0, ((state.flamestrike_r8_expiry or 0) - now))
    }

    -- 5. Snapshot Initial Resources & Vitals
    local p = state.player or {}
    local t = state.target or {}
    local simPower = p.power or 10000
    local simPowerMax = math.max(1, p.powerMax or 10000)
    local simPowerType = p.powerType or 0
    local simPlayerHealth = p.health or 10000
    local simPlayerHealthMax = math.max(1, p.healthMax or 10000)
    local simTargetHealth = t.health or 500000
    local simTargetHealthMax = math.max(1, t.healthMax or 500000)
    local simTargetTTD = t.ttd or 999
    local dtps = state.dtps or 0
    local dps = math.max(500, state.dps or 2500)

    local simTime = 0
    if not FC.simulationActive and self.GetGCDRemaining then
        simTime = self:GetGCDRemaining()
    end

    local lastSimTime = 0
    local MAX_SLOTS = 8
    local iterations = 0
    local MAX_ITERATIONS = 25

    while simTime < (duration + 2.0) and #queue < MAX_SLOTS and iterations < MAX_ITERATIONS do
        iterations = iterations + 1
        local timeDelta = math.max(0, simTime - lastSimTime)
        lastSimTime = simTime

        -- -------------------------------------------------------------
        -- DYNAMIC RESOURCE REGENERATION ALONG TIMELINE
        -- -------------------------------------------------------------
        if simPowerType == 0 then
            -- Mana: Passive combat regen (~1.5% max mana per second)
            simPower = math.min(simPowerMax, simPower + (simPowerMax * 0.015 * timeDelta))
        elseif simPowerType == 3 then
            -- Energy: 10 per second
            simPower = math.min(simPowerMax, simPower + (10.0 * timeDelta))
        elseif simPowerType == 1 then
            -- Rage: Passive swing income in combat (~3 rage per second)
            simPower = math.min(simPowerMax, simPower + (3.0 * timeDelta))
        elseif simPowerType == 2 then
            -- Focus: 5 per second
            simPower = math.min(simPowerMax, simPower + (5.0 * timeDelta))
        end

        -- -------------------------------------------------------------
        -- DYNAMIC TARGET TTD & HEALTH PROJECTION
        -- -------------------------------------------------------------
        simTargetHealth = math.max(0, simTargetHealth - (dps * timeDelta))
        local targetHpPct = (simTargetHealth / simTargetHealthMax) * 100
        local targetRemLife = math.max(0, simTargetTTD - simTime)

        -- -------------------------------------------------------------
        -- DYNAMIC PLAYER HEALTH & DANGER PROJECTION
        -- -------------------------------------------------------------
        if dtps > 0 then
            simPlayerHealth = math.max(1, simPlayerHealth - (dtps * timeDelta))
        end
        local playerHpPct = (simPlayerHealth / simPlayerHealthMax) * 100
        local simDanger = 0
        if playerHpPct < 25 then
            simDanger = 85 + (25 - playerHpPct) * 0.6
        elseif playerHpPct < 50 then
            simDanger = 50 + (50 - playerHpPct) * 1.4
        elseif playerHpPct < 75 then
            simDanger = 20 + (75 - playerHpPct) * 1.2
        end
        if dtps > (simPlayerHealthMax * 0.25) then
            simDanger = simDanger + 20
        end
        simDanger = math.min(100, math.max(0, simDanger))

        -- -------------------------------------------------------------
        -- BUILD SIMULATED STATE SNAPSHOT
        -- -------------------------------------------------------------
        local simState = {
            inCombat = state.inCombat,
            engaged = state.engaged,
            dangerLevel = simDanger,
            dtps = dtps,
            dps = dps,
            enemyCount = state.enemyCount or 1,
            flamestrike_r9_expiry = now + simTime + (simGroundAuras.Flamestrike_R9 > simTime and (simGroundAuras.Flamestrike_R9 - simTime) or 0),
            flamestrike_r8_expiry = now + simTime + (simGroundAuras.Flamestrike_R8 > simTime and (simGroundAuras.Flamestrike_R8 - simTime) or 0),
            phase = (simDanger >= 65) and "emergency" or (targetHpPct <= 20 and "execute" or "combat"),
            player = {
                health = simPlayerHealth,
                healthMax = simPlayerHealthMax,
                healthPct = playerHpPct,
                power = simPower,
                powerMax = simPowerMax,
                powerPct = (simPower / simPowerMax) * 100,
                powerType = simPowerType,
                buffs = {},
                debuffs = state.player and state.player.debuffs or {},
                stats = state.player and state.player.stats or {},
                comboPoints = state.player and state.player.comboPoints or 0
            },
            target = {
                exists = (t.exists ~= false) and (simTargetHealth > 0),
                hostile = t.hostile,
                dead = (simTargetHealth <= 0),
                health = simTargetHealth,
                healthMax = simTargetHealthMax,
                healthPct = targetHpPct,
                ttd = targetRemLife,
                isBoss = t.isBoss,
                classification = t.classification,
                creatureType = t.creatureType,
                isUndead = t.isUndead,
                isDemon = t.isDemon,
                isFrozen = t.isFrozen,
                isCrowdControlled = t.isCrowdControlled,
                resistances = t.resistances or {},
                debuffs = {},
                buffs = {}
            }
        }

        for bName, bRem in pairs(simBuffs) do
            local rem = bRem - simTime
            if rem > 0 then
                simState.player.buffs[bName] = { remaining = rem, duration = 300 }
            end
        end

        for dName, dRem in pairs(simDebuffs) do
            local rem = dRem - simTime
            if rem > 0 then
                simState.target.debuffs[dName] = { remaining = rem, duration = 18, mine = true }
            end
        end

        -- -------------------------------------------------------------
        -- EVALUATE CANDIDATE ACTIONS
        -- -------------------------------------------------------------
        local bestAction, bestValue = nil, -math.huge

        for _, action in ipairs(FC.actions or {}) do
            if action.role ~= "fallback" and action.role ~= "idle" then
                local nextReady = readyAt[action.name] or 0

                if nextReady <= (simTime + 0.05) then
                    local passesStatic = true

                    -- A. Power / Resource Check
                    local cost = action.powerCost or 0
                    if cost > 0 and simPower < cost then
                        passesStatic = false -- Player doesn't have enough mana/energy/rage right now
                    end

                    -- B. DoT Debuff Uptime & Safety Maintenance Checks
                    if passesStatic and action.role == "dot" and action.spellName then
                        local activeRem = (simDebuffs[action.spellName] or 0) - simTime
                        if activeRem > 2.0 then
                            passesStatic = false -- DoT is still ticking strong; do not clip early!
                        else
                            -- 1. Survivability Check: Do not cast DoT if player is dying (Defensive/Heal required)
                            if simDanger >= 65 or playerHpPct < 30 then
                                passesStatic = false
                            end
                            -- 2. Target TTD / DPS Loss Check: Do not cast DoT if target will die before it delivers value
                            local minTtdRequired = math.min(6.0, (action.dotDuration or 12) * 0.40)
                            if targetRemLife < minTtdRequired then
                                passesStatic = false
                            end
                        end
                    end

                    -- C. Self-Buff Uptime Check
                    if passesStatic and action.role == "buff" and action.spellName then
                        local activeRem = (simBuffs[action.spellName] or 0) - simTime
                        if activeRem > 6.0 then
                            passesStatic = false
                        end
                    end

                    -- D. Static Conditions evaluated against simulated state
                    if passesStatic and action.staticConditions then
                        local ok, result = pcall(action.staticConditions, simState)
                        passesStatic = ok and result
                    end

                    -- E. Estimate Future Value
                    if passesStatic then
                        local val = action.priority or 0
                        if self.EstimateFutureValue then
                            local ok, res = pcall(self.EstimateFutureValue, self, action, simState, simTime)
                            if ok and res then val = res end
                        end

                        if val > bestValue then
                            bestValue = val
                            bestAction = action
                        end
                    end
                end
            end
        end

        if not bestAction then
            -- Advance simulation clock to next available cooldown or energy tick
            simTime = simTime + 0.5
        else
            -- Record entry in timeline queue
            table.insert(queue, {
                name = bestAction.name,
                icon = bestAction.icon,
                role = bestAction.role,
                spellId = bestAction.spellId,
                itemId = bestAction.itemId,
                time = simTime,
                castTime = bestAction.castTime or 0,
                actionType = bestAction.actionType
            })

            -- Determine effective execution time (accounting for haste & procs)
            local step = baseGCD
            if FC.CalculateExecutionTime then
                local okExec, execTime, effCast = pcall(FC.CalculateExecutionTime, FC, bestAction, simState)
                if okExec and execTime then
                    step = execTime
                end
            else
                local effectiveCast = bestAction.castTime or 0
                if bestAction.name == "Pyroblast" and simBuffs["Hot Streak"] then
                    effectiveCast = 0
                    simBuffs["Hot Streak"] = nil
                end
                step = math.max(baseGCD, effectiveCast)
            end

            -- Consume simulated procs
            if bestAction.name == "Pyroblast" and simBuffs["Hot Streak"] then
                simBuffs["Hot Streak"] = nil
            elseif bestAction.name == "Fireball" and simBuffs["Brain Freeze"] then
                simBuffs["Brain Freeze"] = nil
            end

            -- Consume power
            local cost = bestAction.powerCost or 0
            if cost > 0 then
                simPower = math.max(0, simPower - cost)
            end

            -- Advance simulated cooldown for the chosen action
            local cdDuration = self:GetCooldownDurationHint(bestAction.spellName or bestAction.name, bestAction.cooldownHint)
            if cdDuration > 0 then
                readyAt[bestAction.name] = simTime + cdDuration
            else
                readyAt[bestAction.name] = simTime + step
            end

            -- Update simulated DoT / Buff / Ground AoE expirations
            if bestAction.name == "Flamestrike" then
                simGroundAuras.Flamestrike_R9 = simTime + step + 8.0
            elseif bestAction.name == "Flamestrike (Rank 8)" then
                simGroundAuras.Flamestrike_R8 = simTime + step + 8.0
            end

            if bestAction.role == "dot" and bestAction.spellName then
                local dotLen = bestAction.dotDuration or 18
                simDebuffs[bestAction.spellName] = simTime + step + dotLen
            elseif bestAction.role == "buff" and bestAction.spellName then
                simBuffs[bestAction.spellName] = simTime + step + 300
            end

            -- Advance simulated timeline clock strictly
            simTime = simTime + step
        end
    end

    FC.timeline.queue = queue
    FC.timeline.builtAt = GetTime()

    return queue
end
