local Stack = require("lib.ds.stack")

---@class StateMachine
local StateMachine = {
    ---@type StateMachine.Config
    states = {},
    ---@type Stack
    stack = nil,

    ---@type any
    output = nil,

    ---@type boolean
    stopped = false,
}

StateMachine.__index = StateMachine

---@class StateMachine.StateLifecycle
---@field alwaysUpdate? boolean Whether this state's update should be called even if it's not the top state
---@field enter? fun(self: StateMachine)
---@field exit? fun(self: StateMachine)
---@field update? fun(self: StateMachine, dt: number, index: integer)
---@field coupdate? fun(self: StateMachine, dt: number, index: integer) Coroutine fn that will also receive these parameters upon resume
---@field draw? fun(self: StateMachine, index: integer)

---@alias StateMachine.Config table<string, StateMachine.StateLifecycle>

---@param states StateMachine.Config
function StateMachine:new(states)
    for name, methods in pairs(states) do
        if methods.alwaysUpdate == nil then
            methods.alwaysUpdate = false
        end

        assert((not methods.update) or (not methods.coupdate),
            "State " .. tostring(name) .. " cannot have both update and coupdate methods")
        if methods.coupdate then
            local coThread = coroutine.create(methods.coupdate)
            local upd = function(sm, dt, index)
                local success = coroutine.resume(coThread, sm, dt, index)
                -- ignore success value
            end
            methods.update = upd
        end
    end

    local o = {
        states = states,
        stack = Stack:new(),
        output = nil,
        stopped = false,
    }
    setmetatable(o, self)
    return o
end

---@param state string
function StateMachine:push(state)
    assert(self.states[state], "State does not exist: " .. tostring(state))
    self.stack:push(state)
    local current = self.stack:top()
    if self.states[current].enter then
        self.states[current].enter(self)
    end
end

function StateMachine:pop()
    local current = self.stack:top()
    if self.states[current] and self.states[current].exit then
        self.states[current].exit(self)
    end
    self.stack:pop()
end

---@param state string
function StateMachine:replace(state)
    assert(self.states[state], "State does not exist: " .. tostring(state))
    local current = self.stack:top()
    if self.states[current] and self.states[current].exit then
        self.states[current].exit(self)
    end
    self.stack:pop()
    self.stack:push(state)
    current = self.stack:top()
    if self.states[current] and self.states[current].enter then
        self.states[current].enter(self)
    end
end

function StateMachine:quit()
    while #self.stack > 0 do
        self:pop()
    end
    self.stopped = true
end

---@return boolean running?
function StateMachine:update(dt)
    if self.stopped then
        return false
    end
    for i = self.stack:size(), 1, -1 do
        local state = self.stack:top(i)
        if not self.states[state] or not self.states[state].update then
        elseif i == 1 or self.states[state].alwaysUpdate then
            self.states[state].update(self, dt, i)
        end
    end

    return true
end

function StateMachine:draw()
    for i = self.stack:size(), 1, -1 do
        local state = self.stack:top(i)
        if self.states[state] and self.states[state].draw then
            self.states[state].draw(self, i)
        end
    end
end

_G.StateMachine = StateMachine
