GameObject = Class{__includes = Animatable}

function GameObject:init(def)
    Animatable.init(self, def)
end

function GameObject:update(dt)
    Animatable.update(self, dt)
end

function GameObject:draw()
    Animatable.draw(self)
end