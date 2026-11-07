---@class LevelGrid
---@field _tileSize Size
---@field _gridSize Size
---@field _freeTileValue integer
---@field _grid integer[][]
---@field _occupants GridObject[][]
---@field pathfinder Pathfinder
LevelGrid = Class{}

---@alias GridObject {size: Size, position: Position, numberOnGrid: integer, occupiedTiles: Position[]}

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
        ---@type integer[]
        local gridLine = {}
        ---@type GridObject[]
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
        self:setOccupantInTile(position, nil)
    end

    local newTilePositions = self:convertPositionAndSizeFromPixelsToGrid(item:getPosition(), item:getSize())
    for i, position in ipairs(newTilePositions) do
        self:setTile(position, numberOnGrid)
        self:setOccupantInTile(position, item.ref)
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

---@param tilePosition Position Position at the top-left corner of the object
---@param sizeInTiles Size Size of the object in tiles
---@return Position[] occupiedTiles The tiles the object occupies
function LevelGrid:getFootprint(tilePosition, sizeInTiles)
    ---@type Position[]
    local occupiedTiles = {}
    for y = tilePosition.y, tilePosition.y + sizeInTiles.height - 1 do
        for x = tilePosition.x, tilePosition.x + sizeInTiles.width - 1 do
            occupiedTiles[#occupiedTiles+1] = {x = x, y = y}
        end
    end

    return occupiedTiles
end

---Places an entity inside the specified tile position, anchored to its top-left corner
---@param entity GridObject Entity to place
---@param tilePosition Position Position to be placed
---@return boolean wasAbleToPlace If the placement of the entity was successful 
function LevelGrid:place(entity, tilePosition)
    if not self:isAreaFree(tilePosition, entity.size, {entity}) then return false end

    local tilesToOccupy = self:getFootprint(tilePosition, entity.size)
    for i, tilesToOccupy in ipairs(tilesToOccupy) do
        self:setTile(tilesToOccupy, entity.numberOnGrid)
        self:setOccupantInTile(tilesToOccupy, entity)
    end
    entity.occupiedTiles = tilesToOccupy

    return true
end

---Removes an entity from a tile
---@param entity GridObject Entity to remove from occupied tiles
function LevelGrid:remove(entity)
    for i, occupiedTile in ipairs(entity.occupiedTiles) do
        self:setTile(occupiedTile, self._freeTileValue)
        self:setOccupantInTile(occupiedTile, nil)
    end
    entity.occupiedTiles = {}
end

---Moves the entity to a new position
---@param entity GridObject
---@param newTilePosition Position
---@return boolean wasAbleToMove If the movement of the entity was successful 
function LevelGrid:move(entity, newTilePosition)
    if not self:isAreaFree(newTilePosition, entity.size, {entity}) then return false end
    self:remove(entity)
    self:place(entity, newTilePosition)

    return true
end

---Returns all valid positions for the entity in the grid
---@param entity GridObject Entity to check
---@return Position[] invalidPositions Valid positions in the whole grid for the entity
function LevelGrid:getValidPositionsFor(entity)
    ---@type Position[]
    local validPositions = {}

    for y = 1, #self._grid do
        for x = 1, #self._grid[y] do
            local tilePosition = {x = x, y = y}
            if self:isAreaFree(tilePosition, entity.size, {entity}) then
                validPositions[#validPositions+1] = tilePosition
            end
        end
    end

    return validPositions
end

---Gets the path, if valid, to target position
---@param from Position Origin tile
---@param to Position Destination tile
---@param entity GridObject Object to move from origin to destination
---@return JumperPath? path Path from origin to the destination, if possible and/or valid
function LevelGrid:getPath(from, to, entity)
    local validPositions = self:getValidPositionsFor(entity)
    local gridCopy = deepcopy(self._grid)
    
    for y = 1, #gridCopy do 
        for x = 1, #gridCopy[y] do
            local position = {x = x, y = y}
            if not table.contains(validPositions, position, true) then
                gridCopy[y][x] = nil
            end
        end
    end

    ---@type Pathfinder
    local finder = Pathfinder:new(Grid:new(gridCopy), nil, self._freeTileValue)

    return finder:getPath(from.x, from.y, to.x, to.y)
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

---Checks if the destination tile is walkable
---@param tilePosition Position The target tile's position
---@return boolean isWalkable If the target tile is walkable
function LevelGrid:isWalkable(tilePosition)
    if not self:isTilePositionValid(tilePosition) then
        return false
    else
        return self:getTile(tilePosition) == self._freeTileValue
    end
end

---Checks if the tile position is inside the LevelGrid
---@param tilePosition Position
---@return boolean isTileValid
function LevelGrid:isTilePositionValid(tilePosition)
    return tilePosition.x <= self._gridSize.width
    and tilePosition.x >= 1
    and tilePosition.y <= self._gridSize.height
    and tilePosition.y >= 1
end

---Returns the number in the tile position, for the pathfinder
---@param tilePosition Position The position of the tile to check
---@return integer? numberOnGrid If the tile is valid and if there is an occupant inside the tile, returns its number; else, returns `nil`
function LevelGrid:getTile(tilePosition)
    if not self:isTilePositionValid(tilePosition) then
        return nil
    end
    return self._grid[tilePosition.y][tilePosition.x]
end

---Returns the occupant in the tile position
---@param tilePosition Position The position of the tile to check
---@return GridObject? occupant If the tile is valid and if there is an occupant inside the tile, returns it; else, returns `nil`
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

---Checks if the target area is free and can be moved into.
---@param tilePosition Position The target position
---@param sizeInTiles Size The size, in tiles, of the object
---@param entitiesToIgnore GridObject[] The references to entities to ignore
---@return boolean isAreaFree The result, if the area is free or not
function LevelGrid:isAreaFree(tilePosition, sizeInTiles, entitiesToIgnore)
    if not tilePosition then return false end

    local sizeInTiles = sizeInTiles or {width = 1, height = 1}
    local entitiesToIgnore = entitiesToIgnore or {}

    for y = tilePosition.y, tilePosition.y + sizeInTiles.height - 1 do
        for x = tilePosition.x, tilePosition.x + sizeInTiles.width - 1 do
            local position = {x = x, y = y}
            if not self:isWalkable(position)
                and not table.contains(entitiesToIgnore, self:getOccupantInTile(position)) then
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