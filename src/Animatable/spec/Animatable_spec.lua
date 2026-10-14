require 'dependencies'

describe('Animatable class tests', function ()
    local createAnimatable = function (defaultAnimation, position, size, animations)
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

        return Animatable {
            position = position,
            size = size,
            defaultAnimation = defaultAnimation,
            animations = animations
        }
    end

    describe('Animatable:init(def)', function ()
        local animatable

        setup(function ()
            animatable = createAnimatable()
        end)

        teardown(function ()
            animatable = nil
        end)

        after_each(function ()
            animatable = createAnimatable()
        end)

        it('Holds "n" initialized animations', function ()
            assert(tablelength(animatable.animations) == 3, 'Incorrect number of animations.')
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
            assert.are.same(animatable.animations, animations)
        end)

        it('Correctly initializes currentAnimation as nil when not passed a defaultAnimation', function ()
            local animatable = createAnimatable('')

            assert.are.equals(nil, animatable.currentAnimation)
        end)

        it('Correctly initializes currentAnimation as nil when passed a defaultAnimation but no animations', function ()
            local animatable = createAnimatable('idle', nil, nil, {})

            assert.are.equals(nil, animatable.currentAnimation)
        end)

        it('Correctly initializes position as 0,0 when not passed a position', function ()
            local animatable = createAnimatable(nil, {}, nil, nil)

            assert.are.same(animatable.position, {x = 0, y = 0})
        end)

        it('Correctly initializes size as 0,0 when not passed a size', function ()
            local animatable = createAnimatable(nil, nil, {}, nil)

            assert.are.same(animatable.size, {width = 0, height = 0})
        end)

        it('Correctly initializes currentAnimation', function ()
            assert.are.equals(animatable.animations['idle'], animatable.currentAnimation)
        end)

        it('Correctly initializes position', function ()
            assert.are.same(animatable.position, {x = 100, y = 200})
        end)

        it('Correctly initializes size', function ()
            assert.are.same(animatable.size, {width = 32, height = 32})
        end)
    end)

    describe('Animatable:update(dt)', function ()
        local animatable

        setup(function ()
            animatable = createAnimatable()
        end)

        teardown(function ()
            animatable = nil
        end)

        it('Correctly updates the frame if there is a currentAnimation', function ()
            assert(animatable.currentAnimation:getCurrentFrame() == 1)
            animatable:update(0.31)
            assert(animatable.currentAnimation:getCurrentFrame() == 2)
            animatable:update(0.3)
            assert(animatable.currentAnimation:getCurrentFrame() == 3)
            animatable:update(0.3)
            assert(animatable.currentAnimation:getCurrentFrame() == 4)
            animatable:update(0.3)
            assert(animatable.currentAnimation:getCurrentFrame() == 5)
            animatable:update(0.3)
            assert(animatable.currentAnimation:getCurrentFrame() == 6)
            animatable:update(0.3)
            assert(animatable.currentAnimation:getCurrentFrame() == 1)
        end)
    end)

    describe('Animatable:setCurrentAnimation(newAnimation)', function ()
        local animatable

        setup(function ()
            animatable = createAnimatable()
        end)

        teardown(function ()
            animatable = nil
        end)
        
        it('Correctly sets currentAnimation when valid animation is passed', function ()
            animatable:setCurrentAnimation('walk')
            assert.are.equals(animatable.animations['walk'], animatable.currentAnimation)
        end)

        it('Correctly sets currentAnimation to nil when invalid animation passed', function ()
            animatable:setCurrentAnimation('fly')
            assert.are.equals(nil, animatable.currentAnimation)
        end)
    end)
end)