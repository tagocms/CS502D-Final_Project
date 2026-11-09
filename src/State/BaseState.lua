---@class State
---@field init fun(self: State)
---@field exit fun(self: State)
---@field update fun(self: State, dt: number, params: table?)
---@field draw fun(self: State)
---@field getName fun(): string
BaseState = Class{}

function BaseState:init() end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:draw() end
function BaseState.getName() return '' end