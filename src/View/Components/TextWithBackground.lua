TextWithBackground = Class{__includes = View}

function TextWithBackground:init(def)
    View.init(self, def)

    self.font = def.font
    self.text = def.text or ''
    self.textAlign = def.textAlign or 'center'
    self.textColor = {
        red = def.textColor.red or 1,
        green = def.textColor.green or 1,
        blue = def.textColor.blue or 1,
        alpha = def.textColor.alpha or 1
    }

    self.filled = def.filled or false
    self.cornerRadius = def.cornerRadius or 0
    self.backgroundColor = {
        red = def.backgroundColor.red or 1,
        green = def.backgroundColor.green or 1,
        blue = def.backgroundColor.blue or 1,
        alpha = def.backgroundColor.alpha or 1
    }
    self.padding = {
        horizontal = def.padding.horizontal or 0,
        vertical = def.padding.vertical or 0,
    }

    self.isDisabled = def.isDisabled or false
    self.onInteractionCallback = def.onInteractionCallback or function (mouseButtonsPressed) end

    self.defaultTextColor = deepcopy(self.textColor)
    self.defaultBackgroundColor = deepcopy(self.backgroundColor)

    self.isHoverAllowed = def.isHoverAllowed or false
    local hoveredColors = self:newColorsForState('hovered')
    self.hoveredTextColor = hoveredColors.newTextColor
    self.hoveredBackgroundColor = hoveredColors.newBackgroundColor

    self.isInteracting = false
    local interactedColors = self:newColorsForState('interacted')
    self.interactedTextColor = interactedColors.newTextColor
    self.interactedBackgroundColor = interactedColors.newBackgroundColor

    if self.isDisabled then
        local disabledColors = self:newColorsForState('disabled')
        self.textColor = disabledColors.newTextColor
        self.backgroundColor = disabledColors.newBackgroundColor
    end
end

function TextWithBackground:update(dt, params)
    if self.isDisabled then return end
    if View.isIntersecting(
        {
            size = {width = 1, height = 1},
            position = params.realMousePosition
        },
        self:getBbox()
    ) then
        if self:isColorDifferentFrom('hovered') and not self.isInteracting then
            self.textColor = self.hoveredTextColor
            self.backgroundColor = self.hoveredBackgroundColor
        end
        local wasInteracted = self.onInteractionCallback(params.mouseButtonsPressed)
        if wasInteracted then
            self:fireInteractionAnimation()
        end
    else
        if self:isColorDifferentFrom('default') and not self.isInteracting then
            self.textColor = self.defaultTextColor
            self.backgroundColor = self.defaultBackgroundColor
        end
    end
end

function TextWithBackground:fireInteractionAnimation()
    self.isInteracting = true
    self.backgroundColor = self.interactedBackgroundColor
    self.textColor = self.interactedTextColor
    Timer.after(0.1, function ()
        self.isInteracting = false
    end)
end

function TextWithBackground:isColorDifferentFrom(state)
    if state == 'hovered' then
        return (
            self.backgroundColor ~= self.hoveredBackgroundColor
            or self.textColor ~= self.hoveredTextColor
        )
    elseif state == 'default' then
        return (
            self.backgroundColor ~= self.defaultBackgroundColor
            or self.textColor ~= self.defaultTextColor
        )
    end

    return false
end

function TextWithBackground:newColorsForState(state)
    local newTextColor = deepcopy(self.defaultTextColor)
    local newBackgroundColor = deepcopy(self.defaultBackgroundColor)

    if state == 'hovered' then
        newTextColor.alpha = newTextColor.alpha * 0.8
        newBackgroundColor.alpha = newBackgroundColor.alpha * 0.6
    elseif state == 'interacted' then
        newTextColor.alpha = newTextColor.alpha * 0.6
        newBackgroundColor.alpha = newBackgroundColor.alpha * 0.4
    elseif state == 'disabled' then
        newTextColor = {
            red = 0.6,
            green = 0.6,
            blue = 0.6,
            alpha = 1
        }
        newBackgroundColor = {
            red = 0.4,
            green = 0.4,
            blue = 0.4,
            alpha = 1
        }
    end

    return {
        newTextColor = newTextColor,
        newBackgroundColor = newBackgroundColor
    }
end

function TextWithBackground:draw()
    local size = self:getSize()

    -- BACKGROUND
    love.graphics.setColor(
        self.backgroundColor.red,
        self.backgroundColor.green,
        self.backgroundColor.blue,
        self.backgroundColor.alpha
    )
    love.graphics.rectangle(
        self.filled and 'fill' or 'line',
        self.position.x, self.position.y,
        size.width,
        size.height,
        self.cornerRadius, self.cornerRadius
    )

    -- TEXT
    if self.font then
        love.graphics.setFont(self.font)
    end
    love.graphics.setColor(
        self.textColor.red,
        self.textColor.green,
        self.textColor.blue,
        self.textColor.alpha
    )
    love.graphics.printf(
        self.text,
        self.position.x + self.padding.horizontal,
        self.position.y + self.padding.vertical,
        size.wrapLimit,
        self.textAlign
    )

    View.clear()
end

function TextWithBackground:getTextSizeForFont(font)
    local previousFont = love.graphics.getFont()

    if font then
        love.graphics.setFont(font)
    end
    local currentFont = love.graphics.getFont()
    local wrapLimit
    if self.size.width then
        wrapLimit = self.size.width - (2 * self.padding.horizontal)
    else
        wrapLimit = currentFont:getWidth(self.text)
    end
    local textWidth, wrappedText = currentFont:getWrap(self.text, wrapLimit)
    local textHeight = currentFont:getHeight() * (#wrappedText)

    -- Reset previousFont
    love.graphics.setFont(previousFont)
    
    return {
        width = textWidth,
        height = textHeight,
        wrapLimit = wrapLimit
    }
end

function TextWithBackground:getSize()
    local textSize = self:getTextSizeForFont(self.font)

    return {
        width = self.size.width or (textSize.width + (2 * self.padding.horizontal)),
        height = self.size.height or (textSize.height + (2 * self.padding.vertical)),
        wrapLimit = textSize.wrapLimit
    }
end

function TextWithBackground:getBbox()
    local size = self:getSize()
    return {
        size = {width = size.width, height = size.height},
        position = self.position
    }
end