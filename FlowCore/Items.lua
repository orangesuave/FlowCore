FlowCore = FlowCore or {}
local FC = FlowCore

FC.registeredItemActions = FC.registeredItemActions or {}

-- Common WotLK Consumable Item IDs
local HEALTHSTONES = { 36892, 36893, 36894, 22103, 22104, 22105, 19004, 19005, 5512, 5511, 5509 }
local HEALING_POTIONS = { 33447, 40067, 41166, 22829, 13446, 3928 }
local MANA_POTIONS = { 33448, 40068, 42545, 22832, 13444, 3827 }

-- =========================================================
-- SCAN ITEMS & TRINKETS
-- =========================================================
function FC:ScanItems()
    -- 1. Scan All Equipped On-Use Items (Trinkets, Gloves, Belt, Boots, Cloak, Weapons)
    local ON_USE_SLOTS = { 1, 2, 3, 6, 8, 10, 13, 14, 15, 16, 17, 18 }
    for _, slot in ipairs(ON_USE_SLOTS) do
        local itemId = GetInventoryItemID("player", slot)
        if itemId then
            local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
            local spellName = GetItemSpell(itemId)

            -- If item has an on-use spell/ability
            if spellName and itemName then
                local prefix = (slot == 13 or slot == 14) and "Trinket: " or ((slot == 10 and "Hands: ") or "Use: ")
                local actionName = prefix .. itemName
                if not FC._registeredSpellNames[actionName] then
                    FC:RegisterItemAction({
                        name = actionName,
                        itemId = itemId,
                        slotId = slot,
                        icon = itemTexture or "Interface\\Icons\\INV_Misc_Gem_Stone_01",
                        role = (slot == 13 or slot == 14) and "trinket" or "use",
                        priority = (slot == 13 or slot == 14 or slot == 10) and 45 or 30,
                        cooldownHint = 120,
                        conditions = function(state)
                            if not state.engaged or not state.inCombat then return false end
                            if not (state.target and state.target.exists and state.target.hostile and not state.target.dead) then
                                return false
                            end
                            local cd = FC:GetInventorySlotCooldownRemaining(slot)
                            return cd <= 0
                        end,
                        score = function(state)
                            local s = 30
                            if state.target and state.target.isBoss then
                                s = s + 35
                            end
                            if state.target and state.target.healthPct > 70 then
                                s = s + 15
                            end
                            return s
                        end
                    })
                end
            end
        end
    end

    -- 2. Scan Healthstones in Bags
    for _, hsId in ipairs(HEALTHSTONES) do
        local count = GetItemCount(hsId)
        if count and count > 0 then
            local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(hsId)
            local actionName = itemName or "Healthstone"
            if not FC._registeredSpellNames[actionName] then
                FC:RegisterItemAction({
                    name = actionName,
                    itemId = hsId,
                    icon = itemTexture or "Interface\\Icons\\INV_Stone_04",
                    role = "heal",
                    priority = 90,
                    cooldownHint = 120,
                    conditions = function(state)
                        if not state.inCombat then return false end
                        if state.player.healthPct > (FC.db and FC.db.minHealthEmergency or 35) then return false end
                        if GetItemCount(hsId) <= 0 then return false end
                        local cd = FC:GetItemCooldownRemaining(hsId)
                        return cd <= 0
                    end,
                    score = function(state)
                        local missing = 100 - (state.player.healthPct or 100)
                        return 100 + (missing * 2.5) + (state.dangerLevel or 0)
                    end
                })
            end
            break -- only need best available healthstone
        end
    end

    -- 3. Scan Healing Potions
    for _, potId in ipairs(HEALING_POTIONS) do
        local count = GetItemCount(potId)
        if count and count > 0 then
            local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(potId)
            local actionName = itemName or "Healing Potion"
            if not FC._registeredSpellNames[actionName] then
                FC:RegisterItemAction({
                    name = actionName,
                    itemId = potId,
                    icon = itemTexture or "Interface\\Icons\\INV_Potion_54",
                    role = "heal",
                    priority = 85,
                    cooldownHint = 60,
                    conditions = function(state)
                        if not state.inCombat then return false end
                        if state.player.healthPct > 30 then return false end
                        if GetItemCount(potId) <= 0 then return false end
                        local cd = FC:GetItemCooldownRemaining(potId)
                        return cd <= 0
                    end,
                    score = function(state)
                        local missing = 100 - (state.player.healthPct or 100)
                        return 80 + (missing * 2) + (state.dangerLevel or 0)
                    end
                })
            end
            break
        end
    end

    -- 4. Scan Mana Potions (for mana users)
    if FC.state.player.powerType == 0 then
        for _, potId in ipairs(MANA_POTIONS) do
            local count = GetItemCount(potId)
            if count and count > 0 then
                local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(potId)
                local actionName = itemName or "Mana Potion"
                if not FC._registeredSpellNames[actionName] then
                    FC:RegisterItemAction({
                        name = actionName,
                        itemId = potId,
                        icon = itemTexture or "Interface\\Icons\\INV_Potion_76",
                        role = "mana",
                        priority = 60,
                        cooldownHint = 60,
                        conditions = function(state)
                            if not state.inCombat then return false end
                            if state.player.powerPct > 20 then return false end
                            if GetItemCount(potId) <= 0 then return false end
                            local cd = FC:GetItemCooldownRemaining(potId)
                            return cd <= 0
                        end,
                        score = function(state)
                            local missing = 100 - (state.player.powerPct or 100)
                            return 40 + (missing * 1.5)
                        end
                    })
                end
                break
            end
        end
    end
end

-- =========================================================
-- SCAN SYNASTRIA ATTUNEMENTS, FORGES & CUSTOM PERKS
-- =========================================================
local forgeScanTooltip = CreateFrame("GameTooltip", "FlowCoreForgeScanTooltip", UIParent, "GameTooltipTemplate")
forgeScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

function FC:ScanAttunementsAndForges()
    self.forgedStats = {
        lightforged = 0,
        warforged = 0,
        titanforged = 0,
        totalAttuned = 0,
        totalMythic = 0,
        totalDamageBonus = 0.0,
        pieces = {}
    }

    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
            local pieceType = nil
            local pieceName = GetItemInfo(itemLink) or ("Slot " .. slot)
            local isAttuned = false
            local isMythic = false

            -- 1. Check Native Synastria DLL / Data Scanner
            if itemId and self.GetSynastriaItemData then
                local d = self:GetSynastriaItemData(itemId)
                if d then
                    if d.forgeTier == 1 or d.forgeName == "Titanforged" then
                        pieceType = "Titanforged"
                    elseif d.forgeTier == 2 or d.forgeName == "Warforged" then
                        pieceType = "Warforged"
                    elseif d.forgeTier == 3 or d.forgeName == "Lightforged" then
                        pieceType = "Lightforged"
                    end
                    if d.isAttuned or (d.attuneProgress and d.attuneProgress >= 100) then
                        isAttuned = true
                    end
                    if d.isMythic then isMythic = true end
                end
            end

            -- 2. Check Tooltip Lines & Item Links for Custom Suffixes
            if not pieceType then
                forgeScanTooltip:ClearLines()
                forgeScanTooltip:SetInventoryItem("player", slot)

                for lineIdx = 1, forgeScanTooltip:NumLines() do
                    local lineText = _G["FlowCoreForgeScanTooltipTextLeft" .. lineIdx]
                    if lineText then
                        local txt = lineText:GetText() or ""
                        if string.find(txt, "Titanforged", 1, true) or string.find(txt, "Titan-Forged", 1, true) then
                            pieceType = "Titanforged"
                            break
                        elseif string.find(txt, "Warforged", 1, true) or string.find(txt, "War-Forged", 1, true) then
                            pieceType = "Warforged"
                            break
                        elseif string.find(txt, "Lightforged", 1, true) or string.find(txt, "Light-Forged", 1, true) then
                            pieceType = "Lightforged"
                            break
                        elseif string.find(txt, "Attuned", 1, true) then
                            isAttuned = true
                        end
                    end
                end
            end

            if pieceType == "Titanforged" then
                self.forgedStats.titanforged = self.forgedStats.titanforged + 1
            elseif pieceType == "Warforged" then
                self.forgedStats.warforged = self.forgedStats.warforged + 1
            elseif pieceType == "Lightforged" then
                self.forgedStats.lightforged = self.forgedStats.lightforged + 1
            end

            if isAttuned then self.forgedStats.totalAttuned = self.forgedStats.totalAttuned + 1 end
            if isMythic then self.forgedStats.totalMythic = self.forgedStats.totalMythic + 1 end

            if pieceType or isAttuned or isMythic then
                table.insert(self.forgedStats.pieces, {
                    slot = slot,
                    name = pieceName,
                    type = pieceType or (isMythic and "Mythic") or "Attuned",
                    attuned = isAttuned,
                    mythic = isMythic
                })
            end
        end
    end

    -- Calculate total damage multiplier (+2% Lightforged, +3.5% Warforged, +5% Titanforged per piece)
    self.forgedStats.totalDamageBonus = (self.forgedStats.lightforged * 0.02) +
                                        (self.forgedStats.warforged * 0.035) +
                                        (self.forgedStats.titanforged * 0.05)

    if self.state and self.state.player then
        self.state.player.synastriaDamageBonus = self.forgedStats.totalDamageBonus
    end

    return self.forgedStats
end
