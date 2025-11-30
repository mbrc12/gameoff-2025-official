local UIList = require("game.uilist")

---@class HomeScreen : Screen
local HomeScreen = {
    ---@type Sea
    sea = nil,
    ---@type UIList[]
    uistack = {},
    ---@type love.ParticleSystem
    particleSystem = nil,
    ---@type table<string, number>
    levels = {},
    selectingLevel = false
}

local ui = {
    _opts = { "start", "select level", "replay intro", "options" },
    start = { },
    ["select level"] = { },
    ["replay intro"] = {},
    options = {
        _opts = { "sensitivity", "bgm volume" },
        sensitivity = { -- sensitivity is inverse of movement time
            _opts = { "x 0.5", "x 1.0", "x 2.0" },
            ["x 0.5"] = 2,
            ["x 1.0"] = 1,
            ["x 2.0"] = 0.5,
        },
        ["bgm volume"] = {
            _opts = { "low", "medium", "high" },
            low = 0,
            medium = 1,
            high = 2,
        }
    },
}

function HomeScreen:enter()
    Music:playMenu()
    
    local parser = require("game.parser")
    local list = parser:list()
    for i, lvl in ipairs(list) do
        local name = parser:get(lvl).name
        assert(name, "Level has no name: " .. lvl)
        ---@cast name string
        self.levels[name] = i
        table.insert(ui["select level"], name)
    end
    
    self.selectingLevel = false
    self.particleSystem = Game.particleSystem()
    Camera:reset()
    sea = require("game.sea").new()
    sea:set(-100)
    self.uistack = {}
    table.insert(self.uistack, UIList.new(ui._opts, true, false))
end

function HomeScreen:leave()
end

function HomeScreen:update(dt)
    sea:update()
    self.particleSystem:update(dt)
    local current_ui = self.uistack[#self.uistack]
    local opt = current_ui:update(dt)
    if not opt then
        return
    end
    if opt == -1 and #self.uistack > 1 then
        table.remove(self.uistack)
        selectingLevel = false
        return
    end
    local selection = current_ui.options[opt]
    if self.selectingLevel then
        local lvlnum = self.levels[selection]
        _G.LevelToLoad = lvlnum
        switchScreen(Fader.new(Game))
    end
    if selection == "start" then
        -- print("starting game")
        switchScreen(Fader.new(Game))
    end
    if selection == "select level" then
        self.selectingLevel = true
        table.insert(self.uistack, UIList.new(ui["select level"], true, true)) -- compressed
        return
    end
    if selection == "replay intro" then
        switchScreen(Fader.new(StoryScreen))
    end
    if selection == "options" then
        table.insert(self.uistack, UIList.new(ui.options._opts, true))
    end
    if selection == "sensitivity" then
        table.insert(self.uistack, UIList.new(ui.options.sensitivity._opts, true))
    end
    if selection == "bgm volume" then
        table.insert(self.uistack, UIList.new(ui.options["bgm volume"]._opts, true))
    end
    for sens, mult in pairs(ui.options.sensitivity) do
        if selection == sens then
            _G.MOVEMENT_TIME = _G.ORIGINAL_MOVEMENT_TIME * mult
            table.remove(self.uistack)
        end
    end
    for vol, level in pairs(ui.options["bgm volume"]) do
        if selection == vol then
            Music:setVolume(vol)
            table.remove(self.uistack)
        end
    end
end

function HomeScreen:draw()
    Draw:draw("main", 0, function()
        sea:draw()
    end)
    Draw:draw("ui", ZINDEX.ui.base, function()
        love.graphics.draw(self.particleSystem, VIEW_WIDTH / 2, -10)
        Draw:sprite("title", VIEW_WIDTH / 2 + 10, VIEW_HEIGHT / 2 - 40)
        local current_ui = self.uistack[#self.uistack]
        current_ui:draw(VIEW_HEIGHT / 2 )
    end)
end

_G.HomeScreen = HomeScreen
