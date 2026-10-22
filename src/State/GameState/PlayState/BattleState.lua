BattleState = Class {__includes = BaseState}

function BattleState:init(def)
    self.gameMap = def.gameMap
    self.mapSize = def.mapSize
    self.camera = def.camera
    self.world = def.world
    self.enemies = def.enemies
    self.player = def.player
    self.getScreenSize = def.getScreenSize

    self.stateStack = Stack()
end

function BattleState:update(dt, params)
    for i, enemy in pairs(self.enemies) do
        enemy:update(dt)
    end
    self.player:update(dt, params.mouseButtonsDown)

    self.stateStack:update(dt, params)
    self:updatePhysicsWorldAndEntitiesPosition(dt)
end

function BattleState:updatePhysicsWorldAndEntitiesPosition(dt)
    self.world:update(dt)
    for i, enemy in pairs(self.enemies) do
        enemy:updatePosition()
    end
    self.player:updatePosition()
end

function BattleState:draw()
    
end

function BattleState.getName()
    return 'BattleState'
end