local Persist = {}
local buffer = require("string.buffer")

---@param filename string
---@param data any
function Persist:save(filename, data)
    local buf = buffer.new()
    buf:encode(data)
    love.filesystem.write(filename, buf:tostring())
end

---@param filename string
---@return any
function Persist:load(filename)
    local data = love.filesystem.read(filename)
    if not data then
        return nil
    end
    return buffer.decode(data)
end

_G.Persist = Persist
