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
    love.window.setIcon(love.image.newImageData("sprites/cursor/mouse_icon1-SwordPointer.png"))

    self:clearKeyDownAndPressed()

    self.gameMap = Sti('src/maps/CastleOutside.lua')
    self.mapSize = {
        width = self.gameMap.width * self.gameMap.tilewidth,
        height = self.gameMap.height * self.gameMap.tileheight
    }

    self.world = love.physics.newWorld(0, 0)
    self.collidables = {}
    for i, object in pairs(self.gameMap.layers["Collidable"].objects) do
        local isPolygon = object.shape == 'polygon'
        local bodyX = isPolygon and 0 or object.x + object.width / 2
        local bodyY = isPolygon and 0 or object.y + object.height / 2
        local collidableObjectBody = love.physics.newBody(self.world, bodyX, bodyY, 'static')
        local collidableObjectShape = {}
        if object.shape == 'polygon' then
            local vertices = {}
            for i, vertex in ipairs(object.polygon) do 
                vertices[#vertices+1] = vertex.x
                vertices[#vertices+1] = vertex.y
            end
            collidableObjectShape = love.physics.newPolygonShape(vertices)
        else 
            collidableObjectShape = love.physics.newRectangleShape(object.width, object.height)
        end
        
        love.physics.newFixture(collidableObjectBody, collidableObjectShape)
        self.collidables[collidableObjectBody] = collidableObjectShape
    end
    
    self.camera = Camera()
    self.player = Player {
        animations = ENTITIES['player'].animations,
        position = {
            x = self.mapSize.width / 2,
            y = self.mapSize.height
        },
        size = ENTITIES['player'].size,
        speed = ENTITIES['player'].speed,
        world = self.world
    }
end

function Game:update(dt)
    self:listenToKeyDown()
    self:handleKeyPressed()

    self.player:update(dt, self.keysDown)
    self:updatePhysicsWorldAndPlayerPosition(dt)
    self:handleCameraMovement()

    self:clearKeyDownAndPressed()
end

function Game:handleCameraMovement()
    self.camera:lookAt(self.player.position.x, self.player.position.y)

    local screenSize = self.getScreenSize()

    -- Left border
    if self.camera.x < screenSize.width / 2 then
        self.camera.x = screenSize.width / 2
    end

    -- Top border
    if self.camera.y < screenSize.height / 2 then
        self.camera.y = screenSize.height / 2
    end

    -- Right border
    if self.camera.x > (self.mapSize.width - screenSize.width / 2) then
        self.camera.x = (self.mapSize.width - screenSize.width / 2)
    end

    -- Bottom border
    if self.camera.y > (self.mapSize.height - screenSize.height / 2) then
        self.camera.y = (self.mapSize.height - screenSize.height / 2)
    end
end

function Game:updatePhysicsWorldAndPlayerPosition(dt)
    self.world:update(dt)
    self.player:updatePosition()
end

function Game:draw()
    self.camera:attach()
        self.gameMap:drawLayer(self.gameMap.layers["Background"])
        self.gameMap:drawLayer(self.gameMap.layers["BackMiddleground"])

        self.player:draw()
        self.gameMap:drawLayer(self.gameMap.layers["Middleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Foreground"])
    self.camera:detach()
end

function Game.getScreenSize()
    return {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }
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