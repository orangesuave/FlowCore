FlowCore = FlowCore or {}
local FC = FlowCore

FC.booted = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)

    if event == "ADDON_LOADED" and arg1 == "FlowCore" then
        if FC.InitDB then
            FC:InitDB()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        -- Initialize SavedVariables if not already done
        if not FC.db and FC.InitDB then
            FC:InitDB()
        end

        -- 1. Scan Talents & Glyphs
        if FC.ScanTalents then
            pcall(FC.ScanTalents, FC)
        end
        if FC.ScanGlyphs then
            pcall(FC.ScanGlyphs, FC)
        end

        -- 2. Scan Spellbook & Perks
        if FC.ScanSpellbook then
            pcall(FC.ScanSpellbook, FC)
        end

        -- 3. Scan Equipped Trinkets & Consumable Items
        if FC.ScanItems then
            pcall(FC.ScanItems, FC)
        end

        -- 4. Initial Synastria/WoWExt scan
        if FC.RefreshExtState then
            pcall(FC.RefreshExtState, FC)
        end

        -- 5. Force State Update (bypassing throttle)
        if FC.UpdateState then
            pcall(FC.UpdateState, FC, true)
        end

        -- Mark addon ready
        FC.booted = true

        -- Trigger first engine run
        if FC.MarkEngineDirty then
            FC:MarkEngineDirty()
        end

        FC:Print("FlowCore v" .. FC.version .. " initialized (Predictive Timeline Active). Type " .. FC.COLORS.INFO .. "/fc|r for commands.")
    end
end)