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

        it('Creates a StateMachine', function ()
            assert(game.stateMachine ~= nil, 'StateMachine not created.')
            assert(getmetatable(game.stateMachine) == StateMachine, 'Game state machine is not a StateMachine.')
        end)

        it('Starts in the PlayState', function ()
            assert(getmetatable(game.stateMachine.currentState) == PlayState, 'Initial state is not PlayState.')
        end)

        it('Makes PlayState available to the StateMachine', function ()
            assert.are.equals(PlayState, game.stateMachine._availableStates[PlayState.getName()])
        end)

        it('Starts the PlayState with the CastleOutside map', function ()
            spy.on(_G, 'Sti')
            Game()
            assert.spy(_G.Sti).was.called_with('src/maps/CastleOutside.lua')
            _G.Sti:revert()
        end)
    end)

    describe('Game:update(dt)', function ()
        local game

        before_each(function ()
            game = Game()
        end)

        after_each(function ()
            game = nil
        end)

        it('Forwards dt and the input params to the StateMachine', function ()
            spy.on(game.stateMachine, 'update')
            game:update(0.25)
            assert.spy(game.stateMachine.update).was.called(1)
            assert.spy(game.stateMachine.update).was.called_with(
                match.is_ref(game.stateMachine),
                0.25,
                match.is_table()
            )
            game.stateMachine.update:revert()
        end)

        it('Forwards the keys that are down to the current state', function ()
            game:setKeyDown('up')
            game:update(0)
            local _, yVelocity = game.stateMachine.currentState.player.physics.body:getLinearVelocity()
            assert(yVelocity < 0, 'Player did not move up, keys down were not forwarded.')
        end)

        it('Provides an enterNewState callback on entering new state that changes the StateMachine state', function ()
            local SwitchingState = Class{__includes = BaseState}
            function SwitchingState:init(def)
                self.enterNewState = def.callbacks.enterNewState
            end
            function SwitchingState:update(dt, params)
                self.enterNewState('PlayState', {gameMapPath = 'src/maps/CastleOutside.lua'})
            end

            game.stateMachine._availableStates['SwitchingState'] = SwitchingState
            game.stateMachine:enterNewState('SwitchingState')
            spy.on(game.stateMachine, 'enterNewState')

            game:update(0)

            assert.spy(game.stateMachine.enterNewState).was.called_with(
                match.is_ref(game.stateMachine),
                'PlayState',
                {gameMapPath = 'src/maps/CastleOutside.lua'}
            )
            assert(getmetatable(game.stateMachine.currentState) == PlayState, 'State was not changed to PlayState.')
        end)

        it('Clears the keys down and pressed after updating', function ()
            game:setKeyDown('up')
            game:keypressed('space')
            game:update(0)
            assert(not game:isDown('up'), 'Key down was not cleared.')
            assert(not game:wasPressed('space'), 'Key pressed was not cleared.')
        end)
    end)

    describe('Game:draw()', function ()
        it('Draws the StateMachine', function ()
            local game = Game()
            stub(game.stateMachine, 'draw')
            game:draw()
            assert.stub(game.stateMachine.draw).was.called(1)
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