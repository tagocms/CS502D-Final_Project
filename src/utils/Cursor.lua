---@class Cursor
Cursor = Class{}

function Cursor:init(def)
    ---@type StateMachine
    self.stateMachine = StateMachine {
        availableStates = {
            [CursorDefaultState.getName()] = CursorDefaultState,
            [CursorMoveState.getName()] = CursorMoveState,
            [CursorInvalidState.getName()] = CursorInvalidState
        },
        initialStateName = 'default',
        initialStateParams = {
            imageData = CURSOR_IMAGE_DATA['default']
        }
    }
end

function Cursor:update(dt, params)
    self.stateMachine:update(dt, params)
end

function Cursor:drawEffect()
    self.stateMachine:draw()
end

function Cursor:changeState(stateName, newStateParams)
    local currentState = self.stateMachine.currentState
    if currentState and currentState.getName() == stateName then return end

    ---@type string
    local imageName

    if stateName == CursorMoveState.getName() then
        imageName = 'move'
    elseif stateName == CursorInvalidState.getName() then
        imageName = 'action-blocked'
    else
        imageName = 'default'
    end

    local newStateParams = push_with_keyvalue(newStateParams, {imageData = CURSOR_IMAGE_DATA[imageName]})

    self.stateMachine:enterNewState(stateName, newStateParams)
end

function Cursor:getStateName()
    return self.stateMachine.currentState and self.stateMachine.currentState.getName() or ''
end