Stack = Class{__includes = BaseState}

function Stack:init(def)
    self._activeItems = {}
    if def.newItem then
        self:pushNewItem(def.newItem)
    end
end

function Stack:exit()
    self:clearStack()
end

function Stack:pushNewItem(newItem)
    table.insert(self._activeItems, newItem)
end

function Stack:popCurrentItem()
    if not self:getCurrentItem() then return end
    
    self:getCurrentItem():exit()
    table.remove(self._activeItems, #self._activeItems)
end

function Stack:popAllItemsTo(itemName)
    if not self:getCurrentItem() then return end
    if not self:isItemInActiveItems(itemName) then return end

    for i, item in ipairs_reverse(self._activeItems) do
        if not item.getName() == itemName then
            self:popCurrentItem()
        else
            return
        end
    end
end

function Stack:clearStack()
    if not self:getCurrentItem() then return end

    for i, item in ipairs_reverse(self._activeItems) do
        self:popCurrentItem()
    end
end

function Stack:getCurrentItem()
    if not (tablelength(self._activeItems) > 0) then return nil end

    return self._activeItems[#self._activeItems]
end

function Stack:getActiveItems()
    return self._activeItems
end

function Stack:isItemInActiveItems(currentItemName)
    for i, item in ipairs(self._activeItems) do
        if item.getName() == currentItemName then
            return true
        end
    end

    return false
end

function Stack:update(dt, params)
    if not self:getCurrentItem() then return end

    self:getCurrentItem():update(dt, params)
end

function Stack:draw()
    if not self:getCurrentItem() then return end
    
    for i, item in pairs(self._activeItems) do
        item:draw()
    end
end

function Stack.getName()
    return 'Stack'
end