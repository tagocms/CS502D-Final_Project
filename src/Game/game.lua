local windowWidth, windowHeight = 1080, 720

Game = Class{}

function Game:init()
    love.window.setMode(windowWidth, windowHeight, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })
    love.window.setTitle("Age of Bandits")
    -- TODO: Not the permanent icon
    love.window.setIcon(love.image.newImageData('sprites/cursor/mouse_icon1-SwordPointer.png'))
    Game.setCursor(CURSOR_IMAGE_DATA['default'])

    self:clearKeyDownAndPressed()
    self:clearMouseDownPressedAndReleased()

    self.stateMachine = StateMachine {
        availableStates = {
            [PlayState.getName()] = PlayState
        },
        initialStateName = PlayState.getName(),
        initialStateParams = {gameMapPath = 'src/maps/CastleOutside.lua'}
    }
end

function Game:update(dt)
    Timer.update(dt)
    
    self:listenToKeyDown()
    self:handleKeyPressed()
    self:listenToMouseButtonsDown()
    self.stateMachine:update(
        dt,
        {
            keysDown = self.keysDown,
            keysPressed = self.keysPressed,
            mouseButtonsDown = self.mouseButtonsDown,
            mouseButtonsPressed = self.mouseButtonsPressed,
            mouseButtonsReleased = self.mouseButtonsReleased,
            realMousePosition = self:getRealMousePosition(),
            isMouseGrabbed = self:isMouseGrabbed()
        }
    )
    self:clearKeyDownAndPressed()
    self:clearMouseDownPressedAndReleased()
end

function Game:draw()
    self.stateMachine:draw()
end

-- Input handling
function Game:keypressed(key)
    self:setKeyPressed(key)
end

function Game:setKeyDown(key)
    self.keysDown:setKeyInteracted(key)
end

function Game:setKeyPressed(key)
    self.keysPressed:setKeyInteracted(key)
end

function Game:isDown(key)
    return self.keysDown:isInteracted(key)
end

function Game:wasPressed(key)
    return self.keysPressed:isInteracted(key)
end

function Game:clearKeyPressed()
    self.keysPressed = KeysInteracted()
end

function Game:clearKeyDown()
    self.keysDown = KeysInteracted()
end

function Game:listenToKeyDown()
    local keys = {
        ['up'] = 'up',
        ['w'] = 'up',
        ['down'] = 'down',
        ['s'] = 'down',
        ['left'] = 'left',
        ['a'] = 'left',
        ['right'] = 'right',
        ['d'] = 'right'
    }

    for key, mappedKey in pairs(keys) do
        if love.keyboard.isDown(key) then
            self:setKeyDown(mappedKey)
        end
    end
end

function Game:handleKeyPressed()
    if self:wasPressed('escape') then
		love.event.quit()
	end
end

function Game:clearKeyDownAndPressed()
    self:clearKeyDown()
    self:clearKeyPressed()
end

-- Mouse
function Game:mousepressed(x, y, button)
    self:setMouseButtonPressed(button)
end

function Game:mousereleased(x, y, button)
    self:setMouseButtonReleased(button)
end

function Game:setMouseButtonDown(button)
    self.mouseButtonsDown:setKeyInteracted(button)
end

function Game:setMouseButtonPressed(button)
    self.mouseButtonsPressed:setKeyInteracted(button)
end

function Game:setMouseButtonReleased(button)
    self.mouseButtonsReleased:setKeyInteracted(button)
end

function Game:setMouseGrabbed(mouseGrabbed)
    love.mouse.setGrabbed(mouseGrabbed)
end

function Game:isMouseButtonDown(button)
    return self.mouseButtonsDown:isInteracted(button)
end

function Game:isMouseButtonPressed(button)
    return self.mouseButtonsPressed:isInteracted(button)
end

function Game:isMouseButtonReleased(button)
    return self.mouseButtonsReleased:isInteracted(button)
end

function Game:isMouseGrabbed()
    return love.mouse.isGrabbed()
end

function Game:clearMouseButtonsDown()
    self.mouseButtonsDown = KeysInteracted()
end

function Game:clearMouseButtonsPressed()
    self.mouseButtonsPressed = KeysInteracted()
end

function Game:clearMouseButtonsReleased()
    self.mouseButtonsReleased = KeysInteracted()
end

function Game:clearMouseDownPressedAndReleased()
    self:clearMouseButtonsDown()
    self:clearMouseButtonsPressed()
    self:clearMouseButtonsReleased()
end

function Game:listenToMouseButtonsDown()
    local buttons = {
        [1] = 1,
        [2] = 2,
        [3] = 3
    }

    for button, mappedButton in pairs(buttons) do
        if love.mouse.isDown(button) then
            self:setMouseButtonDown(mappedButton)
        end
    end
end

function Game:getRealMousePosition()
    local x, y = love.mouse.getPosition()
    return {x = x, y = y}
end

function Game:setMousePosition(position)
    love.mouse.setPosition(position.x, position.y)
end


-- Cursor
function Game.setCursor(imageData)
    love.mouse.setCursor(love.mouse.newCursor(imageData))
end