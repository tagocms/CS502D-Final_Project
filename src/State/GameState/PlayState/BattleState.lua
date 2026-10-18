BattleState = Class {__includes = BaseState}

function BattleState:init(def)
    self.gameMap = def.gameMap
    self.mapSize = def.mapSize
    self.camera = def.camera
    self.world = def.world
    self.enemies = def.enemies
    self.player = def.player
    self.getScreenSize = def.getScreenSize
end

function BattleState:update(dt, params)
    
end

function BattleState:draw()
    
end

function BattleState.getName()
    return 'BattleState'
end