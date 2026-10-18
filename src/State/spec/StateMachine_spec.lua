require 'dependencies'

describe('StateMachine class tests', function ()
    local createState = function (name)
        local State = Class{__includes = BaseState}
        State.getName = function () return name end
        return State
    end

    local StateA, StateB
    local createStateMachine = function (initialStateName, initialStateParams)
        return StateMachine {
            availableStates = {
                [StateA.getName()] = StateA,
                [StateB.getName()] = StateB
            },
            initialStateName = initialStateName or StateA.getName(),
            initialStateParams = initialStateParams
        }
    end

    before_each(function ()
        StateA = createState('StateA')
        StateB = createState('StateB')
    end)

    describe('StateMachine:init(def)', function ()
        it('Enters the initial state', function ()
            local stateMachine = createStateMachine('StateB')
            getmetatable(assert(stateMachine.currentState) == StateB, 'Initial state is not StateB.')
        end)

        it('Passes the initial state params to the initial state', function ()
            local params = {foo = 'bar'}
            spy.on(StateA, 'init')
            createStateMachine('StateA', params)
            assert.spy(StateA.init).was.called_with(match._, params)
        end)

        it('Has no current state when the initial state is unavailable', function ()
            local stateMachine = createStateMachine('Unknown')
            assert.is_nil(stateMachine.currentState)
        end)

        it('Accepts a definition without available states', function ()
            local stateMachine = StateMachine {initialStateName = 'StateA'}
            assert.is_nil(stateMachine.currentState)
        end)
    end)

    describe('StateMachine:enterNewState(newStateName, newStateParams)', function ()
        it('Replaces the current state with the new one', function ()
            local stateMachine = createStateMachine('StateA')
            stateMachine:enterNewState('StateB')
            getmetatable(assert(stateMachine.currentState) == StateB, 'Current state is not StateB.')
        end)

        it('Passes the params to the new state', function ()
            local params = {foo = 'bar'}
            local stateMachine = createStateMachine('StateA')
            spy.on(StateB, 'init')
            stateMachine:enterNewState('StateB', params)
            assert.spy(StateB.init).was.called_with(match._, params)
        end)

        it('Exits the previous state exactly once', function ()
            local stateMachine = createStateMachine('StateA')
            local previousState = stateMachine.currentState
            spy.on(previousState, 'exit')
            stateMachine:enterNewState('StateB')
            assert.spy(previousState.exit).was.called(1)
        end)

        it('Keeps the current state when the new state is unavailable', function ()
            local stateMachine = createStateMachine('StateA')
            local previousState = stateMachine.currentState
            spy.on(previousState, 'exit')
            stateMachine:enterNewState('Unknown')
            assert.are.equals(previousState, stateMachine.currentState)
            assert.spy(previousState.exit).was_not.called()
        end)

        it('Creates a new instance when re-entering the same state', function ()
            local stateMachine = createStateMachine('StateA')
            local previousState = stateMachine.currentState
            stateMachine:enterNewState('StateA')
            assert.are_not.equals(previousState, stateMachine.currentState)
        end)
    end)

    describe('StateMachine:update(dt, params)', function ()
        it('Forwards dt and params to the current state', function ()
            local stateMachine = createStateMachine()
            local params = {foo = 'bar'}
            spy.on(stateMachine.currentState, 'update')
            stateMachine:update(0.5, params)
            assert.spy(stateMachine.currentState.update).was.called_with(match.is_ref(stateMachine.currentState), 0.5, params)
        end)

        it('Does nothing without a current state', function ()
            local stateMachine = createStateMachine('Unknown')
            assert.has_no.errors(function () stateMachine:update(0, {}) end)
        end)
    end)

    describe('StateMachine:draw()', function ()
        it('Draws the current state', function ()
            local stateMachine = createStateMachine()
            spy.on(stateMachine.currentState, 'draw')
            stateMachine:draw()
            assert.spy(stateMachine.currentState.draw).was.called(1)
        end)

        it('Does nothing without a current state', function ()
            local stateMachine = createStateMachine('Unknown')
            assert.has_no.errors(function () stateMachine:draw() end)
        end)
    end)

    describe('StateMachine:exit()', function ()
        it('Exits the current state', function ()
            local stateMachine = createStateMachine()
            spy.on(stateMachine.currentState, 'exit')
            stateMachine:exit()
            assert.spy(stateMachine.currentState.exit).was.called(1)
        end)
    end)

    describe('StateMachine.getName()', function ()
        it('Returns "StateMachine"', function ()
            assert.are.equals('StateMachine', StateMachine.getName())
        end)
    end)
end)
