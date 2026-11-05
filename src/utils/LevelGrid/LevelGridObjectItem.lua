LevelGridObjectItem = Class{}

function LevelGridObjectItem:init(def)
    self.ref = def.ref
    self.lastTilePositions = {}
end

function LevelGridObjectItem:getPosition()
   return self.ref:getPosition()
end

function LevelGridObjectItem:getSize()
    return self.ref:getSize()
end
