SEED = 2
EPSILON = 1e-4
INFINITY = 1e9

CELL_SIZE = 16

VIEW_WIDTH = 320
VIEW_HEIGHT = 180

-- LOCAL = true
LOCAL = true

if LOCAL then
    FULLSCREEN = false
    RENDER_SCALE = 4
else
    FULLSCREEN = true
    RENDER_SCALE = 6
end

RENDER_WIDTH = VIEW_WIDTH * RENDER_SCALE
RENDER_HEIGHT = VIEW_HEIGHT * RENDER_SCALE

CAMERA_CENTER = true

INTEGER_SCALING = false


MOUSE_SPEED = 1.0

TEXT_UPSCALE = 1
FONT_SIZE = 6
TEXT_VIEW_WIDTH = VIEW_WIDTH * TEXT_UPSCALE
TEXT_VIEW_HEIGHT = VIEW_HEIGHT * TEXT_UPSCALE
SCALED_FONT_SIZE = FONT_SIZE * TEXT_UPSCALE

ZINDEX = {
    main = {
        bg = -100,
        cursor = 1000,
    },
    ui = {
        base = 0,
        story = 50,
        text = 100,
        fader = 200,
    },
    map = {
        base = 0,
        water = 1,
    }
}
