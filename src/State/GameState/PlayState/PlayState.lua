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