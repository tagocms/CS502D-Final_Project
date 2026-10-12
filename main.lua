local game = nil
-- Main functions
function love.load(args)
    require 'dependencies'
    
    -- Run the specs inside LÖVE: `love . --test [busted args]`
    if args[1] == '--test' then
        local code = 0
        arg = { select(2, unpack(args)) } -- busted reads the global `arg`
        local ok, err = pcall(require('busted.runner'), { standalone = false })
        if not ok then print(err) code = 1 end
        love.event.quit(code)
        return
    end

    game = Game()
end
function love.update(dt) 
    if game then
        game:update(dt) 
    end
end
function love.draw()
    if game then
        game:draw() 
    end
end

-- Auxiliary functions
function love.keypressed(key) 
    if game then
        game:keypressed(key) 
    end
end
