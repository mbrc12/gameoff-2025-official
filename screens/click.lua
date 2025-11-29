---@class ClickToStart : Screen
local ClickToStart = {
}

function ClickToStart:enter()
end
function ClickToStart:leave()
end

function ClickToStart:update(dt)
    if love.mouse.isDown(1) then
        switchScreen(Fader.new(StoryScreen))
    end
end

function ClickToStart:draw()
    Draw:draw("ui", ZINDEX.ui.base, function()
        love.graphics.setColor(Colors.SteamLords.forest_green)
        love.graphics.rectangle("fill", 0, 0, VIEW_WIDTH, VIEW_HEIGHT)
        love.graphics.setColor(Colors.SteamLords.taupe_green)
        Assets.withFontSize(FONT_SIZE*2, function()
            Draw:centeredText("Click to Start", VIEW_WIDTH / 2, VIEW_HEIGHT / 2 - 10)
        end)
    end)
end

_G.ClickToStart = ClickToStart

