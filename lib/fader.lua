local DEFAULT_FADE_TIME = 1

---@class Fader : Screen
local Fader = {
    total_time = 1,
    elapsed = 0,
    ---@type Screen
    screen = nil,
}
Fader.__index = Fader

---@param screen Screen
---@param time? number
---@return Fader
function Fader.new(screen, time)
    local o = {
        elapsed = 0,
        total_time = time or DEFAULT_FADE_TIME,
        screen = screen,
    }
    setmetatable(o, Fader)
    return o
end

function Fader:enter()
    self.alpha = 1
    self.screen:enter()
end

function Fader:leave()
    self.screen:leave()
end

function Fader:update(dt)
    self.elapsed = self.elapsed + dt
    self.screen:update(dt)
end

function Fader:draw()
    if self.elapsed < self.total_time then
        local t = math.min(self.elapsed / self.total_time, 1)
        Draw:draw("ui", ZINDEX.ui.fader, function()
            Draw:withShader("fader", {
                colorA = Colors.SteamLords.steel_blue,
                colorB = Colors.SteamLords.additional_blue,
                radius = math.pow(t, 0.5) * VIEW_WIDTH,
            }, function()
                love.graphics.rectangle("fill", 0, 0, VIEW_WIDTH, VIEW_HEIGHT)
            end)
        end)
    end

    self.screen:draw()
end

_G.Fader = Fader
