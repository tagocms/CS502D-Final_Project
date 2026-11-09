require 'dependencies'

describe('LevelGrid class tests', function ()
    -- Grid objects have their size in tiles; `position` is the anchor (top-left tile) of the object
    local createGridObject = function (position, size, numberOnGrid)
        ---@type GridObject
        return {
            anchorTilePosition = position or {x = 1, y = 1},
            sizeInTiles = size or {width = 1, height = 1},
            numberOnGrid = numberOnGrid or 2,
            occupiedTiles = {}
        }
    end

    local createLevelGrid = function (def)
        local def = def or {}

        return LevelGrid {
            tileSize = def.tileSize or {width = 32, height = 32},
            gridSize = def.gridSize or {width = 10, height = 10},
            freeTileValue = def.freeTileValue,
            occupiedTileValue = def.occupiedTileValue
        }
    end

    -- Creates a grid object and places it in the grid
    local placeGridObject = function (levelGrid, tilePosition, size, numberOnGrid)
        local gridObject = createGridObject(tilePosition, size, numberOnGrid)
        assert(levelGrid:place(gridObject, tilePosition), 'Could not place the grid object in the setup.')

        return gridObject
    end

    local containsPosition = function (positions, x, y)
        for i, position in ipairs(positions) do
            if position.x == x and position.y == y then
                return true
            end
        end

        return false
    end

    local countOccupiedTiles = function (levelGrid)
        local occupiedTiles = 0
        for y, line in ipairs(levelGrid._grid) do
            for x, tile in ipairs(line) do
                if tile ~= levelGrid._freeTileValue then
                    occupiedTiles = occupiedTiles + 1
                end
            end
        end

        return occupiedTiles
    end

    -- Tiles outside of a 10x10 grid, as created by `createLevelGrid` by default
    local tilesOutsideOfGrid = {
        {x = 0, y = 1}, {x = 11, y = 1}, {x = 1, y = 0}, {x = 1, y = 11}, {x = -1, y = -1}, {x = 11, y = 11}
    }

    local pathToTiles = function (path)
        path:fill()
        local tiles = {}
        for node, count in path:iter() do
            tiles[#tiles + 1] = {x = node:getX(), y = node:getY()}
        end

        return tiles
    end

    -- Path found by the pathfinder of the grid itself, which only looks at the numbers in the grid
    local getPathfinderTiles = function (levelGrid, startX, startY, endX, endY)
        local path = levelGrid.pathfinder:getPath(startX, startY, endX, endY)
        if not path then return nil end

        return pathToTiles(path)
    end

    -- Path found by `LevelGrid:getPath`, which considers the size of the object
    local getObjectPathTiles = function (levelGrid, from, to, gridObject)
        local ok, path = pcall(levelGrid.getPath, levelGrid, from, to, gridObject)
        assert(ok, 'getPath failed: ' .. tostring(path))
        if not path then return nil end

        return pathToTiles(path)
    end

    describe('LevelGrid:init(def)', function ()
        it('Correctly initializes tile size', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            assert.are.same({width = 16, height = 8}, levelGrid._tileSize)
        end)

        it('Defaults tile size to TILE_SIZE', function ()
            local levelGrid = LevelGrid {}

            assert.are.same({width = 32, height = 32}, levelGrid._tileSize)
        end)

        it('Correctly initializes grid size', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}})

            assert.are.same({width = 4, height = 4}, levelGrid._gridSize)
        end)

        it('Defaults grid size to GRID_SIZE', function ()
            local levelGrid = LevelGrid {}

            assert.are.same({width = 32, height = 32}, levelGrid._gridSize)
        end)

        it('Correctly initializes free tile value', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})

            assert.are.equals(7, levelGrid._freeTileValue)
        end)

        it('Defaults free tile value to 0', function ()
            local levelGrid = createLevelGrid()

            assert.are.equals(0, levelGrid._freeTileValue)
        end)

        it('Correctly initializes occupied tile value', function ()
            local levelGrid = createLevelGrid({occupiedTileValue = 5})

            assert.are.equals(5, levelGrid._occupiedTileValue)
        end)

        it('Defaults occupied tile value to 1', function ()
            local levelGrid = createLevelGrid()

            assert.are.equals(1, levelGrid._occupiedTileValue)
        end)

        it('Defaults the occupied tile value to a value different from the free tile value', function ()
            local levelGrid = createLevelGrid({freeTileValue = 1})

            assert.are_not.equals(levelGrid._freeTileValue, levelGrid._occupiedTileValue)
        end)

        it('Correctly initializes the grid with every tile free', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}})

            assert.are.equals(4, #levelGrid._grid)
            for y, line in ipairs(levelGrid._grid) do
                assert.are.equals(4, #line)
                for x, tile in ipairs(line) do
                    assert.are.equals(0, tile)
                end
            end
        end)

        it('Correctly initializes the grid indexed as grid[y][x] with a non-square grid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            assert.are.equals(2, #levelGrid._grid, 'Grid should have one line per row (height).')
            assert.are.equals(4, #levelGrid._grid[1], 'Each line should have one tile per column (width).')
        end)

        it('Fills the grid with the free tile value', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}, freeTileValue = 7})

            for y, line in ipairs(levelGrid._grid) do
                for x, tile in ipairs(line) do
                    assert.are.equals(7, tile)
                end
            end
        end)

        it('Correctly initializes the occupants with one line per row', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            assert.are.equals('table', type(levelGrid._occupants[1]))
            assert.are.equals('table', type(levelGrid._occupants[2]))
            assert.is_nil(levelGrid._occupants[3])
        end)

        it('Starts without occupants in any tile', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}})

            for y = 1, 4 do
                for x = 1, 4 do
                    assert.is_nil(levelGrid:getOccupantInTile({x = x, y = y}), 'Tile ' .. x .. ', ' .. y .. ' has an occupant.')
                end
            end
        end)

        it('Accepts a definition without optional fields', function ()
            assert.has_no.errors(function () LevelGrid {} end)
        end)

        it('Correctly initializes the pathfinder', function ()
            local levelGrid = createLevelGrid()

            assert(levelGrid.pathfinder ~= nil, 'Pathfinder not initialized.')
            assert.are.equals('JPS', levelGrid.pathfinder:getFinder())
            assert.are.equals('ORTHOGONAL', levelGrid.pathfinder:getMode())
        end)
    end)

    describe('LevelGrid:getFootprint(tilePosition, sizeInTiles)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns a single tile for a 1x1 object', function ()
            local tiles = levelGrid:getFootprint({x = 5, y = 3}, {width = 1, height = 1})

            assert.are.same({{x = 5, y = 3}}, tiles)
        end)

        it('Returns every tile of the rectangle that starts at the position', function ()
            local tiles = levelGrid:getFootprint({x = 5, y = 3}, {width = 3, height = 2})

            assert.are.equals(6, #tiles)
            for x = 5, 7 do
                for y = 3, 4 do
                    assert(containsPosition(tiles, x, y), 'Missing tile ' .. x .. ', ' .. y .. '.')
                end
            end
        end)

        it('Uses the position as the top-left corner', function ()
            local tiles = levelGrid:getFootprint({x = 5, y = 3}, {width = 2, height = 2})

            assert.is_false(containsPosition(tiles, 4, 3), 'Included a tile to the left of the position.')
            assert.is_false(containsPosition(tiles, 5, 2), 'Included a tile above the position.')
            assert.is_false(containsPosition(tiles, 7, 3), 'Included a tile beyond the width.')
            assert.is_false(containsPosition(tiles, 5, 5), 'Included a tile beyond the height.')
        end)

        it('Doesnt clip the tiles to the grid', function ()
            local tiles = levelGrid:getFootprint({x = 10, y = 10}, {width = 2, height = 2})

            assert.are.equals(4, #tiles)
            assert(containsPosition(tiles, 11, 11), 'Tile outside of the grid was removed.')
        end)

        it('Includes tiles before the start of the grid', function ()
            local tiles = levelGrid:getFootprint({x = 0, y = 0}, {width = 2, height = 2})

            assert.are.equals(4, #tiles)
            assert(containsPosition(tiles, 0, 0), 'Tile outside of the grid was removed.')
            assert(containsPosition(tiles, 1, 1), 'Missing tile 1, 1.')
        end)

        it('Returns no tiles for an empty size', function ()
            assert.are.same({}, levelGrid:getFootprint({x = 5, y = 3}, {width = 0, height = 0}))
            assert.are.same({}, levelGrid:getFootprint({x = 5, y = 3}, {width = 3, height = 0}))
        end)

        it('Returns a new list on every call', function ()
            local first = levelGrid:getFootprint({x = 5, y = 3}, {width = 1, height = 1})
            local second = levelGrid:getFootprint({x = 5, y = 3}, {width = 1, height = 1})

            assert.are_not.equals(first, second)
        end)
    end)

    describe('LevelGrid:place(entity, tilePosition)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns true when the area is free', function ()
            local gridObject = createGridObject()

            assert.is_true(levelGrid:place(gridObject, {x = 3, y = 3}))
        end)

        it('Sets the number of the object in the tile', function ()
            local gridObject = createGridObject(nil, nil, 5)

            levelGrid:place(gridObject, {x = 3, y = 4})

            assert.are.equals(5, levelGrid._grid[4][3])
        end)

        it('Sets the number of the object in every tile of its footprint', function ()
            local gridObject = createGridObject(nil, {width = 2, height = 3}, 5)

            levelGrid:place(gridObject, {x = 3, y = 3})

            for x = 3, 4 do
                for y = 3, 5 do
                    assert.are.equals(5, levelGrid._grid[y][x], 'Tile ' .. x .. ', ' .. y .. ' was not set.')
                end
            end
        end)

        it('Sets the object as the occupant of every tile of its footprint', function ()
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            levelGrid:place(gridObject, {x = 3, y = 3})

            for x = 3, 4 do
                for y = 3, 4 do
                    assert.are.equals(gridObject, levelGrid._occupants[y][x], 'Tile ' .. x .. ', ' .. y .. ' has no occupant.')
                end
            end
        end)

        it('Stores the tiles occupied by the object', function ()
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            levelGrid:place(gridObject, {x = 3, y = 3})

            assert.are.equals(4, #gridObject.occupiedTiles)
            assert(containsPosition(gridObject.occupiedTiles, 3, 3), 'Missing tile 3, 3.')
            assert(containsPosition(gridObject.occupiedTiles, 4, 4), 'Missing tile 4, 4.')
        end)

        it('Only changes the tiles of the object', function ()
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            levelGrid:place(gridObject, {x = 3, y = 3})

            assert.are.equals(4, countOccupiedTiles(levelGrid))
        end)

        it('Allows objects with different numbers side by side', function ()
            local first = createGridObject(nil, nil, 2)
            local second = createGridObject(nil, nil, 3)

            assert.is_true(levelGrid:place(first, {x = 3, y = 3}))
            assert.is_true(levelGrid:place(second, {x = 4, y = 3}))

            assert.are.equals(2, levelGrid._grid[3][3])
            assert.are.equals(3, levelGrid._grid[3][4])
        end)

        it('Returns false when the object is already placed', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            assert.is_false(levelGrid:place(gridObject, {x = 3, y = 3}))
            assert.is_false(levelGrid:place(gridObject, {x = 6, y = 6}))
        end)

        it('Doesnt change anything when the object is already placed', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            levelGrid:place(gridObject, {x = 6, y = 6})

            assert.are.equals(4, countOccupiedTiles(levelGrid))
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 3}))
            assert.is_nil(levelGrid:getOccupantInTile({x = 6, y = 6}))
            assert(containsPosition(gridObject.occupiedTiles, 3, 3), 'The tiles of the object changed.')
            assert.is_false(containsPosition(gridObject.occupiedTiles, 6, 6), 'The tiles of the object changed.')
        end)

        it('Allows placing the object again after it is removed', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            levelGrid:remove(gridObject)

            assert.is_true(levelGrid:place(gridObject, {x = 6, y = 6}))
            assert.are.equals(1, countOccupiedTiles(levelGrid))
        end)

        it('Returns false when a tile is occupied by another object', function ()
            placeGridObject(levelGrid, {x = 4, y = 4})
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            assert.is_false(levelGrid:place(gridObject, {x = 3, y = 3}))
        end)

        it('Doesnt change anything when a tile is occupied by another object', function ()
            local other = placeGridObject(levelGrid, {x = 4, y = 4})
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            levelGrid:place(gridObject, {x = 3, y = 3})

            assert.are.equals(1, countOccupiedTiles(levelGrid))
            assert.are.equals(other, levelGrid:getOccupantInTile({x = 4, y = 4}))
            assert.are.same({}, gridObject.occupiedTiles)
        end)

        it('Returns false when a tile is a wall', function ()
            levelGrid:setTile({x = 4, y = 4}, 9)
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            assert.is_false(levelGrid:place(gridObject, {x = 3, y = 3}))
            assert.are.equals(1, countOccupiedTiles(levelGrid))
        end)

        it('Returns false when the object is partially outside of the grid', function ()
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            assert.is_false(levelGrid:place(gridObject, {x = 10, y = 10}))
            assert.is_false(levelGrid:place(gridObject, {x = 0, y = 0}))
        end)

        it('Doesnt change anything when the object is partially outside of the grid', function ()
            local gridObject = createGridObject(nil, {width = 2, height = 2})

            levelGrid:place(gridObject, {x = 10, y = 10})

            assert.are.equals(0, countOccupiedTiles(levelGrid))
            assert.are.same({}, gridObject.occupiedTiles)
        end)

        it('Returns false when the object is completely outside of the grid', function ()
            local gridObject = createGridObject()

            assert.is_false(levelGrid:place(gridObject, {x = 20, y = 20}))
        end)

        it('Places objects with the free tile value of the grid', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})
            local gridObject = createGridObject(nil, nil, 2)

            assert.is_true(levelGrid:place(gridObject, {x = 3, y = 3}))
            assert.is_false(levelGrid:isWalkable({x = 3, y = 3}))
        end)
    end)

    describe('LevelGrid:remove(entity)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Frees the tile of the object', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})

            levelGrid:remove(gridObject)

            assert.are.equals(0, levelGrid._grid[3][3])
            assert.is_true(levelGrid:isWalkable({x = 3, y = 3}))
        end)

        it('Frees every tile of an object bigger than a tile', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 3})

            levelGrid:remove(gridObject)

            assert.are.equals(0, countOccupiedTiles(levelGrid))
        end)

        it('Frees the tiles with the free tile value of the grid', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})

            levelGrid:remove(gridObject)

            assert.are.equals(7, levelGrid._grid[3][3])
        end)

        it('Removes the object as the occupant of its tiles', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            levelGrid:remove(gridObject)

            for x = 3, 4 do
                for y = 3, 4 do
                    assert.is_nil(levelGrid._occupants[y][x], 'Tile ' .. x .. ', ' .. y .. ' still has an occupant.')
                end
            end
        end)

        it('Clears the tiles occupied by the object', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            levelGrid:remove(gridObject)

            assert.are.same({}, gridObject.occupiedTiles)
        end)

        it('Keeps the other objects', function ()
            local first = placeGridObject(levelGrid, {x = 3, y = 3})
            local second = placeGridObject(levelGrid, {x = 4, y = 3}, nil, 3)

            levelGrid:remove(first)

            assert.are.equals(3, levelGrid._grid[3][4])
            assert.are.equals(second, levelGrid:getOccupantInTile({x = 4, y = 3}))
        end)

        it('Doesnt fail for an object that was never placed', function ()
            local gridObject = createGridObject()

            assert.has_no.errors(function () levelGrid:remove(gridObject) end)
        end)

        it('Doesnt change the grid for an object that was never placed', function ()
            placeGridObject(levelGrid, {x = 3, y = 3})

            levelGrid:remove(createGridObject())

            assert.are.equals(1, countOccupiedTiles(levelGrid))
        end)

        it('Doesnt fail when the object is removed twice', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            levelGrid:remove(gridObject)

            assert.has_no.errors(function () levelGrid:remove(gridObject) end)
            assert.are.equals(0, countOccupiedTiles(levelGrid))
        end)

        it('Allows the tiles to be used by another object', function ()
            local first = placeGridObject(levelGrid, {x = 3, y = 3})
            levelGrid:remove(first)

            assert.is_true(levelGrid:place(createGridObject(), {x = 3, y = 3}))
        end)
    end)

    describe('LevelGrid:move(entity, newTilePosition)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns true when the new area is free', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})

            assert.is_true(levelGrid:move(gridObject, {x = 5, y = 5}))
        end)

        it('Occupies the new tile', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, nil, 4)

            levelGrid:move(gridObject, {x = 5, y = 5})

            assert.are.equals(4, levelGrid._grid[5][5])
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 5, y = 5}))
        end)

        it('Frees the old tile', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})

            levelGrid:move(gridObject, {x = 5, y = 5})

            assert.are.equals(0, levelGrid._grid[3][3])
            assert.is_nil(levelGrid:getOccupantInTile({x = 3, y = 3}))
        end)

        it('Updates the tiles occupied by the object', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            levelGrid:move(gridObject, {x = 6, y = 6})

            assert.are.equals(4, #gridObject.occupiedTiles)
            assert(containsPosition(gridObject.occupiedTiles, 6, 6), 'Missing tile 6, 6.')
            assert(containsPosition(gridObject.occupiedTiles, 7, 7), 'Missing tile 7, 7.')
        end)

        it('Only occupies the tiles of the object after moving', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            levelGrid:move(gridObject, {x = 6, y = 6})

            assert.are.equals(4, countOccupiedTiles(levelGrid))
        end)

        it('Moves an object bigger than a tile to a position that overlaps its own tiles', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            assert.is_true(levelGrid:move(gridObject, {x = 4, y = 3}))

            assert.are.equals(0, levelGrid._grid[3][3])
            assert.are.equals(2, levelGrid._grid[3][4])
            assert.are.equals(2, levelGrid._grid[3][5])
            assert.are.equals(4, countOccupiedTiles(levelGrid))
        end)

        it('Keeps the object in the same tile when moving to its own position', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})

            assert.is_true(levelGrid:move(gridObject, {x = 3, y = 3}))
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 3}))
        end)

        it('Returns false when the new area is occupied by another object', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            placeGridObject(levelGrid, {x = 5, y = 5}, nil, 3)

            assert.is_false(levelGrid:move(gridObject, {x = 5, y = 5}))
        end)

        it('Keeps the object where it was when it cant move', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            placeGridObject(levelGrid, {x = 5, y = 5}, nil, 3)

            levelGrid:move(gridObject, {x = 5, y = 5})

            assert.are.equals(2, levelGrid._grid[3][3])
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 3}))
            assert.are.equals(3, levelGrid._grid[5][5])
            assert.are.equals(1, #gridObject.occupiedTiles)
        end)

        it('Returns false and keeps the object when part of the new area is occupied', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1}, {width = 2, height = 2})
            placeGridObject(levelGrid, {x = 6, y = 6}, nil, 3)

            assert.is_false(levelGrid:move(gridObject, {x = 5, y = 5}))
            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(2, levelGrid._grid[2][2])
            assert.are.equals(0, levelGrid._grid[5][5])
        end)

        it('Returns false when the new area has a wall', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            levelGrid:setTile({x = 5, y = 5}, 9)

            assert.is_false(levelGrid:move(gridObject, {x = 5, y = 5}))
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 3}))
        end)

        it('Returns false and keeps the object when it would be partially outside of the grid', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3}, {width = 2, height = 2})

            assert.is_false(levelGrid:move(gridObject, {x = 10, y = 10}))
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 3}))
            assert.are.equals(4, countOccupiedTiles(levelGrid))
        end)

        it('Returns false and keeps the object when the new position is outside of the grid', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})

            assert.is_false(levelGrid:move(gridObject, {x = 20, y = 20}))
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 3}))
        end)

        it('Moves to a tile that was freed by removing another object', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            local other = placeGridObject(levelGrid, {x = 5, y = 5}, nil, 3)
            levelGrid:remove(other)

            assert.is_true(levelGrid:move(gridObject, {x = 5, y = 5}))
        end)

        it('Keeps the other objects', function ()
            local gridObject = placeGridObject(levelGrid, {x = 3, y = 3})
            local other = placeGridObject(levelGrid, {x = 7, y = 7}, nil, 3)

            levelGrid:move(gridObject, {x = 5, y = 5})

            assert.are.equals(other, levelGrid:getOccupantInTile({x = 7, y = 7}))
            assert.are.equals(3, levelGrid._grid[7][7])
        end)

        it('Places an object that was never placed', function ()
            local gridObject = createGridObject()

            assert.is_true(levelGrid:move(gridObject, {x = 5, y = 5}))
            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 5, y = 5}))
        end)
    end)

    describe('LevelGrid:getValidPositionsFor(entity)', function ()
        local findPosition = function (positions, x, y)
            for i, position in ipairs(positions) do
                if position.x == x and position.y == y then
                    return position
                end
            end

            return nil
        end

        local countValidPositions = function (positions)
            local validPositions = 0
            for i, position in ipairs(positions) do
                if position.isTileValid then
                    validPositions = validPositions + 1
                end
            end

            return validPositions
        end

        it('Returns every position of the grid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})

            local positions = levelGrid:getValidPositionsFor(createGridObject())

            assert.are.equals(9, #positions)
            for x = 1, 3 do
                for y = 1, 3 do
                    assert(findPosition(positions, x, y) ~= nil, 'Missing position ' .. x .. ', ' .. y .. '.')
                end
            end
        end)

        it('Returns every position of a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            local positions = levelGrid:getValidPositionsFor(createGridObject())

            assert.are.equals(8, #positions)
            assert(findPosition(positions, 4, 2) ~= nil, 'Missing position 4, 2.')
        end)

        it('Marks every position of an empty grid as valid for a 1x1 object', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})

            local positions = levelGrid:getValidPositionsFor(createGridObject())

            assert.are.equals(9, countValidPositions(positions))
        end)

        it('Marks the positions occupied by other objects as invalid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            placeGridObject(levelGrid, {x = 2, y = 2}, nil, 3)

            local positions = levelGrid:getValidPositionsFor(createGridObject())

            assert.are.equals(8, countValidPositions(positions))
            assert.is_false(findPosition(positions, 2, 2).isTileValid, 'Tile occupied by another object is valid.')
        end)

        it('Marks the positions that are walls as invalid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            levelGrid:setTile({x = 1, y = 3}, 9)

            local positions = levelGrid:getValidPositionsFor(createGridObject())

            assert.are.equals(8, countValidPositions(positions))
            assert.is_false(findPosition(positions, 1, 3).isTileValid, 'Wall tile is valid.')
        end)

        it('Marks the positions occupied by the object itself as valid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            local gridObject = placeGridObject(levelGrid, {x = 2, y = 2})

            local positions = levelGrid:getValidPositionsFor(gridObject)

            assert.are.equals(9, countValidPositions(positions))
            assert.is_true(findPosition(positions, 2, 2).isTileValid, 'The tile of the object itself is invalid.')
        end)

        it('Only marks as valid the anchors where an object bigger than a tile fits', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})

            local positions = levelGrid:getValidPositionsFor(createGridObject(nil, {width = 2, height = 2}))

            assert.are.equals(9, #positions)
            assert.are.equals(4, countValidPositions(positions))
            for x = 1, 3 do
                for y = 1, 3 do
                    local shouldBeValid = x <= 2 and y <= 2
                    assert.are.equals(shouldBeValid, findPosition(positions, x, y).isTileValid,
                        'Anchor ' .. x .. ', ' .. y .. ' has the wrong validity.')
                end
            end
        end)

        it('Marks as invalid the anchors whose area has an obstacle', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            levelGrid:setTile({x = 3, y = 3}, 9)

            local positions = levelGrid:getValidPositionsFor(createGridObject(nil, {width = 2, height = 2}))

            assert.are.equals(3, countValidPositions(positions))
            assert.is_false(findPosition(positions, 2, 2).isTileValid, 'Anchor whose area has the obstacle is valid.')
        end)

        it('Blocks the anchors up and to the left of an obstacle, not the ones down and to the right', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 5, height = 5}})
            levelGrid:setTile({x = 3, y = 3}, 9)

            local positions = levelGrid:getValidPositionsFor(createGridObject(nil, {width = 2, height = 2}))

            for x = 2, 3 do
                for y = 2, 3 do
                    assert.is_false(findPosition(positions, x, y).isTileValid, 'Anchor ' .. x .. ', ' .. y .. ' reaches the obstacle.')
                end
            end
            assert.is_true(findPosition(positions, 4, 4).isTileValid, 'Anchor 4, 4 should be valid.')
            assert.is_true(findPosition(positions, 1, 1).isTileValid, 'Anchor 1, 1 should be valid.')
        end)

        it('Marks every position as invalid when the object doesnt fit in the grid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 2, height = 2}})

            local positions = levelGrid:getValidPositionsFor(createGridObject(nil, {width = 3, height = 3}))

            assert.are.equals(4, #positions)
            assert.are.equals(0, countValidPositions(positions))
        end)

        it('Doesnt change the grid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            placeGridObject(levelGrid, {x = 2, y = 2}, nil, 3)
            local gridBefore = deepcopy(levelGrid._grid)

            levelGrid:getValidPositionsFor(createGridObject())

            assert.are.same(gridBefore, levelGrid._grid)
        end)
    end)

    describe('LevelGrid:getPath(from, to, entity)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}})
        end)

        it('Finds a path in an empty grid', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            assert.are.equals(4, #tiles)
            assert.are.same({x = 1, y = 1}, tiles[1])
            assert.are.same({x = 4, y = 1}, tiles[#tiles])
        end)

        it('Only moves orthogonally', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 3, y = 3}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            for i = 2, #tiles do
                local steps = math.abs(tiles[i].x - tiles[i - 1].x) + math.abs(tiles[i].y - tiles[i - 1].y)
                assert.are.equals(1, steps, 'Step ' .. i .. ' of the path is diagonal.')
            end
        end)

        it('Doesnt change the grid', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            local gridBefore = deepcopy(levelGrid._grid)

            getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject)

            assert.are.same(gridBefore, levelGrid._grid)
        end)

        it('Finds a path that avoids walls when the free tile value is not 0', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}, freeTileValue = 7})
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            levelGrid:setTile({x = 2, y = 1}, 9)

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through a wall.')
        end)

        it('Finds a path that avoids walls with a custom occupied tile value', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}, occupiedTileValue = 5})
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            levelGrid:setTile({x = 2, y = 1}, 9)

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through a wall.')
        end)

        it('Avoids the tiles that are walls', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            levelGrid:setTile({x = 2, y = 1}, 9)

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through a wall.')
            assert.are.same({x = 4, y = 1}, tiles[#tiles])
        end)

        it('Avoids the tiles occupied by other objects', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            placeGridObject(levelGrid, {x = 2, y = 1}, nil, 3)

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through another object.')
        end)

        it('Doesnt find a path when the destination is walled off', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            for y = 1, 4 do
                levelGrid:setTile({x = 3, y = y}, 9)
            end

            assert.is_nil(getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject))
        end)

        it('Doesnt find a path to a tile occupied by another object', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1})
            placeGridObject(levelGrid, {x = 4, y = 1}, nil, 3)

            assert.is_nil(getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 1}, gridObject))
        end)

        it('Ignores the tiles of the object itself', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1}, {width = 2, height = 2})

            local tiles = getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 3, y = 3}, gridObject)

            assert(tiles ~= nil, 'Path not found.')
            assert.are.same({x = 3, y = 3}, tiles[#tiles])
        end)

        it('Doesnt find a path to an anchor where an object bigger than a tile doesnt fit', function ()
            local gridObject = placeGridObject(levelGrid, {x = 1, y = 1}, {width = 2, height = 2})

            assert.is_nil(getObjectPathTiles(levelGrid, {x = 1, y = 1}, {x = 4, y = 4}, gridObject))
        end)

        describe('Passages', function ()
            local widePassage

            before_each(function ()
                widePassage = createLevelGrid({gridSize = {width = 5, height = 3}})
            end)

            it('Doesnt let an object bigger than a tile through a passage of one tile', function ()
                local gridObject = placeGridObject(widePassage, {x = 1, y = 2}, {width = 2, height = 2})
                widePassage:setTile({x = 3, y = 1}, 9)
                widePassage:setTile({x = 3, y = 3}, 9)

                assert.is_nil(getObjectPathTiles(widePassage, {x = 1, y = 2}, {x = 4, y = 2}, gridObject))
            end)

            it('Lets an object bigger than a tile through a passage of its size', function ()
                local gridObject = placeGridObject(widePassage, {x = 1, y = 2}, {width = 2, height = 2})
                widePassage:setTile({x = 3, y = 1}, 9)

                local tiles = getObjectPathTiles(widePassage, {x = 1, y = 2}, {x = 4, y = 2}, gridObject)

                assert(tiles ~= nil, 'Path not found.')
                assert.are.same({x = 4, y = 2}, tiles[#tiles])
            end)

            it('Lets a 1x1 object through a passage of one tile', function ()
                local gridObject = placeGridObject(widePassage, {x = 1, y = 2})
                widePassage:setTile({x = 3, y = 1}, 9)
                widePassage:setTile({x = 3, y = 3}, 9)

                local tiles = getObjectPathTiles(widePassage, {x = 1, y = 2}, {x = 5, y = 2}, gridObject)

                assert(tiles ~= nil, 'Path not found.')
                assert(containsPosition(tiles, 3, 2), 'Path doesnt go through the passage.')
            end)
        end)
    end)

    describe('LevelGrid:tilePositionFromPixel(pixelPosition, sizeInTiles)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        -- Tile 5 occupies the pixels 128 to 159 on each axis, with tiles of 32 pixels

        describe('Odd sizes', function ()
            it('Returns the tile under the pixel for a 1x1 object', function ()
                assert.are.same({x = 5, y = 5}, levelGrid:tilePositionFromPixel({x = 144, y = 144}, {width = 1, height = 1}))
            end)

            it('Returns the same tile for every pixel of the tile', function ()
                local size = {width = 1, height = 1}

                assert.are.same({x = 5, y = 5}, levelGrid:tilePositionFromPixel({x = 128, y = 128}, size))
                assert.are.same({x = 5, y = 5}, levelGrid:tilePositionFromPixel({x = 159, y = 159}, size))
            end)

            it('Moves to the next tile at the tile border', function ()
                local size = {width = 1, height = 1}

                assert.are.same({x = 4, y = 4}, levelGrid:tilePositionFromPixel({x = 127, y = 127}, size))
                assert.are.same({x = 6, y = 6}, levelGrid:tilePositionFromPixel({x = 160, y = 160}, size))
            end)

            it('Makes the tile under the pixel the middle tile for a 3x3 object', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 144, y = 144}, {width = 3, height = 3})

                assert.are.same({x = 4, y = 4}, anchor)
            end)

            it('Makes the tile under the pixel the middle tile for a 5x5 object', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 144, y = 144}, {width = 5, height = 5})

                assert.are.same({x = 3, y = 3}, anchor)
            end)

            it('Doesnt depend on where the pixel is inside of the tile', function ()
                local size = {width = 3, height = 3}

                assert.are.same({x = 4, y = 4}, levelGrid:tilePositionFromPixel({x = 129, y = 129}, size))
                assert.are.same({x = 4, y = 4}, levelGrid:tilePositionFromPixel({x = 159, y = 159}, size))
            end)
        end)

        describe('Even sizes', function ()
            it('Snaps to the closest intersection on the left side of a tile', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 129, y = 129}, {width = 2, height = 2})

                -- Closest intersection is between tiles 4 and 5, so the object occupies 4 and 5
                assert.are.same({x = 4, y = 4}, anchor)
            end)

            it('Snaps to the closest intersection on the right side of a tile', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 159, y = 159}, {width = 2, height = 2})

                -- Closest intersection is between tiles 5 and 6, so the object occupies 5 and 6
                assert.are.same({x = 5, y = 5}, anchor)
            end)

            it('Snaps down and to the right when the pixel is exactly in the middle of a tile', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 144, y = 144}, {width = 2, height = 2})

                assert.are.same({x = 5, y = 5}, anchor)
            end)

            it('Centers the object on the intersection when the pixel is exactly on it', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 128, y = 128}, {width = 2, height = 2})

                -- Intersection between tiles 4 and 5
                assert.are.same({x = 4, y = 4}, anchor)
            end)

            it('Works for a 4x4 object', function ()
                local size = {width = 4, height = 4}

                assert.are.same({x = 3, y = 3}, levelGrid:tilePositionFromPixel({x = 129, y = 129}, size))
                assert.are.same({x = 4, y = 4}, levelGrid:tilePositionFromPixel({x = 159, y = 159}, size))
            end)
        end)

        describe('Axes', function ()
            it('Applies the rule of each axis to its own size', function ()
                -- 2 wide (even) and 3 tall (odd)
                local anchor = levelGrid:tilePositionFromPixel({x = 129, y = 144}, {width = 2, height = 3})

                assert.are.same({x = 4, y = 4}, anchor)
            end)

            it('Applies the rules in x and y independently', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 159, y = 129}, {width = 2, height = 2})

                assert.are.same({x = 5, y = 4}, anchor)
            end)

            it('Uses the width for x and the height for y', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 144, y = 144}, {width = 3, height = 1})

                assert.are.same({x = 4, y = 5}, anchor)
            end)

            it('Uses the tile size of the grid', function ()
                local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

                -- 40 / 16 = tile 3; 20 / 8 = tile 3
                assert.are.same({x = 3, y = 3}, levelGrid:tilePositionFromPixel({x = 40, y = 20}, {width = 1, height = 1}))
            end)
        end)

        describe('Outside of the grid', function ()
            it('Doesnt clamp a pixel before the start of the grid', function ()
                assert.are.same({x = 0, y = 0}, levelGrid:tilePositionFromPixel({x = -10, y = -10}, {width = 1, height = 1}))
            end)

            it('Doesnt clamp the anchor of an odd object at the first tile', function ()
                assert.are.same({x = 0, y = 0}, levelGrid:tilePositionFromPixel({x = 0, y = 0}, {width = 3, height = 3}))
            end)

            it('Doesnt clamp the anchor of an even object at the first tile', function ()
                assert.are.same({x = 0, y = 0}, levelGrid:tilePositionFromPixel({x = 0, y = 0}, {width = 2, height = 2}))
            end)

            it('Doesnt clamp a pixel after the end of the grid', function ()
                assert.are.same({x = 11, y = 11}, levelGrid:tilePositionFromPixel({x = 330, y = 330}, {width = 1, height = 1}))
            end)

            it('Gives an anchor that isAreaFree rejects', function ()
                local anchor = levelGrid:tilePositionFromPixel({x = 0, y = 0}, {width = 3, height = 3})

                assert.is_false(levelGrid:isAreaFree(anchor, {width = 3, height = 3}))
            end)
        end)

        it('Gives an anchor with the pixel in the middle tile of a 3x3 object that fits in the grid', function ()
            local size = {width = 3, height = 3}
            local anchor = levelGrid:tilePositionFromPixel({x = 144, y = 144}, size)

            assert.is_true(levelGrid:isInside({x = 5, y = 5}, anchor, size))
            assert.is_true(levelGrid:isAreaFree(anchor, size))
        end)
    end)

    describe('LevelGrid:getCenterPixel(tilePositionAnchor, sizeInTiles)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns the center of the tile for a 1x1 object', function ()
            local pixel = levelGrid:getCenterPixel({x = 1, y = 1}, {width = 1, height = 1})

            assert.are.same({x = 16, y = 16}, pixel)
        end)

        it('Returns the center of a tile that is not the first for a 1x1 object', function ()
            local pixel = levelGrid:getCenterPixel({x = 5, y = 5}, {width = 1, height = 1})

            assert.are.same({x = 144, y = 144}, pixel)
        end)

        it('Returns the center of the middle tile for a 3x3 object', function ()
            -- Anchor 4 means tiles 4, 5 and 6, so the middle tile is 5
            local pixel = levelGrid:getCenterPixel({x = 4, y = 4}, {width = 3, height = 3})

            assert.are.same({x = 144, y = 144}, pixel)
        end)

        it('Returns the intersection in the middle of a 2x2 object', function ()
            -- Anchor 4 means tiles 4 and 5, so the center is the intersection between them
            local pixel = levelGrid:getCenterPixel({x = 4, y = 4}, {width = 2, height = 2})

            assert.are.same({x = 128, y = 128}, pixel)
        end)

        it('Returns the intersection in the middle of a 4x4 object', function ()
            -- Anchor 3 means tiles 3 to 6, so the center is the intersection between 4 and 5
            local pixel = levelGrid:getCenterPixel({x = 3, y = 3}, {width = 4, height = 4})

            assert.are.same({x = 128, y = 128}, pixel)
        end)

        it('Applies the rule of each axis to its own size', function ()
            -- 2 wide (even) and 3 tall (odd)
            local pixel = levelGrid:getCenterPixel({x = 4, y = 4}, {width = 2, height = 3})

            assert.are.same({x = 128, y = 144}, pixel)
        end)

        it('Uses the tile size of the grid', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            -- Tile 2 on x spans 16 to 31 and tile 3 on y spans 16 to 23
            local pixel = levelGrid:getCenterPixel({x = 2, y = 3}, {width = 1, height = 1})

            assert.are.same({x = 24, y = 20}, pixel)
        end)

        it('Is the inverse of tilePositionFromPixel for every size', function ()
            for width = 1, 4 do
                for height = 1, 4 do
                    local size = {width = width, height = height}
                    local anchor = {x = 4, y = 6}

                    local pixel = levelGrid:getCenterPixel(anchor, size)

                    assert.are.same(anchor, levelGrid:tilePositionFromPixel(pixel, size),
                        'Round trip failed for size ' .. width .. 'x' .. height .. '.')
                end
            end
        end)
    end)

    describe('LevelGrid:distanceBetweenEntities(firstEntity, secondEntity)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns 0 for objects in the same tile', function ()
            local first = createGridObject({x = 3, y = 3})
            local second = createGridObject({x = 3, y = 3})

            assert.are.equals(0, levelGrid:distanceBetweenEntities(first, second))
        end)

        it('Returns 1 for objects in adjacent tiles', function ()
            local first = createGridObject({x = 3, y = 3})

            assert.are.equals(1, levelGrid:distanceBetweenEntities(first, createGridObject({x = 4, y = 3})))
            assert.are.equals(1, levelGrid:distanceBetweenEntities(first, createGridObject({x = 3, y = 4})))
        end)

        it('Returns the distance in tiles for objects in a straight line', function ()
            local first = createGridObject({x = 3, y = 3})
            local second = createGridObject({x = 6, y = 3})

            assert.are.equals(3, levelGrid:distanceBetweenEntities(first, second))
        end)

        it('Returns the euclidean distance for objects in diagonal', function ()
            local first = createGridObject({x = 3, y = 3})
            local second = createGridObject({x = 4, y = 4})

            assert.are.equals(math.sqrt(2), levelGrid:distanceBetweenEntities(first, second))
        end)

        it('Uses the closest tiles of an object bigger than a tile', function ()
            local first = createGridObject({x = 1, y = 1}, {width = 2, height = 2})
            local second = createGridObject({x = 4, y = 1})

            -- The closest tile of the first object is 2, 1
            assert.are.equals(2, levelGrid:distanceBetweenEntities(first, second))
        end)

        it('Uses the closest tiles of both objects when they are bigger than a tile', function ()
            local first = createGridObject({x = 1, y = 1}, {width = 2, height = 2})
            local second = createGridObject({x = 5, y = 1}, {width = 2, height = 2})

            -- Closest tiles are 2, 1 and 5, 1
            assert.are.equals(3, levelGrid:distanceBetweenEntities(first, second))
        end)

        it('Returns 0 for objects whose footprints overlap', function ()
            local first = createGridObject({x = 1, y = 1}, {width = 3, height = 3})
            local second = createGridObject({x = 3, y = 3}, {width = 2, height = 2})

            assert.are.equals(0, levelGrid:distanceBetweenEntities(first, second))
        end)

        it('Returns the same distance regardless of the order of the objects', function ()
            local first = createGridObject({x = 1, y = 2}, {width = 2, height = 3})
            local second = createGridObject({x = 7, y = 6})

            assert.are.equals(
                levelGrid:distanceBetweenEntities(first, second),
                levelGrid:distanceBetweenEntities(second, first)
            )
        end)
    end)

    describe('LevelGrid.convertPositionFromGridToPixels(tilePosition, tileSize, center)', function ()
        local tileSize = {width = 32, height = 32}

        it('Converts the first tile to the origin', function ()
            local pixelPosition = LevelGrid.convertPositionFromGridToPixels({x = 1, y = 1}, tileSize)

            assert.are.same({x = 0, y = 0}, pixelPosition)
        end)

        it('Converts to the start of the tile', function ()
            local pixelPosition = LevelGrid.convertPositionFromGridToPixels({x = 3, y = 2}, tileSize)

            assert.are.same({x = 64, y = 32}, pixelPosition)
        end)

        it('Converts to the center of the tile', function ()
            local pixelPosition = LevelGrid.convertPositionFromGridToPixels({x = 3, y = 2}, tileSize, true)

            assert.are.same({x = 80, y = 48}, pixelPosition)
        end)

        it('Doesnt center by default', function ()
            local notCentered = LevelGrid.convertPositionFromGridToPixels({x = 3, y = 2}, tileSize)
            local explicitlyNotCentered = LevelGrid.convertPositionFromGridToPixels({x = 3, y = 2}, tileSize, false)

            assert.are.same(explicitlyNotCentered, notCentered)
        end)

        it('Supports tiles that are not squares', function ()
            local rectangularTileSize = {width = 16, height = 8}

            assert.are.same({x = 16, y = 16}, LevelGrid.convertPositionFromGridToPixels({x = 2, y = 3}, rectangularTileSize))
            assert.are.same({x = 24, y = 20}, LevelGrid.convertPositionFromGridToPixels({x = 2, y = 3}, rectangularTileSize, true))
        end)
    end)

    describe('LevelGrid:convertPositionToPixelsInTileStart(tilePosition)', function ()
        it('Converts to the start of the tile using the tile size of the grid', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            assert.are.same({x = 16, y = 16}, levelGrid:convertPositionToPixelsInTileStart({x = 2, y = 3}))
        end)
    end)

    describe('LevelGrid:convertPositionToPixelsInTileCenter(tilePosition)', function ()
        it('Converts to the center of the tile using the tile size of the grid', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            assert.are.same({x = 24, y = 20}, levelGrid:convertPositionToPixelsInTileCenter({x = 2, y = 3}))
        end)
    end)

    describe('LevelGrid.convertPositionFromPixelsToGrid(pixelPosition, tileSize)', function ()
        local tileSize = {width = 32, height = 32}

        it('Converts the origin to the first tile', function ()
            local tilePosition = LevelGrid.convertPositionFromPixelsToGrid({x = 0, y = 0}, tileSize)

            assert.are.same({x = 1, y = 1}, tilePosition)
        end)

        it('Keeps every pixel of a tile in the same tile', function ()
            local tilePosition = LevelGrid.convertPositionFromPixelsToGrid({x = 31.9, y = 31.9}, tileSize)

            assert.are.same({x = 1, y = 1}, tilePosition)
        end)

        it('Moves to the next tile at the tile border', function ()
            local tilePosition = LevelGrid.convertPositionFromPixelsToGrid({x = 32, y = 64}, tileSize)

            assert.are.same({x = 2, y = 3}, tilePosition)
        end)

        it('Supports tiles that are not squares', function ()
            local tilePosition = LevelGrid.convertPositionFromPixelsToGrid({x = 40, y = 20}, {width = 16, height = 8})

            assert.are.same({x = 3, y = 3}, tilePosition)
        end)

        it('Is the inverse of converting a tile center to pixels', function ()
            local tilePosition = {x = 7, y = 4}
            local pixelPosition = LevelGrid.convertPositionFromGridToPixels(tilePosition, tileSize, true)

            assert.are.same(tilePosition, LevelGrid.convertPositionFromPixelsToGrid(pixelPosition, tileSize))
        end)
    end)

    describe('LevelGrid:convertPositionToGrid(pixelPosition)', function ()
        it('Converts using the tile size of the grid', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            assert.are.same({x = 3, y = 3}, levelGrid:convertPositionToGrid({x = 40, y = 20}))
        end)
    end)

    describe('LevelGrid:convertPositionAndSizeFromPixelsToGrid(pixelPosition, objectSizeInPixels)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns a single tile for an object aligned with one tile', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 0, y = 0}, {width = 32, height = 32})

            assert.are.same({{x = 1, y = 1}}, positions)
        end)

        it('Doesnt include the next tile when the object ends exactly at the tile border', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 32, y = 0}, {width = 32, height = 32})

            assert.are.same({{x = 2, y = 1}}, positions)
        end)

        it('Returns every tile covered by an object bigger than a tile', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 0, y = 0}, {width = 96, height = 64})

            assert.are.equals(6, #positions)
            for x = 1, 3 do
                for y = 1, 2 do
                    assert(containsPosition(positions, x, y), 'Missing tile ' .. x .. ', ' .. y .. '.')
                end
            end
        end)

        it('Returns every tile touched by an object that is not aligned with the tiles', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 16, y = 16}, {width = 32, height = 32})

            assert.are.equals(4, #positions)
            assert(containsPosition(positions, 1, 1), 'Missing tile 1, 1.')
            assert(containsPosition(positions, 2, 1), 'Missing tile 2, 1.')
            assert(containsPosition(positions, 1, 2), 'Missing tile 1, 2.')
            assert(containsPosition(positions, 2, 2), 'Missing tile 2, 2.')
        end)

        it('Ignores the tiles before the start of the grid', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = -16, y = -16}, {width = 32, height = 32})

            assert.are.same({{x = 1, y = 1}}, positions)
        end)

        it('Ignores the tiles after the end of the grid', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 288, y = 288}, {width = 64, height = 64})

            assert.are.same({{x = 10, y = 10}}, positions)
        end)

        it('Returns no tiles for an object completely outside of the grid', function ()
            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 1000, y = 1000}, {width = 32, height = 32})

            assert.are.same({}, positions)
        end)

        it('Uses the tile size of the grid', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            local positions = levelGrid:convertPositionAndSizeFromPixelsToGrid({x = 16, y = 8}, {width = 32, height = 16})

            assert.are.equals(4, #positions)
            assert(containsPosition(positions, 2, 2), 'Missing tile 2, 2.')
            assert(containsPosition(positions, 3, 2), 'Missing tile 3, 2.')
            assert(containsPosition(positions, 2, 3), 'Missing tile 2, 3.')
            assert(containsPosition(positions, 3, 3), 'Missing tile 3, 3.')
        end)
    end)

    describe('LevelGrid:isInside(targetTilePosition, anchorTilePosition, sizeInTiles)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns true for the anchor tile', function ()
            assert.is_true(levelGrid:isInside({x = 3, y = 2}, {x = 3, y = 2}, {width = 1, height = 1}))
        end)

        it('Returns true for any tile of an object bigger than a tile', function ()
            local size = {width = 3, height = 3}

            assert.is_true(levelGrid:isInside({x = 2, y = 2}, {x = 1, y = 1}, size))
            assert.is_true(levelGrid:isInside({x = 3, y = 3}, {x = 1, y = 1}, size))
            assert.is_true(levelGrid:isInside({x = 3, y = 1}, {x = 1, y = 1}, size))
        end)

        it('Returns false for a tile next to a 1x1 object', function ()
            assert.is_false(levelGrid:isInside({x = 4, y = 2}, {x = 3, y = 2}, {width = 1, height = 1}))
            assert.is_false(levelGrid:isInside({x = 2, y = 2}, {x = 3, y = 2}, {width = 1, height = 1}))
        end)

        it('Returns false for the tiles right after an object bigger than a tile', function ()
            local size = {width = 2, height = 2}

            assert.is_false(levelGrid:isInside({x = 5, y = 3}, {x = 3, y = 3}, size))
            assert.is_false(levelGrid:isInside({x = 3, y = 5}, {x = 3, y = 3}, size))
        end)

        it('Returns false for the tiles right before an object bigger than a tile', function ()
            local size = {width = 2, height = 2}

            assert.is_false(levelGrid:isInside({x = 2, y = 3}, {x = 3, y = 3}, size))
            assert.is_false(levelGrid:isInside({x = 3, y = 2}, {x = 3, y = 3}, size))
        end)

        it('Uses the width for x and the height for y', function ()
            local size = {width = 3, height = 1}

            assert.is_true(levelGrid:isInside({x = 5, y = 3}, {x = 3, y = 3}, size))
            assert.is_false(levelGrid:isInside({x = 3, y = 4}, {x = 3, y = 3}, size))
        end)
    end)

    describe('LevelGrid:isWalkable(tilePosition)', function ()
        it('Returns true for a free tile', function ()
            local levelGrid = createLevelGrid()

            assert.is_true(levelGrid:isWalkable({x = 1, y = 1}))
        end)

        it('Returns false for a tile occupied by a grid object', function ()
            local levelGrid = createLevelGrid()
            placeGridObject(levelGrid, {x = 2, y = 1}, nil, 3)

            assert.is_false(levelGrid:isWalkable({x = 2, y = 1}))
        end)

        it('Returns false for a tile that is a wall', function ()
            local levelGrid = createLevelGrid()
            levelGrid:setTile({x = 2, y = 1}, 9)

            assert.is_false(levelGrid:isWalkable({x = 2, y = 1}))
        end)

        it('Returns true again after the grid object is removed', function ()
            local levelGrid = createLevelGrid()
            local gridObject = placeGridObject(levelGrid, {x = 2, y = 1}, nil, 3)

            levelGrid:remove(gridObject)

            assert.is_true(levelGrid:isWalkable({x = 2, y = 1}))
        end)

        it('Considers the free tile value as walkable', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})

            assert.is_true(levelGrid:isWalkable({x = 1, y = 1}))
        end)

        it('Returns true for the tiles at the edges of the grid', function ()
            local levelGrid = createLevelGrid()

            assert.is_true(levelGrid:isWalkable({x = 1, y = 1}))
            assert.is_true(levelGrid:isWalkable({x = 10, y = 1}))
            assert.is_true(levelGrid:isWalkable({x = 1, y = 10}))
            assert.is_true(levelGrid:isWalkable({x = 10, y = 10}))
        end)

        it('Returns false for tiles outside of the grid', function ()
            local levelGrid = createLevelGrid()

            for i, tilePosition in ipairs(tilesOutsideOfGrid) do
                local tileName = tilePosition.x .. ', ' .. tilePosition.y
                local ok, isWalkable = pcall(levelGrid.isWalkable, levelGrid, tilePosition)

                assert(ok, 'Failed for tile ' .. tileName .. ': ' .. tostring(isWalkable))
                assert.is_false(isWalkable, 'Tile ' .. tileName .. ' is outside of the grid.')
            end
        end)

        it('Returns false for tiles outside of a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            assert.is_true(levelGrid:isWalkable({x = 4, y = 2}))
            assert.is_false(levelGrid:isWalkable({x = 5, y = 2}))
            assert.is_false(levelGrid:isWalkable({x = 4, y = 3}))
        end)
    end)

    describe('LevelGrid:isTilePositionValid(tilePosition)', function ()
        it('Returns true for the tiles at the corners of the grid', function ()
            local levelGrid = createLevelGrid()

            assert.is_true(levelGrid:isTilePositionValid({x = 1, y = 1}))
            assert.is_true(levelGrid:isTilePositionValid({x = 10, y = 1}))
            assert.is_true(levelGrid:isTilePositionValid({x = 1, y = 10}))
            assert.is_true(levelGrid:isTilePositionValid({x = 10, y = 10}))
        end)

        it('Returns true for a tile in the middle of the grid', function ()
            local levelGrid = createLevelGrid()

            assert.is_true(levelGrid:isTilePositionValid({x = 5, y = 5}))
        end)

        it('Returns false for tiles outside of the grid', function ()
            local levelGrid = createLevelGrid()

            for i, tilePosition in ipairs(tilesOutsideOfGrid) do
                assert.is_false(levelGrid:isTilePositionValid(tilePosition),
                    'Tile ' .. tilePosition.x .. ', ' .. tilePosition.y .. ' is outside of the grid.')
            end
        end)

        it('Uses the width for x and the height for y in a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            assert.is_true(levelGrid:isTilePositionValid({x = 4, y = 2}))
            assert.is_false(levelGrid:isTilePositionValid({x = 5, y = 2}))
            assert.is_false(levelGrid:isTilePositionValid({x = 4, y = 3}))
        end)
    end)

    describe('LevelGrid:getTile(tilePosition)', function ()
        it('Returns the free tile value for a free tile', function ()
            local levelGrid = createLevelGrid()

            assert.are.equals(0, levelGrid:getTile({x = 5, y = 5}))
        end)

        it('Returns the number of the grid object that occupies the tile', function ()
            local levelGrid = createLevelGrid()
            placeGridObject(levelGrid, {x = 2, y = 1}, nil, 3)

            assert.are.equals(3, levelGrid:getTile({x = 2, y = 1}))
        end)

        it('Returns the free tile value of the grid when it is not 0', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})

            assert.are.equals(7, levelGrid:getTile({x = 5, y = 5}))
        end)

        it('Reads the grid as grid[y][x]', function ()
            local levelGrid = createLevelGrid()
            levelGrid._grid[2][5] = 9

            assert.are.equals(9, levelGrid:getTile({x = 5, y = 2}))
        end)

        it('Returns the tiles at the edges of the grid', function ()
            local levelGrid = createLevelGrid()
            levelGrid._grid[1][10] = 4
            levelGrid._grid[10][1] = 5

            assert.are.equals(4, levelGrid:getTile({x = 10, y = 1}))
            assert.are.equals(5, levelGrid:getTile({x = 1, y = 10}))
        end)

        it('Returns nil for tiles outside of the grid', function ()
            local levelGrid = createLevelGrid()

            for i, tilePosition in ipairs(tilesOutsideOfGrid) do
                local tileName = tilePosition.x .. ', ' .. tilePosition.y
                local ok, tile = pcall(levelGrid.getTile, levelGrid, tilePosition)

                assert(ok, 'Failed for tile ' .. tileName .. ': ' .. tostring(tile))
                assert.is_nil(tile, 'Tile ' .. tileName .. ' is outside of the grid.')
            end
        end)

        it('Returns nil for tiles outside of a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            assert.are.equals(0, levelGrid:getTile({x = 4, y = 2}))
            assert.is_nil(levelGrid:getTile({x = 5, y = 2}))
            assert.is_nil(levelGrid:getTile({x = 4, y = 3}))
        end)
    end)

    describe('LevelGrid:getOccupantInTile(tilePosition)', function ()
        it('Returns nil for a free tile', function ()
            local levelGrid = createLevelGrid()

            assert.is_nil(levelGrid:getOccupantInTile({x = 5, y = 5}))
        end)

        it('Returns the grid object that occupies the tile', function ()
            local levelGrid = createLevelGrid()
            local gridObject = placeGridObject(levelGrid, {x = 5, y = 5})

            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 5, y = 5}))
        end)

        it('Returns the grid object for every tile it occupies', function ()
            local levelGrid = createLevelGrid()
            local gridObject = placeGridObject(levelGrid, {x = 5, y = 5}, {width = 2, height = 2})

            for x = 5, 6 do
                for y = 5, 6 do
                    assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = x, y = y}))
                end
            end
        end)

        it('Returns the occupant of each tile when there are many objects', function ()
            local levelGrid = createLevelGrid()
            local first = placeGridObject(levelGrid, {x = 2, y = 2})
            local second = placeGridObject(levelGrid, {x = 3, y = 2}, nil, 3)

            assert.are.equals(first, levelGrid:getOccupantInTile({x = 2, y = 2}))
            assert.are.equals(second, levelGrid:getOccupantInTile({x = 3, y = 2}))
        end)

        it('Reads the occupants as occupants[y][x]', function ()
            local levelGrid = createLevelGrid()
            local gridObject = createGridObject()
            levelGrid._occupants[2][5] = gridObject

            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 5, y = 2}))
        end)

        it('Returns nil for a tile that is a wall', function ()
            local levelGrid = createLevelGrid()
            levelGrid:setTile({x = 5, y = 5}, 9)

            assert.is_nil(levelGrid:getOccupantInTile({x = 5, y = 5}))
        end)

        it('Returns nil after the grid object is removed', function ()
            local levelGrid = createLevelGrid()
            local gridObject = placeGridObject(levelGrid, {x = 5, y = 5})

            levelGrid:remove(gridObject)

            assert.is_nil(levelGrid:getOccupantInTile({x = 5, y = 5}))
        end)

        it('Returns nil for tiles outside of the grid', function ()
            local levelGrid = createLevelGrid()

            for i, tilePosition in ipairs(tilesOutsideOfGrid) do
                local tileName = tilePosition.x .. ', ' .. tilePosition.y
                local ok, occupant = pcall(levelGrid.getOccupantInTile, levelGrid, tilePosition)

                assert(ok, 'Failed for tile ' .. tileName .. ': ' .. tostring(occupant))
                assert.is_nil(occupant, 'Tile ' .. tileName .. ' is outside of the grid.')
            end
        end)

        it('Returns nil for tiles outside of a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            assert.is_nil(levelGrid:getOccupantInTile({x = 5, y = 2}))
            assert.is_nil(levelGrid:getOccupantInTile({x = 4, y = 3}))
        end)
    end)

    describe('LevelGrid:setTile(tilePosition, newValue)', function ()
        it('Sets the value of the tile', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setTile({x = 3, y = 4}, 5)

            assert.are.equals(5, levelGrid:getTile({x = 3, y = 4}))
        end)

        it('Writes the grid as grid[y][x]', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setTile({x = 5, y = 2}, 9)

            assert.are.equals(9, levelGrid._grid[2][5])
        end)

        it('Only changes the given tile', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setTile({x = 3, y = 4}, 5)

            assert.are.equals(1, countOccupiedTiles(levelGrid))
        end)

        it('Sets the tiles at the edges of the grid', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setTile({x = 1, y = 1}, 2)
            levelGrid:setTile({x = 10, y = 1}, 3)
            levelGrid:setTile({x = 1, y = 10}, 4)
            levelGrid:setTile({x = 10, y = 10}, 5)

            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(3, levelGrid._grid[1][10])
            assert.are.equals(4, levelGrid._grid[10][1])
            assert.are.equals(5, levelGrid._grid[10][10])
        end)

        it('Overwrites a tile occupied by a grid object', function ()
            local levelGrid = createLevelGrid()
            placeGridObject(levelGrid, {x = 2, y = 2}, nil, 3)

            levelGrid:setTile({x = 2, y = 2}, 6)

            assert.are.equals(6, levelGrid:getTile({x = 2, y = 2}))
        end)

        it('Makes a free tile not walkable', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setTile({x = 2, y = 2}, 6)

            assert.is_false(levelGrid:isWalkable({x = 2, y = 2}))
        end)

        it('Makes an occupied tile walkable when set to the free tile value', function ()
            local levelGrid = createLevelGrid()
            placeGridObject(levelGrid, {x = 2, y = 2}, nil, 3)

            levelGrid:setTile({x = 2, y = 2}, levelGrid._freeTileValue)

            assert.is_true(levelGrid:isWalkable({x = 2, y = 2}))
        end)

        it('Accepts the free tile value of the grid when it is not 0', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})

            levelGrid:setTile({x = 2, y = 2}, 6)
            levelGrid:setTile({x = 2, y = 2}, 7)

            assert.is_true(levelGrid:isWalkable({x = 2, y = 2}))
        end)

        it('Doesnt change the occupant of the tile', function ()
            local levelGrid = createLevelGrid()
            local gridObject = placeGridObject(levelGrid, {x = 2, y = 2})

            levelGrid:setTile({x = 2, y = 2}, 6)

            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 2, y = 2}))
        end)

        it('Changes the result of isAreaFree', function ()
            local levelGrid = createLevelGrid()
            assert.is_true(levelGrid:isAreaFree({x = 2, y = 2}, {width = 2, height = 2}))

            levelGrid:setTile({x = 3, y = 3}, 6)

            assert.is_false(levelGrid:isAreaFree({x = 2, y = 2}, {width = 2, height = 2}))
        end)

        it('Ignores tiles outside of the grid', function ()
            local levelGrid = createLevelGrid()

            for i, tilePosition in ipairs(tilesOutsideOfGrid) do
                local tileName = tilePosition.x .. ', ' .. tilePosition.y
                local ok, err = pcall(levelGrid.setTile, levelGrid, tilePosition, 5)

                assert(ok, 'Failed for tile ' .. tileName .. ': ' .. tostring(err))
            end

            assert.are.equals(0, countOccupiedTiles(levelGrid), 'A tile inside of the grid was changed.')
        end)

        it('Ignores tiles outside of a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            levelGrid:setTile({x = 5, y = 2}, 5)
            levelGrid:setTile({x = 4, y = 3}, 5)
            assert.are.equals(0, countOccupiedTiles(levelGrid), 'A tile inside of the grid was changed.')

            levelGrid:setTile({x = 4, y = 2}, 5)
            assert.are.equals(5, levelGrid:getTile({x = 4, y = 2}))
        end)

        it('Makes the pathfinder avoid the tile without recreating it', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            local pathfinder = levelGrid.pathfinder
            assert.is_true(containsPosition(getPathfinderTiles(levelGrid, 1, 1, 3, 1), 2, 1), 'Path should be straight.')

            levelGrid:setTile({x = 2, y = 1}, 6)

            local tiles = getPathfinderTiles(levelGrid, 1, 1, 3, 1)
            assert.are.equals(pathfinder, levelGrid.pathfinder)
            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through the tile that was set.')
        end)
    end)

    describe('LevelGrid:setOccupantInTile(tilePosition, newOccupant)', function ()
        it('Sets the occupant of the tile', function ()
            local levelGrid = createLevelGrid()
            local gridObject = createGridObject()

            levelGrid:setOccupantInTile({x = 3, y = 4}, gridObject)

            assert.are.equals(gridObject, levelGrid:getOccupantInTile({x = 3, y = 4}))
        end)

        it('Writes the occupants as occupants[y][x]', function ()
            local levelGrid = createLevelGrid()
            local gridObject = createGridObject()

            levelGrid:setOccupantInTile({x = 5, y = 2}, gridObject)

            assert.are.equals(gridObject, levelGrid._occupants[2][5])
        end)

        it('Only changes the given tile', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})

            levelGrid:setOccupantInTile({x = 2, y = 2}, createGridObject())

            for x = 1, 3 do
                for y = 1, 3 do
                    if x ~= 2 or y ~= 2 then
                        assert.is_nil(levelGrid:getOccupantInTile({x = x, y = y}), 'Tile ' .. x .. ', ' .. y .. ' has an occupant.')
                    end
                end
            end
        end)

        it('Removes the occupant when set to nil', function ()
            local levelGrid = createLevelGrid()
            levelGrid:setOccupantInTile({x = 3, y = 4}, createGridObject())

            levelGrid:setOccupantInTile({x = 3, y = 4}, nil)

            assert.is_nil(levelGrid:getOccupantInTile({x = 3, y = 4}))
        end)

        it('Replaces the occupant of the tile', function ()
            local levelGrid = createLevelGrid()
            local second = createGridObject()
            levelGrid:setOccupantInTile({x = 3, y = 4}, createGridObject())

            levelGrid:setOccupantInTile({x = 3, y = 4}, second)

            assert.are.equals(second, levelGrid:getOccupantInTile({x = 3, y = 4}))
        end)

        it('Doesnt change the value of the tile', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setOccupantInTile({x = 3, y = 4}, createGridObject())

            assert.are.equals(0, levelGrid:getTile({x = 3, y = 4}))
        end)

        it('Sets the tiles at the edges of the grid', function ()
            local levelGrid = createLevelGrid()
            local first, second = createGridObject(), createGridObject()

            levelGrid:setOccupantInTile({x = 1, y = 1}, first)
            levelGrid:setOccupantInTile({x = 10, y = 10}, second)

            assert.are.equals(first, levelGrid._occupants[1][1])
            assert.are.equals(second, levelGrid._occupants[10][10])
        end)

        it('Ignores tiles outside of the grid', function ()
            local levelGrid = createLevelGrid()

            for i, tilePosition in ipairs(tilesOutsideOfGrid) do
                local tileName = tilePosition.x .. ', ' .. tilePosition.y
                local ok, err = pcall(levelGrid.setOccupantInTile, levelGrid, tilePosition, createGridObject())

                assert(ok, 'Failed for tile ' .. tileName .. ': ' .. tostring(err))
            end

            for y = 1, 10 do
                for x = 1, 10 do
                    assert.is_nil(levelGrid._occupants[y][x], 'A tile inside of the grid was changed.')
                end
            end
        end)

        it('Ignores tiles outside of a grid that is not a square', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 2}})

            levelGrid:setOccupantInTile({x = 5, y = 2}, createGridObject())
            levelGrid:setOccupantInTile({x = 4, y = 3}, createGridObject())

            for y = 1, 2 do
                for x = 1, 4 do
                    assert.is_nil(levelGrid._occupants[y][x], 'A tile inside of the grid was changed.')
                end
            end
        end)
    end)

    describe('LevelGrid:isAreaFree(tilePosition, sizeInTiles, entitiesToIgnore)', function ()
        local createLevelGridWithObstacleAt = function (position, size, numberOnGrid)
            local levelGrid = createLevelGrid()
            local obstacle = placeGridObject(levelGrid, position, size, numberOnGrid)

            return levelGrid, obstacle
        end

        it('Returns false when there is no tile position', function ()
            local levelGrid = createLevelGrid()

            assert.is_false(levelGrid:isAreaFree(nil))
        end)

        it('Returns true for a free tile', function ()
            local levelGrid = createLevelGrid()

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}))
        end)

        it('Defaults the area to a single tile', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 2, y = 1})

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}))
        end)

        it('Returns false for a tile occupied by a grid object', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 1, y = 1})

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}))
        end)

        it('Returns false for a tile that is a wall', function ()
            local levelGrid = createLevelGrid()
            levelGrid:setTile({x = 1, y = 1}, 9)

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}))
        end)

        it('Returns false when any tile of the area is occupied', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 2, y = 2})

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}, {width = 2, height = 2}))
        end)

        it('Returns true when every tile of the area is free', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 4, y = 4})

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}, {width = 2, height = 2}))
        end)

        it('Ignores the grid objects listed in entitiesToIgnore', function ()
            local levelGrid, obstacle = createLevelGridWithObstacleAt({x = 1, y = 1})

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}, {width = 1, height = 1}, {obstacle}))
        end)

        it('Doesnt ignore the grid objects that are not listed in entitiesToIgnore', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 1, y = 1})
            local other = createGridObject()

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}, {width = 1, height = 1}, {other}))
        end)

        it('Ignores a grid object by its reference and not by its number', function ()
            local levelGrid = createLevelGrid()
            local first = placeGridObject(levelGrid, {x = 1, y = 1}, nil, 3)
            placeGridObject(levelGrid, {x = 2, y = 1}, nil, 3)

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}, {width = 1, height = 1}, {first}))
            assert.is_false(levelGrid:isAreaFree({x = 2, y = 1}, {width = 1, height = 1}, {first}))
        end)

        it('Returns false when only some of the obstacles of the area are ignored', function ()
            local levelGrid = createLevelGrid()
            local first = placeGridObject(levelGrid, {x = 1, y = 1}, nil, 3)
            placeGridObject(levelGrid, {x = 2, y = 1}, nil, 4)

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}, {width = 2, height = 1}, {first}))
        end)

        it('Returns true when every obstacle of the area is ignored', function ()
            local levelGrid = createLevelGrid()
            local first = placeGridObject(levelGrid, {x = 1, y = 1}, nil, 3)
            local second = placeGridObject(levelGrid, {x = 2, y = 1}, nil, 4)

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}, {width = 2, height = 1}, {first, second}))
        end)

        it('Doesnt ignore walls, which have no occupant', function ()
            local levelGrid = createLevelGrid()
            levelGrid:setTile({x = 1, y = 1}, 9)

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}, {width = 1, height = 1}, {createGridObject()}))
        end)

        it('Checks the area starting at the given tile position', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 1, y = 1})

            assert.is_true(levelGrid:isAreaFree({x = 5, y = 5}, {width = 2, height = 2}), 'An obstacle outside of the area was considered.')
        end)

        it('Returns false when an obstacle is inside an area that doesnt start at the first tile', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 5, y = 5})

            assert.is_false(levelGrid:isAreaFree({x = 4, y = 4}, {width = 2, height = 2}), 'An obstacle inside of the area was ignored.')
        end)

        it('Considers every tile of an obstacle bigger than a tile', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 3, y = 3}, {width = 3, height = 3})

            assert.is_false(levelGrid:isAreaFree({x = 5, y = 5}, {width = 1, height = 1}))
            assert.is_true(levelGrid:isAreaFree({x = 6, y = 6}, {width = 1, height = 1}))
        end)

        it('Returns false for an area that goes beyond the grid', function ()
            local levelGrid = createLevelGrid()

            local areasBeyondGrid = {
                {tilePosition = {x = 10, y = 1}, sizeInTiles = {width = 2, height = 1}},
                {tilePosition = {x = 1, y = 10}, sizeInTiles = {width = 1, height = 2}},
                {tilePosition = {x = 10, y = 10}, sizeInTiles = {width = 2, height = 2}},
                {tilePosition = {x = 0, y = 0}, sizeInTiles = {width = 2, height = 2}}
            }
            for i, area in ipairs(areasBeyondGrid) do
                local ok, isAreaFree = pcall(levelGrid.isAreaFree, levelGrid, area.tilePosition, area.sizeInTiles)

                assert(ok, 'Failed for area ' .. i .. ': ' .. tostring(isAreaFree))
                assert.is_false(isAreaFree, 'Area ' .. i .. ' goes beyond the grid.')
            end
        end)
    end)

    describe('LevelGrid.pathfinder', function ()
        local createWall = function (levelGrid, position, size)
            return placeGridObject(levelGrid, position, size, 9)
        end

        it('Finds a straight path in an empty grid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})

            local tiles = getPathfinderTiles(levelGrid, 1, 1, 3, 1)

            assert.are.equals(3, #tiles)
            assert.are.same({x = 1, y = 1}, tiles[1])
            assert.are.same({x = 3, y = 1}, tiles[#tiles])
        end)

        it('Avoids the tiles occupied by grid objects', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            createWall(levelGrid, {x = 2, y = 1})

            local tiles = getPathfinderTiles(levelGrid, 1, 1, 3, 1)

            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through a grid object.')
            assert.are.same({x = 3, y = 1}, tiles[#tiles])
        end)

        it('Doesnt find a path when the target is walled off', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            createWall(levelGrid, {x = 2, y = 1}, {width = 1, height = 3})

            assert.is_nil(getPathfinderTiles(levelGrid, 1, 1, 3, 1))
        end)

        it('Doesnt find a path to a tile occupied by a grid object', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            createWall(levelGrid, {x = 3, y = 1})

            assert.is_nil(getPathfinderTiles(levelGrid, 1, 1, 3, 1))
        end)

        it('Sees the grid objects that moved without being recreated', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            local wall = createWall(levelGrid, {x = 2, y = 1})
            local pathfinder = levelGrid.pathfinder
            assert.is_false(containsPosition(getPathfinderTiles(levelGrid, 1, 1, 3, 1), 2, 1), 'Path goes through a grid object.')

            levelGrid:move(wall, {x = 2, y = 3})

            assert.are.equals(pathfinder, levelGrid.pathfinder)
            assert.is_true(containsPosition(getPathfinderTiles(levelGrid, 1, 1, 3, 1), 2, 1), 'Path didnt use the tile that was freed.')
        end)

        it('Sees the grid objects that were removed without being recreated', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})
            local wall = createWall(levelGrid, {x = 2, y = 1}, {width = 1, height = 3})
            assert.is_nil(getPathfinderTiles(levelGrid, 1, 1, 3, 1))

            levelGrid:remove(wall)

            assert(getPathfinderTiles(levelGrid, 1, 1, 3, 1) ~= nil, 'Path not found after the grid object was removed.')
        end)

        it('Treats the free tile value as walkable', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}, freeTileValue = 7})

            local tiles = getPathfinderTiles(levelGrid, 1, 1, 3, 1)

            assert(tiles ~= nil, 'Path not found in a grid where every tile is free.')
        end)
    end)
end)
