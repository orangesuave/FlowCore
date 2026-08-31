FlowCore = FlowCore or {}
local FC = FlowCore

-- =====================================================
-- SAFETY INIT
-- =====================================================
FC.state = FC.state or {}
FC.state.player = FC.state.player or { buffs = {}, debuffs = {}, stats = {}, powerType = 0, comboPoints = 0, setBonuses = {} }
FC.state.target = FC.state.target or { exists = false, hostile = false, debuffs = {}, buffs = {}, resistances = {} }
FC.state.enemyCount = FC.state.enemyCount or 1
FC.state.activeEnemies = FC.state.activeEnemies or {}

FC._lastStateUpdate = FC._lastStateUpdate or 0
FC._wasEngaged = FC._wasEngaged or false
FC.simulationActive = false
FC.simulationMode = "single"
FC.simulationExpiry = 0

-- Common WotLK Fragile Breakable CC Debuffs
local BREAKABLE_CC = {
    ["Polymorph"] = true,
    ["Sap"] = true,
    ["Blind"] = true,
    ["Gouge"] = true,
    ["Freezing Trap"] = true,
    ["Freezing Arrow"] = true,
    ["Fear"] = true,
    ["Howl of Terror"] = true,
    ["Seduction"] = true,
    ["Repentance"] = true,
    ["Shackle Undead"] = true,
    ["Banish"] = true,
    ["Hibernate"] = true
}

-- Common Frozen / Freeze Debuffs (Enables Shatter)
local FROZEN_DEBUFFS = {
    ["Frost Nova"] = true,
    ["Freeze"] = true,
    ["Freezing Trap Effect"] = true,
    ["Shattered Barrier"] = true,
    ["Pin"] = true,
    ["Hungering Cold"] = true
}

-- Unit IDs to scan for active combatants
local SCAN_UNIT_IDS = {
    "target", "focus", "mouseover", "targettarget", "focustarget", "pettarget",
    "boss1", "boss2", "boss3", "boss4",
    "arena1", "arena2", "arena3", "arena4", "arena5",
    "party1target", "party2target", "party3target", "party4target",
    "partypet1target", "partypet2target", "partypet3target", "partypet4target"
}
for i = 1, 40 do
    table.insert(SCAN_UNIT_IDS, "raid" .. i .. "target")
end

-- =====================================================
-- COMPREHENSIVE TALENT SCANNER & EFFECT CALCULATOR (3.3.5a)
-- =====================================================
function FC:ScanTalents()
    self.talents = self.talents or {}
    self.talents.known = {}
    self.talents.tabPoints = { [1] = 0, [2] = 0, [3] = 0 }
    self.talents.critBonus = 0
    self.talents.hasteBonus = 0
    self.talents.primarySpec = "Unknown"

    if not GetNumTalentTabs then return end

    local numTabs = GetNumTalentTabs()
    local maxPoints = 0

    for tab = 1, (numTabs or 0) do
        local numTalents = GetNumTalents(tab) or 0
        local tabName = GetTalentTabInfo and GetTalentTabInfo(tab) or ("Tab" .. tab)
        local pointsInTab = 0

        for i = 1, numTalents do
            local name, icon, tier, column, rank, maxRank = GetTalentInfo(tab, i)
            if name and rank and rank > 0 then
                self.talents.known[name] = rank
                pointsInTab = pointsInTab + rank
            end
        end

        self.talents.tabPoints[tab] = pointsInTab
        if pointsInTab > maxPoints then
            maxPoints = pointsInTab
            self.talents.primarySpec = tabName
        end
    end

    if self.debug then
        self:Debug(string.format("Talent scan complete. Spec: %s (%d/%d/%d)",
            tostring(self.talents.primarySpec),
            self.talents.tabPoints[1] or 0,
            self.talents.tabPoints[2] or 0,
            self.talents.tabPoints[3] or 0))
    end
end

function FC:GetTalentRank(name)
    if not self.talents or not self.talents.known then return 0 end
    return self.talents.known[name] or 0
end

function FC:HasTalent(name)
    return (self:GetTalentRank(name) > 0)
end

-- Returns seconds reduced from base cast time due to talents
function FC:GetTalentCastReduction(spellName)
    if not spellName then return 0 end
    local reduction = 0

    -- Mage
    if spellName == "Fireball" or spellName == "Frostfire Bolt" then
        reduction = reduction + (self:GetTalentRank("Improved Fireball") * 0.1)
    elseif spellName == "Frostbolt" then
        reduction = reduction + (self:GetTalentRank("Improved Frostbolt") * 0.1)
    -- Warlock
    elseif spellName == "Shadow Bolt" or spellName == "Chaos Bolt" then
        reduction = reduction + (self:GetTalentRank("Bane") * 0.1)
    elseif spellName == "Soul Fire" then
        reduction = reduction + (self:GetTalentRank("Bane") * 0.4)
    -- Druid
    elseif spellName == "Wrath" or spellName == "Starfire" then
        reduction = reduction + (self:GetTalentRank("Starlight Wrath") * 0.1)
    -- Shaman
    elseif spellName == "Lightning Bolt" or spellName == "Chain Lightning" then
        reduction = reduction + (self:GetTalentRank("Lightning Mastery") * 0.1)
    elseif spellName == "Lava Burst" then
        reduction = reduction + (self:GetTalentRank("Lightning Mastery") * 0.1)
    -- Priest
    elseif spellName == "Holy Fire" or spellName == "Smite" or spellName == "Heal" or spellName == "Greater Heal" then
        reduction = reduction + (self:GetTalentRank("Divine Fury") * 0.1)
    -- Paladin
    elseif spellName == "Holy Light" then
        reduction = reduction + (self:GetTalentRank("Light's Grace") > 0 and 0.5 or 0)
    end

    return reduction
end

-- Returns additional crit chance percentage (0..100) from talents
function FC:GetTalentCritBonus(spellName, school)
    local crit = 0

    -- Mage Talents
    local cm = self:GetTalentRank("Critical Mass")
    if cm > 0 and (school == "Fire" or spellName == "Frostfire Bolt") then
        crit = crit + (cm * 2.0)
    end

    local pyro = self:GetTalentRank("Pyromaniac")
    if pyro > 0 and (school == "Fire" or spellName == "Frostfire Bolt") then
        crit = crit + (pyro * 1.0)
    end

    local wif = self:GetTalentRank("World in Flames")
    if wif > 0 and (spellName == "Flamestrike" or spellName == "Pyroblast" or spellName == "Blast Wave" or spellName == "Dragon's Breath" or spellName == "Living Bomb" or spellName == "Blizzard" or spellName == "Arcane Explosion") then
        crit = crit + (wif * 2.0)
    end

    -- Warlock Talents
    local dev = self:GetTalentRank("Devastation")
    if dev > 0 and (school == "Destruction" or school == "Fire") then
        crit = crit + 5.0
    end

    -- Paladin Talents
    local sl = self:GetTalentRank("Sanctified Light")
    if sl > 0 and (spellName == "Holy Shock" or spellName == "Exorcism" or spellName == "Holy Light") then
        crit = crit + (sl * 2.0)
    end
    local conv = self:GetTalentRank("Conviction")
    if conv > 0 then
        crit = crit + (conv * 1.0)
    end

    -- Warrior Talents
    local cruelty = self:GetTalentRank("Cruelty")
    if cruelty > 0 then
        crit = crit + (cruelty * 1.0)
    end

    -- Rogue Talents
    local malice = self:GetTalentRank("Malice")
    if malice > 0 then
        crit = crit + (malice * 1.0)
    end

    return crit
end

-- Returns dynamic damage multiplier factor (e.g. 1.10 for +10%) based on active talents
function FC:GetTalentDamageMultiplier(spellName, school, targetHealthPct, targetIsSlowed)
    local mult = 1.0
    targetHealthPct = targetHealthPct or 100

    -- Mage
    if school == "Fire" then
        local fp = self:GetTalentRank("Fire Power")
        if fp > 0 then mult = mult * (1.0 + fp * 0.02) end
    end
    if school == "Frost" then
        local pi = self:GetTalentRank("Piercing Ice")
        if pi > 0 then mult = mult * (1.0 + pi * 0.02) end
        local ac = self:GetTalentRank("Arctic Winds")
        if ac > 0 then mult = mult * (1.0 + ac * 0.01) end
    end
    if school == "Arcane" then
        local ai = self:GetTalentRank("Arcane Instability")
        if ai > 0 then mult = mult * (1.0 + ai * 0.01) end
    end

    local pwf = self:GetTalentRank("Playing with Fire")
    if pwf > 0 then mult = mult * (1.0 + pwf * 0.01) end

    local si = self:GetTalentRank("Spell Impact")
    if si > 0 and (spellName == "Fire Blast" or spellName == "Scorch" or spellName == "Arcane Blast" or spellName == "Arcane Barrage" or spellName == "Ice Lance" or spellName == "Cone of Cold") then
        mult = mult * (1.0 + si * 0.02)
    end

    -- Execute Range Talents (<35% HP)
    if targetHealthPct < 35 then
        local mf = self:GetTalentRank("Molten Fury")
        if mf > 0 then mult = mult * (1.0 + mf * 0.06) end

        local de = self:GetTalentRank("Death's Embrace")
        if de > 0 and school == "Shadow" then mult = mult * (1.0 + de * 0.04) end

        local mc = self:GetTalentRank("Merciless Combat")
        if mc > 0 then mult = mult * (1.0 + mc * 0.06) end
    end

    -- Slowed / Snared Target Multipliers
    if targetIsSlowed then
        local ttw = self:GetTalentRank("Torment the Weak")
        if ttw > 0 and (spellName == "Frostbolt" or spellName == "Fireball" or spellName == "Frostfire Bolt" or spellName == "Pyroblast" or spellName == "Arcane Missiles" or spellName == "Arcane Blast" or spellName == "Arcane Barrage") then
            mult = mult * (1.0 + ttw * 0.04)
        end
    end

    -- Warlock Talents
    local shadowMastery = self:GetTalentRank("Shadow Mastery")
    if shadowMastery > 0 and school == "Shadow" then mult = mult * (1.0 + shadowMastery * 0.03) end
    local emberstorm = self:GetTalentRank("Emberstorm")
    if emberstorm > 0 and school == "Fire" then mult = mult * (1.0 + emberstorm * 0.03) end

    -- Priest Talents
    local darkness = self:GetTalentRank("Darkness")
    if darkness > 0 and school == "Shadow" then mult = mult * (1.0 + darkness * 0.02) end

    -- Druid Talents
    local moonfury = self:GetTalentRank("Moonfury")
    if moonfury > 0 and (spellName == "Starfire" or spellName == "Wrath" or spellName == "Moonfire") then mult = mult * (1.0 + moonfury * 0.02) end

    -- Shaman Talents
    local conCall = self:GetTalentRank("Call of Flame")
    if conCall > 0 and (school == "Fire" or spellName == "Lava Burst") then mult = mult * (1.0 + conCall * 0.02) end

    -- Paladin Talents
    local crusade = self:GetTalentRank("Crusade")
    if crusade > 0 then mult = mult * (1.0 + crusade * 0.01) end

    -- Warrior Talents
    local twoHandSpec = self:GetTalentRank("Two-Handed Weapon Specialization")
    if twoHandSpec > 0 and school == "Physical" then mult = mult * (1.0 + twoHandSpec * 0.02) end

    return mult
end

-- Returns critical strike damage multiplier (e.g. 2.50x with 5/5 Burnout)
function FC:GetTalentCritMultiplier(school)
    local mult = 2.0
    if school == "Fire" then
        local burnout = self:GetTalentRank("Burnout")
        if burnout > 0 then
            mult = mult + (burnout * 0.10)
        end
    end
    return mult
end

-- Returns Ignite periodic damage proportion (e.g. 0.40 with 5/5 Ignite)
function FC:GetTalentIgniteRate(school)
    if school == "Fire" then
        local ignite = self:GetTalentRank("Ignite")
        if ignite > 0 then
            return (ignite * 0.08)
        end
    end
    return 0
end

-- =====================================================
-- COMPREHENSIVE GLYPH SCANNER & ROTATIONAL IMPACT (3.3.5a)
-- =====================================================
function FC:ScanGlyphs(talentGroup)
    self.glyphs = self.glyphs or {}
    self.glyphList = {}
    self.state = self.state or {}
    self.state.player = self.state.player or {}
    self.state.player.glyphs = {}

    if not GetGlyphSocketInfo then return end

    local activeGroup = talentGroup or (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
    local numGlyphsFound = 0

    for socketIndex = 1, 6 do
        local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(socketIndex, activeGroup)
        if not glyphSpellID then
            enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(socketIndex)
        end

        local gName = nil
        if glyphSpellID and GetSpellInfo then
            gName = GetSpellInfo(glyphSpellID)
        end

        if not gName and GetGlyphLink then
            local ok, link = pcall(GetGlyphLink, socketIndex, activeGroup)
            if not ok or not link then ok, link = pcall(GetGlyphLink, socketIndex) end
            if ok and link then
                gName = string.match(link, "%[(.+)%]")
            end
        end

        if gName and gName ~= "" then
            local typeStr = (glyphType == 1 or glyphType == "major" or (GLYPHTYPE_MAJOR and glyphType == GLYPHTYPE_MAJOR)) and "Major" or "Minor"
            local cleanName = string.gsub(gName, "%s+$", "")

            local glyphData = {
                id = glyphSpellID or 0,
                name = cleanName,
                type = typeStr,
                socket = socketIndex,
                icon = icon or "Interface\\Icons\\INV_Glyph_MajorMage"
            }

            self.glyphs[cleanName] = glyphData
            self.glyphs[string.lower(cleanName)] = glyphData
            table.insert(self.glyphList, glyphData)
            self.state.player.glyphs[cleanName] = true
            numGlyphsFound = numGlyphsFound + 1
        end
    end

    if self.debug then
        local specName = (self.GetActiveSpecName and self:GetActiveSpecName()) or ("Spec " .. activeGroup)
        self:Debug(string.format("ScanGlyphs: Discovered %d active glyphs for [%s] (Spec %d).", numGlyphsFound, specName, activeGroup))
    end
end

function FC:GetActiveSpecName()
    local activeGroup = (GetActiveTalentGroup and GetActiveTalentGroup()) or 1

    -- 1. Check user configured spec name in DB
    if FC.db and FC.db.specProfiles and FC.db.specProfiles[activeGroup] and FC.db.specProfiles[activeGroup].specName and FC.db.specProfiles[activeGroup].specName ~= ("Spec " .. activeGroup) then
        return FC.db.specProfiles[activeGroup].specName, activeGroup
    end

    -- 2. Check scanned talents primary spec
    if FC.talents and FC.talents.primarySpec and FC.talents.primarySpec ~= "Unknown" then
        return FC.talents.primarySpec, activeGroup
    end

    -- 3. Live scan talents if not already scanned
    if FC.ScanTalents then
        FC:ScanTalents()
        if FC.talents and FC.talents.primarySpec and FC.talents.primarySpec ~= "Unknown" then
            return FC.talents.primarySpec, activeGroup
        end
    end

    -- 4. Direct tab inspection fallback
    if GetTalentTabInfo and GetNumTalentTabs then
        local maxPts = -1
        local bestTab = nil
        for tab = 1, (GetNumTalentTabs() or 0) do
            local name, icon, points = GetTalentTabInfo(tab, false, false, activeGroup)
            if name and points and points > maxPts then
                maxPts = points
                bestTab = name
            end
        end
        if bestTab and maxPts > 0 then
            return bestTab, activeGroup
        end
    end

    -- 5. Class default fallback
    local _, pClass = UnitClass("player")
    if pClass == "MAGE" then return "Fire", activeGroup
    elseif pClass == "WARLOCK" then return "Affliction", activeGroup
    elseif pClass == "PRIEST" then return "Shadow", activeGroup
    elseif pClass == "PALADIN" then return "Retribution", activeGroup
    elseif pClass == "WARRIOR" then return "Fury", activeGroup
    elseif pClass == "ROGUE" then return "Combat", activeGroup
    elseif pClass == "DRUID" then return "Balance", activeGroup
    elseif pClass == "HUNTER" then return "Marksmanship", activeGroup
    elseif pClass == "SHAMAN" then return "Elemental", activeGroup
    elseif pClass == "DEATHKNIGHT" then return "Frost", activeGroup
    end

    return "Spec " .. activeGroup, activeGroup
end

function FC:HasGlyph(glyphNameOrPattern)
    if not self.glyphs or not glyphNameOrPattern then return false end
    if self.glyphs[glyphNameOrPattern] then return true end

    local lowerPattern = string.lower(glyphNameOrPattern)
    if self.glyphs[lowerPattern] then return true end

    for gName, _ in pairs(self.glyphs) do
        if type(gName) == "string" and string.find(string.lower(gName), lowerPattern, 1, true) then
            return true
        end
    end
    return false
end

function FC:GetGlyphDamageMultiplier(spellName)
    if not spellName then return 1.0 end
    local mult = 1.0
    local s = string.lower(spellName)

    if s == "scorch" and self:HasGlyph("scorch") then
        mult = mult * 1.20
    elseif s == "frostbolt" and self:HasGlyph("frostbolt") then
        mult = mult * 1.05
    elseif s == "frostfire bolt" and self:HasGlyph("frostfire") then
        mult = mult * 1.02
    elseif s == "obliterate" and self:HasGlyph("obliterate") then
        mult = mult * 1.25
    elseif s == "mortal strike" and self:HasGlyph("mortal strike") then
        mult = mult * 1.10
    elseif s == "exorcism" and self:HasGlyph("exorcism") then
        mult = mult * 1.20
    elseif (s == "judgment of wisdom" or s == "judgment of light" or s == "judgment of justice") and self:HasGlyph("judgment") then
        mult = mult * 1.10
    elseif s == "incinerate" and self:HasGlyph("incinerate") then
        mult = mult * 1.05
    elseif s == "immolate" and self:HasGlyph("immolate") then
        mult = mult * 1.10
    elseif s == "lightning bolt" and self:HasGlyph("lightning bolt") then
        mult = mult * 1.04
    elseif s == "insect swarm" and self:HasGlyph("insect swarm") then
        mult = mult * 1.30
    elseif s == "steady shot" and self:HasGlyph("steady shot") then
        mult = mult * 1.10
    elseif s == "mind flay" and self:HasGlyph("mind flay") then
        mult = mult * 1.10
    end

    return mult
end

-- =====================================================
-- COMPREHENSIVE CLASS GLYPH CATALOG & RANKING ENGINE
-- =====================================================
FC.CLASS_GLYPHS_CATALOG = {
    ["MAGE"] = {
        -- Major
        { name = "Glyph of Living Bomb", type = "Major", desc = "Periodic damage from Living Bomb can now be critical strikes", scoreFunc = function(spec) return (spec == "Fire") and 980 or 450 end },
        { name = "Glyph of Fireball", type = "Major", desc = "Reduces cast time of Fireball by 0.15s, but removes DoT", scoreFunc = function(spec) return (spec == "Fire" or spec == "Frostfire") and 940 or 200 end },
        { name = "Glyph of Molten Armor", type = "Major", desc = "Molten Armor grants +20% of your Spirit as critical strike rating", scoreFunc = function(spec) return (spec == "Fire" or spec == "Arcane") and 910 or 600 end },
        { name = "Glyph of Arcane Blast", type = "Major", desc = "Increases damage bonus of Arcane Blast debuff by 3% per stack", scoreFunc = function(spec) return (spec == "Arcane") and 990 or 100 end },
        { name = "Glyph of Arcane Missiles", type = "Major", desc = "Increases critical strike damage bonus of Arcane Missiles by 25%", scoreFunc = function(spec) return (spec == "Arcane") and 920 or 150 end },
        { name = "Glyph of Scorch", type = "Major", desc = "Increases Scorch damage by 20%", scoreFunc = function(spec) return (spec == "Fire") and 820 or 350 end },
        { name = "Glyph of Frostfire", type = "Major", desc = "Increases initial Frostfire Bolt damage by 2% and crit by 2%", scoreFunc = function(spec) return (spec == "Fire" or spec == "Frostfire") and 880 or 150 end },
        { name = "Glyph of Frostbolt", type = "Major", desc = "Increases Frostbolt damage by 5%", scoreFunc = function(spec) return (spec == "Frost") and 950 or 100 end },
        { name = "Glyph of Ice Lance", type = "Major", desc = "Ice Lance causes 4x damage against frozen targets (instead of 3x)", scoreFunc = function(spec) return (spec == "Frost") and 900 or 150 end },
        { name = "Glyph of Deep Freeze", type = "Major", desc = "Increases range of Deep Freeze by 10 yards", scoreFunc = function(spec) return (spec == "Frost") and 780 or 100 end },
        { name = "Glyph of Mirror Image", type = "Major", desc = "Mirror Images cast Fireball or Frostbolt (+30% damage)", scoreFunc = function() return 750 end },
        { name = "Glyph of Arcane Barrage", type = "Major", desc = "Reduces mana cost of Arcane Barrage by 20%", scoreFunc = function(spec) return (spec == "Arcane") and 700 or 100 end },
        { name = "Glyph of Evocation", type = "Major", desc = "Regain 60% of your maximum health over Evocation duration", scoreFunc = function() return 650 end },
        { name = "Glyph of Eternal Water", type = "Major", desc = "Water Elemental lasts indefinitely", scoreFunc = function(spec) return (spec == "Frost") and 870 or 50 end },
        { name = "Glyph of Invisibility", type = "Major", desc = "Increases duration of Invisibility by 10 sec", scoreFunc = function() return 400 end },
        { name = "Glyph of Ice Barrier", type = "Major", desc = "Increases amount of damage absorbed by Ice Barrier by 30%", scoreFunc = function(spec) return (spec == "Frost") and 720 or 50 end },
        { name = "Glyph of Ice Block", type = "Major", desc = "Your Frost Nova cooldown is reset when using Ice Block", scoreFunc = function() return 500 end },
        { name = "Glyph of Mana Gem", type = "Major", desc = "Increases mana restored by Mana Gem by 40%", scoreFunc = function(spec) return (spec == "Arcane") and 680 or 400 end },

        -- Minor
        { name = "Glyph of Arcane Intellect", type = "Minor", desc = "Reduces mana cost of Arcane Intellect and Brilliance by 50%", scoreFunc = function() return 500 end },
        { name = "Glyph of Frost Ward", type = "Minor", desc = "Increases chance to reflect Frost spells by +5% (to 15%) while Frost Ward is active", scoreFunc = function() return 480 end },
        { name = "Glyph of Fire Ward", type = "Minor", desc = "Increases chance to reflect Fire spells by +5% (to 15%) while Fire Ward is active", scoreFunc = function() return 480 end },
        { name = "Glyph of Slow Fall", type = "Minor", desc = "Slow Fall no longer requires a reagent (Feather)", scoreFunc = function() return 420 end },
        { name = "Glyph of Blast Wave", type = "Minor", desc = "Blast Wave mana cost reduced by 100%, but no longer knocks back", scoreFunc = function(spec) return (spec == "Fire") and 460 or 200 end },
        { name = "Glyph of the Penguin", type = "Minor", desc = "Your Polymorph spell turns the target into a baby penguin", scoreFunc = function() return 300 end },
    },
    ["WARLOCK"] = {
        { name = "Glyph of Quick Decay", type = "Major", desc = "Your haste reduces time between Corruption ticks", scoreFunc = function(spec) return (spec == "Affliction") and 990 or 600 end },
        { name = "Glyph of Life Tap", type = "Major", desc = "+20% Spirit as Spell Power for 40s after Life Tap", scoreFunc = function() return 960 end },
        { name = "Glyph of Haunt", type = "Major", desc = "+3% bonus damage granted by Haunt", scoreFunc = function(spec) return (spec == "Affliction") and 940 or 100 end },
        { name = "Glyph of Immolate", type = "Major", desc = "+10% periodic damage to Immolate", scoreFunc = function(spec) return (spec == "Destruction") and 950 or 500 end },
        { name = "Glyph of Conflagrate", type = "Major", desc = "Conflagrate no longer consumes Immolate", scoreFunc = function(spec) return (spec == "Destruction") and 980 or 100 end },
        { name = "Glyph of Chaos Bolt", type = "Major", desc = "-2s cooldown on Chaos Bolt", scoreFunc = function(spec) return (spec == "Destruction") and 920 or 100 end },
        { name = "Glyph of Incinerate", type = "Major", desc = "+5% damage done by Incinerate", scoreFunc = function(spec) return (spec == "Destruction") and 900 or 100 end },
        { name = "Glyph of Felguard", type = "Major", desc = "+20% Attack Power for your Felguard", scoreFunc = function(spec) return (spec == "Demonology") and 970 or 50 end },
        { name = "Glyph of Metamorphosis", type = "Major", desc = "Increases duration of Metamorphosis by 6 sec", scoreFunc = function(spec) return (spec == "Demonology") and 950 or 50 end },
        { name = "Glyph of Drain Soul", type = "Minor", desc = "Chance to create extra soul shard", scoreFunc = function() return 500 end },
        { name = "Glyph of Unending Breath", type = "Minor", desc = "+20% swim speed while under Unending Breath", scoreFunc = function() return 450 end },
        { name = "Glyph of Souls", type = "Minor", desc = "Soulwell mana cost reduced by 70%", scoreFunc = function() return 400 end },
    },
    ["PRIEST"] = {
        { name = "Glyph of Shadow", type = "Major", desc = "+30% Spirit as Spell Power on spell crits", scoreFunc = function(spec) return (spec == "Shadow") and 980 or 100 end },
        { name = "Glyph of Mind Flay", type = "Major", desc = "+10% Mind Flay damage when SW:P is active", scoreFunc = function(spec) return (spec == "Shadow") and 960 or 100 end },
        { name = "Glyph of Shadow Word: Pain", type = "Major", desc = "SW:P periodic damage restores 1% base mana", scoreFunc = function(spec) return (spec == "Shadow") and 920 or 100 end },
        { name = "Glyph of Flash Heal", type = "Major", desc = "-10% mana cost on Flash Heal", scoreFunc = function(spec) return (spec == "Holy" or spec == "Discipline") and 950 or 200 end },
        { name = "Glyph of Penance", type = "Major", desc = "-2s cooldown on Penance", scoreFunc = function(spec) return (spec == "Discipline") and 990 or 50 end },
        { name = "Glyph of Power Word: Shield", type = "Major", desc = "PW:S heals target for 20% of absorb amount", scoreFunc = function(spec) return (spec == "Discipline") and 960 or 400 end },
        { name = "Glyph of Fortitude", type = "Minor", desc = "-50% mana cost on Power Word: Fortitude", scoreFunc = function() return 500 end },
        { name = "Glyph of Shadow Protection", type = "Minor", desc = "+10m duration on Shadow Protection", scoreFunc = function() return 480 end },
        { name = "Glyph of Levitate", type = "Minor", desc = "Levitate no longer requires a light feather", scoreFunc = function() return 420 end },
    },
    ["PALADIN"] = {
        { name = "Glyph of Judgment", type = "Major", desc = "+10% damage done by Judgments", scoreFunc = function(spec) return (spec == "Retribution" or spec == "Protection") and 980 or 500 end },
        { name = "Glyph of Seal of Vengeance", type = "Major", desc = "+10 Expertise while Seal of Vengeance/Corruption is active", scoreFunc = function(spec) return (spec == "Retribution" or spec == "Protection") and 960 or 200 end },
        { name = "Glyph of Consecration", type = "Major", desc = "+2s duration and cooldown on Consecration", scoreFunc = function(spec) return (spec == "Retribution" or spec == "Protection") and 920 or 300 end },
        { name = "Glyph of Exorcism", type = "Major", desc = "+20% damage done by Exorcism", scoreFunc = function(spec) return (spec == "Retribution") and 900 or 400 end },
        { name = "Glyph of Holy Light", type = "Major", desc = "Holy Light heals up to 5 nearby targets for 10% of heal", scoreFunc = function(spec) return (spec == "Holy") and 990 or 100 end },
        { name = "Glyph of Flash of Light", type = "Major", desc = "+5% crit chance on Flash of Light", scoreFunc = function(spec) return (spec == "Holy") and 940 or 200 end },
        { name = "Glyph of Lay on Hands", type = "Minor", desc = "-5 min cooldown on Lay on Hands", scoreFunc = function() return 500 end },
        { name = "Glyph of Blessing of Kings", type = "Minor", desc = "-50% mana cost on Kings", scoreFunc = function() return 480 end },
        { name = "Glyph of Blessing of Might", type = "Minor", desc = "+20m duration on Might on self", scoreFunc = function() return 450 end },
    },
    ["DEATHKNIGHT"] = {
        { name = "Glyph of Obliterate", type = "Major", desc = "+25% damage to Obliterate", scoreFunc = function(spec) return (spec == "Frost" or spec == "Unholy") and 990 or 400 end },
        { name = "Glyph of Frost Strike", type = "Major", desc = "-8 Runic Power cost on Frost Strike", scoreFunc = function(spec) return (spec == "Frost") and 960 or 100 end },
        { name = "Glyph of Disease", type = "Major", desc = "Pestilence refreshes disease durations to maximum", scoreFunc = function(spec) return (spec == "Unholy" or spec == "Blood") and 950 or 600 end },
        { name = "Glyph of Death Strike", type = "Major", desc = "+1% Death Strike damage per 1 Runic Power (up to +25%)", scoreFunc = function(spec) return (spec == "Blood") and 980 or 500 end },
        { name = "Glyph of Icy Touch", type = "Major", desc = "+20% Frost Fever disease damage", scoreFunc = function() return 850 end },
        { name = "Glyph of Blood Tap", type = "Minor", desc = "Blood Tap no longer damages self", scoreFunc = function() return 500 end },
        { name = "Glyph of Horn of Winter", type = "Minor", desc = "+1m duration on Horn of Winter", scoreFunc = function() return 480 end },
        { name = "Glyph of Death's Embrace", type = "Minor", desc = "Refunds 20 RP when healing minion with Death Coil", scoreFunc = function() return 420 end },
    },
    ["WARRIOR"] = {
        { name = "Glyph of Mortal Strike", type = "Major", desc = "+10% damage to Mortal Strike", scoreFunc = function(spec) return (spec == "Arms") and 980 or 100 end },
        { name = "Glyph of Whirlwind", type = "Major", desc = "-2s cooldown on Whirlwind", scoreFunc = function(spec) return (spec == "Fury") and 990 or 700 end },
        { name = "Glyph of Bloodthirst", type = "Major", desc = "+100% healing received from Bloodthirst", scoreFunc = function(spec) return (spec == "Fury") and 940 or 100 end },
        { name = "Glyph of Bladestorm", type = "Major", desc = "-15s cooldown on Bladestorm", scoreFunc = function(spec) return (spec == "Arms") and 950 or 100 end },
        { name = "Glyph of Devastate", type = "Major", desc = "Devastate applies 2 stacks of Sunder Armor", scoreFunc = function(spec) return (spec == "Protection") and 980 or 100 end },
        { name = "Glyph of Shield Slam", type = "Major", desc = "+10% block value granted by Shield Slam", scoreFunc = function(spec) return (spec == "Protection") and 960 or 100 end },
        { name = "Glyph of Battle", type = "Minor", desc = "+2 min duration on Battle Shout", scoreFunc = function() return 500 end },
        { name = "Glyph of Command", type = "Minor", desc = "+2 min duration on Commanding Shout", scoreFunc = function() return 480 end },
        { name = "Glyph of Enduring Victory", type = "Minor", desc = "+5s window to use Victory Rush", scoreFunc = function() return 420 end },
    },
    ["ROGUE"] = {
        { name = "Glyph of Eviscerate", type = "Major", desc = "+10% critical strike chance on Eviscerate", scoreFunc = function() return 950 end },
        { name = "Glyph of Sinister Strike", type = "Major", desc = "Sinister Strike crits have 50% chance to add extra combo point", scoreFunc = function(spec) return (spec == "Combat") and 990 or 100 end },
        { name = "Glyph of Mutilate", type = "Major", desc = "-5 Energy cost on Mutilate", scoreFunc = function(spec) return (spec == "Assassination") and 990 or 100 end },
        { name = "Glyph of Rupture", type = "Major", desc = "+4s duration on Rupture", scoreFunc = function() return 920 end },
        { name = "Glyph of Slice and Dice", type = "Major", desc = "+3s duration on Slice and Dice", scoreFunc = function() return 900 end },
        { name = "Glyph of Vanish", type = "Minor", desc = "+30% movement speed while in Vanish", scoreFunc = function() return 500 end },
        { name = "Glyph of Safe Fall", type = "Minor", desc = "Increases distance before taking fall damage", scoreFunc = function() return 450 end },
    },
    ["DRUID"] = {
        { name = "Glyph of Starfire", type = "Major", desc = "Starfire extends Moonfire duration by 3s (up to 9s max)", scoreFunc = function(spec) return (spec == "Balance") and 990 or 100 end },
        { name = "Glyph of Moonfire", type = "Major", desc = "+75% periodic damage on Moonfire, -90% direct damage", scoreFunc = function(spec) return (spec == "Balance") and 960 or 200 end },
        { name = "Glyph of Insect Swarm", type = "Major", desc = "+30% damage on Insect Swarm", scoreFunc = function(spec) return (spec == "Balance") and 930 or 100 end },
        { name = "Glyph of Rip", type = "Major", desc = "+4s duration on Rip", scoreFunc = function(spec) return (spec == "Feral") and 980 or 100 end },
        { name = "Glyph of Savage Roar", type = "Major", desc = "+6% bonus physical damage from Savage Roar", scoreFunc = function(spec) return (spec == "Feral") and 960 or 100 end },
        { name = "Glyph of Shred", type = "Major", desc = "Shred extends Rip duration by 2s (up to 6s max)", scoreFunc = function(spec) return (spec == "Feral") and 950 or 100 end },
        { name = "Glyph of Wild Growth", type = "Major", desc = "Wild Growth affects 1 additional target", scoreFunc = function(spec) return (spec == "Restoration") and 990 or 100 end },
        { name = "Glyph of Swiftmend", type = "Major", desc = "Swiftmend no longer consumes Rejuvenation/Regrowth", scoreFunc = function(spec) return (spec == "Restoration") and 970 or 100 end },
        { name = "Glyph of Thorns", type = "Minor", desc = "+50 min duration on Thorns", scoreFunc = function() return 500 end },
        { name = "Glyph of the Wild", type = "Minor", desc = "-50% mana cost on Mark / Gift of the Wild", scoreFunc = function() return 480 end },
        { name = "Glyph of Aquatic Form", type = "Minor", desc = "+20% swim speed in Aquatic Form", scoreFunc = function() return 420 end },
    },
    ["HUNTER"] = {
        { name = "Glyph of Explosive Shot", type = "Major", desc = "+4% critical strike chance on Explosive Shot", scoreFunc = function(spec) return (spec == "Survival") and 990 or 100 end },
        { name = "Glyph of Steady Shot", type = "Major", desc = "+10% Steady Shot damage when Serpent Sting is active", scoreFunc = function(spec) return (spec == "Marksmanship" or spec == "Survival") and 960 or 500 end },
        { name = "Glyph of Serpent Sting", type = "Major", desc = "+6s duration on Serpent Sting", scoreFunc = function() return 940 end },
        { name = "Glyph of Kill Shot", type = "Major", desc = "-6s cooldown on Kill Shot", scoreFunc = function() return 920 end },
        { name = "Glyph of Chimera Shot", type = "Major", desc = "-1s cooldown on Chimera Shot", scoreFunc = function(spec) return (spec == "Marksmanship") and 970 or 100 end },
        { name = "Glyph of Aimed Shot", type = "Major", desc = "-2s cooldown on Aimed Shot", scoreFunc = function(spec) return (spec == "Marksmanship") and 910 or 100 end },
        { name = "Glyph of Feign Death", type = "Minor", desc = "-5s cooldown on Feign Death", scoreFunc = function() return 500 end },
        { name = "Glyph of Mend Pet", type = "Minor", desc = "Mend Pet increases pet happiness slightly", scoreFunc = function() return 480 end },
        { name = "Glyph of Revive Pet", type = "Minor", desc = "100% pushback reduction on Revive Pet", scoreFunc = function() return 450 end },
    },
    ["SHAMAN"] = {
        { name = "Glyph of Lava", type = "Major", desc = "+10% Spell Power scaling on Lava Burst", scoreFunc = function(spec) return (spec == "Elemental") and 990 or 100 end },
        { name = "Glyph of Lightning Bolt", type = "Major", desc = "+4% damage on Lightning Bolt", scoreFunc = function(spec) return (spec == "Elemental") and 960 or 200 end },
        { name = "Glyph of Flame Shock", type = "Major", desc = "+60% critical damage bonus on Flame Shock DoT", scoreFunc = function(spec) return (spec == "Elemental" or spec == "Enhancement") and 940 or 300 end },
        { name = "Glyph of Stormstrike", type = "Major", desc = "+8% Nature damage bonus on Stormstrike", scoreFunc = function(spec) return (spec == "Enhancement") and 990 or 100 end },
        { name = "Glyph of Windfury Weapon", type = "Major", desc = "+2% Windfury trigger chance per swing", scoreFunc = function(spec) return (spec == "Enhancement") and 970 or 100 end },
        { name = "Glyph of Chain Heal", type = "Major", desc = "Chain Heal heals 1 additional target", scoreFunc = function(spec) return (spec == "Restoration") and 990 or 100 end },
        { name = "Glyph of Riptide", type = "Major", desc = "+6s duration on Riptide", scoreFunc = function(spec) return (spec == "Restoration") and 970 or 100 end },
        { name = "Glyph of Water Walking", type = "Minor", desc = "Water Walking no longer requires a reagent", scoreFunc = function() return 500 end },
        { name = "Glyph of Ghost Wolf", type = "Minor", desc = "Regenerates +1% HP per 5 sec in Ghost Wolf", scoreFunc = function() return 480 end },
    }
}

function FC:GetClassGlyphRankings(specName)
    local pClass = self.playerClass or select(2, UnitClass("player")) or "MAGE"
    local catalog = self.CLASS_GLYPHS_CATALOG[pClass] or self.CLASS_GLYPHS_CATALOG["MAGE"] or {}
    local rankings = {}
    specName = specName or (self.GetActiveSpecName and self:GetActiveSpecName()) or "Fire"

    for _, g in ipairs(catalog) do
        local score = 0
        if g.scoreFunc then
            local ok, res = pcall(g.scoreFunc, specName, self.state and self.state.player and self.state.player.stats)
            if ok and res then score = res end
        end
        local isEquipped = (self.HasGlyph and self:HasGlyph(g.name))

        table.insert(rankings, {
            name = g.name,
            type = g.type,
            desc = g.desc,
            score = score,
            isEquipped = isEquipped
        })
    end

    table.sort(rankings, function(a, b)
        if a.type ~= b.type then
            return a.type == "Major"
        end
        return a.score > b.score
    end)

    return rankings
end

-- =====================================================
-- PLAYER STATS & EQUIPMENT SCANNER
-- =====================================================
function FC:UpdatePlayerStats()
    local p = self.state.player
    p.stats = p.stats or {}

    -- 1. Base Attributes (1=Str, 2=Agi, 3=Sta, 4=Int, 5=Spi)
    p.stats.strength = UnitStat("player", 1) or 0
    p.stats.agility = UnitStat("player", 2) or 0
    p.stats.stamina = UnitStat("player", 3) or 0
    p.stats.intellect = UnitStat("player", 4) or 0
    p.stats.spirit = UnitStat("player", 5) or 0

    -- 2. Attack Power (Melee & Ranged)
    local baseAP, posBuff, negBuff = UnitAttackPower("player")
    p.stats.attackPower = (baseAP or 0) + (posBuff or 0) + (negBuff or 0)

    local baseRAP, posRBuff, negRBuff = UnitRangedAttackPower and UnitRangedAttackPower("player") or 0, 0, 0
    p.stats.rangedAttackPower = (baseRAP or 0) + (posRBuff or 0) + (negRBuff or 0)

    -- 3. Equipped Weapon Damage & Attack Speeds
    local minDmg, maxDmg, minOff, maxOff, physPos, physNeg, pct = UnitDamage("player")
    local mainSpeed, offSpeed = UnitAttackSpeed("player")
    local rangedSpeed, minRangedDmg, maxRangedDmg = 0, 0, 0
    if UnitRangedDamage then
        local rSpd, rMin, rMax = UnitRangedDamage("player")
        rangedSpeed = rSpd or 0
        minRangedDmg = rMin or 0
        maxRangedDmg = rMax or 0
    end

    p.stats.weaponMinDamage = minDmg or 0
    p.stats.weaponMaxDamage = maxDmg or 0
    p.stats.weaponAvgDamage = ((minDmg or 0) + (maxDmg or 0)) / 2
    p.stats.mainHandSpeed = mainSpeed or 2.0
    p.stats.offHandSpeed = offSpeed or 0
    p.stats.rangedSpeed = rangedSpeed or 0
    p.stats.rangedMinDamage = minRangedDmg or 0
    p.stats.rangedMaxDamage = maxRangedDmg or 0
    p.stats.rangedAvgDamage = ((minRangedDmg or 0) + (maxRangedDmg or 0)) / 2

    -- 4. Spell Power per School (1=Physical, 2=Holy, 3=Fire, 4=Nature, 5=Frost, 6=Shadow, 7=Arcane)
    p.stats.spellPower = {
        Holy = GetSpellBonusDamage(2) or 0,
        Fire = GetSpellBonusDamage(3) or 0,
        Nature = GetSpellBonusDamage(4) or 0,
        Frost = GetSpellBonusDamage(5) or 0,
        Shadow = GetSpellBonusDamage(6) or 0,
        Arcane = GetSpellBonusDamage(7) or 0,
        Healing = GetSpellBonusHealing and GetSpellBonusHealing() or 0
    }
    p.stats.spellPower.Max = math.max(
        p.stats.spellPower.Holy,
        p.stats.spellPower.Fire,
        p.stats.spellPower.Nature,
        p.stats.spellPower.Frost,
        p.stats.spellPower.Shadow,
        p.stats.spellPower.Arcane
    )

    -- 5. Critical Strike Chance (Spell, Melee, Ranged)
    p.stats.spellCrit = GetSpellCritChance(3) or GetSpellCritChance(2) or 0
    p.stats.meleeCrit = GetCritChance() or 0
    p.stats.rangedCrit = GetRangedCritChance and GetRangedCritChance() or 0

    -- 6. Haste & Armor Penetration
    local spHaste = 0
    if UnitSpellHaste then
        local ok, h = pcall(UnitSpellHaste, "player")
        if ok and h and type(h) == "number" then spHaste = h end
    end
    if spHaste <= 0 and GetCombatRatingBonus then
        local ok, cr = pcall(GetCombatRatingBonus, 20)
        if ok and cr and type(cr) == "number" then spHaste = cr end
    end
    if spHaste <= 0 and GetHaste then
        local ok, gh = pcall(GetHaste)
        if ok and gh and type(gh) == "number" then spHaste = gh end
    end

    p.stats.spellHaste = spHaste
    p.stats.meleeHaste = (GetCombatRatingBonus and GetCombatRatingBonus(18)) or (GetHaste and GetHaste()) or 0
    p.stats.armorPen = (GetCombatRating and GetCombatRating(25)) or 0

    -- 7. Hit, Expertise & Spell Penetration
    p.stats.spellHit = (GetCombatRatingBonus and GetCombatRatingBonus(8)) or 0
    p.stats.meleeHit = (GetCombatRatingBonus and GetCombatRatingBonus(6)) or 0
    p.stats.rangedHit = (GetCombatRatingBonus and GetCombatRatingBonus(7)) or 0
    p.stats.expertise = (GetExpertise and GetExpertise()) or 0
    p.stats.expertisePct = (GetExpertisePercent and GetExpertisePercent()) or 0
    p.stats.spellPenetration = (GetSpellPenetration and GetSpellPenetration()) or 0

    -- 8. Defensive & Survivability Stats
    p.stats.armor = select(2, UnitArmor("player")) or 0
    p.stats.dodge = (GetDodgeChance and GetDodgeChance()) or 0
    p.stats.parry = (GetParryChance and GetParryChance()) or 0
    p.stats.block = (GetBlockChance and GetBlockChance()) or 0
    p.stats.blockValue = (GetShieldBlock and GetShieldBlock()) or 0
    p.stats.resilience = (GetCombatRating and GetCombatRating(15)) or 0

    -- 9. Combo Points (Rogues & Feral Druids)
    p.comboPoints = GetComboPoints("player", "target") or 0

    -- 10. Tier Set Bonus Scanner
    p.setBonuses = self:ScanTierSets()

    -- 11. Synastria Attunements & Forges
    if self.ScanAttunementsAndForges then
        p.forges = self:ScanAttunementsAndForges()
    end
end

-- =====================================================
-- COMPREHENSIVE TIER SET SCANNER (Classic, TBC, WotLK)
-- =====================================================
local tierScannerTooltip = CreateFrame("GameTooltip", "FlowCoreTierScanTooltip", UIParent, "GameTooltipTemplate")
tierScannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")

function FC:ScanTierSets()
    local setCounts = {
        -- Classic
        T1 = 0, T2 = 0, T2_5 = 0, T3 = 0, D1 = 0, D2 = 0, ZG = 0,
        -- TBC
        T4 = 0, T5 = 0, T6 = 0, D3 = 0, Sunwell = 0,
        -- WotLK
        T7 = 0, T8 = 0, T9 = 0, T10 = 0,
        -- Set Names Catalog
        activeSets = {}
    }

    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            tierScannerTooltip:ClearLines()
            tierScannerTooltip:SetInventoryItem("player", slot)

            for lineIdx = 1, tierScannerTooltip:NumLines() do
                local lineText = _G["FlowCoreTierScanTooltipTextLeft" .. lineIdx]
                if lineText then
                    local txt = lineText:GetText() or ""

                    -- WotLK T10
                    if string.find(txt, "Bloodmage", 1, true) or string.find(txt, "Sanctified Bloodmage", 1, true) or
                       string.find(txt, "Lightsworn", 1, true) or string.find(txt, "Dark Coven", 1, true) or
                       string.find(txt, "Ymirjar Lord's", 1, true) or string.find(txt, "Scourgelord", 1, true) or
                       string.find(txt, "Shadowblade", 1, true) or string.find(txt, "Ahn'Kahar", 1, true) or
                       string.find(txt, "Frost Witch", 1, true) or string.find(txt, "Lasherweave", 1, true) or
                       string.find(txt, "Crimson Acolyte", 1, true) then
                        setCounts.T10 = setCounts.T10 + 1
                        break

                    -- WotLK T9
                    elseif string.find(txt, "Khadgar's", 1, true) or string.find(txt, "Sunstrider's", 1, true) or
                           string.find(txt, "Turalyon's", 1, true) or string.find(txt, "Liadrin's", 1, true) or
                           string.find(txt, "Gul'dan's", 1, true) or string.find(txt, "Kel'Thuzad's", 1, true) or
                           string.find(txt, "Ymirjar", 1, true) or string.find(txt, "Hellscream's", 1, true) or
                           string.find(txt, "Malfurion's", 1, true) or string.find(txt, "Runetotem's", 1, true) or
                           string.find(txt, "Nobundo's", 1, true) or string.find(txt, "Thrall's", 1, true) or
                           string.find(txt, "VanCleef's", 1, true) or string.find(txt, "Garona's", 1, true) or
                           string.find(txt, "Wrynn's", 1, true) or string.find(txt, "Thassarian's", 1, true) or
                           string.find(txt, "Koltira's", 1, true) or string.find(txt, "Windrunner's", 1, true) then
                        setCounts.T9 = setCounts.T9 + 1
                        break

                    -- WotLK T8
                    elseif string.find(txt, "Kirin Tor", 1, true) or string.find(txt, "Deathbringer", 1, true) or
                           string.find(txt, "Sanctification", 1, true) or string.find(txt, "Aegis Plate", 1, true) or
                           string.find(txt, "Worldbreaker", 1, true) or string.find(txt, "Nightsong", 1, true) or
                           string.find(txt, "Terrorblade", 1, true) or string.find(txt, "Siegebreaker", 1, true) or
                           string.find(txt, "Darkruned", 1, true) or string.find(txt, "Conqueror's", 1, true) then
                        setCounts.T8 = setCounts.T8 + 1
                        break

                    -- WotLK T7
                    elseif string.find(txt, "Heroes'", 1, true) or string.find(txt, "Valorous", 1, true) or
                           string.find(txt, "Scourgeborne", 1, true) or string.find(txt, "Cryptstalker Battlegear", 1, true) or
                           string.find(txt, "Earthshatter Battlegear", 1, true) or string.find(txt, "Dreamwalker Garb", 1, true) or
                           string.find(txt, "Frostfire Garb", 1, true) or string.find(txt, "Plagueheart Garb", 1, true) then
                        setCounts.T7 = setCounts.T7 + 1
                        break

                    -- TBC T6
                    elseif string.find(txt, "Tempest", 1, true) or string.find(txt, "Malefic", 1, true) or
                           string.find(txt, "Absolution", 1, true) or string.find(txt, "Lightbringer", 1, true) or
                           string.find(txt, "Gronnstalker", 1, true) or string.find(txt, "Thunderheart", 1, true) or
                           string.find(txt, "Skyshatter", 1, true) or string.find(txt, "Slayer's", 1, true) or
                           string.find(txt, "Onslaught", 1, true) then
                        setCounts.T6 = setCounts.T6 + 1
                        break

                    -- TBC T5
                    elseif string.find(txt, "Tirisfal", 1, true) or string.find(txt, "Corruptor", 1, true) or
                           string.find(txt, "Avatar", 1, true) or string.find(txt, "Crystalforge", 1, true) or
                           string.find(txt, "Rift Stalker", 1, true) or string.find(txt, "Nordrassil", 1, true) or
                           string.find(txt, "Cataclysm", 1, true) or string.find(txt, "Deathmantle", 1, true) or
                           string.find(txt, "Destroyer", 1, true) then
                        setCounts.T5 = setCounts.T5 + 1
                        break

                    -- TBC T4
                    elseif string.find(txt, "Aldor", 1, true) or string.find(txt, "Voidheart", 1, true) or
                           string.find(txt, "Incarnate", 1, true) or string.find(txt, "Justicar", 1, true) or
                           string.find(txt, "Demon Stalker", 1, true) or string.find(txt, "Malorne", 1, true) or
                           string.find(txt, "Cyclone", 1, true) or string.find(txt, "Netherblade", 1, true) or
                           string.find(txt, "Warbringer", 1, true) then
                        setCounts.T4 = setCounts.T4 + 1
                        break

                    -- TBC D3
                    elseif string.find(txt, "Incanter's", 1, true) or string.find(txt, "Oblivion", 1, true) or
                           string.find(txt, "Mana-Etched", 1, true) or string.find(txt, "Desolation", 1, true) or
                           string.find(txt, "Bold Armor", 1, true) or string.find(txt, "Wastewalker", 1, true) or
                           string.find(txt, "Moonglade", 1, true) or string.find(txt, "Tidefury", 1, true) or
                           string.find(txt, "Beast Lord", 1, true) or string.find(txt, "Righteous", 1, true) then
                        setCounts.D3 = setCounts.D3 + 1
                        break

                    -- Classic T3 (Naxx 40)
                    elseif string.find(txt, "Frostfire Regalia", 1, true) or string.find(txt, "Plagueheart Raiment", 1, true) or
                           string.find(txt, "Vestments of Faith", 1, true) or string.find(txt, "Redemption Armor", 1, true) or
                           string.find(txt, "Cryptstalker Armor", 1, true) or string.find(txt, "Dreamwalker Raiment", 1, true) or
                           string.find(txt, "The Earthshatterer", 1, true) or string.find(txt, "Bonescythe Armor", 1, true) or
                           string.find(txt, "Dreadnaught's", 1, true) then
                        setCounts.T3 = setCounts.T3 + 1
                        break

                    -- Classic T2.5 (AQ40)
                    elseif string.find(txt, "Enigma", 1, true) or string.find(txt, "Doomcaller", 1, true) or
                           string.find(txt, "Oracle", 1, true) or string.find(txt, "Avenger's", 1, true) or
                           string.find(txt, "Striker's", 1, true) or string.find(txt, "Genesis", 1, true) or
                           string.find(txt, "Stormcaller's", 1, true) or string.find(txt, "Deathdealer's", 1, true) or
                           string.find(txt, "Conqueror's Battlegear", 1, true) then
                        setCounts.T2_5 = setCounts.T2_5 + 1
                        break

                    -- Classic T2 (BWL)
                    elseif string.find(txt, "Netherwind", 1, true) or string.find(txt, "Nemesis", 1, true) or
                           string.find(txt, "Transcendence", 1, true) or string.find(txt, "Judgement", 1, true) or
                           string.find(txt, "Dragonstalker", 1, true) or string.find(txt, "Stormrage", 1, true) or
                           string.find(txt, "The Ten Storms", 1, true) or string.find(txt, "Bloodfang", 1, true) or
                           string.find(txt, "Battlegear of Wrath", 1, true) then
                        setCounts.T2 = setCounts.T2 + 1
                        break

                    -- Classic T1 (MC)
                    elseif string.find(txt, "Arcanist", 1, true) or string.find(txt, "Felheart", 1, true) or
                           string.find(txt, "Prophecy", 1, true) or string.find(txt, "Lawbringer", 1, true) or
                           string.find(txt, "Giantstalker", 1, true) or string.find(txt, "Cenarion", 1, true) or
                           string.find(txt, "Earthfury", 1, true) or string.find(txt, "Nightslayer", 1, true) or
                           string.find(txt, "Battlegear of Might", 1, true) then
                        setCounts.T1 = setCounts.T1 + 1
                        break

                    -- Classic D1/D2
                    elseif string.find(txt, "Magister's", 1, true) or string.find(txt, "Sorcerer's", 1, true) or
                           string.find(txt, "Dreadmist", 1, true) or string.find(txt, "Deathmist", 1, true) or
                           string.find(txt, "Devout", 1, true) or string.find(txt, "Virtuous", 1, true) or
                           string.find(txt, "Lightforge", 1, true) or string.find(txt, "Soulforge", 1, true) or
                           string.find(txt, "Beaststalker", 1, true) or string.find(txt, "Beastmaster", 1, true) or
                           string.find(txt, "Wildheart", 1, true) or string.find(txt, "Feralheart", 1, true) or
                           string.find(txt, "The Elements", 1, true) or string.find(txt, "The Five Thunders", 1, true) or
                           string.find(txt, "Shadowcraft", 1, true) or string.find(txt, "Darkmantle", 1, true) or
                           string.find(txt, "Valor", 1, true) or string.find(txt, "Heroism", 1, true) then
                        setCounts.D1 = setCounts.D1 + 1
                        break
                    end
                end
            end
        end
    end

    return setCounts
end

-- =====================================================
-- AURAS SCANNER
-- =====================================================
function FC:UpdatePlayerAuras()
    local buffs = {}
    local debuffs = {}
    local hasCurse = false
    local hasPoison = false
    local hasDisease = false
    local hasMagicDebuff = false

    -- Buffs
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", i)
        if not name then break end

        local remaining = 0
        if expirationTime and expirationTime > 0 then
            remaining = math.max(0, expirationTime - GetTime())
        elseif duration == 0 then
            remaining = 9999
        end

        buffs[name] = {
            count = (count and count > 0) and count or 1,
            remaining = remaining,
            duration = duration or 0,
            icon = icon
        }
    end

    -- Debuffs
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime = UnitDebuff("player", i)
        if not name then break end

        local remaining = 0
        if expirationTime and expirationTime > 0 then
            remaining = math.max(0, expirationTime - GetTime())
        end

        debuffs[name] = {
            count = (count and count > 0) and count or 1,
            remaining = remaining,
            duration = duration or 0,
            debuffType = debuffType
        }

        if debuffType == "Curse" then hasCurse = true end
        if debuffType == "Poison" then hasPoison = true end
        if debuffType == "Disease" then hasDisease = true end
        if debuffType == "Magic" then hasMagicDebuff = true end
    end

    self.state.player.buffs = buffs
    self.state.player.debuffs = debuffs
    self.state.player.hasCurse = hasCurse
    self.state.player.hasPoison = hasPoison
    self.state.player.hasDisease = hasDisease
    self.state.player.hasMagicDebuff = hasMagicDebuff
end

function FC:UpdateTargetAuras()
    local t = self.state.target
    t.debuffs = {}
    t.buffs = {}
    t.isFrozen = false
    t.isCrowdControlled = false
    t.hasStealableBuff = false

    if not t.exists or not UnitExists("target") then
        return
    end

    -- Target Debuffs
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitDebuff("target", i)
        if not name then break end

        local remaining = 0
        if expirationTime and expirationTime > 0 then
            remaining = math.max(0, expirationTime - GetTime())
        elseif duration == 0 then
            remaining = 9999
        end

        local isMine = (unitCaster == "player" or unitCaster == "pet")

        t.debuffs[name] = {
            count = (count and count > 0) and count or 1,
            remaining = remaining,
            duration = duration or 0,
            mine = isMine
        }

        if FROZEN_DEBUFFS[name] then
            t.isFrozen = true
        end

        if BREAKABLE_CC[name] then
            t.isCrowdControlled = true
        end
    end

    -- Target Buffs
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitBuff("target", i)
        if not name then break end

        local remaining = 0
        if expirationTime and expirationTime > 0 then
            remaining = math.max(0, expirationTime - GetTime())
        elseif duration == 0 then
            remaining = 9999
        end

        t.buffs[name] = {
            count = (count and count > 0) and count or 1,
            remaining = remaining,
            duration = duration or 0,
            stealable = isStealable
        }

        if isStealable or debuffType == "Magic" then
            t.hasStealableBuff = true
        end
    end
end

-- =====================================================
-- MULTI-TARGET DOT STATUS & AWARENESS (Phase 2)
-- =====================================================
function FC:GetMultiTargetDotInfo(spellName)
    if not spellName or not self.combat or not self.combat.multiTargetDots then
        return 0, {}, 3
    end

    local dotTable = self.combat.multiTargetDots[spellName]
    if not dotTable then
        return 0, {}, (spellName == "Living Bomb" and 3) or 10
    end

    local now = GetTime()
    local activeList = {}
    local activeCount = 0
    local targetGUID = UnitGUID("target")

    for guid, info in pairs(dotTable) do
        local rem = (info.expiresAt or 0) - now
        if rem > 0.1 then
            activeCount = activeCount + 1
            table.insert(activeList, {
                guid = guid,
                name = info.destName or "Enemy",
                remaining = rem,
                duration = info.duration or 12,
                isTarget = (guid == targetGUID)
            })
        else
            dotTable[guid] = nil
        end
    end

    table.sort(activeList, function(a, b) return a.remaining < b.remaining end)
    local maxAllowed = (spellName == "Living Bomb" and 3) or 10
    return activeCount, activeList, maxAllowed
end

-- =====================================================
-- NETWORK LATENCY & SPELL QUEUE WINDOW CALCULATOR
-- =====================================================
function FC:GetLatencyWindow()
    local mode = (self.db and self.db.queueWindowMode) or "auto"
    if mode == "custom" and self.db and self.db.customQueueWindowMs then
        return math.max(0.10, math.min(0.60, self.db.customQueueWindowMs / 1000))
    end

    -- Auto mode: Query client round-trip latency via GetNetStats
    local downRate, upRate, lagHome, lagWorld = GetNetStats()
    local lagMs = lagWorld or lagHome or 60
    if lagMs <= 0 then lagMs = 60 end

    -- Safe queue buffer = round-trip world ping (in seconds) + 120ms human buffer
    local lagSec = (lagMs / 1000) + 0.120
    return math.max(0.150, math.min(0.500, lagSec))
end

-- =====================================================
-- PLAYER CAST & SPELL QUEUE TRACKER
-- =====================================================
function FC:UpdatePlayerCastState()
    local p = self.state.player
    p.isCasting = false
    p.isChanneling = false
    p.castSpellName = nil
    p.castRemaining = 0
    p.castDuration = 0
    p.castStartTime = 0
    p.castEndTime = 0
    p.castQueueWindow = self:GetLatencyWindow()
    p.inCastQueueWindow = false

    local now = GetTime()
    local spellName, _, _, _, startTime, endTime = UnitCastingInfo("player")
    if spellName and endTime then
        p.isCasting = true
        p.castSpellName = spellName
        p.castStartTime = (startTime or 0) / 1000
        p.castEndTime = (endTime or 0) / 1000
        p.castDuration = p.castEndTime - p.castStartTime
        p.castRemaining = math.max(0, p.castEndTime - now)
    else
        local chanName, _, _, _, cStart, cEnd = UnitChannelInfo("player")
        if chanName and cEnd then
            p.isChanneling = true
            p.castSpellName = chanName
            p.castStartTime = (cStart or 0) / 1000
            p.castEndTime = (cEnd or 0) / 1000
            p.castDuration = p.castEndTime - p.castStartTime
            p.castRemaining = math.max(0, p.castEndTime - now)
        end
    end

    -- Check Cast or Channeling Queue Window
    if (p.isCasting or p.isChanneling) and p.castRemaining > 0 then
        if p.castRemaining <= p.castQueueWindow then
            p.inCastQueueWindow = true
            if not p._wasInQueueWindow and self.db and self.db.queueAudio then
                pcall(PlaySound, "igMiniMapZoomIn")
            end
        end
    else
        -- Check Global Cooldown (GCD) Queue Window (For Instant Casts & Rapid Haste Spells)
        local gcdRem = (self.GetGCDRemaining and self:GetGCDRemaining()) or 0
        if gcdRem > 0 and gcdRem <= p.castQueueWindow then
            p.inCastQueueWindow = true
            if not p._wasInQueueWindow and self.db and self.db.queueAudio then
                pcall(PlaySound, "igMiniMapZoomIn")
            end
        end
    end
    p._wasInQueueWindow = p.inCastQueueWindow
end

-- =====================================================
-- TARGET CAST & CHANNELING TRACKER
-- =====================================================
function FC:UpdateTargetCastState()
    local t = self.state.target
    t.isCasting = false
    t.isChanneling = false
    t.castSpellName = nil
    t.castRemaining = 0
    t.interruptible = false

    if not t.exists or not UnitExists("target") then
        return
    end

    local spellName, _, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo("target")
    if spellName and endTime then
        t.isCasting = true
        t.castSpellName = spellName
        t.castRemaining = math.max(0, (endTime / 1000) - GetTime())
        t.interruptible = not notInterruptible
        return
    end

    local chanName, _, _, _, cStart, cEnd, _, notIntChan = UnitChannelInfo("target")
    if chanName and cEnd then
        t.isChanneling = true
        t.castSpellName = chanName
        t.castRemaining = math.max(0, (cEnd / 1000) - GetTime())
        t.interruptible = not notIntChan
    end
end

-- =====================================================
-- VITALS SCANNER
-- =====================================================
function FC:UpdateVitals()
    local p = self.state.player
    local t = self.state.target

    -- Player Vitals
    p.health = UnitHealth("player") or 1
    p.healthMax = UnitHealthMax("player") or 1
    p.healthPct = (p.health / math.max(1, p.healthMax)) * 100
    p.power = UnitMana("player") or 0
    p.powerMax = UnitManaMax("player") or 1
    p.powerPct = (p.power / math.max(1, p.powerMax)) * 100
    p.powerType = UnitPowerType("player") or 0

    -- Player Movement Detection (Phase 1)
    local curSpeed = GetUnitSpeed("player") or 0
    p.isMoving = (curSpeed > 0)
    p.speed = curSpeed

    -- Multi-Spec Support (Up to 6 specs on Synastria) (Phase 4)
    local activeSpec = 1
    if type(GetActiveTalentGroup) == "function" then
        local ok, g = pcall(GetActiveTalentGroup)
        if ok and g and tonumber(g) then
            activeSpec = math.min(6, math.max(1, tonumber(g)))
        end
    end
    self.state.activeSpec = activeSpec

    -- Target Vitals
    if t.exists and UnitExists("target") then
        t.name = UnitName("target") or "Unknown"
        t.guid = UnitGUID("target") or nil
        t.health = UnitHealth("target") or 0
        t.healthMax = UnitHealthMax("target") or 1
        t.healthPct = (t.health / math.max(1, t.healthMax)) * 100
        t.classification = UnitClassification("target") or "normal"
        t.isBoss = (t.classification == "worldboss" or t.classification == "rareelite" or UnitLevel("target") == -1)
        t.creatureType = UnitCreatureType("target") or "Unknown"
        t.isUndead = (t.creatureType == "Undead")
        t.isDemon = (t.creatureType == "Demon")
        t.isDragonkin = (t.creatureType == "Dragonkin")
        t.isElemental = (t.creatureType == "Elemental")
    else
        t.name = "None"
        t.guid = nil
        t.health = 0
        t.healthMax = 1
        t.healthPct = 0
        t.classification = "normal"
        t.isBoss = false
        t.creatureType = "Unknown"
        t.isUndead = false
        t.isDemon = false
        t.isDragonkin = false
        t.isElemental = false
    end
end

-- =====================================================
-- MULTI-TARGET & ACTIVE ENEMY DETECTOR
-- =====================================================
function FC:UpdateActiveEnemies()
    local now = GetTime()
    local count = 0
    local activeTable = {}

    -- 1. Query CombatEvents hostile sliding window (10s window)
    if self.combat and self.combat.activeHostileGUIDs then
        for guid, lastSeen in pairs(self.combat.activeHostileGUIDs) do
            if (now - lastSeen) <= 10.0 then
                count = count + 1
                activeTable[guid] = true
            else
                self.combat.activeHostileGUIDs[guid] = nil
            end
        end
    end

    -- 2. Scan Unit IDs
    for _, unitId in ipairs(SCAN_UNIT_IDS) do
        if UnitExists(unitId) and UnitCanAttack("player", unitId) and not UnitIsDead(unitId) then
            local guid = UnitGUID(unitId)
            if guid and not activeTable[guid] then
                count = count + 1
                activeTable[guid] = true
            end
        end
    end

    if count == 0 and UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        count = 1
    end

    self.state.enemyCount = count
    self.state.activeEnemies = activeTable
end

-- =====================================================
-- COMBAT METRICS (DTPS, DPS, TTD, DANGER LEVEL)
-- =====================================================
function FC:UpdateCombatMetrics()
    local now = GetTime()
    local window = 4.0

    -- 1. Incoming DTPS
    local dtps = 0
    local dmgTakenSum = 0
    local dtHistory = self.combat.damageTakenHistory or {}

    for i = #dtHistory, 1, -1 do
        if (now - dtHistory[i].time) > window then
            table.remove(dtHistory, i)
        else
            dmgTakenSum = dmgTakenSum + (dtHistory[i].amount or 0)
        end
    end
    if #dtHistory > 0 then
        dtps = dmgTakenSum / window
    end
    self.state.dtps = dtps

    -- 2. Target Damage Rate & Target TTD
    local dps = 0
    local dmgDoneSum = 0
    local ddHistory = self.combat.damageDoneHistory or {}

    for i = #ddHistory, 1, -1 do
        if (now - ddHistory[i].time) > window then
            table.remove(ddHistory, i)
        else
            dmgDoneSum = dmgDoneSum + (ddHistory[i].amount or 0)
        end
    end
    if #ddHistory > 0 then
        dps = dmgDoneSum / window
    end
    self.state.dps = dps

    -- 2. Enhanced Target Time-To-Death (TTD) Tracking (Step 2)
    local t = self.state.target
    if t.exists and t.hostile and not t.dead and UnitExists("target") then
        local currentHP = UnitHealth("target")
        local currentGuid = UnitGUID("target")
        self._targetHPSamples = self._targetHPSamples or {}

        if self._lastTargetGUID ~= currentGuid then
            self._lastTargetGUID = currentGuid
            self._targetHPSamples = {}
        end

        table.insert(self._targetHPSamples, { time = now, hp = currentHP })
        while #self._targetHPSamples > 1 and (now - self._targetHPSamples[1].time) > 4.0 do
            table.remove(self._targetHPSamples, 1)
        end

        local ttdCalculated = false
        if #self._targetHPSamples >= 2 then
            local oldest = self._targetHPSamples[1]
            local dt = now - oldest.time
            local dhp = oldest.hp - currentHP
            if dt >= 0.8 and dhp > 0 then
                local targetDPS = dhp / dt
                if targetDPS > 10 then
                    t.ttd = math.max(0.1, currentHP / targetDPS)
                    t.dps = targetDPS
                    ttdCalculated = true
                end
            end
        end

        if not ttdCalculated then
            if dps > 10 then
                t.ttd = t.health / dps
            else
                t.ttd = 999
            end
        end
    else
        t.ttd = 999
    end

    -- 3. Player Time-To-Death estimation
    local p = self.state.player
    if dtps > 10 and p.health > 0 then
        p.ttd = p.health / dtps
    else
        p.ttd = 999
    end

    -- 4. Survivability / Danger Level (0 to 100)
    local danger = 0
    local hpPct = p.healthPct or 100

    if hpPct < 25 then
        danger = 85 + (25 - hpPct) * 0.6
    elseif hpPct < 50 then
        danger = 50 + (50 - hpPct) * 1.4
    elseif hpPct < 75 then
        danger = 20 + (75 - hpPct) * 1.2
    end

    if p.ttd < 4 then
        danger = math.max(danger, 90)
    elseif p.ttd < 8 then
        danger = math.max(danger, 65)
    end

    if dtps > (p.healthMax * 0.25) then
        danger = danger + 20
    end

    -- 5. Preemptive Mana Burn Rate & Time-to-OOM (Step 6)
    if p.powerType == 0 or p.powerType == "MANA" then
        self._manaSamples = self._manaSamples or {}
        table.insert(self._manaSamples, { time = now, mana = p.power })
        while #self._manaSamples > 1 and (now - self._manaSamples[1].time) > 5.0 do
            table.remove(self._manaSamples, 1)
        end

        if #self._manaSamples >= 2 then
            local oldest = self._manaSamples[1]
            local dt = now - oldest.time
            local dMana = oldest.mana - p.power
            if dt >= 1.0 and dMana > 0 then
                local mps = dMana / dt
                p.mps = mps
                p.timeToOOM = math.max(0.1, p.power / math.max(1, mps))
            else
                p.mps = 0
                p.timeToOOM = 999
            end
        else
            p.mps = 0
            p.timeToOOM = 999
        end
    else
        p.mps = 0
        p.timeToOOM = 999
    end

    -- 6. Boss Mechanic & Incoming Lethal Damage Scanner (Step 5)
    local DANGEROUS_SPELLS = {
        ["Soul Shriek"] = true, ["Shadow Nova"] = true, ["Whirlwind"] = true,
        ["Defile"] = true, ["Incinerate Flesh"] = true, ["Bone Spike Graveyard"] = true,
        ["Decimate"] = true, ["Bladestorm"] = true, ["Frost Blast"] = true,
        ["Shadow Prison"] = true, ["Unstable Affliction"] = true, ["Pyroblast"] = true,
        ["Lava Burst"] = true, ["Death and Decay"] = true, ["Chilled to the Bone"] = true,
        ["Flame Tsunami"] = true, ["Shadow Bolt Volley"] = true, ["Impale"] = true,
        ["Gushing Wound"] = true, ["Mutated Infection"] = true, ["Festering Strike"] = true
    }

    local incomingThreat = nil
    local unitsToScan = { "target", "focus", "boss1", "boss2" }
    for _, u in ipairs(unitsToScan) do
        if UnitExists(u) and not UnitIsFriend("player", u) then
            local sName, _, _, _, sStart, sEnd = UnitCastingInfo(u)
            if not sName then sName, _, _, _, sStart, sEnd = UnitChannelInfo(u) end
            if sName and (DANGEROUS_SPELLS[sName] or string.find(string.lower(sName), "blast") or string.find(string.lower(sName), "strike") or string.find(string.lower(sName), "smash")) then
                local remCast = sEnd and ((sEnd / 1000) - now) or 0
                if remCast > 0 and remCast <= 2.5 then
                    incomingThreat = {
                        spell = sName,
                        unit = u,
                        remaining = remCast,
                        danger = 95
                    }
                    break
                end
            end
        end
    end
    self.state.incomingThreat = incomingThreat
    if incomingThreat then
        danger = math.max(danger, 90)
    end

    -- 7. Group Threat & Aggro Threshold Monitoring (Phase 2)
    local inGroup = (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
    local userRole = (FC.db and FC.db.playerRole) or "DPS"
    self.state.inGroup = inGroup
    self.state.playerRole = userRole

    local isThreatMonitoringActive = inGroup and (userRole ~= "Tank" and userRole ~= "Solo")
    self.state.isThreatMonitoringActive = isThreatMonitoringActive

    local hasHighThreat = false
    local threatPercent = 0
    if isThreatMonitoringActive and t.exists and t.hostile and not t.dead and UnitExists("target") then
        local isTanking, status, threatPct = UnitDetailedThreatSituation("player", "target")
        if threatPct then threatPercent = threatPct end
        if status and (status == 3 or (threatPct and threatPct >= 90)) then
            hasHighThreat = true
            danger = math.max(danger, 88)
        end
    end
    self.state.highThreat = hasHighThreat
    self.state.threatPercent = threatPercent

    self.state.dangerLevel = math.min(100, math.max(0, danger))
end

-- =====================================================
-- SIMULATION & OUT-OF-COMBAT TEST SUITE
-- =====================================================
function FC:StartSimulation(mode)
    mode = string.lower(mode or "single")
    self.simulationActive = true
    self.simulationMode = mode
    self.simulationExpiry = GetTime() + 45 -- Auto-expires in 45s
    self.simStartTime = GetTime()
    self.simNextCast = GetTime() + 1.5
    self.simDotExpiry = GetTime() + (mode == "dot" and 4.5 or 8.0)

    self.state.flamestrike_r9_expiry = (mode == "aoe") and 0 or nil
    self.state.flamestrike_r8_expiry = (mode == "aoe") and 0 or nil

    -- Initialize Session Performance Tracking
    self.combatSession = {
        inCombat = true,
        startTime = GetTime(),
        actionsCast = 0,
        optimalActions = 0,
        earlyClips = 0,
        isSimulation = true
    }

    self:Print("=== COMBAT SIMULATION STARTED: [" .. string.upper(mode) .. "] ===")
    self:Print("Real-time animated combat simulation active. Auto-ends in 45s or type /fc sim stop.")

    self:UpdateState(true)
    if self.RunEngine then
        self:RunEngine(true)
    end
end

function FC:StopSimulation()
    if self.combatSession and self.combatSession.inCombat then
        local dur = GetTime() - (self.combatSession.startTime or GetTime())
        local total = math.max(1, self.combatSession.actionsCast or 1)
        local opt = self.combatSession.optimalActions or total
        local score = (opt / total) * 100

        local report = {
            duration = dur,
            total = total,
            optimal = opt,
            score = score,
            earlyClips = self.combatSession.earlyClips or 0
        }
        self.combatSession.lastReport = report
        self.combatSession.inCombat = false

        self:Print(string.format("=== SIMULATION PERFORMANCE: |cffffd700%.1f%% Optimal|r (%.0fs session) ===", score, dur))
        self:Print(string.format("  Actions: |cff55ff55%d/%d|r Recommended | Early DoT Clips: |cffff8800%d|r", opt, total, report.earlyClips))
    end

    self.simulationActive = false
    self.simStartTime = nil
    self.simNextCast = nil
    self.simDotExpiry = nil
    self.state.flamestrike_r9_expiry = nil
    self.state.flamestrike_r8_expiry = nil
    self:Print("Combat simulation stopped. Returned to live combat state.")
    self:UpdateState(true)
    if self.RunEngine then
        self:RunEngine(true)
    end
end

-- =====================================================
-- MAIN STATE UPDATE
-- =====================================================
function FC:UpdateState(force)
    local now = GetTime()

    -- Check simulation timeout
    if FC.simulationActive and now > FC.simulationExpiry then
        FC:StopSimulation()
        return
    end

    -- If in Simulation Mode, apply real-time progressing combat state
    if FC.simulationActive then
        local mode = FC.simulationMode or "single"
        local p = FC.state.player
        local t = FC.state.target

        -- Advance simulated player casts
        if not FC.simNextCast then FC.simNextCast = now + 1.5 end
        if now >= FC.simNextCast then
            local hero = (FC.timeline and FC.timeline.queue and FC.timeline.queue[1])
            local castTime = 1.5
            if hero then
                castTime = math.max(1.0, hero.castTime or 1.5)
                if FC.combatSession and FC.combatSession.inCombat then
                    FC.combatSession.actionsCast = (FC.combatSession.actionsCast or 0) + 1
                    FC.combatSession.optimalActions = (FC.combatSession.optimalActions or 0) + 1
                end

                if hero.role == "dot" or hero.name == "Living Bomb" or hero.name == "Corruption" or hero.name == "Vampiric Touch" or hero.name == "Moonfire" or hero.name == "Flame Shock" then
                    FC.simDotExpiry = now + 12.0
                elseif hero.name == "Flamestrike" then
                    FC.state.flamestrike_r9_expiry = now + 8.0
                elseif hero.name == "Flamestrike (Rank 8)" then
                    FC.state.flamestrike_r8_expiry = now + 8.0
                end
            end
            FC.simNextCast = now + castTime
        end

        p.health = 10000
        p.healthMax = 10000
        p.healthPct = (mode == "emergency") and 20 or 100
        p.power = 15000
        p.powerMax = 15000
        p.powerPct = 100
        p.powerType = 0
        p.comboPoints = (FC.playerClass == "ROGUE" or FC.playerClass == "DRUID") and 5 or 0

        p.buffs = p.buffs or {}
        p.debuffs = p.debuffs or {}

        if mode == "proc" then
            if FC.playerClass == "MAGE" then
                p.buffs["Hot Streak"] = { count = 1, remaining = 8.0, duration = 10 }
                p.buffs["Molten Armor"] = { count = 1, remaining = 1800, duration = 1800 }
                p.buffs["Arcane Intellect"] = { count = 1, remaining = 1800, duration = 1800 }
            elseif FC.playerClass == "WARLOCK" then
                p.buffs["Decimation"] = { count = 1, remaining = 8.0, duration = 10 }
                p.buffs["Fel Armor"] = { count = 1, remaining = 1800, duration = 1800 }
            elseif FC.playerClass == "DEATHKNIGHT" then
                p.buffs["Killing Machine"] = { count = 1, remaining = 8.0, duration = 10 }
                p.buffs["Horn of Winter"] = { count = 1, remaining = 120, duration = 120 }
            elseif FC.playerClass == "WARRIOR" then
                p.buffs["Taste for Blood"] = { count = 1, remaining = 8.0, duration = 10 }
                p.buffs["Battle Shout"] = { count = 1, remaining = 120, duration = 120 }
            elseif FC.playerClass == "PALADIN" then
                p.buffs["The Art of War"] = { count = 1, remaining = 8.0, duration = 10 }
                p.buffs["Greater Blessing of Kings"] = { count = 1, remaining = 1800, duration = 1800 }
            end
        elseif mode == "single" or mode == "dot" or mode == "debuff" then
            if FC.playerClass == "MAGE" then
                p.buffs["Molten Armor"] = { count = 1, remaining = 1800, duration = 1800 }
                p.buffs["Arcane Intellect"] = { count = 1, remaining = 1800, duration = 1800 }
            end
        end

        t.exists = true
        t.hostile = true
        t.attackable = true
        t.dead = false
        t.health = (mode == "execute") and 15000 or 850000
        t.healthMax = 1000000
        t.healthPct = (mode == "execute") and 15 or 85
        t.classification = "worldboss"
        t.isBoss = true
        t.creatureType = "Dragonkin"
        t.ttd = 120

        t.debuffs = {}
        t.buffs = {}

        -- Live Real-time DoT countdown
        local dotRemaining = math.max(0, (FC.simDotExpiry or (now + 4.5)) - now)
        if dotRemaining > 0 then
            if FC.playerClass == "MAGE" then
                t.debuffs["Living Bomb"] = { count = 1, remaining = dotRemaining, duration = 12, mine = true }
            elseif FC.playerClass == "WARLOCK" then
                t.debuffs["Corruption"] = { count = 1, remaining = dotRemaining, duration = 18, mine = true }
            elseif FC.playerClass == "PRIEST" then
                t.debuffs["Vampiric Touch"] = { count = 1, remaining = dotRemaining, duration = 15, mine = true }
            elseif FC.playerClass == "DRUID" then
                t.debuffs["Moonfire"] = { count = 1, remaining = dotRemaining, duration = 12, mine = true }
            elseif FC.playerClass == "SHAMAN" then
                t.debuffs["Flame Shock"] = { count = 1, remaining = dotRemaining, duration = 18, mine = true }
            end
        end

        if FC.playerClass == "MAGE" then
            t.debuffs["Ignite"] = { count = 1, remaining = 6.0, duration = 6, mine = true }
        end

        if mode == "interrupt" then
            t.isCasting = true
            t.castSpellName = "Shadow Bolt"
            t.castRemaining = 1.4
            t.interruptible = true
        else
            t.isCasting = false
            t.interruptible = false
        end

        FC.state.inCombat = true
        FC.state.engaged = true
        FC.state.readyToEngage = false
        FC.state.isIdle = false
        FC.state.enemyCount = (mode == "aoe") and 4 or 1
        FC.state.dangerLevel = (mode == "emergency") and 90 or 0
        FC.state.phase = (mode == "emergency") and "emergency" or (mode == "execute" and "execute" or "combat")

        self:UpdatePlayerStats()
        if self.GetGCDRemaining then
            FC.state.gcdRemaining = self:GetGCDRemaining()
        end
        return
    end

    if not force and (now - (FC._lastStateUpdate or 0)) < 0.05 then
        return
    end
    FC._lastStateUpdate = now

    local targetExists = (UnitExists("target") and true) or false
    local inCombat = (UnitAffectingCombat("player") and true) or false
    local canAttack = targetExists and ((UnitCanAttack("player", "target") and true) or false)
    local isDead = targetExists and ((UnitIsDeadOrGhost("target") and true) or false)

    -- Target Flags
    FC.state.target.exists = targetExists
    FC.state.target.attackable = canAttack
    FC.state.target.hostile = canAttack
    FC.state.target.dead = isDead
    FC.state.target.name = targetExists and (UnitName("target") or "Unknown") or "None"
    FC.state.target.guid = targetExists and UnitGUID("target") or nil

    -- Core Combat Flags
    FC.state.inCombat = inCombat
    FC.state.engaged = (targetExists and canAttack and not isDead and inCombat)
    FC.state.readyToEngage = (targetExists and canAttack and not isDead and not inCombat)
    FC.state.isIdle = (not inCombat and (not targetExists or not canAttack or isDead))

    -- Opener detection
    FC.state.hasJustEngaged = false
    if FC.state.engaged and not FC._wasEngaged then
        FC.state.hasJustEngaged = true
    end
    FC._wasEngaged = FC.state.engaged

    -- Supporting Data
    self:UpdatePlayerAuras()
    self:UpdateTargetAuras()
    self:UpdatePlayerCastState()
    self:UpdateTargetCastState()
    self:UpdateVitals()
    self:UpdatePlayerStats()
    self:UpdateActiveEnemies()
    self:UpdateCombatMetrics()

    -- Phase Machine
    local emergencyHP = (FC.db and FC.db.minHealthEmergency) or 35
    if inCombat then
        if FC.state.player.healthPct <= emergencyHP or FC.state.dangerLevel >= 75 then
            FC.state.phase = "emergency"
        elseif FC.state.engaged and FC.state.hasJustEngaged then
            FC.state.phase = "opener"
        elseif FC.state.engaged and FC.state.target.healthPct <= 20 then
            FC.state.phase = "execute"
        else
            FC.state.phase = "combat"
        end
    else
        if FC.state.readyToEngage then
            FC.state.phase = "ready"
        else
            FC.state.phase = "idle"
        end
    end

    if self.GetGCDRemaining then
        FC.state.gcdRemaining = self:GetGCDRemaining()
    end
end
