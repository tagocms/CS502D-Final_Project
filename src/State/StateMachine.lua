StateMachine = Class{}

function StateMachine:init(def)
    self._availableStates = def.availableStates or {}
    self.callbacks = def.callbacks or {}
    self:enterNewState(def.initialStateName, def.initialStateParams)
end

function StateMachine:exit()
    if not self.currentState then return end
    
    self.currentState:exit()
end

function StateMachine:enterNewState(newStateName, newStateParams)
    if not self._availableStates[newStateName] then return end

    if self.currentState then
        self.currentState:exit()
    end
    local callbacks = {
        enterNewState = function (newName, newParams)
            self:enterNewState(newName, newParams)
        end
    }
    push_with_keyvalue(callbacks, {stateMachineCallbacks = self.callbacks})
    local paramsCopy = push_with_keyvalue({}, newStateParams or {})
    self.currentState = self._availableStates[newStateName](push_with_keyvalue(paramsCopy, {callbacks = callbacks}))
end

function StateMachine:update(dt, params)
    if not self.currentState then return end

    self.currentState:update(dt, params)
end

function StateMachine:draw()
    if not self.currentState then return end

    self.currentState:draw()
end

function StateMachine.getName()
    return 'StateMachine'
end