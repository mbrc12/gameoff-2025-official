local DIALOG_X = 10
local DIALOG_Y = 43
local WIDTH = VIEW_WIDTH - DIALOG_X * 2
local BOX_X = 0
local BOX_H = 50
local MAX_DIALOG_TIME = 9999

---@param text string[]
---@return LogicDelegate
return function(text)
    local i = 1
    ---@return Dialog
    local function dialogFactory(j)
        return Dialog.new(WIDTH, text[j])
    end
    ---@type Dialog|nil
    local dialog = dialogFactory(i)
    local done = false

    local anim = SimpleAnim:new("story/wait", true)

    ---@type LogicDelegate
    return {
        update = function(self, dt)
            if dialog and not done then
                done = dialog:update(dt) or false
            end

            if dialog and not done and Input:isJustPressed("INTERACT") then
                done = dialog:update(MAX_DIALOG_TIME) or false -- fast-forward
                Sounds:sfx("dialog_skip")
                assert(done, "Dialog should be done after fast-forwarding")
                return false
            end

            if done and Input:isJustPressed("INTERACT") then
                Sounds:sfx("dialog_next")
                i = i + 1

                if i > #text then
                    return true
                end

                done = false
                dialog = dialogFactory(i)
            end
        end,

        draw = function()
            if dialog then
                Draw:draw("ui", ZINDEX.ui.text, function()
                    Ninepatch:draw("dialog", BOX_X, VIEW_HEIGHT - BOX_H, VIEW_WIDTH, BOX_H)
                    dialog:draw(DIALOG_X, VIEW_HEIGHT - DIALOG_Y)
                    if done then
                        SimpleAnim:draw(anim, Vec2.new(VIEW_WIDTH - 15, VIEW_HEIGHT - 10))
                    end
                end)
            end
        end,

        onComplete = function()
        end
    }
end
