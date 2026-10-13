ENTITIES = {
    ['player'] = {
        animations = {
            ['idle'] = {
                frames = {1, 2, 3, 4, 5, 6},
                interval = 0.3,
                texture = 'player-soldier'
            },
            ['walk'] = {
                frames = {11, 12, 13, 14, 15, 16, 17, 18},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['jump'] = {
                frames = {21, 22, 23, 24, 25, 26},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['block'] = {
                frames = {31, 32, 33, 34, 35, 36},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['attack-main'] = {
                frames = {41, 42, 43, 44, 45, 46, 47, 48},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['attack-special'] = {
                frames = {51, 52, 53, 54, 55, 56, 57, 58},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['hurt'] = {
                frames = {61, 62, 63, 64, 65, 66},
                interval = 0.1,
                texture = 'player-soldier'
            },
            ['death'] = {
                frames = {71, 72, 73, 74, 75, 76, 77, 78, 79, 80},
                interval = 0.2,
                texture = 'player-soldier'
            },
        },
        defaultAnimation = 'idle',
        size = {
            width = 96,
            height = 96
        },
        speed = 500
    },
    ['enemy'] = {
        animations = {
            ['idle'] = {
                frames = {1, 2, 3, 4, 5, 6},
                interval = 0.3,
                texture = 'enemy-fist'
            },
            ['walk'] = {
                frames = {11, 12, 13, 14, 15, 16, 17, 18},
                interval = 0.1,
                texture = 'enemy-fist'
            },
            ['jump'] = {
                frames = {21, 22, 23, 24, 25, 26},
                interval = 0.1,
                texture = 'enemy-fist'
            },
            ['block'] = {
                frames = {31, 32, 33, 34, 35, 36},
                interval = 0.1,
                texture = 'enemy-fist'
            },
            ['attack-main'] = {
                frames = {41, 42, 43, 44, 45, 46, 47, 48},
                interval = 0.1,
                texture = 'enemy-fist'
            },
            ['attack-special'] = {
                frames = {51, 52, 53, 54, 55, 56, 57, 58},
                interval = 0.1,
                texture = 'enemy-fist'
            },
            ['hurt'] = {
                frames = {61, 62, 63, 64, 65, 66},
                interval = 0.1,
                texture = 'enemy-fist'
            },
            ['death'] = {
                frames = {71, 72, 73, 74, 75, 76, 77, 78, 79, 80},
                interval = 0.2,
                texture = 'enemy-fist'
            },
        },
        defaultAnimation = 'idle',
        size = {
            width = 96,
            height = 96
        }
    }
}