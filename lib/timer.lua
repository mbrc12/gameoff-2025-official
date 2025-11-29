local Timer = {
    timers = {},
    newTimers = {},
}

---@param duration number
---@param func function
function Timer:oneshot(duration, func)
    self.newTimers[Util.uniqueId()] = {
        left = duration,
        func = func,
        type = "oneshot"
    }
end

---@param dt number
function Timer:update(dt)
    for id, timer in pairs(self.newTimers) do
        self.timers[id] = timer
    end
    self.newTimers = {}

    local toDelete = {}

    for id, timer in pairs(self.timers) do
        timer.left = timer.left - dt
        if timer.left <= 0 then
            timer.func()
            if timer.type == "oneshot" then
                table.insert(toDelete, id)
            end
        end
    end

    for _, id in ipairs(toDelete) do
        self.timers[id] = nil
    end
end

--- return an update function that calls `func` every `gap` seconds
--- the returned function takes `dt` as parameter.
--- if withSelf is true, the first parameter is `self`, and the second is `dt`
---@param gap number
---@param func function
---@param defaultReturn? any
---@param immediatelyCall? boolean
---@param withSelf? boolean
---@return function(number):any
function Timer:every(gap, func, defaultReturn, immediatelyCall, withSelf)
    defaultReturn = defaultReturn or nil
    immediatelyCall = immediatelyCall or false

    local elapsed = 0
    if immediatelyCall then
        func()
    end
    return function(...)
        local args = { ... }
        local dt = withSelf and args[2] or args[1]
        local self_ = withSelf and args[1] or nil
        elapsed = elapsed + dt
        if elapsed >= gap then
            elapsed = elapsed - gap
            return func(self_)
        end
        return defaultReturn
    end
end

_G.Timer = Timer
