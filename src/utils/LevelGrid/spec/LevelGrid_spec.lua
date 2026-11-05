require 'dependencies'

describe('LevelGrid class tests', function ()
    local createEntity = function (position, size)
        local entity = {
            position = position or {x = 0, y = 0},
            size = size or {width = 32, height = 32}
        }
        function entity:getPosition() return self.position end
        function entity:getSize() return self.size end
        return entity
    end

    local createLevelGrid = function (def)
        local def = def or {}

        return LevelGrid {
            tileSize = def.tileSize or {width = 32, height = 32},
            gridSize = def.gridSize or {width = 10, height = 10},
            freeTileValue = def.freeTileValue,
            objects = def.objects or {}
        }
    end

    local containsPosition = function (positions, x, y)
        for i, position in ipairs(positions) do
            if position.x == x and position.y == y then
                return true
            end
        end

        return false
    end

    -- Tiles outside of a 10x10 grid, as created by `createLevelGrid` by default
    local tilesOutsideOfGrid = {
        {x = 0, y = 1}, {x = 11, y = 1}, {x = 1, y = 0}, {x = 1, y = 11}, {x = -1, y = -1}, {x = 11, y = 11}
    }

    local getPathTiles = function (levelGrid, startX, startY, endX, endY)
        local path = levelGrid.pathfinder:getPath(startX, startY, endX, endY)
        if not path then return nil end

        path:fill()
        local tiles = {}
        for node, count in path:iter() do
            tiles[#tiles + 1] = {x = node:getX(), y = node:getY()}
        end

        return tiles
    end

    describe('LevelGrid:init(def)', function ()
        it('Correctly initializes tile size', function ()
            local levelGrid = createLevelGrid({tileSize = {width = 16, height = 8}})

            assert.are.same({width = 16, height = 8}, levelGrid._tileSize)
        end)

        it('Defaults tile size to TILE_SIZE', function ()
            local levelGrid = LevelGrid {objects = {}}

            assert.are.same({width = TILE_SIZE, height = TILE_SIZE}, levelGrid._tileSize)
        end)

        it('Correctly initializes grid size', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 4, height = 4}})

            assert.are.same({width = 4, height = 4}, levelGrid._gridSize)
        end)

        it('Defaults grid size to GRID_SIZE', function ()
            local levelGrid = LevelGrid {objects = {}}

            assert.are.same({width = GRID_SIZE, height = GRID_SIZE}, levelGrid._gridSize)
        end)

        it('Correctly initializes free tile value', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})

            assert.are.equals(7, levelGrid._freeTileValue)
        end)

        it('Defaults free tile value to 0', function ()
            local levelGrid = createLevelGrid()

            assert.are.equals(0, levelGrid._freeTileValue)
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

        it('Correctly initializes the grid objects', function ()
            local entity = createEntity()
            local levelGrid = createLevelGrid({objects = {
                player = {numberOnGrid = 2, items = {entity}}
            }})

            assert.are.equals(2, levelGrid._gridObjects['player'].numberOnGrid)
            assert.are.equals(entity, levelGrid._gridObjects['player'].items[entity].ref)
        end)

        it('Marks the tiles occupied by the initial grid objects', function ()
            local entity = createEntity({x = 32, y = 32})
            local levelGrid = createLevelGrid({objects = {
                player = {numberOnGrid = 2, items = {entity}}
            }})

            assert.are.equals(2, levelGrid._grid[2][2])
            assert.are.equals(0, levelGrid._grid[1][1])
            assert.are.equals(0, levelGrid._grid[2][1])
            assert.are.equals(0, levelGrid._grid[1][2])
            assert.are.equals(0, levelGrid._grid[3][3])
        end)

        it('Marks every tile occupied by an item bigger than a tile', function ()
            local entity = createEntity({x = 0, y = 0}, {width = 64, height = 96})
            local levelGrid = createLevelGrid({objects = {
                boss = {numberOnGrid = 3, items = {entity}}
            }})

            for y = 1, 3 do
                for x = 1, 2 do
                    assert.are.equals(3, levelGrid._grid[y][x])
                end
            end
            assert.are.equals(0, levelGrid._grid[4][1])
            assert.are.equals(0, levelGrid._grid[1][3])
        end)

        it('Doesnt mark the tiles of items rejected by shouldAddItem', function ()
            local acceptedEntity = createEntity({x = 0, y = 0})
            local rejectedEntity = createEntity({x = 128, y = 128})
            local levelGrid = createLevelGrid({objects = {
                enemy = {
                    numberOnGrid = 2,
                    items = {acceptedEntity, rejectedEntity},
                    shouldAddItem = function (item) return item:getPosition().x < 100 end
                }
            }})

            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(0, levelGrid._grid[5][5])
        end)

        it('Marks different grid objects with their own numbers', function ()
            local player = createEntity({x = 0, y = 0})
            local enemy = createEntity({x = 64, y = 0})
            local levelGrid = createLevelGrid({objects = {
                player = {numberOnGrid = 2, items = {player}},
                enemy = {numberOnGrid = 3, items = {enemy}}
            }})

            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(3, levelGrid._grid[1][3])
        end)

        it('Correctly initializes the pathfinder', function ()
            local levelGrid = createLevelGrid()

            assert(levelGrid.pathfinder ~= nil, 'Pathfinder not initialized.')
            assert.are.equals('JPS', levelGrid.pathfinder:getFinder())
            assert.are.equals('ORTHOGONAL', levelGrid.pathfinder:getMode())
        end)

        it('Accepts a definition without objects', function ()
            local levelGrid
            assert.has_no.errors(function () levelGrid = LevelGrid {} end)

            assert.are.equals(0, tablelength(levelGrid._gridObjects))
            assert.is_true(levelGrid:isWalkable({x = 1, y = 1}))
        end)
    end)

    describe('LevelGrid:addGridObject(key, object)', function ()
        it('Registers the grid object under the given key', function ()
            local levelGrid = createLevelGrid()

            levelGrid:addGridObject('enemy', {numberOnGrid = 3, items = {}})

            assert(levelGrid._gridObjects['enemy'] ~= nil, 'Grid object not registered.')
            assert.are.equals(3, levelGrid._gridObjects['enemy'].numberOnGrid)
        end)

        it('Wraps each item in a LevelGridObjectItem keyed by its reference', function ()
            local levelGrid = createLevelGrid()
            local entityA, entityB = createEntity(), createEntity()

            levelGrid:addGridObject('enemy', {items = {entityA, entityB}})

            local items = levelGrid._gridObjects['enemy'].items
            assert.are.equals(entityA, items[entityA].ref)
            assert.are.equals(entityB, items[entityB].ref)
            assert.are.equals(LevelGridObjectItem, getmetatable(items[entityA]))
        end)

        it('Accepts a grid object without items', function ()
            local levelGrid = createLevelGrid()

            levelGrid:addGridObject('enemy', {numberOnGrid = 3})

            assert.are.same({}, levelGrid._gridObjects['enemy'].items)
        end)

        it('Passes shouldAddItem to the grid object', function ()
            local levelGrid = createLevelGrid()
            local shouldAddItem = function (item) return false end

            levelGrid:addGridObject('enemy', {shouldAddItem = shouldAddItem})

            assert.are.equals(shouldAddItem, levelGrid._gridObjects['enemy'].shouldAddItem)
        end)

        it('Replaces a grid object registered with the same key', function ()
            local levelGrid = createLevelGrid()

            levelGrid:addGridObject('enemy', {numberOnGrid = 3})
            levelGrid:addGridObject('enemy', {numberOnGrid = 4})

            assert.are.equals(4, levelGrid._gridObjects['enemy'].numberOnGrid)
        end)
    end)

    describe('LevelGrid:deleteGridObject(key)', function ()
        it('Removes the grid object', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity()}}
            }})

            levelGrid:deleteGridObject('enemy')

            assert.is_nil(levelGrid._gridObjects['enemy'])
        end)

        it('Keeps the other grid objects', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity()}},
                player = {numberOnGrid = 2, items = {createEntity()}}
            }})

            levelGrid:deleteGridObject('enemy')

            assert(levelGrid._gridObjects['player'] ~= nil, 'Other grid object was removed.')
        end)

        it('Doesnt fail when the key doesnt exist', function ()
            local levelGrid = createLevelGrid()

            assert.has_no.errors(function () levelGrid:deleteGridObject('unknown') end)
        end)

        it('Frees the tiles occupied by the grid object', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 32, y = 32})}}
            }})
            assert.are.equals(3, levelGrid._grid[2][2])

            levelGrid:deleteGridObject('enemy')

            assert.are.equals(0, levelGrid._grid[2][2])
            assert.is_true(levelGrid:isWalkable({x = 2, y = 2}))
        end)

        it('Frees the tiles of every item of the grid object', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 0, y = 0}), createEntity({x = 128, y = 128})}}
            }})

            levelGrid:deleteGridObject('enemy')

            assert.are.equals(0, levelGrid._grid[1][1])
            assert.are.equals(0, levelGrid._grid[5][5])
        end)

        it('Frees every tile of an item bigger than a tile', function ()
            local levelGrid = createLevelGrid({objects = {
                boss = {numberOnGrid = 3, items = {createEntity({x = 0, y = 0}, {width = 64, height = 96})}}
            }})

            levelGrid:deleteGridObject('boss')

            for y = 1, 3 do
                for x = 1, 2 do
                    assert.are.equals(0, levelGrid._grid[y][x])
                end
            end
        end)

        it('Frees the tiles with the free tile value of the grid', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7, objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 0, y = 0})}}
            }})

            levelGrid:deleteGridObject('enemy')

            assert.are.equals(7, levelGrid._grid[1][1])
        end)

        it('Keeps the tiles of the other grid objects', function ()
            local levelGrid = createLevelGrid({objects = {
                player = {numberOnGrid = 2, items = {createEntity({x = 0, y = 0})}},
                enemy = {numberOnGrid = 3, items = {createEntity({x = 64, y = 0})}}
            }})

            levelGrid:deleteGridObject('enemy')

            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(0, levelGrid._grid[1][3])
        end)

        it('Doesnt change the grid when the key doesnt exist', function ()
            local levelGrid = createLevelGrid({objects = {
                player = {numberOnGrid = 2, items = {createEntity({x = 0, y = 0})}}
            }})

            levelGrid:deleteGridObject('unknown')

            assert.are.equals(2, levelGrid._grid[1][1])
        end)

        it('Frees the tiles of an item that moved since it was last updated', function ()
            local entity = createEntity({x = 0, y = 0})
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {entity}}
            }})
            entity.position = {x = 64, y = 64}
            levelGrid:updateGridObject('enemy', {entity})

            levelGrid:deleteGridObject('enemy')

            assert.are.equals(0, levelGrid._grid[1][1])
            assert.are.equals(0, levelGrid._grid[3][3])
        end)
    end)

    describe('LevelGrid:updateGridObject(gridObjectKey, updatedItemsRefs)', function ()
        local entity, levelGrid

        before_each(function ()
            entity = createEntity({x = 0, y = 0})
            levelGrid = createLevelGrid({objects = {
                player = {numberOnGrid = 2, items = {entity}}
            }})
        end)

        it('Marks the new tile position of an item that moved', function ()
            entity.position = {x = 64, y = 32}

            levelGrid:updateGridObject('player', {entity})

            assert.are.equals(2, levelGrid._grid[2][3])
        end)

        it('Frees the old tile position of an item that moved', function ()
            entity.position = {x = 64, y = 32}

            levelGrid:updateGridObject('player', {entity})

            assert.are.equals(0, levelGrid._grid[1][1])
        end)

        it('Keeps the item tiles when it didnt move', function ()
            levelGrid:updateGridObject('player', {entity})

            assert.are.equals(2, levelGrid._grid[1][1])
        end)

        it('Stores the tiles occupied by the item as its last tile positions', function ()
            entity.position = {x = 64, y = 32}

            levelGrid:updateGridObject('player', {entity})

            local lastTilePositions = levelGrid._gridObjects['player'].items[entity].lastTilePositions
            assert.are.equals(1, #lastTilePositions)
            assert.are.same({x = 3, y = 2}, lastTilePositions[1])
        end)

        it('Frees every old tile of an item bigger than a tile', function ()
            local boss = createEntity({x = 0, y = 64}, {width = 64, height = 64})
            levelGrid:addGridObject('boss', {numberOnGrid = 3, items = {boss}})
            levelGrid:updateGridObject('boss', {boss})
            assert.are.equals(3, levelGrid._grid[3][1])
            assert.are.equals(3, levelGrid._grid[4][2])

            boss.position = {x = 192, y = 192}
            levelGrid:updateGridObject('boss', {boss})

            assert.are.equals(0, levelGrid._grid[3][1])
            assert.are.equals(0, levelGrid._grid[4][2])
            assert.are.equals(3, levelGrid._grid[7][7])
            assert.are.equals(3, levelGrid._grid[8][8])
        end)

        it('Marks the tiles of an item added after initialization once it is updated', function ()
            local enemy = createEntity({x = 96, y = 96})
            levelGrid:addGridObject('enemy', {numberOnGrid = 3, items = {enemy}})

            levelGrid:updateGridObject('enemy', {enemy})

            assert.are.equals(3, levelGrid._grid[4][4])
        end)

        it('Only updates the given items', function ()
            local other = createEntity({x = 128, y = 128})
            levelGrid:addGridObject('enemy', {numberOnGrid = 3, items = {other}})
            levelGrid:updateGridObject('enemy', {other})

            entity.position = {x = 64, y = 32}
            other.position = {x = 0, y = 256}
            levelGrid:updateGridObject('player', {entity})

            assert.are.equals(3, levelGrid._grid[5][5], 'Item not listed was updated.')
            assert.are.equals(0, levelGrid._grid[9][1], 'Item not listed was updated.')
        end)

        it('Ignores references that are not in the grid object', function ()
            local stranger = createEntity({x = 256, y = 256})

            levelGrid:updateGridObject('player', {stranger})

            assert.are.equals(0, levelGrid._grid[9][9])
        end)

        it('Ignores grid objects that dont exist', function ()
            entity.position = {x = 64, y = 32}

            assert.has_no.errors(function () levelGrid:updateGridObject('unknown', {entity}) end)
            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(0, levelGrid._grid[2][3])
        end)

        it('Only marks the tiles inside the grid when the item is partially outside of it', function ()
            entity.position = {x = -16, y = -16}

            levelGrid:updateGridObject('player', {entity})

            assert.are.equals(2, levelGrid._grid[1][1])
            assert.are.equals(1, #levelGrid._gridObjects['player'].items[entity].lastTilePositions)
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

    describe('LevelGrid:isInside(tilePosition, pixelPosition, objectSizeInPixels)', function ()
        local levelGrid

        before_each(function ()
            levelGrid = createLevelGrid()
        end)

        it('Returns true for a tile covered by the object', function ()
            assert.is_true(levelGrid:isInside({x = 3, y = 2}, {x = 64, y = 32}, {width = 32, height = 32}))
        end)

        it('Returns true for any tile covered by an object bigger than a tile', function ()
            assert.is_true(levelGrid:isInside({x = 2, y = 2}, {x = 0, y = 0}, {width = 96, height = 96}))
        end)

        it('Returns false for a tile not covered by the object', function ()
            assert.is_false(levelGrid:isInside({x = 4, y = 2}, {x = 64, y = 32}, {width = 32, height = 32}))
        end)

        it('Returns false for the tile right after the object', function ()
            assert.is_false(levelGrid:isInside({x = 2, y = 1}, {x = 0, y = 0}, {width = 32, height = 32}))
        end)
    end)

    describe('LevelGrid:isWalkable(tilePosition)', function ()
        it('Returns true for a free tile', function ()
            local levelGrid = createLevelGrid()

            assert.is_true(levelGrid:isWalkable({x = 1, y = 1}))
        end)

        it('Returns false for a tile occupied by a grid object', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 32, y = 0})}}
            }})

            assert.is_false(levelGrid:isWalkable({x = 2, y = 1}))
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

    describe('LevelGrid:getTile(tilePosition)', function ()
        it('Returns the free tile value for a free tile', function ()
            local levelGrid = createLevelGrid()

            assert.are.equals(0, levelGrid:getTile({x = 5, y = 5}))
        end)

        it('Returns the number of the grid object that occupies the tile', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 32, y = 0})}}
            }})

            assert.are.equals(3, levelGrid:getTile({x = 2, y = 1}))
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

    describe('LevelGrid:setTile(tilePosition, newValue)', function ()
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
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 32, y = 32})}}
            }})

            levelGrid:setTile({x = 2, y = 2}, 6)

            assert.are.equals(6, levelGrid:getTile({x = 2, y = 2}))
        end)

        it('Makes a free tile not walkable', function ()
            local levelGrid = createLevelGrid()

            levelGrid:setTile({x = 2, y = 2}, 6)

            assert.is_false(levelGrid:isWalkable({x = 2, y = 2}))
        end)

        it('Makes an occupied tile walkable when set to the free tile value', function ()
            local levelGrid = createLevelGrid({objects = {
                enemy = {numberOnGrid = 3, items = {createEntity({x = 32, y = 32})}}
            }})

            levelGrid:setTile({x = 2, y = 2}, levelGrid._freeTileValue)

            assert.is_true(levelGrid:isWalkable({x = 2, y = 2}))
        end)

        it('Accepts the free tile value of the grid when it is not 0', function ()
            local levelGrid = createLevelGrid({freeTileValue = 7})

            levelGrid:setTile({x = 2, y = 2}, 6)
            levelGrid:setTile({x = 2, y = 2}, 7)

            assert.is_true(levelGrid:isWalkable({x = 2, y = 2}))
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
            assert.is_true(containsPosition(getPathTiles(levelGrid, 1, 1, 3, 1), 2, 1), 'Path should be straight.')

            levelGrid:setTile({x = 2, y = 1}, 6)

            local tiles = getPathTiles(levelGrid, 1, 1, 3, 1)
            assert.are.equals(pathfinder, levelGrid.pathfinder)
            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through the tile that was set.')
        end)
    end)

    describe('LevelGrid:isAreaFree(tilePosition, sizeInTiles, entitiesToIgnore)', function ()
        local createLevelGridWithObstacleAt = function (position, size)
            return createLevelGrid({objects = {
                obstacle = {numberOnGrid = 2, items = {createEntity(position, size)}}
            }})
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
            local levelGrid = createLevelGridWithObstacleAt({x = 32, y = 0})

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}))
        end)

        it('Returns false for a tile occupied by a grid object', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 0, y = 0})

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}))
        end)

        it('Returns false when any tile of the area is occupied', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 32, y = 32})

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}, {width = 2, height = 2}))
        end)

        it('Returns true when every tile of the area is free', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 96, y = 96})

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}, {width = 2, height = 2}))
        end)

        it('Ignores the grid objects listed in entitiesToIgnore', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 0, y = 0})

            assert.is_true(levelGrid:isAreaFree({x = 1, y = 1}, {width = 1, height = 1}, {2}))
        end)

        it('Doesnt ignore the grid objects that are not listed in entitiesToIgnore', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 0, y = 0})

            assert.is_false(levelGrid:isAreaFree({x = 1, y = 1}, {width = 1, height = 1}, {3}))
        end)

        it('Checks the area starting at the given tile position', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 0, y = 0})

            assert.is_true(levelGrid:isAreaFree({x = 5, y = 5}, {width = 2, height = 2}), 'An obstacle outside of the area was considered.')
        end)

        it('Returns false when an obstacle is inside an area that doesnt start at the first tile', function ()
            local levelGrid = createLevelGridWithObstacleAt({x = 128, y = 128})

            assert.is_false(levelGrid:isAreaFree({x = 4, y = 4}, {width = 2, height = 2}), 'An obstacle inside of the area was ignored.')
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
        local createWall = function (position, size)
            return {numberOnGrid = 9, items = {createEntity(position, size)}}
        end

        it('Finds a straight path in an empty grid', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}})

            local tiles = getPathTiles(levelGrid, 1, 1, 3, 1)

            assert.are.equals(3, #tiles)
            assert.are.same({x = 1, y = 1}, tiles[1])
            assert.are.same({x = 3, y = 1}, tiles[#tiles])
        end)

        it('Avoids the tiles occupied by grid objects', function ()
            local levelGrid = createLevelGrid({
                gridSize = {width = 3, height = 3},
                objects = {wall = createWall({x = 32, y = 0})}
            })

            local tiles = getPathTiles(levelGrid, 1, 1, 3, 1)

            assert(tiles ~= nil, 'Path not found.')
            assert.is_false(containsPosition(tiles, 2, 1), 'Path goes through a grid object.')
            assert.are.same({x = 3, y = 1}, tiles[#tiles])
        end)

        it('Doesnt find a path when the target is walled off', function ()
            local levelGrid = createLevelGrid({
                gridSize = {width = 3, height = 3},
                objects = {wall = createWall({x = 32, y = 0}, {width = 32, height = 96})}
            })

            assert.is_nil(getPathTiles(levelGrid, 1, 1, 3, 1))
        end)

        it('Doesnt find a path to a tile occupied by a grid object', function ()
            local levelGrid = createLevelGrid({
                gridSize = {width = 3, height = 3},
                objects = {wall = createWall({x = 64, y = 0})}
            })

            assert.is_nil(getPathTiles(levelGrid, 1, 1, 3, 1))
        end)

        it('Sees the grid objects that moved without being recreated', function ()
            local wall = createEntity({x = 32, y = 0})
            local levelGrid = createLevelGrid({
                gridSize = {width = 3, height = 3},
                objects = {wall = {numberOnGrid = 9, items = {wall}}}
            })
            local pathfinder = levelGrid.pathfinder
            assert.is_false(containsPosition(getPathTiles(levelGrid, 1, 1, 3, 1), 2, 1), 'Path goes through a grid object.')

            wall.position = {x = 32, y = 64}
            levelGrid:updateGridObject('wall', {wall})

            assert.are.equals(pathfinder, levelGrid.pathfinder)
            assert.is_true(containsPosition(getPathTiles(levelGrid, 1, 1, 3, 1), 2, 1), 'Path didnt use the tile that was freed.')
        end)

        it('Treats the free tile value as walkable', function ()
            local levelGrid = createLevelGrid({gridSize = {width = 3, height = 3}, freeTileValue = 7})

            local tiles = getPathTiles(levelGrid, 1, 1, 3, 1)

            assert(tiles ~= nil, 'Path not found in a grid where every tile is free.')
        end)
    end)
end)
