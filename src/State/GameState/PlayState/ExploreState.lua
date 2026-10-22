ExploreState = Class {__includes = BaseState}

function ExploreState:init(def)
    self.gameMap = def.gameMap
    self.mapSize = def.mapSize
    self.camera = def.camera
    self.world = def.world
    self.enemies = def.enemies
    self.player = def.player
    self.getScreenSize = def.getScreenSize

    self.isCameraLocked = def.isCameraLocked or false
    self:initializeViews()
end

function ExploreState:getLockCameraToggleButtonText()
    return self.isCameraLocked and 'Unlock camera (k)' or 'Lock camera (k)'
end

function ExploreState:update(dt, params)
    for i, enemy in pairs(self.enemies) do
        enemy:update(dt)
    end
    self:updatePhysicsWorldAndEntitiesPosition(dt)

    self:handleInput(dt, params)
    self:updateViews(dt, params)
end

function ExploreState:handleInput(dt, params)

    self:handleCameraMovement(params.keysDown)
    if params.keysPressed:isInteracted('k') then
        self.isCameraLocked = not self.isCameraLocked
        self.views.lockCameraToggleButton.text = self:getLockCameraToggleButtonText()
    end

    if self:mouseIntersectsAnyView(params.realMousePosition) then
        self.player:update(dt, params, false)
    else
        self.player:update(dt, params, true)
    end
end

function ExploreState:mouseIntersectsAnyView(realMousePosition)
    for k, view in pairs(self.views) do
        if View.isIntersecting({
            size = {width = 1, height = 1},
            position = realMousePosition
        }, view:getBbox()) then
            return true
        end
    end

    return false
end

function ExploreState:handleCameraMovement(keysDown)
    if self.isCameraLocked then
        self.camera:lookAt(self.player.position.x, self.player.position.y)
    else
        if keysDown:isInteracted('up') then
            self.camera.y = self.camera.y - self.camera.speed
        end
        if keysDown:isInteracted('down') then
            self.camera.y = self.camera.y + self.camera.speed
        end
        if keysDown:isInteracted('left') then
            self.camera.x = self.camera.x - self.camera.speed
        end
        if keysDown:isInteracted('right') then
            self.camera.x = self.camera.x + self.camera.speed
        end
    end 

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

function ExploreState:updateViews(dt, params)
    for k, view in pairs(self.views) do
        view:update(dt, params)
    end
end

function ExploreState:initializeViews()
    local screenSize = self.getScreenSize()
    local lockCameraToggleButton = TextWithBackground {
        position = {x = screenSize.width - 200, y = 40},
        text = self:getLockCameraToggleButtonText(),
        filled = true,
        textColor = {red = 1, green = 1, blue = 1, alpha = 1},
        backgroundColor = {red = 0, green = 0, blue = 0, alpha = 1},
        padding = {horizontal = 16, vertical = 8},
        textAlign = 'center',
        cornerRadius = 8,
    }
    lockCameraToggleButton.onNoInteractionCallback = function ()
        lockCameraToggleButton.backgroundColor = {red = 0, green = 0, blue = 0, alpha = 1}
    end
    lockCameraToggleButton.onInteractionCallback = function (mouseButtonsPressed)
        if mouseButtonsPressed:isInteracted(1) then
            self.isCameraLocked = not self.isCameraLocked
            lockCameraToggleButton.text = self:getLockCameraToggleButtonText()
        else
            lockCameraToggleButton.backgroundColor = {red = 0.5, green = 0.5, blue = 0.5, alpha = 1}
        end
    end

        
    self.views = {
        lockCameraToggleButton = lockCameraToggleButton
    }
end

function ExploreState:draw()
    for k, view in pairs(self.views) do
        view:draw()
    end
end

function ExploreState.getName()
    return 'ExploreState'
end