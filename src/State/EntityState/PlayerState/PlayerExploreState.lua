PlayerExploreState = Class{__includes = BaseState}

function PlayerExploreState:init(def)
    self.setMovementTarget = def.setMovementTarget
end

function PlayerExploreState:exit()
    self.setMovementTarget(nil)
end

function PlayerExploreState:update(dt, params)
    self:handleMouseInput(dt, params.mouseButtonsDown, params.mousePosition)
end

function PlayerExploreState:handleMouseInput(dt, mouseButtonsDown, mousePosition)
    if mouseButtonsDown:isInteracted(1) then
        self.setMovementTarget(mousePosition)
    end
end

function PlayerExploreState.getName()
    return 'PlayerExploreState'
end