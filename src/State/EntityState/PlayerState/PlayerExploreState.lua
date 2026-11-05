PlayerExploreState = Class{__includes = BaseState}

function PlayerExploreState:init(def)
    self.setMovementTarget = def.setMovementTarget
end

function PlayerExploreState:exit()
    self.setMovementTarget(nil)
end

function PlayerExploreState:update(dt, params)
    self:handleMouseInput(dt, params.mouseButtonsPressed, params.mousePosition)
end

function PlayerExploreState:handleMouseInput(dt, mouseButtonsPressed, mousePosition)
    if mouseButtonsPressed:isInteracted(1) then
        self.setMovementTarget(mousePosition)
    end
end

function PlayerExploreState.getName()
    return 'PlayerExploreState'
end