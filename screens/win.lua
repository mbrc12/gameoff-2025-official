local UIList = require("game.uilist")

---@class WinScreen : Screen
local WinScreen = {
    elapsed = 0,
    ---@type UIList
    uilist = nil,
}

local FADE_DURATION = 0.5

function WinScreen:enter()
    self.elapsed = 0
    self.uilist = UIList.new({ "return to title" })
    Music:playWin()
end

function WinScreen:leave()
end

function WinScreen:update(dt)
    self.elapsed = self.elapsed + dt
    local opt = self.uilist:update(dt)
    if opt == 1 then
        switchScreen(Fader.new(HomeScreen))
    end
end

function WinScreen:draw()
    Draw:draw("ui", ZINDEX.ui.base, function()
        local color = math.min(self.elapsed / FADE_DURATION, 1)
        local base = Util.copyArray(Colors.SteamLords.aubergine)
        for i = 1, 3 do
            base[i] = base[i] * color
        end
        love.graphics.setColor(base)
        love.graphics.rectangle("fill", 0, 0, VIEW_WIDTH, VIEW_HEIGHT)
        love.graphics.setColor(Colors.White)
        if self.elapsed >= FADE_DURATION then
            love.graphics.setColor(Colors.SteamLords.steel_blue)
            Assets.withFontSize(FONT_SIZE * 4, function()
                Draw:centeredText("You Win", VIEW_WIDTH / 2, VIEW_HEIGHT / 2 - 40)
            end)
            self.uilist:draw(VIEW_HEIGHT / 2 + 30)
        end
    end)
end

_G.WinScreen = WinScreen

