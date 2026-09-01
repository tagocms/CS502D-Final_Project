require 'dependencies'

-- Main functions
function love.load() Game:init() end
function love.update(dt) Game:update(dt) end
function love.draw() Game:draw() end

-- Auxiliary functions
function love.keypressed(key) Game:keypressed(key) end
