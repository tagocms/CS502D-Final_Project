CursorInvalidState = Class {__includes = CursorMoveState}

function CursorInvalidState:draw()
    local position, size = self.effectPosition, self.effectSize
    love.graphics.setColor(1, 0, 0, 0.2)
    love.graphics.rectangle('fill', position.x, position.y, size.width, size.height)
    love.graphics.setColor(1, 1, 1, 1)
end

function CursorInvalidState.getName()
    return 'CursorInvalidState'
end