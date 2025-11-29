local UIList = require("game.uilist")

---@class HomeScreen : Screen
local HomeScreen = {
    ---@type Sea
    sea = nil,
    ---@type UIList[]
    uistack = {},
    ---@type love.ParticleSystem
    particleSystem = nil,
}

local ui = {
    _opts = { "start", "replay intro", "options", "quit" },
    start = { },
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
    quit = {},
}

function HomeScreen:enter()
    Music:playMenu()
    self.particleSystem = Game.particleSystem()
    Camera:reset()
    sea = require("game.sea").new()
    sea:set(-100)
    self.uistack = {}
    table.insert(self.uistack, UIList.new(ui._opts))
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
        return
    end
    local selection = current_ui.options[opt]
    if selection == "start" then
        -- print("starting game")
        switchScreen(Fader.new(Game))
    end
    if selection == "replay intro" then
        switchScreen(Fader.new(StoryScreen))
    end
    if selection == "options" then
        table.insert(self.uistack, UIList.new(ui.options._opts, true))
    end
    if selection == "quit" then
        love.event.quit()
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
