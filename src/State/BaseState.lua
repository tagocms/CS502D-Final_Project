BaseState = Class{}

function BaseState:init() end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:draw() end
function BaseState.getName() return '' end