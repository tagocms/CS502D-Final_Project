CursorMoveState = Class {__includes = BaseState}

function CursorMoveState:init(def)
    love.mouse.setCursor(love.mouse.newCursor(def.imageData))
    self.effectPosition = def.position
    self.effectSize = def.size
end

function CursorMoveState:update(dt, params)
    self.effectPosition = params.position
    self.effectSize = params.size
end

function CursorMoveState:draw()
    local position, size = self.effectPosition, self.effectSize
    love.graphics.setColor(0, 1, 0, 0.2)
    love.graphics.rectangle('fill', position.x, position.y, size.width, size.height)
    love.graphics.setColor(1, 1, 1, 1)
end

function CursorMoveState.getName()
    return 'CursorMoveState'
end