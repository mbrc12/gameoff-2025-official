local PAD = 10
local UIList = require("game.uilist")

---@param kind "bomb"|"drowning"
return function(kind)
    if kind == "bomb" then
        Sounds:sfx("damage")
    else
        Sounds:sfx("drowning")
    end

    local uilist = UIList.new({
        "restart level",
        "quit to menu",
    })
    local uilist2 = UIList.new({
        "no, stay",
        "yes, return and lose progress",
    })
    local current = uilist
    return {
        shouldSnap = false,
        update = function(dt)
            local opt = current:update(dt)
            if not opt then
                return false
            end
            if opt == 1 and current == uilist then
                switchScreen(RestartScreen)
                return true
            elseif opt == 2 and current == uilist then
                current = uilist2
            elseif opt == 1 and current == uilist2 then
                current = uilist
            elseif opt == 2 and current == uilist2 then
                switchScreen(Fader.new(HomeScreen))
                return true
            end
        end,
        draw = function()
            Draw:draw("ui", 100, function()
                love.graphics.setColor(Colors.withAlpha(Colors.SteamLords.indigo_berry, 0.9))
                love.graphics.rectangle("fill", PAD, PAD, VIEW_WIDTH - PAD*2, VIEW_HEIGHT - PAD*2)

                love.graphics.setColor(Colors.SteamLords.pale_teal)
                local text = current == uilist and
                    "Game Over" or
                    "Confirm"
                Assets.withFontSize(FONT_SIZE * 3, function()
                    Draw:centeredText(text, VIEW_WIDTH / 2, VIEW_HEIGHT / 2 - 30)
                end)

                current:draw(VIEW_HEIGHT / 2 + 10)
            end)
        end
    }
end

