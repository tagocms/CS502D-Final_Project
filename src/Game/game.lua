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

    self:clearKeyDownAndPressed()

    self.stateMachine = StateMachine {
        availableStates = {
            [PlayState.getName()] = PlayState
        },
        initialStateName = PlayState.getName(),
        initialStateParams = {gameMapPath = 'src/maps/CastleOutside.lua'}
    }
end

function Game:update(dt)
    self:listenToKeyDown()
    self:handleKeyPressed()
    self.stateMachine:update(
        dt,
        {
            keysDown = self.keysDown,
            keysPressed = self.keysPressed,
            enterNewState = function (newStateName, newStateParams)
                 self.stateMachine:enterNewState(newStateName, newStateParams)
            end
        }
    )
    self:clearKeyDownAndPressed()
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