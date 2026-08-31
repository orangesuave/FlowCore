FlowCore = FlowCore or {}
local FC = FlowCore

FC.combat = FC.combat or {}
FC.combat.signals = FC.combat.signals or {}
FC.combat.signalHistory = FC.combat.signalHistory or {}

local function PushSignal(signal)
    if not signal then return end

    FC.combat.lastSignal = signal
    FC.combat.signalHistory = FC.combat.signalHistory or {}
    table.insert(FC.combat.signalHistory, signal)

    if #FC.combat.signalHistory > 30 then
        table.remove(FC.combat.signalHistory, 1)
    end

    if FC.verbose then
        local val = signal.value or signal.name or signal.spell or 0
        FC:Verbose("SIGNAL -> " .. tostring(signal.type) .. " | " .. tostring(val))
    end
end

function FC:EmitSwingSignal(data)
    if not data then return end
    PushSignal({
        type = "melee",
        value = tonumber(data.final) or 0,
        crit = data.crit or false,
        source = data.source,
        target = data.target,
        absorbed = tonumber(data.absorbed) or 0
    })
end

function FC:EmitSpellSignal(data)
    if not data then return end
    PushSignal({
        type = "spell",
        spell = data.spell or "unknown",
        value = tonumber(data.final or data.amount) or 0,
        source = data.source,
        target = data.target
    })
end

function FC:EmitProcSignal(name, duration, icon)
    PushSignal({
        type = "proc",
        name = name or "unknown",
        duration = duration or 0,
        icon = icon,
        value = 1
    })
end

function FC:EmitAuraSignal(eventType, spell, destGUID)
    PushSignal({
        type = "aura",
        event = eventType,
        spell = spell,
        target = destGUID
    })
end
