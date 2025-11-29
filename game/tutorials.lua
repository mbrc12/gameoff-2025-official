local dialog = require("game.dialog")

---@class TutorialManager
local TutorialManager = {
    ---@type table<string, boolean>
    done = {},
    ---@type Tutorial
    current = {},
}
TutorialManager.__index = TutorialManager

function TutorialManager.new()
    o = {
        done = {},
        current = nil,
    }
    setmetatable(o, TutorialManager)
    return o
end

---@param cell Cell
---@param tutorial Tutorial
---@return LogicDelegate?
function TutorialManager:start(cell, tutorial)
    local anim = SimpleAnim:new("tutorial_highlight", true)
    if self.done[tutorial.id] then
        return nil
    end
    self.current = tutorial
    local dialogManager = dialog(tutorial.text)
    local cells = {} -- cells to highlight
    for _, c in pairs(tutorial.cells) do
        table.insert(cells, { c[1] + cell[1], c[2] + cell[2] })
    end

    return {
        update = function(self_, dt)
            local done = dialogManager:update(dt)
            if done then
                self.done[tutorial.id] = true
                print("Tutorial " .. tutorial.id .. " completed.")
                return true
            end
            return false
        end,
        draw = function(self_)
            dialogManager:draw()
            -- highlight cells
            Draw:draw("main", ZINDEX.main.cursor, function()
                for _, c in pairs(cells) do
                    local center = Registry.map.cellCenter(c)
                    SimpleAnim:draw(anim, center)
                end
            end)
        end,
        onComplete = function(self_)
            dialogManager:onComplete()
        end,
    }
end

return TutorialManager

