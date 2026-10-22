KeysInteracted = Class{}

function KeysInteracted:init()
    self:clear()
end

function KeysInteracted:clear()
    self.keysInteracted = {}
end

function KeysInteracted:setKeyInteracted(key)
    self.keysInteracted[key] = true
end

function KeysInteracted:isInteracted(key)
    return self.keysInteracted[key]
end

function KeysInteracted:hasAnyInteraction()
    for k, value in pairs(self.keysInteracted) do
        if value then
            return true
        end
    end

    return false
end