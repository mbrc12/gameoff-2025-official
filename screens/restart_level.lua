---@class RestartScreen : Screen
local RestartScreen = {
    elapsed = 0
}

local FADE_DURATION = 0.5

function RestartScreen:enter()
    self.elapsed = 0
end

function RestartScreen:leave()
end

function RestartScreen:update(dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed >= FADE_DURATION then
        local current_level = Registry.levelManager.curlvl
        _G.LevelToLoad = current_level
        switchScreen(Fader.new(Game))
    end
end

function RestartScreen:draw()
    Draw:draw("ui", ZINDEX.ui.base, function()
        local color = math.min(self.elapsed / FADE_DURATION, 1)
        local base = Util.copyArray(Colors.SteamLords.steel_blue)
        for i = 1, 3 do
            base[i] = base[i] * color
        end
        love.graphics.setColor(base)
        love.graphics.rectangle("fill", 0, 0, VIEW_WIDTH, VIEW_HEIGHT)
        love.graphics.setColor(Colors.White)
    end)
end

_G.RestartScreen = RestartScreen

