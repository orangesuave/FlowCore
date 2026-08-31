FlowCore = FlowCore or {}
local FC = FlowCore

FC.bossTimers = FC.bossTimers or {}
FC.activeBossEncounter = nil
FC.encounterStartTime = 0
FC.currentInstanceSpeed = 1.0
FC.isSpeedupPerkActive = false
FC.speedBuffStacks = 0

-- =====================================================================
-- SYNASTRIA "DUNGEON EVENT SPEEDUP" PERK & SPEED BUFF DETECTOR
-- =====================================================================
function FC:GetDungeonSpeedMultiplier()
    local isPerkActive = false
    local perkId = 476 -- Standard Synastria Dungeon Event Speedup / Teleportation / Utility ID

    -- 1. Check Native Synastria Perk API
    if type(GetPerkActive) == "function" then
        -- Check by name or perk list
        if _G.PerkMgrPerks and type(_G.PerkMgrPerks) == "table" then
            for id, perk in pairs(_G.PerkMgrPerks) do
                if type(perk) == "table" and perk.name then
                    if string.find(perk.name, "Dungeon Event Speedup", 1, true) or string.find(perk.name, "Speedup", 1, true) then
                        local ok, act = pcall(GetPerkActive, tonumber(id) or 0)
                        if ok and (act == true or act == 1) then
                            isPerkActive = true
                            perkId = tonumber(id)
                            break
                        end
                    end
                end
            end
        end
    end

    -- 2. Check FC.extState active perks cache
    if not isPerkActive and self.extState and self.extState.activePerks then
        for id, p in pairs(self.extState.activePerks) do
            if string.find(p.name or "", "Dungeon Event Speedup", 1, true) or string.find(p.name or "", "Speedup", 1, true) then
                isPerkActive = true
                break
            end
        end
    end

    -- 3. Check SynastriaCoreLib or direct global flags
    if not isPerkActive and _G.SynastriaDungeonSpeedActive == true then
        isPerkActive = true
    end

    self.isSpeedupPerkActive = isPerkActive

    -- If Perk is NOT active, Speed Buff does NOT apply (1.0x baseline)
    if not isPerkActive then
        self.currentInstanceSpeed = 1.0
        self.speedBuffStacks = 0
        return 1.0, false, 0
    end

    -- 4. When Perk IS active, scan instance Speed Buff aura and stacks
    local speedStacks = 1
    local speedMult = 1.5 -- Baseline 1.5x speed with active perk

    for i = 1, 40 do
        local name, rank, icon, count = UnitBuff("player", i)
        if not name then break end
        if string.find(name, "Speed", 1, true) or string.find(name, "Swiftness", 1, true) or string.find(name, "Chronos", 1, true) or string.find(name, "Temporal", 1, true) or string.find(name, "Haste", 1, true) or string.find(name, "Fast", 1, true) then
            local c = (count and count > 0) and count or 1
            speedStacks = math.max(speedStacks, c)
            -- Each speed stack grants +50% speed increase (1 stack = 1.5x, 2 stacks = 2.0x, 3 stacks = 2.5x, 4 stacks = 3.0x)
            speedMult = 1.0 + (speedStacks * 0.50)
            break
        end
    end

    self.speedBuffStacks = speedStacks
    self.currentInstanceSpeed = speedMult
    return speedMult, true, speedStacks
end

-- =====================================================================
-- COMPREHENSIVE 3.3.5a / CHROMIECRAFT ENCOUNTER DATABASE
-- Covers Classic, Burning Crusade, and Wrath of the Lich King
-- =====================================================================
local ENCOUNTERS = {
    -- =================================================================
    -- WRATH OF THE LICH KING (WOTLK) - RAIDS
    -- =================================================================
    -- Icecrown Citadel (ICC)
    ["Lord Marrowgar"] = {
        name = "Lord Marrowgar (ICC)",
        recurring = {
            { name = "Bone Spike Graveyard", interval = 18, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Ability_Creature_Spiked_01" },
            { name = "Bone Storm", interval = 90, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_ScourgePresence" }
        }
    },
    ["Lady Deathwhisper"] = {
        name = "Lady Deathwhisper (ICC)",
        recurring = {
            { name = "Cultist Wave Spawns", interval = 60, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_RaiseDead" },
            { name = "Death and Decay", interval = 22, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_DeathAndDecay" },
            { name = "Dominate Mind (MC)", interval = 40, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate" }
        }
    },
    ["Deathbringer Saurfang"] = {
        name = "Deathbringer Saurfang (ICC)",
        recurring = {
            { name = "Blood Beasts Spawn", interval = 40, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_BloodBoil" },
            { name = "Rune of Blood (Tank Swap)", interval = 20, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_LifeDrain" }
        }
    },
    ["Festergut"] = {
        name = "Festergut (ICC)",
        recurring = {
            { name = "Gas Spore (Inoculate)", interval = 40, warning = 3.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CreepingPlague" },
            { name = "Vile Gas (Ranged Spread)", interval = 30, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_CorrosiveBreath" },
            { name = "Pungent Blight (Wipe Mech)", interval = 120, warning = 5.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion" }
        }
    },
    ["Rotface"] = {
        name = "Rotface (ICC)",
        recurring = {
            { name = "Slime Spray (Cone)", interval = 20, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CallofBone" },
            { name = "Mutated Infection", interval = 14, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows" }
        }
    },
    ["Professor Putricide"] = {
        name = "Professor Putricide (ICC)",
        recurring = {
            { name = "Unstable Experiment (Ooze)", interval = 38, warning = 3.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges" },
            { name = "Malleable Goo (Bounce)", interval = 25, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
            { name = "Choking Gas Bombs", interval = 35, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CreepingPlague" }
        }
    },
    ["Blood Prince Council"] = {
        name = "Blood Prince Council (ICC)",
        recurring = {
            { name = "Invocation Switch", interval = 45, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AntiShadow" },
            { name = "Shadow Resonance", interval = 15, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_ShadowPower" }
        }
    },
    ["Blood-Queen Lana'thel"] = {
        name = "Blood-Queen Lana'thel (ICC)",
        recurring = {
            { name = "Vampiric Bite Timer", interval = 60, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Ability_Gouge" },
            { name = "Swarming Shadows (Fire)", interval = 30, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_Haunting" },
            { name = "Air Phase (Blood Spray)", interval = 125, warning = 5.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_BloodBoil" }
        }
    },
    ["Sindragosa"] = {
        name = "Sindragosa (ICC)",
        recurring = {
            { name = "Blistering Cold (Run Out!)", interval = 35, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Frost_Glacier" },
            { name = "Air Phase (Tombs & Bombs)", interval = 110, warning = 5.0, lethal = true, icon = "Interface\\Icons\\Spell_Frost_FrostWard" }
        }
    },
    ["The Lich King"] = {
        name = "The Lich King (ICC 25H Final)",
        phases = {
            [1] = { name = "Phase 1: The Scourge Army (100% - 70% HP)", threshold = 70 },
            [2] = { name = "Intermission 1: Remorseless Winter (60s)", threshold = 70 },
            [3] = { name = "Phase 2: Val'kyr & Defile (70% - 40% HP)", threshold = 40 },
            [4] = { name = "Intermission 2: Remorseless Winter (60s)", threshold = 40 },
            [5] = { name = "Phase 3: Vile Spirits & Frostmourne (40% - 10% HP)", threshold = 10 },
            [6] = { name = "Phase 4: Fury of Frostmourne & Execute (10% - 0% HP)", threshold = 0 }
        },
        recurring = {
            -- Phase 1
            { name = "Infest (P1/P2 Raid Pulse)", interval = 22, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_Haunting" },
            { name = "Shadow Trap (P1 25H Knockoff)", interval = 15, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows" },
            { name = "Necrotic Plague (P1 Dispel Jump)", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CallofBone" },
            { name = "Shambling Horror (P1 Add Enrage)", interval = 60, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_MonsterGrotesque" },

            -- Intermission 1 & 2
            { name = "Remorseless Winter (Intermission)", interval = 60, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Frost_Glacier" },
            { name = "Raging Spirit (Soul Shriek Silence)", interval = 20, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_SoulLeech_2" },
            { name = "Ice Sphere (Ranged Switch)", interval = 7, warning = 1.5, lethal = true, icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" },

            -- Phase 2
            { name = "Defile (P2/P3 MOVE!)", interval = 32, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_DeathAndDecay" },
            { name = "Val'kyr Shadowguard (P2 3x Grab)", interval = 45, warning = 3.5, lethal = true, icon = "Interface\\Icons\\Spell_Magic_LesserInvisibilty" },
            { name = "Soul Reaper (P2/P3 Tank Buster)", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Ability_Warrior_DecisiveStrike" },

            -- Phase 3
            { name = "Vile Spirits (P3 AoE Detonation)", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_ShadowPower" },
            { name = "Harvest Souls (P3 25H Frostmourne Chamber)", interval = 60, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_SoulLeech_2" }
        }
    },
    -- Ruby Sanctum
    ["Halion"] = {
        name = "Halion (Ruby Sanctum)",
        recurring = {
            { name = "Fiery Combustion / Consumption", interval = 25, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_SealOfFire" },
            { name = "Meteor Strike (Physical)", interval = 40, warning = 3.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_MeteorStorm" },
            { name = "Twilight Cutter (Beams)", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_Twilight" }
        }
    },
    -- Trial of the Crusader (TotC)
    ["Gormok the Impaler"] = {
        name = "Northrend Beasts (TotC)",
        recurring = {
            { name = "Snobold Vassal Spawn", interval = 40, warning = 2.5, lethal = false, icon = "Interface\\Icons\\Ability_Hunter_Pet_Gorilla" },
            { name = "Impale (Tank Swap)", interval = 10, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Ability_Warrior_PunishingBlow" }
        }
    },
    ["Lord Jaraxxus"] = {
        name = "Lord Jaraxxus (TotC)",
        recurring = {
            { name = "Incinerate Flesh (Heal Target!)", interval = 22, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Burnout" },
            { name = "Nether Portal (Mistress)", interval = 60, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Arcane_PortalIronForge" },
            { name = "Infernal Eruption", interval = 120, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Volcano" }
        }
    },
    ["Anub'arak"] = {
        name = "Anub'arak (TotC Final)",
        recurring = {
            { name = "Freezing Slash", interval = 15, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Frost_FrostNova" },
            { name = "Submerge Phase (Burrow)", interval = 80, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Ability_Hunter_Pet_Scorpid" },
            { name = "Shadow Strike (Add Cast)", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AntiShadow" }
        }
    },
    -- Ulduar
    ["Ignis the Furnace Master"] = {
        name = "Ignis (Ulduar)",
        recurring = {
            { name = "Slag Pot (Target Grab)", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
            { name = "Flame Jets (Cast Interrupt)", interval = 25, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Burnout" },
            { name = "Iron Construct Spawn", interval = 40, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Fire_ElementalDevastation" }
        }
    },
    ["XT-002 Deconstructor"] = {
        name = "XT-002 (Ulduar)",
        recurring = {
            { name = "Light / Gravity Bomb", interval = 20, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Holy_SurgeOfLight" },
            { name = "Tympanic Tantrum (Raid AoE)", interval = 60, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Nature_Earthquake" }
        }
    },
    ["General Vezax"] = {
        name = "General Vezax (Ulduar)",
        recurring = {
            { name = "Shadow Crash (Green Pool)", interval = 10, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" },
            { name = "Searing Flames (INTERRUPT!)", interval = 15, warning = 1.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fire" },
            { name = "Surge of Darkness", interval = 60, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows" }
        }
    },
    ["Yogg-Saron"] = {
        name = "Yogg-Saron (Ulduar Final)",
        recurring = {
            { name = "Madness Portals Open", interval = 90, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Arcane_PortalIronForge" },
            { name = "Lunatic Gaze (Look Away!)", interval = 12, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_ShadowPact" },
            { name = "Empowering Shadows", interval = 45, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness" }
        }
    },
    ["Algalon the Observer"] = {
        name = "Algalon the Observer (Ulduar)",
        recurring = {
            { name = "Big Bang (Enter Black Hole)", interval = 90, warning = 5.0, lethal = true, icon = "Interface\\Icons\\Spell_Arcane_StarFire" },
            { name = "Cosmic Smash (Falling Star)", interval = 25, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_MeteorStorm" },
            { name = "Phase Punch (Tank Swap)", interval = 15, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Arcane_ArcaneTorrent" }
        }
    },
    -- Obsidian Sanctum & Eye of Eternity & VoA
    ["Sartharion"] = {
        name = "Sartharion (Obsidian Sanctum)",
        drakes = {
            { name = "Tenebron (Adds)", delay = 30, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
            { name = "Shadron (Portal)", delay = 75, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
            { name = "Vesperon (Portal)", delay = 120, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" }
        },
        recurring = {
            { name = "Flame Tsunami", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
            { name = "Twilight Breath", interval = 15, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_Twilight" }
        }
    },
    ["Malygos"] = {
        name = "Malygos (Eye of Eternity)",
        recurring = {
            { name = "Power Spark", interval = 30, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Arcane_PortalIronForge" },
            { name = "Vortex Phase", interval = 60, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Nature_Cyclone" },
            { name = "Surge of Power", interval = 60, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Arcane_ArcaneTorrent" }
        }
    },
    ["Emalon the Storm Watcher"] = {
        name = "Emalon (Vault of Archavon)",
        recurring = {
            { name = "Overcharge (Kill Add)", interval = 45, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Nature_Lightning" },
            { name = "Lightning Nova", interval = 40, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Nature_WispSplode" }
        }
    },
    ["Koralon the Flame Watcher"] = {
        name = "Koralon (Vault of Archavon)",
        recurring = {
            { name = "Meteor Fists", interval = 45, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fireball02" },
            { name = "Burning Cinders", interval = 30, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Fire_FlameBlades" }
        }
    },
    ["Toravon the Ice Watcher"] = {
        name = "Toravon (Vault of Archavon)",
        recurring = {
            { name = "Frozen Orb", interval = 35, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Frost_FrozenOrb" },
            { name = "Whiteout AoE", interval = 38, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Frost_Blizzard" }
        }
    },
    ["Archavon the Stone Watcher"] = {
        name = "Archavon (Vault of Archavon)",
        recurring = {
            { name = "Rock Shards", interval = 15, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Nature_Earthquake" },
            { name = "Choking Cloud", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CreepingPlague" }
        }
    },
    -- Naxxramas (10/25)
    ["Thaddius"] = {
        name = "Thaddius (Naxxramas)",
        recurring = {
            { name = "Polarity Shift", interval = 30, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Nature_Lightning" }
        }
    },
    ["Heigan the Unclean"] = {
        name = "Heigan (Naxxramas)",
        recurring = {
            { name = "Safety Dance Eruption", interval = 10, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CreepingPlague" },
            { name = "Platform Phase", interval = 90, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AntiShadow" }
        }
    },
    ["Sapphiron"] = {
        name = "Sapphiron (Naxxramas)",
        recurring = {
            { name = "Frost Breath / Ice Block", interval = 65, warning = 5.0, lethal = true, icon = "Interface\\Icons\\Spell_Frost_FrostWard" }
        }
    },
    ["Kel'Thuzad"] = {
        name = "Kel'Thuzad (Naxxramas)",
        recurring = {
            { name = "Shadow Fissure (Void Zone)", interval = 15, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_DeathAndDecay" },
            { name = "Frost Blast (Ice Tomb)", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Frost_FrostNova" },
            { name = "Mind Control (Chains)", interval = 60, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate" }
        }
    },
    ["Grobbulus"] = {
        name = "Grobbulus (Naxxramas)",
        recurring = {
            { name = "Mutating Injection", interval = 20, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CallofBone" },
            { name = "Slime Spray", interval = 20, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_CorrosiveBreath" }
        }
    },
    ["Loatheb"] = {
        name = "Loatheb (Naxxramas)",
        recurring = {
            { name = "Inevitable Doom", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_NightOfTheDead" },
            { name = "Spore Spawn (Crit Buff)", interval = 15, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Nature_Regeneration" }
        }
    },

    -- =================================================================
    -- WRATH OF THE LICH KING (WOTLK) - DUNGEONS & RP/WAVE EVENTS
    -- =================================================================
    ["Cyanigosa"] = {
        name = "Violet Hold (WotLK)",
        recurring = {
            { name = "Portal Wave Timer", interval = 90, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Arcane_PortalIronForge" },
            { name = "Blizzard / Mana Destruction", interval = 25, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Frost_Blizzard" }
        }
    },
    ["Brann Bronzebeard"] = {
        name = "Tribunal of the Ages (Halls of Stone RP)",
        recurring = {
            { name = "Tribunal Defense Phase", interval = 75, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Holy_HolyProtection" }
        }
    },
    ["Falric"] = {
        name = "Halls of Reflection (Wave Gauntlet)",
        recurring = {
            { name = "Wave Interval Timer", interval = 45, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Shadow_RaiseDead" },
            { name = "Quivering Strike / Fear", interval = 20, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_PsychicScream" }
        }
    },
    ["Loken"] = {
        name = "Loken (Halls of Lightning)",
        recurring = {
            { name = "Lightning Nova (RUN IN!)", interval = 20, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Nature_WispSplode" }
        }
    },
    ["Forgemaster Garfrost"] = {
        name = "Forgemaster Garfrost (Pit of Saron)",
        recurring = {
            { name = "Throw Saronite (LoS Boulder)", interval = 20, warning = 2.5, lethal = true, icon = "Interface\\Icons\\INV_Stone_04" }
        }
    },
    ["Bronjahm"] = {
        name = "Bronjahm (Forge of Souls)",
        recurring = {
            { name = "Soulstorm (RUN IN!)", interval = 35, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_SoulLeech_2" }
        }
    },

    -- =================================================================
    -- BURNING CRUSADE (TBC) - RAIDS & DUNGEONS
    -- =================================================================
    -- Sunwell Plateau
    ["Brutallus"] = {
        name = "Brutallus (Sunwell)",
        recurring = {
            { name = "Meteor Slash (Stack)", interval = 12, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_MeteorStorm" },
            { name = "Burn (Run Out)", interval = 20, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Burnout" }
        }
    },
    ["Kil'jaeden"] = {
        name = "Kil'jaeden (Sunwell Final)",
        recurring = {
            { name = "Darkness of Thousand Souls", interval = 45, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness" },
            { name = "Shield Orbs Spawn", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_AntiShadow" }
        }
    },
    -- Black Temple
    ["Illidan Stormrage"] = {
        name = "Illidan Stormrage (Black Temple)",
        recurring = {
            { name = "Shear (Active Mitigation)", interval = 10, warning = 1.5, lethal = true, icon = "Interface\\Icons\\Ability_Gouge" },
            { name = "Flame Burst", interval = 20, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fireball02" },
            { name = "Demon Form Phase", interval = 60, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_Shadowform" }
        }
    },
    ["Teron Gorefiend"] = {
        name = "Teron Gorefiend (Black Temple)",
        recurring = {
            { name = "Shadow of Death (Ghost Form)", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_NetherCloak" }
        }
    },
    -- Mount Hyjal & Tempest Keep & SSC & Karazhan
    ["Archimonde"] = {
        name = "Archimonde (Mount Hyjal)",
        recurring = {
            { name = "Air Burst (Use Tears!)", interval = 25, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Nature_Cyclone" },
            { name = "Doomfire (Run Out)", interval = 20, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fire" }
        }
    },
    ["Kael'thas Sunstrider"] = {
        name = "Kael'thas Sunstrider (Tempest Keep)",
        recurring = {
            { name = "Shock Barrier & Pyroblast", interval = 60, warning = 3.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fireball02" },
            { name = "Gravity Lapse (Swim!)", interval = 90, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Nature_Akanar" }
        }
    },
    ["Lady Vashj"] = {
        name = "Lady Vashj (Serpentshrine Cavern)",
        recurring = {
            { name = "Tainted Elemental Core", interval = 50, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Nature_ElementalDevastation" },
            { name = "Sporebat Green Acid", interval = 25, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CorrosiveBreath" }
        }
    },
    ["Shade of Aran"] = {
        name = "Shade of Aran (Karazhan)",
        recurring = {
            { name = "Flame Wreath (DO NOT MOVE!)", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fire" },
            { name = "Blizzard / Arcane Explosion", interval = 35, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Arcane_ArcaneTorrent" }
        }
    },
    ["Prince Malchezaar"] = {
        name = "Prince Malchezaar (Karazhan)",
        recurring = {
            { name = "Enfeeble (1 HP Warning)", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth" },
            { name = "Infernal Landing", interval = 45, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Volcano" }
        }
    },
    ["Aeonus"] = {
        name = "Black Morass (Opening of the Dark Portal)",
        recurring = {
            { name = "Time Stop (Stun)", interval = 25, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Holy_AshesToAshes" },
            { name = "Rift Wave Spawn", interval = 60, warning = 3.0, lethal = false, icon = "Interface\\Icons\\Spell_Arcane_PortalIronForge" }
        }
    },

    -- =================================================================
    -- CLASSIC (VANILLA) - RAIDS & DUNGEONS
    -- =================================================================
    -- Ahn'Qiraj (AQ40)
    ["C'Thun"] = {
        name = "C'Thun (AQ40 Final)",
        recurring = {
            { name = "Dark Glare (Eye Beam Sweep)", interval = 85, warning = 4.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" },
            { name = "Eye Tentacles Spawn", interval = 30, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_CallofBone" }
        }
    },
    ["Twin Emperors"] = {
        name = "Twin Emperors (AQ40)",
        recurring = {
            { name = "Teleport Swap", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Arcane_Blink" },
            { name = "Explode Bug", interval = 12, warning = 1.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_SelfDestruct" }
        }
    },
    -- Blackwing Lair (BWL)
    ["Nefarian"] = {
        name = "Nefarian (BWL)",
        recurring = {
            { name = "Class Call Mechanic", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_Charm" },
            { name = "Shadow Flame (Onyxia Cloak)", interval = 18, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Incinerate" }
        }
    },
    ["Vaelastrasz the Corrupt"] = {
        name = "Vaelastrasz (BWL 3-Min Timer)",
        recurring = {
            { name = "Burning Adrenaline (Explosion)", interval = 15, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows" },
            { name = "Flame Breath", interval = 12, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Fire" }
        }
    },
    -- Molten Core (MC)
    ["Ragnaros"] = {
        name = "Ragnaros (Molten Core)",
        recurring = {
            { name = "Wrath of Ragnaros (Knockback)", interval = 25, warning = 2.0, lethal = false, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
            { name = "Submerge (Sons of Flame)", interval = 180, warning = 5.0, lethal = true, icon = "Interface\\Icons\\Spell_Fire_ElementalDevastation" }
        }
    },
    ["Baron Geddon"] = {
        name = "Baron Geddon (Molten Core)",
        recurring = {
            { name = "Living Bomb (RUN OUT!)", interval = 30, warning = 3.0, lethal = true, icon = "Interface\\Icons\\Spell_Shadow_MindBomb" },
            { name = "Inferno (Pulse AoE)", interval = 35, warning = 2.5, lethal = true, icon = "Interface\\Icons\\Spell_Fire_Incinerate" }
        }
    },
    -- Classic Dungeons (Wave & RP Events)
    ["Baron Rivendare"] = {
        name = "Stratholme (Undead Side)",
        recurring = {
            { name = "Baron 45-Min Event / Cleave", interval = 15, warning = 2.0, lethal = true, icon = "Interface\\Icons\\Ability_Warrior_Cleave" }
        }
    },
    ["Chief Ukorz Sandscalp"] = {
        name = "Zul'Farrak (Pyramid Wave Event)",
        recurring = {
            { name = "Troll Wave Spawn", interval = 45, warning = 2.5, lethal = false, icon = "Interface\\Icons\\Ability_Hunter_Pet_Raptor" }
        }
    }
}

-- =====================================================================
-- ENCOUNTER TRIGGER & SPEED-SCALED TIMER MANAGEMENT
-- =====================================================================
function FC:CheckBossEncounterTrigger()
    local tName = UnitName("target")
    if not tName then return end

    for bName, data in pairs(ENCOUNTERS) do
        if string.find(tName, bName, 1, true) or (data.name and string.find(tName, data.name, 1, true)) then
            if FC.activeBossEncounter ~= bName then
                FC:StartBossEncounter(bName)
            end
            return
        end
    end
end

function FC:StartBossEncounter(bName)
    local data = ENCOUNTERS[bName]
    if not data then return end

    local now = GetTime()
    local speedMult, perkActive, stacks = FC:GetDungeonSpeedMultiplier()

    FC.activeBossEncounter = bName
    FC.encounterStartTime = now
    FC.bossTimers = {}

    -- Initialize one-time drake / phase triggers
    if data.drakes then
        for _, d in ipairs(data.drakes) do
            local effectiveDelay = d.delay / speedMult
            table.insert(FC.bossTimers, {
                name = d.name,
                expiresAt = now + effectiveDelay,
                totalDur = effectiveDelay,
                icon = d.icon,
                lethal = false,
                isRecurring = false
            })
        end
    end

    -- Initialize recurring timers scaled by speed multiplier
    if data.recurring then
        for _, r in ipairs(data.recurring) do
            local effectiveInterval = r.interval / speedMult
            local effectiveWarning = r.warning or 2.5
            table.insert(FC.bossTimers, {
                name = r.name,
                expiresAt = now + effectiveInterval,
                totalDur = effectiveInterval,
                interval = effectiveInterval,
                baseInterval = r.interval,
                warning = effectiveWarning,
                icon = r.icon,
                lethal = r.lethal,
                isRecurring = true
            })
        end
    end

    if perkActive and speedMult > 1.0 then
        FC:Print(string.format("|cff00ccff[Boss Timers Active]|r |cffffd700%s|r |cff00ff00⚡ Speed: %.1fx (%d stacks, Perk Active)|r", data.name, speedMult, stacks))
    else
        FC:Print(string.format("|cff00ccff[Boss Timers Active]|r |cffffd700%s|r (1.0x baseline speed)", data.name))
    end
end

function FC:StopBossEncounter()
    FC.activeBossEncounter = nil
    FC.bossTimers = {}
end

function FC:UpdateBossTimers()
    local now = GetTime()
    if not FC.activeBossEncounter then return end

    -- Check if combat ended or target dead
    if not UnitAffectingCombat("player") and not UnitExists("boss1") and not UnitExists("target") then
        FC:StopBossEncounter()
        return
    end

    local speedMult = FC:GetDungeonSpeedMultiplier()

    for _, timer in ipairs(FC.bossTimers) do
        if now >= timer.expiresAt then
            if timer.isRecurring and timer.baseInterval then
                local nextInterval = timer.baseInterval / speedMult
                timer.expiresAt = now + nextInterval
                timer.totalDur = nextInterval
            end
        end
    end
end

function FC:GetActiveBossTimers()
    self:UpdateBossTimers()
    local now = GetTime()
    local list = {}
    for _, t in ipairs(self.bossTimers or {}) do
        local rem = t.expiresAt - now
        if rem > 0 and rem <= 240 then
            table.insert(list, {
                name = t.name,
                remaining = rem,
                total = t.totalDur,
                icon = t.icon,
                lethal = t.lethal,
                warning = t.warning or 2.5
            })
        end
    end
    table.sort(list, function(a, b) return a.remaining < b.remaining end)
    return list
end

function FC:GetImpendingBossMechanic()
    local timers = self:GetActiveBossTimers()
    if #timers == 0 then return nil end
    local first = timers[1]
    if first and first.remaining <= (first.warning or 3.0) and first.lethal then
        return first
    end
    return nil
end
