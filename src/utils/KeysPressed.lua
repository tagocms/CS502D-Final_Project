KeysInteracted = Class{}

function KeysInteracted:init()
    self:clear()
end

function KeysInteracted:clear()
    self.keysPressed = {}
end

function KeysInteracted:setKeyInteracted(key)
    self.keysPressed[key] = true
end

function KeysInteracted:isInteracted(key)
    return self.keysPressed[key]
end