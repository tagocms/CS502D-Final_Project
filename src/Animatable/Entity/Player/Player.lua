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
    self.finder = def.finder
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
    if position then
        local gridTarget = LevelGrid.convertPositionFromPixelsToGrid(position, {width = TILE_SIZE, height = TILE_SIZE})
        local playerPosition = self:getPosition()
        local currentPosition = LevelGrid.convertPositionFromPixelsToGrid(playerPosition, {width = TILE_SIZE, height = TILE_SIZE})
        self.path, self.pathLength = self.finder:getPath(currentPosition.x, currentPosition.y, gridTarget.x, gridTarget.y)
        self.currentTarget = 1
    else
        self:setLinearVelocity(0, 0)
        self.path = nil
        self.pathLength = nil
        self.currentTarget = nil
    end
end

function Player:handleMovement(dt)
    if not self.path then return end

    local position = self:getPosition()

    local movementTarget = nil

    for node, count in self.path:iter() do
        if count == self.currentTarget then
            local x, y = node:getPos()
            local centerX, centerY = (x - 1) * TILE_SIZE + TILE_SIZE / 2, (y - 1) * TILE_SIZE + TILE_SIZE / 2
            local hasReachedTarget = function ()
                return (
                    math.abs(centerX - position.x) < 0.5
                    and math.abs(centerY - position.y) < 0.5
                )
            end
            if hasReachedTarget() then
               self.currentTarget = self.currentTarget + 1
            else
                movementTarget = node
                break
            end
        end
    end

    if not movementTarget then
        self:endMovement()
        return
     end

    local delta = {
        x = (movementTarget:getX() - 1) * TILE_SIZE + TILE_SIZE / 2 - position.x,
        y = (movementTarget:getY() - 1) * TILE_SIZE + TILE_SIZE / 2 - position.y
    }
    local totalDistance = math.sqrt(delta.x * delta.x + delta.y * delta.y)

    if totalDistance <= self.speed * dt then
        self:setLinearVelocity(delta.x / dt, delta.y / dt)
    else
        self:setLinearVelocity(
            delta.x / totalDistance * self.speed,
            delta.y / totalDistance * self.speed
    )
    end
    
end

function Player:draw()
    if self.path then
        local previousNode
        for node, count in self.path:iter() do
            if previousNode then
                love.graphics.line((previousNode:getX() - 1) * TILE_SIZE + TILE_SIZE / 2, (previousNode:getY() - 1) * TILE_SIZE + TILE_SIZE / 2, (node:getX() - 1) * TILE_SIZE + TILE_SIZE / 2, (node:getY() - 1) * TILE_SIZE + TILE_SIZE / 2)
            end
            previousNode = node
        end
    end

    Entity.draw(self)
end

function Player:endMovement()
    self:setMovementTarget(nil)
end

function Player:getClassName()
    return 'Player'
end