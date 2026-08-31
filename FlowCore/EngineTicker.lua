FlowCore = FlowCore or {}
local FC = FlowCore

local frame = CreateFrame("Frame")
local elapsed = 0
local TICK_RATE = 0.05 -- 20 Hz update loop

frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed < TICK_RATE then return end
    elapsed = 0

    if not FC.booted then return end

    -- Keep vitals, buffs, debuffs, DTPS fresh
    if FC.UpdateState then
        FC:UpdateState()
    end

    -- Update combat intelligence & pressure
    if FC.UpdateIntelligence then
        FC:UpdateIntelligence()
    end

    -- Nudge engine dirty so cooldown/GCD progression triggers recalculations
    if FC.MarkEngineDirty then
        FC:MarkEngineDirty()
    end

    if FC.ShouldRunEngine and FC:ShouldRunEngine() then
        FC:RunEngine()
    end
end)
