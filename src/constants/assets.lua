TEXTURES = {
    ['player-soldier'] = love.graphics.newImage('sprites/entities/Human_Soldier_Mace_Shield/With_Shadows/Human_Soldier_Mace_Shield-Sheet.png')
}

FRAMES = {
    ['player-soldier'] = GenerateQuads(TEXTURES['player-soldier'], ENTITIES['player'].size.width, ENTITIES['player'].size.height)
}