local Mouse = {
    x = 0,
    y = 0,
    buttons = { left = false, right = false },
    state = {},
}

function Mouse:init()
    -- love.mouse.setRelativeMode(true)
end

---@return Vec2
function Mouse:getPosition()
    return Vec2.new(Util.round(self.x), Util.round(self.y))
end

---@return Vec2
function Mouse:getAbsolutePosition()
    return Vec2.new(self.x - Camera.position.x + VIEW_WIDTH / 2,
                    self.y - Camera.position.y + VIEW_HEIGHT / 2)
end

---@param right? boolean
function Mouse:isDown(right)
    if right then
        return self.buttons.right
    else
        return self.buttons.left
    end
end

function Mouse:isJustDown(right)
    if right then
        return self.buttons.right and not self.state[2].right
    else
        return self.buttons.left and not self.state[2].left
    end
end

function Mouse:update()
    self.state[2] = self.state[1]
    self.state[1] = { left = self.buttons.left, right = self.buttons.right }
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function love.mousemoved(x, y, dx, dy)
    Mouse.x = Mouse.x + dx * MOUSE_SPEED
    Mouse.y = Mouse.y + dy * MOUSE_SPEED
    local x0, y0, w, h = unpack(Camera:viewRect())
    Mouse.x = Util.clamp(Mouse.x, x0, x0 + w)
    Mouse.y = Util.clamp(Mouse.y, y0, y0 + h)
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        Mouse.buttons.left = true
    elseif button == 2 then
        Mouse.buttons.right = true
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        Mouse.buttons.left = false
    elseif button == 2 then
        Mouse.buttons.right = false
    end
end

_G.Mouse = Mouse
