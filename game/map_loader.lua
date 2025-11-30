local generateDecorations = require("game.decorations")
local PLAYER_CELL_Y_ORIGIN = -30
local PLAYER_CELL_X_DELTA = -40

---@param grid GenGrid
---@return number[]
local function gridInSortedOrder(grid)
    local keys = Util.keys(grid)
    table.sort(keys, function(a_, b_)
        local a = Util.numToCell(a_)
        local b = Util.numToCell(b_)
        return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
    end)
    return keys
end

local TOTAL_LOAD_TIME = 0.5
local PLAYER_DROP_TIME = 0.5

---@param topLeft Vec2
---@param bottomRight Vec2
local function setCameraLimits(topLeft, bottomRight)
    Camera.limits.top = topLeft.y - CELL_SIZE / 2 - 10
    Camera.limits.right = bottomRight.x + CELL_SIZE / 2 + 10
    Camera.limits.bottom = bottomRight.y + CELL_SIZE / 2 + 10
    Camera.limits.left = topLeft.x - CELL_SIZE / 2 - 20
end

local romans = {
    "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"
}
---@param n number
---@return string
local function toroman(n)
    return romans[n] or tostring(n)
end

---@param level Level
---@return LogicDelegate
return function(level)
    local map = Registry.map
    map:resetForNewLevel()

    map.cursorState = "disabled"
    Registry.player = require("game.player").new()
    Registry.player.immune = true
    Registry.ui = require("game.ui").new()
    Registry.ui:toggle()
    Registry.ui.name = level.name or ("Level " .. toroman(Registry.levelManager.curlvl))

    local update = Util.coroutinize(true, function()
        map.offset[1] = map.offset[1] + map.size[1] + 1
        map.offset[2] = level.yoffset or 0
        map.size[1] = level.width
        map.size[2] = level.height


        local topLeft = map.cellCenter({ map.offset[1] + 1, map.offset[2] + 1 })
        local bottomRight = map.cellCenter({ map.offset[1] + level.width, map.offset[2] + level.height })


        if map.first_load then
            -- Camera:moveTo(map.cellCenter(Util.cellOffset({1, (level.height + 1)/2}, map.offset)))
            setCameraLimits(topLeft, bottomRight)
            Camera:moveTo(map.cellCenter(Util.cellOffset(level.player, map.offset)))
            -- Log("Camera limits:", Camera.limits)
            -- Log("moved to ", map.cellCenter(Util.cellOffset(level.player, map.offset)))
            map.first_load = false
        end

        local oldKeys = gridInSortedOrder(map.cells)
        local newKeys = gridInSortedOrder(level.grid)

        local function loadNew(key)
            local cell = Util.cellOffset(Util.numToCell(key), map.offset)
            local data = level.grid[key]

            if data.teleport then
                data.teleport = Util.cellOffset(data.teleport, map.offset)
            end

            local num = Util.cellToNum(cell)

            map.cells[num] = data
            map.cells[num].decorationFn = generateDecorations()
        end

        local function unloadOld(key)
            map:scheduleDelete(key)
        end

        local time = love.timer.getTime()
        local per_cell_time = TOTAL_LOAD_TIME / (#oldKeys + 1)

        for i = 1, #oldKeys do
            local key = oldKeys[i]
            unloadOld(key)
            time = love.timer.getTime()
            while love.timer.getTime() - time < per_cell_time do
                coroutine.yield(nil)
            end
        end

        setCameraLimits(topLeft, bottomRight)
        Registry.sea:set(topLeft.x - CELL_SIZE / 2 - 10)

        while not Registry.sea:finished() do
            coroutine.yield(nil)
        end

        local player = Util.cellOffset(level.player, map.offset)
        Camera:moveTo(map.cellCenter(player))

        per_cell_time = TOTAL_LOAD_TIME / (#newKeys + 1)

        map.keytints = level.keytints
        map.tint = level.tint
        map.allowedTools = level.allowedTools
        if #map.allowedTools == 0 then
            map.tool = nil
        else
            map.tool = map.allowedTools[1]
        end
        map.tutorials = level.tutorials
        map.resources = level.initialResources or 0

        for i = 1, #newKeys do
            local key = newKeys[i]
            loadNew(key)
            time = love.timer.getTime()
            while love.timer.getTime() - time < per_cell_time do
                coroutine.yield(nil)
            end
        end

        -- Log("Camera limits:", Camera.limits)

        map.goal = Util.cellOffset(level.goal, map.offset)
        map.goalAnim = SimpleAnim:new("map/flag", true)

        map.cursorState = "enabled"

        -- map.player = Util.cellOffset(level.player, map.offset)
        Registry.player:forcedSet({ player[1] + PLAYER_CELL_X_DELTA, player[2] })
        Registry.player:moveTo(player, PLAYER_DROP_TIME, true) -- no audio

        Registry.player.immune = false
        map.cursorState = "default"

        Registry.ui:toggle()

        Events:emit("map_loaded")
    end)

    return {
        deletionAllowed = true,
        update = update,
    }
end
