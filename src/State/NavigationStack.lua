NavigationStack = Class{__includes = Stack}

function NavigationStack:draw()
    if not self:getCurrentItem() then return end

    self:getCurrentItem():draw()
end

function NavigationStack.getName()
    return 'NavigationStack'
end