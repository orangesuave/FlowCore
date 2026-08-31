FlowCore = FlowCore or {}
local FC = FlowCore

-- Addon Metadata
FC.name = "FlowCore"
FC.version = "1.3.0"

-- Debug & Log Levels
FC.debug = true
FC.verbose = false

-- Database Defaults
FC.defaultSettings = {
    locked = false,
    scale = 1.0,
    showUI = true,
    timelineDuration = 10,
    point = "CENTER",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = -200,
    minHealthEmergency = 35,
    maxTimelineSlots = 8,
    allowCombatBuffs = false,
    autoTrinkets = true,
    autoDefensives = true,
    autoInterrupts = true,
    autoDispels = true,
    autoAoE = true,
    enableSynastriaPerks = true,
    enableQueueIndicator = true,
    customQueueWindowMs = 250,
    queueAudio = false,
    playerRole = "DPS",
    combatApproach = "Balanced",
    showMinimapButton = true,
    minimapPos = 220,
    spellOverrides = {}
}

-- State tables
FC.state = FC.state or {}
FC.state.player = FC.state.player or { buffs = {}, debuffs = {}, stats = {}, powerType = 0, comboPoints = 0, setBonuses = {} }
FC.state.target = FC.state.target or { exists = false, hostile = false, debuffs = {}, buffs = {}, resistances = {} }
FC.state.enemyCount = FC.state.enemyCount or 1
FC.state.activeEnemies = FC.state.activeEnemies or {}

FC.actions = FC.actions or {}
FC.talents = FC.talents or { known = {}, critBonus = 0, hasteBonus = 0 }
FC.items = FC.items or {}
FC.knownCooldowns = FC.knownCooldowns or {}

-- Detect Player Class and Base GCD
local _, playerClass = UnitClass("player")
FC.playerClass = playerClass or "WARRIOR"

-- Base GCD is 1.0s for Rogues and Cat Druids; 1.5s for everyone else
if FC.playerClass == "ROGUE" then
    FC.baseGCD = 1.0
else
    FC.baseGCD = 1.5
end
FC.GCD = FC.baseGCD

-- Color Constants
FC.COLORS = {
    TITLE     = "|cff00ccff",
    SUCCESS   = "|cff55ff55",
    WARNING   = "|cffffaa00",
    DANGER    = "|cffff3333",
    INFO      = "|cff88bbff",
    MUTED     = "|cff888888",
    DAMAGE    = "|cffff4444",
    HEAL      = "|cff33ff77",
    DEFENSIVE = "|cff3399ff",
    BUFF      = "|cffffd700",
    DOT       = "|cffaa55ff",
    INTERRUPT = "|cffff0055",
    DISPEL    = "|cff00ffee",
    PERK      = "|cffff88ff",
    RESET     = "|r"
}

function FC:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(FC.COLORS.TITLE .. "FlowCore|r: " .. tostring(msg))
end

function FC:Debug(msg)
    if self.debug then
        DEFAULT_CHAT_FRAME:AddMessage(FC.COLORS.MUTED .. "[FC Debug]|r " .. tostring(msg))
    end
end

function FC:Verbose(msg)
    if self.verbose then
        DEFAULT_CHAT_FRAME:AddMessage(FC.COLORS.INFO .. "[FC Verbose]|r " .. tostring(msg))
    end
end

-- Initialize Settings from SavedVariables
function FC:InitDB()
    FlowCoreDB = FlowCoreDB or {}
    for k, v in pairs(self.defaultSettings) do
        if FlowCoreDB[k] == nil then
            FlowCoreDB[k] = v
        end
    end
    FlowCoreDB.spellOverrides = FlowCoreDB.spellOverrides or {}
    self.db = FlowCoreDB
end

-- =====================================================
-- MANUAL STATUS CHECK (/fc check)
-- =====================================================
function FC:CheckEngine()
    local action, score = self:GetBestAction(self.state)
    local qCount = (self.timeline and self.timeline.queue) and #self.timeline.queue or 0

    self:Print("=== ENGINE DIAGNOSTIC ===")
    self:Print("Booted: " .. tostring(self.booted))
    self:Print("Class: " .. tostring(self.playerClass) .. " | Base GCD: " .. string.format("%.1fs", self.baseGCD))
    self:Print("Phase: " .. tostring(self.state.phase) .. " | In Combat: " .. tostring(self.state.inCombat))
    self:Print("Enemies: " .. tostring(self.state.enemyCount or 1) .. " active combatants")
    self:Print("Player HP: " .. string.format("%.1f%%", self.state.player.healthPct or 100) .. " | Danger Level: " .. string.format("%.0f", self.state.dangerLevel or 0))
    if self.state.target.exists then
        self:Print("Target: " .. tostring(self.state.target.creatureType) .. " (" .. tostring(self.state.target.classification) .. ") | HP: " .. string.format("%.1f%%", self.state.target.healthPct or 0))
        if self.state.target.isCasting then
            self:Print("Target Casting: " .. tostring(self.state.target.castSpellName) .. " (" .. string.format("%.1fs", self.state.target.castRemaining or 0) .. " remaining | Interruptible: " .. tostring(self.state.target.interruptible) .. ")")
        end
    end
    self:Print("Best Action: " .. (action and action.name or "none") .. " (Score: " .. string.format("%.1f", score or 0) .. ")")
    self:Print("Timeline Queue: " .. qCount .. " planned actions (Next 10s)")
    self:Print("Registered Actions: " .. tostring(#(self.actions or {})))
end
