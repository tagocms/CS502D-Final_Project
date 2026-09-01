local Game = {}

function Game:init()
    
end

function Game:update(dt)
    
end

function Game:draw()
    love.graphics.print("Hello, world!", 400, 300)
end

function Game:keypressed(key)
    if key == 'escape' then
		love.event.quit()
	end
end

return Game