Player = Class{ __includes = Entity }

function Player:init(def)
    Entity.init(self, def)
    self.speed = def.speed
end

function Player:update(dt, keysDown)
    Entity.update(self, dt)

    self:handleMovement(keysDown)
end

function Player:handleMovement(keysDown)
    local isMoving = false
    local xVelocity, yVelocity = 0, 0

    if keysDown:isInteracted("up") then
        yVelocity = yVelocity -self.speed
        isMoving = true
    end
    if keysDown:isInteracted("down") then
        yVelocity = yVelocity + self.speed
        isMoving = true
    end
    if keysDown:isInteracted("left") then
        xVelocity = xVelocity - self.speed
        isMoving = true
    end
    if keysDown:isInteracted("right") then
        xVelocity = xVelocity + self.speed
        isMoving = true
    end

    self.physics.body:setLinearVelocity(xVelocity, yVelocity)
    if isMoving then
        self.currentAnimation = self.animations['walk']
    else
        self.currentAnimation = self.animations['idle']
    end
end