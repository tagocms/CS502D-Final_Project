LevelGridObject = Class{}

function LevelGridObject:init(def)
    self.items = def.items or {}
    self.numberOnGrid = def.numberOnGrid or 1
    self.shouldAddItem = def.shouldAddItem or function (item) return true end
end