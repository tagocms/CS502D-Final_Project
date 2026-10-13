TEXTURES = {
    ['player-soldier'] = love.graphics.newImage('sprites/entities/Human_Soldier_Mace_Shield/With_Shadows/Human_Soldier_Mace_Shield-Sheet.png'),
    ['enemy-fist'] = love.graphics.newImage('sprites/entities/Monster_Orc_Fist/With_Shadows/Monster_Orc_Fist-Sheet.png')
}

FRAMES = {
    ['player-soldier'] = GenerateQuads(TEXTURES['player-soldier'], ENTITIES['player'].size.width, ENTITIES['player'].size.height),
    ['enemy-fist'] = GenerateQuads(TEXTURES['enemy-fist'], ENTITIES['enemy'].size.width, ENTITIES['enemy'].size.height)
}