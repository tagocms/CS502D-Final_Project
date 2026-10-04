require 'dependencies'

-- Main functions
function love.load(args)
    -- Run the specs inside LÖVE: `love . --test [busted args]`
    if args[1] == '--test' then
        local code = 0
        arg = { select(2, unpack(args)) } -- busted reads the global `arg`
        local ok, err = pcall(require('busted.runner'), { standalone = false })
        if not ok then print(err) code = 1 end
        love.event.quit(code)
        return
    end

    Game:init()
end
function love.update(dt) Game:update(dt) end
function love.draw() Game:draw() end

-- Auxiliary functions
function love.keypressed(key) Game:keypressed(key) end
