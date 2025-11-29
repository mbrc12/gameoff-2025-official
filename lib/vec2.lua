---@alias Cell number[]

---@class Vec2
local Vec2 = {
    x = 0,
    y = 0,
}

Vec2.__index = Vec2

---@param x number
---@param y number
---@return Vec2
function Vec2.new(x, y)
    x = x or 0
    y = y or 0
    v = { x = x, y = y }
    setmetatable(v, Vec2)
    return v
end

---@return Vec2
function Vec2:copy()
    return Vec2.new(self.x, self.y)
end

---@param v2 Vec2
---@return Vec2
function Vec2:__add(v2)
    return Vec2.new(self.x + v2.x, self.y + v2.y)
end

---@param v2 Vec2
---@return Vec2
function Vec2:__sub(v2)
    return Vec2.new(self.x - v2.x, self.y - v2.y)
end

---@param scalar number
---@return Vec2
function Vec2:__mul(scalar)
    return Vec2.new(self.x * scalar, self.y * scalar)
end

---@param scalar number
---@return Vec2
function Vec2:__div(scalar)
    return Vec2.new(self.x / scalar, self.y / scalar)
end

function Vec2:__tostring()
    return string.format("(%.2f, %.2f)", self.x, self.y)
end

---@return number
function Vec2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

---@return Vec2
function Vec2:normalized()
    local len = self:length()
    if len > 0 then
        return Vec2.new(self.x / len, self.y / len)
    else
        return Vec2.new(0, 0)
    end
end

---@param angle number in degrees
---@return Vec2
function Vec2:rotated(angle)
    angle = math.rad(angle)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    return Vec2.new(
        self.x * cos_a - self.y * sin_a,
        self.x * sin_a + self.y * cos_a
    )
end

---@param angle number in degrees
function Vec2.polar(angle)
    angle = math.rad(angle)
    return Vec2.new(math.cos(angle), math.sin(angle))
end

---@param v2 Vec2
---@return number
function Vec2:distance(v2)
    return math.sqrt((self.x - v2.x) * (self.x - v2.x) + (self.y - v2.y) * (self.y - v2.y))
end

---@return Vec2
function Vec2:inplaceRound()
    self.x = math.floor(self.x + 0.5)
    self.y = math.floor(self.y + 0.5)
    return self
end

---@param v2 Vec2
---@param t number 0..1
---@return Vec2
function Vec2:lerp(v2, t)
    return Vec2.new(
        self.x + (v2.x - self.x) * t,
        self.y + (v2.y - self.y) * t
    )
end

---@param v2 Vec2
---@return number
function Vec2:dot(v2)
    return self.x * v2.x + self.y * v2.y
end

---@param v2 Vec2
---@param t number 0..1
---@return Vec2
function Vec2:mix(v2, t)
    return Vec2.new(
        self.x * (1 - t) + v2.x * t,
        self.y * (1 - t) + v2.y * t
    )
end

_G.Vec2 = Vec2
