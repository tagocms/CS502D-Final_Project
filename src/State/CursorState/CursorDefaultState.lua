CursorDefaultState = Class {__includes = BaseState}

function CursorDefaultState:init(def)
    love.mouse.setCursor(love.mouse.newCursor(def.imageData))
end

function CursorDefaultState.getName()
    return 'CursorDefaultState'
end