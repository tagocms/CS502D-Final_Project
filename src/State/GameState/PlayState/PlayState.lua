PlayState = Class{__includes = BaseState}

function PlayState:init(def)
    self.callbacks = def.callbacks

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
        
        local fixture = love.physics.newFixture(collidableObjectBody, collidableObjectShape)
        fixture:setUserData('Wall')
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

    self:calculateGrid()
    
    self.camera = Camera()
    self.camera.speed = 10

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

    self.collided = {}
    local function resolveCollision(a, b, coll)
        local objA = a:getUserData()
        local objB = b:getUserData()

        if (objA == 'Player' or objB == 'Player') then
            self:setCollision(self.player)
        end
    end

    local function beginContact(a, b, coll)
        resolveCollision(a, b, coll)
    end

    local function preSolve(a, b, coll)
        resolveCollision(a, b, coll)
    end

    self.world:setCallbacks(beginContact, function () end, preSolve, nil)

    local stateMachine = StateMachine {
        availableStates = {
            [ExploreState.getName()] = ExploreState,
            [BattleState.getName()] = BattleState
        },
        initialStateName = ExploreState.getName(),
        initialStateParams = {
            gameMap = self.gameMap,
            mapSize = self.mapSize,
            camera = self.camera,
            world = self.world,
            enemies = self.enemies,
            player = self.player,
            getScreenSize = PlayState.getScreenSize,
            isCameraLocked = true
        }
    }
    self.stateStack = Stack {
        newItem = stateMachine
    }

    self.showDebug = false
end

function PlayState:exit()
    self.stateStack:exit()
end

function PlayState:update(dt, params)
    local paramsCopy = push_with_keyvalue({}, params)
    self.stateStack:update(
        dt,
        push_with_keyvalue(
            paramsCopy,
            {
                mousePosition = self:convertMousePositionToGame()
            }
        )
    )
    self:handleCollisions()
    if params.keysPressed:isInteracted('d') then
        self.showDebug = not self.showDebug
    end
    self:calculateGrid()
end

function PlayState:setCollision(object)
    self.collided[object] = true
end

function PlayState:handleCollisions()
    if self.collided[self.player] then
        self.player:endMovement()
    end

    self.collided = {}
end

function PlayState:calculateGrid()
    local grid = {}
    for i = 1, self.gameMap.width do
        local line = {}
        for j = 1, self.gameMap.height do
            table.insert(line, j, 0)
        end
        table.insert(grid, i, line)
    end

    -- Recalculate grid to be 0 in walkable tiles, 1 with collidable objects and 2 with enemies
    for body, shape in pairs(self.collidables) do
        local vertices = {shape:getPoints()}
        local verticesConverted = {}
        for i = 1, #vertices, 2 do
            verticesConverted[#verticesConverted+1] = {
                x = vertices[i],
                y = vertices[i + 1]
            }
        end
        local minX = verticesConverted[1].x
        local maxX = verticesConverted[1].x
        local minY = verticesConverted[1].y
        local maxY = verticesConverted[1].y

        for i = 2, #verticesConverted do
            local p = verticesConverted[i]
            if p.x < minX then minX = p.x end
            if p.x > maxX then maxX = p.x end
            if p.y < minY then minY = p.y end
            if p.y > maxY then maxY = p.y end
        end

        local objectPosition = {
            x = body:getX() + minX,
            y = body:getY() + minY
        }
        local objectSize = {
            width = maxX - minX,
            height = maxY - minY
        }
        local tilePositions = self:convertPositionAndSizeFromPixelsToGrid(objectPosition, objectSize)
        for i, position in ipairs(tilePositions) do
            grid[position.x][position.y] = 1
        end
    end

    for i, enemy in ipairs(self.enemies) do
        if not enemy:isDestroyed() then
            local enemyPosition = enemy:getPosition()
            enemyPosition = {
                x = enemyPosition.x - enemy.size.width / 2,
                y = enemyPosition.y - enemy.size.height / 2
            }
            local tilePositions = self:convertPositionAndSizeFromPixelsToGrid(enemyPosition, enemy.size)
            for i, position in ipairs(tilePositions) do
               grid[position.x][position.y] = 2
            end
        end
    end

    self.grid = grid
end

function PlayState:convertPositionFromPixelsToGrid(pixelPosition)
    local tileWidth, tileHeight = self.gameMap.tilewidth, self.gameMap.tileheight

    local x = math.floor(pixelPosition.x / tileWidth) + 1
    local y = math.floor(pixelPosition.y / tileHeight) + 1
    local tilePosition = {
        x = x,
        y = y
    }

    return tilePosition
end

function PlayState:convertPositionAndSizeFromPixelsToGrid(pixelPosition, objectSize)
    local tileWidth, tileHeight = self.gameMap.tilewidth, self.gameMap.tileheight

    local first = self:convertPositionFromPixelsToGrid(pixelPosition)
    local lastX = math.ceil((pixelPosition.x + objectSize.width) / tileWidth)
    local lastY = math.ceil((pixelPosition.y + objectSize.height) / tileHeight)

    local positionsOccupied = {}
    for x = math.max(1, first.x), math.min(self.gameMap.width, lastX) do
        for y = math.max(1, first.y), math.min(self.gameMap.height, lastY) do
            positionsOccupied[#positionsOccupied+1] = {x = x, y = y}
        end
    end

    return positionsOccupied
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
        
        if self.showDebug then
            for i, line in ipairs(self.grid) do
                for j, cell in ipairs(line) do
                    love.graphics.printf(cell, (i - 1) * 32, (j - 1) * 32, 32, 'center', nil, nil, nil, nil, -8)
                    love.graphics.rectangle('line', (i - 1) * 32, (j - 1) * 32, 32, 32)
                end
            end
        end
    self.camera:detach()
    self.stateStack:draw()
end

function PlayState.getName()
    return 'PlayState'
end

function PlayState.getScreenSize()
    return {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }
end

function PlayState:convertMousePositionToGame()
    local x, y = self.camera:mousePosition()
    return { x = x, y = y }
end