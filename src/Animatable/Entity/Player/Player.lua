Player = Class{ __includes = Entity }

function Player:init(def)
    Entity.init(self, def)
    self.speed = def.speed or 0
    self.stateMachine = StateMachine {
        availableStates = {
            [PlayerExploreState.getName()] = PlayerExploreState,
            [PlayerBattleIdleState.getName()] = PlayerBattleIdleState,
        },
        initialStateName = PlayerExploreState.getName(),
        initialStateParams = {
            playerSpeed = self.speed,
            setLinearVelocity = function (xVelocity, yVelocity) self:setLinearVelocity(xVelocity, yVelocity) end,
            setMovementTarget = function (position) self:setMovementTarget(position) end
        }
    }
end

function Player:update(dt, params, canInput)
    Entity.update(self, dt)
    if canInput then
        self.stateMachine:update(dt, params)
    end
    self:handleMovement(dt)
end

function Player:setLinearVelocity(xVelocity, yVelocity)
    self.physics.body:setLinearVelocity(xVelocity, yVelocity)
end

function Player:setMovementTarget(position)
    self.movementTarget = position
end

function Player:handleMovement(dt)
    if not self.movementTarget then return end

    local position = self:getPosition()
    local delta = {
        x = self.movementTarget.x - position.x,
        y = self.movementTarget.y - position.y
    }
    local totalDistance = math.sqrt(delta.x * delta.x + delta.y * delta.y)

    if totalDistance <= self.speed * dt then
        self:endMovement()
    else
        self:setLinearVelocity(
            delta.x / totalDistance * self.speed,
            delta.y / totalDistance * self.speed
        )
    end
end

function Player:endMovement()
    self:setLinearVelocity(0, 0)
    self:setMovementTarget(nil)
end

function Player:getPosition()
    local x, y = self.physics.body:getPosition()
    return { x = x, y = y }
end

function Player:getClassName()
    return 'Player'
end