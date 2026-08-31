FlowCore = FlowCore or {}
local FC = FlowCore

FC.combat = FC.combat or {
    lastEvents = {},
    lastSwing = nil,
    lastSpell = nil,
    procs = {},
    damageTakenHistory = {},
    damageDoneHistory = {},
    signals = {},
    signalHistory = {},
    filterPlayerOnly = false
}
