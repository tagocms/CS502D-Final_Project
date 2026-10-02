local gameWidth, gameHeight = 1080, 720 --fixed game resolution
local windowWidth, windowHeight = 1080, 720

local Game = {}

function Game:init()
    Push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {
        fullscreen = false,
        vsync = true,
        resizable = true,
        upscale = 'normal'
    })
    self.gameMap = Sti('src/maps/CastleOutside.lua')
    self.camera = Camera()
    self.cameraPosition = {x = gameWidth / 2, y = gameHeight / 2}
    
    love.window.setTitle("Age of Bandits")
    -- TODO: Not the permanent icon
    love.window.setIcon(love.image.newImageData("sprites/cursor/mouse_icon1-SwordPointer.png"))
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

    local mapWidth = self.gameMap.width * self.gameMap.tilewidth
    local mapHeight = self.gameMap.height * self.gameMap.tileheight

    -- Right border
    if self.camera.x > (mapWidth - screenSize.width / 2) then
        self.camera.x = (mapWidth - screenSize.width / 2)
    end

    -- Bottom border
    if self.camera.y > (mapHeight - screenSize.height / 2) then
        self.camera.y = (mapHeight - screenSize.height / 2)
    end
end

function Game:draw()
    self.camera:attach()
        self.gameMap:drawLayer(self.gameMap.layers["Background"])
        self.gameMap:drawLayer(self.gameMap.layers["BackMiddleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Middleground"])
        self.gameMap:drawLayer(self.gameMap.layers["Foreground"])
        love.graphics.print("Hello, world!", gameWidth / 2, gameHeight / 2)
    self.camera:detach()
end

function Game:keypressed(key)
    if key == 'escape' then
		love.event.quit()
	end
end

return Game