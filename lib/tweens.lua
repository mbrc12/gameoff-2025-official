---@enum(key) TweenEase
_G.TweenEase = {
    Linear = function(t) return t end,
    In = function(t) return t * t end,
    Out = function(t) return t * (2 - t) end,
    In_Out = function(t)
        if t < 0.5 then
            return 2 * t * t
        else
            return -1 + (4 - 2 * t) * t
        end
    end,
}

local Tweens = {
    ---@type table<number, TweenConfig>
    tweens = {},
}

---@class TweenConfig
---@field manualTick? boolean
---@field duration? number
---@field elapsed? number
---@field ease? TweenEase
---@field step? fun(number)
---@field onComplete? function()
---@field fns? table<string, fun(number)>

local tweenDefaults = {
    manualTick = false,
    duration = 1,
    elapsed = 0,
    ease = "Linear",
    step = nil,
    onComplete = nil,
    fns = {},
}

---@param cfg TweenConfig
---@return number
function Tweens:new(cfg)
    Util.defaults(cfg, tweenDefaults)
    local id = Util.uniqueId()

    self.tweens[id] = cfg
    return id
end

---@param id number
function Tweens:stop(id)
    self.tweens[id] = nil
end

---@param id number
function Tweens:safeCancel(id)
    if self.tweens[id] then
        if self.tweens[id].onComplete then
            self.tweens[id].onComplete()
        end

        self:stop(id)
    end
end

function Tweens:updateOne(id, dt)
    local tween = self.tweens[id]
    tween.elapsed = tween.elapsed + dt
    local t = Util.clamp(tween.elapsed / tween.duration, 0, 1)
    local easedT = TweenEase[tween.ease](t)

    if tween.step then
        tween.step(easedT)
    end

    if t >= 1 then
        if tween.onComplete then
            tween.onComplete()
        end
        self.tweens[id] = nil
    end
end

---@param dt number
function Tweens:update(dt)
    for id, tween in pairs(self.tweens) do
        if not tween.manualTick then
            self:updateOne(id, dt)
        end
    end
end

---@param id number
---@param dt number
function Tweens:tick(id, dt)
    self:updateOne(id, dt)
end

---@param id number
---@param name string
function Tweens:call(id, name)
    local tween = self.tweens[id]
    if tween and tween.fns[name] then
        local t = Util.clamp(tween.elapsed / tween.duration, 0, 1)
        local easedT = TweenEase[tween.ease](t)
        tween.fns[name](easedT)
    end
end

---@param id number
---@return boolean
function Tweens:isOver(id)
    return self.tweens[id] == nil
end

---@param id number
---@param name string
---@return boolean didCall
function Tweens:safeCall(id, name)
    if self.tweens[id] and self.tweens[id].fns[name] then
        self:call(id, name)
        return true
    end
    return false
end

_G.Tweens = Tweens
