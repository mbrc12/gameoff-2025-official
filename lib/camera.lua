local CAMERA_DURATION = 1
local CAMERA_TOLERANCE = 0.5

---@enum (key) ShakeKinds
local ShakeKinds = {
    minor = { duration = 0.1, amount = 1 },
    major = { duration = 0.3, amount = 8 },
}

local Camera = {
    offset = Vec2.new(VIEW_WIDTH / 2, VIEW_HEIGHT / 2),
    position = Vec2.new(0, 0),
    transform = love.math.newTransform(),
    source = Vec2.new(0, 0),
    target = Vec2.new(0, 0),

    shaking = false,
    shakeAmount = 0,
    limits = { left = -INFINITY, right = INFINITY, top = -INFINITY, bottom = INFINITY },

    tween = nil,
}

function Camera:reset()
    if self.tween then
        Tweens:safeCancel(self.tween)
        self.tween = nil
    end

    self.position = Vec2.new(0, 0)
    self.source = Vec2.new(0, 0)
    self.target = Vec2.new(0, 0)
    self.limits = { left = -INFINITY, right = INFINITY, top = -INFINITY, bottom = INFINITY }
    self.shaking = false
    self.shakeAmount = 0
end

function Camera:matrix()
    return {self.transform:getMatrix()}
end

function Camera:matrixInv()
    return {self.transform:inverse():getMatrix()}
end

---@return number[] {x, y, width, height}
function Camera:viewRect()
    return {
        self.position.x - self.offset.x,
        self.position.y - self.offset.y,
        VIEW_WIDTH,
        VIEW_HEIGHT
    }
end

function Camera:apply()
    love.graphics.push()
    self.transform:reset()
    local pos = self.position:copy():inplaceRound()
    self.transform:translate(-pos.x + self.offset.x, -pos.y + self.offset.y)
    love.graphics.applyTransform(self.transform)
end

function Camera:unapply()
    love.graphics.pop()
end

function Camera:instant(pos)
    self.position = pos:copy()
end

function Camera:update()
    local dt = love.timer.getDelta()
    if self.position:distance(self.target) < CAMERA_TOLERANCE then
        self.position = self.target:copy():inplaceRound()
        return
    end

    self.position = self.position:lerp(self.target, math.min(dt * 5, 1))

    -- Log(self.position)
end

---@param pos Vec2
function Camera:moveTo(pos)
    local pos_ = pos:copy()
    pos_.x = Util.clamp(pos_.x, self.limits.left + VIEW_WIDTH / 2, self.limits.right - VIEW_WIDTH / 2)
    pos_.y = Util.clamp(pos_.y, self.limits.top + VIEW_HEIGHT / 2, self.limits.bottom - VIEW_HEIGHT / 2)

    -- if self.target:distance(pos_) < CAMERA_TOLERANCE then
    --     return
    -- end

    pos_.x = Util.round(pos_.x)
    pos_.y = Util.round(pos_.y)

    -- Log("Camera moveTo:", pos_)

    -- Tweens:safeCancel(self.tween)

    -- self.source = self.position:copy()
    self.target = pos_

    -- self.tween = Tweens:new({
    --     duration = CAMERA_DURATION,
    --     ease = "Out",
    --     step = function(t)
    --         self.position = self.source:lerp(self.target, t):inplaceRound()
    --     end,
    --     onComplete = function()
    --         self.position = self.target:copy()
    --         self.tween = nil
    --     end,
    -- })
end

---@param kind ShakeKinds
function Camera:shake(kind)
    -- return
-- end
    kind = kind or "minor"
    --- note that consecutively stacked shakes will not extend the duration
    self.shaking = true
    self.shakeAmount = ShakeKinds[kind].amount
    Timer:oneshot(ShakeKinds[kind].duration, function()
        self.shaking = false
    end)
end

_G.Camera = Camera
