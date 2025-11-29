---@class SeaCreeper : LogicDelegate
local SeaCreeper = {
    speed = 0,
    left = 0,
}
SeaCreeper.__index = SeaCreeper

---@param totalTime number
function SeaCreeper:new(length, totalTime)
    -- print("length", length, "totalTime", totalTime)
    local obj = {
        speed = length / totalTime,
        left = length,
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function SeaCreeper:update(dt)
    local map = Registry.map
    local sea = Registry.sea

    local delta = self.speed * dt
    self.left = self.left - delta
    local pos = sea.target + delta

    sea:set(pos)

    pos = sea.pos

    for num in pairs(map.cells) do
        local cell = Util.numToCell(num)
        local center = map.cellCenter(cell)
        if center.x <= pos then -- 1/2 overlap
            map:scheduleDelete(num)
        end
    end

    if self.left <= 0 then
        return true
    end

    return false
end

return SeaCreeper
