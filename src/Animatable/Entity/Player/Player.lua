Player = Class{ __includes = Entity }

function Player:init(def)
    Entity.init(self, def)
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

function Player:draw()
    local anim = self.currentAnimation
    love.graphics.draw(
        TEXTURES[anim.texture], FRAMES[anim.texture][anim:getCurrentFrame()],
        self.position.x, self.position.y,
        nil,
        5, 5,
        self.size.width / 2, self.size.height / 2
    )
end