---@class Player: Entity
---@field stateMachine StateMachine
Player = Class{ __includes = Entity }

---@class PlayerDef: EntityDef

---@param def PlayerDef Initialization definitions for Player class
function Player:init(def)
    Entity.init(self, def)
    self.stateMachine = StateMachine {
        availableStates = {
            [PlayerExploreState.getName()] = PlayerExploreState,
            [PlayerBattleIdleState.getName()] = PlayerBattleIdleState,
        },
        initialStateName = PlayerExploreState.getName(),
        initialStateParams = {
            playerSpeed = self.speed,
            setMovementTarget = function (position) self:setMovementTarget(position) end
        }
    }
end

function Player:update(dt, params, canInput)
    Entity.update(self, dt)
    if canInput then
        self.stateMachine:update(dt, params)
    end
end

function Player:getClassName()
    return 'Player'
end