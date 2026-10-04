local windowWidth, windowHeight = 1080, 720

local Game = {}

function Game:init()
    love.window.setMode(windowWidth, windowHeight, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })
    love.window.setTitle("Age of Bandits")
    -- TODO: Not the permanent icon
    love.window.setIcon(love.image.newImageData("sprites/cursor/mouse_icon1-SwordPointer.png"))

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
    self.player = {x = windowWidth / 2, y = self.mapSize.height, speed = 500}
    self.player.sprite = love.graphics.newImage('sprites/cursor/mouse_icon1-SwordPointer.png')
    self.player.body = love.physics.newBody(self.world, self.player.x, self.player.y, 'dynamic')
    self.player.body:setFixedRotation(true)
    self.player.shape = love.physics.newRectangleShape(self.player.sprite:getWidth(), self.player.sprite:getHeight())
    love.physics.newFixture(self.player.body, self.player.shape)

end

function Game:update(dt)
    local xVelocity, yVelocity = 0, 0
    if love.keyboard.isDown("w") then
        yVelocity = yVelocity -self.player.speed
    end
     if love.keyboard.isDown("s") then
        yVelocity = yVelocity + self.player.speed
     end
    if love.keyboard.isDown("a") then
        xVelocity = xVelocity - self.player.speed
    end
    if love.keyboard.isDown("d") then
        xVelocity = xVelocity + self.player.speed
    end

    self.camera:lookAt(self.player.x, self.player.y)

    local screenSize = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }

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

    self.player.body:setLinearVelocity(xVelocity, yVelocity)
    self.world:update(dt)

    self.player.x = self.player.body:getX()
    self.player.y = self.player.body:getY()
end

function Game:draw()
    self.camera:attach()
        self.gameMap:drawLayer(self.gameMap.layers["Background"])
        self.gameMap:drawLayer(self.gameMap.layers["BackMiddleground"])

        love.graphics.draw(self.player.sprite, self.player.x, self.player.y, nil, 1, 1, self.player.sprite:getWidth() / 2, self.player.sprite:getHeight() / 2)
        self.gameMap:drawLayer(self.gameMap.layers["Middleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Foreground"])
    self.camera:detach()
end

function Game:keypressed(key)
    if key == 'escape' then
		love.event.quit()
	end
end

return Game