View = Class{}

function View:init(def)
    if def.size then
        self.size = {
            width = def.size.width or nil,
            height = def.size.height or nil
        }
    else
        self.size = {width = nil, height = nil}
    end
    if def.position then
        self.position = {
            x = def.position.x or 0,
            y = def.position.y or 0
        }
    else
        self.position = {x = nil, y = nil}
    end
end

function View:update(dt)
    
end

function View:draw()

end

function View:getBbox()
    return {
        size = self.size,
        position = self.position
    }
end

function View.clear()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont())
end

function View.isIntersecting(bbox1, bbox2)
    if bbox1.position.x + bbox1.size.width < bbox2.position.x then
        return false
    end

    if bbox1.position.y + bbox1.size.height < bbox2.position.y then
        return false
    end

    if bbox1.position.x > bbox2.position.x + bbox2.size.width then
        return false
    end

    if bbox1.position.y > bbox2.position.y + bbox2.size.height then
        return false
    end

    return true
end