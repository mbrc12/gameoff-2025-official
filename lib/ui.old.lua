local HP_SCALE = 0.7

local Ui = {
    ---@type Selection
    selection = nil,
    requiresPause = false,
}

-- local psys

function Ui:init()
    -- psys = love.graphics.newParticleSystem(Assets.texture("particle/mock"))
    -- psys:setEmissionArea("uniform", 5, 1)
    -- psys:setDirection(math.rad(-90))
    -- psys:setLinearDamping(0.5, 1)
    -- psys:setSpeed(20, 30)
    -- psys:setParticleLifetime(0.5, 1)
    -- psys:setEmissionRate(50)
    -- psys:setLinearAcceleration(-3, 0, 3, 0)
    -- psys:setColors(Colors.Yellow, Colors.Yellow, Colors.Teracotta, Colors.Rosewood, Colors.DarkMauve, Colors.EerieBlack)
    -- psys:setSizeVariation(0.5)
    -- psys:setSizes(0.1, 0.5, 0.7, 0.5, 0.3)
    -- psys:start()
end

function Ui:getHp()
    return self.hp
end

function Ui:setHp(hp)
    self.hp = Util.clamp(hp, 0, self.maxHp)
end

function Ui:setMaxHp(maxHp)
    self.maxHp = maxHp
    self.hp = Util.clamp(self.hp, 0, self.maxHp)
end

---@param selectionTree table table of string -> table | nil containing the possible paths of selection
function Ui:choose(selectionTree, callback)
    ---@class Selection
    self.selection = {
        tree = selectionTree,
        callback = callback,
        path = {},
        index = 1,
        choices = Util.keys(selectionTree),
    }
    self.requiresPause = true
    Log("Ui:choose", self.selection.choices)
end

function Ui:drawSelection()
    -- Log(self.selection.choices)

    local height = 10

    for _, v in ipairs(self.selection.path) do
        Text:print(v, 10, height, false, Colors.White)
        height = height + 10
    end

    Text:print("---", 10, height, false, Colors.White)
    height = height + 10

    for i, choice in ipairs(self.selection.choices) do
        local prefix = (i == self.selection.index) and "> " or "  "
        Text:print(prefix .. choice, 10, height, false, Colors.White)
        height = height + 10
    end

    if Input:isJustPressed("UP") then
        self.selection.index = self.selection.index - 1
        if self.selection.index < 1 then
            self.selection.index = #self.selection.choices
        end
    end
    if Input:isJustPressed("DOWN") then
        self.selection.index = self.selection.index + 1
        if self.selection.index > #self.selection.choices then
            self.selection.index = 1
        end
    end

    if Input:isJustPressed("INTERACT") then
        local choice = self.selection.choices[self.selection.index]
        table.insert(self.selection.path, choice)
        self.selection.tree = self.selection.tree[choice]
        if Util.isEmpty(self.selection.tree) then
            local callback = self.selection.callback
            callback(choice, self.selection.path)
            self.requiresPause = false
            self.selection = nil
        else
            self.selection.choices = Util.keys(self.selection.tree)
            self.selection.index = 1
        end
    end
end

---@param dt number
function Ui:update(dt)
    if self.selection then
        self:drawSelection()
    end
end

local regions = {
    leftEnd = { x = 0, y = 0, w = 32, h = 32 },
    filled = { x = 32, y = 0, w = 32, h = 32 },
    empty = { x = 64, y = 0, w = 32, h = 32 },
    rightEnd = { x = 96, y = 0, w = 32, h = 32 },
}

function Ui:drawHp()
    local hpTexture = Assets.texture("ui/hp")
    local filledLength = math.floor(self.hp * HP_SCALE)
    local emptyLength = math.floor((self.maxHp - self.hp) * HP_SCALE)

    local quadLeftEnd = love.graphics.newQuad(regions.leftEnd.x, regions.leftEnd.y, regions.leftEnd.w, regions.leftEnd.h,
        hpTexture:getDimensions())
    local quadFilled = love.graphics.newQuad(regions.filled.x, regions.filled.y, regions.filled.w, regions.filled.h,
        hpTexture:getDimensions())
    local quadEmpty = love.graphics.newQuad(regions.empty.x, regions.empty.y, regions.empty.w, regions.empty.h,
        hpTexture:getDimensions())
    local quadRightEnd = love.graphics.newQuad(regions.rightEnd.x, regions.rightEnd.y, regions.rightEnd.w,
        regions.rightEnd.h, hpTexture:getDimensions())
    local GAP = -10
    local YGAP = 3

    love.graphics.clear(Colors.Transparent)
    love.graphics.draw(hpTexture, quadLeftEnd, GAP, YGAP)
    love.graphics.draw(hpTexture, quadFilled, GAP + regions.leftEnd.w, YGAP, 0, filledLength / regions.filled.w, 1)
    love.graphics.draw(hpTexture, quadEmpty, GAP + regions.leftEnd.w + filledLength, YGAP, 0,
        emptyLength / regions.empty.w, 1)
    love.graphics.draw(hpTexture, quadRightEnd, GAP + regions.leftEnd.w + filledLength + emptyLength, YGAP)
end

function Ui:draw()
    if not self.selection then
        -- self:drawHp()
    end

    -- -- love.graphics.setBlendMode("darken", "premultiplied")
    -- love.graphics.draw(psys, VIEW_WIDTH * 0.66, VIEW_HEIGHT * 0.66)
    --
    -- Camera:apply()
    -- local mouse = Mouse:getPosition()
    -- love.graphics.draw(Assets.texture("ui/mouse"), mouse.x, mouse.y, 0, 1, 1, 8, 8)
    -- Camera:unapply()
end

_G.Ui = Ui
