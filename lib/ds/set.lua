---@class Set
local Set = {
    items = {},
}
Set.__index = Set

---@param items any[]
---@return Set
function Set:new(items)
    local s = {}
    setmetatable(s, Set)
    s.items = {}
    if items then
        for _, item in ipairs(items) do
            s.items[item] = true
        end
    end
    return s
end

---@param item any
---@return Set
function Set:add(item)
    self.items[item] = true
    return self
end

---@param item any
---@return Set
function Set:remove(item)
    self.items[item] = nil
end

---@param item any
---@return boolean
function Set:contains(item)
    return self.items[item] ~= nil
end

---@param fn fun(item: any)
function Set:iter(fn)
    for item, _ in pairs(self.items) do
        fn(item)
    end
end

return Set
