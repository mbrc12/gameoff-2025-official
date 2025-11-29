_G.Events = {
    ---@type table<string, table<integer, fun(...):boolean>>
    subscribers = {},
}

---@enum (key) EventName
local EventName = {
    player_tween_complete = true,
    map_loaded = true,
}

---@param eventName EventName
---@param callback fun(...):boolean
function Events:subscribe(eventName, callback)
    if not self.subscribers[eventName] then
        self.subscribers[eventName] = {}
    end

    local id = Util.uniqueId()
    self.subscribers[eventName][id] = callback
end

---@param eventName EventName
---@param callback fun(...)
function Events:subscribeOnce(eventName, callback)
    local function wrapper(...)
        callback(...)
        return true
    end

    self:subscribe(eventName, wrapper)
end

---@param eventName EventName
---@param callback fun(...):boolean
function Events:unsubscribe(eventName, callback)
    local subs = self.subscribers[eventName]
    if not subs then
        return
    end

    for id, cb in pairs(subs) do
        if cb == callback then
            subs[id] = nil
            return
        end
    end
end

---@param eventName EventName
---@param ... any
function Events:emit(eventName, ...)
    local args = { ... }

    local subs = self.subscribers[eventName]
    if not subs then
        return
    end

    Util.eraseIf(subs, function(callback)
        return callback(unpack(args))
    end)
end
