---@class Bird
local Bird = {
    ---@type Vec2?
    pos = nil,
    ---@type Vec2?
    dir = nil,
}
Bird.__index = Bird

function Bird.new()
    o = {}
    setmetatable(o, Bird)
    return o
end

---@param dt number
function Bird:update(dt)
    if not self.pos and Util.random() < 0.1 then
        self.pos = Vec2.new(-50, Util.random() * 500 - 250)
        -- print("Spawning bird at ", self.pos.x, self.pos.y)
        self.dir = Util.randomDirection()
        self.dir.x = math.abs(self.dir.x)
        if self.dir.x < 0.3 then self.dir.x = 0.3 end
    end
    if self.pos then
        self.pos = self.pos + self.dir * (100 * dt)
        local rect = Camera:viewRect()
        if self.pos.x > rect[1] + rect[3] + 50 then
            self.pos = nil
            self.dir = nil
        end
    end
end

function Bird:draw()
    if self.pos then
        local rot = Util.degAtan2(self.dir.y, self.dir.x) + 45
        Draw:sprite("bird", self.pos.x, self.pos.y, rot)
    end
end

return Bird
