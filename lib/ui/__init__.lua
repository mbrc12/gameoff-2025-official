local Ui = {
    outlines = {}
}

MAX_WIDTH = 100
INSET = 5

function Ui:init()
    self.outlines = {}
end

function Ui:update(dt)
end

local buttonData = {
    normal = {
        ---@type NinePatchConfig
        ninepatch = {
            asset = "ui/button",
            texture = { x = 0, y = 0, w = 48, h = 48 },
            padding = { left = 16, right = 16, top = 16, bottom = 16 },
        },

        yoffset = 14,
    },

    click = {
        ---@type NinePatchConfig
        ninepatch = {
            asset = "ui/button",
            texture = { x = 48, y = 0, w = 48, h = 48 },
            padding = { left = 16, right = 16, top = 16, bottom = 16 },
        },

        yoffset = 18,
    },
}

local checkboxData = {
    off = {
        ---@type NinePatchConfig
        ninepatch = {
            asset = "ui/checkbox",
            texture = { x = 0, y = 0, w = 48, h = 48 },
            padding = { left = 21, right = 16, top = 16, bottom = 16 },
        },

        yoffset = 18,
        textcolor = Colors.CC29LightGray,
    },

    on = {
        ---@type NinePatchConfig
        ninepatch = {
            asset = "ui/checkbox",
            texture = { x = 48, y = 0, w = 48, h = 48 },
            padding = { left = 16, right = 21, top = 16, bottom = 16 },
        },

        yoffset = 18,
        textcolor = Colors.CC29Black,
    },
}

local state = "off"

local nclicks = 1

function Ui:draw()
    local text = "circumcircles"
    local x, y = 10, 10

    local width = Assets.font:getWidth(text)
    local upgradedWidth = math.ceil((width + 10) / 16) * 16
    local height = Assets.font:getHeight()

    local version = Mouse:isDown() and checkboxData.on or checkboxData.off

    local fullWidth = upgradedWidth + version.ninepatch.padding.left + version.ninepatch.padding.right
    local fullHeight = height + version.ninepatch.padding.top + version.ninepatch.padding.bottom

    local mouse = Mouse:getAbsolutePosition()
    local mx, my = mouse.x, mouse.y
    local touch = false

    if mx >= x and mx <= x + fullWidth and my >= y and my <= y + fullHeight then
        touch = true
    end

    if touch and Mouse:isJustDown() then
        state = state == "on" and "off" or "on"
    end

    version = checkboxData[state]

    Draw:draw("ui", 0, function()
        Ninepatch:draw(version.ninepatch, x, y, fullWidth, fullHeight)
        if touch then
            Ui:scheduleOutline(x, y, fullWidth, fullHeight)
        end

        love.graphics.setColor(version.textcolor or Colors.CC29LightGray)
        love.graphics.print(text,
            x + version.ninepatch.padding.left + (upgradedWidth - width) / 2,
            y + version.yoffset)
    end)

    if Mouse:isJustDown() and touch then
        nclicks = nclicks * 1.5
        Assets.sfx("click"):play()
    end

    Ui:drawOutlines()
end

function Ui:scheduleOutline(x, y, w, h)
    table.insert(self.outlines, { x, y, w, h })
end

function Ui:drawOutlines()
    Draw:draw("ui_background", 0, function()
        if #self.outlines == 0 then
            return
        end

        local shader = Assets.shader("outline")
        love.graphics.setShader(shader)
        Util.setShaderUniforms(shader, {
            sourceTexture = Draw.canvases["ui"],
            aOutlines = self.outlines,
            outlineCount = #self.outlines,
            highlightColor = Colors.CC29LightGray,
        })

        love.graphics.rectangle("fill", 0, 0, VIEW_WIDTH, VIEW_HEIGHT)
        love.graphics.setShader()

        self.outlines = {}
    end)
end

_G.Ui = Ui
