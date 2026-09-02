local gameWidth, gameHeight = 1080, 720 --fixed game resolution
local windowWidth, windowHeight = 1080, 720

local Game = {}

function Game:init()
    
    
    Push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {fullscreen = false})
end

function Game:update(dt)
    
end

function Game:draw()
    Push:start()
    love.graphics.print("Hello, world!", gameWidth / 2, gameHeight / 2)
    Push:finish()
end

function Game:keypressed(key)
    if key == 'escape' then
		love.event.quit()
	end
end

return Game