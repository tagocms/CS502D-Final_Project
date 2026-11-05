TEXTURES = {
    ['player-soldier'] = love.graphics.newImage('sprites/entities/Human_Soldier_Mace_Shield/With_Shadows/Human_Soldier_Mace_Shield-Sheet.png'),
    ['enemy-fist'] = love.graphics.newImage('sprites/entities/Monster_Orc_Fist/With_Shadows/Monster_Orc_Fist-Sheet.png')
}

FRAMES = {
    ['player-soldier'] = GenerateQuads(TEXTURES['player-soldier'], ENTITIES['player'].spriteSize.width, ENTITIES['player'].spriteSize.height),
    ['enemy-fist'] = GenerateQuads(TEXTURES['enemy-fist'], ENTITIES['enemy'].spriteSize.width, ENTITIES['enemy'].spriteSize.height)
}

CURSOR_IMAGE_DATA = {
    ['default'] = love.image.newImageData('sprites/cursor/mouse_icon21-Default.png'),
    ['move'] = love.image.newImageData('sprites/cursor/mouse_icon15-Directions.png'),
    ['attack'] = love.image.newImageData('sprites/cursor/mouse_icon1-SwordPointer.png'),
    ['defend'] = love.image.newImageData('sprites/cursor/mouse_icon2-Shield.png'),
    ['action-blocked'] = love.image.newImageData('sprites/cursor/mouse_icon5-Blocked.png'),
    ['grab'] = love.image.newImageData('sprites/cursor/mouse_icon3-Hand.png'),
}

TILE_SIZE = 32
GRID_SIZE = 60