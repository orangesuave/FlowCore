local FC = FlowCore

function FC:FormatNumber(n)
    n = tonumber(n) or 0
    if n >= 1000000 then
        return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fk", n / 1000)
    else
        return tostring(math.floor(n))
    end
end

-- =====================================================
-- DAMAGE REPORTING & WHISPER HELPERS
-- =====================================================
function FC:GetTopDamageReport(limit)
    limit = limit or 5
    if not self.actions or #self.actions <= 2 then
        if self.ScanSpellbook then self:ScanSpellbook(true) end
    end
    local spellList = {}
    local seenNames = {}
    for _, action in ipairs(self.actions or {}) do
        local aName = action.name or action.spellName
        local isDamageRole = (action.role == "nuke" or action.role == "dot" or action.role == "aoe" or action.role == "spender" or action.role == "execute")
        local isKnownDamageSpell = self.SPELL_DAMAGE_DATABASE and self.SPELL_DAMAGE_DATABASE[aName]

        if aName and action.actionType == "spell" and (isDamageRole or isKnownDamageSpell) and not seenNames[aName] then
            seenNames[aName] = true
            local expDmg, modDmg, crit = 0, 0, 0
            if self.CalculateExpectedDamage then
                local ok, ed, md, cr = pcall(self.CalculateExpectedDamage, self, action, self.state)
                if ok then
                    expDmg, modDmg, crit = ed or 0, md or 0, cr or 0
                end
            end

            local execTime, effCast = 1.5, 0
            if self.CalculateExecutionTime then
                local ok, et, ec = pcall(self.CalculateExecutionTime, self, action, self.state)
                if ok then
                    execTime, effCast = et or 1.5, ec or 0
                end
            end

            local dpct = (tonumber(expDmg) or 0) / math.max(0.05, tonumber(execTime) or 1.5)
            local pCost = tonumber(action.powerCost) or 0
            local dpm = (pCost > 0) and ((tonumber(expDmg) or 0) / pCost) or (tonumber(expDmg) or 0)

            table.insert(spellList, {
                name = tostring(aName),
                role = tostring(action.role or "nuke"),
                school = tostring(action.school or (isKnownDamageSpell and isKnownDamageSpell.school) or "Physical"),
                expDmg = tonumber(expDmg) or 0,
                execTime = tonumber(execTime) or 1.5,
                effCast = tonumber(effCast) or 0,
                dpct = tonumber(dpct) or 0,
                dpm = tonumber(dpm) or 0,
                crit = tonumber(crit) or 0
            })
        end
    end

    table.sort(spellList, function(a, b) return (a.dpct or 0) > (b.dpct or 0) end)

    local top = {}
    for i = 1, math.min(limit, #spellList) do
        table.insert(top, spellList[i])
    end
    return top, spellList
end

function FC:WhisperDamageReport(targetPlayer, limit)
    limit = limit or 5
    targetPlayer = string.gsub(targetPlayer or "", "^%s*(.-)%s*$", "%1")
    -- Strip level prefix like "80:Culait" -> "Culait"
    if string.find(targetPlayer, ":") then
        targetPlayer = string.match(targetPlayer, ":(%S+)") or targetPlayer
    end

    if targetPlayer == "target" or targetPlayer == "%t" or targetPlayer == "" then
        if UnitExists("target") and UnitIsPlayer("target") then
            targetPlayer = UnitName("target")
        end
    end

    if not targetPlayer or targetPlayer == "" then
        self:Print("Usage: /fc damage <player> or /fc whisper <player> (e.g. /fc damage Brunton)")
        return false
    end

    local topSpells, allSpells = self:GetTopDamageReport(limit)
    if #topSpells == 0 then
        self:Print("No damage spells found to report.")
        return false
    end

    local spec = (self.talents and self.talents.primarySpec) or "DPS"

    -- Synchronous delivery directly within the user command context
    SendChatMessage(string.format("FlowCore Top %d Spells (%s):", #topSpells, tostring(spec)), "WHISPER", nil, targetPlayer)

    for i, s in ipairs(topSpells) do
        local line = string.format("%d. %s (%s): %.0f Dmg - %.0f DPCT - %.1fs Cast",
            tonumber(i) or 1,
            tostring(s.name or "Spell"),
            tostring(s.school or "Magic"),
            tonumber(s.expDmg) or 0,
            tonumber(s.dpct) or 0,
            tonumber(s.effCast) or 0)
        SendChatMessage(line, "WHISPER", nil, targetPlayer)
    end

    self:Print(string.format("Whispered top %d damage abilities to |cffffd700%s|r.", #topSpells, targetPlayer))
    return true
end

function FC:PrintGCD()
    local base = (self.playerClass == "ROGUE" or self.playerClass == "CAT") and 1.0 or (self.baseGCD or 1.5)
    local hasteMult, hastePct = 1.0, 0
    if self.GetHasteMultiplier then
        hasteMult, hastePct = self:GetHasteMultiplier()
    end
    local effGCD = (self.GetEffectiveGCD and self:GetEffectiveGCD()) or math.max(0.0, base / hasteMult)
    local gcdRem = (self.GetGCDRemaining and self:GetGCDRemaining()) or 0
    local lagWin = (self.GetLatencyWindow and self:GetLatencyWindow()) or 0.250

    self:Print("=== GCD & HASTE DIAGNOSTICS ===")
    self:Print(string.format("  Base GCD: |cff00ccff%.2fs|r | Haste: |cffffd700%.1f%% (%.3fx)|r", base, hastePct or 0, hasteMult or 1))
    self:Print(string.format("  Effective GCD: |cff55ff55%.3fs|r | Current Rem: |cffff8800%.3fs|r", effGCD, gcdRem))
    self:Print(string.format("  Queue Window: |cff00ffcc%.0fms|r", lagWin * 1000))
end

SLASH_FLOWCORE1 = "/fc"
SLASH_FLOWCORE2 = "/flowcore"

SlashCmdList["FLOWCORE"] = function(msg)
    msg = msg or ""
    local cmd, arg = string.match(msg, "^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")
    arg = arg or ""

    if cmd == "config" or cmd == "opt" or cmd == "options" or cmd == "settings" then
        if FC.ToggleConfigUI then
            FC:ToggleConfigUI()
        end
    elseif cmd == "minimap" or cmd == "mm" or cmd == "map" then
        FC.db.showMinimapButton = not FC.db.showMinimapButton
        if FC.UpdateMinimapButtonVisibility then FC:UpdateMinimapButtonVisibility() end
        FC:Print("Minimap button visibility: " .. (FC.db.showMinimapButton and "|cff55ff55ENABLED|r" or "|cffff2222DISABLED|r"))
    elseif cmd == "test" or cmd == "sim" then
        local subCmd = string.lower(arg or "")
        if subCmd == "stop" or subCmd == "off" then
            FC:StopSimulation()
        else
            local mode = (subCmd == "" and "single") or subCmd
            FC:StartSimulation(mode)
        end

    elseif cmd == "style" or cmd == "view" or cmd == "mode" then
        local style = string.lower(arg or "")
        if style == "tracks" or style == "track" or style == "eventhorizon" or style == "eh" then
            FC.db.timelineStyle = "tracks"
            FC:Print("Timeline view mode set to: |cffffd700EVENTHORIZON MULTI-TRACK|r")
        elseif style == "icons" or style == "icon" or style == "simple" then
            FC.db.timelineStyle = "icons"
            FC:Print("Timeline view mode set to: |cffffd700ICON SEQUENCE|r")
        else
            FC.db.timelineStyle = (FC.db.timelineStyle == "icons") and "tracks" or "icons"
            FC:Print("Timeline view mode toggled to: |cffffd700" .. string.upper(FC.db.timelineStyle) .. "|r")
        end

    elseif cmd == "best" then
        local action, score = FC:GetBestAction(FC.state)
        if action then
            FC:Print("Best Action: " .. FC.COLORS.SUCCESS .. action.name .. "|r (Score: " .. string.format("%.1f", score or 0) .. " | Role: " .. tostring(action.role) .. ")")
        else
            FC:Print("No action currently available.")
        end

    elseif cmd == "check" then
        FC:CheckEngine()

    elseif cmd == "stats" then
        if FC.UpdatePlayerStats then FC:UpdatePlayerStats() end
        local p = FC.state.player or {}
        local s = p.stats or {}
        local sp = s.spellPower or {}
        local sets = p.setBonuses or {}
        local forges = p.forges or {}

        FC:Print("=== PLAYER STATS & COMBAT SCALING ===")
        FC:Print(string.format("  Attributes: Str %d | Agi %d | Sta %d | Int %d | Spi %d",
            s.strength or 0, s.agility or 0, s.stamina or 0, s.intellect or 0, s.spirit or 0))
        FC:Print(string.format("  Weapon: %.1f-%.1f (Avg: %.1f) | Speed: MH %.2fs / OH %.2fs | Ranged: %.2fs",
            s.weaponMinDamage or 0, s.weaponMaxDamage or 0, s.weaponAvgDamage or 0,
            s.mainHandSpeed or 2.0, s.offHandSpeed or 0, s.rangedSpeed or 0))
        FC:Print(string.format("  Attack Power: %d (Ranged: %d) | ArP: %d | Expertise: %d (%.1f%%)",
            s.attackPower or 0, s.rangedAttackPower or 0, s.armorPen or 0, s.expertise or 0, s.expertisePct or 0))
        FC:Print(string.format("  Spell Power: Max %d (Fire: %d, Frost: %d, Arcane: %d, Shadow: %d, Holy: %d, Heal: %d)",
            sp.Max or 0, sp.Fire or 0, sp.Frost or 0, sp.Arcane or 0, sp.Shadow or 0, sp.Holy or 0, sp.Healing or 0))
        FC:Print(string.format("  Crit: Spell %.1f%% | Melee %.1f%% | Ranged %.1f%%",
            s.spellCrit or 0, s.meleeCrit or 0, s.rangedCrit or 0))
        FC:Print(string.format("  Haste: Spell %.1f%% | Melee %.1f%% | Hit: Spell +%.1f%% / Melee +%.1f%%",
            s.spellHaste or 0, s.meleeHaste or 0, s.spellHit or 0, s.meleeHit or 0))
        FC:Print(string.format("  Defense: Armor %d | Dodge %.1f%% | Parry %.1f%% | Block %.1f%% (Value: %d) | Resil: %d",
            s.armor or 0, s.dodge or 0, s.parry or 0, s.block or 0, s.blockValue or 0, s.resilience or 0))
        if FC.playerClass == "ROGUE" or FC.playerClass == "DRUID" then
            FC:Print(string.format("  Combo Points: %d/5", p.comboPoints or 0))
        end
        local setList = {}
        if (sets.T10 or 0) > 0 then table.insert(setList, "T10=" .. sets.T10 .. "pc") end
        if (sets.T9 or 0) > 0 then table.insert(setList, "T9=" .. sets.T9 .. "pc") end
        if (sets.T8 or 0) > 0 then table.insert(setList, "T8=" .. sets.T8 .. "pc") end
        if (sets.T7 or 0) > 0 then table.insert(setList, "T7=" .. sets.T7 .. "pc") end
        if (sets.T6 or 0) > 0 then table.insert(setList, "T6=" .. sets.T6 .. "pc") end
        if (sets.T5 or 0) > 0 then table.insert(setList, "T5=" .. sets.T5 .. "pc") end
        if (sets.T4 or 0) > 0 then table.insert(setList, "T4=" .. sets.T4 .. "pc") end
        if (sets.T3 or 0) > 0 then table.insert(setList, "T3=" .. sets.T3 .. "pc") end
        if (sets.T2_5 or 0) > 0 then table.insert(setList, "T2.5=" .. sets.T2_5 .. "pc") end
        if (sets.T2 or 0) > 0 then table.insert(setList, "T2=" .. sets.T2 .. "pc") end
        if (sets.T1 or 0) > 0 then table.insert(setList, "T1=" .. sets.T1 .. "pc") end
        if (sets.D1 or 0) > 0 then table.insert(setList, "D1/D2=" .. sets.D1 .. "pc") end
        if (sets.D3 or 0) > 0 then table.insert(setList, "D3=" .. sets.D3 .. "pc") end
        local setStr = (#setList > 0) and table.concat(setList, ", ") or "None"
        FC:Print(string.format("  Tier Sets (Classic/TBC/WotLK): %s", setStr))
        if forges.totalDamageBonus and forges.totalDamageBonus > 0 then
            FC:Print(string.format("  Attunements/Forges: +%.1f%% Damage (Titan: %d, War: %d, Light: %d)",
                forges.totalDamageBonus * 100, forges.titanforged or 0, forges.warforged or 0, forges.lightforged or 0))
        end

    elseif cmd == "gcd" or cmd == "haste" or cmd == "speed" then
        FC:PrintGCD()

    elseif cmd == "synergies" or cmd == "synergy" or cmd == "prereqs" or cmd == "rules" then
        FC:Print("=== ACTIVE CROSS-SPELL SYNERGY & PREREQUISITE RULES ===")
        local report = (FC.GetActiveSynergyReport and FC:GetActiveSynergyReport()) or {}
        local count = 0
        for _, rule in ipairs(report) do
            count = count + 1
            local enList = {}
            for eName, _ in pairs(rule.enablers or {}) do table.insert(enList, eName) end
            local enStr = (#enList > 0) and table.concat(enList, "/") or "Multi-Hit/DoT"
            FC:Print(string.format("  %d. |cffffd700%s|r -> |cff00ccff[%s]|r: %s", count, enStr, rule.requiredFor or "Synergy", rule.desc or ""))
        end
        if count == 0 then
            FC:Print("No active class cross-spell synergy rules detected for current spec.")
        else
            FC:Print(string.format("Total active synergy prerequisite rules: |cff00ccff%d|r", count))
        end

    elseif cmd == "empirical" or cmd == "calibrate" or cmd == "samples" then
        FC:Print("=== EMPIRICAL COMBAT LOG SELF-LEARNING SAMPLES ===")
        local samples = FC.empiricalSamples or {}
        local count = 0
        for sName, s in pairs(samples) do
            count = count + 1
            local critPct = (s.hits > 0) and (s.crits / s.hits * 100) or 0
            FC:Print(string.format("  |cffffd700%s|r: %d hits (%d crits, %.0f%%) | Avg NonCrit: |cff55ff55%.0f|r | Avg Crit: |cffff8800%.0f|r | Min/Max: %.0f/%.0f",
                sName, s.hits, s.crits, critPct, s.avgNonCrit, s.avgCrit, (s.minHit < 999999 and s.minHit or 0), s.maxHit))
        end
        if count == 0 then
            FC:Print("No empirical combat samples recorded yet. Cast spells in combat to train self-learning calibration.")
        else
            FC:Print(string.format("Total empirical spell profiles calibrated: |cff00ccff%d|r", count))
        end

    elseif cmd == "ttd" or cmd == "threat" then
        if FC.UpdateState then FC:UpdateState(true) end
        local t = FC.state.target or {}
        local p = FC.state.player or {}
        local tName = (t.name and t.name ~= "None" and t.name) or (UnitExists("target") and UnitName("target")) or "None"
        local tHp = t.health or (UnitExists("target") and UnitHealth("target")) or 0
        local tHpMax = t.healthMax or (UnitExists("target") and UnitHealthMax("target")) or 1
        local tHpPct = (tHp / math.max(1, tHpMax)) * 100

        FC:Print("=== TARGET TTD & INCOMING THREAT DIAGNOSTICS ===")
        FC:Print(string.format("  Target: |cffffd700%s|r | Health: |cff55ff55%s|r / %s (|cff00ccff%.1f%%|r)", tostring(tName), FC:FormatNumber(tHp), FC:FormatNumber(tHpMax), tHpPct))
        if t.ttd and t.ttd < 900 then
            FC:Print(string.format("  Target TTD: |cff00ccff%.1f seconds|r | Target Incoming DPS: |cffff8800%.0f|r", t.ttd, t.dps or 0))
        else
            FC:Print("  Target TTD: |cff888888Target is at steady HP (no damage taken yet)|r")
        end
        FC:Print(string.format("  Player Time-to-OOM: |cff00ffcc%.1fs|r | Burn Rate: %.1f MPS", p.timeToOOM or 999, p.mps or 0))
        if FC.state.incomingThreat then
            local inc = FC.state.incomingThreat
            FC:Print(string.format("  |cffff2222★ INCOMING BOSS THREAT:|r |cffffd700%s|r (%.1fs remaining) from %s", inc.spell, inc.remaining, inc.unit))
        else
            FC:Print("  Incoming Boss Threat: |cff55ff55None detected|r")
        end

    elseif cmd == "forges" or cmd == "forge" or cmd == "attune" or cmd == "attunement" then
        local forges = (FC.ScanAttunementsAndForges and FC:ScanAttunementsAndForges()) or {}
        FC:Print("=== SYNASTRIA FORGED GEAR & ATTUNEMENT SCALING ===")
        FC:Print(string.format("  Attuned Gear: |cff55ff55%d/18 pieces|r | Mythic Gear: |cffff8800%d pieces|r", forges.totalAttuned or 0, forges.totalMythic or 0))
        FC:Print(string.format("  Lightforged (+2.0%%/pc): |cff55ff55%d pieces|r", forges.lightforged or 0))
        FC:Print(string.format("  Warforged   (+3.5%%/pc): |cff00ccff%d pieces|r", forges.warforged or 0))
        FC:Print(string.format("  Titanforged (+5.0%%/pc): |cffffd700%d pieces|r", forges.titanforged or 0))
        FC:Print(string.format("  Total Forged Multiplier: |cffff8800+%.1f%% Global Damage/Stat Bonus|r", (forges.totalDamageBonus or 0) * 100))
        if forges.pieces and #forges.pieces > 0 then
            for _, p in ipairs(forges.pieces) do
                local col = (p.type == "Titanforged" and "|cffffd700") or (p.type == "Warforged" and "|cff00ccff") or (p.type == "Lightforged" and "|cff55ff55") or (p.type == "Mythic" and "|cffff8800") or "|cff00ccff"
                local attStr = p.attuned and " [Attuned]" or ""
                FC:Print(string.format("    - %s[%s%s]|r: %s", col, p.type, attStr, p.name))
            end
        end

    elseif cmd == "damage" or cmd == "dpct" or cmd == "calc" then
        local whisperTarget = string.match(arg or "", "^whisper%s+(%S+)") or string.match(arg or "", "^to%s+(%S+)")
        if not whisperTarget and arg ~= "" and arg ~= "all" and arg ~= "full" and arg ~= "self" then
            whisperTarget = string.match(arg, "^(%S+)")
        end

        if whisperTarget then
            FC:WhisperDamageReport(whisperTarget, 5)
        else
            FC:Print("=== LIVE SPELL DAMAGE & DPCT SIMULATION ===")
            local top, spellList = FC:GetTopDamageReport(50)
            for i, s in ipairs(spellList) do
                FC:Print(string.format("%d. |cffffd700%s|r (|cff00ccff%s|r) -> Expected: |cff55ff55%.0f|r | Cast: %.1fs (Exec: %.1fs) | |cffff8800DPCT: %.0f|r | DPM: %.1f | Crit: %.1f%%",
                    i, s.name, s.school, s.expDmg, s.effCast, s.execTime, s.dpct, s.dpm, s.crit * 100))
            end
            if #spellList == 0 then
                FC:Print("No rotational damage spells registered.")
            end
        end

    elseif cmd == "caps" or cmd == "hit" or cmd == "exp" or cmd == "statcaps" then
        local mode = string.lower(arg or "")
        local isMythic = (mode == "mythic" or mode == "m")
        local reports = (FC.AnalyzeStatCaps and FC:AnalyzeStatCaps(mode)) or {}
        local specName = (FC.GetActiveSpecName and FC:GetActiveSpecName()) or "Active Spec"
        FC:Print(string.format("=== STAT CAP & COMBAT RATINGS AUDIT: [%s] (%s MODE) ===", specName, isMythic and "MYTHIC DUNGEON" or "NORMAL/RAID"))
        for _, r in ipairs(reports) do
            FC:Print(string.format("  - |cffffd700%s|r: %s -> %s %s%s", r.name, r.current, r.target, r.status, r.detail or ""))
        end
        if not isMythic then
            FC:Print("  |cff888888Tip: Type '/fc caps mythic' to audit against Mythic Dungeon boss suppression caps (e.g. 700% crit requirement).|r")
        end

    elseif cmd == "weights" or cmd == "statweights" then
        local specName = (FC.GetActiveSpecName and FC:GetActiveSpecName()) or "Active Spec"
        local w = (FC.GetStatWeights and FC:GetStatWeights(specName)) or {}
        FC:Print("=== RELATIVE STAT WEIGHTS & DPS VALUES: [" .. specName .. "] ===")
        local wList = {}
        for stat, val in pairs(w) do
            table.insert(wList, string.format("|cffffd700%s|r: |cff55ff55%.2f|r", stat, val))
        end
        FC:Print("  " .. table.concat(wList, " | "))
        FC:Print("  |cff888888Stat weights represent DPS gain per 1 point of stat. Use for gemming and enchanting priority.|r")

    elseif cmd == "gearcheck" or cmd == "gear" or cmd == "enchants" or cmd == "gems" then
        local audit = (FC.AuditEquippedGear and FC:AuditEquippedGear()) or {}
        local specName = (FC.GetActiveSpecName and FC:GetActiveSpecName()) or "Active Spec"
        FC:Print("=== EQUIPPED GEAR, ENCHANT & GEM AUDIT: [" .. specName .. "] ===")
        FC:Print(string.format("  Equipped Gear Score: |cffffd700%.1f PTS|r", audit.score or 0))
        if audit.totalEmptySockets and audit.totalEmptySockets > 0 then
            FC:Print(string.format("  |cffff2222★ Empty Gem Sockets: %d socket(s) need gems!|r", audit.totalEmptySockets))
        else
            FC:Print("  Gem Sockets: |cff55ff55All sockets fully gemmed.|r")
        end
        if audit.missingEnchants and #audit.missingEnchants > 0 then
            FC:Print(string.format("  |cffff8800★ Missing Enchants: %d slot(s) un-enchanted:|r", #audit.missingEnchants))
            for _, e in ipairs(audit.missingEnchants) do
                FC:Print(string.format("    - |cffffd700%s|r: %s", e.slotName, e.itemName))
            end
        else
            FC:Print("  Enchants: |cff55ff55All major slots fully enchanted (Multi-Profession verified).|r")
        end

    elseif cmd == "upgrades" or cmd == "bagcheck" or cmd == "bank" or cmd == "mail" then
        local specName = (FC.GetActiveSpecName and FC:GetActiveSpecName()) or "Active Spec"
        FC:Print("=== BAGS, BANK & MAIL EQUIPPABLE UPGRADE FINDER: [" .. specName .. "] ===")
        local upgrades = (FC.ScanBagsBankMailForUpgrades and FC:ScanBagsBankMailForUpgrades(specName)) or {}
        if #upgrades == 0 then
            FC:Print("  |cff55ff55No higher-scoring equippable items found in Bags, Bank, or Mail. Your equipped gear is optimal!|r")
        else
            FC:Print(string.format("  Discovered |cff00ccff%d|r equippable upgrade candidates (Trinket procs & affixes modeled):", #upgrades))
            for i, u in ipairs(upgrades) do
                FC:Print(string.format("  %d. |cffffd700%s|r (|cff00ffcc%s|r from %s) -> |cff55ff55+%.1f PTS (+%.1f%%)|r (Score: %.1f vs Equipped: %.1f)",
                    i, u.name, u.slotName, u.source, u.gain, u.gainPct, u.candScore, u.curScore))
            end
        end

    elseif cmd == "build" or cmd == "tree" or cmd == "talents" then
        local specName = (FC.GetActiveSpecName and FC:GetActiveSpecName()) or "Active Spec"
        local syn = (FC.OpenTalentBuildAdvisor and FC:OpenTalentBuildAdvisor(specName)) or (FC.AnalyzeBuildSynergies and FC:AnalyzeBuildSynergies(specName)) or {}
        local pts = syn.tabPoints or { [1] = 0, [2] = 0, [3] = 0 }
        FC:Print(string.format("=== FULL TALENT, PERK & GLYPH BUILD COMPARISON: [%s] ===", specName))
        FC:Print(string.format("  Talent Tree Distribution: |cffffd700%d|r / |cffffd700%d|r / |cffffd700%d|r", pts[1] or 0, pts[2] or 0, pts[3] or 0))

        FC:Print("|cff00ccff--- 1. Keystone Talent Synergies ---|r")
        for _, t in ipairs(syn.talents or {}) do
            FC:Print(string.format("  %s |cffffd700%s|r: %s", t.status, t.name, t.desc))
        end

        FC:Print("|cff00ccff--- 2. Active Perks & Recommendations by Synastria Categories ---|r")
        for _, p in ipairs(syn.perks or {}) do
            FC:Print(string.format("  %s |cffffd700%s (%d/%d):|r %s%s", p.status, p.category, p.count, p.max, p.perksStr, p.recommendationStr or ""))
        end

        FC:Print("|cff00ccff--- 3. Active Perk Prerequisites & Talent Dependencies ---|r")
        if syn.perkPrerequisites and #syn.perkPrerequisites > 0 then
            for _, req in ipairs(syn.perkPrerequisites) do
                FC:Print(string.format("  %s |cffffd700%s|r: %s", req.status, req.name, req.desc))
            end
        else
            FC:Print("  |cff55ff55[PREREQS MET]|r |cffffd700Active Perks Synchronized|r: All active perk prerequisites & talent synergies satisfied.")
        end

        FC:Print("|cff00ccff--- 4. Equipped Glyphs ---|r")
        for _, g in ipairs(syn.glyphs or {}) do
            FC:Print(string.format("  %s |cffffd700%s|r: %s", g.status, g.name, g.desc))
        end

        FC:Print("|cff00ccff--- 5. Simulation Benchmarks (Optimal Rotation, Cooldowns & Survivability) ---|r")
        local sims = (FC.RunSimulationBenchmarks and FC:RunSimulationBenchmarks(specName)) or { single = 0, cleave = 0, aoe = 0 }
        FC:Print(string.format("  - |cffffd70025H Raid Boss|r [The Lich King - 103.2M HP]: |cff55ff55~%d DPS|r (Optimal Cooldown Cycle, 100%% LB Uptime, Molten Fury Execute)", sims.single or 0))
        FC:Print(string.format("  - |cffffd700Cleave|r [Level 82 Elite Mobs - 3 Targets]: |cff55ff55~%d DPS|r (3x Living Bomb Multi-Dotting + HS Pyroblast Weaving)", sims.cleave or 0))
        FC:Print(string.format("  - |cffffd700Mass AOE|r [6+ Target Trash Pack]: |cff55ff55~%d DPS|r (Rank 9+8 Flamestrike Stacking + Firestarter Instant Casts)", sims.aoe or 0))
        FC:Print(string.format("  - |cffffd700Speed & Movement Uptime|r: |cff00ffcc%s|r", sims.speedRating or "Optimal 1.00s GCD Floor (41yd Range)"))
        FC:Print(string.format("  - |cffffd700Survivability & Threat Headroom|r: |cff00ffcc%s|r", sims.survivabilityRating or "High (-20% Threat, 92% Pushback Immunity, Incanter Shield)"))

    elseif cmd == "approach" or cmd == "focus" then
        local sub = string.lower(arg or "")
        if sub == "st" or sub == "singletarget" or sub == "boss" then
            FC.db.combatApproach = "ST Damage"
        elseif sub == "aoe" or sub == "cleave" or sub == "trash" then
            FC.db.combatApproach = "AOE Damage"
        elseif sub == "survival" or sub == "pvp" or sub == "defensive" or sub == "tank" then
            FC.db.combatApproach = "Survival/PVP"
        elseif sub == "balanced" or sub == "tri" or sub == "default" then
            FC.db.combatApproach = "Balanced"
        else
            local cur = FC.db.combatApproach or "Balanced"
            FC:Print(string.format("Current Combat Approach: |cffffd700[%s]|r", cur))
            FC:Print("Usage: |cff55ff55/fc approach balanced|r | |cffff8800/fc approach st|r | |cff00ccff/fc approach aoe|r | |cffff6666/fc approach survival|r")
            return
        end
        FC:Print(string.format("Combat Approach set to |cffffd700[%s]|r", FC.db.combatApproach))
        if FC.UpdateState then FC:UpdateState() end

    elseif cmd == "role" then
        local sub = string.lower(arg or "")
        if sub == "tank" then
            FC.db.playerRole = "Tank"
        elseif sub == "healer" or sub == "heal" then
            FC.db.playerRole = "Healer"
        elseif sub == "solo" then
            FC.db.playerRole = "Solo"
        elseif sub == "dps" or sub == "damage" then
            FC.db.playerRole = "DPS"
        else
            local cur = FC.db.playerRole or "DPS"
            FC:Print(string.format("Current Player Role: |cffffd700[%s]|r", cur))
            FC:Print("Usage: |cff00ccff/fc role tank|r | |cff55ff55/fc role healer|r | |cffff8800/fc role dps|r | |cffaaaaaa/fc role solo|r")
            return
        end
        FC:Print(string.format("Player Role set to |cffffd700[%s]|r", FC.db.playerRole))
        if FC.UpdateState then FC:UpdateState() end

    elseif cmd == "prep" or cmd == "buffcheck" or cmd == "ready" then
        local ready, warnings = false, {}
        if FC.CheckPreCombatReadiness then ready, warnings = FC:CheckPreCombatReadiness() end
        FC:Print("=== PRE-COMBAT READINESS & RAID BUFF CHECKLIST ===")
        if ready and #warnings == 0 then
            FC:Print("  |cff55ff55★ ALL ESSENTIAL BUFFS ACTIVE - READY FOR COMBAT!|r")
        else
            for _, w in ipairs(warnings) do
                FC:Print("  - " .. w)
            end
            if ready then
                FC:Print("  |cff55ff55Combat essentials met (minor optional consumables missing).|r")
            else
                FC:Print("  |cffff2222★ Warning: Missing core combat essentials! Buff before pulling.|r")
            end
        end

    elseif cmd == "report" or cmd == "log" or cmd == "perf" or cmd == "performance" then
        if arg ~= "" and arg ~= "self" and arg ~= "last" then
            FC:WhisperDamageReport(arg, 5)
        else
            local r = FC.lastCombatReport or (FC.combatSession and FC.combatSession.lastReport)
            if r then
                FC:Print("=== LAST COMBAT PERFORMANCE & ROTATION REPORT ===")
                FC:Print(string.format("  Encounter Duration: |cff00ccff%.1f seconds|r", r.duration or 0))
                if r.grade then
                    FC:Print(string.format("  Rotation Execution Grade: %s[%s] (%.1f%% Optimal)|r", r.gradeCol or "|cff55ff55", r.grade, r.execPct or 0))
                    FC:Print(string.format("  Recommended Casts Followed: |cff55ff55%d/%d|r", r.matchedCasts or 0, r.totalCasts or 0))
                else
                    FC:Print(string.format("  Rotation Efficiency: |cffffd700%.1f%% Optimal|r (|cff55ff55%d/%d|r Recommended Casts)", r.score or 0, r.optimal or 0, r.total or 0))
                end
                if r.dotsClipped and r.dotsClipped > 0 then
                    FC:Print(string.format("  Early DoT Clips: |cffff8800%d|r (Cast closer to final tick)", r.dotsClipped))
                else
                    FC:Print("  DoT Uptime & Refresh: |cff55ff55Zero early DoT clips!|r")
                end
            else
                FC:Print("No recent combat session recorded. Complete a combat encounter to view performance analysis.")
            end
        end

    elseif cmd == "keybinds" or cmd == "keys" or cmd == "binds" then
        FC:Print("=== ACTION BAR & BARTENDER KEYBINDS ===")
        if FC.ScanActionKeybinds then FC:ScanActionKeybinds(true) end
        local count = 0
        local keysList = {}
        for name, key in pairs(FC.keybindCache or {}) do
            if type(name) == "string" then
                table.insert(keysList, { name = name, key = key })
            end
        end
        table.sort(keysList, function(a, b) return a.name < b.name end)

        for _, item in ipairs(keysList) do
            count = count + 1
            FC:Print(string.format("  |cffffd700%s|r -> |cff55ff55[%s]|r", item.name, item.key))
        end

        if count == 0 then
            FC:Print("No action bar keybinds found. Make sure spells/items are placed on your action bars or Bartender buttons.")
        else
            FC:Print(string.format("Total keybound abilities found: |cff00ccff%d|r", count))
        end

    elseif cmd == "sound" or cmd == "audio" then
        FC.db = FC.db or {}
        FC.db.enableSound = not (FC.db.enableSound ~= false)
        FC:Print(string.format("Audio Proc & Emergency Cues: %s", FC.db.enableSound and "|cff55ff55ENABLED|r" or "|cffff2222DISABLED|r"))

    elseif cmd == "screenglow" or cmd == "flash" then
        FC.db = FC.db or {}
        FC.db.showScreenGlow = not (FC.db.showScreenGlow ~= false)
        FC:Print(string.format("Fullscreen Vignette Screen Flash: %s", FC.db.showScreenGlow and "|cff55ff55ENABLED|r" or "|cffff2222DISABLED|r"))

    elseif cmd == "glow" or cmd == "buttonglow" or cmd == "actionglow" then
        FC.db = FC.db or {}
        FC.db.enableButtonGlow = not (FC.db.enableButtonGlow ~= false)
        if not FC.db.enableButtonGlow and FC.HideAllButtonGlows then
            FC:HideAllButtonGlows()
        end
        FC:Print(string.format("Action Bar Button Glow Injector: %s", FC.db.enableButtonGlow and "|cff55ff55ENABLED|r" or "|cffff2222DISABLED|r"))

    elseif cmd == "timers" or cmd == "bosstimers" or cmd == "speed" or cmd == "dungeonspeed" then
        local timers = (FC.GetActiveBossTimers and FC:GetActiveBossTimers()) or {}
        local speedMult, perkActive, stacks = 1.0, false, 0
        if FC.GetDungeonSpeedMultiplier then
            speedMult, perkActive, stacks = FC:GetDungeonSpeedMultiplier()
        end

        FC:Print("=== RAID & DUNGEON ENCOUNTER TIMERS ===")
        if perkActive and speedMult > 1.0 then
            FC:Print(string.format("  Perk 'Dungeon Event Speedup': |cff55ff55ACTIVE|r | Multiplier: |cffffd700%.1fx|r (%d Speed Stacks)", speedMult, stacks))
            FC:Print("  |cff888888All boss mechanic, RP, and wave timers are dynamically scaled by " .. string.format("%.1fx|r", speedMult))
        elseif perkActive then
            FC:Print("  Perk 'Dungeon Event Speedup': |cff55ff55ACTIVE|r | Multiplier: 1.0x (No Speed Buff Stacks active)")
        else
            FC:Print("  Perk 'Dungeon Event Speedup': |cffff2222INACTIVE|r (Timers running at 1.0x baseline speed)")
        end

        if FC.activeBossEncounter then
            FC:Print(string.format("  Active Encounter: |cffffd700%s|r", FC.activeBossEncounter))
        end

        if #timers == 0 then
            FC:Print("  No active boss encounter or RP timers currently running.")
        else
            for i, t in ipairs(timers) do
                local col = t.lethal and "|cffff2222" or "|cffffd700"
                FC:Print(string.format("  %d. %s%s|r in |cff00ccff%.1f seconds|r", i, col, t.name, t.remaining))
            end
        end

    elseif cmd == "npc" or cmd == "target" or cmd == "enemy" or cmd == "mob" or cmd == "boss" then
        if FC.InspectTargetNPC then
            local info, err = FC:InspectTargetNPC()
            if not info then
                FC:Print(err or "No active target.")
            else
                FC:Print(string.format("=== TARGET NPC COMBAT STATS: |cffffd700[%s]|r (Lvl %d %s) ===", info.name, info.level, info.classification))
                FC:Print(string.format("  Creature Type: |cffffffff%s|r | Health: |cff55ff55%d / %d (%.1f%%)|r", info.creatureType, info.curHp, info.maxHp, info.hpPct))
                if info.maxPower > 0 then
                    FC:Print(string.format("  Mana / Power: |cff00ccff%d / %d|r", info.curPower, info.maxPower))
                end
                FC:Print(string.format("  Armor: |cffffd700%d|r (Base: %d, Shred: |cff55ff55-%.0f%%|r) -> Physical DR: |cffff8800%.1f%%|r",
                    info.effectiveArmor, info.baseArmor, info.armorShredPct, info.drPct))
                
                if info.knownProfile and info.knownProfile.abilities then
                    FC:Print("  |cff00ccffKnown Boss Mechanics & Multi-Phase Abilities:|r")
                    for _, ab in ipairs(info.knownProfile.abilities) do
                        local pfx = (ab.phase and ("|cffff8800[" .. ab.phase .. "]|r ")) or ""
                        FC:Print(string.format("    • %s|cffffd700%s|r [%s - %s]: %s (Every ~%ds)", pfx, ab.name, ab.school, ab.type or "Spell", ab.desc, ab.interval or 0))
                    end
                end

                if #info.activeDebuffs > 0 then
                    FC:Print(string.format("  Active Debuffs (%d): |cffdddddd%s|r", #info.activeDebuffs, table.concat(info.activeDebuffs, ", ")))
                else
                    FC:Print("  Active Debuffs: |cff888888None (Apply Sunder, Faerie Fire, Curse of Elements)|r")
                end
            end
        end


    elseif cmd == "macro" or cmd == "macros" or cmd == "genmacros" then
        if FC.GenerateSmartMouseoverMacros then
            FC:GenerateSmartMouseoverMacros()
        end

    elseif cmd == "glyphs" or cmd == "glyph" then
        if FC.ScanTalents then FC:ScanTalents() end
        local specName, activeGroup = "Unknown", 1
        if FC.GetActiveSpecName then specName, activeGroup = FC:GetActiveSpecName() end
        if FC.ScanGlyphs then FC:ScanGlyphs(activeGroup) end
        local glyphs = FC.glyphList or {}

        FC:Print(string.format("=== EQUIPPED GLYPHS: |cffffd700[%s]|r (Spec %d) ===", specName, activeGroup))
        if #glyphs == 0 then
            FC:Print("  No active glyphs discovered on this spec.")
        else
            for i, g in ipairs(glyphs) do
                local typeCol = (g.type == "Major") and "|cffffd700" or "|cff00ccff"
                local bonus = ""
                local n = string.lower(g.name or "")
                -- Major
                if string.find(n, "fireball") then bonus = "(-0.15s cast time)"
                elseif string.find(n, "living bomb") then bonus = "(Periodic DoT ticks can CRIT)"
                elseif string.find(n, "molten armor") then bonus = "(+20% Spirit converted to Crit)"
                elseif string.find(n, "arcane blast") then bonus = "(+3% damage per stack)"
                elseif string.find(n, "arcane missiles") then bonus = "(+25% Crit damage bonus)"
                elseif string.find(n, "scorch") then bonus = "(+20% Scorch damage)"
                elseif string.find(n, "frostfire") then bonus = "(+2% damage & +2% crit)"
                elseif string.find(n, "frostbolt") then bonus = "(+5% damage)"
                elseif string.find(n, "ice lance") then bonus = "(4x shatter damage on frozen mobs)"
                elseif string.find(n, "deep freeze") then bonus = "(+10 yd cast range)"
                elseif string.find(n, "mirror image") then bonus = "(Images cast Fireball/Frostbolt)"
                elseif string.find(n, "arcane barrage") then bonus = "(-20% mana cost)"
                elseif string.find(n, "evocation") then bonus = "(Regain 60% max HP over channel)"
                elseif string.find(n, "eternal water") then bonus = "(Water Elemental lasts indefinitely)"
                elseif string.find(n, "obliterate") then bonus = "(+25% Obliterate damage)"
                elseif string.find(n, "mortal strike") then bonus = "(+10% Mortal Strike damage)"
                elseif string.find(n, "exorcism") then bonus = "(+20% Exorcism damage)"
                elseif string.find(n, "judgment") then bonus = "(+10% Judgment damage)"
                elseif string.find(n, "incinerate") then bonus = "(+5% Incinerate damage)"
                elseif string.find(n, "immolate") then bonus = "(+10% Immolate periodic damage)"
                elseif string.find(n, "lightning bolt") then bonus = "(+4% Lightning Bolt damage)"
                elseif string.find(n, "insect swarm") then bonus = "(+30% Insect Swarm damage)"
                elseif string.find(n, "steady shot") then bonus = "(+10% Steady Shot damage)"
                elseif string.find(n, "quick decay") then bonus = "(Haste scales Corruption tick rate)"
                elseif string.find(n, "haunt") then bonus = "(+3% Haunt bonus damage)"
                -- Minor
                elseif string.find(n, "arcane intellect") or string.find(n, "brilliance") then bonus = "(-50% Mana cost on Intellect/Brilliance)"
                elseif string.find(n, "frost ward") then bonus = "(+5% reflect chance -> 15% Frost reflection)"
                elseif string.find(n, "fire ward") then bonus = "(+5% reflect chance -> 15% Fire reflection)"
                elseif string.find(n, "blast wave") then bonus = "(-100% Mana cost, knockback removed)"
                elseif string.find(n, "slow fall") then bonus = "(No light feather required)"
                elseif string.find(n, "penguin") then bonus = "(Transforms target into baby penguin)"
                elseif string.find(n, "feign death") then bonus = "(-5s Feign Death cooldown)"
                elseif string.find(n, "levitate") then bonus = "(No light feather required)"
                elseif string.find(n, "fortitude") then bonus = "(-50% Mana cost on Fortitude)"
                elseif string.find(n, "water walking") then bonus = "(No reagent required)"
                elseif string.find(n, "kings") then bonus = "(-50% Mana cost on Kings)"
                elseif string.find(n, "might") then bonus = "(+20 min duration on self)"
                elseif string.find(n, "blood tap") then bonus = "(No longer damages self)"
                elseif string.find(n, "horn of winter") then bonus = "(+1 min duration)"
                end
                FC:Print(string.format("  %d. %s[%s]|r |cffffffff%s|r %s", i, typeCol, g.type, g.name, bonus ~= "" and ("|cff55ff55" .. bonus .. "|r") or ""))
            end
        end

        -- Print Class Glyph Optimization Tier List
        if FC.GetClassGlyphRankings then
            local rankings = FC:GetClassGlyphRankings(specName)
            if rankings and #rankings > 0 then
                FC:Print(string.format("=== CLASS GLYPH TIER LIST & OPTIMIZATION (|cffffd700%s|r) ===", specName))
                for i = 1, math.min(10, #rankings) do
                    local r = rankings[i]
                    local eqTag = r.isEquipped and "|cff55ff55[EQUIPPED]|r" or "|cff888888[Available]|r"
                    local typeCol = (r.type == "Major") and "|cffffd700" or "|cff00ccff"
                    FC:Print(string.format("  %d. %s %s[%s]|r |cffffffff%s|r (Score: |cffff8800%d|r)", i, eqTag, typeCol, r.type, r.name, r.score))
                    FC:Print(string.format("     |cff888888%s|r", r.desc))
                end
            end
        end

    elseif cmd == "why" or cmd == "explain" or cmd == "logic" or cmd == "decision" or cmd == "debugscore" then
        if FC.ExplainDecision then
            FC:ExplainDecision()
        end

    elseif cmd == "debugkeys" then
        FC:Print("=== LIVE ACTION BUTTON DEBUG ===")
        for i = 1, 12 do
            local btBtn = _G["BT4Button" .. i]
            if btBtn then
                local slot = nil
                if SecureActionButton_GetEffectiveAction then
                    local ok, s = pcall(SecureActionButton_GetEffectiveAction, btBtn)
                    if ok and s then slot = s end
                end
                if not slot and btBtn.GetAttribute then slot = btBtn:GetAttribute("action") end
                if not slot and btBtn._state_action then slot = btBtn._state_action end
                if not slot and btBtn.GetID then slot = btBtn:GetID() end

                local key = GetBindingKey("CLICK BT4Button" .. i .. ":LeftButton") or
                            GetBindingKey("CLICK BT4Button" .. i .. ":KeyBind") or
                            GetBindingKey("ACTIONBUTTON" .. i)
                local hkObj = _G["BT4Button" .. i .. "HotKey"] or btBtn.HotKey
                local hkText = hkObj and hkObj.GetText and hkObj:GetText() or "nil"

                local infoStr = "empty"
                if slot and tonumber(slot) and tonumber(slot) > 0 then
                    local aType, id, subType = GetActionInfo(tonumber(slot))
                    if aType == "spell" and id then
                        local sName = (GetSpellName and GetSpellName(id, subType or "spell")) or GetSpellInfo(id, subType or "spell") or GetSpellInfo(id) or ("Spell #" .. tostring(id))
                        infoStr = "spell:" .. tostring(sName)
                    elseif aType == "item" and id then
                        infoStr = "item:" .. tostring(GetItemInfo(id) or id)
                    elseif aType == "macro" and id then
                        local mName, _, mBody = GetMacroInfo(id)
                        local line1 = mBody and string.match(mBody, "[^\r\n]+") or ""
                        infoStr = "macro:" .. tostring(mName or id) .. " (" .. tostring(line1) .. ")"
                    elseif aType then
                        infoStr = tostring(aType) .. ":" .. tostring(id)
                    end
                end

                FC:Print(string.format("BT4Button%d -> Slot: %s | Key: %s (HotKey: %s) | Content: %s",
                    i, tostring(slot), tostring(key), tostring(hkText), infoStr))
            end
        end

    elseif cmd == "perks" then
        local ext = FC.extState or {}
        local catCounts = ext.activePerkCounts or {}
        local setName = ext.activeClassSet or (FC.db and FC.db.synastriaClassSet) or "None"
        local setDef = FC.SYNASTRIA_CLASS_SETS[setName]
        local setCount = ext.classSetCount or (FC.db and FC.db.synastriaClassSetCount) or 5

        FC:Print("=== SYNASTRIA NATIVE PERKS & SET BONUSES ===")
        FC:Print(string.format("Limits (Max 5): |cffff6666Off: %d/5|r | |cff6666ffDef: %d/5|r | |cff44ff44Sup: %d/5|r | |cffdddd44Util: %d/5|r | |cffff88ffClass: %d/5|r | |cff888888Misc: %d|r",
            catCounts.Offensive or 0,
            catCounts.Defensive or 0,
            catCounts.Support or 0,
            catCounts.Utility or 0,
            catCounts.Class or 0,
            catCounts.Misc or 0
        ))

        if setDef then
            FC:Print(string.format("|cffffd700Active Class Set:|r %s (%d/5 Perks) | 4pc: %s", setDef.name, setCount, (setDef.fourPiece or "None")))
        end

        local categoriesOrder = { "Class", "Offensive", "Defensive", "Support", "Utility", "Misc" }
        local totalPrinted = 0

        for _, catName in ipairs(categoriesOrder) do
            local catPerks = {}
            for id, perk in pairs(ext.activePerks or {}) do
                if perk.category == catName then
                    table.insert(catPerks, perk)
                end
            end

            if #catPerks > 0 then
                FC:Print(string.format("|cff00ccff--- %s Perks (%d) ---|r", catName, #catPerks))
                for idx, perk in ipairs(catPerks) do
                    totalPrinted = totalPrinted + 1
                    FC:Print(string.format("  %d. %s (ID: %s)", idx, tostring(perk.name or "Perk"), tostring(perk.id)))
                end
            end
        end

        if totalPrinted == 0 then
            FC:Print("No active perks found.")
        end

    elseif cmd == "talents" or cmd == "talent" then
        if FC.ScanTalents then FC:ScanTalents() end
        local t = FC.talents or {}
        local known = t.known or {}
        local tabPts = t.tabPoints or { [1] = 0, [2] = 0, [3] = 0 }
        local specName = t.primarySpec or "Unknown"

        FC:Print("=== TALENT SCAN & SPECIALIZATION ===")
        FC:Print(string.format("Primary Specialization: |cffffd700%s|r (|cff55ff55%d|r / |cff55ff55%d|r / |cff55ff55%d|r)",
            specName, tabPts[1] or 0, tabPts[2] or 0, tabPts[3] or 0))

        local sortedTalents = {}
        for name, rank in pairs(known) do
            table.insert(sortedTalents, { name = name, rank = rank })
        end
        table.sort(sortedTalents, function(a, b) return a.name < b.name end)

        if #sortedTalents == 0 then
            FC:Print("No spent talent points detected.")
        else
            FC:Print(string.format("|cff00ccff--- Known Talents (%d) ---|r", #sortedTalents))
            local listStr = ""
            for i, item in ipairs(sortedTalents) do
                listStr = listStr .. string.format("|cffffd700%s|r (%d), ", item.name, item.rank)
                if i % 4 == 0 or i == #sortedTalents then
                    FC:Print("  " .. string.gsub(listStr, ", $", ""))
                    listStr = ""
                end
            end
        end

        FC:Print("=== ACTIVE TALENT MODIFIERS ===")
        local testSpells = {
            { name = "Fireball", school = "Fire" },
            { name = "Pyroblast", school = "Fire" },
            { name = "Flamestrike", school = "Fire" },
            { name = "Fire Blast", school = "Fire" },
            { name = "Living Bomb", school = "Fire" },
            { name = "Frostfire Bolt", school = "Fire" },
            { name = "Frostbolt", school = "Frost" },
            { name = "Ice Lance", school = "Frost" },
            { name = "Deep Freeze", school = "Frost" },
            { name = "Arcane Blast", school = "Arcane" },
            { name = "Arcane Missiles", school = "Arcane" },
            { name = "Arcane Barrage", school = "Arcane" },
        }
        local anyMods = false
        for _, s in ipairs(testSpells) do
            local sName = s.name
            local school = s.school
            local red = FC.GetTalentCastReduction and FC:GetTalentCastReduction(sName) or 0
            local crit = FC.GetTalentCritBonus and FC:GetTalentCritBonus(sName, school) or 0
            local mult = FC.GetTalentDamageMultiplier and FC:GetTalentDamageMultiplier(sName, school, 100, false) or 1.0
            if red > 0 or crit > 0 or mult > 1.001 then
                anyMods = true
                FC:Print(string.format("  |cffffd700%s|r (%s): Cast Red: |cff55ff55-%.1fs|r | Bonus Crit: |cff55ff55+%.1f%%|r | Dmg Mult: |cff55ff55x%.2f|r",
                    sName, school, red, crit, mult))
            end
        end

        local cMult = FC.GetTalentCritMultiplier and FC:GetTalentCritMultiplier("Fire") or 2.0
        local ignRate = FC.GetTalentIgniteRate and FC:GetTalentIgniteRate("Fire") or 0
        if cMult > 2.0 or ignRate > 0 then
            FC:Print(string.format("  |cffff8800Fire Mechanics:|r Crit Damage: |cff55ff55%.2fx|r (Burnout) | Ignite Burn: |cff55ff55+%.0f%%|r",
                cMult, ignRate * 100))
        end

    elseif cmd == "synastria" then
        FC:Print("=== SYNASTRIA NATIVE SERVER & DLL STATUS ===")
        FC:Print("Native Functions Available:")
        FC:Print("  GetCustomGameData: " .. tostring(type(GetCustomGameData) == "function") .. " | GetItemTagsCustom: " .. tostring(type(GetItemTagsCustom) == "function"))
        FC:Print("  GetItemAttuneProgress: " .. tostring(type(GetItemAttuneProgress) == "function") .. " | GetItemAttuneForge: " .. tostring(type(GetItemAttuneForge) == "function"))
        FC:Print("  GetPerkActive: " .. tostring(type(GetPerkActive) == "function") .. " | OpenPerkMgr: " .. tostring(type(OpenPerkMgr) == "function") .. " | OpenAttuneSummary: " .. tostring(type(OpenAttuneSummary) == "function"))

        if type(GetCustomGameDataCount) == "function" then
            FC:Print("Custom Server Packet Counts:")
            for typeName, typeId in pairs(FC.CustomDataTypes or {}) do
                local ok, cnt = pcall(GetCustomGameDataCount, typeId)
                if ok and cnt and cnt > 0 then
                    FC:Print(string.format("  [%d] %s: %d entries", typeId, typeName, cnt))
                end
            end
        end

        local ext = FC.extState or {}
        local f = ext.forgeCounts or {}
        FC:Print(string.format("Equipped Attunements: %d Attuned | Forges: |cffff8800%d Titanforged|r, |cff00ccff%d Warforged|r, |cffffd700%d Lightforged|r",
            ext.totalAttunedItems or 0, f.Titanforged or 0, f.Warforged or 0, f.Lightforged or 0))

    elseif cmd == "attune" or cmd == "attunement" or cmd == "forge" then
        FC:Print("=== EQUIPPED SYNASTRIA ATTUNEMENTS & FORGES ===")
        if FC.ScanEquippedAttunements then FC:ScanEquippedAttunements() end
        local gear = FC.extState and FC.extState.attunementGear or {}
        if #gear == 0 then
            FC:Print("No equipped gear data found.")
        else
            for i, item in ipairs(gear) do
                local tagStr = ""
                if item.isMythic then tagStr = tagStr .. " [Mythic]" end
                if item.hasRandomAffix then tagStr = tagStr .. " [Affix]" end
                if item.forgeName and item.forgeName ~= "Normal" then tagStr = tagStr .. " [" .. item.forgeName .. "]" end

                local progStr = item.isAttuned and "|cff55ff55ATTUNED (100%)|r" or string.format("|cffffaa00%d%%|r", item.attuneProgress or 0)
                FC:Print(string.format("Slot %d: %s -> %s%s", item.slot or i, item.link or ("Item " .. tostring(item.itemId)), progStr, tagStr))
            end
        end

    elseif cmd == "inspectitem" or cmd == "itemdata" then
        local targetItem = arg
        if not targetItem or targetItem == "" then
            FC:Print("Usage: /fc inspectitem <itemId or itemLink> (e.g. /fc inspectitem 49623)")
        else
            local itemId = tonumber(string.match(targetItem, "item:(%d+)")) or tonumber(targetItem)
            if not itemId then
                FC:Print("Invalid item ID or item link.")
            else
                local d = FC:GetSynastriaItemData(itemId)
                FC:Print("=== SYNASTRIA ITEM DATA (ID: " .. itemId .. ") ===")
                FC:Print("  Mythic: " .. tostring(d.isMythic) .. " | Random Affix: " .. tostring(d.hasRandomAffix) .. " | Can Roll Resist: " .. tostring(d.canRollResist))
                FC:Print("  Forge Tier: " .. tostring(d.forgeTier) .. " (" .. tostring(d.forgeName) .. ") | Attune Progress: " .. tostring(d.attuneProgress) .. "% | Attuned: " .. tostring(d.isAttuned))
                FC:Print("  Can Attune Helper: " .. tostring(d.canAttune))
            end
        end

    elseif cmd == "inspectperk" then
        local pid = tonumber(arg)
        if not pid then
            FC:Print("Usage: /fc inspectperk <id> (e.g. /fc inspectperk 1113)")
        else
            FC:Print("=== INSPECT PERK ID " .. pid .. " ===")
            if type(GetPerkActive) == "function" then
                FC:Print("GetPerkActive: " .. tostring(GetPerkActive(pid)))
            end
            if type(GetPerkAcquired) == "function" then
                FC:Print("GetPerkAcquired: " .. tostring(GetPerkAcquired(pid)))
            end
            if _G.PerkMgrPerks and _G.PerkMgrPerks[pid] then
                local p = _G.PerkMgrPerks[pid]
                if type(p) == "table" then
                    for k, v in pairs(p) do
                        FC:Print("  " .. tostring(k) .. ": " .. tostring(v))
                    end
                else
                    FC:Print("  Perk entry is: " .. tostring(p))
                end
            else
                FC:Print("Perk not found in PerkMgrPerks.")
            end
        end

    elseif cmd == "enemies" then
        FC:Print("=== ACTIVE IN-COMBAT ENEMIES ===")
        FC:Print("Total Enemies: " .. tostring(FC.state.enemyCount or 1))
        local count = 0
        if FC.combat and FC.combat.activeHostileGUIDs then
            local now = GetTime()
            for guid, lastSeen in pairs(FC.combat.activeHostileGUIDs) do
                count = count + 1
                FC:Print(string.format("%d. GUID: %s (Active: %.1fs ago)", count, tostring(guid), (now - lastSeen)))
            end
        end
        if count == 0 then
            FC:Print("No hostile combatants currently tracked in CLEU window.")
        end

    elseif cmd == "target" then
        local t = FC.state.target or {}
        FC:Print("=== TARGET DIAGNOSTIC ===")
        if not t.exists then
            FC:Print("Target: None")
        else
            FC:Print("Name: " .. tostring(UnitName("target")) .. " | Classification: " .. tostring(t.classification) .. " | Level: " .. tostring(UnitLevel("target")))
            FC:Print("Creature Type: " .. tostring(t.creatureType) .. " (Undead: " .. tostring(t.isUndead) .. ", Demon: " .. tostring(t.isDemon) .. ")")
            FC:Print("Health: " .. string.format("%.1f%%", t.healthPct or 0) .. " | TTD: " .. string.format("%.1fs", t.ttd or 999))
            FC:Print("Frozen / Shatter: " .. tostring(t.isFrozen) .. " | Breakable CC: " .. tostring(t.isCrowdControlled))
            FC:Print("Stealable Buff: " .. tostring(t.hasStealableBuff))
            if t.isCasting or t.isChanneling then
                FC:Print("Casting: " .. tostring(t.castSpellName) .. " (" .. string.format("%.1fs", t.castRemaining or 0) .. " remaining | Interruptible: " .. tostring(t.interruptible) .. ")")
            else
                FC:Print("Casting: No")
            end
            if t.resistances and next(t.resistances) then
                local resList = {}
                for school, status in pairs(t.resistances) do
                    table.insert(resList, school .. "=" .. status)
                end
                FC:Print("Resistances: " .. table.concat(resList, ", "))
            else
                FC:Print("Resistances: None detected")
            end
        end

    elseif cmd == "timeline" then
        local queue = (FC.timeline and FC.timeline.queue) or {}
        if #queue == 0 then
            FC:Print("Timeline is currently empty.")
        else
            FC:Print("=== PREDICTIVE TIMELINE (Next 10s) ===")
            for i, entry in ipairs(queue) do
                FC:Print(string.format("%d. [|cff00ccff+%.1fs|r] %s (%s)", i, entry.time or 0, entry.name or "?", entry.role or "action"))
            end
        end

    elseif cmd == "ui" or cmd == "toggle" then
        if FC.ToggleTimelineUI then
            FC:ToggleTimelineUI()
        end

    elseif cmd == "lock" then
        if FC.LockTimelineUI then
            FC:LockTimelineUI()
        end

    elseif cmd == "scale" then
        if FC.SetTimelineScale then
            FC:SetTimelineScale(arg)
        end

    elseif cmd == "state" then
        local p = FC.state.player or {}
        local t = FC.state.target or {}
        FC:Print("=== FLOWCORE COMBAT STATE ===")
        FC:Print("Phase: " .. FC.COLORS.TITLE .. tostring(FC.state.phase) .. "|r | In Combat: " .. tostring(FC.state.inCombat) .. " | Engaged: " .. tostring(FC.state.engaged))
        FC:Print("Enemies: " .. tostring(FC.state.enemyCount or 1) .. " active combatants")
        FC:Print("Player HP: " .. string.format("%.1f%%", p.healthPct or 100) .. " | Power: " .. string.format("%.0f", p.power or 0) .. " (Type " .. tostring(p.powerType) .. ")")
        FC:Print("Incoming DTPS: " .. string.format("%.1f", FC.state.dtps or 0) .. " | Danger Level: " .. string.format("%.0f/100", FC.state.dangerLevel or 0))
        if t.exists then
            FC:Print("Target: " .. tostring(t.creatureType) .. " | HP: " .. string.format("%.1f%%", t.healthPct or 0) .. " | Hostile: " .. tostring(t.hostile) .. " | TTD: " .. string.format("%.1fs", t.ttd or 999))
        else
            FC:Print("Target: None")
        end

    elseif cmd == "spells" then
        FC:Print("=== REGISTERED SPELL ACTIONS ===")
        local count = 0
        for _, action in ipairs(FC.actions or {}) do
            if action.actionType == "spell" then
                count = count + 1
                local origin = action.autoDiscovered and "[auto]" or "[manual]"
                if action.isSynastriaPerk then origin = "[perk]" end
                FC:Print(origin .. " " .. action.name .. " (Role: " .. tostring(action.role) .. ", Priority: " .. tostring(action.priority) .. ", School: " .. tostring(action.school or "Physical") .. ")")
            end
        end
        FC:Print("Total Spells: " .. count)

    elseif cmd == "items" then
        FC:Print("=== REGISTERED ITEM ACTIONS ===")
        local count = 0
        for _, action in ipairs(FC.actions or {}) do
            if action.actionType == "item" then
                count = count + 1
                FC:Print("[item] " .. action.name .. " (Role: " .. tostring(action.role) .. ", Priority: " .. tostring(action.priority) .. ")")
            end
        end
        FC:Print("Total Items: " .. count)

    elseif cmd == "rescan" then
        if FC.ScanTalents then FC:ScanTalents() end
        if FC.ScanSpellbook then FC:ScanSpellbook(true) end
        if FC.ScanItems then FC:ScanItems() end
        if FC.RefreshExtState then FC:RefreshExtState() end
        if FC.RefreshConfigSpellsList then FC:RefreshConfigSpellsList() end
        if FC.RefreshConfigPerksList then FC:RefreshConfigPerksList() end
        FC:Print("Full talent, spellbook, item, and perk rescan complete.")

    elseif cmd == "scanapi" then
        local term = string.lower(arg or "")
        if term == "" then
            FC:Print("Usage: /fc scanapi <search term> (e.g. /fc scanapi perk)")
        else
            FC:Print("=== GLOBAL SEARCH: \"" .. term .. "\" ===")
            local found = 0
            for k, v in pairs(_G) do
                if type(k) == "string" and string.find(string.lower(k), term, 1, true) then
                    found = found + 1
                    if found <= 40 then
                        FC:Print(k .. " (" .. type(v) .. ")")
                    end
                end
            end
            FC:Print("Matches: " .. found .. (found > 40 and " (showing first 40)" or ""))
        end

    elseif cmd == "verbose" then
        FC.verbose = not FC.verbose
        FC:Print("Verbose logging: " .. tostring(FC.verbose))

    elseif cmd == "debug" then
        FC.debug = not FC.debug
        FC:Print("Debug logging: " .. tostring(FC.debug))

    else
        FC:Print("=== FlowCore Commands ===")
        FC:Print("/fc sim | test [mode] - Live Combat Simulation (single|aoe|proc|emergency|interrupt|stop)")
        FC:Print("/fc caps | hit        - Stat Cap & Combat Rating Audit (Hit, Exp, Haste, Defense)")
        FC:Print("/fc weights           - Relative Stat Weights & DPS Values for Active Spec")
        FC:Print("/fc gearcheck         - Equipped Gear Audit (Enchants & Empty Gem Sockets)")
        FC:Print("/fc upgrades          - Scan Bags, Bank & Mail for Equippable Upgrades")
        FC:Print("/fc build | talents   - Talent Build & Synergy Advisor (Missing Keystones)")
        FC:Print("/fc prep | buffcheck  - Pre-Combat Readiness & Raid Buff Checklist")
        FC:Print("/fc report | combat   - Post-Fight Combat Performance & Rotation Grading")
        FC:Print("/fc damage | dpct     - Live Spell Damage, DPCT, & Mana Efficiency Breakdown")
        FC:Print("/fc gcd | haste       - Inspect Effective Haste GCD, Live GCD & Latency Window")
        FC:Print("/fc synergies         - List Active Cross-Spell Synergy & Prerequisite Rules")
        FC:Print("/fc empirical         - Live Combat Log Self-Learning Samples & Multipliers")
        FC:Print("/fc ttd | threat      - Target Time-to-Death & Incoming Boss Threat Diagnostics")
        FC:Print("/fc stats             - Real-time Player Stats, Haste/Crit & Set Bonuses")
        FC:Print("/fc perks             - List Active Synastria Custom Perks & Set Bonuses")
        FC:Print("/fc glyphs            - List Equipped Major/Minor Glyphs & Rotational Modifiers")
        FC:Print("/fc synastria         - Synastria Native DLL, Packet Counts & Attunement Summary")
        FC:Print("/fc forges | attune   - List Equipped Attunements & Forges (Titan/War/Light)")
        FC:Print("/fc timers | boss     - Inspect Active Raid Boss Mechanic Timers")
        FC:Print("/fc sound | audio     - Toggle Audio Proc & Alert Chimes")
        FC:Print("/fc screenglow        - Toggle Fullscreen Vignette Screen Flash")
        FC:Print("/fc glow              - Toggle Action Bar Button Glow Injector")
        FC:Print("/fc inspectitem <id>  - Inspect Custom Item Tags, Mythic & Forge Properties")
        FC:Print("/fc inspectperk <id>  - Inspect raw server data for a specific perk ID")
        FC:Print("/fc approach <balanced|st|aoe|survival> - Set Combat Approach & Focus Engine")
        FC:Print("/fc role <dps|tank|healer|solo> - Set Group Role for Threat Aggro Warnings")
        FC:Print("/fc macro             - Generate Smart Mouseover Macros (255-char safe)")
        FC:Print("/fc ui | toggle       - Toggle Timeline HUD")
        FC:Print("/fc config            - Open FlowCore In-Game Configuration Panel")
        FC:Print("/fc lock              - Lock/Unlock Timeline Position")
        FC:Print("/fc why | explain     - Explain Real-time Recommendation Decision Logic")
        FC:Print("/fc best              - Current Immediate Recommended Cast")
        FC:Print("/fc timeline          - Print 10-Second Forecast in Chat")
        FC:Print("/fc check             - Run Full Engine Diagnostics")
        FC:Print("/fc state             - Inspect Real-time Combat Vitals & DTPS")
        FC:Print("/fc enemies           - Inspect Active In-Combat Enemies")
        FC:Print("/fc target            - Inspect Target Type, Casts, CC, & Resistances")
        FC:Print("/fc spells            - List Auto-Discovered Spells & Perks")
        FC:Print("/fc items             - List Tracked Trinkets & Consumables")
        FC:Print("/fc rescan            - Rescan Spellbook, Items & Perks")
        FC:Print("/fc debug | verbose   - Toggle Logging")
    end
end