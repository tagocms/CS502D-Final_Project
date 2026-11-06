LevelGrid = Class{}

function LevelGrid:init(def)
    self._tileSize = def.tileSize or {
        width = TILE_SIZE,
        height = TILE_SIZE
    }
    self._gridSize = def.gridSize or {
        width = GRID_SIZE,
        height = GRID_SIZE
    }
    self._freeTileValue = def.freeTileValue or 0

    self:initializeGridObjects(def.objects)
    self:initializeGrid()
    self:initializePathfinder()
end

-- Grid 1-based
-- Grid indexed as `grid[y][x]`
-- Entity position should be top-left in the grid
function LevelGrid:initializeGrid()
    self._grid = {}
    self._occupants = {}

    for i = 1, self._gridSize.height do
        local gridLine = {}
        local occupantsLine = {}
        for j = 1, self._gridSize.width do
            table.insert(gridLine, j, self._freeTileValue)
            table.insert(occupantsLine, j, nil)
        end
        table.insert(self._grid, i, gridLine)
        table.insert(self._occupants, i, occupantsLine)
    end

    -- Initialize gridObjects
    self:initializeGridObjectsPositions()
end

function LevelGrid:initializeGridObjects(objects)
    self._gridObjects = {}
    if not objects then return end

    for k, object in pairs(objects) do
        self:addGridObject(k, object)
    end
end

function LevelGrid:initializePathfinder()
    self.pathfinder = Pathfinder(Grid:new(self._grid), 'JPS', self._freeTileValue)
    self.pathfinder:setMode('ORTHOGONAL')
end

function LevelGrid:initializeGridObjectsPositions()
    for k, gridObject in pairs(self._gridObjects) do
        for i, item in pairs(gridObject.items) do
            if gridObject.shouldAddItem(item) then
                self:updateItemTilePositions(item, gridObject.numberOnGrid)
            end
        end
    end
end

function LevelGrid:addGridObject(key, object)
    local gridObjectItems = {}
    for i, item in ipairs(object.items or {}) do
        gridObjectItems[item] = LevelGridObjectItem {
            ref = item
        }
    end
    self._gridObjects[key] = LevelGridObject {
        numberOnGrid = object.numberOnGrid,
        shouldAddItem = object.shouldAddItem,
        items = gridObjectItems
    }
end

function LevelGrid:deleteGridObject(key)
    if not self._gridObjects[key] then return end
    for key, item in pairs(self._gridObjects[key].items) do
        self:updateItemTilePositions(item, self._freeTileValue)
    end
    self._gridObjects[key] = nil
end

function LevelGrid:updateGridObject(gridObjectKey, updatedItemsRefs)
    if not self._gridObjects[gridObjectKey] then return end

    for i, itemRef in ipairs(updatedItemsRefs) do
        if self._gridObjects[gridObjectKey].items[itemRef] then
            local itemInGridObject = self._gridObjects[gridObjectKey].items[itemRef]
            self:updateItemTilePositions(itemInGridObject, self._gridObjects[gridObjectKey].numberOnGrid)
        end
    end
end

function LevelGrid:updateItemTilePositions(item, numberOnGrid)
    for i, position in ipairs(item.lastTilePositions) do
        self:setTile(position, self._freeTileValue)
        self:setOccupantTile(position, nil)
    end

    local newTilePositions = self:convertPositionAndSizeFromPixelsToGrid(item:getPosition(), item:getSize())
    for i, position in ipairs(newTilePositions) do
        self:setTile(position, numberOnGrid)
        self:setOccupantTile(position, item.ref)
    end

    item.lastTilePositions = newTilePositions
end

function LevelGrid.convertPositionFromGridToPixels(tilePosition, tileSize, center)
    local tileWidth, tileHeight = tileSize.width, tileSize.height
    local center = center or false

    local x = (tilePosition.x - 1) * tileWidth + (center and tileWidth / 2 or 0)
    local y = (tilePosition.y - 1) * tileHeight + (center and tileHeight / 2 or 0)
    local pixelPosition = {
        x = x,
        y = y
    }

    return pixelPosition
end

function LevelGrid:convertPositionToPixelsInTileStart(tilePosition)
    return LevelGrid.convertPositionFromGridToPixels(tilePosition, self._tileSize, false)
end

function LevelGrid:convertPositionToPixelsInTileCenter(tilePosition)
    return LevelGrid.convertPositionFromGridToPixels(tilePosition, self._tileSize, true)
end

function LevelGrid.convertPositionFromPixelsToGrid(pixelPosition, tileSize)
    local tileWidth, tileHeight = tileSize.width, tileSize.height

    local x = math.floor(pixelPosition.x / tileWidth) + 1
    local y = math.floor(pixelPosition.y / tileHeight) + 1
    local tilePosition = {
        x = x,
        y = y
    }

    return tilePosition
end

function LevelGrid:convertPositionToGrid(pixelPosition)
    return LevelGrid.convertPositionFromPixelsToGrid(pixelPosition, self._tileSize)
end

function LevelGrid:convertPositionAndSizeFromPixelsToGrid(pixelPosition, objectSizeInPixels)
    local tileWidth, tileHeight = self._tileSize.width, self._tileSize.height

    local first = self:convertPositionToGrid(pixelPosition)
    local lastX = math.ceil((pixelPosition.x + objectSizeInPixels.width) / tileWidth)
    local lastY = math.ceil((pixelPosition.y + objectSizeInPixels.height) / tileHeight)

    local positionsOccupied = {}
    for x = math.max(1, first.x), math.min(self._gridSize.width, lastX) do
        for y = math.max(1, first.y), math.min(self._gridSize.height, lastY) do
            positionsOccupied[#positionsOccupied+1] = {x = x, y = y}
        end
    end

    return positionsOccupied
end

function LevelGrid:isInside(tilePosition, pixelPosition, objectSizeInPixels)
    local positionsOccupied = self:convertPositionAndSizeFromPixelsToGrid(pixelPosition, objectSizeInPixels)

    for i, position in ipairs(positionsOccupied) do
        if position.x == tilePosition.x and position.y == tilePosition.y then
            return true
        end
    end

    return false
end

function LevelGrid:isWalkable(tilePosition)
    return self:getTile(tilePosition) == self._freeTileValue
end

function LevelGrid:isTilePositionValid(tilePosition)
    return tilePosition.x <= self._gridSize.width
    and tilePosition.x >= 1
    and tilePosition.y <= self._gridSize.height
    and tilePosition.y >= 1
end

function LevelGrid:getTile(tilePosition)
    if not self:isTilePositionValid(tilePosition) then
        return nil
    end
    return self._grid[tilePosition.y][tilePosition.x]
end

function LevelGrid:getOccupantInTile(tilePosition)
    if not self:isTilePositionValid(tilePosition) then
        return nil
    end
    return self._occupants[tilePosition.y][tilePosition.x]
end

function LevelGrid:setTile(tilePosition, newValue)
    if self:isTilePositionValid(tilePosition) then
        self._grid[tilePosition.y][tilePosition.x] = newValue
    end
end

function LevelGrid:setOccupantInTile(tilePosition, newOccupant)
    if self:isTilePositionValid(tilePosition) then
        self._occupants[tilePosition.y][tilePosition.x] = newOccupant
    end
end

function LevelGrid:isAreaFree(tilePosition, sizeInTiles, entitiesToIgnore)
    if not tilePosition then return false end

    local sizeInTiles = sizeInTiles or {width = 1, height = 1}
    local entitiesToIgnore = entitiesToIgnore or {}

    for y = tilePosition.y, tilePosition.y + sizeInTiles.height - 1 do
        for x = tilePosition.x, tilePosition.x + sizeInTiles.width - 1 do
            local position = {x = x, y = y}
            if not self:isWalkable(position)
                and not table.contains(entitiesToIgnore, self:getTile(position)) then
                return false
            end
        end
    end

    return true
end

function LevelGrid:draw()
    for y, line in ipairs(self._grid) do
        for x, tile in ipairs(line) do
            local pixelPosition = self:convertPositionToPixelsInTileStart({x = x, y = y})
            -- Tile text
            love.graphics.printf(
                tile,
                pixelPosition.x, pixelPosition.y,
                self._tileSize.width,
                'center',
                nil, nil, nil, nil, -8
            )
            -- Rectangle
            love.graphics.rectangle(
                'line', 
                pixelPosition.x, pixelPosition.y,
                self._tileSize.width, self._tileSize.height
            )
        end
    end
end