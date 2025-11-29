require("constants")

function love.conf(t)
    t.window.width = RENDER_WIDTH
    t.window.height = RENDER_HEIGHT
    t.window.fullscreen = FULLSCREEN
    t.modules.physics = false
    t.modules.touch = false
    t.window.title = "Perilous Escape"
    -- t.graphics.gammacorrect = false
    -- t.window.msaa = 0
    -- t.window.vsync = true
    -- t.graphics.setDefaultFilter("nearest", "nearest")
end
