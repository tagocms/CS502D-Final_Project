local windowWidth, windowHeight = 1080, 720

local Game = {}

function Game:init()
    love.window.setMode(windowWidth, windowHeight, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })
    love.window.setTitle("Age of Bandits")
    -- TODO: Not the permanent icon
    love.window.setIcon(love.image.newImageData("sprites/cursor/mouse_icon1-SwordPointer.png"))

    self.gameMap = Sti('src/maps/CastleOutside.lua')
    self.mapSize = {
        width = self.gameMap.width * self.gameMap.tilewidth,
        height = self.gameMap.height * self.gameMap.tileheight
    }
    
    self.camera = Camera()
    self.cameraPosition = {x = windowWidth / 2, y = windowHeight / 2}
end

function Game:update(dt)
    if love.keyboard.isDown("w") then
        self.cameraPosition.y = self.cameraPosition.y - 10
    end
     if love.keyboard.isDown("s") then
        self.cameraPosition.y = self.cameraPosition.y + 10
     end
    if love.keyboard.isDown("a") then
        self.cameraPosition.x = self.cameraPosition.x - 10
    end
    if love.keyboard.isDown("d") then
        self.cameraPosition.x = self.cameraPosition.x + 10
    end

    self.camera:lookAt(self.cameraPosition.x, self.cameraPosition.y)

    local screenSize = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }

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

function Game:draw()
    self.camera:attach()
        self.gameMap:drawLayer(self.gameMap.layers["Background"])
        self.gameMap:drawLayer(self.gameMap.layers["BackMiddleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Middleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Foreground"])
    self.camera:detach()
end

function Game:keypressed(key)
    if key == 'escape' then
		love.event.quit()
	end
end

return Game