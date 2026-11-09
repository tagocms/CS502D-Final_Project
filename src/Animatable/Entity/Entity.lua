---@class Entity: Animatable
---@field anchorTilePosition Position
---@field sizeInTiles Size
---@field speed number? In tiles/second
---@field numberOnGrid integer
---@field occupiedTiles Position[]
---@field path JumperPath?
---@field isMoving boolean
---@field isDestroyed boolean
Entity = Class{__includes = Animatable}

---@class EntityDef: AnimatableDef
---@field speed number?
---@field numberOnGrid integer
---@field occupiedTiles Position[]?
---@field levelGrid LevelGrid

---@param def EntityDef Initialization definitions for Entity class
function Entity:init(def)
    Animatable.init(self, def)
    self.numberOnGrid = def.numberOnGrid
    self.occupiedTiles = def.occupiedTiles or {}
    self.levelGrid = def.levelGrid

    self.anchorTilePosition = self.levelGrid:convertPositionToGrid(self.position)
    self.sizeInTiles = {
        width = math.ceil(self.size.width / self.levelGrid._tileSize.width),
        height = math.ceil(self.size.height / self.levelGrid._tileSize.height)
    }

    self.speed = def.speed or 10
    self.isMoving = false
    self.isDestroyed = false
    self:place()
end

function Entity:update(dt)
    Animatable.update(self, dt)
    if self.isMoving then
        self:setCurrentAnimation('walk')
    else
        self:setCurrentAnimation('idle')
    end
end

function Entity:place()
    self.levelGrid:place(self, self.anchorTilePosition)
end

function Entity:moveTo(newTilePosition, tweenTime)
    if not self.isMoving then
        self:animateMovement(newTilePosition, tweenTime)
    end
end

function Entity:remove()
    self.levelGrid:remove(self)
    self.isDestroyed = true
end

function Entity:animateMovement(newTilePosition, tweenTime)
    self.path = self.levelGrid:getPath(self.anchorTilePosition, newTilePosition, self)
    if self.path then
        local length = self.path:getLength()
        local timePerSegment = tweenTime / length
        self.isMoving = true
        for node, count in self.path:iter() do
            local newPixelPosition = self.levelGrid:convertPositionToPixelsInTileStart({x = node:getX(), y = node:getY()})
            Timer.after(timePerSegment * count, function ()
                if not self.levelGrid:move(self, {x = node:getX(), y = node:getY()}) then return end
                Timer.tween(timePerSegment, {
                        [self.position] = {x = newPixelPosition.x, y = newPixelPosition.y}
                })
                :finish(function ()
                    self.anchorTilePosition = newTilePosition
                    if count == length then
                        self.path = nil
                        self.isMoving = false
                    end
                end)
            end)
        end
    end
end


---Sets the player's movement target to the pixel position
---@param pixelPosition Position Destination position
function Entity:setMovementTarget(pixelPosition)
    local gridTarget = self.levelGrid:convertPositionToGrid(pixelPosition)
    self:moveTo(
        gridTarget, 
        self.levelGrid:distanceBetweenEntities(self, {anchorTilePosition = gridTarget, sizeInTiles = {width = 1, height = 1}}) / self.speed
    )
end

function Entity:draw()
    if self.path then
        local previousNode
        local tileSize = self.levelGrid._tileSize
        local tileWidth, tileHeight = tileSize.width, tileSize.height
        for node, count in self.path:iter() do
            if previousNode then
                love.graphics.line(
                (previousNode:getX() - 1) * tileWidth + tileWidth / 2,
                (previousNode:getY() - 1) * tileHeight + tileHeight / 2,
                (node:getX() - 1) * tileWidth + tileWidth / 2,
                (node:getY() - 1) * tileHeight + tileHeight / 2
            )
            end
            previousNode = node
        end
    end

    Animatable.draw(self)
end

function Entity:getClassName()
    return 'Entity'
end