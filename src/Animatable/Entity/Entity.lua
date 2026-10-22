Entity = Class{__includes = Animatable}

function Entity:init(def)
    Animatable.init(self, def)

    local world = def.world
    if world and (type(world) == "userdata" and world:typeOf("World")) then
        self:createPhysics(def.world)
    end
end

function Entity:update(dt)
    Animatable.update(self, dt)
    local xVelocity, yVelocity = self.physics.body:getLinearVelocity()
    if xVelocity ~= 0 or yVelocity ~= 0 then
        self:setCurrentAnimation('walk')
    else
        self:setCurrentAnimation('idle')
    end
end

function Entity:updatePosition()
    if not self.physics.body then return end
    self.position.x = self.physics.body:getX()
    self.position.y = self.physics.body:getY()
end

function Entity:draw()
    Animatable.draw(self, 3, 3, self.size.width / 2, self.size.height / 2)
end

function Entity:createPhysics(world)
    if self.size.width <= 0 or self.size.height <= 0 then return end
    if self.physics and self.physics.body then
        self.physics.body:destroy()
    end

    self.physics = {}
    self.physics.body = love.physics.newBody(world, self.position.x, self.position.y, 'dynamic')
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.size.width, self.size.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
    self.physics.fixture:setUserData(self:getClassName())
end

function Entity:getClassName()
    return 'Entity'
end