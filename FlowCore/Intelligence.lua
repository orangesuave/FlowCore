FlowCore = FlowCore or {}
local FC = FlowCore

FC.intel = FC.intel or {}
FC.combat = FC.combat or {}
FC.combat.procICDs = FC.combat.procICDs or {}

-- =====================================================
-- MAJOR TRINKET & PROC ICD DEFINITIONS (Phase 3)
-- =====================================================
FC.TRINKET_ICDS = {
    ["Dislodged Foreign Object"] = { buff = "Dislodged Foreign Object", icd = 45, duration = 20, sp = 1210 },
    ["Flare of the Heavens"]     = { buff = "Flare of the Heavens",     icd = 45, duration = 10, sp = 850 },
    ["Charred Twilight Scale"]   = { buff = "Charred Twilight Scale",   icd = 45, duration = 15, sp = 861 },
    ["Phylactery"]               = { buff = "Phylactery of the Nameless Lich", icd = 100, duration = 20, sp = 1207 },
    ["Lightweave"]               = { buff = "Lightweave",               icd = 45, duration = 15, sp = 295 },
    ["Ashen Band"]               = { buff = "Ashen Band of Endless Destruction", icd = 60, duration = 10, sp = 285 },
    ["Greatness"]                = { buff = "Greatness",                icd = 45, duration = 15, stat = 300 },
    ["Deathbringer's Will"]      = { buff = "Strength of the Taunka",   icd = 105, duration = 30, ap = 600 },
    ["Whispering Fanged Skull"]  = { buff = "Whispering Fanged Skull",  icd = 45, duration = 15, ap = 1100 },
    ["Hyperspeed Acceleration"]  = { buff = "Hyperspeed Acceleration",  icd = 60, duration = 12, haste = 340 }
}

-- =====================================================
-- BURST WINDOW & COOLDOWN ALIGNMENT STATE (Phase 3)
-- =====================================================
function FC:GetBurstWindowState()
    if not (self.state and (self.state.inCombat or self.state.engaged or self.simulationActive)) then
        return false, 0, nil, false, 0, nil
    end

    local pBuffs = (self.state and self.state.player and self.state.player.buffs) or {}
    local now = GetTime()

    -- 1. Check Bloodlust / Heroism / Time Warp
    if pBuffs["Bloodlust"] or pBuffs["Heroism"] or pBuffs["Time Warp"] then
        local b = pBuffs["Bloodlust"] or pBuffs["Heroism"] or pBuffs["Time Warp"]
        return true, (b.remaining or 40), "Heroism", false, 0
    end

    -- 2. Check Major Class Damage Cooldowns (Combustion, Arcane Power, Icy Veins, Avenging Wrath)
    local majorCooldownBuffs = { "Combustion", "Arcane Power", "Icy Veins", "Avenging Wrath", "Death Wish", "Recklessness", "Adrenaline Rush" }
    for _, bName in ipairs(majorCooldownBuffs) do
        if pBuffs[bName] and (pBuffs[bName].remaining or 0) > 0.1 then
            return true, pBuffs[bName].remaining, bName, false, 0
        end
    end

    -- 3. Check Active Trinket / Proc Buffs
    for tKey, def in pairs(self.TRINKET_ICDS) do
        if pBuffs[def.buff] and (pBuffs[def.buff].remaining or 0) > 0.1 then
            return true, pBuffs[def.buff].remaining, def.buff, false, 0
        end
    end

    -- 4. Check Impending ICD Procs (ready in <= 2.5s)
    local impendingBurst = false
    local minTimeToBurst = 999
    local impendingSource = nil

    for tKey, def in pairs(self.TRINKET_ICDS) do
        local icdInfo = self.combat.procICDs[def.buff]
        if icdInfo and icdInfo.readyAt then
            local remICD = icdInfo.readyAt - now
            if remICD > 0 and remICD <= 2.5 and remICD < minTimeToBurst then
                impendingBurst = true
                minTimeToBurst = remICD
                impendingSource = def.buff
            end
        end
    end

    return false, 0, nil, impendingBurst, (impendingBurst and minTimeToBurst or 0), impendingSource
end

-- =====================================================
-- COMBAT INTELLIGENCE ENGINE
-- =====================================================
function FC:UpdateIntelligence()
    if not FC.booted then return end

    local events = FC.combat.lastEvents or {}
    local now = GetTime()

    local dmgTotal = 0
    local dmgCount = 0
    local hasProc = false

    local recentWindow = 10
    local startIndex = math.max(1, #events - recentWindow)

    for i = startIndex, #events do
        local e = events[i]
        if e and (now - e.time) <= 3.5 then
            if e.event == "SWING_DAMAGE" or e.event == "SPELL_DAMAGE" or e.event == "RANGE_DAMAGE" then
                dmgTotal = dmgTotal + (e.amount or 0)
                dmgCount = dmgCount + 1
            end

            if e.event == "SPELL_AURA_APPLIED" or e.event == "SPELL_AURA_REFRESH" then
                hasProc = true
            end
        end
    end

    local burst = (dmgCount > 0) and (dmgTotal / dmgCount) or 0
    local procValue = hasProc and 1 or 0

    FC.intel.burstScore = burst
    FC.intel.procScore = procValue
    FC.intel.pressure = (burst * 0.1) + (procValue * 30) + (FC.state.dangerLevel or 0) * 0.5

    -- Burst Phase Evaluation (Phase 3)
    local isBurst, burstRem, burstSrc, impBurst, timeToBurst, impSrc = self:GetBurstWindowState()
    FC.intel.isBurstPhase = isBurst
    FC.intel.burstRemaining = burstRem
    FC.intel.burstSource = burstSrc
    FC.intel.impendingBurst = impBurst
    FC.intel.timeUntilBurst = timeToBurst
    FC.intel.impendingSource = impSrc
end
