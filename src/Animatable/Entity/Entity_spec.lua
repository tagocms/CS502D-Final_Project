require 'dependencies'

describe('Entity class tests', function ()
    local createEntity = function (defaultAnimation, position, size, animations, physicsWorld)
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

        return Entity {
            position = position,
            size = size,
            defaultAnimation = defaultAnimation,
            animations = animations,
            world = world
        }
    end

    describe('Entity:init(def)', function ()
        local entity

        setup(function ()
            entity = createEntity()
        end)

        teardown(function ()
            entity = nil
        end)

        after_each(function ()
            entity = createEntity()
        end)

        it('Holds "n" initialized animations', function ()
            assert(tablelength(entity.animations) == 3, 'Incorrect number of animations.')
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
            assert.are.same(entity.animations, animations)
        end)

        it('Correctly initializes currentAnimation as nil when not passed a defaultAnimation', function ()
            local entity = createEntity('')

            assert.are.equals(nil, entity.currentAnimation)
        end)

        it('Correctly initializes currentAnimation as nil when passed a defaultAnimation but no animations', function ()
            local entity = createEntity('idle', nil, nil, {})

            assert.are.equals(nil, entity.currentAnimation)
        end)

        it('Correctly initializes position as 0,0 when not passed a position', function ()
            local entity = createEntity(nil, {}, nil, nil)

            assert.are.same(entity.position, {x = 0, y = 0})
        end)

        it('Correctly initializes size as 1,1 when not passed a size', function ()
            local entity = createEntity(nil, nil, {}, nil)

            assert.are.same(entity.size, {width = 0, height = 0})
        end)

        it('Correctly initializes currentAnimation', function ()
            assert.are.equals(entity.animations['idle'], entity.currentAnimation)
        end)

        it('Correctly initializes position', function ()
            assert.are.same(entity.position, {x = 100, y = 200})
        end)

        it('Correctly initializes size', function ()
            assert.are.same(entity.size, {width = 32, height = 32})
        end)

        it('Correctly initializes physics', function ()
            assert(entity.physics.body and entity.physics.shape and entity.physics.fixture, 'Physics not initialized correctly.')
        end)

        it('Doesnt initialize physics if there is no size', function ()
            local entity = createEntity(nil, nil, {}, nil, nil)

            assert(entity.physics == nil, 'Physics initialized with an entity with no size.')
        end)

        it('Doesnt initialize physics if there is no world', function ()
            local entity = createEntity(nil, nil, nil, nil, {})

            assert(entity.physics == nil, 'Physics initialized with an entity with no world.')
        end)

        it('Destroys physics bodies already created when creating physics again', function ()
            assert(entity.physics.body and entity.physics.shape and entity.physics.fixture, 'Physics not initialized correctly.')
            local body = entity.physics.body
            assert(not body:isDestroyed(), 'Body destroyed prematurely.')
            
            local world = love.physics.newWorld(0, 0)
            entity:createPhysics(world)
            assert(entity.physics.body and entity.physics.shape and entity.physics.fixture, 'Physics not updated correctly.')
            assert(body:isDestroyed(), 'Body was not destroyed correctly.')
        end)

        it('Correctly creates physics after initialization', function ()
            local entity = createEntity(nil, nil, nil, nil, {})
            assert(entity.physics == nil, 'Physics initialized with an entity with no world.')
            
            local world = love.physics.newWorld(0, 0)
            entity:createPhysics(world)
            assert(entity.physics.body and entity.physics.shape and entity.physics.fixture, 'Physics not created correctly.')
        end)
    end)

    describe('Entity:update(dt)', function ()
        local entity

        setup(function ()
            entity = createEntity()
        end)

        teardown(function ()
            entity = nil
        end)

        it('Correctly updates the frame if there is a currentAnimation', function ()
            assert(entity.currentAnimation:getCurrentFrame() == 1)
            entity:update(0.31)
            assert(entity.currentAnimation:getCurrentFrame() == 2)
            entity:update(0.3)
            assert(entity.currentAnimation:getCurrentFrame() == 3)
            entity:update(0.3)
            assert(entity.currentAnimation:getCurrentFrame() == 4)
            entity:update(0.3)
            assert(entity.currentAnimation:getCurrentFrame() == 5)
            entity:update(0.3)
            assert(entity.currentAnimation:getCurrentFrame() == 6)
            entity:update(0.3)
            assert(entity.currentAnimation:getCurrentFrame() == 1)
        end)
    end)

    describe('Entity:setCurrentAnimation(newAnimation)', function ()
        local entity

        setup(function ()
            entity = createEntity()
        end)

        teardown(function ()
            entity = nil
        end)
        
        it('Correctly sets currentAnimation when valid animation is passed', function ()
            entity:setCurrentAnimation('walk')
            assert.are.equals(entity.animations['walk'], entity.currentAnimation)
        end)

        it('Correctly sets currentAnimation to nil when invalid animation passed', function ()
            entity:setCurrentAnimation('fly')
            assert.are.equals(nil, entity.currentAnimation)
        end)
    end)

    describe('Entity:updatePosition()', function ()
        local entity

        setup(function ()
            entity = createEntity()
        end)

        teardown(function ()
            entity = nil
        end)

        it('Correctly equals both entity position and entity body position without movement', function ()
            assert.are.equals(entity.physics.body:getX(), entity.position.x)
            assert.are.equals(entity.physics.body:getY(), entity.position.y)
        end)

        it('Correctly equals both entity position and entity body position with movement', function ()
            local getCurrentX = function () return entity.physics.body:getX() end
            local getCurrentY = function () return entity.physics.body:getY() end

            entity.physics.body:setX(getCurrentX() + 10)
            entity.physics.body:setY(getCurrentY() - 10)
            entity:updatePosition()
            assert.are.equals(entity.physics.body:getX(), entity.position.x)
            assert.are.equals(entity.physics.body:getY(), entity.position.y)

            entity.physics.body:setY(getCurrentY() + 10)
            entity:updatePosition()
            assert.are.equals(entity.physics.body:getX(), entity.position.x)
            assert.are.equals(entity.physics.body:getY(), entity.position.y)

            entity:updatePosition()
            assert.are.equals(entity.physics.body:getX(), entity.position.x)
            assert.are.equals(entity.physics.body:getY(), entity.position.y)

            entity.physics.body:setY(getCurrentY() + 10)
            entity.physics.body:setY(getCurrentY() - 10)
            entity:updatePosition()
            assert.are.equals(entity.physics.body:getX(), entity.position.x)
            assert.are.equals(entity.physics.body:getY(), entity.position.y)

            entity.physics.body:setX(getCurrentX() + 10)
            entity.physics.body:setX(getCurrentX() - 10)
            entity:updatePosition()
            assert.are.equals(entity.physics.body:getX(), entity.position.x)
            assert.are.equals(entity.physics.body:getY(), entity.position.y)
        end)
    end)
end)