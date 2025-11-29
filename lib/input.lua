local JOYSTICK_CHECK_INTERVAL = 1 -- seconds

---@enum (key) Actions
local Actions = {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
    INTERACT = 4,
    SWITCH = 5,
    BACK = 6,
    HIDE = 7,
    TELEPORT = 8,
}

---@type table<Actions, {keyboard: string[], joystick: string[]}>
local keymap = {
    UP = { keyboard = {'w', 'up'}, joystick = {'dpup', 'lup', 'rup'} },
    DOWN = { keyboard = {'s', 'down'}, joystick = {'dpdown', 'ldown', 'rdown'} },
    LEFT = { keyboard = {'a', 'left'}, joystick = {'dpleft', 'lleft', 'rleft'} },
    RIGHT = { keyboard = {'d', 'right'}, joystick = {'dpright', 'lright', 'rright'} },
    INTERACT = { keyboard = {'e', 'space', 'return'}, joystick = {'a'} },
    SWITCH = { keyboard = {'q', 'tab'}, joystick = {'x'} },
    BACK = { keyboard = {'escape', 'backspace'}, joystick = {'b'} },
    HIDE = { keyboard = {'h'}, joystick = {'rbutton'} },
    TELEPORT = { keyboard = {'t'}, joystick = {'y'} },
}

---@type table<string, fun(love.Joystick):boolean>
local joystickChecker = {
    a = function(joy) return joy:isGamepadDown("a") end,
    b = function(joy) return joy:isGamepadDown("b") end,
    x = function(joy) return joy:isGamepadDown("x") end,
    y = function(joy) return joy:isGamepadDown("y") end,
    dpleft = function(joy) return joy:isGamepadDown("dpleft") end,
    dpright = function(joy) return joy:isGamepadDown("dpright") end,
    dpup = function(joy) return joy:isGamepadDown("dpup") end,
    dpdown = function(joy) return joy:isGamepadDown("dpdown") end,
    ltrigger = function(joy) return joy:getGamepadAxis("triggerleft") > 0.5 end,
    rtrigger = function(joy) return joy:getGamepadAxis("triggerright") > 0.5 end,
    lbutton = function(joy) return joy:isGamepadDown("leftshoulder") end,
    rbutton = function(joy) return joy:isGamepadDown("rightshoulder") end,
    lup = function(joy) return joy:getGamepadAxis("lefty") < -0.5 end,
    ldown = function(joy) return joy:getGamepadAxis("lefty") > 0.5 end,
    lleft = function(joy) return joy:getGamepadAxis("leftx") < -0.5 end,
    lright = function(joy) return joy:getGamepadAxis("leftx") > 0.5 end,
    rup = function(joy) return joy:getGamepadAxis("righty") < -0.5 end,
    rdown = function(joy) return joy:getGamepadAxis("righty") > 0.5 end,
    rleft = function(joy) return joy:getGamepadAxis("rightx") < -0.5 end,
    rright = function(joy) return joy:getGamepadAxis("rightx") > 0.5 end,
}

---@class Input
local Input = {
    ---@type table<number, table<Actions, boolean>>
    history = {},

    ---@type table<Actions, boolean>
    next = {},

    ---@type love.Joystick
    joystick = nil,

    lastJoystickCheck = 0,

    releasedInTheInterim = false,
}

function new_state()
    local state = {}
    for action, _ in pairs(Actions) do
        state[action] = false
    end
    return state
end

local INPUT_HISTORY = 10

function Input:init()
    for i = 1, INPUT_HISTORY do
        table.insert(self.history, new_state())
    end
    self.next = new_state()
    self:checkJoystick()
end

-- Check for joystick connection every JOYSTICK_CHECK_INTERVAL seconds
function Input:checkJoystick()
    if self.joystick and self.joystick:isConnected() then
        return
    else
        self.joystick = nil
    end

    if self.lastJoystickCheck + JOYSTICK_CHECK_INTERVAL > love.timer.getTime() then
        return
    end

    self.jastJoystickCheck = love.timer.getTime()

    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        self.joystick = joysticks[1]
        Log("Joystick connected: " .. self.joystick:getName())
    end
end

local frame = 0
--- tool-assisted input testing
---@param current table<Actions, boolean>
local function tas(current)
    frame = frame + 1
    current["UP"] = (frame % 3) <= 1
end

---@param dt number
function Input:update(dt)
    self:checkJoystick()
    table.remove(self.history)

    table.insert(self.history, 1, self.next)
    local current = self.history[1]
    -- tas(current)

    for action, mappings in pairs(keymap) do
        for _, key in ipairs(mappings.keyboard) do
            if love.keyboard.isDown(key) then
               current[action] = true
            end
        end
        if self.joystick then
            for _, button in ipairs(mappings.joystick) do
                local checker = joystickChecker[button]
                if checker and checker(self.joystick) then
                    current[action] = true
                end
            end
        end
    end

    self.next = new_state()

end

function love.keypressed(key, scancode, isrepeat)
    if key == "f5" and not isrepeat then
        if Registry.player then
            Registry.player.nodamage = not Registry.player.nodamage
            Registry.map.resources = 100
        end
    end
    if key == "f8" and not isrepeat then
        dbg()
    end
    for action, mappings in pairs(keymap) do
        for _, k in ipairs(mappings.keyboard) do
            if key == k then
                Input.next[action] = true
            end
        end
    end
end

function love.gamepadpressed(joystick, button)
    for action, mappings in pairs(keymap) do
        for _, b in ipairs(mappings.joystick) do
            if button == b then
                Input.next[action] = true
            end
        end
    end
end

---@param action Actions
---@return boolean
function Input:isPressed(action)
    local current = self.history[1]
    return current[action]
end

---@param action Actions
---@param leniency? number
---@return boolean
function Input:isJustPressed(action, leniency)
    leniency = leniency or 1
    for i = 1, #self.history - 1 do
        local state = self.history[i]
        local prev = self.history[i + 1]
        if state[action] and not prev[action] then
            return i <= leniency
        end
    end
end

---@return boolean
function Input:holding()
    for action, _ in pairs(Actions) do
        if self.history[1][action] ~= self.history[2][action] then
            return false
        end
    end
    return true
end

---@return boolean
function Input:nothing()
    for action, _ in pairs(Actions) do
        if self.history[1][action] then
            return false
        end
    end
    return true
end

---@param frames number
---@return string
function Input:debugString(frames)
    frames = frames or 1
    local parts = {}
    local s = ""
    for i = 1, frames do
        s = s .. (i > 1 and " | " or "")
        for action, _ in pairs(Actions) do
            if self.history[i][action] then
                s = s .. action .. " "
            end
        end
    end
    return s
end

---@return Vec2
function Input:direction()
    local dir = Vec2.new(0, 0)
    if self:isPressed("UP") then
        dir.y = dir.y - 1
    end
    if self:isPressed("DOWN") then
        dir.y = dir.y + 1
    end
    if self:isPressed("LEFT") then
        dir.x = dir.x - 1
    end
    if self:isPressed("RIGHT") then
        dir.x = dir.x + 1
    end
    return dir:normalized()
end

function love.joystickreleased(key, scancode)
    Input.releasedInTheInterim = true
end

_G.Input = Input
