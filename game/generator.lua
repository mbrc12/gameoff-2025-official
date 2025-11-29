require("lib.util")
require("lib.log")

---@type MapCell
_G.DEFAULT_CELL = {
    bomb = false,
    revealed = false,
    explored = false,
    item = false,
    decorationFn = nil,
    countConcealed = false,
    wall = false,
}

local dkjson = require("deps.dkjson")

local Generator = {}

local MAX_DOORS = 3
local DOOR_KEY_PROB = 0.3
local MIN_DOOR_KEY_DIST = 4
local MIN_DOOR_DOOR_DIST = 4
local MIN_KEY_KEY_DIST = 4
local MIN_PLAYER_KEY_DIST = 4
local NONARTICULATION_REMOVE_PROB = 0.2
local REACHABLE_FRAC_MIN = 0.4
local REACHABLE_FRAC_MAX = 0.9
local MIN_TELEPORT_DIST = 10

local KEY_NAMES = {
    "archival",
    "history",
    "spirit",
    "ocean",
    "dream",
    "spite",
    "champion",
    "life",
    "luck",
    "shadow",
    "flame",
    "storm",
    "long past",
    "future",
    "disdain",
    "time",
    "void",
    "eternity",
    "spiral",
    "rebirth",
}

local DIRECTIONS = {
    { 1,  0 },
    { -1, 0 },
    { 0,  1 },
    { 0,  -1 },
}

local function l1(a, b)
    return math.abs(a[1] - b[1]) + math.abs(a[2] - b[2])
end

---@class UnionFind
---@field find fun(x: number): number
---@field union fun(x: number, y: number)

--- Not the optimal implementation, but the x, y are random so the sizes should be balanced enough
---@return UnionFind
local function unionFind()
    local parent = {}

    local function find(x)
        if parent[x] == nil then
            parent[x] = x
        end
        if parent[x] ~= x then
            parent[x] = find(parent[x])
        end
        return parent[x]
    end

    local function union(x, y)
        local rootX = find(x)
        local rootY = find(y)
        if rootX ~= rootY then
            parent[rootY] = rootX
        end
    end

    return {
        find = find,
        union = union,
    }
end

---@class MapCellEx : MapCell
---@field dist number
---@field time number
---@field top number

---@param levelWidth number
---@param levelHeight number
function Generator:generate(levelWidth, levelHeight)
    ---@type table<number, MapCellEx>
    local grid = {}
    local player, goal

    repeat
        player = { 1, Util.randint(1, levelHeight) }
        goal = { levelWidth, Util.randint(1, levelHeight) }
    until l1(player, goal) >= math.floor((levelWidth + levelHeight) / 2)

    ---@param fn fun(cell: Cell, num: number, data: MapCellEx)
    local function forEach(fn)
        for x = 1, levelWidth do
            for y = 1, levelHeight do
                local num = Util.cellToNum({ x, y })
                fn({ x, y }, num, grid[Util.cellToNum({ x, y })])
            end
        end
    end

    forEach(function(_, num, _)
        grid[num] = {}
    end)

    local function reset()
        for x = 1, levelWidth do
            for y = 1, levelHeight do
                local num = Util.cellToNum({ x, y })
                Util.defaults(grid[num], DEFAULT_CELL)
                grid[num].wall = true
                grid[num].dist = math.huge
            end
        end

        grid[Util.cellToNum(player)].wall = false
        grid[Util.cellToNum(goal)].wall = true

        grid[Util.cellToNum(player)].dist = 0
    end

    reset()

    ---@param cell Cell
    ---@return MapCellEx
    local function get(cell)
        local num = Util.cellToNum(cell)
        return grid[num]
    end

    ---@param cell Cell
    ---@return boolean
    local function inBounds(cell)
        return cell[1] >= 1 and cell[1] <= levelWidth and cell[2] >= 1 and cell[2] <= levelHeight
    end

    ---@param cell Cell
    ---@param teleports boolean|nil
    ---@param fn fun(current: Cell, next: Cell): boolean whether to continue to next
    local function bfs(cell, teleports, fn)
        local queue = { cell }
        local visited = {}
        local startNum = Util.cellToNum(cell)
        visited[startNum] = true

        while #queue > 0 do
            local current = table.remove(queue, 1)
            local currentNum = Util.cellToNum(current)

            for _, dir in ipairs(DIRECTIONS) do
                local neighbor = { current[1] + dir[1], current[2] + dir[2] }
                local neighborNum = Util.cellToNum(neighbor)
                if inBounds(neighbor) and not visited[neighborNum] then
                    visited[neighborNum] = true
                    if fn(current, neighbor) then
                        table.insert(queue, neighbor)
                    end
                end
            end

            if teleports then
                local currentData = get(current)
                if currentData.teleport then
                    local neighbor = currentData.teleport --[[@as Cell]]
                    local neighborNum = Util.cellToNum(neighbor)
                    if inBounds(neighbor) and not visited[neighborNum] then
                        visited[neighborNum] = true
                        if fn(current, neighbor) then
                            table.insert(queue, neighbor)
                        end
                    end
                end
            end
        end
    end

    ---@param cell Cell
    ---@return fun(c: Cell): boolean
    local function articulations(cell)
        local time = 0
        forEach(function(_, _, data)
            data.time = math.huge
            data.top = math.huge
        end)

        local function dfs(v, pi)
            time = time + 1
            get(v).time = time
            get(v).top = time

            for _, dir in ipairs(DIRECTIONS) do
                local neighbor = { v[1] + dir[1], v[2] + dir[2] }
                if inBounds(neighbor) and (not get(neighbor).wall) and (not Util.cellEq(neighbor, pi)) then
                    if get(neighbor).time == math.huge then
                        dfs(neighbor, v)
                    end
                    get(v).top = math.min(get(v).top, get(neighbor).top)
                end
            end
        end

        dfs(cell, nil)

        return function(c)
            return get(c).top >= get(c).time
        end
    end

    local uf = unionFind()

    local function addCell(cell)
        for _, dir in ipairs(DIRECTIONS) do
            local neighbor = { cell[1] + dir[1], cell[2] + dir[2] }
            if inBounds(neighbor) and (not get(neighbor).wall) then
                uf.union(Util.cellToNum(cell), Util.cellToNum(neighbor))
            end
        end
    end

    ---@param a Cell
    ---@param b Cell
    ---@return number
    local function distance(a, b)
        forEach(function(_, _, data)
            data.dist = math.huge
        end)
        get(a).dist = 0

        bfs(a, true, function(current, next)
            if not get(next).wall then
                local nextData = get(next)
                local currentData = get(current)
                if nextData.dist > currentData.dist + 1 then
                    nextData.dist = currentData.dist + 1
                end
                return true
            end
        end)

        return get(b).dist
    end

    local tries = 500

    local function debugPrint(step)
        if step ~= 152 then
            return
        end

        print(self:jsonFromGen({
            grid = grid,
            player = player,
            goal = goal,
        }, levelWidth, levelHeight))
    end


    Util.runWhile(function()
        local step = 500 - tries
        print("---- Generation try ", step, " ----")
        tries = tries - 1
        if tries <= 0 then
            return false
        end

        forEach(function(_, _, data)
            data.wall = true
            data.teleport = nil
            data.door = nil
            data.key = nil
            data.dist = math.huge
        end)
        get(player).wall = false
        get(goal).wall = false

        uf = unionFind()
        local teleportCount = 0
        local rand = 1

        while rand > 1/2 and teleportCount < 4 do
            rand = Util.random()
            teleportCount = teleportCount + 1
            local cell1, cell2
            repeat
                cell1 = { Util.randint(1, levelWidth), Util.randint(1, levelHeight) }
                cell2 = { Util.randint(1, levelWidth), Util.randint(1, levelHeight) }
            until l1(cell1, cell2) >= MIN_TELEPORT_DIST

            local cell1Data = get(cell1)
            local cell2Data = get(cell2)
            cell1Data.wall = false
            cell2Data.wall = false
            cell1Data.teleport = cell2
            cell2Data.teleport = cell1

            addCell(cell1)
            addCell(cell2)

            uf.union(Util.cellToNum(cell1), Util.cellToNum(cell2))
            -- print("Adding teleport between ", cell1[1], cell1[2], " and ", cell2[1], cell2[2])
        end
        print("Placed ", teleportCount, " teleports")

        Util.runWhile(function()
            local playerRoot = uf.find(Util.cellToNum(player))
            local goalRoot = uf.find(Util.cellToNum(goal))
            if playerRoot == goalRoot then
                return false
            end

            local cell = { Util.randint(1, levelWidth), Util.randint(1, levelHeight) }
            get(cell).wall = false
            addCell(cell)
            return true
        end)

        debugPrint(step)

        local artFn = articulations(player)
        forEach(function(cell, _, data)
            if data.wall or data.teleport then
                return
            end

            if Util.cellEq(cell, player) or Util.cellEq(cell, goal) then
                return
            end

            if artFn(cell) then
                return
            end

            if Util.random() < NONARTICULATION_REMOVE_PROB then
                data.wall = true
                artFn = articulations(player)
                return
            end
        end)

        local reachableFromPlayer = 0

        distance(player, goal) -- compute distances
        forEach(function(cell, _, data)
            if data.wall then
                return
            end
            if get(cell).dist == math.huge then
                data.wall = true
            else
                reachableFromPlayer = reachableFromPlayer + 1
            end
        end)

        if get(goal).dist == math.huge then
            Log("Goal not reachable from player")
            return true
        end

        local frac = reachableFromPlayer / (levelWidth * levelHeight)
        if frac < REACHABLE_FRAC_MIN or frac > REACHABLE_FRAC_MAX then
            Log("Reachable fraction ", frac, " out of bounds")
            return true
        end

        if get(goal).dist <= (levelWidth + levelHeight) then
            Log("Goal too close to player: ", get(goal).dist)
            return true
        end

        local cells = {} -- reachable cells
        forEach(function(cell, _, data)
            if not data.wall and get(cell).dist < math.huge then
                table.insert(cells, cell)
            end
        end)

        table.sort(cells, function(a, b) -- descending distance from player
            return get(a).dist > get(b).dist
        end)

        ---@type { door: Cell, key: Cell }[]
        local doorAndKeys = {}
        local assigned_keys = {}


        Util.ipairs(cells, function(_, cell)
            if #doorAndKeys >= MAX_DOORS then
                return
            end

            if Util.cellEq(cell, player) or Util.cellEq(cell, goal) then
                return
            end
            for _, dk in ipairs(doorAndKeys) do
                if Util.cellEq(cell, dk.door) or Util.cellEq(cell, dk.key) then
                    return
                end
            end

            local data = get(cell)

            if data.teleport then
                return
            end

            data.wall = true
            distance(player, goal) -- recompute distances

            local blocker = get(goal).dist == math.huge
            for _, dk in ipairs(doorAndKeys) do
                local door = dk.door
                local key = dk.key
                if get(door).dist == math.huge then
                    blocker = true
                    break
                end
                if get(key).dist == math.huge then
                    blocker = true
                    break
                end
            end

            data.wall = false

            distance(player, goal) -- recompute distances

            if not blocker then
                return
            end

            if Util.random() > DOOR_KEY_PROB then
                return
            end

            -- place door and key
            local doorCell = cell
            local doorDist = get(doorCell).dist
            local candidates = {}
            forEach(function(c, _, d)
                if d.dist == math.huge or d.wall or d.teleport or Util.cellEq(c, doorCell) or Util.cellEq(c, player) or Util.cellEq(c, goal) then
                    return
                end

                for _, dk in ipairs(doorAndKeys) do
                    if Util.cellEq(c, dk.door) or Util.cellEq(c, dk.key) then
                        return
                    end
                end

                if d.dist < doorDist then
                    table.insert(candidates, c)
                end
            end)
            if #candidates == 0 then
                return
            end

            local keyCell = candidates[Util.randint(1, #candidates)]
            local keyName
            repeat
                keyName = KEY_NAMES[Util.randint(1, #KEY_NAMES)]
            until not assigned_keys[keyName]
            assigned_keys[keyName] = true

            get(doorCell).door = keyName
            get(keyCell).key = keyName
            table.insert(doorAndKeys, { door = doorCell, key = keyCell })
            -- Log("Placed door at ", doorCell[1], doorCell[2], " and key at ", keyCell[1], keyCell[2], " for key ", keyName)
        end)

        if #doorAndKeys == 0 then
            Log("No doors placed")
            return true
        end



        for _, dk in ipairs(doorAndKeys) do
            local door = dk.door
            local key = dk.key
            if l1(door, key) < MIN_DOOR_KEY_DIST then
                Log("Door-key too close")
                return true
            end
            if l1(key, player) < MIN_PLAYER_KEY_DIST then
                Log("Player-key too close")
                return true
            end
            for _, dk2 in ipairs(doorAndKeys) do
                if dk ~= dk2 then
                    local door2 = dk2.door
                    local key2 = dk2.key
                    if l1(door, door2) < MIN_DOOR_DOOR_DIST then
                        Log("Door-door too close")
                        return true
                    end
                    if l1(key, key2) < MIN_KEY_KEY_DIST then
                        Log("Key-key too close")
                        return true
                    end
                end
            end
        end

        forEach(function(cell, _, data)
            if not data.wall then
                return
            end

            local distanceToBoundary = math.min(cell[1] - 1, levelWidth - cell[1], cell[2] - 1, levelHeight - cell[2]) + 1
            local wallProb = 0.9 / distanceToBoundary
            if Util.random() > wallProb then
                data.wall = false
                data.bomb = true
            end
        end)

        forEach(function(cell, _, data)
            if not data.bomb then
                return
            end

            local count = 0
            local wallCount = 0
            for _, dir in ipairs(DIRECTIONS) do
                local neighbor = { cell[1] + dir[1], cell[2] + dir[2] }
                if inBounds(neighbor) then
                    count = count + 1
                    if get(neighbor).wall then
                        wallCount = wallCount + 1
                    end
                end
            end

            local wallProb = (wallCount + 1) / (2 * count + 2)
            if Util.random() < wallProb then
                data.wall = true
            end
        end)

        return false -- found
    end)

    if tries <= 0 then
        return nil
    end

    return {
        grid = grid,
        player = player,
        goal = goal,
    }
end

function Generator:jsonFromGen(gen, levelWidth, levelHeight)
    local alphas = "abcdefghijklmnopqrstuvwxyz"
    local currentAlpha = 0
    local function nextAlpha()
        currentAlpha = currentAlpha + 1
        return alphas:sub(currentAlpha, currentAlpha)
    end

    local grid = { }
    local doorkeys = {}
    local teleports = {}

    local desc = {}

    for y = 1, levelHeight do
        local str = ""
        for x = 1, levelWidth do
            local cell = { x, y }
            local num = Util.cellToNum(cell)
            if Util.cellEq(cell, gen.player) then
                str = str .. "P"
            elseif Util.cellEq(cell, gen.goal) then
                str = str .. "G"
            elseif gen.grid[num].wall then
                str = str .. "#"
            elseif gen.grid[num].bomb then
                str = str .. "X"
            elseif gen.grid[num].door or gen.grid[num].key then
                local name = gen.grid[num].door or gen.grid[num].key --[[@as string]]
                local a = nextAlpha()
                if gen.grid[num].key then
                    desc[a] = { key = name }
                else
                    desc[a] = { door = name }
                end
                str = str .. a
            elseif gen.grid[num].teleport then
                local other = gen.grid[num].teleport --[[@as Cell]]
                local otherNum = Util.cellToNum(other)
                local idx = math.min(num, otherNum)
                local a
                if teleports[idx] then
                    a = teleports[idx]
                else
                    a = nextAlpha()
                    teleports[idx] = a
                end
                str = str .. a
                desc[a] = { teleport = true }
            else
                str = str .. "."
            end
        end
        table.insert(grid, str)
    end

    desc["_data"] = grid
    return dkjson.encode(desc, { indent = true })
end

---@param levelWidth number
---@param levelHeight number
---@param seed number
function Generator:generateJSON(levelWidth, levelHeight, seed)
    seed = seed or 1
    Util.seed(seed)
    local gen = self:generate(levelWidth, levelHeight)
    if not gen then
        return nil
    end

    return self:jsonFromGen(gen, levelWidth, levelHeight)
end

return Generator
