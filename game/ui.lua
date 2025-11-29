local OFFSET = 16
local RESX = 40
local MAXRESX = 64

local TOPX = VIEW_WIDTH - 67
local TOPY = 2
local TIMERX = 7
local TIMERY = 19

local LEVEL_NAME_X_OFFSET = 4
local LEVEL_NAME_Y_OFFSET = 14

local PICKUP_TIME = 2.0
local PICKUP_EASE = TweenEase.Out

---@class UI
local UI = {
    show = true,
    elapsed = 0,
    ---@type {current: Vec2, time_left: number}[]
    get_resource_from = {},
    name = "",
}
UI.__index = UI

---@return UI
function UI.new()
    o = {
        show = true,
        elapsed = 0,
        get_resource_from = {},
        name = "",
    }
    setmetatable(o, UI)
    return o
end

function UI:toggle()
    self.show = not self.show
end

---@param from Cell
function UI:schedulePickupResource(from)
    local start = Registry.map.cellCenter(from) - Camera.position + Camera.offset
    table.insert(self.get_resource_from, { current = start, time_left = PICKUP_TIME })
end

function UI:draw()
    local map = Registry.map

    if not self.show then
        return
    end

    local function drawResource(starty)
        local x = TOPX + RESX
        local y = TOPY + starty

        local function stepXY()
            if x > TOPX + MAXRESX then
                x = TOPX + RESX
                y = y + 3
            end
            local ax = x
            local ay = y
            x = x + 3
            return ax, ay
        end

        for _ = 1, map.resources - #self.get_resource_from do
            local cx, cy = stepXY()
            Draw:sprite("map/item", cx, cy)
        end

        Util.arrayEraseIf(self.get_resource_from, function(data)
            data.time_left = data.time_left - love.timer.getDelta()
            local cx, cy = stepXY()
            local tv = Vec2.new(cx, cy)
            local next = tv:lerp(data.current, PICKUP_EASE(data.time_left / PICKUP_TIME))
            data.current = next

            if Vec2.distance(data.current, tv) < 2 then
                return true
            end
            Draw:sprite("map/item", data.current.x, data.current.y)
        end)
    end

    Draw:draw("ui", ZINDEX.ui.base, function()
        -- Ninepatch:draw("ui/panel", 0, 0, 40, 40)

        Draw:sprite("ui/badge", TOPX, TOPY)
        -- if not self.hidetimer then
        love.graphics.setColor(Colors.SteamLords.slate_violet)
        Draw:rightAlignedText(string.format("%d:%02d", math.floor(self.elapsed / 60) % 100, self.elapsed % 60),
            VIEW_WIDTH - TIMERX, TIMERY)

        Draw:rightAlignedText(self.name, VIEW_WIDTH - LEVEL_NAME_X_OFFSET, VIEW_HEIGHT - LEVEL_NAME_Y_OFFSET)
        love.graphics.setColor(Colors.White)
        -- end

        -- drawResource(map.resources, 13, "map/item_red")
        drawResource(13)

        if not map.tool then
            Draw:sprite("ui/badge_cross", TOPX + OFFSET, TOPY + OFFSET)
            return
        end

        local required = ToolCosts[map.tool]

        local count = math.floor(map.resources / required)

        if count == 0 then
            Draw:sprite("ui/badge_cross", TOPX + OFFSET, TOPY + OFFSET + 1)
        end

        local off = 0
        for _ = 1, required do
            Draw:sprite("map/item", TOPX + OFFSET + off - 3, TOPY + OFFSET - 3)
            off = off + 3
        end

        love.graphics.setColor(Colors.SteamLords.sea_glass)
        Draw:rightAlignedText("" .. count, TOPX + OFFSET + 11, TOPY + OFFSET - 13)
        love.graphics.setColor(Colors.White)

        Draw:sprite("ui/" .. map.tool, TOPX + OFFSET, TOPY + OFFSET + 1)
    end)
end

---@param dt number
function UI:update(dt)
    self.elapsed = self.elapsed + dt
end

return UI
