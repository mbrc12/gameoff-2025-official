---@class Stack
local Stack = {
    ---@type any[]
    items = {},
}

Stack.__index = Stack

---@return Stack
function Stack:new()
    local o = {
        items = {},
    }
    setmetatable(o, self)
    return o
end

---@param item any
function Stack:push(item)
    table.insert(self.items, item)
end

---@return any
function Stack:pop()
    assert(#self.items > 0, "Stack underflow")
    return table.remove(self.items)
end

---@param n? integer
---@return any
function Stack:top(n)
    n = n or 1
    assert(#self.items >= n, "Stack has " .. #self.items .. " < " .. n .. " items")
    return self.items[#self.items - n + 1]
end

---@return integer
function Stack:size()
    return #self.items
end

return Stack
