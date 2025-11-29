_G.RESOURCE_MAX = 27

local control = require("game.control")

require("game.player")
require("game.level_manager")

---@class LogicDelegate
---@field shouldSnap? boolean -- whether the player should be snapped to grid when this delegate starts
---@field deletionAllowed? boolean -- whether regular deletions are allowed during this delegate's lifetime
---@field update fun(self: LogicDelegate, dt: number): boolean -- return true to end and remove this delegate
---@field draw? fun(self: LogicDelegate)
---@field onComplete? fun(self: LogicDelegate)

---@class MapCell
---@field item boolean
---@field revealed boolean
---@field explored boolean
---@field decorationFn? DecorationFn
---@field bomb boolean -- whether this cell contains a bomb
---@field countConcealed boolean -- whether to conceal the bomb count even when revealed
---@field teleport? Cell -- cell to teleport to
---@field key? string -- name of key contained in this cell
---@field keyText? string[] -- text to show when picking up this key
---@field door? string -- name of key that opens this door
---@field wall? boolean -- whether this cell is a wall
---@field tutorialId? string -- tutorial to trigger when this cell is revealed


---@enum (key) CursorState
local CursorState = {
    default = "default",
    enabled = "enabled",
    disabled = "disabled",
}

---@enum (key) Tools
local Tools = {
    rat = "rat",
    water = "water",
    defuser = "defuser",
}

ToolCosts = {
    rat = 1,
    water = 2,
    defuser = 3,
}

---@class Map
local Map = {
    allowedTools = {},

    first_load = true, -- if map is waiting on being loaded for the first time
    ---@type table<number, MapCell>
    cells = {},
    ---@type number[]
    cellsScheduledForDeletion = {},

    ---@type number[]
    tint = nil,
    ---@type table<string, number[]>
    keytints = {},

    ---@type LogicDelegate[]
    extensions = {},

    ---@type Cell
    offset = { 0, 0 },
    ---@type number[]
    size = { 0, 0 },

    ---@type Cell|nil
    goal = nil,
    ---@type number|nil
    goalAnim = nil,


    ---@type Cell
    player = { 0, 0 },
    ---@type Vec2
    playerPos = nil,

    ---@type Tools
    tool = nil,
    resources = 0,

    ---@type LogicDelegate
    pauseDelegate = nil,
    ---@type CursorState
    cursorState = "default",

    glint = nil,

    ---@type table<string, Tutorial>
    tutorials = {},

    ---@type table<number, Vec2>
    untrackedAnimations = {},
}
Map.__index = Map

function Map.new()
    Util.seed(SEED)
    o = {
        allowedTools = {},
        first_load = true,
        cells = {},
        cellsScheduledForDeletion = {},
        tint = nil,
        keytints = {},
        extensions = {},
        offset = { 0, 0 },
        size = { 0, 0 },
        goal = nil,
        goalAnim = nil,
        player = { 0, 0 },
        playerPos = nil,
        tool = nil,
        resources = 0,
        pauseDelegate = nil,
        cursorState = "default",
        glint = SimpleAnim:new("glint", true),
        tutorials = {},
        untrackedAnimations = {},
    }
    setmetatable(o, Map)
    return o
end

function Map:resetForNewLevel()
    self.cursorState = "default"
    self.allowedTools = {}
    self.tool = nil
    self.extensions = {}
    self.cellsScheduledForDeletion = {}
end

---@param cell Cell
---@return MapCell
function Map:get(cell)
    return self.cells[Util.cellToNum(cell)]
end

---@param cell Cell
---@return Vec2
function Map.cellCenter(cell)
    return Vec2.new(
        (cell[1] * CELL_SIZE + CELL_SIZE / 2),
        (cell[2] * CELL_SIZE + CELL_SIZE / 2)
    )
end

---@param cell Cell
---@return boolean
function Map:exists(cell)
    return self:get(cell) ~= nil
end

---@param c Cell
function Map:reveal(c)
    self:get(c).revealed = true
end

---@param cell Cell
---@param fn fun(adjacent: Cell)
---@param includeSelf? boolean
function Map:iterateAdjacent(cell, fn, includeSelf)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if includeSelf or (dx ~= 0 or dy ~= 0) then
                local adjacent = { cell[1] + dx, cell[2] + dy }
                if self:exists(adjacent) then
                    fn(adjacent)
                end
            end
        end
    end
end

---@param cell Cell
---@return boolean
function Map:isBomb(cell)
    return self.cells[Util.cellToNum(cell)].bomb
end

---@param cell Cell
---@return number
function Map:adjacentBombs(cell)
    local count = 0
    self:iterateAdjacent(cell, function(adjacent)
        if self.cells[Util.cellToNum(adjacent)].bomb then
            count = count + 1
        end
    end, true)
    return count
end

---@param delegate LogicDelegate?
---@return boolean -- whether pausing was successful
function Map:pause(delegate)
    if not delegate then
        return false
    end
    -- default behavior is to snap the player to grid when pausing
    if delegate.shouldSnap == nil or delegate.shouldSnap == true then
        Registry.player:finishMovement()
    end
    self.pauseDelegate = delegate
    return true
end

---@param ext LogicDelegate
function Map:addExtension(ext)
    table.insert(self.extensions, ext)
end

---@param num number
function Map:scheduleDelete(num)
    table.insert(self.cellsScheduledForDeletion, num)
end

---@param dt number
function Map:update(dt)
    if love.keyboard.isDown("f7") then
        dbg()
    end

    Registry.bird:update(dt)
    Registry.sea:update(dt)

    --- Each pause delegate can specify whether regular deletions are allowed during its lifetime (this
    --- is the case for map loading, for example, but disabled for exploration and such).
    --- It would be nicer to have a general system to handle conflicts like this, but I do not have a good
    --- idea for that right now.

    local shouldDelete = true
    if self.pauseDelegate then
        shouldDelete = shouldDelete and (self.pauseDelegate.deletionAllowed or false)
    end

    if shouldDelete and #self.cellsScheduledForDeletion > 0 then
        for _, num in ipairs(self.cellsScheduledForDeletion) do
            local animId = SimpleAnim:new("map/delete", false)
            local cell = Util.numToCell(num)
            local pos = self.cellCenter(cell)
            self.untrackedAnimations[animId] = pos
            self.cells[num] = nil
        end
        self.cellsScheduledForDeletion = {}
    end

    Registry.player:update(dt)

    if self.pauseDelegate then
        if self.pauseDelegate.update then
            if self.pauseDelegate:update(dt) then
                if self.pauseDelegate.onComplete then
                    self.pauseDelegate:onComplete()
                end
                self.pauseDelegate = nil
            end
        else
            self.pauseDelegate = nil
        end

        return
    end

    --- this is not executed when pause-delegate is active

    control(dt)

    --- usual delegates are updated
    Util.arrayEraseIf(self.extensions, function(ext)
        local shouldRemove = ext:update(dt)
        return shouldRemove
    end)

    Registry.ui:update(dt)

    --- decision on level success/failure overrides all pause delegates
    Registry.levelManager:decide()

    --- draw comes after this, so we can clamp resources here
    self.resources = math.min(self.resources, RESOURCE_MAX)
end

------ draw

function Map:draw()
    -- dbg()
    -- Camera:moveTo(self.playerPos)

    Draw:draw("main", ZINDEX.map.base, function()
        local hiddens = {}

        Util.eraseIf(self.untrackedAnimations, function(pos, id)
            local completed = SimpleAnim:draw(id, pos)
            return completed
        end)

        for num, cellData in pairs(self.cells) do
            local cell = Util.numToCell(num)
            local pos = self.cellCenter(cell)
            if Util.cellEq(cell, self.goal) then
                SimpleAnim:draw(self.goalAnim, pos)
            elseif cellData.key then
                love.graphics.setColor(self.keytints[cellData.key])
                Draw:sprite("map/key", pos.x, pos.y)
                love.graphics.setColor(Colors.White)
                SimpleAnim:draw(self.glint, pos)
            elseif cellData.wall then
                table.insert(hiddens, cell)
            elseif cellData.revealed then
                if cellData.bomb then
                    Draw:sprite("map/bomb", pos.x, pos.y)
                elseif cellData.teleport then
                    Draw:sprite("map/teleport", pos.x, pos.y)
                elseif cellData.countConcealed and self:adjacentBombs(cell) > 0 then
                    Draw:sprite("map/cross", pos.x, pos.y)
                elseif not cellData.explored and self:adjacentBombs(cell) == 0 then
                    Draw:sprite("map/unexplored", pos.x, pos.y)
                end

                if cellData.item then
                    Draw:sprite("map/item", pos.x, pos.y)
                end
            else
                table.insert(hiddens, cell)
            end
        end

        if #hiddens > 0 then
            love.graphics.setColor(self.tint)
        end
        --- draw all hidden at once to reduce color switches
        for _, cell in ipairs(hiddens) do
            local pos = self.cellCenter(cell)
            local cellData = self:get(cell)
            Draw:sprite("map/hidden", pos.x, pos.y)
            if cellData.wall then
                Draw:sprite("map/wall", pos.x, pos.y)
            end
            if cellData.door then
                love.graphics.setColor(self.keytints[cellData.door])
                Draw:sprite("map/door", pos.x, pos.y)
                love.graphics.setColor(self.tint)
            end
        end
        love.graphics.setColor(Colors.White)

        for _, cell in ipairs(hiddens) do
            local cellData = self:get(cell)
            if cellData.decorationFn and not cellData.door and not cellData.wall then
                cellData.decorationFn(cell)
            end
        end

        local locatorSprite = nil
        if self.cursorState == "default" then
            locatorSprite = self.pauseDelegate and "map/locator_paused" or "map/locator"
        elseif self.cursorState == "enabled" then
            locatorSprite = "map/locator"
        end

        if locatorSprite and self.playerPos then
            Draw:sprite(locatorSprite, self.playerPos.x, self.playerPos.y, 0)
        end

        love.graphics.setColor(Colors.SteamLords.pale_teal)

        for num, cellData in pairs(self.cells) do
            local cell = Util.numToCell(num)
            local pos = self.cellCenter(cell)
            local forbidNumber =
                (not cellData.revealed) or
                cellData.bomb or
                cellData.teleport or
                Util.cellEq(cell, self.goal) or
                cellData.door or
                cellData.key
            if not forbidNumber then
                local adj = self:adjacentBombs(cell)
                if adj > 0 and not cellData.countConcealed then
                    Draw:centeredText("" .. adj, pos.x + 1, pos.y - 1)
                end
            end
        end

        love.graphics.setColor(Colors.White)

        Registry.sea:draw()
        Registry.bird:draw()
    end)

    for _, ext in ipairs(self.extensions) do
        if ext.draw then
            ext:draw()
        end
    end

    if self.pauseDelegate and self.pauseDelegate.draw then
        self.pauseDelegate:draw()
    end

    Registry.ui:draw()
end

return Map
