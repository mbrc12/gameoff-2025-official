local OPTION_SPACING = 5

---@class UIList
local UIList = {
    allowBack = false,
    current = 1,
    ---@type string[]
    options = nil,
    ---@type number
    width = nil,
    ---@type number[]
    color = {},
    compressed = false,
}
UIList.__index = UIList

---@param options string[]
---@param allowBack boolean|nil
---@param compressed boolean|nil
---@return UIList
function UIList.new(options, allowBack, compressed)
    o = {}
    setmetatable(o, UIList)

    o.color = Colors.SteamLords.steel_blue
    o.options = options
    o.current = 1
    o.allowBack = allowBack or false
    o.compressed = compressed or false

    local font = Assets.font
    for _, option in ipairs(options) do
        local w = font:getWidth(option)
        if not o.width or w > o.width then
            o.width = w
        end
    end

    return o
end

---@param dt number
---@return number | nil
function UIList:update(dt)
    if Input:isJustPressed("DOWN") or Input:isJustPressed("RIGHT") or Input:isJustPressed("SWITCH") then
        self.current = self.current + 1
        if self.current > #self.options then
            self.current = 1
        end
        Sounds:shuffledSfx("menu_move")
    elseif Input:isJustPressed("UP") or Input:isJustPressed("LEFT") then
        self.current = self.current - 1
        if self.current < 1 then
            self.current = #self.options
        end
        Sounds:shuffledSfx("menu_move")
    end

    if Input:isJustPressed("INTERACT") then
        Sounds:shuffledSfx("menu_select")
        return self.current
    end

    if self.allowBack and Input:isJustPressed("BACK") then
        Sounds:shuffledSfx("menu_back")
        return -1
    end

    return nil
end

---@param y number
function UIList:draw(y)
    local marker_width = 16
    local font = Assets.font
    local total_width = self.width + 2
    local x = Util.round((VIEW_WIDTH - total_width) / 2) - 10
    local selection_y = y
    local font_height = font:getHeight()

    love.graphics.setColor(self.color)

    if not self.compressed then
        for i, option in ipairs(self.options) do
            local option_width = font:getWidth(option)
            local option_y = y + (i - 1) * (font_height + OPTION_SPACING)
            if i == self.current then
                selection_y = option_y
            end

            love.graphics.print(option, x + marker_width + Util.round((total_width - option_width)/2), option_y - 1)
        end
    else
        -- show only one option at a time
        local option = self.options[self.current]
        local option_width = font:getWidth(option)
        love.graphics.print(option, x + marker_width + Util.round((total_width - option_width)/2), y - 1)
    end
    love.graphics.setColor(Colors.White)

    local marker_y = selection_y + font_height/2
    if self.compressed then
        marker_y = marker_y + math.sin(love.timer.getTime() * 10) * 2
    end

    Draw:sprite("uilist/marker", x + 5, marker_y, self.compressed and 90 or 0)
end

return UIList
