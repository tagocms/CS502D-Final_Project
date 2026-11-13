PlayState = Class{__includes = BaseState}

function PlayState:init(def)
    self.callbacks = def.callbacks

    self.gameMap = Sti(def.gameMapPath)
    self.mapSize = {
        width = self.gameMap.width * self.gameMap.tilewidth,
        height = self.gameMap.height * self.gameMap.tileheight
    }
    self.levelGrid = LevelGrid {
        tileSize = {
            width = self.gameMap.tilewidth,
            height = self.gameMap.tileheight
        },
        gridSize = {
            width = self.gameMap.width,
            height = self.gameMap.height
        },
        freeTileValue = 0
    }

    self.collidables = {}
    for i, object in pairs(self.gameMap.layers['Collidable'].objects) do
        self.collidables[#self.collidables+1] = Collidable {
            object = object,
            levelGrid = self.levelGrid
        }
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
            numberOnGrid = 1,
            levelGrid = self.levelGrid,
        }
    end
    
    self.camera = Camera()
    self.camera.speed = 1000
    self.cursor = Cursor()

    self.player = Player {
        animations = ENTITIES['player'].animations,
        defaultAnimation = ENTITIES['player'].defaultAnimation,
        position = {
            x = self.mapSize.width / 2,
            y = self.mapSize.height - ENTITIES['player'].size.height / 2
        },
        size = ENTITIES['player'].size,
        numberOnGrid = 1,
        levelGrid = self.levelGrid,
        cursor = self.cursor
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
            enemies = self.enemies,
            player = self.player,
            getScreenSize = PlayState.getScreenSize,
            isCameraLocked = true,
            levelGrid = self.levelGrid,
            cursor = self.cursor
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
    if params.keysPressed:isInteracted('g') then
        self.showDebug = not self.showDebug
    end
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
            self.levelGrid:draw()
        end

        self.cursor:drawEffect()
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