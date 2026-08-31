FlowCore = FlowCore or {}
local FC = FlowCore

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MANA")
frame:RegisterEvent("UNIT_RAGE")
frame:RegisterEvent("UNIT_ENERGY")
frame:RegisterEvent("UNIT_RUNIC_POWER")
frame:RegisterEvent("RUNE_POWER_UPDATE")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("UPDATE_BINDINGS")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("GLYPH_ADDED")
frame:RegisterEvent("GLYPH_REMOVED")
frame:RegisterEvent("GLYPH_UPDATED")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_INBOX_UPDATE")

frame:SetScript("OnEvent", function(self, event, unit)
    if not FC.booted then return end

    if event == "PLAYER_REGEN_DISABLED" then
        if FC.StartCombatSession then FC:StartCombatSession() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if FC.EndCombatSession then FC:EndCombatSession() end
    elseif event == "BANKFRAME_OPENED" or event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
        if FC.ScanBagsBankMailForUpgrades then pcall(FC.ScanBagsBankMailForUpgrades, FC) end
    end

    if event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "UNIT_RUNIC_POWER" then
        if unit ~= "player" and unit ~= "target" then return end
    end

    if event == "GLYPH_ADDED" or event == "GLYPH_REMOVED" or event == "GLYPH_UPDATED" then
        if FC.ScanGlyphs then
            pcall(FC.ScanGlyphs, FC)
        end
        if FC.MarkEngineDirty then FC:MarkEngineDirty() end
        return
    end

    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        local inGroup = (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
        FC.db = FC.db or {}
        if inGroup and (not FC.db.playerRole or FC.db.playerRole == "Solo") then
            FC.db.playerRole = "DPS"
        end
    end

    if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
        local activeSpec = 1
        if type(GetActiveTalentGroup) == "function" then
            local ok, g = pcall(GetActiveTalentGroup)
            if ok and g and tonumber(g) then
                activeSpec = math.min(6, math.max(1, tonumber(g)))
            end
        end

        FC.db = FC.db or {}
        FC.db.specProfiles = FC.db.specProfiles or {}
        FC.db.activeSpec = activeSpec

        if not FC.db.specProfiles[activeSpec] then
            FC.db.specProfiles[activeSpec] = {
                specName = "Spec " .. activeSpec,
                playerRole = FC.db.playerRole or "DPS"
            }
        end

        if FC.ScanTalents then
            pcall(FC.ScanTalents, FC)
        end
        if FC.ScanGlyphs then
            pcall(FC.ScanGlyphs, FC, activeSpec)
        end
        if FC.ScanSpellbook then
            pcall(FC.ScanSpellbook, FC, true)
        end
        if FC.UpdatePlayerStats then
            pcall(FC.UpdatePlayerStats, FC)
        end
        if FC.ScanActionKeybinds then
            pcall(FC.ScanActionKeybinds, FC, true)
        end
        if FC.ScanAttunementsAndForges then
            pcall(FC.ScanAttunementsAndForges, FC)
        end
        if FC.RefreshConfigSpellsList and FlowCoreConfigFrame and FlowCoreConfigFrame:IsShown() then
            pcall(FC.RefreshConfigSpellsList, FC)
        end
    end

    if event == "UPDATE_BINDINGS" or event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" then
        if FC.ScanActionKeybinds then
            pcall(FC.ScanActionKeybinds, FC, true)
        end
    end

    if event == "BAG_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
        if FC.ScanItems then
            pcall(FC.ScanItems, FC)
        end
    end

    if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
        if FC.ScanSpellbook then
            pcall(FC.ScanSpellbook, FC)
        end
        if FC.ScanActionKeybinds then
            pcall(FC.ScanActionKeybinds, FC, true)
        end
    end

    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED" then
        if FC.CheckBossEncounterTrigger then
            pcall(FC.CheckBossEncounterTrigger, FC)
        end
    end

    if FC.UpdateState then
        FC:UpdateState()
    end

    if FC.MarkEngineDirty then
        FC:MarkEngineDirty()
    end
end)
