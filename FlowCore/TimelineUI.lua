FlowCore = FlowCore or {}
local FC = FlowCore

-- =====================================================
-- TIMELINE UI CONFIGURATION & CONSTANTS
-- =====================================================
local MAX_ICONS = 7
local HERO_SIZE = 36
local SLOT_SIZE = 30
local ICON_GAP = 5

local TRACK_HEIGHT = 16
local TRACK_BAR_WIDTH = 300
local TRACK_GAP = 6
local TRACK_DURATION = 10.0 -- Far left = 0.0s (NOW), Far right = 10.0s
local MAX_TRACK_ROWS = 8

-- Role Border Colors (RGB)
local ROLE_COLORS = {
    ["execute"]   = { r = 1.0, g = 0.2, b = 0.2 },
    ["builder"]   = { r = 0.9, g = 0.4, b = 0.1 },
    ["nuke"]      = { r = 1.0, g = 0.3, b = 0.1 },
    ["spender"]   = { r = 1.0, g = 0.5, b = 0.1 },
    ["defensive"] = { r = 0.2, g = 0.6, b = 1.0 },
    ["heal"]      = { r = 0.2, g = 0.9, b = 0.3 },
    ["dot"]       = { r = 0.7, g = 0.3, b = 0.9 },
    ["cooldown"]  = { r = 1.0, g = 0.85, b = 0.1 },
    ["trinket"]   = { r = 1.0, g = 0.8, b = 0.2 },
    ["buff"]      = { r = 0.2, g = 0.85, b = 0.85 },
    ["item"]      = { r = 0.4, g = 0.9, b = 0.7 },
    ["interrupt"] = { r = 1.0, g = 0.0, b = 0.3 },
    ["dispel"]    = { r = 0.0, g = 1.0, b = 0.9 },
    ["mana"]      = { r = 0.2, g = 0.5, b = 1.0 },
    ["default"]   = { r = 0.5, g = 0.5, b = 0.5 }
}

-- Calculate total frame width
local FRAME_WIDTH = TRACK_BAR_WIDTH + 20
local ICONS_ONLY_HEIGHT = 76

-- =====================================================
-- MAIN FRAME SETUP
-- =====================================================
local main = CreateFrame("Frame", "FlowCoreTimelineFrame", UIParent)
main:SetSize(FRAME_WIDTH, 200)
main:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
main:SetMovable(true)
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:SetClampedToScreen(true)

-- Background with sleek dark gradient
local bg = main:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(main)
bg:SetTexture(0.04, 0.04, 0.05, 0.90)

-- Border styling
local frameBorder = CreateFrame("Frame", nil, main)
frameBorder:SetAllPoints(main)
frameBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
frameBorder:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.85)

-- =====================================================
-- HEADER BAR (Title, Settings Button, Style Toggle, Phase Indicator)
-- =====================================================
local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", main, "TOPLEFT", 8, -6)
title:SetText("|cff00ccffFlowCore|r |cff888888Timeline|r")

-- Config / Settings Button
local cfgBtn = CreateFrame("Button", "FlowCoreTimelineConfigButton", main)
cfgBtn:SetSize(14, 14)
cfgBtn:SetPoint("LEFT", title, "RIGHT", 6, 0)
local cfgIcon = cfgBtn:CreateTexture(nil, "ARTWORK")
cfgIcon:SetAllPoints(cfgBtn)
cfgIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
cfgIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

cfgBtn:SetScript("OnClick", function()
    if FC.ToggleConfigUI then
        FC:ToggleConfigUI()
    end
end)
cfgBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("FlowCore Configuration", 1, 1, 1)
    GameTooltip:AddLine("Click to configure settings, spells, priorities, and Synastria perks.", 0.6, 0.8, 1, 1)
    GameTooltip:Show()
end)
cfgBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Style Toggle Button (Tracks vs Icons)
local styleBtn = CreateFrame("Button", "FlowCoreTimelineStyleButton", main)
styleBtn:SetSize(14, 14)
styleBtn:SetPoint("LEFT", cfgBtn, "RIGHT", 4, 0)
local styleIcon = styleBtn:CreateTexture(nil, "ARTWORK")
styleIcon:SetAllPoints(styleBtn)
styleIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
styleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

styleBtn:SetScript("OnClick", function()
    if not FC.db then return end
    FC.db.timelineStyle = (FC.db.timelineStyle == "icons") and "tracks" or "icons"
    FC:Print("Timeline style set to: " .. string.upper(FC.db.timelineStyle))
end)
styleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Toggle Timeline View Mode", 1, 1, 1)
    local cur = (FC.db and FC.db.timelineStyle) or "tracks"
    GameTooltip:AddLine("Current Mode: |cffffd700" .. string.upper(cur) .. "|r", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Click to switch between Tracks + Icons & Compact Icon Sequence view.", 0.6, 0.8, 1, 1)
    GameTooltip:Show()
end)
styleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local phaseText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
phaseText:SetPoint("TOPRIGHT", main, "TOPRIGHT", -8, -6)
phaseText:SetText("|cff55ff55READY|r")

-- Dragging & Position Persistence
main:SetScript("OnDragStart", function(self)
    if not (FC.db and FC.db.locked) then
        self:StartMoving()
    end
end)

main:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if FC.db then
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        FC.db.point = point
        FC.db.relativePoint = relativePoint
        FC.db.xOfs = xOfs
        FC.db.yOfs = yOfs
    end
end)

-- Restore Saved Position
function FC:RestoreUIPosition()
    if self.db and self.db.point then
        main:ClearAllPoints()
        main:SetPoint(self.db.point, UIParent, self.db.relativePoint or self.db.point, self.db.xOfs or 0, self.db.yOfs or -200)
    end
    if self.db and self.db.scale then
        main:SetScale(self.db.scale)
    end
    if self.db and self.db.showUI == false then
        main:Hide()
    end

    if self.heroHUD and self.db and self.db.heroHUD_point then
        self.heroHUD:ClearAllPoints()
        self.heroHUD:SetPoint(self.db.heroHUD_point, UIParent, self.db.heroHUD_relPoint or self.db.heroHUD_point, self.db.heroHUD_x or 0, self.db.heroHUD_y or -100)
    end
    if self.heroHUD and self.db and self.db.showHeroHUD == false then
        self.heroHUD:Hide()
    end
end

-- =====================================================
-- CENTRAL FLOATING HERO HUD (Phase 5)
-- Positioned near character center of vision / under feet
-- =====================================================
local heroHUD = CreateFrame("Button", "FlowCoreHeroHUDFrame", UIParent)
heroHUD:SetSize(46, 46)
heroHUD:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
heroHUD:SetMovable(true)
heroHUD:EnableMouse(true)
heroHUD:RegisterForDrag("LeftButton")
heroHUD:SetClampedToScreen(true)

local hudIcon = heroHUD:CreateTexture(nil, "ARTWORK")
hudIcon:SetAllPoints(heroHUD)
hudIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
hudIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
heroHUD.icon = hudIcon

local hudBorder = CreateFrame("Frame", nil, heroHUD)
hudBorder:SetAllPoints(heroHUD)
hudBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 2,
})
hudBorder:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.9)
heroHUD.border = hudBorder

local hudProcGlow = heroHUD:CreateTexture(nil, "OVERLAY")
hudProcGlow:SetPoint("TOPLEFT", heroHUD, "TOPLEFT", -4, 4)
hudProcGlow:SetPoint("BOTTOMRIGHT", heroHUD, "BOTTOMRIGHT", 4, -4)
hudProcGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
hudProcGlow:SetAlpha(0)
heroHUD.procGlow = hudProcGlow

local hudHotkeyFrame = CreateFrame("Frame", nil, heroHUD)
hudHotkeyFrame:SetPoint("BOTTOMRIGHT", heroHUD, "BOTTOMRIGHT", 2, -2)
hudHotkeyFrame:SetSize(18, 14)
hudHotkeyFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
hudHotkeyFrame:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
hudHotkeyFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.95)

local hudHotkeyText = hudHotkeyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hudHotkeyText:SetPoint("CENTER", hudHotkeyFrame, "CENTER", 0, 0)
hudHotkeyText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
hudHotkeyText:SetTextColor(1.0, 0.88, 0.2, 1.0)
heroHUD.hotkeyText = hudHotkeyText
heroHUD.hotkeyFrame = hudHotkeyFrame

heroHUD:SetScript("OnDragStart", function(self)
    if not (FC.db and FC.db.locked) then
        self:StartMoving()
    end
end)
heroHUD:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if FC.db then
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        FC.db.heroHUD_point = point
        FC.db.heroHUD_relPoint = relativePoint
        FC.db.heroHUD_x = xOfs
        FC.db.heroHUD_y = yOfs
    end
end)

-- Off-Target / Mouseover Multi-Dot Prompt Badge
local hudOffTargetBadge = CreateFrame("Frame", nil, heroHUD)
hudOffTargetBadge:SetPoint("TOP", heroHUD, "BOTTOM", 0, -3)
hudOffTargetBadge:SetSize(74, 14)
hudOffTargetBadge:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
hudOffTargetBadge:SetBackdropColor(0.02, 0.10, 0.20, 0.92)
hudOffTargetBadge:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.95)
local hudOffTargetText = hudOffTargetBadge:CreateFontString(nil, "OVERLAY")
hudOffTargetText:SetPoint("CENTER", hudOffTargetBadge, "CENTER", 0, 0)
hudOffTargetText:SetFont("Fonts\\ARIALN.TTF", 9, "OUTLINE")
hudOffTargetText:SetTextColor(0.2, 0.9, 1.0, 1.0)
hudOffTargetText:SetText("OFF-TARGET")
hudOffTargetBadge.text = hudOffTargetText
hudOffTargetBadge:Hide()
heroHUD.offTargetBadge = hudOffTargetBadge

FC.heroHUD = heroHUD

-- =====================================================
-- FULLSCREEN VIGNETTE FLASH & AUDIO CUE ENGINE (Phase 4)
-- =====================================================
local screenGlow = CreateFrame("Frame", "FlowCoreScreenGlow", UIParent)
screenGlow:SetAllPoints(UIParent)
screenGlow:SetFrameStrata("BACKGROUND")
local sgTex = screenGlow:CreateTexture(nil, "BACKGROUND")
sgTex:SetAllPoints(screenGlow)
sgTex:SetTexture("Interface\\FullScreenTextures\\LowHealth")
sgTex:SetBlendMode("ADD")
sgTex:SetAlpha(0)
screenGlow.tex = sgTex
FC.screenGlow = screenGlow

local lastProcSound = 0
function FC:FlashScreen(r, g, b, alpha)
    if self.db and self.db.showScreenGlow == false then return end
    sgTex:SetVertexColor(r or 1, g or 0.8, b or 0.2)
    sgTex:SetAlpha(alpha or 0.45)
    UIFrameFadeOut(screenGlow, 0.45, alpha or 0.45, 0)
end

function FC:PlayProcSound(isEmergency)
    if self.db and self.db.enableSound == false then return end
    local now = GetTime()
    if (now - lastProcSound) < 1.2 then return end
    lastProcSound = now
    if isEmergency then
        PlaySoundFile("Sound\\Spells\\PVPFlagCaptured.wav")
    else
        PlaySoundFile("Sound\\Spells\\Shiffar_NexusHornProc.wav")
    end
end

-- =====================================================
-- ACTION BAR BUTTON GLOW INJECTOR (Phase 5)
-- =====================================================
FC.activeGlowButtons = FC.activeGlowButtons or {}

local function CreateButtonGlow(btn)
    if btn._fcGlow then return btn._fcGlow end
    local glow = CreateFrame("Frame", nil, btn)
    glow:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 3)
    glow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
    glow:SetFrameLevel(btn:GetFrameLevel() + 5)
    glow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2.5
    })
    glow:SetBackdropBorderColor(1.0, 0.85, 0.1, 1.0)

    local glowTex = glow:CreateTexture(nil, "OVERLAY")
    glowTex:SetAllPoints(glow)
    glowTex:SetTexture(1.0, 0.85, 0.1, 0.25)

    glow:Hide()
    btn._fcGlow = glow
    return glow
end

function FC:HideAllButtonGlows()
    for btn, glow in pairs(self.activeGlowButtons or {}) do
        if glow then glow:Hide() end
    end
    self.activeGlowButtons = {}
end

function FC:ShowButtonGlowForAction(actionName, spellId, itemId)
    if self.db and self.db.enableButtonGlow == false then
        self:HideAllButtonGlows()
        return
    end

    self:HideAllButtonGlows()
    if not actionName then return end

    local targetBtn = nil

    -- 1. Check BT4 buttons
    for i = 1, 120 do
        local btn = _G["BT4Button" .. i]
        if btn and btn:IsVisible() and (btn._actionName == actionName or (btn._actionRankedName and string.find(btn._actionRankedName, actionName, 1, true))) then
            targetBtn = btn
            break
        end
    end

    -- 2. Check Dominos buttons
    if not targetBtn then
        for i = 1, 120 do
            local btn = _G["DominosActionButton" .. i]
            if btn and btn:IsVisible() and (btn._actionName == actionName or (btn._actionRankedName and string.find(btn._actionRankedName, actionName, 1, true))) then
                targetBtn = btn
                break
            end
        end
    end

    -- 3. Check Blizzard Default buttons
    if not targetBtn then
        local barPrefixes = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "BonusActionButton" }
        for _, prefix in ipairs(barPrefixes) do
            for i = 1, 12 do
                local btn = _G[prefix .. i]
                if btn and btn:IsVisible() and (btn._actionName == actionName or (btn._actionRankedName and string.find(btn._actionRankedName, actionName, 1, true))) then
                    targetBtn = btn
                    break
                end
            end
            if targetBtn then break end
        end
    end

    if targetBtn then
        local glow = CreateButtonGlow(targetBtn)
        glow:Show()
        self.activeGlowButtons[targetBtn] = glow
    end
end

-- =====================================================
-- ACTION BAR & BARTENDER KEYBIND DISCOVERY ENGINE
-- =====================================================
FC.keybindCache = {}
local lastKeybindScan = 0

local function FormatKeybindText(key)
    if not key or key == "" then return nil end
    key = string.upper(key)
    key = string.gsub(key, "CTRL%-", "C")
    key = string.gsub(key, "CONTROL%-", "C")
    key = string.gsub(key, "ALT%-", "A")
    key = string.gsub(key, "SHIFT%-", "S")
    key = string.gsub(key, "BUTTON4", "M4")
    key = string.gsub(key, "BUTTON5", "M5")
    key = string.gsub(key, "BUTTON3", "M3")
    key = string.gsub(key, "MIDDLEMOUSE", "M3")
    key = string.gsub(key, "MOUSEWHEELUP", "MWU")
    key = string.gsub(key, "MOUSEWHEELDOWN", "MWD")
    key = string.gsub(key, "NUMPAD", "N")
    key = string.gsub(key, "PAGEUP", "PU")
    key = string.gsub(key, "PAGEDOWN", "PD")
    key = string.gsub(key, "INSERT", "Ins")
    key = string.gsub(key, "DELETE", "Del")
    key = string.gsub(key, "SPACE", "Spc")
    return key
end

local function ExtractSpellsFromMacroBody(mBody)
    local results = {}
    if not mBody or mBody == "" then return results end

    for line in string.gmatch(mBody, "[^\r\n]+") do
        local showSpell = string.match(line, "^#showtooltip%s+(.+)") or string.match(line, "^#show%s+(.+)")
        if showSpell then
            showSpell = string.gsub(showSpell, "%[.-%]", "")
            local rank = string.match(showSpell, "%((Rank%s*%d+)%)")
            local base = string.gsub(showSpell, "%(.-%)", "")
            base = string.gsub(base, "^[!%s]+", "")
            base = string.gsub(base, "%s+$", "")
            if base ~= "" and not string.find(base, "^%d+$") then
                if rank and rank ~= "" then
                    table.insert(results, base .. " (" .. rank .. ")")
                else
                    table.insert(results, base)
                end
            end
        end

        local castLine = string.match(line, "^/castsequence%s+(.+)") or
                         string.match(line, "^/cast%s+(.+)") or
                         string.match(line, "^/use%s+(.+)")
        if castLine then
            castLine = string.gsub(castLine, "reset=[^%s,;]+%s*", "")

            for branch in string.gmatch(castLine, "[^;]+") do
                for spellPart in string.gmatch(branch, "[^,]+") do
                    local clean = string.gsub(spellPart, "%[.-%]", "")
                    local rank = string.match(clean, "%((Rank%s*%d+)%)")
                    local base = string.gsub(clean, "%(.-%)", "")
                    base = string.gsub(base, "^[!%s]+", "")
                    base = string.gsub(base, "%s+$", "")
                    if base ~= "" and not string.find(base, "^%d+$") then
                        if rank and rank ~= "" then
                            table.insert(results, base .. " (" .. rank .. ")")
                        else
                            table.insert(results, base)
                        end
                    end
                end
            end
        end
    end

    return results
end

local function ResolveSpellNameAndRank(id, subType)
    if not id then return nil, nil end
    local bookType = subType or "spell"
    local name, rank = nil, nil
    if GetSpellName then
        local ok, n, r = pcall(GetSpellName, id, bookType)
        if ok and n and n ~= "" then name, rank = n, r end
    end
    if not name and GetSpellInfo then
        local ok, n, r = pcall(GetSpellInfo, id, bookType)
        if ok and n and n ~= "" then name, rank = n, r end
    end
    if not name and GetSpellLink then
        local ok, link = pcall(GetSpellLink, id, bookType)
        if ok and link then
            name = string.match(link, "%[(.+)%]")
        end
    end
    if not name and GetSpellInfo then
        local ok, n, r = pcall(GetSpellInfo, id)
        if ok and n and n ~= "" then name, rank = n, r end
    end
    return name, rank
end

local function ProcessActionButton(btn, bindingNames, slotOverride, isHighPriority)
    if not btn then return end
    local btnName = btn:GetName() or ""
    local key = nil
    if bindingNames then
        for _, bName in ipairs(bindingNames) do
            local k = GetBindingKey(bName)
            if k and k ~= "" then
                key = k
                break
            end
        end
    end

    if not key and btnName ~= "" then
        key = GetBindingKey("CLICK " .. btnName .. ":LeftButton") or
              GetBindingKey("CLICK " .. btnName .. ":KeyBind") or
              GetBindingKey("CLICK " .. btnName .. ":action") or
              GetBindingKey("CLICK " .. btnName .. ":LeftClick") or
              GetBindingKey(btnName)
    end

    if not key and btnName ~= "" then
        local hkObj = _G[btnName .. "HotKey"] or btn.HotKey or btn.hotkey
        if hkObj and hkObj.GetText then
            local t = hkObj:GetText()
            if t and t ~= "" and t ~= RANGE_INDICATOR and t ~= "●" and not string.find(t, "^%s*$") then
                key = t
            end
        end
    end

    if not key or key == "" then return end
    local formattedKey = FormatKeybindText(key)

    local function SetKey(kName, val)
        if not kName or kName == "" then return end
        if isHighPriority or not FC.keybindCache[kName] then
            FC.keybindCache[kName] = val
        end
    end

    if btn.GetAttribute then
        local bType = btn:GetAttribute("type")
        if bType == "spell" then
            local sName = btn:GetAttribute("spell")
            if sName then SetKey(sName, formattedKey) end
        elseif bType == "item" then
            local iName = btn:GetAttribute("item")
            if iName then SetKey(iName, formattedKey) end
        elseif bType == "macro" then
            local mVal = btn:GetAttribute("macro")
            if type(mVal) == "string" then
                SetKey(mVal, formattedKey)
            elseif type(mVal) == "number" then
                local mName, _, mBody = GetMacroInfo(mVal)
                if mName then SetKey(mName, formattedKey) end
                for _, s in ipairs(ExtractSpellsFromMacroBody(mBody)) do
                    SetKey(s, formattedKey)
                end
            end
        end
    end

    local slot = nil
    if SecureActionButton_GetEffectiveAction then
        local ok, s = pcall(SecureActionButton_GetEffectiveAction, btn)
        if ok and s and tonumber(s) and tonumber(s) > 0 then slot = tonumber(s) end
    end
    if not slot and btn.GetPagedID then
        local ok, s = pcall(btn.GetPagedID, btn)
        if ok and s and tonumber(s) and tonumber(s) > 0 then slot = tonumber(s) end
    end
    if not slot and btn.GetAction then
        local ok, s = pcall(btn.GetAction, btn)
        if ok and s and tonumber(s) and tonumber(s) > 0 then slot = tonumber(s) end
    end
    if not slot and btn.GetAttribute then
        local ok, s = pcall(btn.GetAttribute, btn, "action")
        if ok and s and tonumber(s) and tonumber(s) > 0 then slot = tonumber(s) end
    end
    if not slot and btn.action then
        slot = tonumber(btn.action)
    end
    if not slot and btn._state_action then
        slot = tonumber(btn._state_action)
    end
    if not slot and btn.GetID then
        local ok, s = pcall(btn.GetID, btn)
        if ok and s and tonumber(s) and tonumber(s) > 0 then slot = tonumber(s) end
    end
    if not slot then
        slot = slotOverride
    end

    if slot and slot > 0 and slot <= 120 then
        local aType, id, subType = GetActionInfo(slot)

        if aType == "spell" and id then
            local sName, sRank = ResolveSpellNameAndRank(id, subType)
            if sName then
                btn._actionName = sName
                if sRank and sRank ~= "" and string.find(sRank, "Rank") then
                    local rankedName = sName .. " (" .. sRank .. ")"
                    btn._actionRankedName = rankedName
                    SetKey(rankedName, formattedKey)
                    local isDownrank = (sName == "Flamestrike" and not string.find(sRank, "Rank 9"))
                    if not isDownrank then
                        SetKey(sName, formattedKey)
                    end
                else
                    SetKey(sName, formattedKey)
                end
            end
            SetKey(id, formattedKey)
        elseif aType == "item" and id then
            local iName = GetItemInfo(id)
            if iName then
                btn._actionName = iName
                SetKey(iName, formattedKey)
            end
            SetKey(id, formattedKey)
        elseif aType == "macro" and id then
            local mName, _, mBody = GetMacroInfo(id)
            local mSpell = GetMacroSpell(id)
            if mSpell then
                btn._actionName = mSpell
                SetKey(mSpell, formattedKey)
            end
            if mName then SetKey(mName, formattedKey) end

            local extracted = ExtractSpellsFromMacroBody(mBody)
            for _, s in ipairs(extracted) do
                if not btn._actionName then btn._actionName = s end
                SetKey(s, formattedKey)
            end
        end
    end
end

function FC:ScanActionKeybinds()
    lastKeybindScan = GetTime()
    self.keybindCache = {}

    -- 1. Pass 1: Standard Action Bar 1 (Slots 1 to 12)
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        local bNames = { "ACTIONBUTTON" .. i }
        ProcessActionButton(btn, bNames, i, true)
    end

    -- 2. Pass 2: Bartender4 Buttons (BT4Button1 to 120)
    for i = 1, 120 do
        local btn = _G["BT4Button" .. i]
        if btn then
            local bNames = {
                "CLICK BT4Button" .. i .. ":LeftButton",
                "CLICK BT4Button" .. i .. ":KeyBind",
                "CLICK BT4Button" .. i .. ":action",
                "BT4Button" .. i
            }
            if i <= 12 then table.insert(bNames, "ACTIONBUTTON" .. i)
            elseif i >= 13 and i <= 24 then table.insert(bNames, "ACTIONBUTTON" .. (i - 12))
            elseif i >= 25 and i <= 36 then table.insert(bNames, "MULTIACTIONBAR3BUTTON" .. (i - 24))
            elseif i >= 37 and i <= 48 then table.insert(bNames, "MULTIACTIONBAR4BUTTON" .. (i - 36))
            elseif i >= 49 and i <= 60 then table.insert(bNames, "MULTIACTIONBAR2BUTTON" .. (i - 48))
            elseif i >= 61 and i <= 72 then table.insert(bNames, "MULTIACTIONBAR1BUTTON" .. (i - 60))
            end
            ProcessActionButton(btn, bNames, i, true)
        end
    end

    -- 3. Pass 3: Blizzard MultiActionBars
    local multiBars = {
        { prefix = "MultiBarBottomLeftButton",   bPrefix = "MULTIACTIONBAR1BUTTON", offset = 60 },
        { prefix = "MultiBarBottomRightButton",  bPrefix = "MULTIACTIONBAR2BUTTON", offset = 48 },
        { prefix = "MultiBarRightButton",        bPrefix = "MULTIACTIONBAR3BUTTON", offset = 24 },
        { prefix = "MultiBarLeftButton",         bPrefix = "MULTIACTIONBAR4BUTTON", offset = 36 },
        { prefix = "BonusActionButton",          bPrefix = "BONUSACTIONBUTTON",     offset = 72 }
    }
    for _, bar in ipairs(multiBars) do
        for i = 1, 12 do
            local btn = _G[bar.prefix .. i]
            if btn then
                local bNames = { bar.bPrefix .. i, "CLICK " .. bar.prefix .. i .. ":LeftButton" }
                ProcessActionButton(btn, bNames, bar.offset + i, false)
            end
        end
    end

    -- 4. Pass 4: Dominos Buttons
    for i = 1, 120 do
        local btn = _G["DominosActionButton" .. i]
        if btn and btn:IsVisible() then
            local bNames = {
                "CLICK DominosActionButton" .. i .. ":LeftButton",
                "CLICK DominosActionButton" .. i .. ":HOTKEY",
                "DominosActionButton" .. i
            }
            ProcessActionButton(btn, bNames, i, false)
        end
    end
end

function FC:GetKeybindForAction(actionOrName, spellId, itemId)
    local now = GetTime()
    if (now - lastKeybindScan) > 2.5 or not next(self.keybindCache or {}) then
        self:ScanActionKeybinds()
    end

    local name = nil
    if type(actionOrName) == "table" then
        name = actionOrName.spellName or actionOrName.name
        spellId = spellId or actionOrName.spellId
        itemId = itemId or actionOrName.itemId
    elseif type(actionOrName) == "string" then
        name = actionOrName
    end

    local cache = self.keybindCache or {}
    if name and cache[name] then
        return cache[name]
    end

    -- Dynamic lookup for highest available rank in cache
    if name and not string.find(name, "%(Rank") then
        local bestRankNum = -1
        local bestKey = nil
        local prefix = name .. " (Rank "
        for k, v in pairs(cache) do
            if string.find(k, prefix, 1, true) == 1 then
                local rNum = tonumber(string.match(k, "%(Rank%s*(%d+)%)")) or 0
                if rNum > bestRankNum then
                    bestRankNum = rNum
                    bestKey = v
                end
            end
        end
        if bestKey then
            return bestKey
        end
    end

    if spellId and cache[spellId] then
        return cache[spellId]
    end
    if itemId and cache[itemId] then
        return cache[itemId]
    end

    return nil
end

-- =====================================================
-- SECTION 1: MULTI-TRACK SCROLLING TIMELINE (TOP SECTION)
-- Far Left = 0.0s (NOW), Far Right = 10.0s (Future)
-- Timeline items glide from right to left toward 0s!
-- =====================================================
local trackContainer = CreateFrame("Frame", nil, main)
trackContainer:SetPoint("TOPLEFT", main, "TOPLEFT", 10, -24)
trackContainer:SetPoint("TOPRIGHT", main, "TOPRIGHT", -10, -24)
trackContainer:SetHeight(120)

-- Time Ruler Bar at top of tracks with 1-second precision intervals
local rulerBar = CreateFrame("Frame", nil, trackContainer)
rulerBar:SetPoint("TOPLEFT", trackContainer, "TOPLEFT", 0, 0)
rulerBar:SetPoint("TOPRIGHT", trackContainer, "TOPRIGHT", 0, 0)
rulerBar:SetHeight(14)

local rulerLabels = {}
for sec = 0, 10 do
    local ratio = sec / TRACK_DURATION
    local x = ratio * TRACK_BAR_WIDTH

    -- Vertical Tick Notch at every second
    local tick = rulerBar:CreateTexture(nil, "BORDER")
    local isEven = (sec % 2 == 0)
    tick:SetPoint("BOTTOMLEFT", rulerBar, "BOTTOMLEFT", x, 0)
    tick:SetSize(1, isEven and 6 or 4)
    if isEven then
        tick:SetTexture(0.5, 0.65, 0.85, 0.75)
    else
        tick:SetTexture(0.35, 0.45, 0.60, 0.45)
    end

    local rText = rulerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rText:SetFont("Fonts\\FRIZQT__.TTF", isEven and 9 or 8, "NONE")
    if sec == 0 then
        rText:SetPoint("LEFT", rulerBar, "LEFT", 0, 1)
        rText:SetText("|cff55ff550s (NOW)|r")
    elseif sec == 10 then
        rText:SetPoint("RIGHT", rulerBar, "RIGHT", 0, 1)
        rText:SetText("+10s")
        rText:SetTextColor(0.6, 0.7, 0.8, 0.8)
    else
        rText:SetPoint("CENTER", rulerBar, "LEFT", x, 1)
        rText:SetText(string.format("+%ds", sec))
        if isEven then
            rText:SetTextColor(0.70, 0.80, 0.90, 0.90)
        else
            rText:SetTextColor(0.40, 0.50, 0.65, 0.65)
        end
    end
    table.insert(rulerLabels, rText)
end

local trackRows = {}

local function CreateTrackRow(index)
    local row = CreateFrame("Frame", "FlowCoreTrackRow" .. index, trackContainer)
    row:SetSize(TRACK_BAR_WIDTH, TRACK_HEIGHT)
    row:SetPoint("TOPLEFT", trackContainer, "TOPLEFT", 0, -14 - ((index - 1) * (TRACK_HEIGHT + TRACK_GAP)))

    -- Background canvas
    local barCanvas = CreateFrame("Frame", nil, row)
    barCanvas:SetAllPoints(row)
    barCanvas:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    barCanvas:SetBackdropColor(0.08, 0.08, 0.10, 0.75)
    barCanvas:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
    row.barCanvas = barCanvas

    -- 1-Second Interval Grid lines (+1s, +2s, +3s, +4s, +5s, +6s, +7s, +8s, +9s)
    row.gridLines = {}
    for g = 1, 9 do
        local gLine = barCanvas:CreateTexture(nil, "BORDER")
        local gx = (g / TRACK_DURATION) * TRACK_BAR_WIDTH
        gLine:SetPoint("TOPLEFT", barCanvas, "TOPLEFT", gx, 0)
        gLine:SetPoint("BOTTOMLEFT", barCanvas, "BOTTOMLEFT", gx, 0)
        gLine:SetWidth(1)
        if g % 2 == 0 then
            gLine:SetTexture(0.4, 0.45, 0.55, 0.30)
        else
            gLine:SetTexture(0.25, 0.30, 0.40, 0.18)
        end
        table.insert(row.gridLines, gLine)
    end

    -- Recast / Pandemic Safe Refresh Window Highlight (First 2.0 seconds from far left)
    local recastHighlight = barCanvas:CreateTexture(nil, "ARTWORK")
    recastHighlight:SetTexture(1.0, 0.6, 0.1, 0.20)
    recastHighlight:Hide()
    row.recastHighlight = recastHighlight

    -- Active DoT / Aura Bar Texture
    local dotBar = barCanvas:CreateTexture(nil, "ARTWORK")
    dotBar:SetTexture(0.7, 0.3, 0.9, 0.70)
    dotBar:Hide()
    row.dotBar = dotBar

    -- Tick Marker Pips (up to 8 ticks)
    row.tickPips = {}
    for p = 1, 8 do
        local pip = barCanvas:CreateTexture(nil, "OVERLAY")
        pip:SetWidth(1.5)
        pip:SetTexture(1.0, 1.0, 1.0, 0.9)
        pip:Hide()
        table.insert(row.tickPips, pip)
    end

    -- Casting / Channeling Bar Segment
    local castBar = barCanvas:CreateTexture(nil, "ARTWORK")
    castBar:SetTexture(0.1, 0.85, 0.4, 0.75)
    castBar:Hide()
    row.castBar = castBar

    -- Latency / Spell Queue Safe Zone Overlay (leftmost 150-400ms of the cast)
    local castQueueBar = barCanvas:CreateTexture(nil, "OVERLAY")
    castQueueBar:SetTexture(1.0, 0.35, 0.2, 0.85)
    castQueueBar:Hide()
    row.castQueueBar = castQueueBar

    -- Cooldown Bar Segment
    local cdBar = barCanvas:CreateTexture(nil, "BACKGROUND")
    cdBar:SetTexture(0.4, 0.4, 0.4, 0.30)
    cdBar:Hide()
    row.cdBar = cdBar

    -- Predicted Future Cast Block (from 10s Timeline)
    local futureCastBlock = barCanvas:CreateTexture(nil, "OVERLAY")
    futureCastBlock:SetTexture(1.0, 0.85, 0.2, 0.45)
    futureCastBlock:Hide()
    row.futureCastBlock = futureCastBlock

    -- Vertical "NOW" Indicator Line (Far Left = 0s)
    local nowLine = barCanvas:CreateTexture(nil, "OVERLAY")
    nowLine:SetPoint("TOPLEFT", barCanvas, "TOPLEFT", 0, 0)
    nowLine:SetPoint("BOTTOMLEFT", barCanvas, "BOTTOMLEFT", 0, 0)
    nowLine:SetWidth(2)
    nowLine:SetTexture(0.2, 1.0, 0.5, 0.95)
    row.nowLine = nowLine

    -- Spell Icon (Centered on the Green 0s NOW Indicator Line)
    local iconFrame = CreateFrame("Button", nil, row)
    iconFrame:SetSize(TRACK_HEIGHT + 2, TRACK_HEIGHT + 2)
    iconFrame:SetPoint("CENTER", barCanvas, "LEFT", 0, 0)
    iconFrame:SetFrameLevel(barCanvas:GetFrameLevel() + 10)
    row.iconFrame = iconFrame

    local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints(iconFrame)
    iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = iconTex

    local iconBorder = CreateFrame("Frame", nil, iconFrame)
    iconBorder:SetPoint("TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    iconBorder:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.85)
    row.iconBorder = iconBorder

    -- Multi-target count badge on icon
    local countBadge = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countBadge:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 3, -3)
    countBadge:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    countBadge:SetTextColor(0.2, 1.0, 0.4, 1.0)
    countBadge:Hide()
    row.countBadge = countBadge

    iconFrame:SetScript("OnEnter", function(self)
        if not row.spellName then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if row.spellId then
            GameTooltip:SetHyperlink("spell:" .. row.spellId)
        elseif row.itemId then
            GameTooltip:SetHyperlink("item:" .. row.itemId)
        else
            GameTooltip:AddLine(row.spellName, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row:Hide()
    trackRows[index] = row
    return row
end

for i = 1, MAX_TRACK_ROWS do
    CreateTrackRow(i)
end

-- =====================================================
-- SECTION 2: FORECAST SPELL ICONS (BOTTOM SECTION)
-- Chronologically ordered from Left to Right:
-- Slot 1 (Far Left, Hero Slot = NOW) -> Slots 2..7 (+1.5s, +3.0s, +4.5s...)
-- =====================================================
local iconContainer = CreateFrame("Frame", nil, main)
iconContainer:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 10, 8)
iconContainer:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -10, 8)
iconContainer:SetHeight(48)

local iconSlots = {}
for i = 1, MAX_ICONS do
    local isHero = (i == 1)
    local currentSize = isHero and HERO_SIZE or SLOT_SIZE

    local slot = CreateFrame("Button", "FlowCoreSlot" .. i, iconContainer)
    slot:SetSize(currentSize, currentSize)

    if isHero then
        slot:SetPoint("BOTTOMLEFT", iconContainer, "BOTTOMLEFT", 0, 12)
    else
        local prevOffset = HERO_SIZE + ICON_GAP + ((i - 2) * (SLOT_SIZE + ICON_GAP))
        slot:SetPoint("BOTTOMLEFT", iconContainer, "BOTTOMLEFT", prevOffset, 14)
    end

    slot:EnableMouse(true)

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(slot)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot.icon = icon

    local borderFrame = CreateFrame("Frame", nil, slot)
    borderFrame:SetPoint("TOPLEFT", isHero and -2 or -1.5, isHero and 2 or 1.5)
    borderFrame:SetPoint("BOTTOMRIGHT", isHero and 2 or 1.5, isHero and -2 or -1.5)
    borderFrame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = isHero and 2.5 or 1.5,
    })
    slot.borderFrame = borderFrame

    local hotkeyFrame = CreateFrame("Frame", nil, borderFrame)
    hotkeyFrame:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 1, 1)
    hotkeyFrame:SetSize(isHero and 18 or 14, isHero and 14 or 12)
    hotkeyFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    hotkeyFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.90)
    hotkeyFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.90)
    slot.hotkeyFrame = hotkeyFrame

    local hotkeyText = hotkeyFrame:CreateFontString(nil, "OVERLAY")
    hotkeyText:SetPoint("CENTER", hotkeyFrame, "CENTER", 0, 0)
    hotkeyText:SetFont("Fonts\\ARIALN.TTF", isHero and 12 or 10, "OUTLINE")
    hotkeyText:SetTextColor(1.0, 1.0, 1.0, 1.0)
    slot.hotkeyText = hotkeyText

    local timeText = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetPoint("BOTTOM", slot, "BOTTOM", 0, -12)
    slot.timeText = timeText

    slot:SetScript("OnEnter", function(self)
        if not self.entry then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if self.entry.spellId then
            GameTooltip:SetHyperlink("spell:" .. self.entry.spellId)
        elseif self.entry.itemId then
            GameTooltip:SetHyperlink("item:" .. self.entry.itemId)
        else
            GameTooltip:AddLine(self.entry.name or "Action", 1, 1, 1)
        end
        local hk = FC:GetKeybindForAction(self.entry.name, self.entry.spellId, self.entry.itemId)
        if hk then
            GameTooltip:AddLine("Keybind: |cffffd700" .. hk .. "|r", 1, 1, 1)
        end
        GameTooltip:AddLine("Time: " .. string.format("%.1fs", self.entry.time or 0) .. " | Role: " .. tostring(self.entry.role or "unknown"), 0.5, 0.8, 1)
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    slot:Hide()
    iconSlots[i] = slot
end

-- =====================================================
-- TIMELINE TRACKING FILTER
-- =====================================================
function FC:IsSpellTrackedInTimeline(sName, action)
    if not sName then return false end

    -- 1. Check user override in database
    if self.db and self.db.spellOverrides and self.db.spellOverrides[sName] and self.db.spellOverrides[sName].trackInTimeline ~= nil then
        return self.db.spellOverrides[sName].trackInTimeline
    end

    -- 2. Default: Major Cooldowns & Defensives
    if action then
        if action.role == "cooldown" or action.role == "defensive" or action.role == "mana" or action.role == "trinket" then
            return true
        end
        if action.actionType == "spell" then
            local dur = self:GetCooldownDurationHint(sName, action.cooldownHint)
            if dur and dur > 1.5 then
                return true
            end
        end
    end

    local defaultCooldowns = {
        ["Combustion"] = true,
        ["Evocation"] = true,
        ["Dragon's Breath"] = true,
        ["Blast Wave"] = true,
        ["Deep Freeze"] = true,
        ["Mirror Image"] = true,
        ["Ice Block"] = true,
        ["Arcane Power"] = true,
        ["Icy Veins"] = true,
        ["Mana Gem"] = true,
        ["Avenging Wrath"] = true,
        ["Divine Protection"] = true,
        ["Lay on Hands"] = true,
        ["Death Wish"] = true,
        ["Recklessness"] = true,
        ["Shield Wall"] = true,
        ["Blade Flurry"] = true,
        ["Adrenaline Rush"] = true,
        ["Vanish"] = true,
        ["Cloak of Shadows"] = true,
        ["Shadowfiend"] = true,
        ["Dispersion"] = true,
        ["Bloodlust"] = true,
        ["Heroism"] = true
    }

    return defaultCooldowns[sName] == true
end

-- =====================================================
-- RENDER EVENTHORIZON MULTI-TRACK TIMELINE (TOP) + ICONS (BOTTOM)
-- =====================================================
local function RenderTracksView(now)
    local actions = FC.actions or {}
    local queue = (FC.timeline and FC.timeline.queue) or {}
    local heroAction = queue[1]

    -- 1. Identify active track items: Hero Recommended Action first, then upcoming queue, then major cooldowns
    local trackSpells = {}
    local seen = {}

    -- A. Hero Action (Slot 1 NOW) placed prominently at Top Row 1
    if heroAction then
        local sName = heroAction.name or heroAction.spellName
        if sName and not seen[sName] then
            table.insert(trackSpells, heroAction)
            seen[sName] = true
        end
    end

    -- B. Upcoming spells in the forecast queue
    for qIdx, qItem in ipairs(queue) do
        if qIdx > 1 then
            local sName = qItem.name or qItem.spellName
            if sName and not seen[sName] and #trackSpells < MAX_TRACK_ROWS then
                table.insert(trackSpells, qItem)
                seen[sName] = true
            end
        end
    end

    -- C. Remaining tracked cooldowns and defensives
    for _, a in ipairs(actions) do
        local sName = a.name or a.spellName
        if sName and not seen[sName] and FC:IsSpellTrackedInTimeline(sName, a) then
            table.insert(trackSpells, a)
            seen[sName] = true
            if #trackSpells >= MAX_TRACK_ROWS then break end
        end
    end

    local rowCount = math.max(2, #trackSpells)
    local tracksHeight = 14 + (rowCount * (TRACK_HEIGHT + TRACK_GAP))
    local totalFrameHeight = 28 + tracksHeight + 8 + 48 + 10
    main:SetSize(FRAME_WIDTH, totalFrameHeight)
    trackContainer:SetHeight(tracksHeight)

    local pixelsPerSec = TRACK_BAR_WIDTH / TRACK_DURATION

    -- 2. Render each track on top
    for i = 1, MAX_TRACK_ROWS do
        local row = trackRows[i]
        local a = trackSpells[i]

        if a then
            local sName = a.name or a.spellName or "Action"
            row.spellName = sName
            row.spellId = a.spellId
            row.itemId = a.itemId
            row:SetPoint("TOPLEFT", trackContainer, "TOPLEFT", 0, -14 - ((i - 1) * (TRACK_HEIGHT + TRACK_GAP)))

            local color = ROLE_COLORS[a.role] or ROLE_COLORS["default"]

            -- Set Spell Icon Texture & Role Border Color
            if row.icon then
                row.icon:SetTexture(a.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            end
            if row.iconBorder then
                row.iconBorder:SetBackdropBorderColor(color.r, color.g, color.b, 0.95)
            end

            -- Multi-Target DoT info (Phase 2)
            local multiCount, multiList, maxAllowed = 0, {}, 3
            if FC.GetMultiTargetDotInfo then
                multiCount, multiList, maxAllowed = FC:GetMultiTargetDotInfo(sName)
            end

            if multiCount > 1 and row.countBadge then
                row.countBadge:SetText(tostring(multiCount))
                row.countBadge:Show()
            else
                if row.countBadge then row.countBadge:Hide() end
            end

            -- Hero Recommendation Glow
            if heroAction and (heroAction.name == sName or heroAction.spellName == sName) then
                row.barCanvas:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.9)
                if row.iconBorder then row.iconBorder:SetBackdropBorderColor(1.0, 0.85, 0.2, 1.0) end
            else
                row.barCanvas:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
            end

            row.dotBar:Hide()
            row.recastHighlight:Hide()
            for p = 1, 8 do row.tickPips[p]:Hide() end

            -- 1. Active DoT / Aura Bar Tracking (Current Target + Multi-Target)
            local dotRemaining = 0
            local tDebuffs = (FC.state and FC.state.target and FC.state.target.debuffs) or {}
            if tDebuffs[sName] and tDebuffs[sName].mine and (tDebuffs[sName].remaining or 0) > 0.1 then
                dotRemaining = tDebuffs[sName].remaining
            elseif multiCount > 0 and multiList[1] then
                dotRemaining = multiList[1].remaining
            end

            if dotRemaining > 0.1 then
                local dWidth = math.min(TRACK_BAR_WIDTH, dotRemaining * pixelsPerSec)
                row.dotBar:ClearAllPoints()
                row.dotBar:SetPoint("TOPLEFT", row.barCanvas, "TOPLEFT", 0, 0)
                row.dotBar:SetPoint("BOTTOMLEFT", row.barCanvas, "BOTTOMLEFT", 0, 0)
                row.dotBar:SetWidth(math.max(2, dWidth))
                row.dotBar:SetTexture(0.7, 0.3, 0.9, 0.70)
                row.dotBar:Show()

                -- Recast Pandemic highlight (last 2.5s before expiring)
                if dotRemaining <= 2.5 then
                    row.recastHighlight:ClearAllPoints()
                    row.recastHighlight:SetPoint("TOPLEFT", row.barCanvas, "TOPLEFT", 0, 0)
                    row.recastHighlight:SetPoint("BOTTOMLEFT", row.barCanvas, "BOTTOMLEFT", 0, 0)
                    row.recastHighlight:SetWidth(math.max(2, dWidth))
                    row.recastHighlight:Show()
                end
            end

            -- 1. Active Cast Bar (if currently casting this cooldown ability)
            local isCastingThis = false
            local pCast = (FC.state and FC.state.player) or {}
            local spellName = pCast.castSpellName
            local remCast = pCast.castRemaining or 0

            if not spellName then
                local sNameCast, _, _, _, _, endTime = UnitCastingInfo("player")
                if not sNameCast then sNameCast, _, _, _, _, endTime = UnitChannelInfo("player") end
                if sNameCast and endTime then
                    spellName = sNameCast
                    remCast = math.max(0, (endTime / 1000) - now)
                end
            end

            local isCastMatch = false
            if spellName and sName and remCast > 0 then
                if spellName == sName then
                    isCastMatch = true
                elseif type(sName) == "string" and type(spellName) == "string" then
                    if string.find(sName, spellName, 1, true) or string.find(spellName, sName, 1, true) then
                        isCastMatch = true
                    end
                end
            end

            if isCastMatch then
                local cWidth = math.min(TRACK_BAR_WIDTH, remCast * pixelsPerSec)
                row.castBar:ClearAllPoints()
                row.castBar:SetPoint("TOPLEFT", row.barCanvas, "TOPLEFT", 0, 0)
                row.castBar:SetPoint("BOTTOMLEFT", row.barCanvas, "BOTTOMLEFT", 0, 0)
                row.castBar:SetWidth(math.max(2, cWidth))
                row.castBar:Show()
                isCastingThis = true

                -- Spell Queue Safe-Zone Latency Overlay (Phase 1)
                if FC.db and FC.db.enableQueueIndicator ~= false and row.castQueueBar then
                    local lagSec = (FC.GetLatencyWindow and FC:GetLatencyWindow()) or 0.250
                    local qWidth = math.min(cWidth, lagSec * pixelsPerSec)
                    row.castQueueBar:ClearAllPoints()
                    row.castQueueBar:SetPoint("TOPLEFT", row.barCanvas, "TOPLEFT", 0, 0)
                    row.castQueueBar:SetPoint("BOTTOMLEFT", row.barCanvas, "BOTTOMLEFT", 0, 0)
                    row.castQueueBar:SetWidth(math.max(2, qWidth))

                    if remCast <= lagSec then
                        -- Inside safe queue window! Radiant Emerald Green
                        row.castQueueBar:SetTexture(0.2, 1.0, 0.4, 0.95)
                    else
                        -- Outside safe queue window: Amber/Red threshold
                        row.castQueueBar:SetTexture(1.0, 0.35, 0.2, 0.75)
                    end
                    row.castQueueBar:Show()
                else
                    if row.castQueueBar then row.castQueueBar:Hide() end
                end
            else
                row.castBar:Hide()
                if row.castQueueBar then row.castQueueBar:Hide() end
            end

            -- 2. Cooldown Bar Tracking
            if a.actionType == "spell" and not isCastingThis then
                local cdRem = FC:GetNativeTimeUntilReady(sName)
                if cdRem > 0.1 then
                    local cdWidth = math.min(TRACK_BAR_WIDTH, cdRem * pixelsPerSec)
                    row.cdBar:ClearAllPoints()
                    row.cdBar:SetPoint("TOPLEFT", row.barCanvas, "TOPLEFT", 0, 0)
                    row.cdBar:SetPoint("BOTTOMLEFT", row.barCanvas, "BOTTOMLEFT", 0, 0)
                    row.cdBar:SetWidth(math.max(2, cdWidth))
                    row.cdBar:Show()
                else
                    row.cdBar:Hide()
                end
            else
                row.cdBar:Hide()
            end

            -- 3. Forecasted Future Cast Marker from 10s Timeline
            local futureSlot = nil
            for qIdx, qItem in ipairs(queue) do
                if qIdx > 1 and (qItem.name == sName or qItem.spellName == sName) then
                    futureSlot = qItem
                    break
                end
            end
            if futureSlot and futureSlot.time and futureSlot.time > 0 then
                local fLeft = futureSlot.time * pixelsPerSec
                local fCastLen = math.max(1.0, futureSlot.castTime or 1.5)
                local fRight = math.min(TRACK_BAR_WIDTH, fLeft + (fCastLen * pixelsPerSec))
                if fLeft < TRACK_BAR_WIDTH then
                    row.futureCastBlock:ClearAllPoints()
                    row.futureCastBlock:SetPoint("TOPLEFT", row.barCanvas, "TOPLEFT", fLeft, 0)
                    row.futureCastBlock:SetPoint("BOTTOMLEFT", row.barCanvas, "BOTTOMLEFT", fLeft, 0)
                    row.futureCastBlock:SetWidth(math.max(3, fRight - fLeft))
                    row.futureCastBlock:Show()
                else
                    row.futureCastBlock:Hide()
                end
            else
                row.futureCastBlock:Hide()
            end

            row:Show()
        else
            row:Hide()
        end
    end

    -- 3. Render the chronological forecast icons on the bottom
    local pState = (FC.state and FC.state.player) or {}
    for i = 1, MAX_ICONS do
        local slot = iconSlots[i]
        local entry = queue[i]

        if entry then
            slot.entry = entry
            slot.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

            if i == 1 then
                if pState.inCastQueueWindow then
                    slot.timeText:SetText("|cff00ff00QUEUE!|r")
                    slot.borderFrame:SetBackdropBorderColor(0.2, 1.0, 0.4, 1.0)
                elseif (entry.time or 0) <= 0.1 then
                    slot.timeText:SetText("|cff55ff55NOW|r")
                    local color = ROLE_COLORS[entry.role] or ROLE_COLORS["default"]
                    slot.borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
                else
                    slot.timeText:SetText(string.format("+%.1fs", entry.time or 0))
                    local color = ROLE_COLORS[entry.role] or ROLE_COLORS["default"]
                    slot.borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
                end
            else
                slot.timeText:SetText(string.format("+%.1fs", entry.time or 0))
                local color = ROLE_COLORS[entry.role] or ROLE_COLORS["default"]
                slot.borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
            end

            local hotkey = FC:GetKeybindForAction(entry.name, entry.spellId, entry.itemId)
            if hotkey and hotkey ~= "" then
                slot.hotkeyText:SetText(hotkey)
                local strWidth = slot.hotkeyText:GetStringWidth() or 10
                slot.hotkeyFrame:SetWidth(math.max(i == 1 and 16 or 13, strWidth + 4))
                slot.hotkeyFrame:Show()
            else
                slot.hotkeyFrame:Hide()
            end

            slot:Show()
        else
            slot.entry = nil
            slot:Hide()
        end
    end
end

-- =====================================================
-- RENDER COMPACT ICON SEQUENCE VIEW (ONLY ICONS)
-- =====================================================
local function RenderIconsOnlyView()
    main:SetSize(FRAME_WIDTH, ICONS_ONLY_HEIGHT)
    local queue = (FC.timeline and FC.timeline.queue) or {}
    local pState = (FC.state and FC.state.player) or {}

    for i = 1, MAX_ICONS do
        local slot = iconSlots[i]
        local entry = queue[i]

        if entry then
            slot.entry = entry
            slot.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

            if i == 1 then
                if pState.inCastQueueWindow then
                    slot.timeText:SetText("|cff00ff00QUEUE!|r")
                    slot.borderFrame:SetBackdropBorderColor(0.2, 1.0, 0.4, 1.0)
                elseif (entry.time or 0) <= 0.1 then
                    slot.timeText:SetText("|cff55ff55NOW|r")
                    local color = ROLE_COLORS[entry.role] or ROLE_COLORS["default"]
                    slot.borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
                else
                    slot.timeText:SetText(string.format("+%.1fs", entry.time or 0))
                    local color = ROLE_COLORS[entry.role] or ROLE_COLORS["default"]
                    slot.borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
                end
            else
                slot.timeText:SetText(string.format("+%.1fs", entry.time or 0))
                local color = ROLE_COLORS[entry.role] or ROLE_COLORS["default"]
                slot.borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
            end

            local hotkey = FC:GetKeybindForAction(entry.name, entry.spellId, entry.itemId)
            if hotkey and hotkey ~= "" then
                slot.hotkeyText:SetText(hotkey)
                local strWidth = slot.hotkeyText:GetStringWidth() or 10
                slot.hotkeyFrame:SetWidth(math.max(i == 1 and 16 or 13, strWidth + 4))
                slot.hotkeyFrame:Show()
            else
                slot.hotkeyFrame:Hide()
            end

            slot:Show()
        else
            slot.entry = nil
            slot:Hide()
        end
    end
end

-- =====================================================
-- REFRESH TIMELINE UI
-- =====================================================
FC.main = main
FC.heroHUD = heroHUD

local function RefreshUI()
    local now = GetTime()

    -- 1. Timeline UI Visibility Check
    if FC.db and FC.db.showUI == false then
        if main:IsShown() then main:Hide() end
    else
        if not main:IsShown() then main:Show() end

        -- Update Phase Text & Burst Window Status (Phase 3)
        local intel = FC.intel or {}
        if intel.isBurstPhase then
            phaseText:SetText(string.format("|cffff8800BURST: %s (%.0fs)|r", tostring(intel.burstSource or "Proc"), math.max(0, intel.burstRemaining or 0)))
        elseif intel.impendingBurst then
            phaseText:SetText(string.format("|cffffd700PRE-BURST (%.1fs)|r", math.max(0, intel.timeUntilBurst or 0)))
        else
            local bTimers = (FC.GetActiveBossTimers and FC:GetActiveBossTimers()) or {}
            local speedMult, perkActive = 1.0, false
            if FC.GetDungeonSpeedMultiplier then
                speedMult, perkActive = FC:GetDungeonSpeedMultiplier()
            end

            if #bTimers > 0 then
                local nextMech = bTimers[1]
                local col = nextMech.lethal and "|cffff2222" or "|cffffd700"
                local spdTag = (perkActive and speedMult > 1.0) and string.format(" |cff00ff00[%.1fx]|r", speedMult) or ""
                phaseText:SetText(string.format("%s%s (%.1fs)%s|r", col, nextMech.name, nextMech.remaining, spdTag))
            else
                local phase = FC.state.phase or "idle"
                local spdTag = (perkActive and speedMult > 1.0) and string.format(" |cff00ff00⚡%.1fx|r", speedMult) or ""
                if phase == "emergency" then
                    phaseText:SetText("|cffff2222EMERGENCY|r" .. spdTag)
                elseif phase == "execute" then
                    phaseText:SetText("|cffff5522EXECUTE|r" .. spdTag)
                elseif phase == "combat" then
                    phaseText:SetText("|cff00ccffCOMBAT|r" .. spdTag)
                elseif phase == "opener" then
                    phaseText:SetText("|cffffd700OPENER|r" .. spdTag)
                elseif phase == "ready" then
                    phaseText:SetText("|cff55ff55READY|r" .. spdTag)
                else
                    phaseText:SetText("|cff888888IDLE|r" .. spdTag)
                end
            end
        end

        local style = (FC.db and FC.db.timelineStyle) or "tracks"
        if style == "tracks" then
            trackContainer:Show()
            RenderTracksView(now)
        else
            trackContainer:Hide()
            RenderIconsOnlyView()
        end
    end

    -- 2. Update Floating Hero HUD (Phase 5) - Independent of Timeline UI visibility!
    if heroHUD then
        if FC.db and FC.db.showHeroHUD == false then
            heroHUD:Hide()
            if FC.HideAllButtonGlows then FC:HideAllButtonGlows() end
        else
            local queue = (FC.timeline and FC.timeline.queue) or {}
            local heroEntry = queue[1]
            local pState = (FC.state and FC.state.player) or {}
            local pBuffs = pState.buffs or {}

            if heroEntry and (FC.state.inCombat or FC.state.engaged or FC.state.readyToEngage or FC.simulationActive) then
                heroHUD.icon:SetTexture(heroEntry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

                -- Hotkey text
                local hotkey = FC:GetKeybindForAction(heroEntry.name, heroEntry.spellId, heroEntry.itemId)
                if hotkey and hotkey ~= "" then
                    heroHUD.hotkeyText:SetText(hotkey)
                    local strWidth = heroHUD.hotkeyText:GetStringWidth() or 10
                    heroHUD.hotkeyFrame:SetWidth(math.max(16, strWidth + 4))
                    heroHUD.hotkeyFrame:Show()
                else
                    heroHUD.hotkeyFrame:Hide()
                end

                -- Off-Target Multi-Dot Badge
                if heroEntry.isOffTarget then
                    heroHUD.offTargetBadge:Show()
                else
                    heroHUD.offTargetBadge:Hide()
                end

                -- Check active reactive procs (Hot Streak, Brain Freeze, Art of War, etc.)
                local isProcActive = (pBuffs["Hot Streak"] or pBuffs["Brain Freeze"] or pBuffs["The Art of War"] or pBuffs["Killing Machine"] or pBuffs["Sudden Death"] or pBuffs["Bloodsurge"] or pBuffs["Maelstrom Weapon"] or pBuffs["Nightfall"])

                if FC.state and FC.state.incomingThreat then
                    heroHUD.border:SetBackdropBorderColor(1.0, 0.1, 0.1, 1.0)
                    heroHUD.procGlow:SetTexture(1.0, 0.1, 0.1, 0.60)
                    heroHUD.procGlow:SetAlpha(0.95)
                    FC:PlayProcSound(true)
                    FC:FlashScreen(1.0, 0.1, 0.1, 0.45)
                elseif isProcActive then
                    heroHUD.border:SetBackdropBorderColor(1.0, 0.3, 0.1, 1.0)
                    heroHUD.procGlow:SetTexture(1.0, 0.85, 0.2, 0.45)
                    heroHUD.procGlow:SetAlpha(0.85)
                    if not FC._wasProcActive then
                        FC:PlayProcSound(false)
                        FC:FlashScreen(1.0, 0.85, 0.2, 0.35)
                    end
                elseif pState.inCastQueueWindow then
                    heroHUD.border:SetBackdropBorderColor(0.2, 1.0, 0.4, 1.0)
                    heroHUD.procGlow:SetTexture(0.2, 1.0, 0.4, 0.35)
                    heroHUD.procGlow:SetAlpha(0.65)
                else
                    local col = ROLE_COLORS[heroEntry.role] or ROLE_COLORS["default"]
                    heroHUD.border:SetBackdropBorderColor(col.r, col.g, col.b, 0.9)
                    heroHUD.procGlow:SetAlpha(0)
                end
                FC._wasProcActive = isProcActive

                -- Action Bar Button Glow Injector (Phase 5)
                if FC.ShowButtonGlowForAction then
                    FC:ShowButtonGlowForAction(heroEntry.name or heroEntry.spellName, heroEntry.spellId, heroEntry.itemId)
                end

                heroHUD:Show()
            else
                heroHUD:Hide()
                if FC.HideAllButtonGlows then FC:HideAllButtonGlows() end
            end
        end
    end
end

-- UI Refresh Ticker (60 FPS smooth scrolling animation running on independent driver frame)
local uiDriver = CreateFrame("Frame")
local uiElapsed = 0
uiDriver:SetScript("OnUpdate", function(_, delta)
    uiElapsed = uiElapsed + delta
    if uiElapsed < 0.016 then return end
    uiElapsed = 0

    RefreshUI()
end)

-- =====================================================
-- UI CONTROLS & COMMANDS
-- =====================================================
function FC:ToggleTimelineUI()
    if main:IsShown() then
        main:Hide()
        if self.db then self.db.showUI = false end
        self:Print("Timeline UI hidden.")
    else
        main:Show()
        if self.db then self.db.showUI = true end
        self:Print("Timeline UI visible.")
    end
end

function FC:LockTimelineUI(lock)
    if self.db then
        if lock ~= nil then
            self.db.locked = lock
        else
            self.db.locked = not self.db.locked
        end
        self:Print("Timeline position " .. (self.db.locked and "LOCKED." or "UNLOCKED."))
    end
end

function FC:SetTimelineScale(scale)
    scale = tonumber(scale)
    if scale and scale >= 0.5 and scale <= 2.0 then
        main:SetScale(scale)
        if self.db then self.db.scale = scale end
        self:Print("Timeline scale set to " .. string.format("%.2f", scale))
    else
        self:Print("Invalid scale. Enter a number between 0.5 and 2.0 (e.g. /fc scale 1.2)")
    end
end

-- Hook login position restore
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    FC:RestoreUIPosition()
end)
