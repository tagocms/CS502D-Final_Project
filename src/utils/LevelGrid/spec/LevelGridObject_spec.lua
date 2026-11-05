require 'dependencies'

describe('LevelGridObject class tests', function ()
    describe('LevelGridObject:init(def)', function ()
        it('Correctly initializes items', function ()
            local items = {{}, {}}
            local gridObject = LevelGridObject {items = items}

            assert.are.equals(items, gridObject.items)
        end)

        it('Defaults items to an empty list', function ()
            local gridObject = LevelGridObject {}

            assert.are.same({}, gridObject.items)
        end)

        it('Doesnt share default items between grid objects', function ()
            local gridObjectA = LevelGridObject {}
            local gridObjectB = LevelGridObject {}

            gridObjectA.items[1] = {}

            assert.are.same({}, gridObjectB.items)
        end)

        it('Correctly initializes numberOnGrid', function ()
            local gridObject = LevelGridObject {numberOnGrid = 5}

            assert.are.equals(5, gridObject.numberOnGrid)
        end)

        it('Defaults numberOnGrid to 1', function ()
            local gridObject = LevelGridObject {}

            assert.are.equals(1, gridObject.numberOnGrid)
        end)

        it('Correctly initializes shouldAddItem', function ()
            local shouldAddItem = function (item) return false end
            local gridObject = LevelGridObject {shouldAddItem = shouldAddItem}

            assert.are.equals(shouldAddItem, gridObject.shouldAddItem)
        end)

        it('Defaults shouldAddItem to a function that accepts any item', function ()
            local gridObject = LevelGridObject {}

            assert.is_true(gridObject.shouldAddItem({}))
            assert.is_true(gridObject.shouldAddItem(nil))
        end)
    end)
end)
