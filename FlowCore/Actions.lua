FlowCore = FlowCore or {}
local FC = FlowCore

FC.actions = FC.actions or {}
FC._registeredSpellNames = FC._registeredSpellNames or {}

function FC:RegisterAction(action)
    table.insert(FC.actions, action)
end

-- =====================================================
-- POINT-BLANK AOE & CONE IMPACT RADIUS DATABASE
-- =====================================================
FC.PBAOE_IMPACT_RADIUS = {
    -- Mage
    ["Arcane Explosion"] = 10,
    ["Dragon's Breath"] = 12,
    ["Cone of Cold"] = 10,
    ["Frost Nova"] = 10,
    ["Blast Wave"] = 10,

    -- Warrior
    ["Thunder Clap"] = 8,
    ["Whirlwind"] = 8,
    ["Cleave"] = 5,
    ["Shockwave"] = 10,
    ["Intimidating Shout"] = 10,
    ["Demoralizing Shout"] = 10,

    -- Paladin
    ["Consecration"] = 8,
    ["Divine Storm"] = 8,
    ["Holy Wrath"] = 10,

    -- Death Knight
    ["Blood Boil"] = 10,
    ["Pestilence"] = 5,

    -- Rogue
    ["Fan of Knives"] = 8,

    -- Priest
    ["Holy Nova"] = 10,
    ["Psychic Scream"] = 8,

    -- Druid
    ["Swipe (Bear)"] = 5,
    ["Swipe (Cat)"] = 5,

    -- Shaman
    ["Magma Totem"] = 8,
    ["Fire Nova"] = 10,
    ["Thunderstorm"] = 10,

    -- Warlock
    ["Hellfire"] = 10,
    ["Shadowflame"] = 10,
}

function FC:IsTargetInImpactRange(spellName, targetUnit, explicitRadius)
    targetUnit = targetUnit or "target"
    if not UnitExists(targetUnit) then return true, "no_target" end

    local cleanName = string.match(spellName, "^([^%(]+)") or spellName
    cleanName = string.gsub(cleanName, "%s+$", "")

    -- 1. If spell has native single-target range check in WoW API
    if IsSpellInRange then
        local inRange = IsSpellInRange(cleanName, targetUnit)
        if inRange == 1 then
            return true, "in_range"
        elseif inRange == 0 then
            return false, "Out of spell range"
        end
        -- inRange == nil means spell does NOT have a targeted range (PBAoE, Cone, Melee, or Ground)
    end

    -- 2. Radius for un-targeted / self-centered / melee spells
    local radius = explicitRadius or (FC.PBAOE_IMPACT_RADIUS and FC.PBAOE_IMPACT_RADIUS[cleanName])
    if not radius then
        -- Default assumption: Requires melee range (5 yards)
        radius = 5
    end

    if radius <= 0 then
        return true, "self_buff"
    end

    -- 3. Proximity distance check
    if radius <= 5 then
        -- Melee (5 yards): Check duel range (dist 3 is ~9.9y)
        if CheckInteractDistance and not CheckInteractDistance(targetUnit, 3) then
            return false, "Out of melee range (>5 yd)"
        end
    elseif radius <= 10 then
        -- 8-10 yd PBAoE / Radius (e.g. Arcane Explosion 10y, Thunder Clap 8y, Consecration 8y)
        if CheckInteractDistance and not CheckInteractDistance(targetUnit, 3) then
            return false, string.format("Out of impact range (>%d yd radius)", radius)
        end
    elseif radius <= 12 then
        -- 10-12 yd Cones (e.g. Dragon's Breath 12y, Cone of Cold 10y)
        if CheckInteractDistance and not CheckInteractDistance(targetUnit, 2) and not CheckInteractDistance(targetUnit, 3) then
            return false, string.format("Out of impact range (>%d yd cone)", radius)
        end
    end

    return true, "in_impact_range"
end

-- =====================================================
-- BUILD SPELL ACTION
-- =====================================================
local function BuildSpellAction(spellId, spellName, spellIcon, opts)
    opts = opts or {}

    local displayName = opts.name or spellName
    local requiresTarget = (opts.requiresTarget ~= false)
    if opts.role == "buff" or opts.role == "heal" or opts.role == "defensive" or opts.role == "mana" then
        requiresTarget = false
    end
    if opts.role == "dispel" and (displayName == "Remove Curse" or displayName == "Cleanse" or displayName == "Cure Toxins") then
        requiresTarget = false
    end

    -- Static condition check (used by Timeline simulation & real-time evaluation)
    local function checkStatic(state)
        state = state or FC.state

        -- Check user runtime enable/disable toggle from Config UI
        local ov = FC.db and FC.db.spellOverrides and FC.db.spellOverrides[displayName]
        if ov then
            if ov.enabled == false then
                return false
            end
            if (ov.role == "buff" or opts.role == "buff") and ov.recastCheck == false then
                return false
            end
        elseif opts.enabled == false then
            return false
        end

        local effectiveRole = (ov and ov.role) or opts.role or "nuke"
        local needTarget = (effectiveRole ~= "buff" and effectiveRole ~= "heal" and effectiveRole ~= "defensive" and effectiveRole ~= "mana" and effectiveRole ~= "utility")
        if effectiveRole == "dispel" and (displayName == "Remove Curse" or displayName == "Cleanse" or displayName == "Cure Toxins") then
            needTarget = false
        end

        if needTarget then
            if not (state.target and state.target.exists and state.target.hostile and not state.target.dead) then
                return false
            end
            -- Range / Impact Proximity Check (handles single-target spells, 10y PBAoE, cones, and 5y melee)
            if not FC.simulationActive and state.target and state.target.exists then
                local inImpact, reason = FC:IsTargetInImpactRange(spellName, "target", opts.impactRadius or opts.radius)
                if not inImpact then
                    return false
                end
            end
        elseif effectiveRole == "aoe" and state.target and state.target.exists and not FC.simulationActive then
            -- For un-targeted AoE spells (Arcane Explosion, Dragon's Breath), ensure target is within impact radius
            local inImpact, reason = FC:IsTargetInImpactRange(spellName, "target", opts.impactRadius or opts.radius)
            if not inImpact then
                return false
            end
        end

        -- Usability / Mana Check
        if not FC.simulationActive and IsUsableSpell and spellName then
            local isUsable, notEnoughMana = IsUsableSpell(spellName)
            if isUsable == nil and notEnoughMana then
                return false
            end
        end

        if opts.conditions then
            local ok, res = pcall(opts.conditions, state)
            if not ok or not res then
                return false
            end
        end

        return true
    end

    local action = {
        name = displayName,
        spellId = spellId,
        spellName = spellName,
        icon = spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
        priority = opts.priority or 0,
        role = opts.role or "builder",
        school = opts.school or "Physical",
        cooldownHint = opts.cooldown or 0,
        castTime = opts.castTime or 0,
        dotDuration = opts.dotDuration or 0,
        procBonus = opts.procBonus,
        autoDiscovered = opts.autoDiscovered or false,
        isSynastriaPerk = opts.isSynastriaPerk or false,
        actionType = "spell",

        staticConditions = checkStatic,

        conditions = function(state)
            state = state or FC.state

            if not checkStatic(state) then
                return false
            end

            -- Must be off its own cooldown (GCD is handled dynamically)
            if not FC.simulationActive and not FC:IsNativeSpellReady(spellName) then
                return false
            end

            return true
        end,

        score = function(state)
            local s = 0
            -- Respect user custom priority overrides from Config UI
            if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[displayName] and FC.db.spellOverrides[displayName].priority then
                s = FC.db.spellOverrides[displayName].priority - (opts.priority or 0)
            end

            if opts.score then
                local ok, res = pcall(opts.score, state)
                if ok and res then
                    s = s + res
                end
            end
            return s
        end
    }

    FC:RegisterAction(action)
    FC._registeredSpellNames[displayName] = true
    FC._registeredSpellNames[spellName] = true

    return action
end

-- =====================================================
-- REGISTER SPELL ACTION (BY ID)
-- =====================================================
function FC:RegisterSpellAction(spellId, opts)
    local spellName, _, spellIcon = GetSpellInfo(spellId)
    if not spellName then return end

    if FC._registeredSpellNames[spellName] then return end

    return BuildSpellAction(spellId, spellName, spellIcon, opts)
end

-- =====================================================
-- REGISTER SPELL ACTION (BY NAME)
-- =====================================================
function FC:RegisterSpellActionByName(spellName, spellIcon, opts)
    if not spellName then return end

    if FC._registeredSpellNames[spellName] then return end

    return BuildSpellAction(nil, spellName, spellIcon, opts)
end

-- =====================================================
-- REGISTER ITEM ACTION
-- =====================================================
function FC:RegisterItemAction(opts)
    opts = opts or {}
    local name = opts.name or "Item"

    local function checkStatic(state)
        state = state or FC.state

        if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[name] then
            if FC.db.spellOverrides[name].enabled == false then
                return false
            end
        end

        if opts.conditions then
            local ok, res = pcall(opts.conditions, state)
            if not ok or not res then
                return false
            end
        end
        return true
    end

    local action = {
        name = name,
        itemId = opts.itemId,
        slotId = opts.slotId,
        icon = opts.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        priority = opts.priority or 40,
        role = opts.role or "item",
        cooldownHint = opts.cooldownHint or 60,
        castTime = 0,
        actionType = "item",

        staticConditions = checkStatic,

        conditions = function(state)
            state = state or FC.state
            if not checkStatic(state) then return false end

            if opts.slotId then
                if FC:GetInventorySlotCooldownRemaining(opts.slotId) > 0 then return false end
            elseif opts.itemId then
                if FC:GetItemCooldownRemaining(opts.itemId) > 0 then return false end
            end

            return true
        end,

        score = function(state)
            local s = 0
            if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[name] and FC.db.spellOverrides[name].priority then
                s = FC.db.spellOverrides[name].priority - (opts.priority or 40)
            end

            if opts.score then
                local ok, res = pcall(opts.score, state)
                if ok and res then s = s + res end
            end
            return s
        end
    }

    FC:RegisterAction(action)
    FC._registeredSpellNames[name] = true
    return action
end

-- =====================================================
-- META ACTIONS (FALLBACK & IDLE)
-- =====================================================
FC:RegisterAction({
    name = "Idle",
    priority = 0,
    role = "idle",
    icon = "Interface\\Icons\\Spell_Holy_Restoration",
    conditions = function(state)
        return state.phase == "idle" or (not state.target or not state.target.exists)
    end,
    score = function()
        return 0
    end
})

FC:RegisterAction({
    name = "Fallback",
    priority = -999,
    role = "fallback",
    icon = "Interface\\Icons\\INV_Misc_QuestionMark",
    conditions = function()
        return true
    end,
    score = function()
        return -10000
    end
})