_G.Util = {}

local json = require("deps.dkjson")

Util.id = 100
function Util.uniqueId()
    Util.id = Util.id + 1
    return Util.id
end

---@param shader love.Shader
---@param uniforms table<string, table|number>
---@param debug boolean?
function Util.setShaderUniforms(shader, uniforms, debug)
    debug = debug or false
    for name, value in pairs(uniforms) do
        if debug then
            Log("Setting shader uniform", name, " = ",  value)
        end
        if name:sub(1, 1) == "a" then
            shader:send(name, unpack(value))
        else
            shader:send(name, value)
        end
    end
end

---@param t1 table
---@param t2 table
function Util.shallowMerge(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

---@param t1 table
---@param t2 table
---@return table
function Util.defaults(t1, t2)
    for k, v in pairs(t2) do
        if t1[k] == nil then
            if not (type(v) == "function") then
                t1[k] = v
            end
        end
    end
    return t1
end

---@param a number
---@param b number
function Util.aeq(a, b)
    return a < b + EPSILON and a + EPSILON > b
end

---@param a number
---@param b number
---@return boolean
function Util.aless(a, b)
    return a < b + EPSILON
end

---@param a number
---@param b number
---@return boolean
function Util.agtr(a, b)
    return a + EPSILON > b
end

---@param val number
---@param min number
---@param max number
---@return number
function Util.clamp(val, min, max)
    if min > max then
        return (min + max) / 2
    end
    return math.min(math.max(val, min), max)
end

---@param val number
---@param places? number
---@return number
function Util.round(val, places)
    places = places or 0
    local mult = 10 ^ places
    return math.floor(val * mult + 0.5) / mult
end

---@param arr table
---@return table
function Util.copyArray(arr)
    local new = {}
    for i, v in ipairs(arr) do
        table.insert(new, v)
    end
    return new
end

--- whenAll(f) returns a function g such that if you call g() it returns a callback. When all these callbacks have been called, f is called.
---@param fn function
function Util.whenAll(fn)
    local count = 0
    local finalized = false
    ---@type { callback: fun(): (fun(): nil), enable: fun(): nil }
    return {
        callback = function()
            count = count + 1
            return function()
                count = count - 1
                if not finalized then
                    print("Warning: whenAll callback called before enabled")
                end
                if count == 0 and finalized then
                    fn()
                end
            end
        end,
        enable = function()
            finalized = true
        end
    }
end

--- Cells are considered centered around the grid position.

---@param cell Cell
---@return Vec2
function Util.cellToWorld(cell)
    return Vec2.new(cell[1] * CELL_SIZE, cell[2] * CELL_SIZE)
end

---@param pos Vec2
---@return Cell
function Util.worldToCell(pos)
    return { Util.round(pos.x / CELL_SIZE), Util.round(pos.y / CELL_SIZE) }
end

---@param cell Cell
function Util.cellToNum(cell)
    return (cell[1] + 2^20) * (2^21) + (cell[2] + 2^20)
end

---@param n number
function Util.numToCell(n)
    local x = math.floor(n / (2^21)) - 2^20
    local y = n % (2^21) - 2^20
    return { x, y }
end

function Util.cellEq(c1, c2)
    if c1 == nil or c2 == nil then
        return false
    end
    return c1[1] == c2[1] and c1[2] == c2[2]
end

---@param cell Cell
function Util.cellOffset(cell, offset)
    return { cell[1] + offset[1], cell[2] + offset[2] }
end

---@param n number
---@param dx number
---@param dy number
---@return number
function Util.addAsCellNum(n, dx, dy)
    return n + dx * (2^21) + dy
end

---@param pos Vec2
---@return Vec2
function Util.snapToGrid(pos)
    local cell = Util.worldToCell(pos)
    return Util.cellToWorld(cell)
end

---@param fn function
---@return function
function Util.memoize(fn)
    local cache = {}
    return function(x)
        if cache[x] == nil then
            cache[x] = fn(x)
        end
        return cache[x]
    end
end

---@generic T
---@param t table<T, any>
---@return T[]
function Util.keys(t)
    if t == nil then
        return {}
    end
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

---@param t table
---@return boolean
function Util.isEmpty(t)
    return next(t) == nil
end

---@param path string
---@return any
function Util.readJson(path)
    local contents = love.filesystem.read(path)
    if not contents then
        error("Could not read file: " .. path)
    end
    local obj = json.decode(contents, 1, nil)
    return obj
end

---@generic V
---@param t table<any, V>
---@param predicate fun(v: V): boolean
function Util.all(t, predicate)
    for _, v in pairs(t) do
        if not predicate(v) then
            return false
        end
    end
    return true
end

--- only works on dictionary-like tables, not arrays
---@generic K, V
---@param t table<K, V>
---@param predicate fun(v: V, k: K): boolean?
function  Util.eraseIf(t, predicate)
    local toRemove = {}
    for k, v in pairs(t) do
        if predicate(v, k) then
            table.insert(toRemove, k)
        end
    end

    for _, k in pairs(toRemove) do
        t[k] = nil
    end
end

--- fast array erase
---@generic V
---@param t V[]
---@param predicate fun(v: V): boolean?
function Util.arrayEraseIf(t, predicate)
    local j = 1
    for i = 1, #t do
        local v = t[i]
        if not predicate(v) then
            t[j] = t[i]
            j = j + 1
        else
            t[j] = nil
        end
    end

    local count = #t - (j - 1)
    for _ = 1, count do
        table.remove(t)
    end
end

---@param arr any[]
---@param other any[]
---@return any[]
function Util.concat(arr, other)
    local new = {}
    for _, v in ipairs(arr) do
        table.insert(new, v)
    end
    for _, v in ipairs(other) do
        table.insert(new, v)
    end
    return new
end

---@param width number
---@param height number
---@return number, number
function Util.centerCoords(width, height)
    return (VIEW_WIDTH - width) / 2, (VIEW_HEIGHT - height) / 2
end

---Iterate over all key-value pairs in a table, calling fn for each.
---@generic K, V
---@param t table<K, V>
---@param fn fun(k: K, v: V): any
function Util.pairs(t, fn)
    for k, v in pairs(t) do
        fn(k, v)
    end
end

---Iterate over all indexed values in a table, calling fn for each.
---@generic V
---@param t V[]
---@param fn fun(idx: integer, v: V): any
function Util.ipairs(t, fn)
    for i, v in ipairs(t) do
        fn(i, v)
    end
end

--- Run the given function repeatedly while it returns true
---@param fn function
function Util.runWhile(fn)
    while fn() do end
end

---@param y number
---@param x number
---@return number angle in degrees
function Util.degAtan2(y, x)
    return math.atan2(y, x) * (180 / math.pi)
end

---@param x number
---@param s number
function Util.step(x, s)
    return math.floor((x + s / 2) / s) * s
end

---@param co function
---@param returnOnFinish any
---@return function
function Util.coroutinize(returnOnFinish, co)
    local thread = coroutine.create(co)

    return function(...)
        if coroutine.status(thread) == "dead" then
            return returnOnFinish
        end
        local ok, ret = coroutine.resume(thread, ...)
        if not ok then
            error(ret)
        end
        return ret
    end
end

---@generic K, V
---@param t table<K, V>
---@param fn fun(k: K, v: V): any
---@param comp? fun(a: K, b: K): boolean
function Util.sortedPairs(t, fn, comp)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, comp)
    local i = 0
    for _, k in ipairs(keys) do
        i = i + 1
        fn(k, t[k])
    end
end


-------- random
local RNG_X
local RNG_M = 2^31 - 1
local RNG_A = 48271
local THROWAWAY = 10 --- number of initial values to throw away

if SEED then
    RNG_X = SEED
else
    RNG_X = os.time() % RNG_M
end

---@return number
local function rng_next()
    RNG_X = (RNG_A * RNG_X) % RNG_M
    return RNG_X
end

for _ = 1, THROWAWAY do
    rng_next()
end

---@return number
function Util.random()
    return rng_next() / RNG_M
end

function Util.seed(seed)
    RNG_X = seed % RNG_M
    for _ = 1, THROWAWAY do
        rng_next()
    end
end

---Return a random integer in [m, n]
---@param m number
---@param n number
---@return number
function Util.randint(m, n)
    return math.floor(Util.random() * (n - m + 1)) + m
end

---@generic K
---@param arr K[]
---@return K
function Util.choice(arr)
    local idx = Util.randint(1, #arr)
    return arr[idx]
end


---@return Vec2
function Util.randomDirection()
    local angle = Util.random() * 360
    return Vec2.polar(angle)
end

--- Return a shuffled copy of the input array
--- Note that the complexity is O(n^2); don't use for large arrays
---@param arr any[]
function Util.shuffled(arr)
    local copy = Util.copyArray(arr)
    local shuffled = {}
    while #copy > 0 do
        local idx = Util.randint(1, #copy)
        table.insert(shuffled, copy[idx])
        table.remove(copy, idx)
    end
    return shuffled
end

