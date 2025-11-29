local FREQ = 1
local AMP = 5
local STARTX = -500
local TOPY = -500
local HEIGHT = 1000
local LERP = 0.03
-- local LERP = 1

---@class Sea
local Sea = {
    actual = -200,
    pos = 0,
    target = 0,
}
Sea.__index = Sea

function Sea.new()
    o = {}
    setmetatable(o, Sea)
    return o
end

function Sea:set(x)
    self.target = x
end

function Sea:finished()
    return math.abs(self.actual - self.target) < AMP * 4
end

function Sea:update(dt)
    self.actual = self.actual * (1 - LERP) + self.target * LERP
    self.pos = self.actual + math.sin(love.timer.getTime() * FREQ) * AMP
end

function Sea:draw()
    Ninepatch:draw("sea", STARTX, TOPY, self.pos - STARTX, HEIGHT)
    -- Draw:draw("ui", 2000, function()
    --     Ninepatch:draw("sea", 0, 0, 100, 100)
    -- end)
end

return Sea
