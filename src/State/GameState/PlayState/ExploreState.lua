ExploreState = Class {__includes = BaseState}

function ExploreState:init(def)
    self.gameMap = def.gameMap
    self.mapSize = def.mapSize
    self.camera = def.camera
    self.world = def.world
    self.enemies = def.enemies
    self.player = def.player
    self.getScreenSize = def.getScreenSize
end

function ExploreState:update(dt, params)
    for i, enemy in pairs(self.enemies) do
        enemy:update(dt)
    end
    self.player:update(dt, params.keysDown)

    self:updatePhysicsWorldAndEntitiesPosition(dt)
    self:handleCameraMovement()
end

function ExploreState:handleCameraMovement()
    self.camera:lookAt(self.player.position.x, self.player.position.y)

    local screenSize = self.getScreenSize()

    -- Left border
    if self.camera.x < screenSize.width / 2 then
        self.camera.x = screenSize.width / 2
    end

    -- Top border
    if self.camera.y < screenSize.height / 2 then
        self.camera.y = screenSize.height / 2
    end

    -- Right border
    if self.camera.x > (self.mapSize.width - screenSize.width / 2) then
        self.camera.x = (self.mapSize.width - screenSize.width / 2)
    end

    -- Bottom border
    if self.camera.y > (self.mapSize.height - screenSize.height / 2) then
        self.camera.y = (self.mapSize.height - screenSize.height / 2)
    end
end

function ExploreState:updatePhysicsWorldAndEntitiesPosition(dt)
    self.world:update(dt)
    for i, enemy in pairs(self.enemies) do
        enemy:updatePosition()
    end
    self.player:updatePosition()
end

function ExploreState:draw()
    self.camera:attach()
        self.gameMap:drawLayer(self.gameMap.layers["Background"])
        self.gameMap:drawLayer(self.gameMap.layers["BackMiddleground"])

        for i, enemy in pairs(self.enemies) do
            enemy:draw()
        end
        self.player:draw()

        self.gameMap:drawLayer(self.gameMap.layers["Middleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Foreground"])
    self.camera:detach()
end

function ExploreState.getName()
    return 'ExploreState'
end