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
        width = 32,
        height = 32
    }
    self._gridSize = def.gridSize or {
        width = 32,
        height = 32
    }
    self._freeTileValue = def.freeTileValue or 0
    self._occupiedTileValue = def.occupiedTileValue or self._freeTileValue + 1

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
end

function LevelGrid:initializePathfinder()
    self.pathfinder = Pathfinder(Grid:new(self._grid), 'JPS', self._freeTileValue)
    self.pathfinder:setMode('ORTHOGONAL')
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
    if not self:isAreaFree(tilePosition, entity.size, {entity})
    or (entity.occupiedTiles and #entity.occupiedTiles > 0) then
        return false
    end

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

---@alias TilePositionValid {x: integer, y: integer, isTileValid: boolean}

---Returns all positions for the entity in the grid, marked as valid or invalid
---@param entity GridObject Entity to check
---@return TilePositionValid[] positions Positions in the whole grid for the entity, marked as valid or invalid
function LevelGrid:getValidPositionsFor(entity)
    ---@type TilePositionValid[]
    local positions = {}

    for y = 1, #self._grid do
        for x = 1, #self._grid[y] do
            local tilePosition = {x = x, y = y}
            if self:isAreaFree(tilePosition, entity.size, {entity}) then
                tilePosition.isTileValid = true
                positions[#positions+1] = tilePosition
            else
                tilePosition.isTileValid = false
                positions[#positions+1] = tilePosition
            end
        end
    end

    return positions
end

---Gets the path, if valid, to target position
---@param from Position Origin tile
---@param to Position Destination tile
---@param entity GridObject Object to move from origin to destination
---@return JumperPath? path Path from origin to the destination, if possible and/or valid
function LevelGrid:getPath(from, to, entity)
    local positions = self:getValidPositionsFor(entity)
    local gridCopy = deepcopy(self._grid)

    for i, position in ipairs(positions) do
        if position.isTileValid then
            gridCopy[position.y][position.x] = self._freeTileValue
        else
            gridCopy[position.y][position.x] = self._occupiedTileValue
        end
    end

    ---@type Pathfinder
    local finder = Pathfinder:new(Grid:new(gridCopy), nil, self._freeTileValue)
    finder:setMode('ORTHOGONAL')

    return finder:getPath(from.x, from.y, to.x, to.y)
end

---Gets the tile position anchor from a pixel position and the entity's size in tiles
---@param pixelPosition Position Position, in pixels
---@param sizeInTiles Size Size, in tiles, of the entity
---@return Position tilePosition Anchor for the entity (given its size) on the grid
function LevelGrid:tilePositionFromPixel(pixelPosition, sizeInTiles)
    ---@type Position
    local tilePosition
    local entityWidth, entityHeight = sizeInTiles.width, sizeInTiles.height
    local isEntityWidthEven, isEntityHeightEven = entityWidth % 2 == 0, entityHeight % 2 == 0

    ---@type integer
    local tileX, tileY
    if isEntityWidthEven then
        tileX = math.floor(pixelPosition.x / self._tileSize.width + 0.5) + 1 - (entityWidth / 2)
    else
        tileX = math.floor(pixelPosition.x / self._tileSize.width) + 1 - math.floor(entityWidth / 2)
    end

    if isEntityHeightEven then
        tileY = math.floor(pixelPosition.y / self._tileSize.height + 0.5) + 1 - (entityHeight / 2)
    else
        tileY = math.floor(pixelPosition.y / self._tileSize.height) + 1 - math.floor(entityHeight / 2)
    end

    tilePosition = {
        x = tileX,
        y = tileY
    }
    return tilePosition
end

---Gets the center pixel position for an anchor, given its entity's size in tiles
---@param tilePositionAnchor Position Entity's tile anchor
---@param sizeInTiles Size Entity's size in tiles
---@return Position centerPixelPosition The pixel at the center of the entity, given the anchor and its size in tiles
function LevelGrid:getCenterPixel(tilePositionAnchor, sizeInTiles)
    ---@type Position
    local centerPixelPosition
    local entityWidth, entityHeight = sizeInTiles.width, sizeInTiles.height
    local isEntityWidthEven, isEntityHeightEven = entityWidth % 2 == 0, entityHeight % 2 == 0

    local centerTilePosition = {
        x = tilePositionAnchor.x + math.floor(entityWidth / 2),
        y = tilePositionAnchor.y + math.floor(entityHeight / 2)
    }

    centerPixelPosition = {
        x = (centerTilePosition.x - 1) * self._tileSize.width + (not isEntityWidthEven and self._tileSize.width / 2 or 0),
        y = (centerTilePosition.y - 1) * self._tileSize.height + (not isEntityHeightEven and self._tileSize.height / 2 or 0),
    }

    return centerPixelPosition
end

---Distance between the first and second entities, given their positions and footprints
---@param firstEntity GridObject First entity
---@param secondEntity GridObject Second entity
---@return number minDistance The minimum distance between both entities
function LevelGrid:distanceBetweenEntities(firstEntity, secondEntity)
    ---@type number?
    local minDistance = nil

    local firstEntityFootprint = self:getFootprint(firstEntity.position, firstEntity.size)
    local secondEntityFootprint = self:getFootprint(secondEntity.position, secondEntity.size)

    for i, firstEntityPosition in ipairs(firstEntityFootprint) do
        for j, secondEntityPosition in ipairs(secondEntityFootprint) do
            local deltaX, deltaY = firstEntityPosition.x - secondEntityPosition.x, firstEntityPosition.y - secondEntityPosition.y
            local distance = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))
            if not minDistance then
                minDistance = distance
            elseif distance < minDistance then
                minDistance = distance
            end
        end
    end

    return minDistance
end

---Checks if an antity with a given anchor and size in tiles is inside the target tile position
---@param targetTilePosition Position Target tile's position
---@param anchorTilePosition Position Entity's anchor tile's position
---@param sizeInTiles Size Entity's size in tiles
---@return boolean isInside `true` if the entity is inside the tile; `false` if not.
function LevelGrid:isInside(targetTilePosition, anchorTilePosition, sizeInTiles)
    local positionsOccupied = self:getFootprint(anchorTilePosition, sizeInTiles)

    for i, position in ipairs(positionsOccupied) do
        if position.x == targetTilePosition.x and position.y == targetTilePosition.y then
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

---Sets the value in the tile position if it's valid.
---@param tilePosition Position Tile position to have its value changed
---@param newValue integer New value
function LevelGrid:setTile(tilePosition, newValue)
    if self:isTilePositionValid(tilePosition) then
        self._grid[tilePosition.y][tilePosition.x] = newValue
    end
end

---Sets the occupant in the tile position if it's valid.
---@param tilePosition Position Tile position to have its value changed
---@param newOccupant GridObject? New occupant
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

---Draws the level grid to the screen.
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