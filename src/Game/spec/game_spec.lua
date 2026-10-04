require 'dependencies'

describe('Map loading', function ()
    it('Loads a 60x60 grid', function() 
        local gameMap = Sti('src/maps/CastleOutside.lua')
        assert(gameMap.width * gameMap.height == 60 * 60, 'Map grid size divergent from 60 * 60.')
    end)
    
end)