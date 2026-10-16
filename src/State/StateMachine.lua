StateMachine = Class{}

function StateMachine:init(def)
    self._availableStates = def.availableStates or {}
    self:enterNewState(def.initialStateName, def.initialStateParams)
end

function StateMachine:exit()
    self.currentState:exit()
end

function StateMachine:enterNewState(newStateName, newStateParams)
    if not self._availableStates[newStateName] then return end

    if self.currentState then
        self.currentState:exit()
    end
    self.currentState = self._availableStates[newStateName](newStateParams)
end

function StateMachine:update(dt)
    if not self.currentState then return end

    self.currentState:update(dt)
end

function StateMachine:draw()
    if not self.currentState then return end

    self.currentState:draw()
end

function StateMachine.getName()
    return 'StateMachine'
end