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

    self.defaultAnimation = def.defaultAnimation
    self:initializeAnimations(def.animations)
end

function Animatable:initializeAnimations(animations)
    self.animations = {}
    for key, animation in pairs(animations) do
        local newAnimation = Animation {
            frames = animation.frames,
            interval = animation.interval,
            texture = animation.texture,
            looping = animation.looping or true,
        }  
        self.animations[key] = newAnimation
    end
    self.currentAnimation = self.animations[self.defaultAnimation]
end

function Animatable:update(dt)
    self.currentAnimation:update(dt)
end

function Animatable:draw(scaleX, scaleY, offsetX, offsetY)
    local anim = self.currentAnimation
    local scaleX = scaleX or 1
    local scaleY = scaleY or 1
    local offsetX = offsetX or nil
    local offsetY = offsetY or nil

    love.graphics.draw(
        TEXTURES[anim.texture], FRAMES[anim.texture][anim:getCurrentFrame()], 
        self.position.x, self.position.y,
        nil,
        scaleX, scaleY,
        offsetX, offsetY, 
        nil, nil
    )
end