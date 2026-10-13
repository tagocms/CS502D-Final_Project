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

        it('Correctly initializes enemies', function ()
            assert(#game.enemies == 2, 'Incorrect number of enemies initialized.')
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

        describe('Movement', function ()
            it('Correctly handles player up movement', function ()
                game:setKeyDown('up')
                game:update(0)
                local xVelocity, yVelocity = game.player.physics.body:getLinearVelocity()
                assert(xVelocity == 0, 'Player x velocity should be 0.')
                assert(math.floor(yVelocity) == -game.player.speed, 'Player y velocity is incorrect.')
            end)

            it('Correctly handles player down movement', function ()
                game:setKeyDown('down')
                game:update(0)
                local xVelocity, yVelocity = game.player.physics.body:getLinearVelocity()
                assert(xVelocity == 0, 'Player x velocity should be 0.')
                assert(math.ceil(yVelocity) == game.player.speed, 'Player y velocity is incorrect.')
            end)

            it('Correctly handles player left movement', function ()
                game:setKeyDown('left')
                game:update(0)
                local xVelocity, yVelocity = game.player.physics.body:getLinearVelocity()
                assert(math.floor(xVelocity) == -game.player.speed, 'Player x velocity is incorrect.')
                assert(yVelocity == 0, 'Player y velocity should be 0.')
            end)

            it('Correctly handles player right movement', function ()
                game:setKeyDown('right')
                game:update(0)
                local xVelocity, yVelocity = game.player.physics.body:getLinearVelocity()
                assert(math.ceil(xVelocity) == game.player.speed, 'Player x velocity is incorrect.')
                assert(yVelocity == 0, 'Player y velocity should be 0.')
            end)
        end)

        describe('Camera', function ()
            local screenSize = {
                width = 1080,
                height = 720
            }
            local game

            before_each(function ()
                game = Game()
                game.getScreenSize = function ()
                    return screenSize
                end
            end)

            after_each(function ()
                game.getScreenSize = nil
            end)

            it('Correctly fixes the camera to player position when centered', function ()
                game.player.physics.body:setX(game.mapSize.width / 2)
                game.player.physics.body:setY(game.mapSize.height / 2)
                game:update(0)

                assert.are.equals(game.player.position.x, game.camera.x)
                assert.are.equals(game.player.position.y, game.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the left of the screen', function ()
                game.player.physics.body:setX(0)
                game.player.physics.body:setY(game.mapSize.height / 2)
                game:update(0)
                
                assert.are.equals(screenSize.width / 2, game.camera.x)
                assert.are.equals(game.player.position.y, game.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the right of the screen', function ()
                game.player.physics.body:setX(game.mapSize.width)
                game.player.physics.body:setY(game.mapSize.height / 2)
                game:update(0)
                
                assert.are.equals((game.mapSize.width - screenSize.width / 2), game.camera.x)
                assert.are.equals(game.player.position.y, game.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the top of the screen', function ()
                game.player.physics.body:setX(game.mapSize.width / 2)
                game.player.physics.body:setY(0)
                game:update(0)
                
                assert.are.equals(game.player.position.x, game.camera.x)
                assert.are.equals(screenSize.height / 2, game.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the bottom of the screen', function ()
                game.player.physics.body:setX(game.mapSize.width / 2)
                game.player.physics.body:setY(game.mapSize.height)
                game:update(0)
                
                assert.are.equals(game.player.position.x, game.camera.x)
                assert.are.equals((game.mapSize.height - screenSize.height / 2), game.camera.y)
            end)
        end)

        describe('Physics', function ()
            it('Correctly equals both player position and player body position without movement', function ()
                assert.are.equals(game.player.position.x, game.player.physics.body:getX(), 'Player X out of sync with body.')
                assert.are.equals(game.player.position.y, game.player.physics.body:getY(), 'Player Y out of sync with body.')
            end)

            it('Correctly equals both player position and player body position with movement', function ()
                game:setKeyDown('right')
                game:setKeyDown('up')
                game:update(0)
                assert.are.equals(game.player.position.x, game.player.physics.body:getX(), 'Player X out of sync with body.')
                assert.are.equals(game.player.position.y, game.player.physics.body:getY(), 'Player Y out of sync with body.')

                game:setKeyDown('down')
                game:update(0)
                assert.are.equals(game.player.position.x, game.player.physics.body:getX(), 'Player X out of sync with body.')
                assert.are.equals(game.player.position.y, game.player.physics.body:getY(), 'Player Y out of sync with body.')

                game:setKeyDown('left')
                game:update(0)
                assert.are.equals(game.player.position.x, game.player.physics.body:getX(), 'Player X out of sync with body.')
                assert.are.equals(game.player.position.y, game.player.physics.body:getY(), 'Player Y out of sync with body.')

                game:setKeyDown('up')
                game:setKeyDown('down')
                game:update(0)
                assert.are.equals(game.player.position.x, game.player.physics.body:getX(), 'Player X out of sync with body.')
                assert.are.equals(game.player.position.y, game.player.physics.body:getY(), 'Player Y out of sync with body.')

                game:setKeyDown('right')
                game:setKeyDown('left')
                game:update(0)
                assert.are.equals(game.player.position.x, game.player.physics.body:getX(), 'Player X out of sync with body.')
                assert.are.equals(game.player.position.y, game.player.physics.body:getY(), 'Player Y out of sync with body.')
            end)

            it('Correctly updates enemy position to their physics bodies', function ()
                for i, enemy in pairs(game.enemies) do
                    local enemyX = enemy.physics.body:getX()
                    enemy.physics.body:setX(enemyX + 10)
                    game:update(0)
                    assert(enemy.position.x == enemyX + 10, "Enemy x position not updated.")
                end

                for i, enemy in pairs(game.enemies) do
                    local enemyY = enemy.physics.body:getY()
                    enemy.physics.body:setY(enemyY + 10)
                    game:update(0)
                    assert(enemy.position.y == enemyY + 10, "Enemy y position not updated.")
                end
            end)
        end)
    end)

    describe('Game:keypressed(key)', function ()
        local game

        setup(function ()
            game = Game()
        end)

        teardown(function ()
            game = nil
        end)

        it('Correctly sets "escape" key in the "wasKeyPressed" table', function ()
            spy.on(game, 'setKeyPressed')
            game:clearKeyDownAndPressed()
            game:keypressed('escape')
            assert.spy(game.setKeyPressed).was.called()
            assert.spy(game.setKeyPressed).was.called_with(match.is_ref(game), 'escape')

            assert(game:wasPressed('escape'), '"Escape" was not correctly set.')

            game:clearKeyDownAndPressed()
            game.setKeyPressed:revert()
        end)

        it('Correctly quits the application when "escape" is pressed', function ()
            stub(love.event, 'quit')
            game:keypressed('escape')
            game:handleKeyPressed()
            assert.stub(love.event.quit).was.called()
            love.event.quit:revert()
        end)
    end)
end)