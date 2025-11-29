local Generator = require("game.generator")

local Parser = {
    ---@type table<string, Level>
    levels = {}
}
local FILE = "assets/levels.jsonc"
local JSON

---@alias GenGrid table<number, MapCell>
---@alias Tutorial {id: string, cells: Cell[], text: string[]}

---@class Level
---@field name? string
---@field grid GenGrid
---@field width number
---@field height number
---@field seacreep boolean
---@field player Cell
---@field goal Cell
---@field yoffset number
---@field tint number[]
---@field keytints table<string, number[]>
---@field allowedTools string[]
---@field tutorials table<string, Tutorial>
---@field initialResources number

function Parser:init()
    JSON = Util.readJson(FILE)
    assert(JSON, "Failed to load levels from " .. FILE)
    print("Loaded levels.")
end

---@return string[]
function Parser:list()
    return JSON["_levels"]
end

---@param levelName string
function Parser:get(levelName)
    return  self:_parseLevel((Util.readJson(FILE))[levelName])
end


local DEFAULT_RESOURCE_CHANCES = 0.1
local DEFAULT_RESOURCE_INITIAL = 3

local KEY_TINTS = { "eggplant_purple", "additional_blue", "forest_green", "mahogany", "taupe_green", "slate_violet", "aubergine" }

---@param raw table
---@return Level
function Parser:_parseLevel(raw)
    local seacreep = raw["_seacreep"] or false
    local seed = raw["_seed"] or 1
    Util.seed(seed)
    local width
    local height
    local raw_tint = raw["_tint"] or "eggplant_purple"
    local tint = Colors.SteamLords[raw_tint]

    ---@type table<string, Tutorial>
    local tutorials = raw["_tutorials"] or {}
    ---@type Cell
    local player
    ---@type Cell
    local goal
    ---@type GenGrid
    local grid = {}
    ---@type table<string, Cell>
    local teleports = {}

    local function parseData()
        local data = raw["_data"] --[[ @as string[] ]]
        width = data[1]:len()
        height = #data
        for i = 1, width do
            for j = 1, height do
                local char = data[j]:sub(i, i)
                local num = Util.cellToNum({ i, j })
                grid[num] = {}
                Util.defaults(grid[num], DEFAULT_CELL)
                if tutorials[char] then
                    grid[num].tutorialId = tutorials[char].id
                end
                if char == "." then
                elseif char == "P" then
                    player = { i, j }
                elseif char == "G" then
                    goal = { i, j }
                elseif char == "X" then
                    grid[num].bomb = true
                elseif char == "#" then
                    grid[num].wall = true
                else
                    local additional_info = raw[char]
                    if additional_info then

                        -- if additional_info["key"] and (not additional_info["revealed"]) then -- keys are revealed by default
                        --     additional_info["revealed"] = true -- will be replaced if the other value is set
                        -- end

                        for k, v in pairs(additional_info) do
                            if k == "teleport" and v == true then
                                if not teleports[char] then
                                    teleports[char] = { i, j }
                                else
                                    local other = teleports[char]
                                    grid[num].teleport = { other[1], other[2] }
                                    grid[Util.cellToNum(other)].teleport = { i, j }
                                end
                            else
                                grid[num][k] = v
                            end
                        end
                    end
                end
            end
        end
    end

    if not raw["_data"] then
        local size = raw["_size"] or { 9, 9 }
        width = size[1]
        height = size[2]
        local gen = Generator:generate(width, height)
        if not gen then
            error("Failed to generate level")
        end
        grid = gen.grid
        player = gen.player
        goal = gen.goal
    else
        parseData()
    end

    Util.seed(seed)
    local resource_chances = (raw["_resources"] and raw["_resources"].chances) or DEFAULT_RESOURCE_CHANCES
    local resource_initial = (raw["_resources"] and raw["_resources"].initial) or DEFAULT_RESOURCE_INITIAL

    --- add items and set key tints
    Util.sortedPairs(grid, function(num, cellData)
        local cell = Util.numToCell(num)
        local forbid =
            cellData.bomb or
            cellData.wall or
            cellData.door or
            Util.cellEq(cell, player) or
            Util.cellEq(cell, goal) or
            (cellData.teleport ~= nil) or
            (cellData.key ~= nil)

        if not forbid then
            local u = Util.random()
            if u < resource_chances then
                cellData.item = true
            end
        end
    end)

    local keytints = raw["_keytints"] or {}

    Util.seed(seed)
    for _, cellData in pairs(grid) do
        if cellData.key then
            if not keytints[cellData.key] then
                local tintName
                repeat
                    local tintIdx = Util.randint(1, #KEY_TINTS)
                    tintName = KEY_TINTS[tintIdx]
                until tintName ~= raw_tint
                keytints[cellData.key] = Colors.SteamLords[tintName]
            else
                keytints[cellData.key] = Colors.SteamLords[keytints[cellData.key]]
            end
        end
    end
    -- Log("Key tints: ", keytints)

    --- replace the tutorial character keys with id-keyed table
    local tutorials_ = {}
    for _, t in pairs(tutorials) do
        tutorials_[t.id] = t
    end

    local yoffset = raw["_yoffset"] or Util.round((15 - height) / 2)

    local name = raw["_name"]

    return {
        name = name,
        grid = grid,
        width = width,
        height = height,
        seacreep = seacreep,
        player = player,
        goal = goal,
        yoffset = yoffset,
        tint = tint,
        keytints = keytints,
        allowedTools = raw["_tools"] or {},
        tutorials = tutorials_,
        initialResources = resource_initial,
    }
end

---@param level Level
---@param cell Cell
---@param fn fun(adjacent: Cell)
---@param includeSelf? boolean
function Parser:_iterateAdjacent(level, cell, fn, includeSelf)
    local width = level.width
    local height = level.height
    for dx = -1, 1 do
        for dy = -1, 1 do
            if includeSelf or (dx ~= 0 or dy ~= 0) then
                local adjacent = { cell[1] + dx, cell[2] + dy }
                if adjacent[1] >= 1 and adjacent[1] <= width and adjacent[2] >= 1 and adjacent[2] <= height then
                    fn(adjacent)
                end
            end
        end
    end
end

---@param level Level
---@param cell Cell
---@return number
function Parser:_adjacentBombs(level, cell)
    local count = 0
    self:_iterateAdjacent(level, cell, function(adjacent)
        if level.grid[Util.cellToNum(adjacent)].bomb then
            count = count + 1
        end
    end, true)
    return count
end

return Parser
