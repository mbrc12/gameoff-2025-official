---@class Screen
local Screen = {}

function Screen:enter()
    -- Called when the screen is entered
end

function Screen:leave()
    -- Called when the screen is left
end

---@param dt number
function Screen:update(dt)
    -- Update the screen state
end

function Screen:draw()
    -- Draw the screen contents
end

-- exports nothing
