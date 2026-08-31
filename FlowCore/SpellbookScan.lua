FlowCore = FlowCore or {}
local FC = FlowCore

FC.spellbookOverrides = FC.spellbookOverrides or {}
FC._registeredSpellNames = FC._registeredSpellNames or {}

local BOOKTYPE_SPELL = BOOKTYPE_SPELL or "spell"

-- =====================================================================
-- SPELL BLACKLIST (Non-combat, Professions, Mounts, Utilities)
-- =====================================================================
local IGNORED_SPELLS = {
    ["Attack"] = true,
    ["Auto Shot"] = true,
    ["Shoot"] = true,
    ["Throw"] = true,
    ["Dodge"] = true,
    ["Parry"] = true,
    ["Block"] = true,
    ["Dual Wield"] = true,
    ["Hearthstone"] = true,
    ["Cooking"] = true,
    ["First Aid"] = true,
    ["Fishing"] = true,
    ["Mining"] = true,
    ["Smelting"] = true,
    ["Herbalism"] = true,
    ["Skinning"] = true,
    ["Alchemy"] = true,
    ["Blacksmithing"] = true,
    ["Enchanting"] = true,
    ["Engineering"] = true,
    ["Inscription"] = true,
    ["Jewelcrafting"] = true,
    ["Leatherworking"] = true,
    ["Tailoring"] = true,
    ["Apprentice Riding"] = true,
    ["Journeyman Riding"] = true,
    ["Expert Riding"] = true,
    ["Artisan Riding"] = true,
    ["Cold Weather Flying"] = true,
    ["Flight Master's License"] = true,
    ["Find Minerals"] = true,
    ["Find Herbs"] = true,
    ["Find Fish"] = true,
    ["Track Humanoids"] = true,
    ["Track Beasts"] = true,
    ["Track Undead"] = true,
    ["Track Hidden"] = true,
    ["Track Elementals"] = true,
    ["Track Demons"] = true,
    ["Track Giants"] = true,
    ["Track Dragonkin"] = true,
    ["Sense Undead"] = true,
    ["Sense Demons"] = true,
    ["Disenchant"] = true,
    ["Prospecting"] = true,
    ["Milling"] = true,
    ["Pick Lock"] = true,
    ["Herb Gathering"] = true,
    ["Survey"] = true,
    ["Archaeology"] = true,
    ["Conjure Refreshment"] = true,
    ["Conjure Food"] = true,
    ["Conjure Water"] = true,
    ["Conjure Mana Gem"] = true,
    ["Portal: Shattrath"] = true,
    ["Portal: Dalaran"] = true,
    ["Portal: Orgrimmar"] = true,
    ["Portal: Stormwind"] = true,
    ["Portal: Ironforge"] = true,
    ["Portal: Darnassus"] = true,
    ["Portal: Undercity"] = true,
    ["Portal: Thunder Bluff"] = true,
    ["Portal: Silvermoon"] = true,
    ["Portal: Exodar"] = true,
    ["Teleport: Shattrath"] = true,
    ["Teleport: Dalaran"] = true,
    ["Teleport: Orgrimmar"] = true,
    ["Teleport: Stormwind"] = true,
    ["Teleport: Ironforge"] = true,
    ["Teleport: Darnassus"] = true,
    ["Teleport: Undercity"] = true,
    ["Teleport: Thunder Bluff"] = true,
    ["Teleport: Silvermoon"] = true,
    ["Teleport: Exodar"] = true,
    ["Ritual of Refreshment"] = true,
    ["Ritual of Souls"] = true,
    ["Ritual of Summoning"] = true,
    ["Basic Campfire"] = true,
    ["Slow Fall"] = true,
    ["Teleport"] = true,
    ["Warp"] = true,
    ["Dampen Magic"] = true,
    ["Amplify Magic"] = true,
    ["Polymorph"] = true,
    ["Master of Anatomy"] = true,
    ["Northern Cloth Scavenging"] = true,
    ["Regeneration"] = true,
    ["Gem Perfection"] = true,
    ["Da Voodoo Shuffle"] = true,
    ["Beast Slaying"] = true,
    ["Berserking"] = true,
    ["Toughness"] = true,
    ["Lifeblood"] = true
}

local function IsIgnoredSpell(spellName)
    if not spellName or spellName == "" then return true end
    if IGNORED_SPELLS[spellName] then return true end

    -- Pattern matching for custom Synastria UI menus, portals, teleports, and profession macros
    if string.find(spellName, "^View ") or
       string.find(spellName, "^Portal:") or
       string.find(spellName, "^Teleport:") or
       string.find(spellName, "%(Mass%)$") or
       string.find(spellName, " Specialization$") or
       string.find(spellName, " Tailoring$") or
       string.find(spellName, " Leatherworking$") or
       string.find(spellName, " Blacksmithing$") or
       string.find(spellName, " Engineering$") or
       string.find(spellName, " Alchemy$") or
       string.find(spellName, " Jewelcrafting$") or
       string.find(spellName, " Inscription$") or
       string.find(spellName, "^Track ") or
       string.find(spellName, "^Find ") or
       string.find(spellName, "^Sense ") then
        return true
    end

    return false
end

-- =====================================================================
-- MUTUALLY EXCLUSIVE BUFF GROUPS
-- =====================================================================
local EXCLUSIVE_BUFF_GROUPS = {
    ["MAGE_ARMOR"] = {
        spells = { ["Molten Armor"] = true, ["Mage Armor"] = true, ["Ice Armor"] = true, ["Frost Armor"] = true },
        preference = { "Molten Armor", "Mage Armor", "Ice Armor", "Frost Armor" }
    },
    ["MAGE_INTELLECT"] = {
        spells = { ["Arcane Intellect"] = true, ["Arcane Brilliance"] = true, ["Dalaran Intellect"] = true, ["Dalaran Brilliance"] = true },
        preference = { "Arcane Brilliance", "Dalaran Brilliance", "Arcane Intellect", "Dalaran Intellect" }
    },
    ["PALADIN_SEAL"] = {
        spells = { ["Seal of Vengeance"] = true, ["Seal of Corruption"] = true, ["Seal of Command"] = true, ["Seal of Righteousness"] = true, ["Seal of Wisdom"] = true, ["Seal of Light"] = true },
        preference = { "Seal of Vengeance", "Seal of Corruption", "Seal of Command", "Seal of Righteousness", "Seal of Wisdom", "Seal of Light" }
    },
    ["PALADIN_BLESSING"] = {
        spells = { ["Greater Blessing of Might"] = true, ["Blessing of Might"] = true, ["Greater Blessing of Kings"] = true, ["Blessing of Kings"] = true, ["Greater Blessing of Wisdom"] = true, ["Blessing of Wisdom"] = true, ["Greater Blessing of Sanctuary"] = true, ["Blessing of Sanctuary"] = true },
        preference = { "Greater Blessing of Might", "Blessing of Might", "Greater Blessing of Kings", "Blessing of Kings" }
    },
    ["WARLOCK_ARMOR"] = {
        spells = { ["Fel Armor"] = true, ["Demon Armor"] = true, ["Demon Skin"] = true },
        preference = { "Fel Armor", "Demon Armor", "Demon Skin" }
    },
    ["PRIEST_FORTITUDE"] = {
        spells = { ["Prayer of Fortitude"] = true, ["Power Word: Fortitude"] = true },
        preference = { "Prayer of Fortitude", "Power Word: Fortitude" }
    },
    ["PRIEST_SPIRIT"] = {
        spells = { ["Prayer of Spirit"] = true, ["Divine Spirit"] = true },
        preference = { "Prayer of Spirit", "Divine Spirit" }
    },
    ["PRIEST_SHADOW_PROT"] = {
        spells = { ["Prayer of Shadow Protection"] = true, ["Shadow Protection"] = true },
        preference = { "Prayer of Shadow Protection", "Shadow Protection" }
    },
    ["DRUID_MARK"] = {
        spells = { ["Gift of the Wild"] = true, ["Mark of the Wild"] = true },
        preference = { "Gift of the Wild", "Mark of the Wild" }
    },
    ["PRIEST_INNER"] = {
        spells = { ["Inner Fire"] = true, ["Inner Will"] = true },
        preference = { "Inner Fire", "Inner Will" }
    },
    ["SHAMAN_SHIELD"] = {
        spells = { ["Lightning Shield"] = true, ["Water Shield"] = true, ["Earth Shield"] = true },
        preference = { "Lightning Shield", "Water Shield", "Earth Shield" }
    },
    ["DK_PRESENCE"] = {
        spells = { ["Blood Presence"] = true, ["Frost Presence"] = true, ["Unholy Presence"] = true },
        preference = { "Blood Presence", "Frost Presence", "Unholy Presence" }
    }
}

local SPELL_TO_EXCLUSIVE_GROUP = {}
for groupName, groupDef in pairs(EXCLUSIVE_BUFF_GROUPS) do
    for spell, _ in pairs(groupDef.spells) do
        SPELL_TO_EXCLUSIVE_GROUP[spell] = groupName
    end
end

local STANDALONE_SELF_BUFFS = {
    ["Thorns"] = true,
    ["Battle Shout"] = true,
    ["Commanding Shout"] = true,
    ["Horn of Winter"] = true,
    ["Bone Shield"] = true,
    ["Vampiric Embrace"] = true
}

local DEFENSIVE_SPELLS = {
    ["Ice Block"] = { hp = 20, priority = 100, cd = 300, school = "Frost" },
    ["Ice Barrier"] = { hp = 100, priority = 90, cd = 30, school = "Frost" }, -- Maintained 100% when actively tanking
    ["Mana Shield"] = { hp = 70, priority = 80, school = "Arcane" },
    ["Frost Ward"] = { hp = 90, priority = 65, cd = 30, school = "Frost" },
    ["Fire Ward"] = { hp = 90, priority = 65, cd = 30, school = "Fire" },
    ["Ice Ward"] = { hp = 90, priority = 65, cd = 30, school = "Frost" },
    ["Frost Nova"] = { hp = 95, priority = 72, cd = 25, school = "Frost" },
    ["Blink"] = { hp = 40, priority = 75, cd = 15, school = "Arcane" },
    ["Mage Ward"] = { hp = 60, priority = 70, cd = 30, school = "Arcane" },
    ["Mirror Image"] = { hp = 70, priority = 75, cd = 180, school = "Arcane" },
    ["Invisibility"] = { hp = 15, priority = 90, cd = 180, school = "Arcane" },
    ["Divine Shield"] = { hp = 20, priority = 100, cd = 300, school = "Holy" },
    ["Divine Protection"] = { hp = 50, priority = 85, cd = 120, school = "Holy" },
    ["Sacred Shield"] = { hp = 100, priority = 88, cd = 6, school = "Holy" },
    ["Holy Shield"] = { hp = 100, priority = 90, cd = 8, school = "Holy" },
    ["Lay on Hands"] = { hp = 15, priority = 95, cd = 1200, school = "Holy" },
    ["Shield Wall"] = { hp = 35, priority = 95, cd = 300, school = "Physical" },
    ["Shield Block"] = { hp = 90, priority = 85, cd = 40, school = "Physical" },
    ["Last Stand"] = { hp = 25, priority = 90, cd = 180, school = "Physical" },
    ["Enraged Regeneration"] = { hp = 40, priority = 85, cd = 180, school = "Physical" },
    ["Icebound Fortitude"] = { hp = 45, priority = 90, cd = 120, school = "Frost" },
    ["Anti-Magic Shell"] = { hp = 60, priority = 85, cd = 45, school = "Shadow" },
    ["Bone Shield"] = { hp = 100, priority = 88, cd = 60, school = "Unholy" },
    ["Vampiric Blood"] = { hp = 45, priority = 90, cd = 60, school = "Blood" },
    ["Cloak of Shadows"] = { hp = 50, priority = 85, cd = 90, school = "Physical" },
    ["Evasion"] = { hp = 50, priority = 85, cd = 180, school = "Physical" },
    ["Feint"] = { hp = 60, priority = 70, cd = 10, school = "Physical" },
    ["Deterrence"] = { hp = 35, priority = 90, cd = 90, school = "Physical" },
    ["Shamanistic Rage"] = { hp = 50, priority = 85, cd = 60, school = "Physical" },
    ["Barkskin"] = { hp = 60, priority = 85, cd = 60, school = "Nature" },
    ["Survival Instincts"] = { hp = 35, priority = 90, cd = 180, school = "Physical" },
    ["Frenzied Regeneration"] = { hp = 40, priority = 85, cd = 180, school = "Physical" },
    ["Dispersion"] = { hp = 25, priority = 95, cd = 120, school = "Shadow" },
    ["Power Word: Shield"] = { hp = 100, priority = 88, cd = 4, school = "Holy" }
}

local MAJOR_COOLDOWNS = {
    ["Combustion"] = { priority = 85, cd = 120, school = "Fire" },
    ["Icy Veins"] = { priority = 85, cd = 144, school = "Frost" },
    ["Arcane Power"] = { priority = 85, cd = 100, school = "Arcane" },
    ["Presence of Mind"] = { priority = 80, cd = 120, school = "Arcane" },
    ["Avenging Wrath"] = { priority = 85, cd = 120, school = "Holy" },
    ["Death Wish"] = { priority = 85, cd = 180, school = "Physical" },
    ["Recklessness"] = { priority = 85, cd = 300, school = "Physical" },
    ["Army of the Dead"] = { priority = 80, cd = 600, school = "Shadow" },
    ["Summon Gargoyle"] = { priority = 85, cd = 180, school = "Shadow" },
    ["Empower Rune Weapon"] = { priority = 85, cd = 300, school = "Physical" },
    ["Adrenaline Rush"] = { priority = 85, cd = 180, school = "Physical" },
    ["Killing Spree"] = { priority = 85, cd = 120, school = "Physical" },
    ["Shadow Dance"] = { priority = 85, cd = 60, school = "Physical" },
    ["Rapid Fire"] = { priority = 85, cd = 300, school = "Physical" },
    ["Call of the Wild"] = { priority = 80, cd = 300, school = "Physical" },
    ["Bloodlust"] = { priority = 90, cd = 300, school = "Physical" },
    ["Heroism"] = { priority = 90, cd = 300, school = "Physical" },
    ["Feral Spirit"] = { priority = 85, cd = 120, school = "Physical" },
    ["Berserk"] = { priority = 85, cd = 180, school = "Physical" },
    ["Tiger's Fury"] = { priority = 75, cd = 30, school = "Physical" },
    ["Shadowfiend"] = { priority = 75, cd = 300, school = "Shadow" }
}

local INTERRUPT_SPELLS = {
    ["Counterspell"] = { cd = 24, school = "Arcane" },
    ["Wind Shear"] = { cd = 6, school = "Nature" },
    ["Kick"] = { cd = 10, school = "Physical" },
    ["Pummel"] = { cd = 10, school = "Physical" },
    ["Shield Bash"] = { cd = 12, school = "Physical" },
    ["Mind Freeze"] = { cd = 10, school = "Frost" },
    ["Strangulate"] = { cd = 120, school = "Shadow" },
    ["Hammer of Justice"] = { cd = 60, school = "Holy" },
    ["Silencing Shot"] = { cd = 20, school = "Physical" },
    ["Silence"] = { cd = 45, school = "Shadow" },
    ["Feral Charge - Bear"] = { cd = 15, school = "Physical" },
    ["Feral Charge - Cat"] = { cd = 30, school = "Physical" },
    ["Skull Bash"] = { cd = 10, school = "Physical" },
    ["Spell Lock"] = { cd = 24, school = "Shadow" }
}

local DISPEL_SPELLS = {
    ["Spellsteal"] = { role = "dispel", priority = 75, school = "Arcane", conditions = function(state)
        return state.target and state.target.hasStealableBuff
    end },
    ["Purge"] = { role = "dispel", priority = 70, school = "Nature", conditions = function(state)
        return state.target and state.target.hasStealableBuff
    end },
    ["Dispel Magic"] = { role = "dispel", priority = 65, school = "Holy", conditions = function(state)
        return state.target and state.target.hasStealableBuff
    end },
    ["Remove Curse"] = { role = "dispel", priority = 65, school = "Arcane", conditions = function(state)
        return state.player and state.player.hasCurse
    end },
    ["Cleanse"] = { role = "dispel", priority = 65, school = "Holy", conditions = function(state)
        local p = state.player or {}
        return p.hasPoison or p.hasDisease or p.hasMagicDebuff
    end },
    ["Cure Toxins"] = { role = "dispel", priority = 60, school = "Nature", conditions = function(state)
        local p = state.player or {}
        return p.hasPoison or p.hasDisease
    end }
}

-- =====================================================
-- ROTATIONAL & AOE SPELLS DATABASE (Comprehensive WotLK Class Catalog)
-- =====================================================
local ROTATIONAL_SPELLS = {
    -- -------------------------------------------------------------
    ["Pyroblast"] = { priority = 90, role = "nuke", school = "Fire", castTime = 5.0, class = "MAGE", procBonus = { ["Hot Streak"] = 2.5 }, conditions = function(state)
        local buffs = (state.player and state.player.buffs) or {}
        -- Fire Mage: Only cast Pyroblast with Hot Streak (instant) in combat, or as out-of-combat opener
        return (buffs["Hot Streak"] and (buffs["Hot Streak"].remaining or 0) > 0) or not state.inCombat
    end },
    ["Deep Freeze"] = { priority = 85, role = "cooldown", school = "Frost", cooldown = 30, class = "MAGE", conditions = function(state)
        local buffs = state.player.buffs or {}
        return (buffs["Fingers of Frost"] and buffs["Fingers of Frost"].remaining > 0) or (state.target and state.target.isFrozen)
    end },
    ["Living Bomb"] = { priority = 65, role = "dot", school = "Fire", dotDuration = 12, class = "MAGE", conditions = function(state)
        local debuff = state.target.debuffs and state.target.debuffs["Living Bomb"]
        local needTarget = not debuff or not debuff.mine or (debuff.remaining or 0) <= 1.5
        if needTarget then return true end

        -- Multi-Target Cleave: If multiple enemies exist and active Living Bombs < 3
        if (state.enemyCount or 1) > 1 and FC.GetMultiTargetDotInfo then
            local activeCount, _, maxAllowed = FC:GetMultiTargetDotInfo("Living Bomb")
            if activeCount < math.min(state.enemyCount or 1, maxAllowed or 3) then
                return true
            end
        end
        return false
    end },
    ["Arcane Blast"] = { priority = 60, role = "nuke", school = "Arcane", castTime = 2.5, class = "MAGE" },
    ["Arcane Missiles"] = { priority = 55, role = "nuke", school = "Arcane", castTime = 5.0, class = "MAGE", procBonus = { ["Missile Barrage"] = 2.0, ["Clearcasting"] = 1.6 } },
    ["Arcane Barrage"] = { priority = 52, role = "nuke", school = "Arcane", cooldown = 3, class = "MAGE" },
    ["Fire Blast"] = { priority = 50, role = "nuke", school = "Fire", cooldown = 8, class = "MAGE" },
    ["Ice Lance"] = { priority = 48, role = "nuke", school = "Frost", class = "MAGE", procBonus = { ["Fingers of Frost"] = 2.0 } },
    ["Frostfire Bolt"] = { priority = 48, role = "nuke", school = "Fire", castTime = 3.0, class = "MAGE", procBonus = { ["Brain Freeze"] = 2.2 } },
    ["Fireball"] = { priority = 45, role = "nuke", school = "Fire", castTime = 3.5, class = "MAGE", procBonus = { ["Brain Freeze"] = 2.2 } },
    ["Frostbolt"] = { priority = 45, role = "nuke", school = "Frost", castTime = 3.0, class = "MAGE" },
    ["Scorch"] = { priority = 40, role = "nuke", school = "Fire", castTime = 1.5, class = "MAGE" },
    ["Dragon's Breath"] = { priority = 55, role = "aoe", school = "Fire", cooldown = 20, class = "MAGE" },
    ["Cone of Cold"] = { priority = 52, role = "aoe", school = "Frost", cooldown = 10, class = "MAGE" },
    ["Flamestrike"] = {
        priority = 80, role = "aoe", school = "Fire", castTime = 2.0, class = "MAGE",
        conditions = function(state)
            local enemies = state.enemyCount or 1
            if enemies < 3 and not (state.simulationActive and state.simulationMode == "aoe") then
                return false
            end
            local now = GetTime()
            local r9_exp = (state.flamestrike_r9_expiry or 0) - now
            return r9_exp <= 1.5
        end
    },
    ["Flamestrike (Rank 8)"] = {
        priority = 78, role = "aoe", school = "Fire", castTime = 2.0, class = "MAGE",
        conditions = function(state)
            local enemies = state.enemyCount or 1
            if enemies < 3 and not (state.simulationActive and state.simulationMode == "aoe") then
                return false
            end
            local now = GetTime()
            local r9_exp = (state.flamestrike_r9_expiry or 0) - now
            local r8_exp = (state.flamestrike_r8_expiry or 0) - now
            -- Recommend Rank 8 when Rank 9 ground DoT is active and Rank 8 ground DoT is down
            return r9_exp > 1.5 and r8_exp <= 1.5
        end
    },
    ["Blizzard"] = {
        priority = 75, role = "aoe", school = "Frost", castTime = 8.0, class = "MAGE",
        conditions = function(state)
            local enemies = state.enemyCount or 1
            if enemies < 3 and not (state.simulationActive and state.simulationMode == "aoe") then
                return false
            end
            local now = GetTime()
            local r9_exp = (state.flamestrike_r9_expiry or 0) - now
            local r8_exp = (state.flamestrike_r8_expiry or 0) - now
            local hasR8 = FC._registeredSpellNames["Flamestrike (Rank 8)"]
            if hasR8 then
                return r9_exp > 1.5 and r8_exp > 1.5
            else
                return r9_exp > 1.5
            end
        end
    },
    ["Arcane Explosion"] = { priority = 42, role = "aoe", school = "Arcane", class = "MAGE" },
    ["Evocation"] = { priority = 85, role = "mana", school = "Arcane", cooldown = 240, class = "MAGE", conditions = function(state)
        local p = state.player or {}
        local hasEvoGlyph = (FC.extState and FC.extState.activeGlyphs and FC.extState.activeGlyphs["Glyph of Evocation"])
        if hasEvoGlyph and (p.healthPct or 100) <= 45 then return true end
        return state.inCombat and (p.powerPct or 100) <= 25
    end },

    -- -------------------------------------------------------------
    -- PALADIN
    -- -------------------------------------------------------------
    ["Hammer of Wrath"] = { priority = 85, role = "execute", school = "Holy", cooldown = 6, class = "PALADIN", conditions = function(state)
        return (state.target.healthPct or 100) <= 20
    end },
    ["Judgement of Light"] = { priority = 65, role = "nuke", school = "Holy", cooldown = 8, class = "PALADIN" },
    ["Judgement of Wisdom"] = { priority = 65, role = "nuke", school = "Holy", cooldown = 8, class = "PALADIN" },
    ["Crusader Strike"] = { priority = 60, role = "nuke", school = "Physical", cooldown = 4, class = "PALADIN" },
    ["Divine Storm"] = { priority = 58, role = "nuke", school = "Physical", cooldown = 10, class = "PALADIN" },
    ["Exorcism"] = { priority = 55, role = "nuke", school = "Holy", cooldown = 15, class = "PALADIN", procBonus = { ["The Art of War"] = 2.2 } },
    ["Hammer of the Righteous"] = { priority = 60, role = "nuke", school = "Physical", cooldown = 6, class = "PALADIN" },
    ["Shield of Righteousness"] = { priority = 58, role = "nuke", school = "Holy", cooldown = 6, class = "PALADIN" },
    ["Holy Wrath"] = { priority = 60, role = "aoe", school = "Holy", cooldown = 30, class = "PALADIN" },
    ["Consecration"] = { priority = 52, role = "aoe", school = "Holy", cooldown = 8, class = "PALADIN" },
    ["Holy Shock"] = { priority = 55, role = "heal", school = "Holy", cooldown = 6, class = "PALADIN" },

    -- -------------------------------------------------------------
    -- WARLOCK
    -- -------------------------------------------------------------
    ["Soul Fire"] = { priority = 70, role = "execute", school = "Fire", castTime = 4.0, class = "WARLOCK", procBonus = { ["Decimation"] = 2.5 } },
    ["Chaos Bolt"] = { priority = 68, role = "nuke", school = "Fire", cooldown = 12, castTime = 2.5, class = "WARLOCK" },
    ["Conflagrate"] = { priority = 65, role = "nuke", school = "Fire", cooldown = 10, class = "WARLOCK", conditions = function(state)
        local debuffs = state.target.debuffs or {}
        return (debuffs["Immolate"] and debuffs["Immolate"].mine) or (debuffs["Shadowflame"] and debuffs["Shadowflame"].mine)
    end },
    ["Haunt"] = { priority = 62, role = "dot", school = "Shadow", cooldown = 8, dotDuration = 12, castTime = 1.5, class = "WARLOCK" },
    ["Unstable Affliction"] = { priority = 60, role = "dot", school = "Shadow", dotDuration = 15, castTime = 1.5, class = "WARLOCK" },
    ["Corruption"] = { priority = 58, role = "dot", school = "Shadow", dotDuration = 18, class = "WARLOCK" },
    ["Immolate"] = { priority = 58, role = "dot", school = "Fire", dotDuration = 15, castTime = 2.0, class = "WARLOCK" },
    ["Incinerate"] = { priority = 46, role = "nuke", school = "Fire", castTime = 2.5, class = "WARLOCK" },
    ["Shadow Bolt"] = { priority = 45, role = "nuke", school = "Shadow", castTime = 3.0, class = "WARLOCK", procBonus = { ["Shadow Trance"] = 2.2 } },
    ["Drain Soul"] = { priority = 65, role = "execute", school = "Shadow", class = "WARLOCK", conditions = function(state)
        return (state.target.healthPct or 100) <= 25
    end },
    ["Life Tap"] = { priority = 50, role = "mana", school = "Shadow", class = "WARLOCK", conditions = function(state)
        return state.inCombat and (state.player.powerPct or 100) <= 35 and (state.player.healthPct or 100) > 55
    end },

    -- -------------------------------------------------------------
    -- SHAMAN
    -- -------------------------------------------------------------
    ["Lava Burst"] = { priority = 75, role = "nuke", school = "Fire", cooldown = 8, castTime = 2.0, class = "SHAMAN" },
    ["Flame Shock"] = { priority = 68, role = "dot", school = "Fire", cooldown = 6, dotDuration = 18, class = "SHAMAN" },
    ["Earth Shock"] = { priority = 55, role = "nuke", school = "Nature", cooldown = 6, class = "SHAMAN" },
    ["Lightning Bolt"] = { priority = 50, role = "nuke", school = "Nature", castTime = 2.5, class = "SHAMAN" },
    ["Chain Lightning"] = { priority = 60, role = "aoe", school = "Nature", cooldown = 3, castTime = 2.0, class = "SHAMAN" },
    ["Stormstrike"] = { priority = 65, role = "nuke", school = "Physical", cooldown = 8, class = "SHAMAN" },
    ["Lava Lash"] = { priority = 55, role = "nuke", school = "Fire", cooldown = 6, class = "SHAMAN" },

    -- -------------------------------------------------------------
    -- PRIEST
    -- -------------------------------------------------------------
    ["Vampiric Touch"] = { priority = 70, role = "dot", school = "Shadow", castTime = 1.5, dotDuration = 15, class = "PRIEST" },
    ["Shadow Word: Pain"] = { priority = 65, role = "dot", school = "Shadow", dotDuration = 18, class = "PRIEST" },
    ["Devouring Plague"] = { priority = 68, role = "dot", school = "Shadow", dotDuration = 24, class = "PRIEST" },
    ["Mind Blast"] = { priority = 62, role = "nuke", school = "Shadow", cooldown = 8, castTime = 1.5, class = "PRIEST" },
    ["Mind Flay"] = { priority = 55, role = "nuke", school = "Shadow", castTime = 3.0, class = "PRIEST" },
    ["Shadow Word: Death"] = { priority = 58, role = "execute", school = "Shadow", cooldown = 12, class = "PRIEST" },

    -- -------------------------------------------------------------
    -- DRUID
    -- -------------------------------------------------------------
    ["Starfire"] = { priority = 55, role = "nuke", school = "Arcane", castTime = 3.5, class = "DRUID" },
    ["Wrath"] = { priority = 52, role = "nuke", school = "Nature", castTime = 1.5, class = "DRUID" },
    ["Moonfire"] = { priority = 60, role = "dot", school = "Arcane", dotDuration = 12, class = "DRUID" },
    ["Insect Swarm"] = { priority = 58, role = "dot", school = "Nature", dotDuration = 12, class = "DRUID" },
    ["Starsurge"] = { priority = 65, role = "nuke", school = "Arcane", cooldown = 15, class = "DRUID" },
    ["Mangle (Cat)"] = { priority = 65, role = "builder", school = "Physical", class = "DRUID" },
    ["Shred"] = { priority = 60, role = "builder", school = "Physical", class = "DRUID" },
    ["Rip"] = { priority = 75, role = "spender", school = "Physical", dotDuration = 16, class = "DRUID" },
    ["Ferocious Bite"] = { priority = 70, role = "spender", school = "Physical", class = "DRUID" },
    ["Rake"] = { priority = 58, role = "dot", school = "Physical", dotDuration = 9, class = "DRUID" },

    -- -------------------------------------------------------------
    -- WARRIOR
    -- -------------------------------------------------------------
    ["Execute"] = { priority = 90, role = "execute", school = "Physical", class = "WARRIOR", conditions = function(state)
        local procs = state.player.buffs or {}
        return (state.target.healthPct or 100) <= 20 or (procs["Sudden Death"] and procs["Sudden Death"].remaining > 0)
    end },
    ["Mortal Strike"] = { priority = 70, role = "nuke", school = "Physical", cooldown = 6, class = "WARRIOR" },
    ["Bloodthirst"] = { priority = 70, role = "nuke", school = "Physical", cooldown = 4, class = "WARRIOR" },
    ["Whirlwind"] = { priority = 65, role = "aoe", school = "Physical", cooldown = 10, class = "WARRIOR" },
    ["Overpower"] = { priority = 75, role = "nuke", school = "Physical", cooldown = 5, class = "WARRIOR" },
    ["Slam"] = { priority = 55, role = "nuke", school = "Physical", castTime = 1.5, class = "WARRIOR" },
    ["Rend"] = { priority = 60, role = "dot", school = "Physical", dotDuration = 15, class = "WARRIOR" },
    ["Shield Slam"] = { priority = 75, role = "nuke", school = "Physical", cooldown = 6, class = "WARRIOR" },
    ["Revenge"] = { priority = 70, role = "nuke", school = "Physical", cooldown = 5, class = "WARRIOR" },
    ["Devastate"] = { priority = 55, role = "builder", school = "Physical", class = "WARRIOR" },
    ["Shockwave"] = { priority = 65, role = "aoe", school = "Physical", cooldown = 20, class = "WARRIOR" },
    ["Thunder Clap"] = { priority = 50, role = "aoe", school = "Physical", cooldown = 6, class = "WARRIOR" },

    -- -------------------------------------------------------------
    -- DEATH KNIGHT
    -- -------------------------------------------------------------
    ["Frost Strike"] = { priority = 75, role = "spender", school = "Frost", class = "DEATHKNIGHT" },
    ["Death Coil"] = { priority = 70, role = "spender", school = "Shadow", class = "DEATHKNIGHT" },
    ["Obliterate"] = { priority = 72, role = "builder", school = "Physical", class = "DEATHKNIGHT" },
    ["Scourge Strike"] = { priority = 72, role = "builder", school = "Shadow", class = "DEATHKNIGHT" },
    ["Death Strike"] = { priority = 68, role = "builder", school = "Physical", class = "DEATHKNIGHT" },
    ["Heart Strike"] = { priority = 65, role = "builder", school = "Physical", class = "DEATHKNIGHT" },
    ["Blood Strike"] = { priority = 55, role = "builder", school = "Physical", class = "DEATHKNIGHT" },
    ["Howling Blast"] = { priority = 70, role = "aoe", school = "Frost", cooldown = 8, class = "DEATHKNIGHT" },
    ["Icy Touch"] = { priority = 60, role = "dot", school = "Frost", dotDuration = 21, class = "DEATHKNIGHT" },
    ["Plague Strike"] = { priority = 60, role = "dot", school = "Shadow", dotDuration = 21, class = "DEATHKNIGHT" },
    ["Pestilence"] = { priority = 62, role = "aoe", school = "Shadow", class = "DEATHKNIGHT" },
    ["Blood Boil"] = { priority = 55, role = "aoe", school = "Shadow", class = "DEATHKNIGHT" },

    -- -------------------------------------------------------------
    -- ROGUE
    -- -------------------------------------------------------------
    ["Mutilate"] = { priority = 70, role = "builder", school = "Physical", class = "ROGUE" },
    ["Sinister Strike"] = { priority = 65, role = "builder", school = "Physical", class = "ROGUE" },
    ["Backstab"] = { priority = 65, role = "builder", school = "Physical", class = "ROGUE" },
    ["Eviscerate"] = { priority = 75, role = "spender", school = "Physical", class = "ROGUE", conditions = function(state)
        return (state.player.comboPoints or 0) >= 4
    end },
    ["Envenom"] = { priority = 78, role = "spender", school = "Nature", class = "ROGUE", conditions = function(state)
        return (state.player.comboPoints or 0) >= 4
    end },
    ["Slice and Dice"] = { priority = 85, role = "buff", school = "Physical", class = "ROGUE", conditions = function(state)
        local buffs = state.player.buffs or {}
        return (state.player.comboPoints or 0) >= 1 and (not buffs["Slice and Dice"] or (buffs["Slice and Dice"].remaining or 0) <= 3)
    end },
    ["Rupture"] = { priority = 72, role = "spender", school = "Physical", dotDuration = 16, class = "ROGUE", conditions = function(state)
        local debuffs = state.target.debuffs or {}
        return (state.player.comboPoints or 0) >= 4 and (not debuffs["Rupture"] or (debuffs["Rupture"].remaining or 0) <= 2)
    end },
    ["Fan of Knives"] = { priority = 60, role = "aoe", school = "Physical", class = "ROGUE" },

    -- -------------------------------------------------------------
    -- HUNTER
    -- -------------------------------------------------------------
    ["Kill Shot"] = { priority = 90, role = "execute", school = "Physical", cooldown = 15, class = "HUNTER", conditions = function(state)
        return (state.target.healthPct or 100) <= 20
    end },
    ["Explosive Shot"] = { priority = 80, role = "nuke", school = "Fire", cooldown = 6, class = "HUNTER" },
    ["Chimera Shot"] = { priority = 78, role = "nuke", school = "Nature", cooldown = 10, class = "HUNTER" },
    ["Aim Shot"] = { priority = 70, role = "nuke", school = "Physical", cooldown = 10, class = "HUNTER" },
    ["Black Arrow"] = { priority = 72, role = "dot", school = "Shadow", cooldown = 30, dotDuration = 15, class = "HUNTER" },
    ["Serpent Sting"] = { priority = 68, role = "dot", school = "Nature", dotDuration = 21, class = "HUNTER" },
    ["Steady Shot"] = { priority = 50, role = "nuke", school = "Physical", castTime = 2.0, class = "HUNTER" },
    ["Multi-Shot"] = { priority = 60, role = "aoe", school = "Physical", cooldown = 10, class = "HUNTER" },
    ["Volley"] = { priority = 55, role = "aoe", school = "Physical", castTime = 6.0, class = "HUNTER" },
    ["Arcane Shot"] = { priority = 55, role = "nuke", school = "Arcane", cooldown = 6, class = "HUNTER" }
}

-- =====================================================
-- SPELL CLASSIFICATION ENGINE
-- =====================================================
local function ClassifySpell(spellName, castTimeSec, powerCost, powerType)
    if INTERRUPT_SPELLS[spellName] then
        local intr = INTERRUPT_SPELLS[spellName]
        return {
            role = "interrupt",
            priority = 95,
            cooldown = intr.cd,
            school = intr.school,
            conditions = function(state)
                if FC.db and FC.db.autoInterrupts == false then return false end
                local t = state.target
                if not t or not t.exists or not t.hostile or t.dead then return false end
                return (t.isCasting or t.isChanneling) and t.interruptible
            end,
            score = function(state)
                local t = state.target
                local rem = t.castRemaining or 1.5
                return 60 + math.max(0, (2.0 - rem) * 20)
            end
        }
    end

    if DISPEL_SPELLS[spellName] then
        local d = DISPEL_SPELLS[spellName]
        return {
            role = "dispel",
            priority = d.priority or 65,
            school = d.school,
            conditions = function(state)
                if FC.db and FC.db.autoDispels == false then return false end
                if d.conditions then
                    local ok, res = pcall(d.conditions, state)
                    if not ok or not res then return false end
                end
                return true
            end,
            score = function(state)
                return 25
            end
        }
    end

    local exclusiveGroup = SPELL_TO_EXCLUSIVE_GROUP[spellName]
    if exclusiveGroup then
        local groupDef = EXCLUSIVE_BUFF_GROUPS[exclusiveGroup]
        return {
            role = "buff",
            priority = 20,
            exclusiveGroup = exclusiveGroup,
            conditions = function(state)
                local ov = FC.db and FC.db.spellOverrides and FC.db.spellOverrides[spellName]
                if ov and ov.recastCheck == false then
                    return false
                end

                if state.inCombat and (FC.db and FC.db.allowCombatBuffs == false) then
                    return false
                end

                local threshold = math.max(10, (FC.db and FC.db.timelineWindow or 10))
                local buffs = state.player.buffs or {}
                for grpSpell, _ in pairs(groupDef.spells) do
                    local activeBuff = buffs[grpSpell]
                    if activeBuff and (activeBuff.remaining or 999) > threshold then
                        return false
                    end
                end

                for _, prefSpell in ipairs(groupDef.preference) do
                    if FC._registeredSpellNames[prefSpell] then
                        return (spellName == prefSpell)
                    end
                end
                return true
            end,
            score = function(state)
                return state.inCombat and -25 or 25
            end
        }
    end

    if STANDALONE_SELF_BUFFS[spellName] then
        return {
            role = "buff",
            priority = 18,
            conditions = function(state)
                local ov = FC.db and FC.db.spellOverrides and FC.db.spellOverrides[spellName]
                if ov and ov.recastCheck == false then
                    return false
                end

                if state.inCombat and (FC.db and FC.db.allowCombatBuffs == false) then
                    return false
                end

                local threshold = math.max(10, (FC.db and FC.db.timelineWindow or 10))
                local buff = state.player.buffs and state.player.buffs[spellName]
                if not buff then return true end
                return (buff.remaining or 999) <= threshold
            end,
            score = function(state)
                return state.inCombat and -25 or 20
            end
        }
    end

    if DEFENSIVE_SPELLS[spellName] then
        local def = DEFENSIVE_SPELLS[spellName]
        return {
            role = "defensive",
            priority = def.priority,
            cooldown = def.cd,
            school = def.school or "Physical",
            conditions = function(state)
                if not state.inCombat then return false end
                if FC.db and FC.db.autoDefensives == false then return false end
                local hp = state.player.healthPct or 100
                local danger = state.dangerLevel or 0
                return (hp <= def.hp) or (danger >= 55)
            end,
            score = function(state)
                local missing = 100 - (state.player.healthPct or 100)
                return (missing * 1.8) + (state.dangerLevel or 0) * 1.2
            end
        }
    end

    if MAJOR_COOLDOWNS[spellName] then
        local cd = MAJOR_COOLDOWNS[spellName]
        return {
            role = "cooldown",
            priority = cd.priority,
            cooldown = cd.cd,
            school = cd.school or "Physical",
            conditions = function(state)
                if not state.target or not state.target.exists or state.target.dead then return false end
                return (state.target.healthPct or 0) > 30 or (state.target.isBoss)
            end,
            score = function(state)
                local s = 30
                if state.target and state.target.isBoss then s = s + 35 end
                if state.target and (state.target.ttd or 0) > 15 then s = s + 20 end
                return s
            end
        }
    end

    if ROTATIONAL_SPELLS[spellName] then
        local r = ROTATIONAL_SPELLS[spellName]
        return {
            role = r.role or "nuke",
            priority = r.priority or 45,
            cooldown = r.cooldown or 0,
            castTime = r.castTime or castTimeSec,
            dotDuration = r.dotDuration or 0,
            procBonus = r.procBonus,
            school = r.school or "Physical",
            conditions = function(state)
                if not state.target or not state.target.exists or not state.target.hostile or state.target.dead then
                    return false
                end
                if r.conditions then
                    local ok, res = pcall(r.conditions, state)
                    if not ok or not res then return false end
                end
                return true
            end,
            score = function(state)
                return 15
            end
        }
    end

    return {
        role = "utility",
        priority = 5,
        castTime = castTimeSec,
        school = "Physical",
        conditions = function(state)
            return false
        end,
        score = function(state)
            return 0
        end
    }
end

-- =====================================================
-- MAIN SPELLBOOK SCAN
-- =====================================================
function FC:ScanSpellbook(force)
    local discovered = 0

    if force then
        FC._registeredSpellNames = {}
        FC.actions = {}
    end

    -- 1. Scan Player's Actual Spellbook Slots
    if GetNumSpellTabs then
        local numTabs = GetNumSpellTabs()
        for tab = 1, (numTabs or 0) do
            local tabName, _, offset, numSpells = GetSpellTabInfo(tab)
            if offset and numSpells then
                for i = offset + 1, offset + numSpells do
                    local sType, sId = nil, nil
                    if GetSpellBookItemInfo then
                        local ok, t, id = pcall(GetSpellBookItemInfo, i, BOOKTYPE_SPELL)
                        if ok then sType, sId = t, id end
                    end

                    local name, subName = nil, nil
                    if GetSpellBookItemName then
                        local ok, n, sub = pcall(GetSpellBookItemName, i, BOOKTYPE_SPELL)
                        if ok then name, subName = n, sub end
                    end
                    if not name and GetSpellName then
                        local ok, n, sub = pcall(GetSpellName, i, BOOKTYPE_SPELL)
                        if ok then name, subName = n, sub end
                    end

                    local spellInfoName, _, icon, cost, isFunnel, powerType, castTimeMs = GetSpellInfo(i, BOOKTYPE_SPELL)
                    name = name or spellInfoName

                    if name and not IsIgnoredSpell(name) then
                        local isPassive = false
                        if sType == "FUTURESPELL" or sType == "FLYOUT" then
                            isPassive = true
                        elseif subName and string.lower(subName) == "passive" then
                            isPassive = true
                        elseif sId and IsPassiveSpell then
                            local ok, res = pcall(IsPassiveSpell, sId)
                            if ok and (res == true or res == 1) then
                                isPassive = true
                            end
                        end

                        if not isPassive and (sType == "SPELL" or not sType) then
                            local candidates = {}
                            if not FC._registeredSpellNames[name] then
                                table.insert(candidates, name)
                            end
                            -- Only register ranked variant if specifically Flamestrike for double-stacking
                            if name == "Flamestrike" and subName and subName ~= "" and string.find(subName, "Rank 8") then
                                local rankedName = "Flamestrike (Rank 8)"
                                if not FC._registeredSpellNames[rankedName] then
                                    table.insert(candidates, rankedName)
                                end
                            end

                            for _, regName in ipairs(candidates) do
                                local castTimeSec = (castTimeMs and castTimeMs > 0) and (castTimeMs / 1000) or 0
                                local override = FC.spellbookOverrides[regName]
                                local opts = override or ClassifySpell(regName, castTimeSec, cost, powerType)

                                opts.castTime = castTimeSec
                                opts.powerCost = cost or 0
                                opts.powerType = powerType or 0
                                opts.autoDiscovered = true
                                opts.isSynastriaPerk = false

                                if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[regName] then
                                    local userOv = FC.db.spellOverrides[regName]
                                    if userOv.priority then opts.priority = userOv.priority end
                                    if userOv.role then opts.role = userOv.role end
                                    if userOv.enabled ~= nil then opts.enabled = userOv.enabled end
                                end

                                FC:RegisterSpellActionByName(regName, icon, opts)
                                discovered = discovered + 1
                            end
                        end
                    end
                end
            end
        end
    end

    -- 1b. Scan Pet Spellbook Slots (Hunter, Warlock, Unholy DK, Frost Mage Water Elemental)
    if HasPetSpells and HasPetSpells() then
        local numPetSpells = HasPetSpells()
        for i = 1, (numPetSpells or 0) do
            local name, subName = nil, nil
            if GetSpellBookItemName then
                local ok, n, sub = pcall(GetSpellBookItemName, i, "pet")
                if ok then name, subName = n, sub end
            end
            if not name and GetSpellName then
                local ok, n, sub = pcall(GetSpellName, i, "pet")
                if ok then name, subName = n, sub end
            end
            local spellInfoName, _, icon, cost, isFunnel, powerType, castTimeMs = GetSpellInfo(i, "pet")
            name = name or spellInfoName

            if name and not IsIgnoredSpell(name) and not FC._registeredSpellNames[name] then
                local castTimeSec = (castTimeMs and castTimeMs > 0) and (castTimeMs / 1000) or 0
                local opts = ClassifySpell(name, castTimeSec, cost, powerType)
                opts.castTime = castTimeSec
                opts.powerCost = cost or 0
                opts.powerType = powerType or 0
                opts.autoDiscovered = true
                opts.isPetAbility = true

                -- Pet specific role overrides
                if name == "Spell Lock" or name == "Gnaw" then
                    opts.role = "interrupt"
                    opts.priority = 95
                elseif name == "Freeze" then
                    opts.role = "aoe"
                    opts.priority = 85
                elseif name == "Sacrifice" or name == "Huddle" then
                    opts.role = "defensive"
                    opts.priority = 90
                elseif name == "Kill Command" then
                    opts.role = "nuke"
                    opts.priority = 80
                end

                FC:RegisterSpellActionByName(name, icon, opts)
                discovered = discovered + 1
            end
        end
    end

    -- 2. Class Catalog Auto-Discovery (Ensures core class spells register cleanly)
    local playerClass = FC.playerClass or "MAGE"
    local catalogList = { ROTATIONAL_SPELLS, DEFENSIVE_SPELLS, MAJOR_COOLDOWNS, INTERRUPT_SPELLS, DISPEL_SPELLS }

    for _, db in ipairs(catalogList) do
        for sName, sDef in pairs(db) do
            if not FC._registeredSpellNames[sName] and not IsIgnoredSpell(sName) then
                if not sDef.class or sDef.class == playerClass then
                    local query = sDef.spellId or string.match(sName, "^(.-)%s*%(") or sName
                    local sInfoName, _, icon, cost, _, powerType, castTimeMs = GetSpellInfo(query)
                    if sInfoName then
                        local castTimeSec = (castTimeMs and castTimeMs > 0) and (castTimeMs / 1000) or (sDef.castTime or 0)
                        local opts = ClassifySpell(sName, castTimeSec, cost, powerType)
                        opts.castTime = castTimeSec
                        opts.powerCost = cost or 0
                        opts.powerType = powerType or 0
                        opts.autoDiscovered = true
                        opts.isSynastriaPerk = false

                        if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[sName] then
                            local userOv = FC.db.spellOverrides[sName]
                            if userOv.priority then opts.priority = userOv.priority end
                            if userOv.role then opts.role = userOv.role end
                            if userOv.enabled ~= nil then opts.enabled = userOv.enabled end
                        end

                        FC:RegisterSpellActionByName(sName, icon, opts)
                        discovered = discovered + 1
                    end
                end
            end
        end
    end

    -- 3. Synastria Custom Active Perks (Spell IDs >= 80000)
    if _G.PerkMgrPerks and type(_G.PerkMgrPerks) == "table" then
        for perkId, perk in pairs(_G.PerkMgrPerks) do
            if type(perk) == "table" and perk.name and not FC._registeredSpellNames[perk.name] then
                local sid = perk.spellId or perkId
                if sid and sid >= 80000 and not IsIgnoredSpell(perk.name) then
                    local name, _, icon, cost, _, powerType, castTimeMs = GetSpellInfo(sid)
                    if name and not FC._registeredSpellNames[name] then
                        local castTimeSec = (castTimeMs and castTimeMs > 0) and (castTimeMs / 1000) or 0
                        local opts = ClassifySpell(name, castTimeSec, cost, powerType)
                        opts.castTime = castTimeSec
                        opts.autoDiscovered = true
                        opts.isSynastriaPerk = true

                        if FC.db and FC.db.spellOverrides and FC.db.spellOverrides[name] then
                            local userOv = FC.db.spellOverrides[name]
                            if userOv.priority then opts.priority = userOv.priority end
                            if userOv.role then opts.role = userOv.role end
                            if userOv.enabled ~= nil then opts.enabled = userOv.enabled end
                        end

                        FC:RegisterSpellActionByName(name, icon, opts)
                        discovered = discovered + 1
                    end
                end
            end
        end
    end

    -- Always guarantee fallback actions exist
    if FC._registeredSpellNames and not FC._registeredSpellNames["Idle"] then
        FC:RegisterAction({
            name = "Idle",
            priority = 0,
            role = "idle",
            icon = "Interface\\Icons\\Spell_Holy_Restoration",
            conditions = function(state)
                return state.phase == "idle" or (not state.target or not state.target.exists)
            end,
            score = function() return 0 end
        })
        FC._registeredSpellNames["Idle"] = true
    end

    if FC._registeredSpellNames and not FC._registeredSpellNames["Fallback"] then
        FC:RegisterAction({
            name = "Fallback",
            priority = -999,
            role = "fallback",
            icon = "Interface\\Icons\\INV_Misc_QuestionMark",
            conditions = function() return true end,
            score = function() return -10000 end
        })
        FC._registeredSpellNames["Fallback"] = true
    end

    if FC.debug then
        FC:Debug("ScanSpellbook: discovered & registered " .. discovered .. " spell actions.")
    end
end

function FC:RescanSpellbook()
    self:ScanSpellbook(true)
    if self.ScanGlyphs then self:ScanGlyphs() end
    if self.ScanItems then self:ScanItems() end
    if self.RefreshExtState then self:RefreshExtState() end
    FC:Print("Spellbook, glyphs, items, and Synastria perks rescanned.")
end