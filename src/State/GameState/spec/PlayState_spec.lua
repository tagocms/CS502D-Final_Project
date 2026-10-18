require 'dependencies'

describe('PlayState class tests', function ()
    local createPlayState = function ()
        return PlayState {gameMapPath = 'src/maps/CastleOutside.lua', callbacks = {}}
    end

    local createKeysDown = function (...)
        local keysDown = KeysInteracted()
        for i, key in ipairs({...}) do
            keysDown:setKeyInteracted(key)
        end
        return keysDown
    end

    describe('PlayState:init(def)', function ()
        local playState

        setup(function ()
            playState = createPlayState()
        end)

        teardown(function ()
            playState = nil
        end)

        it('Loads a 60x60 grid', function() 
            local gameMap = playState.gameMap
            assert(gameMap.width * gameMap.height == 60 * 60, 'Map grid size divergent from 60 * 60.')
        end)

        it('Correctly initializes physics world and camera', function ()
            assert(playState.world ~= nil, 'Physics world not initialized.')
            assert(playState.camera ~= nil, 'Camera not initialized.')
            assert(tablelength(playState.collidables) > 0, 'Collidables not loaded.')
        end)

        it('Correctly initializes player', function ()
            assert(playState.player ~= nil, 'Player not initialized.')
        end)

        it('Correctly initializes enemies', function ()
            assert(#playState.enemies == 2, 'Incorrect number of enemies initialized.')
        end)
    end)

    describe('PlayState:getName()', function ()
        it('Returns "PlayState"', function ()
            assert.are.equals('PlayState', PlayState.getName())
        end)
    end)

    describe('PlayState:update(dt, params)', function ()
        local playState

        setup(function ()
            playState = createPlayState()
        end)

        teardown(function ()
            playState = nil
        end)

        describe('Movement', function ()
            it('Correctly handles player up movement', function ()
                playState:update(0, {keysDown = createKeysDown('up')})
                local xVelocity, yVelocity = playState.player.physics.body:getLinearVelocity()
                assert(xVelocity == 0, 'Player x velocity should be 0.')
                assert(math.floor(yVelocity) == -playState.player.speed, 'Player y velocity is incorrect.')
            end)

            it('Correctly handles player down movement', function ()
                playState:update(0, {keysDown = createKeysDown('down')})
                local xVelocity, yVelocity = playState.player.physics.body:getLinearVelocity()
                assert(xVelocity == 0, 'Player x velocity should be 0.')
                assert(math.ceil(yVelocity) == playState.player.speed, 'Player y velocity is incorrect.')
            end)

            it('Correctly handles player left movement', function ()
                playState:update(0, {keysDown = createKeysDown('left')})
                local xVelocity, yVelocity = playState.player.physics.body:getLinearVelocity()
                assert(math.floor(xVelocity) == -playState.player.speed, 'Player x velocity is incorrect.')
                assert(yVelocity == 0, 'Player y velocity should be 0.')
            end)

            it('Correctly handles player right movement', function ()
                playState:update(0, {keysDown = createKeysDown('right')})
                local xVelocity, yVelocity = playState.player.physics.body:getLinearVelocity()
                assert(math.ceil(xVelocity) == playState.player.speed, 'Player x velocity is incorrect.')
                assert(yVelocity == 0, 'Player y velocity should be 0.')
            end)
        end)

        describe('Camera', function ()
            local screenSize = {
                width = 1080,
                height = 720
            }
            local playState

            before_each(function ()
                playState = createPlayState()
                playState.getScreenSize = function ()
                    return screenSize
                end
            end)

            after_each(function ()
                playState.getScreenSize = nil
            end)

            it('Correctly fixes the camera to player position when centered', function ()
                playState.player.physics.body:setX(playState.mapSize.width / 2)
                playState.player.physics.body:setY(playState.mapSize.height / 2)
                playState:update(0, {keysDown = createKeysDown()})

                assert.are.equals(playState.player.position.x, playState.camera.x)
                assert.are.equals(playState.player.position.y, playState.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the left of the screen', function ()
                playState.player.physics.body:setX(0)
                playState.player.physics.body:setY(playState.mapSize.height / 2)
                playState:update(0, {keysDown = createKeysDown()})
                
                assert.are.equals(screenSize.width / 2, playState.camera.x)
                assert.are.equals(playState.player.position.y, playState.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the right of the screen', function ()
                playState.player.physics.body:setX(playState.mapSize.width)
                playState.player.physics.body:setY(playState.mapSize.height / 2)
                playState:update(0, {keysDown = createKeysDown()})
                
                assert.are.equals((playState.mapSize.width - screenSize.width / 2), playState.camera.x)
                assert.are.equals(playState.player.position.y, playState.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the top of the screen', function ()
                playState.player.physics.body:setX(playState.mapSize.width / 2)
                playState.player.physics.body:setY(0)
                playState:update(0, {keysDown = createKeysDown()})
                
                assert.are.equals(playState.player.position.x, playState.camera.x)
                assert.are.equals(screenSize.height / 2, playState.camera.y)
            end)

            it('Correctly fixes the camera to player position when to the bottom of the screen', function ()
                playState.player.physics.body:setX(playState.mapSize.width / 2)
                playState.player.physics.body:setY(playState.mapSize.height)
                playState:update(0, {keysDown = createKeysDown()})
                
                assert.are.equals(playState.player.position.x, playState.camera.x)
                assert.are.equals((playState.mapSize.height - screenSize.height / 2), playState.camera.y)
            end)
        end)

        describe('Physics', function ()
            it('Correctly equals both player position and player body position without movement', function ()
                assert.are.equals(playState.player.physics.body:getX(), playState.player.position.x)
                assert.are.equals(playState.player.physics.body:getY(), playState.player.position.y)
            end)

            it('Correctly equals both player position and player body position with movement', function ()
                local assertPositionsMatch = function ()
                    assert.are.equals(playState.player.physics.body:getX(), playState.player.position.x)
                    assert.are.equals(playState.player.physics.body:getY(), playState.player.position.y)
                end

                playState:update(0, {keysDown = createKeysDown('right', 'up')})
                assertPositionsMatch()

                playState:update(0, {keysDown = createKeysDown('right', 'up', 'down')})
                assertPositionsMatch()

                playState:update(0, {keysDown = createKeysDown('right', 'up', 'down', 'left')})
                assertPositionsMatch()

                playState:update(0, {keysDown = createKeysDown('up', 'down')})
                assertPositionsMatch()

                playState:update(0, {keysDown = createKeysDown('right', 'left')})
                assertPositionsMatch()
            end)

            it('Correctly updates enemy position to their physics bodies', function ()
                for i, enemy in pairs(playState.enemies) do
                    local enemyX = enemy.physics.body:getX()
                    enemy.physics.body:setX(enemyX + 10)
                    playState:update(0, {keysDown = createKeysDown()})
                    assert(enemy.position.x == enemyX + 10, "Enemy x position not updated.")
                end

                for i, enemy in pairs(playState.enemies) do
                    local enemyY = enemy.physics.body:getY()
                    enemy.physics.body:setY(enemyY + 10)
                    playState:update(0, {keysDown = createKeysDown()})
                    assert(enemy.position.y == enemyY + 10, "Enemy y position not updated.")
                end
            end)
        end)
    end)
end)
