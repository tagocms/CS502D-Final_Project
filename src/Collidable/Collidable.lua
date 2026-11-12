---@class Collidable
---@field levelGrid LevelGrid
---@field size Size
---@field position Position
---@field sizeInTiles Size
---@field anchorTilePosition Position
---@field numberOnGrid integer
Collidable = Class{}

---@class CollidableDef
---@field object CollidableShape
---@field levelGrid LevelGrid

---@param def CollidableDef Initilization definitions for Collidable
function Collidable:init(def)
    local object = def.object

    local isPolygon = object.shape == 'polygon'
    local vertices = object.polygon
    if isPolygon and vertices then
        local minX = vertices[1].x
        local maxX = vertices[1].x
        local minY = vertices[1].y
        local maxY = vertices[1].y

        for i = 2, #vertices do
            local p = vertices[i]
            if p.x < minX then minX = p.x end
            if p.x > maxX then maxX = p.x end
            if p.y < minY then minY = p.y end
            if p.y > maxY then maxY = p.y end
        end

        self.size = {
            width = maxX - minX,
            height = maxY - minY
        }
        self.position = {
            x = minX,
            y = minY
        }
    else
        self.size = {
            width = object.width,
            height = object.height
        }
        self.position = {
            x = object.x,
            y = object.y
        }
    end

    self.numberOnGrid = 1
    self.levelGrid = def.levelGrid
    self:initializeTilePositionsAndSize()
    self:place()
end

function Collidable:initializeTilePositionsAndSize()
    self.anchorTilePosition = self.levelGrid:convertPositionToGrid(self.position)
    self.sizeInTiles = self.levelGrid:convertSizeToGrid(self.size)
end

function Collidable:place()
    self.levelGrid:place(self, self.anchorTilePosition)
end

function Collidable:getPosition()
    return self.position
end

function Collidable:getSize()
    return self.size
end