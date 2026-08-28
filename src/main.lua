require 'dependencies'

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
end

function love.draw()
	love.graphics.print("Hello, world!", 400, 300)
end
