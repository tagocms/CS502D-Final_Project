require 'dependencies'

describe('LevelGridObjectItem class tests', function ()
    local createRef = function (position, size)
        local ref = {
            position = position or {x = 100, y = 200},
            size = size or {width = 32, height = 32}
        }
        function ref:getPosition() return self.position end
        function ref:getSize() return self.size end
        return ref
    end

    local createItem = function (ref)
        return LevelGridObjectItem {
            ref = ref or createRef()
        }
    end

    describe('LevelGridObjectItem:init(def)', function ()
        it('Correctly initializes ref', function ()
            local ref = createRef()
            local item = createItem(ref)

            assert.are.equals(ref, item.ref)
        end)

        it('Correctly initializes lastTilePositions as an empty list', function ()
            local item = createItem()

            assert.are.same({}, item.lastTilePositions)
        end)

        it('Doesnt share lastTilePositions between items', function ()
            local itemA = createItem()
            local itemB = createItem()

            itemA.lastTilePositions[#itemA.lastTilePositions + 1] = {x = 1, y = 1}

            assert.are.same({}, itemB.lastTilePositions)
        end)
    end)

    describe('LevelGridObjectItem:getPosition()', function ()
        it('Returns the position of the referenced object', function ()
            local item = createItem(createRef({x = 10, y = 20}))

            assert.are.same({x = 10, y = 20}, item:getPosition())
        end)

        it('Follows the referenced object when it moves', function ()
            local ref = createRef({x = 10, y = 20})
            local item = createItem(ref)

            ref.position = {x = 50, y = 60}

            assert.are.same({x = 50, y = 60}, item:getPosition())
        end)
    end)

    describe('LevelGridObjectItem:getSize()', function ()
        it('Returns the size of the referenced object', function ()
            local item = createItem(createRef(nil, {width = 64, height = 96}))

            assert.are.same({width = 64, height = 96}, item:getSize())
        end)

        it('Follows the referenced object when it is resized', function ()
            local ref = createRef(nil, {width = 32, height = 32})
            local item = createItem(ref)

            ref.size = {width = 96, height = 96}

            assert.are.same({width = 96, height = 96}, item:getSize())
        end)
    end)
end)
