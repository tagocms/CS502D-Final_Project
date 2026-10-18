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
            getScreenSize = PlayState.getScreenSize
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
    self.stateStack:update(dt, params)
end

function PlayState:draw()
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