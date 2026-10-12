Entity = Class{__includes = Animatable}

function Entity:init(def)
    Animatable.init(self, def)
    self.speed = def.speed

    if def.world then
        self:createPhysics(def.world)
    end
end

function Entity:update(dt)
    Animatable.update(self, dt)
end

function Entity:updatePosition()
    self.position.x = self.physics.body:getX()
    self.position.y = self.physics.body:getY()
end

function Entity:draw()
    Animatable.draw(self)
end

function Entity:createPhysics(world)
    self.physics = {}
    self.physics.body = love.physics.newBody(world, self.position.x, self.position.y, 'dynamic')
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.size.width, self.size.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
end