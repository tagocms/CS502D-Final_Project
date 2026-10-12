Animatable = Class{}

function Animatable:init(def)
    self.position = {
        x = def.position.x,
        y = def.position.y
    }
    self.size = {
        width = def.size.width,
        height = def.size.height
    }
    self:initializeAnimations(def.animations)
end

function Animatable:initializeAnimations(animations)
    self.animations = {}
    self.currentAnimation = nil
    for key, animation in pairs(animations) do
        local animation = Animation {
            frames = animation.frames,
            interval = animation.interval,
            texture = animation.texture,
            looping = animation.looping or true
        }  
        self.animations[key] = animation

        if not self.currentAnimation then
            self.currentAnimation = animation
        end
    end
end

function Animatable:update(dt)
    self.currentAnimation:update(dt)
end

function Animatable:draw()
    local anim = self.currentAnimation
    love.graphics.draw(TEXTURES[anim.texture], FRAMES[anim.texture][anim:getCurrentFrame()], self.position.x, self.position.y)
end