Collidable = Class{}

function Collidable:init(def)
    local object = def.object

    local isPolygon = object.shape == 'polygon'
    if isPolygon then
        local vertices = object.polygon
        local minX = vertices[1].x
        local maxX = vertices[1].x
        local minY = vertices[1].y
        local maxY = vertices[1].y

        for i = 2, #vertices do
            local p = vertices[i]
            if p.x < minX then minX = p.x end
            if p.x > maxX then maxX = p.x end
            if p.y < minY then minY = p.y end
            if p.y > maxY then maxY = p.y end
        end

        self.size = {
            width = maxX - minX,
            height = maxY - minY
        }
        self.position = {
            x = minX,
            y = minY
        }
    else
        self.size = {
            width = object.width,
            height = object.height
        }
        self.position = {
            x = object.x,
            y = object.y
        }
    end
end

function Collidable:getPosition()
    return self.position
end

function Collidable:getSize()
    return self.size
end