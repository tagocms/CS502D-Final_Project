PlayState = Class{__includes = BaseState}

function PlayState:init(def)
    self.gameMap = Sti(def.gameMapPath)
    self.mapSize = {
        width = self.gameMap.width * self.gameMap.tilewidth,
        height = self.gameMap.height * self.gameMap.tileheight
    }

    self.world = love.physics.newWorld(0, 0)
    self.collidables = {}
    for i, object in pairs(self.gameMap.layers['Collidable'].objects) do
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

    self.enemies = {}
    for i, object in pairs(self.gameMap.layers['Enemy'].objects) do
        self.enemies[#self.enemies+1] = Entity {
            animations = ENTITIES['enemy'].animations,
            defaultAnimation = ENTITIES['enemy'].defaultAnimation,
            position = {
                x = object.x,
                y = object.y
            },
            size = ENTITIES['enemy'].size,
            world = self.world
        }
    end
    
    self.camera = Camera()
    self.player = Player {
        animations = ENTITIES['player'].animations,
        defaultAnimation = ENTITIES['player'].defaultAnimation,
        position = {
            x = self.mapSize.width / 2,
            y = self.mapSize.height
        },
        size = ENTITIES['player'].size,
        speed = ENTITIES['player'].speed,
        world = self.world
    }
end

function PlayState:exit()
    
end

function PlayState:update(dt, params)
    for i, enemy in pairs(self.enemies) do
        enemy:update(dt)
    end
    self.player:update(dt, params.keysDown)

    self:updatePhysicsWorldAndEntitiesPosition(dt)
    self:handleCameraMovement()
end

function PlayState:handleCameraMovement()
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

function PlayState:updatePhysicsWorldAndEntitiesPosition(dt)
    self.world:update(dt)
    for i, enemy in pairs(self.enemies) do
        enemy:updatePosition()
    end
    self.player:updatePosition()
end

function PlayState.getScreenSize()
    return {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }
end

function PlayState:draw()
    self.camera:attach()
        self.gameMap:drawLayer(self.gameMap.layers["Background"])
        self.gameMap:drawLayer(self.gameMap.layers["BackMiddleground"])

        for i, enemy in pairs(self.enemies) do
            enemy:draw()
        end
        self.player:draw()

        self.gameMap:drawLayer(self.gameMap.layers["Middleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Foreground"])
    self.camera:detach()
end

function PlayState.getName()
    return 'PlayState'
end