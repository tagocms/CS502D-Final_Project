PlayerExploreState = Class{__includes = BaseState}

function PlayerExploreState:init(def)
    self.setMovementTarget = def.setMovementTarget
    self.updateCursor = def.updateCursor
end

function PlayerExploreState:exit()

end

function PlayerExploreState:update(dt, params)
    self.updateCursor(dt, params, params.canInput)
    if params.canInput then
        self:handleMouseInput(params.mouseButtonsPressed, params.mousePosition)
    end
end

function PlayerExploreState:handleMouseInput(mouseButtonsPressed, mousePosition)
    if mouseButtonsPressed:isInteracted(1) then
        self.setMovementTarget(mousePosition)
    end
end

function PlayerExploreState.getName()
    return 'PlayerExploreState'
end