DEBUG = false

PROF_CAPTURE = false -- profiling

LURKER_HOTLOAD = DEBUG and true
LOVEBIRD_ENABLE = DEBUG and true

require("lib.__init__")
require("constants")
require("music")

local manual_gc = require("deps.manual_gc")
Prof = require("profile.jprof")

require("game.game")
require("screens.win")
require("screens.restart_level")
require("screens.home")
require("screens.story")
require("screens.click")
require("game.parser"):init()

local moonshine = require("deps.moonshine")
local moonshine_effect

---@type Screen
local currentScreen


function love.load()
    love.joystick.loadGamepadMappings("assets/general/mappings.txt")

    Log({ love.graphics.getRendererInfo() })

    love.graphics.setDefaultFilter("nearest", "nearest")
    -- love.audio.setVolume(0.5)

    moonshine_effect = moonshine(moonshine.effects.glow).chain(moonshine.effects.chromasep).chain(moonshine.effects.scanlines)
    -- moonshine_effect = moonshine(moonshine.effects.chromasep).chain(moonshine.effects.scanlines)
    -- moonshine_effect = moonshine(moonshine.effects.chromasep)
    moonshine_effect.chromasep.radius = 1 -- tasteful chromatic aberration
    moonshine_effect.glow.min_luma = 0.1
    moonshine_effect.glow.strength = 3
    moonshine_effect.scanlines.width = 1
    moonshine_effect.scanlines.thickness = 1
    moonshine_effect.scanlines.opacity = 0.6
    moonshine_effect.scanlines.color = Colors.SteamLords.midnight_black

    if not CAMERA_CENTER then
        Camera.offset = Vec2.new(0, 0)
    end

    Assets:load()
    Music:init()

    Draw:init()

    Mouse:init()
    Input:init()
    SimpleAnim:init()
    -- Anim:init()

    currentScreen = ClickToStart
    currentScreen:enter()
end

function switchScreen(newScreen)
    currentScreen:leave()
    currentScreen = newScreen
    currentScreen:enter()
end

function love.update(dt)
    if LURKER_HOTLOAD then
        require("deps.lurker.lurker").update()
    end
    if LOVEBIRD_ENABLE then
        require("deps.lovebird").update()
    end

    Prof.push("frame")
    Text:clear() -- so that draw never has stale text

    Timer:update(dt)
    Input:update(dt)
    Mouse:update()
    Tweens:update(dt)

    Prof.push("screen_update")
    currentScreen:update(dt)
    Prof.pop("screen_update")

    -- local message = string.format("mem: %.1f M, fps: %d, input: %s, mouse: (%d,%d), abs (%d,%d)",
    --     collectgarbage("count") / 1024,
    --     love.timer.getFPS(),
    --     Input:debugString(),
    --     Mouse:getPosition().x, Mouse:getPosition().y,
    --     Mouse:getAbsolutePosition().x, Mouse:getAbsolutePosition().y
    -- )
    -- local message = string.format("f:%d, m:%.1fM, i:%s",
    --     love.timer.getFPS(),
    --     collectgarbage("count")/1024,
    --     Input:debugString(1)
    -- )
    --
    -- Text:print(message, VIEW_WIDTH - Assets.font:getWidth(message), 10, false, Colors.Sweetie16.lime)

    Prof.push("gc")
    manual_gc(1e-3, 64)
    Prof.pop("gc")
end

function love.draw()
    -- if FULLSCREEN then
    --     ensureFullscreen()
    -- end

    Draw:begin()

    currentScreen:draw()

    Text:draw()

    Draw:finish()

    -- end graphics, start text

    -- preserve aspect ratio
    love.graphics.clear(Colors.Black)
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local finalCanvas = Draw:getFinalCanvas()
    local finalCanvas_width, finalCanvas_height = finalCanvas:getDimensions()
    local scale = math.min(window_width / finalCanvas_width, window_height / finalCanvas_height)
    if INTEGER_SCALING then
        scale = math.floor(scale + EPSILON)
    end
    local offset_x = (window_width - scale * finalCanvas_width) / 2
    local offset_y = (window_height - scale * finalCanvas_height) / 2

    moonshine_effect(function()
        love.graphics.draw(finalCanvas, offset_x, offset_y, 0, scale, scale)
    end)

    Prof.pop("frame")
end

-- function ensureFullscreen()
--     if not love.window.getFullscreen() then
--         love.window.setFullscreen(true)
--     end
-- end

function love.quit()
    Prof.write("prof.mpack") -- run with love11 . lt prof.mpack
end
