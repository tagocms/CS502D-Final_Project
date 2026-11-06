require 'dependencies'

describe('Collidable class tests', function ()
    local createRectangle = function (x, y, width, height)
        return {
            shape = 'rectangle',
            x = x or 0,
            y = y or 0,
            width = width or 32,
            height = height or 32
        }
    end

    -- Vertices are expected in world coordinates, as STI converts them when loading a map
    local createPolygon = function (vertices, x, y)
        return {
            shape = 'polygon',
            x = x or 0,
            y = y or 0,
            width = 0,
            height = 0,
            polygon = vertices
        }
    end

    local createCollidable = function (object)
        return Collidable {object = object}
    end

    local containsPosition = function (positions, x, y)
        for i, position in ipairs(positions) do
            if position.x == x and position.y == y then
                return true
            end
        end

        return false
    end

    describe('Collidable:init(def)', function ()
        describe('Rectangles', function ()
            it('Correctly initializes position from the object', function ()
                local collidable = createCollidable(createRectangle(96, 160, 64, 32))

                assert.are.same({x = 96, y = 160}, collidable.position)
            end)

            it('Correctly initializes size from the object', function ()
                local collidable = createCollidable(createRectangle(96, 160, 64, 32))

                assert.are.same({width = 64, height = 32}, collidable.size)
            end)
        end)

        describe('Polygons', function ()
            it('Correctly initializes position as the top-left corner of the bounding box', function ()
                local collidable = createCollidable(createPolygon({
                    {x = 40, y = 70}, {x = 100, y = 50}, {x = 90, y = 120}
                }))

                assert.are.same({x = 40, y = 50}, collidable.position)
            end)

            it('Correctly initializes size as the size of the bounding box', function ()
                local collidable = createCollidable(createPolygon({
                    {x = 40, y = 70}, {x = 100, y = 50}, {x = 90, y = 120}
                }))

                assert.are.same({width = 60, height = 70}, collidable.size)
            end)

            it('Finds the bounding box when the minimum is not in the first vertex', function ()
                local collidable = createCollidable(createPolygon({
                    {x = 100, y = 100}, {x = 120, y = 90}, {x = 30, y = 40}, {x = 80, y = 60}
                }))

                assert.are.same({x = 30, y = 40}, collidable.position)
                assert.are.same({width = 90, height = 60}, collidable.size)
            end)

            it('Doesnt use the origin of the object as the position', function ()
                local collidable = createCollidable(createPolygon({
                    {x = 1472, y = 160}, {x = 1536, y = 160}, {x = 1536, y = 96}
                }, 1472, 160))

                assert.are_not.equals(160, collidable.position.y, 'Position is the origin of the object, not the bounding box.')
            end)

            it('Correctly handles a triangle whose origin is at the bottom', function ()
                -- Same shape as the polygon in the CastleOutside map that starts at its bottom-left corner:
                -- relative vertices (0, 0), (64, 0), (64, -64) on the object at (1472, 160)
                local collidable = createCollidable(createPolygon({
                    {x = 1472, y = 160}, {x = 1536, y = 160}, {x = 1536, y = 96}
                }, 1472, 160))

                assert.are.same({x = 1472, y = 96}, collidable.position)
                assert.are.same({width = 64, height = 64}, collidable.size)
            end)

            it('Correctly handles a triangle whose origin is at the top', function ()
                -- Relative vertices (0, 0), (0, 64), (64, 64) on the object at (1632, 96)
                local collidable = createCollidable(createPolygon({
                    {x = 1632, y = 96}, {x = 1632, y = 160}, {x = 1696, y = 160}
                }, 1632, 96))

                assert.are.same({x = 1632, y = 96}, collidable.position)
                assert.are.same({width = 64, height = 64}, collidable.size)
            end)

            it('Correctly handles a polygon with a single vertex as a point', function ()
                local collidable = createCollidable(createPolygon({{x = 50, y = 80}}))

                assert.are.same({x = 50, y = 80}, collidable.position)
                assert.are.same({width = 0, height = 0}, collidable.size)
            end)

            it('Doesnt change the vertices of the object', function ()
                local object = createPolygon({
                    {x = 1472, y = 160}, {x = 1536, y = 160}, {x = 1536, y = 96}
                }, 1472, 160)
                local original = deepcopy(object)

                createCollidable(object)

                assert.are.same(original, object)
            end)
        end)
    end)

    describe('Collidable:getPosition()', function ()
        it('Returns the position', function ()
            local collidable = createCollidable(createRectangle(96, 160))

            assert.are.equals(collidable.position, collidable:getPosition())
        end)

        it('Returns the top-left corner of the bounding box for polygons', function ()
            local collidable = createCollidable(createPolygon({
                {x = 1472, y = 160}, {x = 1536, y = 160}, {x = 1536, y = 96}
            }, 1472, 160))

            assert.are.same({x = 1472, y = 96}, collidable:getPosition())
        end)
    end)

    describe('Collidable:getSize()', function ()
        it('Returns the size', function ()
            local collidable = createCollidable(createRectangle(96, 160, 64, 32))

            assert.are.equals(collidable.size, collidable:getSize())
        end)

        it('Returns the size of the bounding box for polygons', function ()
            local collidable = createCollidable(createPolygon({
                {x = 1472, y = 160}, {x = 1536, y = 160}, {x = 1536, y = 96}
            }, 1472, 160))

            assert.are.same({width = 64, height = 64}, collidable:getSize())
        end)
    end)

    describe('Collidable on the LevelGrid', function ()
        local levelGrid

        before_each(function ()
            levelGrid = LevelGrid {
                tileSize = {width = 32, height = 32},
                gridSize = {width = 60, height = 60}
            }
        end)

        local getTiles = function (collidable)
            return levelGrid:convertPositionAndSizeFromPixelsToGrid(collidable:getPosition(), collidable:getSize())
        end

        it('Covers the tiles of a rectangle', function ()
            local tiles = getTiles(createCollidable(createRectangle(32, 32, 64, 32)))

            assert.are.equals(2, #tiles)
            assert(containsPosition(tiles, 2, 2), 'Missing tile 2, 2.')
            assert(containsPosition(tiles, 3, 2), 'Missing tile 3, 2.')
        end)

        it('Covers the tiles of a triangle whose origin is at the bottom', function ()
            local tiles = getTiles(createCollidable(createPolygon({
                {x = 1472, y = 160}, {x = 1536, y = 160}, {x = 1536, y = 96}
            }, 1472, 160)))

            assert.are.equals(4, #tiles)
            for x = 47, 48 do
                for y = 4, 5 do
                    assert(containsPosition(tiles, x, y), 'Missing tile ' .. x .. ', ' .. y .. '.')
                end
            end
        end)

        it('Covers the tiles of a triangle whose origin is at the top', function ()
            local tiles = getTiles(createCollidable(createPolygon({
                {x = 1632, y = 96}, {x = 1632, y = 160}, {x = 1696, y = 160}
            }, 1632, 96)))

            assert.are.equals(4, #tiles)
            for x = 52, 53 do
                for y = 4, 5 do
                    assert(containsPosition(tiles, x, y), 'Missing tile ' .. x .. ', ' .. y .. '.')
                end
            end
        end)
    end)

    describe('Collidable with the objects of the CastleOutside map', function ()
        local objects

        setup(function ()
            objects = Sti('src/maps/CastleOutside.lua').layers['Collidable'].objects
        end)

        teardown(function ()
            objects = nil
        end)

        it('Has polygons to test', function ()
            local polygons = 0
            for i, object in ipairs(objects) do
                if object.shape == 'polygon' then
                    polygons = polygons + 1
                end
            end

            assert(polygons > 0, 'No polygons in the Collidable layer.')
        end)

        it('Has a bounding box that contains every vertex of each polygon', function ()
            for i, object in ipairs(objects) do
                if object.shape == 'polygon' then
                    local collidable = createCollidable(object)
                    local position, size = collidable:getPosition(), collidable:getSize()

                    for j, vertex in ipairs(object.polygon) do
                        assert(vertex.x >= position.x and vertex.x <= position.x + size.width,
                            'Vertex ' .. j .. ' of object ' .. object.id .. ' is outside of the bounding box in x.')
                        assert(vertex.y >= position.y and vertex.y <= position.y + size.height,
                            'Vertex ' .. j .. ' of object ' .. object.id .. ' is outside of the bounding box in y.')
                    end
                end
            end
        end)

        it('Has a bounding box that touches the polygon on every side', function ()
            for i, object in ipairs(objects) do
                if object.shape == 'polygon' then
                    local collidable = createCollidable(object)
                    local position, size = collidable:getPosition(), collidable:getSize()
                    local touchesLeft, touchesRight, touchesTop, touchesBottom = false, false, false, false

                    for j, vertex in ipairs(object.polygon) do
                        touchesLeft = touchesLeft or vertex.x == position.x
                        touchesRight = touchesRight or vertex.x == position.x + size.width
                        touchesTop = touchesTop or vertex.y == position.y
                        touchesBottom = touchesBottom or vertex.y == position.y + size.height
                    end

                    assert(touchesLeft and touchesRight and touchesTop and touchesBottom,
                        'Bounding box of object ' .. object.id .. ' is bigger than the polygon.')
                end
            end
        end)

        it('Uses the position and size of the object for rectangles', function ()
            for i, object in ipairs(objects) do
                if object.shape == 'rectangle' then
                    local collidable = createCollidable(object)

                    assert.are.same({x = object.x, y = object.y}, collidable:getPosition())
                    assert.are.same({width = object.width, height = object.height}, collidable:getSize())
                end
            end
        end)
    end)
end)
