require("game.registry")
local Map = require("game.map")

---@class Game : Screen
local Game = {
    ---@type love.ParticleSystem
    particles = nil,
}

_G.LevelToLoad = nil

---@return love.ParticleSystem
function Game.particleSystem()
    local particles = love.graphics.newParticleSystem(Assets.texture("snow"), 100)
    particles:setParticleLifetime(5)
    particles:setInsertMode("random")
    particles:setEmitterLifetime(-1)
    particles:setEmissionRate(10)
    particles:setDirection(math.pi * 0.6)
    particles:setEmissionArea("uniform", VIEW_WIDTH, 10, 0, false)
    particles:setSpeed(40, 70)
    particles:start()
    return particles
end

function Game:enter()
    Music:playTheme()
    self.particles = Game.particleSystem()

    Camera:reset()

    Registry.bird = require("game.bird").new()
    Registry.sea = require("game.sea").new()
    Registry.map = Map.new()
    Registry.ui = require("game.ui").new()
    Registry.player = require("game.player").new()
    Registry.levelManager = require("game.level_manager").new(_G.LevelToLoad)
    Registry.levelManager:load()
    Registry.tutorialManager = require("game.tutorials").new()

    _G.LevelToLoad = nil
end

function Game:leave()
end

function Game:update(dt)
    Registry.map:update(dt)
    self.particles:update(dt)
end

function Game:draw()
    -- Anim:draw()
    Prof.push("compute_draws")
    Camera:update()

    Registry.map:draw()

    Prof.pop("compute_draws")
    Draw:draw("ui", ZINDEX.ui.base, function()
        love.graphics.setColor(Colors.White)
        love.graphics.draw(self.particles, VIEW_WIDTH / 2, -10)
    end)
end

_G.Game = Game

return Game
