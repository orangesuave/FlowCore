FlowCore = FlowCore or {}
local FC = FlowCore

FC.cooldowns = FC.cooldowns or {}
FC.knownCooldowns = FC.knownCooldowns or {}

FC.GCD = FC.GCD or 1.5
FC._gcdStart = FC._gcdStart or 0

-- =========================================================
-- NATIVE SPELL COOLDOWNS
-- =========================================================
function FC:GetNativeCooldown(spellNameOrId)
    if not spellNameOrId then return 0, 0, 0 end
    local start, duration, enabled = GetSpellCooldown(spellNameOrId)
    if not start then return 0, 0, 0 end

    -- Cache known maximum cooldown length whenever we observe a real cooldown active
    if duration and duration > (self.GCD + 0.05) then
        self.knownCooldowns[spellNameOrId] = duration
        if type(spellNameOrId) == "number" then
            local sName = GetSpellInfo(spellNameOrId)
            if sName then
                self.knownCooldowns[sName] = duration
            end
        end
    end

    return start, duration, enabled
end

function FC:IsNativeSpellReady(spellNameOrId)
    local start, duration = self:GetNativeCooldown(spellNameOrId)
    if start == 0 or duration == 0 then return true end

    -- Filter out pure GCD duration
    if duration <= (self.GCD + 0.05) then return true end

    return (start + duration) <= GetTime()
end

function FC:GetNativeTimeUntilReady(spellNameOrId)
    local start, duration = self:GetNativeCooldown(spellNameOrId)
    if start == 0 or duration == 0 then return 0 end
    if duration <= (self.GCD + 0.05) then return 0 end

    return math.max(0, (start + duration) - GetTime())
end

-- =========================================================
-- ITEM COOLDOWNS
-- =========================================================
function FC:GetItemCooldownRemaining(itemId)
    if not itemId or not GetItemCooldown then return 0 end
    local start, duration, enable = GetItemCooldown(itemId)
    if not start or start == 0 or duration == 0 then return 0 end
    if duration <= (self.GCD + 0.05) then return 0 end

    return math.max(0, (start + duration) - GetTime())
end

function FC:GetInventorySlotCooldownRemaining(slotId)
    if not slotId or not GetInventoryItemCooldown then return 0 end
    local start, duration, enable = GetInventoryItemCooldown("player", slotId)
    if not start or start == 0 or duration == 0 then return 0 end
    if duration <= (self.GCD + 0.05) then return 0 end

    return math.max(0, (start + duration) - GetTime())
end

-- =========================================================
-- COOLDOWN DURATION HINT
-- Retrieves known or estimated full cooldown length (in seconds)
-- used by Timeline.lua for forward simulation.
-- =========================================================
function FC:GetCooldownDurationHint(spellNameOrId, fallback)
    if not spellNameOrId then return fallback or 0 end
    local cached = self.knownCooldowns[spellNameOrId]
    if cached and cached > 0 then
        return cached
    end
    return fallback or 0
end

-- =========================================================
-- GLOBAL COOLDOWN (GCD) & HASTE TRACKING (Uncapped down to 0.0s)
-- =========================================================
function FC:GetHasteMultiplier()
    local hastePct = 0

    if UnitSpellHaste then
        local ok, h = pcall(UnitSpellHaste, "player")
        if ok and h and type(h) == "number" and h > 0 then
            hastePct = h
        end
    end

    if hastePct <= 0 and GetCombatRatingBonus then
        local ok, cr = pcall(GetCombatRatingBonus, 20)
        if ok and cr and type(cr) == "number" and cr > 0 then
            hastePct = cr
        end
    end

    if hastePct <= 0 and GetHaste then
        local ok, gh = pcall(GetHaste)
        if ok and gh and type(gh) == "number" and gh > 0 then
            hastePct = gh
        end
    end

    if hastePct <= 0 and self.state and self.state.player and self.state.player.stats then
        hastePct = self.state.player.stats.spellHaste or self.state.player.stats.meleeHaste or 0
    end

    local mult = 1.0 + (hastePct / 100)
    return math.max(1.0, mult), hastePct
end

function FC:GetEffectiveGCD()
    local hasteMult = self:GetHasteMultiplier()
    local base = (self.playerClass == "ROGUE" or self.playerClass == "CAT") and 1.0 or (self.baseGCD or 1.5)
    -- Scaling with haste down to a minimum of 0.0 seconds!
    return math.max(0.0, base / hasteMult)
end

function FC:GetGCDRemaining()
    local now = GetTime()
    local gcdSpell = (self.playerClass == "ROGUE") and 1752 or 61304 -- Sinister Strike or generic GCD
    local start, duration = GetSpellCooldown(gcdSpell)

    local effGCD = self:GetEffectiveGCD()
    if start and start > 0 and duration and duration > 0 and duration <= (effGCD + 0.15) then
        return math.max(0, (start + duration) - now)
    end

    local remaining = ((self._gcdStart or 0) + effGCD) - now
    return math.max(0, remaining)
end

function FC:IsGCDReady()
    return self:GetGCDRemaining() <= 0
end
