LevelGridObjectItem = Class{}

function LevelGridObjectItem:init(def)
    self._ref = def.ref
    self.lastTilePositions = {}
end

function LevelGridObjectItem:getPosition()
   return self._ref:getPosition()
end

function LevelGridObjectItem:getSize()
    return self._ref:getSize()
end
