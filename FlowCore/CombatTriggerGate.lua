FlowCore = FlowCore or {}
local FC = FlowCore

FC._engineDirty = FC._engineDirty or false
FC._lastEngineRun = FC._lastEngineRun or 0
FC._engineThrottle = 0.05 -- 50ms minimum spacing

function FC:MarkEngineDirty()
    self._engineDirty = true
end

function FC:ShouldRunEngine()
    if not self._engineDirty then
        return false
    end

    local now = GetTime()
    if (now - (self._lastEngineRun or 0)) < self._engineThrottle then
        return false
    end

    return true
end

function FC:RunEngine()
    if not self.GetBestAction then return end

    local action, score = self:GetBestAction(self.state)

    self.lastActionName = action and action.name or "none"
    self.lastActionScore = score

    -- Rebuild the 10-second predictive timeline
    if self.BuildTimeline then
        local duration = (self.db and self.db.timelineDuration) or 10
        self:BuildTimeline(duration)
    end

    self._lastEngineRun = GetTime()
    self._engineDirty = false
end
