FlowCore = FlowCore or {}
local FC = FlowCore

-- Selection state for multi-select spell configuration (Phase 3)
FC.selectedConfigSpells = FC.selectedConfigSpells or {}

-- =====================================================
-- CONFIG WINDOW FRAME (FlowCoreConfigFrame)
-- =====================================================
local configFrame = CreateFrame("Frame", "FlowCoreConfigFrame", UIParent)
configFrame:SetSize(720, 580)
configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetClampedToScreen(true)
configFrame:SetScript("OnDragStart", configFrame.StartMoving)
configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
configFrame:Hide()

-- Dark translucent background
local bg = configFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(configFrame)
bg:SetTexture(0.04, 0.04, 0.06, 0.94)

-- Border
local border = CreateFrame("Frame", nil, configFrame)
border:SetAllPoints(configFrame)
border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
border:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.9)

-- Title
local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 14, -12)
title:SetText("|cff00ccffFlowCore|r |cffffffffConfiguration & Spells|r")

-- Close Button
local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)

-- =====================================================
-- TAB BAR
-- =====================================================
local tabs = {}
local activeTab = 1

local function SelectTab(tabIndex)
    activeTab = tabIndex
    for i, tab in ipairs(tabs) do
        if i == tabIndex then
            tab.content:Show()
            tab:SetBackdropBorderColor(0.2, 0.8, 1.0, 1.0)
            tab.text:SetTextColor(1, 1, 1)
        else
            tab.content:Hide()
            tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
            tab.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end
end

local function CreateTab(name, index)
    local tab = CreateFrame("Button", "FlowCoreConfigTab" .. index, configFrame)
    tab:SetSize(166, 26)
    tab:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12 + (index - 1) * 174, -36)
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)
    text:SetText(name)
    tab.text = text

    local content = CreateFrame("Frame", nil, configFrame)
    content:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, -68)
    content:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -12, 12)
    tab.content = content

    tab:SetScript("OnClick", function()
        SelectTab(index)
    end)

    tabs[index] = tab
    return content
end

local generalContent = CreateTab("General", 1)
local spellsContent = CreateTab("Spells & Actions", 2)
local perksContent = CreateTab("Synastria Perks", 3)
local buffsContent = CreateTab("Buff Groups", 4)

-- =====================================================
-- TAB 1: GENERAL SETTINGS (2-Column Layout)
-- =====================================================
local cbCount = 0
local function CreateCheckbox(parent, x, y, labelText, dbKey, onClickCallback)
    cbCount = cbCount + 1
    local frameName = "FlowCoreCB_" .. tostring(dbKey or cbCount)
    local cb = CreateFrame("CheckButton", frameName, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local text = _G[frameName .. "Text"]
    if not text then
        text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    end
    text:SetText(labelText)
    cb.text = text

    cb:SetScript("OnShow", function(self)
        if FC.db and dbKey then
            self:SetChecked(FC.db[dbKey] == true)
        end
    end)

    cb:SetScript("OnClick", function(self)
        local val = (self:GetChecked() == 1 or self:GetChecked() == true)
        if FC.db and dbKey then
            FC.db[dbKey] = val
        end
        if onClickCallback then
            onClickCallback(val)
        end
    end)

    return cb
end

local sliderCount = 0
local function CreateSlider(parent, x, y, labelText, minVal, maxVal, step, dbKey, formatStr, onValChange)
    sliderCount = sliderCount + 1
    local frameName = "FlowCoreSlider_" .. tostring(dbKey or sliderCount)
    local slider = CreateFrame("Slider", frameName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetWidth(220)

    local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2)
    title:SetText(labelText)

    local valText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)

    local lowText = _G[frameName .. "Low"]
    if lowText then lowText:SetText(tostring(minVal)) end
    local highText = _G[frameName .. "High"]
    if highText then highText:SetText(tostring(maxVal)) end
    local textWidget = _G[frameName .. "Text"]
    if textWidget then textWidget:SetText("") end

    slider:SetScript("OnShow", function(self)
        if FC.db and dbKey then
            local v = FC.db[dbKey] or minVal
            self:SetValue(v)
            valText:SetText(string.format(formatStr, v))
        end
    end)

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor((val / step) + 0.5) * step
        if FC.db and dbKey then
            FC.db[dbKey] = val
        end
        valText:SetText(string.format(formatStr, val))
        if onValChange then
            onValChange(val)
        end
    end)

    return slider
end

-- Column 1: HUD & Automation Toggles (x = 8)
CreateCheckbox(generalContent, 8, -6, "Show Timeline UI Bar", "showUI")
CreateCheckbox(generalContent, 8, -28, "Lock HUD Position", "locked", function(val)
    if FC.LockTimelineUI then FC:LockTimelineUI(val) end
end)
CreateCheckbox(generalContent, 8, -50, "|cffffd700Floating Hero HUD|r", "showHeroHUD")
CreateCheckbox(generalContent, 8, -72, "Show Minimap Icon", "showMinimapButton", function(val)
    if FC.UpdateMinimapButtonVisibility then FC:UpdateMinimapButtonVisibility() end
end)
CreateCheckbox(generalContent, 8, -94, "Action Bar Button Glow", "enableButtonGlow")
CreateCheckbox(generalContent, 8, -116, "Audio Proc & Alert Cues", "enableSound")
CreateCheckbox(generalContent, 8, -138, "Fullscreen Vignette Flash", "showScreenGlow")
CreateCheckbox(generalContent, 8, -160, "Auto-Recommend Defensives", "autoDefensives")
CreateCheckbox(generalContent, 8, -182, "Auto-Recommend Trinkets", "autoTrinkets")
CreateCheckbox(generalContent, 8, -204, "Auto-Recommend Interrupts", "autoInterrupts")
CreateCheckbox(generalContent, 8, -226, "Auto-Recommend Dispels", "autoDispels")
CreateCheckbox(generalContent, 8, -248, "Auto-Switch AoE (2+ targets)", "autoAoE")
CreateCheckbox(generalContent, 8, -270, "|cffff88ffSynastria Perks Scaling|r", "enableSynastriaPerks")

-- Player Role Selector (Phase 2: Tank/Solo ignores threat alert)
local roleLabel = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
roleLabel:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 8, -296)
roleLabel:SetText("|cff00ccffGroup Role:|r")

local roleBtn = CreateFrame("Button", "FlowCoreConfigRoleBtn", generalContent, "UIPanelButtonTemplate")
roleBtn:SetSize(130, 22)
roleBtn:SetPoint("LEFT", roleLabel, "RIGHT", 6, 0)

local ROLES_LIST = { "DPS", "Healer", "Tank", "Solo" }
local function UpdateRoleBtnText()
    local curRole = (FC.db and FC.db.playerRole) or "DPS"
    local col = (curRole == "Tank" and "|cff00ccff") or (curRole == "Healer" and "|cff55ff55") or (curRole == "Solo" and "|cffaaaaaa") or "|cffff8800"
    roleBtn:SetText(string.format("%s%s|r", col, curRole))
end

roleBtn:SetScript("OnShow", UpdateRoleBtnText)
roleBtn:SetScript("OnClick", function()
    FC.db = FC.db or {}
    local curRole = FC.db.playerRole or "DPS"
    local nextIdx = 1
    for i, r in ipairs(ROLES_LIST) do
        if r == curRole then nextIdx = (i % #ROLES_LIST) + 1 break end
    end
    FC.db.playerRole = ROLES_LIST[nextIdx]
    UpdateRoleBtnText()
    if FC.UpdateState then FC:UpdateState() end
    FC:Print(string.format("Player Role set to |cffffd700%s|r", FC.db.playerRole))
end)

-- Combat Approach & Focus Selector
local approachLabel = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
approachLabel:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 8, -322)
approachLabel:SetText("|cff00ccffApproach:|r")

local approachBtn = CreateFrame("Button", "FlowCoreConfigApproachBtn", generalContent, "UIPanelButtonTemplate")
approachBtn:SetSize(150, 22)
approachBtn:SetPoint("LEFT", approachLabel, "RIGHT", 6, 0)

local APPROACHES_LIST = { "Balanced", "ST Damage", "AOE Damage", "Survival/PVP" }
local APPROACH_DESCS = {
    ["Balanced"] = "|cff55ff55Balanced|r: Equal value on ST & AoE damage, survival, and fast pack-to-pack speed with resource/mana sustain.",
    ["ST Damage"] = "|cffff8800ST Damage|r: Maximum priority on Single Target boss rotation, burst cycles, execute phases and ST stat scaling.",
    ["AOE Damage"] = "|cff00ccffAOE Damage|r: Maximum priority on 3+ target cleave, multi-dotting, ground AoE hazards, and mass trash burst.",
    ["Survival/PVP"] = "|cffff6666Survival / PVP|r: Heavy emphasis on Stamina, Damage Reduction, Resilience, Shields, and passive health recovery."
}

local approachDescText = generalContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
approachDescText:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 8, -348)
approachDescText:SetWidth(530)
approachDescText:SetJustifyH("LEFT")

local function UpdateApproachUI()
    local curApp = (FC.db and FC.db.combatApproach) or "Balanced"
    local col = (curApp == "Balanced" and "|cff55ff55") or (curApp == "ST Damage" and "|cffff8800") or (curApp == "AOE Damage" and "|cff00ccff") or "|cffff6666"
    approachBtn:SetText(string.format("%s%s|r", col, curApp))
    approachDescText:SetText(APPROACH_DESCS[curApp] or APPROACH_DESCS["Balanced"])
end

approachBtn:SetScript("OnShow", UpdateApproachUI)
approachBtn:SetScript("OnClick", function()
    FC.db = FC.db or {}
    local curApp = FC.db.combatApproach or "Balanced"
    local nextIdx = 1
    for i, a in ipairs(APPROACHES_LIST) do
        if a == curApp then nextIdx = (i % #APPROACHES_LIST) + 1 break end
    end
    FC.db.combatApproach = APPROACHES_LIST[nextIdx]
    UpdateApproachUI()
    if FC.UpdateState then FC:UpdateState() end
    FC:Print(string.format("Combat Approach set to |cffffd700[%s]|r - %s", FC.db.combatApproach, APPROACH_DESCS[FC.db.combatApproach] or ""))
end)

-- Column 2: Sliders & Smart Macro Generator (x = 270)
CreateSlider(generalContent, 270, -20, "Latency Queue Buffer", 100, 500, 25, "customQueueWindowMs", "%d ms")
CreateSlider(generalContent, 270, -66, "Emergency Health Threshold", 15, 60, 5, "minHealthEmergency", "%d%% HP")
CreateSlider(generalContent, 270, -112, "Timeline Forecast Duration", 5, 15, 1, "timelineDuration", "%d seconds")
CreateSlider(generalContent, 270, -158, "Timeline HUD Scale", 0.6, 1.8, 0.1, "scale", "%.1fx", function(val)
    if FC.SetTimelineScale then FC:SetTimelineScale(val) end
end)

-- Smart Mouseover Macro Generator (Phase 5)
local macroPanel = CreateFrame("Frame", nil, generalContent)
macroPanel:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 270, -210)
macroPanel:SetSize(250, 110)
macroPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
macroPanel:SetBackdropColor(0.1, 0.12, 0.18, 0.8)
macroPanel:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.8)

local macroTitle = macroPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
macroTitle:SetPoint("TOPLEFT", macroPanel, "TOPLEFT", 8, -6)
macroTitle:SetText("|cffffd700Smart Mouseover Macros|r")

local macroDesc = macroPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
macroDesc:SetPoint("TOPLEFT", macroPanel, "TOPLEFT", 8, -22)
macroDesc:SetWidth(234)
macroDesc:SetJustifyH("LEFT")
macroDesc:SetText("Generates [@mouseover,harm,nodead][] macros for all your class abilities (255-char safe).")

local btnGenMacro = CreateFrame("Button", nil, macroPanel, "UIPanelButtonTemplate")
btnGenMacro:SetSize(234, 24)
btnGenMacro:SetPoint("BOTTOM", macroPanel, "BOTTOM", 0, 6)
btnGenMacro:SetText("Generate Mouseover Macros")
btnGenMacro:SetScript("OnClick", function()
    if FC.GenerateSmartMouseoverMacros then
        FC:GenerateSmartMouseoverMacros()
    end
end)

-- Out-of-Combat Live Simulation Buttons (Bottom)
local simHeader = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
simHeader:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 8, -440)
simHeader:SetText("|cff00ccffOut-of-Combat Live Simulation & Diagnostics:|r")

local btnSimSingle = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
btnSimSingle:SetSize(120, 24)
btnSimSingle:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 8, -462)
btnSimSingle:SetText("Test Boss Sim")
btnSimSingle:SetScript("OnClick", function()
    if FC.StartSimulation then FC:StartSimulation("single") end
end)

local btnSimAoE = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
btnSimAoE:SetSize(120, 24)
btnSimAoE:SetPoint("LEFT", btnSimSingle, "RIGHT", 8, 0)
btnSimAoE:SetText("Test AoE Sim")
btnSimAoE:SetScript("OnClick", function()
    if FC.StartSimulation then FC:StartSimulation("aoe") end
end)

local btnSimProc = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
btnSimProc:SetSize(120, 24)
btnSimProc:SetPoint("LEFT", btnSimAoE, "RIGHT", 8, 0)
btnSimProc:SetText("Test Procs Sim")
btnSimProc:SetScript("OnClick", function()
    if FC.StartSimulation then FC:StartSimulation("proc") end
end)

local btnSimStop = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
btnSimStop:SetSize(120, 24)
btnSimStop:SetPoint("LEFT", btnSimProc, "RIGHT", 8, 0)
btnSimStop:SetText("Stop Sim")
btnSimStop:SetScript("OnClick", function()
    if FC.StopSimulation then FC:StopSimulation() end
end)

-- =====================================================
-- TAB 2: SPELLS & ACTIONS (WITH MULTI-SELECT & BULK ACTIONS)
-- =====================================================
local SPELL_SECTIONS = {
    { id = "nuke",      name = "Single-Target Nukes",       color = "|cffff8800" },
    { id = "dot",       name = "DoTs & Debuffs",            color = "|cffff5533" },
    { id = "aoe",       name = "Area of Effect (AoE)",      color = "|cffffff33" },
    { id = "cooldown",  name = "Major DPS Cooldowns",       color = "|cffffd700" },
    { id = "defensive", name = "Defensives & Absorbs",      color = "|cff55ff55" },
    { id = "heal",      name = "Heals & Restorations",      color = "|cff33ff88" },
    { id = "interrupt", name = "Interrupts & Crowd Control",color = "|cffff3333" },
    { id = "dispel",    name = "Dispels & Cleanses",        color = "|cff33ffcc" },
    { id = "buff",      name = "Buffs & Auras",             color = "|cffbb88ff" },
    { id = "mana",      name = "Mana & Resources",          color = "|cff4488ff" },
    { id = "utility",   name = "Utilities & Movement",      color = "|cffaaaaaa" },
}

local searchBox = CreateFrame("EditBox", "FlowCoreSpellsSearchBox", spellsContent, "InputBoxTemplate")
searchBox:SetSize(140, 20)
searchBox:SetPoint("TOPLEFT", spellsContent, "TOPLEFT", 50, -4)
searchBox:SetAutoFocus(false)

local searchLabel = spellsContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("RIGHT", searchBox, "LEFT", -6, 0)
searchLabel:SetText("Search:")

local rescanBtn = CreateFrame("Button", nil, spellsContent, "UIPanelButtonTemplate")
rescanBtn:SetSize(75, 22)
rescanBtn:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
rescanBtn:SetText("Rescan")
rescanBtn:SetScript("OnClick", function()
    if FC.ScanSpellbook then FC:ScanSpellbook(true) end
    if FC.ScanItems then FC:ScanItems() end
    FC:RefreshConfigSpellsList()
    FC:RefreshConfigPerksList()
    FC:Print("Spellbook, items & perks rescanned.")
end)

-- Multi-Select Top Bar Buttons (Phase 3)
local selectAllBtn = CreateFrame("Button", nil, spellsContent, "UIPanelButtonTemplate")
selectAllBtn:SetSize(80, 22)
selectAllBtn:SetPoint("LEFT", rescanBtn, "RIGHT", 6, 0)
selectAllBtn:SetText("Select All")

local clearSelBtn = CreateFrame("Button", nil, spellsContent, "UIPanelButtonTemplate")
clearSelBtn:SetSize(75, 22)
clearSelBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 6, 0)
clearSelBtn:SetText("Clear Sel")

-- Bulk Action Bar (Phase 3)
local bulkBar = CreateFrame("Frame", nil, spellsContent)
bulkBar:SetPoint("TOPLEFT", spellsContent, "TOPLEFT", 0, -28)
bulkBar:SetPoint("TOPRIGHT", spellsContent, "TOPRIGHT", 0, -28)
bulkBar:SetHeight(24)

local bulkCountText = bulkBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bulkCountText:SetPoint("LEFT", bulkBar, "LEFT", 4, 0)
bulkCountText:SetText("|cff00ccff0 selected|r")

local function GetSelectedSpellCount()
    local c = 0
    for _ in pairs(FC.selectedConfigSpells) do c = c + 1 end
    return c
end

local function UpdateBulkCountText()
    local c = GetSelectedSpellCount()
    bulkCountText:SetText(string.format("|cff00ccff%d selected|r", c))
end

local bulkCategoryBtn = CreateFrame("Button", "FlowCoreBulkCategoryBtn", bulkBar, "UIPanelButtonTemplate")
bulkCategoryBtn:SetSize(180, 22)
bulkCategoryBtn:SetPoint("LEFT", bulkCountText, "RIGHT", 12, 0)
bulkCategoryBtn:SetText("Bulk Change Category...")

local bulkTrackBtn = CreateFrame("Button", nil, bulkBar, "UIPanelButtonTemplate")
bulkTrackBtn:SetSize(150, 22)
bulkTrackBtn:SetPoint("LEFT", bulkCategoryBtn, "RIGHT", 6, 0)
bulkTrackBtn:SetText("Toggle Timeline Track")

-- Scrollable Spell List Frame
local scrollFrame = CreateFrame("ScrollFrame", "FlowCoreSpellsScrollFrame", spellsContent, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", spellsContent, "TOPLEFT", 0, -56)
scrollFrame:SetPoint("BOTTOMRIGHT", spellsContent, "BOTTOMRIGHT", -26, 0)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(500, 10)
scrollFrame:SetScrollChild(scrollChild)

local spellRows = {}
local sectionHeaders = {}
local ROW_HEIGHT = 32
local HEADER_HEIGHT = 22

-- Dropdown Menu Frame
local roleDropdownMenu = CreateFrame("Frame", "FlowCoreRoleDropdownMenu", configFrame)
roleDropdownMenu:SetFrameStrata("TOOLTIP")
roleDropdownMenu:SetSize(210, #SPELL_SECTIONS * 20 + 8)
roleDropdownMenu:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
roleDropdownMenu:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
roleDropdownMenu:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.9)
roleDropdownMenu:EnableMouse(true)
roleDropdownMenu:Hide()

local dropdownDismissOverlay = CreateFrame("Button", "FlowCoreDropdownDismissOverlay", configFrame)
dropdownDismissOverlay:SetFrameStrata("FULLSCREEN_DIALOG")
dropdownDismissOverlay:SetAllPoints(UIParent)
dropdownDismissOverlay:EnableMouse(true)
dropdownDismissOverlay:RegisterForClicks("LeftButtonDown", "RightButtonDown")
dropdownDismissOverlay:SetScript("OnClick", function()
    roleDropdownMenu:Hide()
    dropdownDismissOverlay:Hide()
end)
dropdownDismissOverlay:Hide()

roleDropdownMenu:SetScript("OnHide", function()
    dropdownDismissOverlay:Hide()
end)

roleDropdownMenu.buttons = {}
for i, sec in ipairs(SPELL_SECTIONS) do
    local btn = CreateFrame("Button", nil, roleDropdownMenu)
    btn:SetSize(200, 19)
    btn:SetPoint("TOPLEFT", roleDropdownMenu, "TOPLEFT", 5, - (4 + (i - 1) * 20))

    local btnBg = btn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints(btn)
    btnBg:SetTexture(1, 1, 1, 0)
    btn.bg = btnBg

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btnText:SetText(sec.color .. sec.name .. "|r")
    btn.text = btnText

    btn:SetScript("OnEnter", function(self) self.bg:SetTexture(0.2, 0.5, 0.8, 0.4) end)
    btn:SetScript("OnLeave", function(self) self.bg:SetTexture(1, 1, 1, 0) end)

    btn:SetScript("OnClick", function()
        if roleDropdownMenu.isBulkMode then
            local count = 0
            for sName in pairs(FC.selectedConfigSpells) do
                FC.db.spellOverrides[sName] = FC.db.spellOverrides[sName] or {}
                FC.db.spellOverrides[sName].role = sec.id
                for _, a in ipairs(FC.actions or {}) do
                    if a.name == sName then a.role = sec.id end
                end
                count = count + 1
            end
            FC:Print(string.format("|cff00ccff[Bulk Action]|r Moved |cff55ff55%d|r selected spells to %s%s|r", count, sec.color, sec.name))
        else
            local aName = roleDropdownMenu.targetSpellName
            local action = roleDropdownMenu.targetAction
            if aName then
                FC.db.spellOverrides[aName] = FC.db.spellOverrides[aName] or {}
                FC.db.spellOverrides[aName].role = sec.id
                if action then action.role = sec.id end
                FC:Print(string.format("%s category set to %s%s|r", aName, sec.color, sec.name))
            end
        end
        roleDropdownMenu:Hide()
        dropdownDismissOverlay:Hide()
        FC:RefreshConfigSpellsList()
    end)

    roleDropdownMenu.buttons[i] = btn
end

bulkCategoryBtn:SetScript("OnClick", function(self)
    if GetSelectedSpellCount() == 0 then
        FC:Print("|cffff8800No spells selected. Check the boxes next to spells first.|r")
        return
    end
    roleDropdownMenu.isBulkMode = true
    roleDropdownMenu.targetSpellName = nil
    roleDropdownMenu:ClearAllPoints()
    roleDropdownMenu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
    dropdownDismissOverlay:Show()
    roleDropdownMenu:Show()
end)

bulkTrackBtn:SetScript("OnClick", function()
    local count = 0
    for sName in pairs(FC.selectedConfigSpells) do
        FC.db.spellOverrides[sName] = FC.db.spellOverrides[sName] or {}
        local cur = FC.db.spellOverrides[sName].trackInTimeline
        FC.db.spellOverrides[sName].trackInTimeline = not cur
        count = count + 1
    end
    FC:Print(string.format("|cff00ccff[Bulk Action]|r Toggled timeline tracking for |cff55ff55%d|r selected spells.", count))
    FC:RefreshConfigSpellsList()
end)

selectAllBtn:SetScript("OnClick", function()
    for _, action in ipairs(FC.actions or {}) do
        if action.name and not action.isSynastriaPerk then
            FC.selectedConfigSpells[action.name] = true
        end
    end
    UpdateBulkCountText()
    FC:RefreshConfigSpellsList()
end)

clearSelBtn:SetScript("OnClick", function()
    FC.selectedConfigSpells = {}
    UpdateBulkCountText()
    FC:RefreshConfigSpellsList()
end)

function FC:RefreshConfigSpellsList()
    local filterText = string.lower(searchBox:GetText() or "")
    UpdateBulkCountText()

    for _, header in ipairs(sectionHeaders) do header:Hide() end
    for _, row in ipairs(spellRows) do row:Hide() end

    local groupedSpells = {}
    for _, sec in ipairs(SPELL_SECTIONS) do groupedSpells[sec.id] = {} end

    local seenSpells = {}
    for _, action in ipairs(FC.actions or {}) do
        if action.role ~= "fallback" and action.role ~= "idle" and not action.isSynastriaPerk then
            local aName = action.name or "Unknown"
            if not seenSpells[aName] then
                seenSpells[aName] = true
                if filterText == "" or string.find(string.lower(aName), filterText, 1, true) then
                    local effRole = action.role or "utility"
                    if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[aName] and FC.db.spellOverrides[aName].role then
                        effRole = FC.db.spellOverrides[aName].role
                    end
                    if not groupedSpells[effRole] then groupedSpells[effRole] = {} end
                    table.insert(groupedSpells[effRole], action)
                end
            end
        end
    end

    local currentY = 0
    local headerIndex = 0
    local rowIndex = 0

    for _, sec in ipairs(SPELL_SECTIONS) do
        local list = groupedSpells[sec.id] or {}
        if #list > 0 then
            table.sort(list, function(a, b)
                local pA = (FC.db and FC.db.spellOverrides and FC.db.spellOverrides[a.name] and FC.db.spellOverrides[a.name].priority) or a.priority or 0
                local pB = (FC.db and FC.db.spellOverrides and FC.db.spellOverrides[b.name] and FC.db.spellOverrides[b.name].priority) or b.priority or 0
                return pA > pB
            end)

            headerIndex = headerIndex + 1
            local header = sectionHeaders[headerIndex]
            if not header then
                header = CreateFrame("Frame", "FlowCoreSectionHeader_" .. headerIndex, scrollChild)
                header:SetSize(490, HEADER_HEIGHT)
                local hBg = header:CreateTexture(nil, "BACKGROUND")
                hBg:SetAllPoints(header)
                hBg:SetTexture(0.2, 0.25, 0.35, 0.5)
                header.bg = hBg

                local hText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                hText:SetPoint("LEFT", header, "LEFT", 8, 0)
                header.text = hText
                sectionHeaders[headerIndex] = header
            end

            header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
            header.text:SetText(string.format("%s=== %s (%d) ===|r", sec.color, sec.name, #list))
            header:Show()
            currentY = currentY + HEADER_HEIGHT + 2

            for _, action in ipairs(list) do
                rowIndex = rowIndex + 1
                local row = spellRows[rowIndex]
                local aName = action.name or "Unknown"

                if not row then
                    row = CreateFrame("Frame", "FlowCoreSpellRow_" .. rowIndex, scrollChild)
                    row:SetSize(490, ROW_HEIGHT)

                    local rowBg = row:CreateTexture(nil, "BACKGROUND")
                    rowBg:SetAllPoints(row)
                    rowBg:SetTexture(0.12, 0.12, 0.12, 0.5)
                    row.bg = rowBg

                    -- Multi-Select Checkbox (Phase 3)
                    local selCB = CreateFrame("CheckButton", "FlowCoreSpellRowSelCB_" .. rowIndex, row, "UICheckButtonTemplate")
                    selCB:SetSize(20, 20)
                    selCB:SetPoint("LEFT", row, "LEFT", 2, 0)
                    row.selCB = selCB

                    -- Enable/Disable Checkbutton
                    local cb = CreateFrame("CheckButton", "FlowCoreSpellRowCB_" .. rowIndex, row, "UICheckButtonTemplate")
                    cb:SetSize(20, 20)
                    cb:SetPoint("LEFT", selCB, "RIGHT", 2, 0)
                    row.cb = cb

                    -- Spell Icon
                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(24, 24)
                    icon:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    row.icon = icon

                    -- Spell Name
                    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameText:SetPoint("LEFT", icon, "RIGHT", 4, 0)
                    nameText:SetWidth(125)
                    nameText:SetJustifyH("LEFT")
                    row.nameText = nameText

                    -- Role Dropdown Button
                    local rBtn = CreateFrame("Button", "FlowCoreSpellRowRoleBtn_" .. rowIndex, row, "UIPanelButtonTemplate")
                    rBtn:SetSize(75, 20)
                    rBtn:SetPoint("LEFT", nameText, "RIGHT", 2, 0)
                    row.roleBtn = rBtn

                    -- Track in Timeline CheckButton
                    local trackCB = CreateFrame("CheckButton", "FlowCoreSpellRowTrackCB_" .. rowIndex, row, "UICheckButtonTemplate")
                    trackCB:SetSize(18, 18)
                    trackCB:SetPoint("LEFT", rBtn, "RIGHT", 4, 0)
                    row.trackCB = trackCB

                    local trackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    trackText:SetPoint("LEFT", trackCB, "RIGHT", 0, 0)
                    trackText:SetText("|cff00ccffTrack|r")
                    row.trackText = trackText

                    -- Priority
                    local prioText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    prioText:SetPoint("RIGHT", row, "RIGHT", -50, 0)
                    prioText:SetWidth(40)
                    prioText:SetJustifyH("RIGHT")
                    row.prioText = prioText

                    local minusBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    minusBtn:SetSize(20, 20)
                    minusBtn:SetPoint("RIGHT", row, "RIGHT", -26, 0)
                    minusBtn:SetText("-")
                    row.minusBtn = minusBtn

                    local plusBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    plusBtn:SetSize(20, 20)
                    plusBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                    plusBtn:SetText("+")
                    row.plusBtn = plusBtn

                    spellRows[rowIndex] = row
                end

                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
                row.action = action
                row.icon:SetTexture(action.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.nameText:SetText(aName)

                local effRole = action.role or "utility"
                local isEnabled = true
                local currPrio = action.priority or 0
                local isTracked = false

                if FC.IsSpellTrackedInTimeline then
                    isTracked = FC:IsSpellTrackedInTimeline(aName, action)
                elseif action.role == "cooldown" or action.role == "defensive" or action.role == "mana" or action.role == "trinket" then
                    isTracked = true
                end

                if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[aName] then
                    local ov = FC.db.spellOverrides[aName]
                    if ov.role ~= nil then effRole = ov.role end
                    if ov.enabled ~= nil then isEnabled = ov.enabled end
                    if ov.priority ~= nil then currPrio = ov.priority end
                    if ov.trackInTimeline ~= nil then isTracked = ov.trackInTimeline end
                end

                row.selCB:SetChecked(FC.selectedConfigSpells[aName] == true)
                row.cb:SetChecked(isEnabled)
                row.roleBtn:SetText(sec.color .. tostring(effRole) .. "|r")
                row.prioText:SetText(tostring(currPrio))
                row.trackCB:SetChecked(isTracked == true)

                row.selCB:SetScript("OnClick", function(self)
                    local isSel = (self:GetChecked() == 1 or self:GetChecked() == true)
                    if isSel then
                        FC.selectedConfigSpells[aName] = true
                    else
                        FC.selectedConfigSpells[aName] = nil
                    end
                    UpdateBulkCountText()
                end)

                row.cb:SetScript("OnClick", function(self)
                    local val = (self:GetChecked() == 1 or self:GetChecked() == true)
                    FC.db.spellOverrides[aName] = FC.db.spellOverrides[aName] or {}
                    FC.db.spellOverrides[aName].enabled = val
                    action.enabled = val
                    FC:Print(string.format("%s %s", aName, val and "|cff55ff55ENABLED|r" or "|cffff2222DISABLED|r"))
                end)

                row.trackCB:SetScript("OnClick", function(self)
                    local val = (self:GetChecked() == 1 or self:GetChecked() == true)
                    FC.db.spellOverrides[aName] = FC.db.spellOverrides[aName] or {}
                    FC.db.spellOverrides[aName].trackInTimeline = val
                    FC:Print(string.format("%s timeline tracking %s", aName, val and "|cff55ff55ENABLED|r" or "|cffff2222DISABLED|r"))
                end)

                row.roleBtn:SetScript("OnClick", function(self)
                    roleDropdownMenu.isBulkMode = false
                    roleDropdownMenu.targetSpellName = aName
                    roleDropdownMenu.targetAction = action
                    roleDropdownMenu:ClearAllPoints()
                    roleDropdownMenu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
                    dropdownDismissOverlay:Show()
                    roleDropdownMenu:Show()
                end)

                row.minusBtn:SetScript("OnClick", function()
                    FC.db.spellOverrides[aName] = FC.db.spellOverrides[aName] or {}
                    local newPrio = (FC.db.spellOverrides[aName].priority or action.priority or 0) - 5
                    FC.db.spellOverrides[aName].priority = newPrio
                    row.prioText:SetText(tostring(newPrio))
                    FC:RefreshConfigSpellsList()
                end)

                row.plusBtn:SetScript("OnClick", function()
                    FC.db.spellOverrides[aName] = FC.db.spellOverrides[aName] or {}
                    local newPrio = (FC.db.spellOverrides[aName].priority or action.priority or 0) + 5
                    FC.db.spellOverrides[aName].priority = newPrio
                    row.prioText:SetText(tostring(newPrio))
                    FC:RefreshConfigSpellsList()
                end)

                row:Show()
                currentY = currentY + ROW_HEIGHT + 2
            end
            currentY = currentY + 4
        end
    end

    scrollChild:SetHeight(math.max(10, currentY))
end

searchBox:SetScript("OnTextChanged", function()
    FC:RefreshConfigSpellsList()
end)

-- =====================================================
-- TAB 3: SYNASTRIA PERKS & CLASS SET BONUSES
-- =====================================================
local perkTopPanel = CreateFrame("Frame", nil, perksContent)
perkTopPanel:SetPoint("TOPLEFT", perksContent, "TOPLEFT", 0, 0)
perkTopPanel:SetPoint("TOPRIGHT", perksContent, "TOPRIGHT", 0, 0)
perkTopPanel:SetHeight(180)

local perkHeader = perkTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
perkHeader:SetPoint("TOPLEFT", perkTopPanel, "TOPLEFT", 8, -4)
perkHeader:SetText("|cffff88ffSynastria Class Perk Set Bonus Configuration:|r")

local exportPerksBtn = CreateFrame("Button", "FlowCoreExportPerksBtn", perkTopPanel, "UIPanelButtonTemplate")
exportPerksBtn:SetSize(90, 22)
exportPerksBtn:SetPoint("TOPRIGHT", perkTopPanel, "TOPRIGHT", -10, -4)
exportPerksBtn:SetText("Export CSV")
exportPerksBtn:SetScript("OnClick", function()
    if FC.ExportPerksToCSV then
        FC:ExportPerksToCSV()
    end
end)
exportPerksBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Export Perks to CSV", 1, 0.82, 0)
    GameTooltip:AddLine("Exports all discovered perks with IDs, categories, names, assigned classes, sets, and descriptions into CSV format saved in SavedVariables and opens a copyable clipboard window.", 1, 1, 1, true)
    GameTooltip:Show()
end)
exportPerksBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local scanPerksBtn = CreateFrame("Button", "FlowCoreScanPerksBtn", perkTopPanel, "UIPanelButtonTemplate")
scanPerksBtn:SetSize(155, 22)
scanPerksBtn:SetPoint("RIGHT", exportPerksBtn, "LEFT", -6, 0)
scanPerksBtn:SetText("Scan / Cache All Perks")
scanPerksBtn:SetScript("OnClick", function()
    if FC.ScanAndCacheAllPerks then
        FC:ScanAndCacheAllPerks()
    elseif FC.RefreshExtState then
        FC:RefreshExtState()
        FC:RefreshConfigPerksList()
    end
end)
scanPerksBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Scan & Cache Synastria Perks", 1, 0.82, 0)
    GameTooltip:AddLine("Queries native server perk tables, cleans placeholders ($0d, $1d, etc.), builds local calculation caches, and refreshes the perks database for high-precision simulation.", 1, 1, 1, true)
    GameTooltip:Show()
end)
scanPerksBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local setBonusText = perkTopPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
setBonusText:SetWidth(680)
setBonusText:SetJustifyH("LEFT")

local function UpdateClassSetDisplay()
    local setName = FC.db and FC.db.synastriaClassSet or (FC.extState and FC.extState.activeClassSet) or "None"
    local setDef = (FC.discoveredPerkSets and FC.discoveredPerkSets[setName]) or FC.SYNASTRIA_CLASS_SETS[setName]
    local count = (FC.db and FC.db.synastriaClassSetCount) or (FC.extState and FC.extState.classSetCount) or 5

    if setDef then
        setBonusText:SetText(string.format(
            "|cffffd700Active Set:|r |cffffffff%s|r (%d/5 Perks Selected)\n" ..
            "|cff55ff55[2-Perk Bonus (Active)]|r: %s\n" ..
            "|cff55ff55[4-Perk Bonus (%s)]|r: %s",
            setDef.name or setName,
            count,
            setDef.twoPiece or "None",
            count >= 4 and "Active" or "Inactive",
            setDef.fourPiece or "None"
        ))
    else
        setBonusText:SetText("|cffff8888No Class Perk Set selected.|r")
    end
end

-- Filter & Search State (Default to Active + My Class Only for instant load performance)
local perkFilterMode = "active"
local perkMyClassOnly = true
local perkSearchText = ""

local searchBoxPerks = CreateFrame("EditBox", "FlowCorePerksSearchBox", perkTopPanel, "InputBoxTemplate")
searchBoxPerks:SetSize(130, 20)
searchBoxPerks:SetAutoFocus(false)
searchBoxPerks:SetText("")

local searchPlaceholder = searchBoxPerks:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchPlaceholder:SetPoint("LEFT", searchBoxPerks, "LEFT", 4, 0)
searchPlaceholder:SetText("Search perks...")

searchBoxPerks:SetScript("OnTextChanged", function(self)
    local text = string.lower(self:GetText() or "")
    if text == "" then
        searchPlaceholder:Show()
    else
        searchPlaceholder:Hide()
    end
    perkSearchText = text
    FC:RefreshConfigPerksList()
end)

local btnFilterAll = CreateFrame("Button", "FlowCorePerkFilterAll", perkTopPanel, "UIPanelButtonTemplate")
btnFilterAll:SetSize(45, 20)
btnFilterAll:SetPoint("LEFT", searchBoxPerks, "RIGHT", 6, 0)
btnFilterAll:SetText("All")

local btnFilterActive = CreateFrame("Button", "FlowCorePerkFilterActive", perkTopPanel, "UIPanelButtonTemplate")
btnFilterActive:SetSize(55, 20)
btnFilterActive:SetPoint("LEFT", btnFilterAll, "RIGHT", 4, 0)
btnFilterActive:SetText("|cff55ff55Active|r")

local btnFilterInactive = CreateFrame("Button", "FlowCorePerkFilterInactive", perkTopPanel, "UIPanelButtonTemplate")
btnFilterInactive:SetSize(65, 20)
btnFilterInactive:SetPoint("LEFT", btnFilterActive, "RIGHT", 4, 0)
btnFilterInactive:SetText("Inactive")

local function UpdateFilterButtonStates()
    btnFilterAll:SetText(perkFilterMode == "all" and "|cff55ff55All|r" or "All")
    btnFilterActive:SetText(perkFilterMode == "active" and "|cff55ff55Active|r" or "Active")
    btnFilterInactive:SetText(perkFilterMode == "inactive" and "|cff55ff55Inactive|r" or "Inactive")
end

btnFilterAll:SetScript("OnClick", function()
    perkFilterMode = "all"
    UpdateFilterButtonStates()
    FC:RefreshConfigPerksList()
end)

btnFilterActive:SetScript("OnClick", function()
    perkFilterMode = "active"
    UpdateFilterButtonStates()
    FC:RefreshConfigPerksList()
end)

btnFilterInactive:SetScript("OnClick", function()
    perkFilterMode = "inactive"
    UpdateFilterButtonStates()
    FC:RefreshConfigPerksList()
end)

local cbMyClassOnly = CreateFrame("CheckButton", "FlowCorePerkMyClassOnlyCB", perkTopPanel, "UICheckButtonTemplate")
cbMyClassOnly:SetSize(20, 20)
cbMyClassOnly:SetPoint("LEFT", btnFilterInactive, "RIGHT", 8, 0)
cbMyClassOnly:SetChecked(true)

local cbMyClassText = cbMyClassOnly:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cbMyClassText:SetPoint("LEFT", cbMyClassOnly, "RIGHT", 2, 0)
cbMyClassText:SetText("My Class Only")

cbMyClassOnly:SetScript("OnClick", function(self)
    perkMyClassOnly = (self:GetChecked() == 1 or self:GetChecked() == true)
    FC:RefreshConfigPerksList()
end)

local setRules = perkTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
setRules:SetText("|cff00ccffPerk Rules:|r Max 5 perks per category. Sim columns reflect marginal value when replacing lowest active perk.")

-- Perk Column Sort State
local perkSortColumn = "name"
local perkSortAsc = true

local perkColHeaders = {}

local function UpdateColHeaderVisuals()
    for colKey, btn in pairs(perkColHeaders) do
        local baseLabel = btn.baseLabel or ""
        if perkSortColumn == colKey then
            local arrow = perkSortAsc and "|cff55ff55▲|r" or "|cff55ff55▼|r"
            btn.text:SetText(string.format("|cffffffff%s|r %s", baseLabel, arrow))
        else
            btn.text:SetText(string.format("|cffffd700%s|r", baseLabel))
        end
    end
end

-- Column Headers Bar (Pinned & Sortable)
local perkColHeader = CreateFrame("Frame", "FlowCorePerkColHeader", perkTopPanel)
perkColHeader:SetSize(660, 20)
local colBg = perkColHeader:CreateTexture(nil, "BACKGROUND")
colBg:SetAllPoints(perkColHeader)
colBg:SetTexture(0.08, 0.10, 0.16, 0.85)

local function CreateColHeaderButton(x, width, align, labelText, colKey, defaultAsc)
    local btn = CreateFrame("Button", "FlowCorePerkColHdr_" .. colKey, perkColHeader)
    btn:SetPoint("LEFT", perkColHeader, "LEFT", x, 0)
    btn:SetSize(width, 20)
    btn.baseLabel = labelText
    btn.colKey = colKey

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", btn, "LEFT", 0, 0)
    txt:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
    txt:SetJustifyH(align)
    btn.text = txt

    btn:SetScript("OnClick", function()
        if perkSortColumn == colKey then
            perkSortAsc = not perkSortAsc
        else
            perkSortColumn = colKey
            perkSortAsc = (defaultAsc ~= nil) and defaultAsc or false
        end
        UpdateColHeaderVisuals()
        FC:RefreshConfigPerksList()
    end)

    btn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        UpdateColHeaderVisuals()
    end)

    perkColHeaders[colKey] = btn
    return btn
end

CreateColHeaderButton(32, 175, "LEFT", "Perk Name", "name", true)
CreateColHeaderButton(215, 75, "RIGHT", "25H LK", "single", false)
CreateColHeaderButton(295, 75, "RIGHT", "3+ Cleave", "cleave", false)
CreateColHeaderButton(375, 75, "RIGHT", "6+ AoE", "aoe", false)
CreateColHeaderButton(455, 65, "RIGHT", "EHP", "ehp", false)
CreateColHeaderButton(525, 65, "RIGHT", "Score", "score", false)
CreateColHeaderButton(595, 65, "RIGHT", "Status", "status", true)
UpdateColHeaderVisuals()

local perkScrollFrame = CreateFrame("ScrollFrame", "FlowCorePerksScrollFrame", perksContent, "UIPanelScrollFrameTemplate")
perkScrollFrame:SetPoint("BOTTOMRIGHT", perksContent, "BOTTOMRIGHT", -26, 0)

local perkScrollChild = CreateFrame("Frame", nil, perkScrollFrame)
perkScrollChild:SetSize(660, 10)
perkScrollFrame:SetScrollChild(perkScrollChild)

local classSetButtons = {}
local function CreateDynamicClassSetButtons()
    for _, btn in ipairs(classSetButtons) do btn:Hide() end
    local pClass = FC.playerClass or (UnitClass and select(2, UnitClass("player"))) or "DEATHKNIGHT"

    local matchingSets = {}
    local seen = {}

    -- 1. Sets discovered dynamically from PerkMgrSets & SynastriaCoreLib strictly for player's class
    for sName, sDef in pairs(FC.discoveredPerkSets or {}) do
        if type(sName) == "string" and not seen[sName] then
            if sDef.class == pClass then
                seen[sName] = true
                table.insert(matchingSets, sName)
            end
        end
    end

    -- 2. Fallback to SYNASTRIA_CLASS_SETS if no native sets discovered
    if #matchingSets == 0 then
        for sName, sDef in pairs(FC.SYNASTRIA_CLASS_SETS or {}) do
            if type(sName) == "string" and not seen[sName] then
                if sDef.class == pClass then
                    seen[sName] = true
                    table.insert(matchingSets, sName)
                end
            end
        end
    end

    table.sort(matchingSets)

    if #matchingSets == 0 then
        table.insert(matchingSets, "Unholy Death Knight")
    end

    local curSet = FC.db and FC.db.synastriaClassSet
    local hasValidCurSet = false
    for _, sName in ipairs(matchingSets) do
        if curSet == sName then
            hasValidCurSet = true
            break
        end
    end
    if not hasValidCurSet and #matchingSets > 0 then
        FC.db.synastriaClassSet = matchingSets[1]
        curSet = matchingSets[1]
    end

    -- Buttons sit cleanly in Row 2 below Header
    local buttonStartY = -30
    for idx, sName in ipairs(matchingSets) do
        local btn = classSetButtons[idx]
        if not btn then
            btn = CreateFrame("Button", "FlowCoreClassSetBtn_" .. idx, perkTopPanel, "UIPanelButtonTemplate")
            btn:SetSize(160, 20)
            classSetButtons[idx] = btn
        end
        local col = (idx - 1) % 4
        local row = math.floor((idx - 1) / 4)
        btn:SetPoint("TOPLEFT", perkTopPanel, "TOPLEFT", 8 + col * 168, buttonStartY - row * 22)
        btn:SetSize(160, 20)

        local isSelected = (curSet == sName)
        btn:SetText(isSelected and ("|cff55ff55" .. sName .. "|r") or sName)
        btn:SetScript("OnClick", function()
            FC.db.synastriaClassSet = sName
            FC.db.synastriaClassSetCount = 5
            UpdateClassSetDisplay()
            CreateDynamicClassSetButtons()
            FC:Print(string.format("Synastria Class Set set to |cffff88ff%s|r (4pc bonus active).", sName))
        end)
        btn:Show()
    end

    local totalRows = math.max(1, math.ceil(#matchingSets / 4))
    local bonusTextY = buttonStartY - (totalRows * 22) - 6
    setBonusText:ClearAllPoints()
    setBonusText:SetPoint("TOPLEFT", perkTopPanel, "TOPLEFT", 10, bonusTextY)

    local bonusTextHeight = 76
    local filterBarY = bonusTextY - bonusTextHeight - 6

    searchBoxPerks:ClearAllPoints()
    searchBoxPerks:SetPoint("TOPLEFT", perkTopPanel, "TOPLEFT", 15, filterBarY)

    setRules:ClearAllPoints()
    setRules:SetPoint("TOPLEFT", perkTopPanel, "TOPLEFT", 10, filterBarY - 24)

    perkColHeader:ClearAllPoints()
    perkColHeader:SetPoint("TOPLEFT", perkTopPanel, "TOPLEFT", 0, filterBarY - 44)

    local topHeight = math.abs(filterBarY) + 68
    perkTopPanel:SetHeight(topHeight)

    perkScrollFrame:ClearAllPoints()
    perkScrollFrame:SetPoint("TOPLEFT", perksContent, "TOPLEFT", 0, -topHeight - 4)
    perkScrollFrame:SetPoint("BOTTOMRIGHT", perksContent, "BOTTOMRIGHT", -26, 0)
end

local function FormatSimNum(val)
    val = tonumber(val) or 0
    if val >= 100000 then
        return string.format("%.0fk", val / 1000)
    elseif val >= 10000 then
        return string.format("%.1fk", val / 1000)
    else
        return tostring(math.floor(val))
    end
end

local perkRows = {}
local perkSectionHeaders = {}
local PERK_SECTIONS = {
    { id = "Class",     name = "Class Perks",      color = "|cffff88ff" },
    { id = "Offensive", name = "Offensive Perks",  color = "|cffff6666" },
    { id = "Defensive", name = "Defensive Perks",  color = "|cff6666ff" },
    { id = "Support",   name = "Support Perks",    color = "|cff44ff44" },
    { id = "Utility",   name = "Utility Perks",    color = "|cffdddd44" },
    { id = "Misc",      name = "Misc / QoL Perks", color = "|cff888888" },
}

function FC:RefreshConfigPerksList()
    UpdateClassSetDisplay()
    CreateDynamicClassSetButtons()
    for _, row in ipairs(perkRows) do row:Hide() end
    for _, h in ipairs(perkSectionHeaders) do h:Hide() end

    local baseSim, lowestActiveInCat, minScoreInCat, GetSwapSim = self:SimulatePerkSwapMetrics()

    local ext = FC.extState or {}
    local cats = ext.categories or {}
    local currentY = 0
    local headerIndex = 0
    local rowIndex = 0

    for _, sec in ipairs(PERK_SECTIONS) do
        local rawList = cats[sec.id] or {}
        local filteredList = {}

        for _, perk in ipairs(rawList) do
            local matches = true

            -- 1. Search Query Filter
            if perkSearchText ~= "" then
                local pName = string.lower(perk.name or "")
                local pDesc = string.lower(perk.description or "")
                if not string.find(pName, perkSearchText, 1, true) and not string.find(pDesc, perkSearchText, 1, true) then
                    matches = false
                end
            end

            -- 2. Active / Inactive Filter
            if matches then
                if perkFilterMode == "active" and not perk.active then
                    matches = false
                elseif perkFilterMode == "inactive" and perk.active then
                    matches = false
                end
            end

            -- 3. My Class Only Filter
            if matches and perkMyClassOnly then
                if FC.IsPerkForPlayerClass and not FC:IsPerkForPlayerClass(perk) then
                    matches = false
                end
            end

            if matches then
                table.insert(filteredList, perk)
            end
        end

        if #filteredList > 0 then
            headerIndex = headerIndex + 1
            local header = perkSectionHeaders[headerIndex]
            if not header then
                header = CreateFrame("Frame", "FlowCorePerkSectionHeader_" .. headerIndex, perkScrollChild)
                header:SetSize(660, HEADER_HEIGHT)
                local hBg = header:CreateTexture(nil, "BACKGROUND")
                hBg:SetAllPoints(header)
                hBg:SetTexture(0.2, 0.25, 0.35, 0.5)
                header.bg = hBg

                local hText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                hText:SetPoint("LEFT", header, "LEFT", 8, 0)
                header.text = hText
                perkSectionHeaders[headerIndex] = header
            end

            local activeCount = 0
            for _, p in ipairs(filteredList) do
                if p.active then activeCount = activeCount + 1 end
            end

            header:SetPoint("TOPLEFT", perkScrollChild, "TOPLEFT", 0, -currentY)
            header.text:SetText(string.format("%s=== %s (%d Active / %d Showing) ===|r", sec.color, sec.name, activeCount, #filteredList))
            header:Show()
            currentY = currentY + HEADER_HEIGHT + 2

            -- Pre-calculate benchmark / swap values ONCE per perk for instantaneous O(1) sort comparisons
            for _, p in ipairs(filteredList) do
                if p.active then
                    local sim = p._sim or baseSim
                    p._calcVal = (perkSortColumn == "score" and (p._marginalScore or sim.score)) or sim[perkSortColumn] or 0
                else
                    local swap = GetSwapSim(p, sec.id)
                    p._swapSim = swap
                    p._baseSim = baseSim
                    p._calcVal = swap[perkSortColumn] or 0
                end
            end

            table.sort(filteredList, function(a, b)
                if perkSortColumn == "status" then
                    if a.active ~= b.active then
                        if perkSortAsc then
                            return a.active and not b.active
                        else
                            return not a.active and b.active
                        end
                    end
                    return (a.name or "") < (b.name or "")
                elseif perkSortColumn == "name" then
                    local nameA = a.name or ""
                    local nameB = b.name or ""
                    if nameA ~= nameB then
                        if perkSortAsc then
                            return nameA < nameB
                        else
                            return nameA > nameB
                        end
                    end
                    return (a.id or 0) < (b.id or 0)
                else
                    local valA = a._calcVal or 0
                    local valB = b._calcVal or 0
                    if valA ~= valB then
                        if perkSortAsc then
                            return valA < valB
                        else
                            return valA > valB
                        end
                    end
                    return (a.name or "") < (b.name or "")
                end
            end)

            for _, perk in ipairs(filteredList) do
                rowIndex = rowIndex + 1
                local row = perkRows[rowIndex]
                local pName = perk.name or "Perk"

                if not row then
                    row = CreateFrame("Frame", "FlowCorePerkRow_" .. rowIndex, perkScrollChild)
                    row:SetSize(660, ROW_HEIGHT)

                    local rowBg = row:CreateTexture(nil, "BACKGROUND")
                    rowBg:SetAllPoints(row)
                    rowBg:SetTexture(0.12, 0.12, 0.12, 0.5)
                    row.bg = rowBg

                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(22, 22)
                    icon:SetPoint("LEFT", row, "LEFT", 4, 0)
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    row.icon = icon

                    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                    nameText:SetWidth(180)
                    nameText:SetJustifyH("LEFT")
                    row.nameText = nameText

                    local singleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    singleText:SetPoint("LEFT", row, "LEFT", 215, 0)
                    singleText:SetWidth(75)
                    singleText:SetJustifyH("RIGHT")
                    row.singleText = singleText

                    local cleaveText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    cleaveText:SetPoint("LEFT", row, "LEFT", 295, 0)
                    cleaveText:SetWidth(75)
                    cleaveText:SetJustifyH("RIGHT")
                    row.cleaveText = cleaveText

                    local aoeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    aoeText:SetPoint("LEFT", row, "LEFT", 375, 0)
                    aoeText:SetWidth(75)
                    aoeText:SetJustifyH("RIGHT")
                    row.aoeText = aoeText

                    local ehpText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    ehpText:SetPoint("LEFT", row, "LEFT", 455, 0)
                    ehpText:SetWidth(65)
                    ehpText:SetJustifyH("RIGHT")
                    row.ehpText = ehpText

                    local scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    scoreText:SetPoint("LEFT", row, "LEFT", 525, 0)
                    scoreText:SetWidth(65)
                    scoreText:SetJustifyH("RIGHT")
                    row.scoreText = scoreText

                    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    statusText:SetPoint("LEFT", row, "LEFT", 595, 0)
                    statusText:SetWidth(65)
                    statusText:SetJustifyH("RIGHT")
                    row.statusText = statusText

                    row:EnableMouse(true)
                    row:SetScript("OnEnter", function(self)
                        if not self.perk then return end
                        local p = self.perk
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:ClearLines()

                        -- 1. Perk Name in Gold
                        GameTooltip:AddLine(p.name or "Perk", 1, 0.82, 0)

                        -- 2. Perk Description (Formatted & Cleaned of Placeholders)
                        local desc = p.description
                        if not desc or desc == "" then
                            if p.id and _G.PerkMgrPerks and _G.PerkMgrPerks[p.id] then
                                local rawP = _G.PerkMgrPerks[p.id]
                                desc = rawP.description or rawP.desc or rawP.tooltip or rawP.text
                            end
                            if (not desc or desc == "") and p.id and LibStub and LibStub("SynastriaCoreLib-1.0", true) then
                                local coreLib = LibStub("SynastriaCoreLib-1.0", true)
                                if coreLib and coreLib.Perks and type(coreLib.Perks.GetPerk) == "function" then
                                    local ok, libP = pcall(coreLib.Perks.GetPerk, coreLib.Perks, p.id)
                                    if ok and type(libP) == "table" then
                                        desc = libP.description or libP.tooltip or libP.text
                                    end
                                end
                            end
                        end

                        if desc and desc ~= "" then
                            local formattedDesc = (FC.FormatPerkDescription and FC:FormatPerkDescription(desc, p.spellId, p.name, p.id, p)) or desc
                            GameTooltip:AddLine(formattedDesc, 1, 1, 1, true)
                        end

                        -- 3. Perk Set Details
                        local pSet = p.setName
                        if not pSet and FC.discoveredPerkSets and p.id then
                            for sName, sDef in pairs(FC.discoveredPerkSets) do
                                if type(sName) == "string" and sDef.perks then
                                    for _, pId in ipairs(sDef.perks) do
                                        if pId == p.id then
                                            pSet = sName
                                            break
                                        end
                                    end
                                end
                                if pSet then break end
                            end
                        end

                        if pSet then
                            local setDef = (FC.discoveredPerkSets and FC.discoveredPerkSets[pSet]) or (FC.SYNASTRIA_CLASS_SETS and FC.SYNASTRIA_CLASS_SETS[pSet])
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine("|cffffd700Perk Set: " .. pSet .. "|r", 1, 0.82, 0)
                            if setDef then
                                if setDef.twoPiece and setDef.twoPiece ~= "" then
                                    GameTooltip:AddLine("|cff55ff55(2) Set Bonus:|r " .. setDef.twoPiece, 0.9, 0.9, 0.9, true)
                                end
                                if setDef.fourPiece and setDef.fourPiece ~= "" then
                                    GameTooltip:AddLine("|cff55ff55(4) Set Bonus:|r " .. setDef.fourPiece, 0.9, 0.9, 0.9, true)
                                end
                            end
                        end

                        -- 4. Simulation & Marginal Comparison
                        local curRole = (FC.db and FC.db.playerRole) or "DPS"
                        local curApp = (FC.db and FC.db.combatApproach) or "Balanced"

                        if p.active then
                            local sim = p._sim or baseSim
                            local mScore = p._marginalScore or sim.score
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(string.format("|cffffd700Active Build Simulation (%s / %s):|r", curRole, curApp), 1, 0.82, 0)
                            GameTooltip:AddDoubleLine("• 25H Lich King:", string.format("~%s DPS", FormatSimNum(sim.single)), 0.8, 0.8, 0.8, 0.33, 1, 0.33)
                            GameTooltip:AddDoubleLine("• 3+ Cleave:", string.format("~%s DPS", FormatSimNum(sim.cleave)), 0.8, 0.8, 0.8, 0.33, 1, 0.33)
                            GameTooltip:AddDoubleLine("• 6+ AoE:", string.format("~%s DPS", FormatSimNum(sim.aoe)), 0.8, 0.8, 0.8, 0.33, 1, 0.33)
                            GameTooltip:AddDoubleLine("• Effective Health (EHP):", string.format("~%s EHP", FormatSimNum(sim.ehp)), 0.8, 0.8, 0.8, 0.33, 1, 0.33)
                            GameTooltip:AddDoubleLine("• Marginal Value Contribution:", string.format("+%s pts", FormatSimNum(mScore)), 0.8, 0.8, 0.8, 1, 0.82, 0)
                        else
                            local s = p._swapSim or baseSim
                            local b = p._baseSim or baseSim
                            local dSingle = s.single - b.single
                            local dCleave = s.cleave - b.cleave
                            local dAoe = s.aoe - b.aoe
                            local dEhp = s.ehp - b.ehp
                            local dScore = s.score - b.score

                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(string.format("|cffffd700Marginal Swap Sim (Replaces lowest active in %s):|r", tostring(p.category)), 1, 0.82, 0)
                            GameTooltip:AddDoubleLine("• 25H Lich King:", string.format("~%s DPS (%s%+d|r)", FormatSimNum(s.single), (dSingle > 0 and "|cff55ff55") or (dSingle == 0 and "|cffffd700") or "|cff888888", dSingle), 0.8, 0.8, 0.8, 1, 1, 1)
                            GameTooltip:AddDoubleLine("• 3+ Cleave:", string.format("~%s DPS (%s%+d|r)", FormatSimNum(s.cleave), (dCleave > 0 and "|cff55ff55") or (dCleave == 0 and "|cffffd700") or "|cff888888", dCleave), 0.8, 0.8, 0.8, 1, 1, 1)
                            GameTooltip:AddDoubleLine("• 6+ AoE:", string.format("~%s DPS (%s%+d|r)", FormatSimNum(s.aoe), (dAoe > 0 and "|cff55ff55") or (dAoe == 0 and "|cffffd700") or "|cff888888", dAoe), 0.8, 0.8, 0.8, 1, 1, 1)
                            GameTooltip:AddDoubleLine("• Effective Health (EHP):", string.format("~%s EHP (%s%+d|r)", FormatSimNum(s.ehp), (dEhp > 0 and "|cff55ff55") or (dEhp == 0 and "|cffffd700") or "|cff888888", dEhp), 0.8, 0.8, 0.8, 1, 1, 1)
                            GameTooltip:AddDoubleLine("• Projected Score (" .. curRole .. "/" .. curApp .. "):", string.format("%s pts (%s%+d|r)", FormatSimNum(s.score), (dScore > 0 and "|cff55ff55") or (dScore == 0 and "|cffffd700") or "|cff888888", dScore), 1, 0.82, 0, 1, 1, 1)
                        end

                        -- 5. Footer Details
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddDoubleLine("Category:", tostring(p.category), 0.7, 0.7, 0.7, 0.2, 0.8, 1)
                        if p.id and p.id > 0 then
                            GameTooltip:AddDoubleLine("Perk ID:", tostring(p.id), 0.7, 0.7, 0.7, 0.8, 0.8, 0.8)
                        end
                        GameTooltip:AddDoubleLine("Status:", p.active and "|cff55ff55[ACTIVE]|r" or "|cff888888[INACTIVE]|r", 0.7, 0.7, 0.7, 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    perkRows[rowIndex] = row
                end

                row:SetPoint("TOPLEFT", perkScrollChild, "TOPLEFT", 0, -currentY)
                row.perk = perk

                local iconPath = (FC.FormatPerkIcon and FC.FormatPerkIcon(perk.icon, perk.spellId, perk.name, perk.id, perk)) or (perk.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.icon:SetTexture(iconPath)
                row.nameText:SetText(pName)

                if perk.active then
                    local sim = perk._sim or baseSim
                    local mScore = perk._marginalScore or 0
                    local minCatScore = minScoreInCat[sec.id] or 0

                    local singleCol = (mScore > minCatScore and "|cff55ff55") or (mScore == minCatScore and "|cffffd700") or "|cff888888"
                    local cleaveCol = singleCol
                    local aoeCol = singleCol
                    local ehpCol = singleCol
                    local scoreCol = singleCol

                    row.singleText:SetText(singleCol .. FormatSimNum(sim.single) .. "|r")
                    row.cleaveText:SetText(cleaveCol .. FormatSimNum(sim.cleave) .. "|r")
                    row.aoeText:SetText(aoeCol .. FormatSimNum(sim.aoe) .. "|r")
                    row.ehpText:SetText(ehpCol .. FormatSimNum(sim.ehp) .. "|r")
                    row.scoreText:SetText(scoreCol .. FormatSimNum(mScore > 0 and mScore or sim.score) .. "|r")
                    row.statusText:SetText("|cff55ff55[ACTIVE]|r")
                    row.nameText:SetTextColor(1, 0.9, 0.4)
                else
                    local swapSim = GetSwapSim(perk, sec.id)
                    perk._swapSim = swapSim
                    perk._baseSim = baseSim

                    local singleCol = (swapSim.single > baseSim.single and "|cff55ff55") or (swapSim.single == baseSim.single and "|cffffd700") or "|cff888888"
                    local cleaveCol = (swapSim.cleave > baseSim.cleave and "|cff55ff55") or (swapSim.cleave == baseSim.cleave and "|cffffd700") or "|cff888888"
                    local aoeCol = (swapSim.aoe > baseSim.aoe and "|cff55ff55") or (swapSim.aoe == baseSim.aoe and "|cffffd700") or "|cff888888"
                    local ehpCol = (swapSim.ehp > baseSim.ehp and "|cff55ff55") or (swapSim.ehp == baseSim.ehp and "|cffffd700") or "|cff888888"
                    local scoreCol = (swapSim.score > baseSim.score and "|cff55ff55") or (swapSim.score == baseSim.score and "|cffffd700") or "|cff888888"

                    row.singleText:SetText(singleCol .. FormatSimNum(swapSim.single) .. "|r")
                    row.cleaveText:SetText(cleaveCol .. FormatSimNum(swapSim.cleave) .. "|r")
                    row.aoeText:SetText(aoeCol .. FormatSimNum(swapSim.aoe) .. "|r")
                    row.ehpText:SetText(ehpCol .. FormatSimNum(swapSim.ehp) .. "|r")
                    row.scoreText:SetText(scoreCol .. FormatSimNum(swapSim.score) .. "|r")
                    row.statusText:SetText("|cff888888[INACTIVE]|r")
                    row.nameText:SetTextColor(0.6, 0.6, 0.6)
                end

                row:Show()
                currentY = currentY + ROW_HEIGHT + 2
            end
        end
    end

    perkScrollChild:SetHeight(math.max(10, currentY + 20))
end

-- =====================================================
-- TAB 4: BUFF GROUPS EXPLANATION & STATUS
-- =====================================================
local buffDesc = buffsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
buffDesc:SetPoint("TOPLEFT", buffsContent, "TOPLEFT", 10, -10)
buffDesc:SetWidth(510)
buffDesc:SetJustifyH("LEFT")
buffDesc:SetText("|cff00ccffExclusive Buff Groups|r prevent multiple overlapping buffs from fighting each other.\n\nFlowCore automatically ensures only ONE buff from each group is maintained, and will never overwrite an existing armor, intellect, or seal mid-fight.\n\n|cffffd700Configured Groups:|r\n- |cffffffffMage Armors|r: Molten Armor, Mage Armor, Ice Armor, Frost Armor\n- |cffffffffIntellect Buffs|r: Arcane Brilliance, Arcane Intellect, Dalaran Brilliance\n- |cffffffffFortitude Buffs|r: Prayer of Fortitude, Power Word: Fortitude\n- |cffffffffSpirit Buffs|r: Prayer of Spirit, Divine Spirit\n- |cffffffffPaladin Seals|r: Seal of Command, Righteousness, Vengeance, Corruption, etc.\n- |cffffffffPaladin Blessings|r: Kings, Might, Wisdom, Sanctuary (Greater & Normal)\n- |cffffffffWarlock Armors|r: Fel Armor, Demon Armor, Demon Skin\n- |cffffffffShaman Shields|r: Lightning Shield, Water Shield, Earth Shield\n- |cffffffffHunter Aspects|r: Dragonhawk, Hawk, Viper, Monkey, Cheetah, Pack\n- |cffffffffDK Presences|r: Blood, Frost, Unholy")

-- =====================================================
-- SMART MOUSEOVER MACRO GENERATOR FUNCTION (Phase 5)
-- =====================================================
function FC:GenerateSmartMouseoverMacros()
    local spellsToMacro = {}
    local classSpells = {
        ["MAGE"] = { "Living Bomb", "Fire Blast", "Pyroblast", "Fireball", "Frostbolt", "Ice Lance", "Counterspell", "Spellsteal", "Polymorph", "Slow", "Arcane Barrage", "Deep Freeze", "Frostfire Bolt", "Scorch", "Blast Wave" },
        ["WARLOCK"] = { "Corruption", "Curse of Agony", "Curse of the Elements", "Curse of Doom", "Immolate", "Shadow Bolt", "Incinerate", "Chaos Bolt", "Haunt", "Unstable Affliction", "Shadowburn", "Death Coil", "Fear", "Banish", "Spell Lock" },
        ["PRIEST"] = { "Shadow Word: Pain", "Vampiric Touch", "Devouring Plague", "Mind Flay", "Mind Blast", "Shadow Word: Death", "Silence", "Dispel Magic", "Psychic Horror", "Flash Heal", "Greater Heal", "Penance", "Renew", "Power Word: Shield" },
        ["DRUID"] = { "Moonfire", "Insect Swarm", "Wrath", "Starfire", "Starsurge", "Faerie Fire", "Entangling Roots", "Cyclone", "Hibernate", "Rejuvenation", "Regrowth", "Lifebloom", "Healing Touch", "Swiftmend", "Nourish" },
        ["SHAMAN"] = { "Flame Shock", "Earth Shock", "Frost Shock", "Wind Shear", "Lightning Bolt", "Chain Lightning", "Lava Burst", "Purge", "Hex", "Lesser Healing Wave", "Healing Wave", "Chain Heal", "Riptide" },
        ["PALADIN"] = { "Judgement of Light", "Judgement of Wisdom", "Judgement of Justice", "Hammer of Wrath", "Holy Shock", "Exorcism", "Hand of Reckoning", "Cleanse", "Hand of Protection", "Hand of Freedom", "Hand of Salvation", "Flash of Light", "Holy Light" },
        ["WARRIOR"] = { "Taunt", "Mocking Blow", "Shoot", "Throw", "Heroic Throw", "Shattering Throw", "Pummel", "Shield Bash", "Execute" },
        ["ROGUE"] = { "Blind", "Kick", "Gouge", "Tricks of the Trade", "Shadowstep", "Deadly Throw" },
        ["DEATHKNIGHT"] = { "Icy Touch", "Plague Strike", "Death Coil", "Dark Command", "Death Grip", "Mind Freeze", "Strangulate", "Chains of Ice" },
        ["HUNTER"] = { "Hunter's Mark", "Serpent Sting", "Concussive Shot", "Silencing Shot", "Chimera Shot", "Kill Shot", "Tranquilizing Shot", "Scare Beast", "Distracting Shot" }
    }

    local pClass = FC.playerClass or "MAGE"
    local candidateList = classSpells[pClass] or { "Fire Blast", "Living Bomb", "Counterspell" }

    for _, sName in ipairs(candidateList) do
        if (FC.knownSpells and (FC.knownSpells[sName] or FC.knownSpells[string.lower(sName)])) or GetSpellInfo(sName) then
            table.insert(spellsToMacro, sName)
        end
    end

    if #spellsToMacro == 0 then
        FC:Print("|cffff8800No known class offensive/utility spells found to macro.|r")
        return
    end

    local numGlobal, numChar = GetNumMacros()
    local maxChar = 18
    local charAvail = maxChar - (numChar or 0)

    local created = 0
    local skipped = 0

    for _, sName in ipairs(spellsToMacro) do
        local cleanName = string.gsub(sName, "[%s%p]+", "")
        local mName = "FC_" .. string.sub(cleanName, 1, 13)
        local mBody = string.format("#showtooltip\n/cast [@mouseover,harm,nodead][@mouseover,help,nodead][] %s", sName)

        if string.len(mBody) <= 255 then
            local existingIndex = GetMacroIndexByName(mName)
            -- If macro exists (in global or character slots), update it
            if existingIndex and existingIndex > 0 then
                EditMacro(existingIndex, mName, "INV_MISC_QUESTIONMARK", mBody)
                created = created + 1
            elseif charAvail > 0 then
                -- Strictly create under Character-Specific Macros (perCharacter = 1)
                local ok, res = pcall(CreateMacro, mName, "INV_MISC_QUESTIONMARK", mBody, 1)
                if ok and res then
                    created = created + 1
                    charAvail = charAvail - 1
                else
                    skipped = skipped + 1
                end
            else
                skipped = skipped + 1
            end
        end
    end

    FC:Print(string.format("|cff00ccff[Smart Macro Generator]|r Successfully created/updated |cff55ff55%d|r Character-Specific mouseover macros (%d skipped - %d/18 Character slots used).", created, skipped, maxChar - charAvail))
    FC:Print("  |cff888888All macros are saved under Character Macros, under 255 characters, and ready to bind.|r")
end

-- =====================================================
-- TOGGLE CONFIG UI FUNCTION
-- =====================================================
function FC:ToggleConfigUI()
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        SelectTab(1)
        FC:RefreshConfigSpellsList()
        FC:RefreshConfigPerksList()
        configFrame:Show()
    end
end

-- =====================================================
-- MINIMAP BUTTON (Interactive Drag & Clickable Access)
-- =====================================================
local mmBtn = CreateFrame("Button", "FlowCoreMinimapButton", Minimap)
mmBtn:SetSize(32, 32)
mmBtn:SetFrameStrata("MEDIUM")
mmBtn:SetFrameLevel(8)
mmBtn:EnableMouse(true)
mmBtn:SetMovable(true)
mmBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmBtn:RegisterForDrag("LeftButton")
mmBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-Button-Highlight")

local mmBg = mmBtn:CreateTexture(nil, "BACKGROUND")
mmBg:SetSize(20, 20)
mmBg:SetPoint("CENTER", mmBtn, "CENTER", 0, 0)
mmBg:SetTexture("Interface\\Icons\\Spell_Fire_FlameShock")
mmBg:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local mmBorder = mmBtn:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(52, 52)
mmBorder:SetPoint("TOPLEFT", mmBtn, "TOPLEFT", 0, 0)
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdateMinimapButtonPosition()
    local angle = (FC.db and FC.db.minimapPos) or 220
    local radius = 80
    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius
    mmBtn:ClearAllPoints()
    mmBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

mmBtn:SetScript("OnDragStart", function(self)
    self.isDragging = true
end)

mmBtn:SetScript("OnDragStop", function(self)
    self.isDragging = false
end)

mmBtn:SetScript("OnUpdate", function(self)
    if self.isDragging then
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if angle < 0 then angle = angle + 360 end
        FC.db = FC.db or {}
        FC.db.minimapPos = angle
        UpdateMinimapButtonPosition()
    end
end)

mmBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            if FC.OpenTalentBuildAdvisor then
                FC:OpenTalentBuildAdvisor()
            end
        else
            FC:ToggleConfigUI()
        end
    elseif button == "RightButton" then
        if FC.ToggleTimelineUI then
            FC:ToggleTimelineUI()
        end
    end
end)

mmBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local specName = (FC.GetActiveSpecName and FC:GetActiveSpecName()) or "Active Spec"
    local role = (FC.db and FC.db.playerRole) or "DPS"
    local approach = (FC.db and FC.db.combatApproach) or "Balanced"
    local set = (FC.extState and FC.extState.activeClassSet) or "None"

    GameTooltip:AddLine("|cff00ccffFlowCore|r |cffffffff(v1.3.0)|r", 1, 1, 1)
    GameTooltip:AddDoubleLine("Spec:", "|cffffd700" .. specName .. "|r", 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine("Role:", "|cff00ffcc" .. role .. "|r", 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine("Approach:", "|cff55ff55" .. approach .. "|r", 0.7, 0.7, 0.7, 1, 1, 1)
    if set ~= "None" then
        GameTooltip:AddDoubleLine("Class Set:", "|cffff88ff" .. set .. "|r", 0.7, 0.7, 0.7, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ccffLeft-Click:|r Open Settings Panel", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cff00ccffRight-Click:|r Toggle Timeline HUD", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cff00ccffShift + Left-Click:|r Build & Perk Advisor", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cff888888Drag to move around Minimap|r", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)

mmBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

function FC:UpdateMinimapButtonVisibility()
    if FC.db and FC.db.showMinimapButton == false then
        mmBtn:Hide()
    else
        mmBtn:Show()
        UpdateMinimapButtonPosition()
    end
end

-- Initialize Minimap Button on load
local mmInit = CreateFrame("Frame")
mmInit:RegisterEvent("PLAYER_LOGIN")
mmInit:SetScript("OnEvent", function()
    if FC.UpdateMinimapButtonVisibility then
        FC:UpdateMinimapButtonVisibility()
    end
end)
