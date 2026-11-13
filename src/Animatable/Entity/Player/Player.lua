---@class Player: Entity
---@field stateMachine StateMachine
Player = Class{ __includes = Entity }

---@class PlayerDef: EntityDef
---@field cursor Cursor

---@param def PlayerDef Initialization definitions for Player class
function Player:init(def)
    Entity.init(self, def)
    self.stateMachine = StateMachine {
        availableStates = {
            [PlayerExploreState.getName()] = PlayerExploreState,
            [PlayerBattleIdleState.getName()] = PlayerBattleIdleState,
        },
        initialStateName = PlayerExploreState.getName(),
        initialStateParams = {
            playerSpeed = self.speed,
            setMovementTarget = function (position) self:setMovementTarget(position) end
        }
    }

    self.cursor = def.cursor
end

function Player:update(dt, params, canInput)
    Entity.update(self, dt)
    if canInput then
        self.stateMachine:update(dt, params)
    end
    self:updateCursor(dt, params, canInput)
end

function Player:updateCursor(dt, params, canInput)
    local anchor = self.levelGrid:tilePositionFromPixel(params.mousePosition, self.sizeInTiles)
    local anchorConverted = self.levelGrid:convertPositionToPixelsInTileStart(anchor)
    local isAreaFree = self.levelGrid:isAreaFree(anchor, self.sizeInTiles, {self})
    local cursorParams = {position = anchorConverted, size = self.size}
    local currentStateName = self.cursor:getStateName()
    if not canInput then
        if currentStateName ~= CursorDefaultState.getName() then
            self.cursor:changeState(CursorDefaultState.getName(), {})
        end
    else
        if anchor 
        and isAreaFree
        and currentStateName ~= CursorMoveState.getName() then
            self.cursor:changeState(CursorMoveState.getName(), cursorParams)
        elseif (not anchor or not isAreaFree)
        and currentStateName ~= CursorInvalidState.getName() then
            self.cursor:changeState(CursorInvalidState.getName(), cursorParams)
        else
            self.cursor:update(dt, cursorParams)
        end
    end
end

function Player:getClassName()
    return 'Player'
end