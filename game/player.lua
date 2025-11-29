local explore = require("game.explore")
local dialog = require("game.dialog")

_G.ORIGINAL_MOVEMENT_TIME = 0.16
_G.MOVEMENT_TIME = ORIGINAL_MOVEMENT_TIME -- might be changed by options

local ease_fn = TweenEase.Out

---@class Player
local Player = {
    nodamage = false,
    ---@type Cell|nil
    old = nil,
    elapsed = 0,
    allotted_time = 1,

    ---@type table<string, boolean>
    keys = {},

    immune = false, -- no decision on game allowed
}
Player.__index = Player

function Player.new()
    o = {
        keys = {},
    }
    setmetatable(o, Player)
    return o
end

---@param cell Cell
function Player:forcedSet(cell)
    local map = Registry.map
    map.player = { cell[1], cell[2] }
    map.playerPos = map.cellCenter(map.player)
end

---@return boolean
function Player:isMoving()
    return self.old ~= nil
end

---@param cell Cell
---@param time number|nil
---@param noaudio boolean|nil
function Player:moveTo(cell, time, noaudio)
    local map = Registry.map

    if self.old then
        self:finishMovement()
    end

    self.old = { map.player[1], map.player[2] }
    map.player = { cell[1], cell[2] }
    map:reveal(cell)


    if not noaudio then
        Sounds:sfx("move")
    end

    self.elapsed = 0
    self.allotted_time = time or MOVEMENT_TIME
end

function Player:finishMovement()
    local map = Registry.map

    if not self.old then
        return
    end

    self.old = nil
    self.elapsed = 0

    map.playerPos = map.cellCenter(map.player)

    if not self.immune and Util.cellEq(map.player, map.goal) then
        Registry.levelManager:complete()
        return
    end

    local cellData = map:get(map.player)

    if cellData.item and map.resources < RESOURCE_MAX then
        map.resources = map.resources + 1
        -- Sounds:shuffledSfx("powerup")
        Sounds:sfx("pickup")
        Registry.ui:schedulePickupResource(map.player)
    end

    cellData.item = false


    if cellData.bomb and not self.immune and not self.nodamage then
        -- Game over
        Registry.levelManager:fail("bomb")
        return
    end

    if cellData.key then -- pick up key
        self.keys[cellData.key] = true
        --- add logic to show keytext
        Sounds:sfx("key_pickup")
        map:pause(dialog(Util.concat({
            "Picked up the key of " .. cellData.key .. ".",
        }, cellData.keyText or {})))

        cellData.key = nil
    end

    Events:emit("player_tween_complete")

end

---@return boolean did a new job start?
function Player:idleJobs()
    local map = Registry.map
    local cellData = map:get(map.player)

    if not cellData.explored then
        local exploreStart = map:pause(explore(map.player))
        if exploreStart then
            return true
        end
    end

    if map.tutorials[cellData.tutorialId] then
        local tut = map.tutorials[cellData.tutorialId]
        local tutStart = map:pause(Registry.tutorialManager:start(map.player, tut))
        if tutStart then
            return true
        end
    end

    return false
end

---@param dt number
function Player:update(dt)
    local map = Registry.map

    if not self.immune then
        if not map:exists(map.player) then -- current got destroyed
            Registry.levelManager:fail("drowning")
            return
        end
    end

    if not self.old and not map.pauseDelegate then
        if self:idleJobs() then
            return
        end
    end

    --- explore only if not moving, and not explored and not paused

    if not self.old then
        return
    end

    self.elapsed = self.elapsed + dt
    local t_pre = math.min(self.elapsed / self.allotted_time)

    local t = ease_fn(t_pre)
    map.playerPos = map.cellCenter(self.old):lerp(map.cellCenter(map.player), t)
    Camera:moveTo(map.playerPos)

    if t_pre >= 1 then
        self:finishMovement()
        return
    end
end

return Player
