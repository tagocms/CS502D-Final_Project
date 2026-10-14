require 'dependencies'

describe('Player class tests', function ()
    local createPlayer = function (defaultAnimation, position, size, animations, physicsWorld, speed)
        local defaultAnimation = defaultAnimation or 'idle'
        local position = position or {
            x = 100,
            y = 200
        }
        local size = size or {
            width = 32,
            height = 32
        }
        local animations = animations or {
            ['idle'] = {
                frames = {1, 2, 3, 4, 5, 6},
                interval = 0.3,
                texture = 'player-soldier'
            },
            ['walk'] = {
                frames = {11, 12, 13, 14, 15, 16, 17, 18},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['jump'] = {
                frames = {21, 22, 23, 24, 25, 26},
                interval = 0.1,
                texture = 'player-soldier'
            }
        }
        local world = physicsWorld or love.physics.newWorld(0, 0)
        local speed = speed or 500

        return Player {
            position = position,
            size = size,
            defaultAnimation = defaultAnimation,
            animations = animations,
            world = world,
            speed = speed
        }
    end

    describe('Player:init(def)', function ()
        local player

        setup(function ()
            player = createPlayer()
        end)

        teardown(function ()
            player = nil
        end)

        after_each(function ()
            player = createPlayer()
        end)

        it('Holds "n" initialized animations', function ()
            assert(tablelength(player.animations) == 3, 'Incorrect number of animations.')
        end)

        it('Correctly initializes animations', function ()
            local animations = {}
            animations['idle'] = Animation {
                frames = {1, 2, 3, 4, 5, 6},
                interval = 0.3,
                texture = 'player-soldier'
            }
            animations['walk'] = Animation {
                frames = {11, 12, 13, 14, 15, 16, 17, 18},
                interval = 0.1,
                texture = 'player-soldier'
            }
            animations['jump'] = Animation {
                frames = {21, 22, 23, 24, 25, 26},
                interval = 0.1,
                texture = 'player-soldier'
            }
            assert.are.same(player.animations, animations)
        end)

        it('Correctly initializes currentAnimation as nil when not passed a defaultAnimation', function ()
            local player = createPlayer('')

            assert.are.equals(nil, player.currentAnimation)
        end)

        it('Correctly initializes currentAnimation as nil when passed a defaultAnimation but no animations', function ()
            local player = createPlayer('idle', nil, nil, {})

            assert.are.equals(nil, player.currentAnimation)
        end)

        it('Correctly initializes position as 0,0 when not passed a position', function ()
            local player = createPlayer(nil, {}, nil, nil)

            assert.are.same(player.position, {x = 0, y = 0})
        end)

        it('Correctly initializes size as 1,1 when not passed a size', function ()
            local player = createPlayer(nil, nil, {}, nil)

            assert.are.same(player.size, {width = 0, height = 0})
        end)

        it('Correctly initializes currentAnimation', function ()
            assert.are.equals(player.animations['idle'], player.currentAnimation)
        end)

        it('Correctly initializes position', function ()
            assert.are.same(player.position, {x = 100, y = 200})
        end)

        it('Correctly initializes size', function ()
            assert.are.same(player.size, {width = 32, height = 32})
        end)

        it('Correctly initializes physics', function ()
            assert(player.physics.body and player.physics.shape and player.physics.fixture, 'Physics not initialized correctly.')
        end)

        it('Doesnt initialize physics if there is no size', function ()
            local player = createPlayer(nil, nil, {}, nil, nil)

            assert(player.physics == nil, 'Physics initialized with an player with no size.')
        end)

        it('Doesnt initialize physics if there is no world', function ()
            local player = createPlayer(nil, nil, nil, nil, {})

            assert(player.physics == nil, 'Physics initialized with an player with no world.')
        end)

        it('Destroys physics bodies already created when creating physics again', function ()
            assert(player.physics.body and player.physics.shape and player.physics.fixture, 'Physics not initialized correctly.')
            local body = player.physics.body
            assert(not body:isDestroyed(), 'Body destroyed prematurely.')
            
            local world = love.physics.newWorld(0, 0)
            player:createPhysics(world)
            assert(player.physics.body and player.physics.shape and player.physics.fixture, 'Physics not updated correctly.')
            assert(body:isDestroyed(), 'Body was not destroyed correctly.')
        end)

        it('Correctly creates physics after initialization', function ()
            local player = createPlayer(nil, nil, nil, nil, {})
            assert(player.physics == nil, 'Physics initialized with an player with no world.')
            
            local world = love.physics.newWorld(0, 0)
            player:createPhysics(world)
            assert(player.physics.body and player.physics.shape and player.physics.fixture, 'Physics not created correctly.')
        end)

        it('Correctly initializes speed', function ()
            assert.are.equals(500, player.speed)
        end)
    end)

    describe('Player:update(dt)', function ()
        local player
        local keysDown

        setup(function ()
            player = createPlayer()
            keysDown = KeysInteracted()
        end)

        teardown(function ()
            player = nil
            keysDown = nil
        end)

        after_each(function ()
            keysDown = KeysInteracted()
        end)

        it('Correctly updates the frame if there is a currentAnimation', function ()
            assert(player.currentAnimation:getCurrentFrame() == 1)
            player:update(0.31, keysDown)
            assert(player.currentAnimation:getCurrentFrame() == 2)
            player:update(0.3, keysDown)
            assert(player.currentAnimation:getCurrentFrame() == 3)
            player:update(0.3, keysDown)
            assert(player.currentAnimation:getCurrentFrame() == 4)
            player:update(0.3, keysDown)
            assert(player.currentAnimation:getCurrentFrame() == 5)
            player:update(0.3, keysDown)
            assert(player.currentAnimation:getCurrentFrame() == 6)
            player:update(0.3, keysDown)
            assert(player.currentAnimation:getCurrentFrame() == 1)
        end)

        it('Correctly handles player up movement', function ()
            keysDown:setKeyInteracted('up')
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(xVelocity == 0, 'Player x velocity should be 0.')
            assert(math.floor(yVelocity) == -player.speed, 'Player y velocity is incorrect.')
            assert(player.currentAnimation == player.animations['walk'], 'Player animation didnt change.')
        end)

        it('Correctly handles player down movement', function ()
            keysDown:setKeyInteracted('down')
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(xVelocity == 0, 'Player x velocity should be 0.')
            assert(math.ceil(yVelocity) == player.speed, 'Player y velocity is incorrect.')
            assert(player.currentAnimation == player.animations['walk'], 'Player animation didnt change.')
        end)

        it('Correctly handles player left movement', function ()
            keysDown:setKeyInteracted('left')
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(math.floor(xVelocity) == -player.speed, 'Player x velocity is incorrect.')
            assert(yVelocity == 0, 'Player y velocity should be 0.')
            assert(player.currentAnimation == player.animations['walk'], 'Player animation didnt change.')
        end)

        it('Correctly handles player right movement', function ()
            keysDown:setKeyInteracted('right')
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(math.ceil(xVelocity) == player.speed, 'Player x velocity is incorrect.')
            assert(yVelocity == 0, 'Player y velocity should be 0.')
            assert(player.currentAnimation == player.animations['walk'], 'Player animation didnt change.')
        end)

        it('Correctly handles player idle', function ()
            -- Starts idle
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(xVelocity == 0, 'Player x velocity should be 0.')
            assert(yVelocity == 0, 'Player y velocity should be 0.')
            assert(player.currentAnimation == player.animations['idle'], 'Player animation should be idle.')

            -- Walking
            keysDown:setKeyInteracted('right')
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(math.ceil(xVelocity) == player.speed, 'Player x velocity is incorrect.')
            assert(yVelocity == 0, 'Player y velocity should be 0.')
            assert(player.currentAnimation == player.animations['walk'], 'Player animation didnt change.')
            
            -- Idle again
            keysDown:clear()
            player:update(0, keysDown)
            local xVelocity, yVelocity = player.physics.body:getLinearVelocity()
            assert(xVelocity == 0, 'Player x velocity should be 0.')
            assert(yVelocity == 0, 'Player y velocity should be 0.')
            assert(player.currentAnimation == player.animations['idle'], 'Player animation didnt change.')
        end)
    end)

    describe('Player:setCurrentAnimation(newAnimation)', function ()
        local player

        setup(function ()
            player = createPlayer()
        end)

        teardown(function ()
            player = nil
        end)
        
        it('Correctly sets currentAnimation when valid animation is passed', function ()
            player:setCurrentAnimation('walk')
            assert.are.equals(player.animations['walk'], player.currentAnimation)
        end)

        it('Correctly sets currentAnimation to nil when invalid animation passed', function ()
            player:setCurrentAnimation('fly')
            assert.are.equals(nil, player.currentAnimation)
        end)
    end)

    describe('Player:updatePosition()', function ()
        local player

        setup(function ()
            player = createPlayer()
        end)

        teardown(function ()
            player = nil
        end)

        it('Correctly equals both player position and player body position without movement', function ()
            assert.are.equals(player.physics.body:getX(), player.position.x)
            assert.are.equals(player.physics.body:getY(), player.position.y)
        end)

        it('Correctly equals both player position and player body position with movement', function ()
            local getCurrentX = function () return player.physics.body:getX() end
            local getCurrentY = function () return player.physics.body:getY() end

            player.physics.body:setX(getCurrentX() + 10)
            player.physics.body:setY(getCurrentY() - 10)
            player:updatePosition()
            assert.are.equals(player.physics.body:getX(), player.position.x)
            assert.are.equals(player.physics.body:getY(), player.position.y)

            player.physics.body:setY(getCurrentY() + 10)
            player:updatePosition()
            assert.are.equals(player.physics.body:getX(), player.position.x)
            assert.are.equals(player.physics.body:getY(), player.position.y)

            player:updatePosition()
            assert.are.equals(player.physics.body:getX(), player.position.x)
            assert.are.equals(player.physics.body:getY(), player.position.y)

            player.physics.body:setY(getCurrentY() + 10)
            player.physics.body:setY(getCurrentY() - 10)
            player:updatePosition()
            assert.are.equals(player.physics.body:getX(), player.position.x)
            assert.are.equals(player.physics.body:getY(), player.position.y)

            player.physics.body:setX(getCurrentX() + 10)
            player.physics.body:setX(getCurrentX() - 10)
            player:updatePosition()
            assert.are.equals(player.physics.body:getX(), player.position.x)
            assert.are.equals(player.physics.body:getY(), player.position.y)
        end)
    end)
end)