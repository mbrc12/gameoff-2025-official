local Text = {
    calls = {}
}
-- manage the text render layer

---@param text string
---@param x number ignored if centered
---@param y number
---@param centered? boolean
---@param color? number[]
---@param relative? boolean if false, x and y are in-game coordinates
function Text:print(text, x, y, centered, color, relative)
    relative = relative or false
    assert((relative == false) or (centered == false), "Cannot center text with in-game coordinates")
    x = x * TEXT_UPSCALE
    y = y * TEXT_UPSCALE
    color = color or Colors.White
    table.insert(self.calls, { text = text, x = x, y = y, centered = centered, color = color, relative = relative })
end

function Text:clear()
    self.calls = {}
end

---@return boolean
function Text:hasPending()
    return #self.calls > 0
end

function Text:draw()
    Draw:draw("ui", ZINDEX.ui.text, function()
        for _, item in ipairs(self.calls) do
            love.graphics.setColor(unpack(item.color))
            local x, y = item.x, item.y
            if item.centered then
                local width = Assets.font:getWidth(item.text)
                x = (TEXT_VIEW_WIDTH - width) / 2
            end
            if item.relative then
                x = item.x - Camera.position.x * TEXT_UPSCALE + TEXT_VIEW_WIDTH / 2
                y = item.y - Camera.position.y * TEXT_UPSCALE + TEXT_VIEW_HEIGHT / 2
            end
            love.graphics.print(item.text, x, y)
        end

        self.calls = {}
    end)
    -- love.graphics.setColor(unpack(oldColor))
end

_G.Text = Text
