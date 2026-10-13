Animatable = Class{}

function Animatable:init(def)
    self.position = {
        x = def.position.x or 0,
        y = def.position.y or 0
    }
    self.size = {
        width = def.size.width or 0,
        height = def.size.height or 0
    }

    self:initializeAnimations(def.animations, def.defaultAnimation)
end

function Animatable:initializeAnimations(animations, defaultAnimation)
    local defaultAnimation = defaultAnimation or 'idle'

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

    local currentAnimation
    if self.animations[defaultAnimation] then
        currentAnimation = self.animations[defaultAnimation]
    end
    self.currentAnimation = currentAnimation
end

function Animatable:update(dt)
    if not self.currentAnimation then return end
    self.currentAnimation:update(dt)
end

function Animatable:setCurrentAnimation(newAnimation)
    if self.animations[newAnimation] then
        self.currentAnimation = self.animations[newAnimation]
    else
        self.currentAnimation = nil
    end
end

function Animatable:draw(scaleX, scaleY, offsetX, offsetY)
    if not self.currentAnimation then return end
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