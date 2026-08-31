FlowCore = FlowCore or {}
local FC = FlowCore

function FC:EstimateFutureValue(action, state, simTime)
    simTime = simTime or 0
    local base = action.priority or 0

    -- 1. DPCT Baseline
    if FC.CalculateDPCT and (action.role == "nuke" or action.role == "dot" or action.role == "aoe" or action.role == "spender" or action.role == "builder" or action.role == "execute") then
        local okDpct, dpct = pcall(FC.CalculateDPCT, FC, action, state)
        if okDpct and dpct and dpct > 0 then
            base = base + (dpct * 0.02)
        end
    end

    -- 2. Custom Score Function
    if action.score then
        local ok, val = pcall(action.score, state)
        if ok and val then
            base = base + val
        end
    end

    -- 3. Prediction & Procs Layer
    if FC.ApplyPredictionScore then
        local ok, val = pcall(FC.ApplyPredictionScore, FC, action, state, base)
        if ok and val then
            base = val
        end
    end

    -- 4. Synastria Perk Multipliers
    if FC.ApplyExtStateScore then
        local ok, val = pcall(FC.ApplyExtStateScore, FC, action, state, base)
        if ok and val then
            base = val
        end
    end

    -- 5. Role-based Situational & Debuff Uptime Maintenance Tuning
    if action.role == "execute" and state.phase == "execute" then
        base = base + 50
    elseif action.role == "defensive" and (state.phase == "emergency" or (state.dangerLevel or 0) >= 60) then
        base = base + 90
    elseif action.role == "heal" and (state.phase == "emergency" or (state.player and (state.player.healthPct or 100) < 40)) then
        base = base + 80
    elseif action.role == "dot" and action.spellName then
        -- DoT Uptime Refresh Incentive: If debuff is missing or expiring within <= 2.0s, incentivize smooth reapplication
        local debuffs = state.target and state.target.debuffs or {}
        local debuff = debuffs[action.spellName]
        if not debuff or (debuff.remaining or 0) <= 2.0 then
            base = base + 35
        end
    end

    return base
end
