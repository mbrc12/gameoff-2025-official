---@enum (key) DrawTargets
local DrawTargets = {
    _composite = 0,
    main = 1,
    ui = 2,
}

local targetOrder = { "main", "ui" }

---@type table<DrawTargets, { clear: number[], camera: boolean, width: integer, height: integer }>
local targetSettings = {
    _composite = { clear = Colors.Transparent, camera = false, width = RENDER_WIDTH, height = RENDER_HEIGHT },
    main = { clear = Colors.SteamLords.midnight_black, camera = true, width = VIEW_WIDTH, height = VIEW_HEIGHT, scale = RENDER_WIDTH / VIEW_WIDTH },
    ui = { clear = Colors.Transparent, camera = false, width = VIEW_WIDTH, height = VIEW_HEIGHT, scale = RENDER_WIDTH / VIEW_WIDTH },
}

local Draw = {
    ---@type love.Shader
    defaultShader = nil,

    ---@type table<DrawTargets, table<number, fun()[]>>
    calls = {},

    ---@type table<DrawTargets, love.Canvas>
    canvases = {},

} -- draw order management

function Draw:init()
    self.defaultShader = Assets.shader("default")
    self:_resetShader()

    for name, _ in pairs(DrawTargets) do
        local settings = targetSettings[name]
        self.canvases[name] = love.graphics.newCanvas(
            settings.width,
            settings.height
        )
    end
end


---@return love.Canvas
function Draw:getFinalCanvas()
    return self.canvases["_composite"]
end

--- Call Draw:begin() to start a new collection of draw calls
--- Call Draw:finish() to execute the collected draw calls in order of their z value

function Draw:_resetShader()
    love.graphics.setShader(self.defaultShader)
    Util.setShaderUniforms(self.defaultShader, { blink = 0, blinkColor = Colors.BLINK_COLOR })
end

---@param shaderName Assets.Shaders
---@param parameters table<string, any>
---@param fn fun() a function that performs arbitrary drawing commands
function Draw:withShader(shaderName, parameters, fn)
    local shader = Assets.shader(shaderName)
    love.graphics.setShader(shader)
    Util.setShaderUniforms(shader, parameters)

    fn()

    self:_resetShader()
end

--- enable blink effect in the default shader
---@param on boolean
function Draw:blink(on)
    Util.setShaderUniforms(self.defaultShader, { blink = on and 1 or 0 })
end

function Draw:begin()
    self.calls = {}
end

---@param textureOrName Assets.Textures | love.Image
---@param x number
---@param y number
---@param r? number rotation in degrees
---@param flip? boolean whether to flip the texture horizontally
---@param center? boolean whether to center the texture on (x, y)
---@param tx? number optional, texture coordinate u
---@param ty? number optional, texture quad v
---@param tw? number optional, texture quad width
---@param th? number optional, texture quad height
---@param scale? number
function Draw:simple(textureOrName, x, y, r, flip, center, tx, ty, tw, th, scale)
    ---@type love.Image
    local texture = textureOrName

    scale = scale or 1

    if type(textureOrName) == "string" then
        texture = Assets.texture(textureOrName)
    end

    r = r or 0
    r = math.rad(r % 360)

    if center == nil then
        center = true
    end

    flip = flip or false
    tx = tx or 0
    ty = ty or 0
    tw = tw or texture:getWidth()
    th = th or texture:getHeight()

    local sx = flip and -1 or 1

    local ox = center and Util.round(tw / 2) or 0
    local oy = center and Util.round(th / 2) or 0

    local quad = love.graphics.newQuad(tx, ty, tw, th, texture:getWidth(), texture:getHeight())

    love.graphics.draw(texture, quad, x, y, r, sx * scale, scale, ox, oy)
end

---@class SpriteConfig
---@field asset Assets.Textures
---@field tx number
---@field ty number
---@field tw? number
---@field th? number
---@field center? boolean

local spriteConfigDefaults = { center = true }

---@param spriteCfg SpriteConfig | Assets.Sprites
---@param x number
---@param y number
---@param r? number
---@param flip? boolean
function Draw:sprite(spriteCfg, x, y, r, flip)
    if type(spriteCfg) == "string" then
        spriteCfg = Assets.sprites[spriteCfg]
    end

    ---@cast spriteCfg SpriteConfig

    flip = flip or false
    r = r or 0

    Util.defaults(spriteCfg, spriteConfigDefaults)

    self:simple(
        spriteCfg.asset,
        x,
        y,
        r,
        flip,
        spriteCfg.center,
        spriteCfg.tx,
        spriteCfg.ty,
        spriteCfg.tw,
        spriteCfg.th
    )
end

---@param text string
---@param x number
---@param y number
---@return number width
---@return number height
function Draw:centeredText(text, x, y)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    love.graphics.print(text, x - textWidth / 2, y - textHeight / 2 + 1)
    return textWidth, textHeight
end

---@param text string
---@param x number
---@param y number
---@return number width
---@return number height
function Draw:rightAlignedText(text, x, y)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, x - textWidth, y)
    return textWidth, textHeight
end

---@param text string
---@param x number
---@param y number
function Draw:text(text, x, y)
    love.graphics.print(text, x, y)
end

---@param target DrawTargets
---@param zIndex number
---@param fn fun() a function that performs arbitrary drawing commands
function Draw:draw(target, zIndex, fn)
    if not self.calls[target] then
        self.calls[target] = {}
    end

    local calls = self.calls[target]

    if not calls[zIndex] then
        calls[zIndex] = {}
    end

    table.insert(calls[zIndex], fn)
end

---@param name DrawTargets
function Draw:_doCanvas(name)
    Prof.push("canvas_" .. name)
    local canvas = self.canvases[name]

    Prof.push("canvas_setup_" .. name)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(targetSettings[name].clear)
    Prof.pop("canvas_setup_" .. name)


    local calls = self.calls[name]

    Prof.push("canvas_sort")
    local zKeys = Util.keys(calls)
    table.sort(zKeys)
    Prof.pop("canvas_sort")

    if targetSettings[name].camera then
        Camera:apply()
    end

    for _, item in ipairs(zKeys) do
        local fns = calls[item]
        Prof.push("z_" .. item)
        for _, fn in ipairs(fns) do
            fn()
            love.graphics.setColor(Colors.White)
        end
        Prof.pop("z_" .. item)
    end

    self.calls[name] = {}
    love.graphics.setCanvas()

    if targetSettings[name].camera then
        Camera:unapply()
    end

    Prof.pop("canvas_" .. name)
end

function Draw:finish()
    for _, name in ipairs(targetOrder) do
        self:_doCanvas(name)
    end

    --- composite pass

    Prof.push("draw_composite")

    love.graphics.setCanvas(self.canvases["_composite"])
    love.graphics.clear(targetSettings["_composite"].clear)

    local composite_width = self.canvases["_composite"]:getWidth()
    local composite_height = self.canvases["_composite"]:getHeight()

    -- produce the composite canvas
    love.graphics.setColor(Colors.White)

    for _, name in ipairs(targetOrder) do
        local settings = targetSettings[name]
        local scale = math.min(
            composite_width / settings.width,
            composite_height / settings.height
        )
        local offset_x = (composite_width - (settings.width * scale)) / 2
        local offset_y = (composite_height - (settings.height * scale)) / 2

        love.graphics.draw(self.canvases[name], offset_x, offset_y, 0, scale, scale)
    end

    love.graphics.setCanvas()
    Prof.pop("draw_composite")
end

_G.Draw = Draw
