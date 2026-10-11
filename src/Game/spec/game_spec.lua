require 'dependencies'

describe('Game class tests', function ()
    describe('Game:init()', function ()
        local game

        setup(function ()
            game = Game()
        end)

        teardown(function ()
            game = nil
        end)

        it('Correctly sets window title', function ()
            local windowTitle = love.window.getTitle()
            assert(windowTitle == 'Age of Bandits', 'Window title is divergent from "Age of Bandits".')
        end)

        it('Correctly sets window icon', function ()
            assert(love.window.getIcon():getString() == love.image.newImageData("sprites/cursor/mouse_icon1-SwordPointer.png"):getString(), 'Wrong icon being set.')
        end)

        it('Loads a 60x60 grid', function() 
            local gameMap = game.gameMap
            assert(gameMap.width * gameMap.height == 60 * 60, 'Map grid size divergent from 60 * 60.')
        end)

        it('Correctly initializes physics world and camera', function ()
            assert(game.world ~= nil, 'Physics world not initialized.')
            assert(game.camera ~= nil, 'Camera not initialized.')
            assert(tablelength(game.collidables) > 0, 'Collidables not loaded.')
        end)

        it('Correctly initializes player', function ()
            assert(game.player ~= nil, 'Player not initialized.')
        end)
    end)

    describe('Game:update(dt)', function ()
        local game

        setup(function ()
            game = Game()
        end)

        teardown(function ()
            game = nil
        end)

        -- Game:update(dt) tests
        -- camera
        it('Correctly fixes the camera when going too far to each direction', function ()
            game:update(0.2)
        end)
        -- physics
        -- movement
    end)

    describe('Game:keypressed(key)', function ()
        local game

        setup(function ()
            game = Game()
        end)

        teardown(function ()
            game = nil
        end)

        it('Quits the application', function ()
            stub(love.event, 'quit')
            game:keypressed('escape')
            assert.stub(love.event.quit).was.called()
            love.event.quit:revert()
        end)
    end)
end)