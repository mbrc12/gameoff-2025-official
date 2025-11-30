local Parser = require("game.parser")
local SeaCreeper = require("game.sea_creeper")
local game_over = require("game.game_over")
local map_loader = require("game.map_loader")

---@class LevelManager
local LevelManager = {
    list = {},
    ---@type Level
    level = nil,
    curlvl = 1,
    --- during a frame, both of these outcomes can happen, decide() will resolve it at the end of the frame
    failed = false,
    succeeded = false,
    kind = nil,
}
LevelManager.__index = LevelManager

---@param lvl? number
function LevelManager.new(lvl)
    o = {
        list = Parser:list(),
        curlvl = lvl or 1,
    }
    setmetatable(o, LevelManager)
    return o
end

function LevelManager:load()
    Registry.player.immune = true
    self.level = Parser:get(self.list[self.curlvl])
    Registry.map:pause(map_loader(self.level))
    Events:subscribeOnce("map_loaded", function()
        self:postLoad()
    end)
end

function LevelManager:postLoad()
    local map = Registry.map
    if self.level.seacreep then
        local creeper = SeaCreeper:new((map.size[1] + 1) * CELL_SIZE, map.size[2] * CELL_SIZE / 2)
        map:addExtension(creeper)
        if self.level.name and self.level.name == "Finale" then
            creeper.speed = creeper.speed * 3
        end
    end
    -- map:addExtension(SeaCreeper:new((map.size[1] + 1) * CELL_SIZE, map.size[1] * 2))
    Registry.player.immune = false

    self.failed = false
    self.succeeded = false
end

---@param kind "bomb" | "drowning"
function LevelManager:fail(kind)
    self.kind = kind
    self.failed = true
end

function LevelManager:complete()
    self.succeeded = true
end

function LevelManager:decide()
    if not self.failed and not self.succeeded then
        return
    end
    if self.succeeded then
        self.curlvl = self.curlvl + 1
        if self.curlvl == #self.list + 1 then
            switchScreen(WinScreen)
            return
        end
        self:load()
        return
    end
    if self.failed then
        Registry.map:pause(game_over(self.kind))
    end
end

return LevelManager
